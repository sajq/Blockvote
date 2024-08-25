#!/bin/bash

CC_NAME=${1}
CC_SRC_PATH=${2}
CC_SRC_LANGUAGE=${3}
CC_VERSION=${4}
CC_PACKAGE_ONLY=${5:-false}
CC_RUNTIME_LANGUAGE=java

FABRIC_CFG_PATH=$PWD/votingOrganizations/config

packageChaincode() {

CC_RUNTIME_LANGUAGE=java

echo "Compiling Java code..."
pushd $CC_SRC_PATH
./gradlew installDist
popd
echo "Finished compiling Java code"
CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME

set -x

if [ ${CC_PACKAGE_ONLY} = true ] ; then
    mkdir -p packagedChaincode
    peer lifecycle chaincode package packagedChaincode/${CC_NAME}_${CC_VERSION}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  else
    peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  fi
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)

if [ $res -ne 0 ]; then
  echo "Chaincode packaging failed"
else
  echo "Chaincode is packaged!"
fi
}

packageChaincode

exit 0
