#!/bin/bash

CHAINCODE_NAME=$1
CHAINCODE_PATH=$2
CHAINCODE_LANG=$3
CHAINCODE_VER=$4
CHAINCODE_PCKG_STATUS=${5:-false}
CHAINCODE_RUNTIME_LANG=java

FABRIC_CFG_PATH=$PWD/votingOrganizations/config

packageChaincode() {

CC_RUNTIME_LANGUAGE=java

echo "Compiling Java code..."
pushd $CHAINCODE_PATH
./gradlew installDist
popd
echo "Finished compiling Java code"
CHAINCODE_PATH=$CHAINCODE_PATH/build/install/$CHAINCODE_NAME

set -x

if [ ${CHAINCODE_PCKG_STATUS} = true ] ; then
    mkdir -p packagedChaincode
    peer lifecycle chaincode package packagedChaincode/${CHAINCODE_NAME}_${CHAINCODE_VER}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_RUNTIME_LANG} --label ${CHAINCODE_NAME}_${CHAINCODE_VER} >&log.txt
else
    peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_NAME}_${CHAINCODE_VER} >&log.txt
fi
res=$?
{ set +x; } 2>/dev/null
cat log.txt
PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_NAME}.tar.gz)

if [ $res -ne 0 ]; then
  echo "Chaincode packaging failed"
else
  echo "Chaincode is packaged!"
fi
}

packageChaincode

exit 0
