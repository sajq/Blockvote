#!/bin/bash

CHANNEL_NAME=${1:-"votechannel"}
CC_NAME=${2}
CC_SRC_PATH=${3}
CHAINCODE_CHANNEL_DOCKER_RUN=${4:-"true"}
CC_VERSION=${5:-"1.0"}
CC_SEQUENCE=${6:-"1"}
CC_INIT_FCN=${7:-"NA"}
CC_END_POLICY=${8:-"NA"}
CC_COLL_CONFIG=${9:-"NA"}
DELAY=${10:-"3"}
MAX_RETRY=${11:-"5"}
VERBOSE=${12:-"false"}
CHAINCODE_CHANNEL_PORT=9888
MSYS_NO_PATHCONV=1

: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

CONFIG_PATH=/config

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

chaincodePackage() {

  address="{{.peername}}_${CC_NAME}_ccaas:${CHAINCODE_CHANNEL_PORT}"
  prefix=$(basename "$0")
  tempdir=$(mktemp -d -t "$prefix.XXXXXXXX") || error_exit "Error creating temporary directory"
  label=${CC_NAME}_${CC_VERSION}
  mkdir -p "$tempdir/src"

cat > "$tempdir/src/connection.json" <<CONN_EOF
{
  "address": "${address}",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF

   mkdir -p "$tempdir/pkg"

cat << METADATA-EOF > "$tempdir/pkg/metadata.json"
{
    "type": "ccaas",
    "label": "$label"
}
METADATA-EOF

    tar -C "$tempdir/src" -czf "$tempdir/pkg/code.tar.gz" .
    tar -C "$tempdir/pkg" -czf "$CC_NAME.tar.gz" metadata.json code.tar.gz
    rm -Rf "$tempdir"

    PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)

    successln "Chaincode is packaged  ${address}"
}

buildDockerImages() {

  if [ "$CHAINCODE_CHANNEL_DOCKER_RUN" = "true" ]; then
    echo "Building CAAS docker image..."
    ${CONTAINER_CLI} build -f $CC_SRC_PATH/Dockerfile -t ${CC_NAME}_ccaas_image:latest --build-arg CC_SERVER_PORT=9999 $CC_SRC_PATH >&log.txt
    echo "CAAS docket image build succesfully"
  else
    echo "CAAS docket image build error!"
  fi
}

startDockerContainer() {

  if [ "$CHAINCODE_CHANNEL_DOCKER_RUN" = "true" ]; then
    echo "Starting CAAS docker container..."

    ${CONTAINER_CLI} run --rm -d --name participant0voteOrg1_${CC_NAME}_ccaas  \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest

    ${CONTAINER_CLI} run  --rm -d --name participant0voteOrg2_${CC_NAME}_ccaas \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest

    echo "Docker container started succesfully"
  else
    echo "Docker container has not started! Error"
  fi
}

buildDockerImages

chaincodePackage

installChaincode 1
installChaincode 2

resolveSequence

chaincodeQueryDeploy 1

chaincodeDefApprove 1

commitTest 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
commitTest 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

chaincodeDefApprove 2

commitTest 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
commitTest 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

chaincodeDefCommit 1 2

queryCommit 1
queryCommit 2

startDockerContainer

if [ "$CC_INIT_FCN" = "NA" ]; then
  echo "Chaincode initialization is not required"
else
  chaincodeInvoke 1 2
fi

exit 0
