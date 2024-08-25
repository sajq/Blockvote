/*
 * SPDX-License-Identifier: Apache-2.0
 */

package org.hyperledger.fabric.samples.votetransaction;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

public final class VoteTest {

    @Nested
    class VoteTestEquals {

        @Test
        public void isReflexive() {
            Vote vote = new Vote("vote1", "voter1", "12-08-2024");

            assertThat(asset).isEqualTo(asset);
        }

        @Test
        public void isSymmetric() {
            Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");
            Vote vote2 = new Vote("vote1", "voter1", "12-08-2024");

            assertThat(vote1).isEqualTo(vote2);
            assertThat(vote2).isEqualTo(vote1);
        }

        @Test
        public void isTransitive() {
            Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");
            Vote vote2 = new Vote("vote1", "voter1", "12-08-2024");
            Vote vote3 = new Vote("vote1", "voter1", "12-08-2024");

            assertThat(vote1).isEqualTo(vote2);
            assertThat(vote2).isEqualTo(vote3);
            assertThat(vote1).isEqualTo(vote3);
        }

        @Test
        public void handlesInequality() {
            Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");
            Vote vote2 = new Vote("vote2", "voter2", "23-08-2024");

            assertThat(vote1).isNotEqualTo(vote2);
        }

        @Test
        public void handlesOtherObjects() {
            Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");
            String vote2 = "not a vote";

            assertThat(vote1).isNotEqualTo(vote2);
        }

        @Test
        public void handlesNull() {
            Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");

            assertThat(vote1).isNotEqualTo(null);
        }
    }

    @Test
    public void toStringIdentifiesVote() {
        Vote vote1 = new Vote("vote1", "voter1", "12-08-2024");

        assertThat(asset.toString()).isEqualTo("Vote@e04f6c53 [voteID=vote1, voterID=voter1, voteDate=12-08-2024]");
    }
}
