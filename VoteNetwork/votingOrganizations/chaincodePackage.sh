#!/bin/bash

CHAINCODE_NAME=$1
CHAINCODE_PATH=$2
CHAINCODE_LANG=$3
CHAINCODE_VER=$4
CHAINCODE_PCKG_STATUS=$5
CHAINCODE_RUNTIME_LANG=java

FABRIC_CFG_PATH=$PWD/votingOrganizations/config

if [ ${CHAINCODE_PCKG_STATUS} = true ] ; then
    mkdir -p packagedChaincode
    peer lifecycle chaincode package packagedChaincode/${CHAINCODE_NAME}_${CHAINCODE_VER}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_RUNTIME_LANG} --label ${CHAINCODE_NAME}_${CHAINCODE_VER} >&log.txt
else
    peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path ${CHAINCODE_PATH} --lang ${CHAINCODE_LANG} --label ${CHAINCODE_NAME}_${CHAINCODE_VER} >&log.txt
fi

PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CHAINCODE_NAME}.tar.gz)

echo "Chaincode is packaged"

exit 0
