package org.hyperledger.fabric.samples.assettransfer;

import java.util.Objects;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;
import com.owlike.genson.annotation.JsonProperty;

@DataType()
public final class Vote {

    @Property()
    private final String voteID;

    @Property()
    private final String voterID;

    @Property()
    private final String voteDate;

    public Vote(@JsonProperty("voteID") final String voteID, @JsonProperty("voterID") final String voterID, @JsonProperty("voteDate") final String voteDate) {
        this.voteID = voteID;
        this.voterID = voterID;
        this.voteDate = voteDate;
    }

    public String getVoteID() {
        return voteID;
    }

    public String getVoterID() {
        return voterID;
    }

    public String getVoteDate() {
        return voteDate;
    }

    @Override
    public int hashCode() {
        return Objects.hash(getVoteID(), getVoterID(), getVoteDate());
    }

    @Override
    public boolean equals(final Object obj) {
        if (this == obj) {
            return true;
        }

        if ((obj == null) || (getClass() != obj.getClass())) {
            return false;
        }

        Vote other = (Vote) obj;

        return Objects.deepEquals(
                new String[] {getVoteID(), getVoterID(), getVoteDate()},
                new String[] {other.getVoteID(), other.getVoterID(), other.getVoteDate()});
    }

    @Override
    public String toString() {
        return getVoteID() + " " + getVoterID() + " " + getVoteDate();
    }
}
