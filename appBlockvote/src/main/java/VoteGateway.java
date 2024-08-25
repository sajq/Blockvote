import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonParser;
import io.grpc.Grpc;
import io.grpc.ManagedChannel;
import io.grpc.TlsChannelCredentials;
import org.hyperledger.fabric.client.CommitException;
import org.hyperledger.fabric.client.CommitStatusException;
import org.hyperledger.fabric.client.Contract;
import org.hyperledger.fabric.client.EndorseException;
import org.hyperledger.fabric.client.Gateway;
import org.hyperledger.fabric.client.GatewayException;
import org.hyperledger.fabric.client.SubmitException;
import org.hyperledger.fabric.client.identity.Identities;
import org.hyperledger.fabric.client.identity.Identity;
import org.hyperledger.fabric.client.identity.Signer;
import org.hyperledger.fabric.client.identity.Signers;
import org.hyperledger.fabric.client.identity.X509Identity;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.InvalidKeyException;
import java.security.cert.CertificateException;
import java.time.Instant;
import java.util.concurrent.TimeUnit;

public final class VoteGateway {

    private static final String MSP = System.getenv().getOrDefault("MSP_ID", "voteOrg1MSP"); /**get info from environment of server regarding Membership Service Provider ID**/
    private static final String VoteChannel = System.getenv().getOrDefault("CHANNEL_NAME", "votechannel");
    private static final String VoteChaincode = System.getenv().getOrDefault("CHAINCODE_NAME", "BlockVote");

    private static final Path VOTE_CRYPT_PATH = Paths.get("../VoteNetwork/votingOrganizations/peerOrganizations/voteOrg1.blockvote.com");
    private static final Path CERT_PATH = VOTE_CRYPT_PATH.resolve(Paths.get("users/User1@voteOrg1.blockvote.com/msp/signcerts"));
    private static final Path VOTE_KEYS = VOTE_CRYPT_PATH.resolve(Paths.get("users/User1@voteOrg1.blockvote.com/msp/keystore"));
    private static final Path TLS_CERT = VOTE_CRYPT_PATH.resolve(Paths.get("peers/peer0.voteOrg1.blockvote.com/tls/ca.crt"));

    private static final String voteEndpoint="localhost:7051";
    private static final String voteLeader="peer0.voteOrg1.blockvote.com";

    private final Contract gatewayContract;
    private final String testVoteID = "voteGateway-"+ Instant.now();
    private final Gson gs = new GsonBuilder().setPrettyPrinting().create();

    public VoteGateway(final Gateway gateway) throws GatewayException, CommitException
    {
        System.out.println(VoteChannel);
        var network = gateway.getNetwork(VoteChannel);
        gatewayContract = network.getContract(VoteChaincode);
        System.out.println("test1");
    }

    public static void main(final String[] args) throws Exception {

        ManagedChannel managedChannel = createVoteChannel();

        var gatewayBuilder = Gateway.newInstance().identity(voteIndentity()).signer(getVoteSigner()).connection(managedChannel)
				// Default timeouts for different gRPC calls
				.evaluateOptions(options -> options.withDeadlineAfter(5, TimeUnit.SECONDS))
				.endorseOptions(options -> options.withDeadlineAfter(15, TimeUnit.SECONDS))
				.submitOptions(options -> options.withDeadlineAfter(5, TimeUnit.SECONDS))
				.commitStatusOptions(options -> options.withDeadlineAfter(1, TimeUnit.MINUTES)); //org.hyperledger.fabric.client.Gateway.newInstance().identity(voteIndentity()).signer(getVoteSigner()).connection(managedChannel);


        try(Gateway voteGateway = gatewayBuilder.connect())
        {
            System.out.println("test2");
            new VoteGateway(voteGateway).run();
        }finally {
            managedChannel.shutdown();
        }

    }

    public void run() throws GatewayException, CommitException {
        initializeVoteLedger();

        submitVote(testVoteID,"1");

        getVote(testVoteID);

        updateVote(testVoteID,"2");

        getAllVotes();
    }

    public static ManagedChannel createVoteChannel() throws IOException { 
        return Grpc.newChannelBuilder(voteEndpoint, TlsChannelCredentials.newBuilder().trustManager(TLS_CERT.toFile()).build()).overrideAuthority(voteLeader).build();
    }

    public static Identity voteIndentity() throws IOException, CertificateException {
    try (var certReader = Files.newBufferedReader(getFirstFilePath(CERT_PATH))) {
			var voteCertificate = Identities.readX509Certificate(certReader);
			return new X509Identity(MSP, voteCertificate);
		}
        //return new X509Identity(MSP,getVotingCertificate());
    }
    
    private static Path getFirstFilePath(Path dirPath) throws IOException {
		try (var keyFiles = Files.list(dirPath)) {
			return keyFiles.findFirst().orElseThrow();
		}
	}
/*
    private static X509Certificate getVotingCertificate() throws IOException, CertificateException {
        try{
            return Identities.readX509Certificate(Files.newBufferedReader(Files.list(CERT_PATH).findFirst().orElseThrow()));
        }catch(Exception e)
        {
            System.out.println("Error in reading certificate");
            throw e;
        }
    }*/

    public static Signer getVoteSigner() throws IOException, InvalidKeyException {
    try (var keyReader = Files.newBufferedReader(getFirstFilePath(VOTE_KEYS))) {
			var privateKey = Identities.readPrivateKey(keyReader);
			return Signers.newPrivateKeySigner(privateKey);
		}
        //return Signers.newPrivateKeySigner(getVotingPrivateKey());
    }
/*
    private static PrivateKey getVotingPrivateKey() throws IOException, InvalidKeyException {
        try{
            return Identities.readPrivateKey(Files.newBufferedReader(Files.list(VOTE_KEYS).findFirst().orElseThrow()));
        }catch(Exception e)
        {
            System.out.println("Error in reading private key");
            throw e;
        }
    }*/

    private void initializeVoteLedger() throws EndorseException, CommitException, SubmitException, CommitStatusException {
        System.out.println("Initializing ledger...");
        try{
        gatewayContract.submitTransaction("InitLedger");
        } catch(Exception e){
          System.out.println("test3");
          e.printStackTrace();
          throw e;
        }
        System.out.println("Ledger initialized!");
    }

    private void submitVote(String voteID, String voterID) throws EndorseException, CommitException, SubmitException, CommitStatusException {
        System.out.println("Submitting vote...");
        gatewayContract.submitTransaction("submitVote",voteID,voterID, Instant.now().toString());
        System.out.println("Vote submitted!");
    }

    private void getVote(String voteID) throws GatewayException {
        System.out.println("Retrieving vote...");
        var evaluateResult = gatewayContract.evaluateTransaction("getVote",voteID);
        System.out.println(evaluateResult);
    }

    private void updateVote(String voteID, String voterID){
        /**check if voting campaign is still valid**/
        try{
            System.out.println("Updating vote...");
            gatewayContract.submitTransaction("updateVote",voteID,voterID, Instant.now().toString());
            System.out.println("Vote updated!");
        }catch(Exception e)
        {
            System.out.println("Vote with ID: "+voteID+" was not updated!");
        }
    }

    private void getAllVotes() throws GatewayException {
        System.out.println("Retrieving all votes...");
        var result = gatewayContract.evaluateTransaction("getAllVotes");
	System.out.println(result);
        //return Base64.getEncoder().encodeToString(gatewayContract.evaluateTransaction("getAllVotes"));
    }

}
