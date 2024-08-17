package SmartContracts;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.util.Date;
import java.util.Objects;

@DataType()
public final class Vote {

    @Property()
    private final String voteID;

    @Property()
    private final String voterID;

    @Property()
    private final Date voteDate;

    public Vote(@JsonProperty("voteID") String voteID, @JsonProperty("voterID") String voterID, @JsonProperty("voteDate") Date voteDate){
        this.voteID = voteID;
        this.voterID = voterID;
        this.voteDate = voteDate;
    }

    public String getVoteID(){
        return voteID;
    }

    public String getVoterID(){
        return voterID;
    }

    public Date getVoteDate(){
        return voteDate;
    }

    @Override
    public int hashCode(){
        return Objects.hash(getVoteID(),getVoterID(),getVoteDate());
    }

    @Override
    public String toString() {
        return getVoteID()+" "+getVoterID()+" "+getVoteDate();
    }
}
