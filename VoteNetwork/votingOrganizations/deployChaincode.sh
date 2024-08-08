#!/bin/bash

CHANNEL_NAME=${1:-"votechannel"}
CC_NAME=${2}
CC_SRC_PATH=${3}
CC_SRC_LANGUAGE=${4}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}
INIT_REQUIRED="--init-required"

if [ "$CC_INIT_FCN" = "NA" ]; then
  INIT_REQUIRED=""
fi

if [ "$CC_END_POLICY" = "NA" ]; then
  CC_END_POLICY=""
else
  CC_END_POLICY="--signature-policy $CC_END_POLICY"
fi

if [ "$CC_COLL_CONFIG" = "NA" ]; then
  CC_COLL_CONFIG=""
else
  CC_COLL_CONFIG="--collections-config $CC_COLL_CONFIG"
fi

FABRIC_CFG_PATH=$PWD/votingOrganizations

source ./votingOrganizations/chaincodeUtils.sh
source ./votingOrganizations/envVar.sh

jq --version > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
 echo "jq command not found..."
 exit 1
fi

./votingOrganizations/chaincodePackage.sh $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION false

PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)

echo "Installing chaincode on participant0.voteOrg1..."
prepareChaincode 1
echo "Install chaincode on participant0.voteOrg2..."
prepareChaincode 2

resolveSequence

chaincodeQueryDeploy 1

chaincodeDefApprove 1

commitTest 1 "\"voteOrg1MSP\": true" "\"voteOrg2MSP\": false"
commitTest 2 "\"voteOrg1MSP\": true" "\"voteOrg2MSP\": false"

chaincodeDefApprove 2

commitTest 1 "\"voteOrg1MSP\": true" "\"voteOrg2MSP\": true"
commitTest 2 "\"voteOrg1MSP\": true" "\"voteOrg2MSP\": true"

chaincodeDefCommit 1 2

queryCommit 1
queryCommit 2

if [ "$CC_INIT_FCN" = "NA" ]; then
  echo "Chaincode initialization is not required"
else
  chaincodeInvoke 1 2
fi

exit 0
