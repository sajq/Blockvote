package Gateway;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import io.grpc.Grpc;
import io.grpc.ManagedChannel;
import io.grpc.TlsChannelCredentials;
import org.hyperledger.fabric.client.*;
import org.hyperledger.fabric.client.identity.*;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.InvalidKeyException;
import java.security.PrivateKey;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.time.Instant;
import java.util.Base64;

public final class VoteGateway {

    private static final String MSP = "VoteMSP"; /**get info from environment of server regarding Membership Service Provider ID**/
    private static final String VoteChannel = "vote_channel";
    private static final String VoteChaincode = "vote_chaincode";

    private static final Path VOTE_CRYPT_PATH = Paths.get("VoteNetwork/votingOrganizations/participantOrganizations/voteOrg1.blockvote.com");
    private static final Path CERT_PATH = VOTE_CRYPT_PATH.resolve(Paths.get("users/User1@voteOrg1.blockvote.com/msp/signcerts"));
    private static final Path VOTE_KEYS = VOTE_CRYPT_PATH.resolve(Paths.get("users/User1@voteOrg1.blockvote.com/msp/keystore"));
    private static final Path TLS_CERT = VOTE_CRYPT_PATH.resolve(Paths.get("peers/peer0.voteOrg1.blockvote.com/tls/ca.crt"));

    private static final String voteEndpoint="localhost:8333";
    private static final String voteLeader="voter0.blockvote.com";

    public static Contract gatewayContract;
    private final String testVoteID = "voteGateway-"+ Instant.now();
    private final Gson gs = new GsonBuilder().create();

    public VoteGateway(Gateway gateway)
    {
        Network network = gateway.getNetwork(VoteChannel);
        gatewayContract = network.getContract(VoteChaincode);
    }

    public static void main(final String[] args) throws CertificateException, IOException, InvalidKeyException, CommitException, GatewayException {

        ManagedChannel managedChannel = createVoteChannel();

        Gateway.Builder gatewayBuilder = org.hyperledger.fabric.client.Gateway.newInstance().identity(voteIndentity()).signer(getVoteSigner()).connection(managedChannel);
        /**Add optional timeouts**/

        try(Gateway voteGateway = gatewayBuilder.connect())
        {
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
        return Grpc.newChannelBuilder(voteEndpoint, TlsChannelCredentials.newBuilder().trustManager(TLS_CERT.toFile()).build()).build();
    }

    public static org.hyperledger.fabric.client.identity.Identity voteIndentity() throws IOException, CertificateException {
        return new X509Identity(MSP,getVotingCertificate());
    }

    private static X509Certificate getVotingCertificate() throws IOException, CertificateException {
        try{
            return Identities.readX509Certificate(Files.newBufferedReader(Files.list(CERT_PATH).findFirst().orElseThrow()));
        }catch(Exception e)
        {
            System.out.println("Error in reading certificate");
            throw e;
        }
    }

    public static Signer getVoteSigner() throws IOException, InvalidKeyException {
        return Signers.newPrivateKeySigner(getVotingPrivateKey());
    }

    private static PrivateKey getVotingPrivateKey() throws IOException, InvalidKeyException {
        try{
            return Identities.readPrivateKey(Files.newBufferedReader(Files.list(VOTE_KEYS).findFirst().orElseThrow()));
        }catch(Exception e)
        {
            System.out.println("Error in reading private key");
            throw e;
        }
    }

    private void initializeVoteLedger() throws EndorseException, CommitException, SubmitException, CommitStatusException {
        System.out.println("Initializing ledger...");
        gatewayContract.submitTransaction("InitLedger");
        System.out.println("Ledger initialized!");
    }

    private void submitVote(String voteID, String voterID) throws EndorseException, CommitException, SubmitException, CommitStatusException {
        System.out.println("Submitting vote...");
        gatewayContract.submitTransaction("CreateAsset",voteID,voterID, Instant.now().toString());
        System.out.println("Vote submitted!");
    }

    private String getVote(String voteID) throws GatewayException {
        System.out.println("Retrieving vote...");
        return Base64.getEncoder().encodeToString(gatewayContract.evaluateTransaction("ReadAsset",voteID));
    }

    private void updateVote(String voteID, String voterID){
        /**check if voting campaign is still valid**/
        try{
            System.out.println("Updating vote...");
            gatewayContract.submitTransaction("UpdateAsset",voteID,voterID, Instant.now().toString());
            System.out.println("Vote updated!");
        }catch(Exception e)
        {
            System.out.println("Vote with ID: "+voteID+" was not updated!");
        }
    }

    private String getAllVotes() throws GatewayException {
        System.out.println("Retrieving all votes...");
        return Base64.getEncoder().encodeToString(gatewayContract.evaluateTransaction("GetAllAssets"));
    }

}
