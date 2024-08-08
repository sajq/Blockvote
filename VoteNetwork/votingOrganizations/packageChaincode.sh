#!/bin/bash

CC_NAME=${1}
CC_SRC_PATH=${2}
CC_SRC_LANGUAGE=${3}
CC_VERSION=${4}
CC_PACKAGE_ONLY=${5:-false}

CONFIG_PATH=/config

CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

if [ ${CC_PACKAGE_ONLY} = true ] ; then
  mkdir -p packagedChaincode
  peer lifecycle chaincode package packagedChaincode/${CC_NAME}_${CC_VERSION}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
else
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
fi
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  echo "Chaincode is packaged"

exit 0