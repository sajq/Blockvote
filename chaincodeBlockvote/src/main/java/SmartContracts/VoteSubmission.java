package SmartContracts;

import com.owlike.genson.Genson;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Contract(
        name = "Vote Submission Contract",
        info = @Info(
                title = "Vote Submission",
                description = "Vote submission class",
                version = "0.0.1"
        )
)

@Default
public final class VoteSubmission implements ContractInterface {

    private final Genson gs = new Genson();

    private enum VoteTransferErrors {
        ALREADY_VOTED,
        VOTING_CAMPAIGN_NOT_STARTED
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void ChainStarterVotes(Context context)
    {
        ChaincodeStub chaincodeStub=context.getStub();

        submitVote(context,"vote1","voter1",Date.from(Instant.now()));
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Vote submitVote(Context context, String voteID, String voterID, Date voteDate)
    {
        ChaincodeStub chaincodeStub=context.getStub();

        /*if(voterAlreadyVoted(voteID,voterID))
        {

        }*/

        Vote vote = new Vote(voteID,voterID,voteDate);
        chaincodeStub.putStringState(voteID,gs.serialize(vote));

        return vote;
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Vote getVote(Context context, String voteID)
    {
        ChaincodeStub chaincodeStub=context.getStub();
        String voteJSON = chaincodeStub.getStringState(voteID);

        //check if vote exists

        return gs.deserialize(voteJSON,Vote.class);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Vote updateVote(Context context, String voteID, String voterID, Date voteDate)
    {
        ChaincodeStub chaincodeStub=context.getStub();

        //check if vote exists

        Vote vote = new Vote(voteID,voterID,voteDate);
        chaincodeStub.putStringState(voteID,gs.serialize(vote));
        return vote;
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void deleteVote(Context context, String voteID)
    {
        ChaincodeStub chaincodeStub=context.getStub();

        //check if vote exists

        chaincodeStub.delState(voteID);
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String getAllVotes(Context context)
    {
        ChaincodeStub chaincodeStub=context.getStub();

        List<Vote> votes=new ArrayList<Vote>();
        QueryResultsIterator<KeyValue> queryResults = chaincodeStub.getStateByRange("","");

        for(KeyValue kv:queryResults){
            votes.add(gs.deserialize(kv.getStringValue(),Vote.class));
        }

        System.out.println(votes);
        return gs.serialize(votes);
    }

    public boolean voteExists(Context context, String voteID){

        // add vote campaign check

        ChaincodeStub chaincodeStub=context.getStub();
        String voteJSON = chaincodeStub.getStringState(voteID);
        return (voteJSON != null && !voteJSON.isEmpty());
    }

}
