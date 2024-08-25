/*
 * SPDX-License-Identifier: Apache-2.0
 */

package org.hyperledger.fabric.samples.votetransaction;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.ThrowableAssert.catchThrowable;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyZeroInteractions;
import static org.mockito.Mockito.when;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

public final class VoteTransactionTest {

    private final class MockKeyValue implements KeyValue {

        private final String key;
        private final String value;

        MockKeyValue(final String key, final String value) {
            super();
            this.key = key;
            this.value = value;
        }

        @Override
        public String getKey() {
            return this.key;
        }

        @Override
        public String getStringValue() {
            return this.value;
        }

        @Override
        public byte[] getValue() {
            return this.value.getBytes();
        }

    }

    private final class MockAssetResultsIterator implements QueryResultsIterator<KeyValue> {

        private final List<KeyValue> votesList;

        MockAssetResultsIterator() {
            super();

            voteList = new ArrayList<KeyValue>();

            voteList.add(new MockKeyValue("vote1",
                    "{ \"voteID\": \"vote1\", \"voterID\": \"voter1\", \"voteDate\": 12-08-2024 }"));
            voteList.add(new MockKeyValue("vote2",
                    "{ \"voteID\": \"vote2\", \"voterID\": \"voter2\", \"voteDate\": 24-09-2024 }"));
            voteList.add(new MockKeyValue("vote3",
                    "{ \"voteID\": \"vote3\", \"voterID\": \"voter3\", \"voteDate\": 01-09-2024 }"));
            voteList.add(new MockKeyValue("vote4",
                    "{ \"voteID\": \"vote4\", \"voterID\": \"voter4\", \"voteDate\": 17-07-2024 }"));
            voteList.add(new MockKeyValue("vote5",
                    "{ \"voteID\": \"vote5\", \"voterID\": \"voter5\", \"voteDate\": 21-03-2024 }"));
            voteList.add(new MockKeyValue("vote6",
                    "{ \"voteID\": \"vote6\", \"voterID\": \"voter6\", \"voteDate\": 09-02-2023 }"));
        }

        @Override
        public Iterator<KeyValue> iterator() {
            return votesList.iterator();
        }

        @Override
        public void close() throws Exception {
            // do nothing
        }

    }

    @Test
    public void invokeUnknownTransaction() {
        AssetTransfer contract = new AssetTransfer();
        Context ctx = mock(Context.class);

        Throwable thrown = catchThrowable(() -> {
            contract.unknownTransaction(ctx);
        });

        assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                .hasMessage("Undefined contract method called");
        assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo(null);

        verifyZeroInteractions(ctx);
    }

    @Nested
    class InvokeReadVoteTransaction {

        @Test
        public void whenVoteExists() {
            VoteTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("vote1"))
                    .thenReturn("{ \"voteID\": \"vote1\", \"voterID\": \"voter1\", \"voteDate\": 12-08-2024 }");

            Vote vote = contract.getVote(ctx, "vote1");

            assertThat(asset).isEqualTo(new Vote("vote1", "voter1", "12-08-2024"));
        }

        @Test
        public void whenVoteDoesNotExist() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("vote1")).thenReturn("");

            Throwable thrown = catchThrowable(() -> {
                contract.getVote(ctx, "vote1");
            });

            assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                    .hasMessage("Vote vote1 does not exist");
            assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo("VOTE_NOT_FOUND".getBytes());
        }
    }

    @Test
    void invokeChainStarterVotesTransaction() {
        AssetTransfer contract = new AssetTransfer();
        Context ctx = mock(Context.class);
        ChaincodeStub stub = mock(ChaincodeStub.class);
        when(ctx.getStub()).thenReturn(stub);

        contract.ChainStarterVotes(ctx);

        InOrder inOrder = inOrder(stub);
        inOrder.verify(stub).putStringState("vote1", "{ \"voteID\": \"vote1\", \"voterID\": \"voter1\", \"voteDate\": 12-08-2024 }");
        inOrder.verify(stub).putStringState("vote2", "{ \"voteID\": \"vote2\", \"voterID\": \"voter2\", \"voteDate\": 24-09-2024 }");
        inOrder.verify(stub).putStringState("vote3", "{ \"voteID\": \"vote3\", \"voterID\": \"voter3\", \"voteDate\": 01-09-2024 }");
        inOrder.verify(stub).putStringState("vote4", "{ \"voteID\": \"vote4\", \"voterID\": \"voter4\", \"voteDate\": 17-07-2024 }");
        inOrder.verify(stub).putStringState("vote5", "{ \"voteID\": \"vote5\", \"voterID\": \"voter5\", \"voteDate\": 21-03-2024 }");

    }

    @Nested
    class InvokeCreateVoteTransaction {

        @Test
        public void whenVoteExists() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("vote1"))
                    .thenReturn("vote1", "{ \"voteID\": \"vote1\", \"voterID\": \"voter1\", \"voteDate\": 12-08-2024 }");

            Throwable thrown = catchThrowable(() -> {
                contract.submitVote(ctx, "vote1", "voter1", "12-08-2024");
            });

            assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                    .hasMessage("Vote vote1 already exists");
            assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo("ALREADY_VOTED".getBytes());
        }

        @Test
        public void whenVoteDoesNotExist() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("vote")).thenReturn("");

            Asset asset = contract.submitVote(ctx, "vote1", "voter1", "12-08-2024");

            assertThat(asset).isEqualTo(new Asset(ctx, "vote1", "voter1", "12-08-2024"));
        }
    }

    @Test
    void invokeGetAllVotesTransaction() {
        AssetTransfer contract = new AssetTransfer();
        Context ctx = mock(Context.class);
        ChaincodeStub stub = mock(ChaincodeStub.class);
        when(ctx.getStub()).thenReturn(stub);
        when(stub.getStateByRange("", "")).thenReturn(new MockAssetResultsIterator());

        String votes = contract.GetAllVotes(ctx);

        assertThat(votes).isEqualTo("[{ \"voteID\": \"vote1\", \"voterID\": \"voter1\", \"voteDate\": 12-08-2024 },"
                + "{ \"voteID\": \"vote2\", \"voterID\": \"voter2\", \"voteDate\": 24-09-2024 },"
                + "{ \"voteID\": \"vote3\", \"voterID\": \"voter3\", \"voteDate\": 01-09-2024 },"
                + "{ \"voteID\": \"vote4\", \"voterID\": \"voter4\", \"voteDate\": 17-07-2024 },"
                + "{ \"voteID\": \"vote5\", \"voterID\": \"voter5\", \"voteDate\": 21-03-2024 },"
                + "{ \"voteID\": \"vote6\", \"voterID\": \"voter6\", \"voteDate\": 09-02-2023 }]");

    }
/*
    @Nested
    class TransferAssetTransaction {

        @Test
        public void whenAssetExists() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("asset1"))
                    .thenReturn("{ \"assetID\": \"asset1\", \"color\": \"blue\", \"size\": 5, \"owner\": \"Tomoko\", \"appraisedValue\": 300 }");

            String oldOwner = contract.TransferAsset(ctx, "asset1", "Dr Evil");

            assertThat(oldOwner).isEqualTo("Tomoko");
        }

        @Test
        public void whenAssetDoesNotExist() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("asset1")).thenReturn("");

            Throwable thrown = catchThrowable(() -> {
                contract.TransferAsset(ctx, "asset1", "Dr Evil");
            });

            assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                    .hasMessage("Asset asset1 does not exist");
            assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo("ASSET_NOT_FOUND".getBytes());
        }
    }

    @Nested
    class UpdateAssetTransaction {

        @Test
        public void whenAssetExists() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("asset1"))
                    .thenReturn("{ \"assetID\": \"asset1\", \"color\": \"blue\", \"size\": 45, \"owner\": \"Arturo\", \"appraisedValue\": 60 }");

            Asset asset = contract.UpdateAsset(ctx, "asset1", "pink", 45, "Arturo", 600);

            assertThat(asset).isEqualTo(new Asset("asset1", "pink", 45, "Arturo", 600));
        }

        @Test
        public void whenAssetDoesNotExist() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("asset1")).thenReturn("");

            Throwable thrown = catchThrowable(() -> {
                contract.TransferAsset(ctx, "asset1", "Alex");
            });

            assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                    .hasMessage("Asset asset1 does not exist");
            assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo("ASSET_NOT_FOUND".getBytes());
        }
    }
*/
    @Nested
    class DeleteVoteTransaction {

        @Test
        public void whenVoteDoesNotExist() {
            AssetTransfer contract = new AssetTransfer();
            Context ctx = mock(Context.class);
            ChaincodeStub stub = mock(ChaincodeStub.class);
            when(ctx.getStub()).thenReturn(stub);
            when(stub.getStringState("vote1")).thenReturn("");

            Throwable thrown = catchThrowable(() -> {
                contract.deleteVote(ctx, "vote1");
            });

            assertThat(thrown).isInstanceOf(ChaincodeException.class).hasNoCause()
                    .hasMessage("Vote vote1 does not exist");
            assertThat(((ChaincodeException) thrown).getPayload()).isEqualTo("VOTE_NOT_FOUND".getBytes());
        }
    }
}
