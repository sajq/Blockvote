package org.hyperledger.fabric.samples.assettransfer;

import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.contract.annotation.Default;
import com.owlike.genson.Genson;
import java.util.ArrayList;
import java.util.List;

@Contract(
        name = "BlockVote",
        info = @Info(
                title = "Vote Submission",
                description = "Vote submission class",
                version = "0.0.1"
        )
)

@Default
public final class VoteSubmission implements ContractInterface {

    private enum VoteTransferErrors {
        VOTE_NOT_FOUND,
        ALREADY_VOTED,
        VOTING_CAMPAIGN_NOT_STARTED
    }

    private final Genson genson = new Genson();

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void InitLedger(final Context context) {
        ChaincodeStub chaincodeStub = context.getStub();
        submitVote(context, "vote1", "voter1", "12-08-2024");
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Vote submitVote(final Context context, final String voteID, final String voterID, final String voteDate) {
        ChaincodeStub chaincodeStub = context.getStub();

        /*if(voterAlreadyVoted(voteID,voterID))
        {

        }*/

        Vote vote = new Vote(voteID, voterID, voteDate);
        chaincodeStub.putStringState(voteID, genson.serialize(vote));

        return vote;
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public Vote getVote(final Context context, final String voteID) {
        ChaincodeStub chaincodeStub = context.getStub();
        String voteJSON = chaincodeStub.getStringState(voteID);

        //check if vote exists

        return genson.deserialize(voteJSON, Vote.class);
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public Vote updateVote(final Context context, final String voteID, final String voterID, final String voteDate) {
        ChaincodeStub chaincodeStub = context.getStub();

        //check if vote exists

        Vote vote = new Vote(voteID, voterID, voteDate);
        chaincodeStub.putStringState(voteID, genson.serialize(vote));
        return vote;
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public boolean voteExists(final Context context, final String voteID) {

        ChaincodeStub chaincodeStub = context.getStub();
        String voteJSON = chaincodeStub.getStringState(voteID);
        return (!voteJSON.isEmpty() && voteJSON != null);
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String getAllVotes(final Context context) {
        ChaincodeStub chaincodeStub = context.getStub();

        List<Vote> votes = new ArrayList<Vote>();
        QueryResultsIterator<KeyValue> queryResults = chaincodeStub.getStateByRange("", "");

        for (KeyValue kv:queryResults) {
            votes.add(genson.deserialize(kv.getStringValue(), Vote.class));
        }

        System.out.println(votes);
        return genson.serialize(votes);
    }

}
