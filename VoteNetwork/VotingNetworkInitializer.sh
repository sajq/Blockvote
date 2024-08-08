#!/bin/bash

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/votingOrganizations/config

pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="docker-compose"}
echo "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

function clearContainers() {
  echo "Removing remaining containers"
  docker rm -f $(docker ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  docker rm -f $(docker ps -aq --filter name='dev-peer*') 2>/dev/null || true
  docker kill "$(docker ps -q --filter name=ccaas)" 2>/dev/null || true
}

function removeUnwantedImages() {
  echo "Removing generated chaincode docker images"
  docker image rm -f $(docker images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

NONWORKING_VERSIONS="^1\.0\. ^1\.1\. ^1\.2\. ^1\.3\. ^1\.4\."

function installPrereqs() {

 echo "Installing prerequisites..."
 
 IMAGE_PAR=""
 if [ "$IMAGETAG" != "default" ]; then
  IMAGE_PAR="-f ${IMAGETAG}"
 fi
 
 CA_IMAGE_PAR=""
 if [ "$CA_IMAGETAG" != "default" ]; then
  CA_IMAGE_PAR="-c ${CA_IMAGETAG}"
 fi
 
 ./install-fabric.sh ${IMAGE_PAR} ${CA_IMAGE_PAR} docker binary
 
}

function checkPrerequistes() {
  
  peer version > /dev/null 2>&1

  if [[ $? -ne 0 ||  ! -d "./votingOrganizations/config/" ]]; then
    echo "Configuration and binary files not found.."
    exit 1
  fi

  LOCAL_VERSION=$(peer version | sed -ne 's/^ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-peer:latest peer version | sed -ne 's/^ Version: //p')

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "Local fabric binaries and docker images are out of  sync. This may cause problems."
  fi

  for UNSUPPORTED_VERSION in $NONWORKING_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "Local Fabric binary version of $LOCAL_VERSION does not match the versions supported by the voting network."
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match the versions supported by the voting network."
    fi
  done

  if [ "$CRYPTO" == "cfssl" ]; then

    echo "Using cfssl crypto generator"

    cfssl version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "cfssl binary could not be found.."
      exit 1
    fi
  fi

  if [ "$CRYPTO" == "Certificate Authorities" ]; then
 
    echo "Using Certificate Authorities crypto generator"

    fabric-ca-client version > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "fabric-ca-client binary not found.."
      exit 1
    fi
    CA_LOCAL_VERSION=$(fabric-ca-client version | sed -ne 's/ Version: //p')
    CA_DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-ca:latest fabric-ca-client version | sed -ne 's/ Version: //p' | head -1)

    if [ "$CA_LOCAL_VERSION" != "$CA_DOCKER_IMAGE_VERSION" ]; then
      echo "Local fabric-ca binaries and docker images have different versions installed! Potential error"
    fi
  fi
  
  echo "Prerequisites check finished successfuly"
}

function createVotingOrganizations(){

    echo "Creating voting orgs..."

    if [ -d "votingOrganizations/participantOrganizations" ]; then
    	echo "Deleting existing organizations files.."
    	rm -rf votingOrganizations/pariticpantOrganizations
    	rm -rf votingOrganizations/orderersOrganizations
    fi
    
    if [ ! -d "votingOrganizations/peerOrganizations/voteOrg1.blockvote.com" ]; then
    	echo "kill me"
      fi
	
    if [ "$CRYPTO" == "cryptogen" ]; then
    
      echo "Using cryptogen"
      #creation of minimum of two voting organizations
      
      echo "Creation of new voting organization no.1 ..."
      set -x
      cryptogen generate --config=./votingOrganizations/cryptogen/voteOrg1-config.yaml --output="votingOrganizations"
      res=$?
      { set +x; } 2>/dev/null
      if [ $res -ne 0 ]; then
        echo "Failed to generate certificates org1..."
      fi
      
      echo "Creation of new voting organization no.2 ..."
      set -x
      cryptogen generate --config=./votingOrganizations/cryptogen/voteOrg2-config.yaml --output="votingOrganizations"
      res=$?
      { set +x; } 2>/dev/null
      if [ $res -ne 0 ]; then
        echo "Failed to generate certificates org2..."
      else
        echo "Two new voting organizations have been created."
      fi
      

      #creation of orderers
      echo "Creation of new orderers..."
      set -x
      cryptogen generate --config=./votingOrganizations/cryptogen/voteOrderer-config.yaml --output="votingOrganizations"
      res=$?
      { set +x; } 2>/dev/null
      if [ $res -ne 0 ]; then
        echo "Failed to generate certificates for orderer..."
      fi
      echo "Orderer has been created."
      
      if [ -d "votingOrganizations/peerOrganizations/voteOrg1.blockvote.com" ]; then
    	echo "exists 1"
      fi
      
      if [ ! -d "votingOrganizations/participantOrganizations/voteOrg1.blockvote.com" ]; then
        echo "Creating participant catalogues"
    	mkdir -p votingOrganizations/participantOrganizations/voteOrg1.blockvote.com
    	mkdir -p votingOrganizations/participantOrganizations/voteOrg2.blockvote.com
    	mkdir -p votingOrganizations/orderersOrganizations/blockvote.com
    	
    	echo "Moving newly created organizations files..."
      mv votingOrganizations/peerOrganizations/voteOrg1.blockvote.com votingOrganizations/participantOrganizations
      mv votingOrganizations/peerOrganizations/voteOrg2.blockvote.com votingOrganizations/participantOrganizations
      mv votingOrganizations/ordererOrganizations/blockvote.com votingOrganizations/orderersOrganizations
      	rm -r votingOrganizations/peerOrganizations
      	rm -r votingOrganizations/ordererOrganizations
      fi

    elif [ "$CRYPTO" == "cfssl" ]; then
      . votingOrganizations/certificates.sh
      
      echo "Using cfssl"

      echo "Creation of new voter and admin for organization vote0."
      participants_certs_creation admin admin.voteOrg0.blockvote.com voteOrg0
      participants_certs_creation participant participant10.voteOrg0.blockvote.com voteOrg0

      echo "Creation of new voter and admin for organization vote1."
      participants_certs_creation admin admin.voteOrg1.blockvote.com voteOrg1
      participants_certs_creation participant participant0.voteOrg1.blockvote.com voteOrg1

      echo "Creation of new orderer and admin for organization vote1."
      orderers_certs_creation admin admin.voteOrg1.blockvote.com
      orderers_certs_creation orderer voter2.voteOrg1.blockvote.com

    elif [ "$CRYPTO" == "CA" ]; then

      echo "Creation of Fabric Certificate Authorities"
      . votingOrganizations/certificates.sh

      createVoteOrg0
      createVoteOrg1
      createVoteOrgOrderer
    fi
      
    echo "Generating CCP files for voting organizations"
    ./votingOrganizations/ccp-script.sh
    
}

function createVotingChannel(){

  networkStatus="false"

  if ! $CONTAINER_CLI info > /dev/null 2>&1 ; then
    echo "Network is not running!"
  fi

  CONTAINERS=($($CONTAINER_CLI ps | grep hyperledger/ | awk '{print $2}'))
  len=$(echo ${#CONTAINERS[@]})
  echo $len

  if [[ $len -ge 4 ]] && [[ ! -d "votingOrganizations/participantOrganizations" ]]; then
    echo "Synchronization of certificates and containers"
    networkDown
  fi

  [[ $len -lt 4 ]] || [[ ! -d "votingOrganizations/participantOrganizations" ]] && networkStatus="true" || echo "Network online."

  echo $networkStatus
  if [ $networkStatus == "true"  ]; then
    echo "Starting network"
    startNetwork
  fi

  ./votingOrganizations/createVotingChannel.sh $CHANNEL_NAME $CLI_DELAY $MAX_RETRY $VERBOSE $bft_true

}

function startNetwork(){

  checkPrerequistes

  if [ ! -d "votingOrganizations/participantOrganizations" ]; then
    echo "Did not found files related to any voting organization! Creating organizations files"
      createVotingOrganizations
  fi
  
  COMPOSE_FILES="-f compose/${COMPOSE_FILE_BASE} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE}"

  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"
  fi
 
  echo "${DOCKER_SOCKET}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} 
 
  DOCKER_SOCKET="${DOCKER_SOCKET}" ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} up 2>&1

  $CONTAINER_CLI ps -a
  if [ $? -ne 0 ]; then
      echo "Network has not been started due to an error"
  else
      echo "Network started successfuly"
  fi
  
  sleep 5
  
  $CONTAINER_CLI ps -a
}

function deployChaincode(){

 echo "Deploying chaincode..."

  ./votingOrganizations/deployChaincode.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE
  
  echo "Chaincode deployment complete"
}

function deployChaincodeInChannel(){
  votingOrganizations/deployChaincodeinChannel.sh $CHANNEL_NAME $CC_NAME $CC_SRC_PATH $CHAINCODE_CHANNEL_DOCKER_RUN $CC_VERSION $CC_SEQUENCE $CC_INIT_FCN $CC_END_POLICY $CC_COLL_CONFIG $CLI_DELAY $MAX_RETRY $VERBOSE $CHAINCODE_CHANNEL_DOCKER_RUN
  
  if [ $? -ne 0 ]; then
    echo "Deploying chaincode-as-a-service failed"
  fi
}

function packageChaincode(){
  votingOrganizations/packageChaincode.sh $CC_NAME $CC_SRC_PATH $CC_SRC_LANGUAGE $CC_VERSION true
  
  if [ $? -ne 0 ]; then
    echo "Packaging the chaincode failed"
  fi
}

function listChaincode() {

  export FABRIC_CFG_PATH=${PWD}/votingOrganizations/config
  
  . votingOrganizations/envVar.sh
  . votingOrganizations/chaincodeUtils.sh

  queryInstalledOnPeer

  listAllCommitted

}

function invokeChaincode() {

  export FABRIC_CFG_PATH=${PWD}/votingOrganizations/config
  
  . votingOrganizations/envVar.sh
  . votingOrganizations/chaincodeUtils.sh

  chaincodeInvoke $ORG $CHANNEL_NAME $CC_NAME $CC_INVOKE_CONSTRUCTOR

}

function queryChaincode() {

  export FABRIC_CFG_PATH=${PWD}/votingOrganizations/config
  
  . votingOrganizations/envVar.sh
  . votingOrganizations/chaincodeUtils.sh

  chaincodeQuery $ORG $CHANNEL_NAME $CC_NAME $CC_QUERY_CONSTRUCTOR

}

function networkDown() {

  COMPOSE_FILE_BASE_LOCAL=compose-bft-vote-net.yaml
  COMPOSE_BASE_FILES="-f compose/${COMPOSE_FILE_BASE_LOCAL} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_BASE_LOCAL}"
  COMPOSE_COUCH_FILES="-f compose/${COMPOSE_FILE_COUCH} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_COUCH}"
  COMPOSE_CA_FILES="-f compose/${COMPOSE_FILE_CA} -f compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_CA}"
  COMPOSE_FILES="${COMPOSE_BASE_FILES} ${COMPOSE_COUCH_FILES} ${COMPOSE_CA_FILES}"

  COMPOSE_ORG3_BASE_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_BASE} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_BASE}"
  COMPOSE_ORG3_COUCH_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_COUCH} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_COUCH}"
  COMPOSE_ORG3_CA_FILES="-f addOrg3/compose/${COMPOSE_FILE_ORG3_CA} -f addOrg3/compose/${CONTAINER_CLI}/${CONTAINER_CLI}-${COMPOSE_FILE_ORG3_CA}"
  COMPOSE_ORG3_FILES="${COMPOSE_ORG3_BASE_FILES} ${COMPOSE_ORG3_COUCH_FILES} ${COMPOSE_ORG3_CA_FILES}"

  if [ "${CONTAINER_CLI}" == "docker" ]; then
    DOCKER_SOCKET=$DOCKER_SOCKET ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes --remove-orphans
  elif [ "${CONTAINER_CLI}" == "podman" ]; then
    ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES} ${COMPOSE_ORG3_FILES} down --volumes
  else
    fatalln "Container CLI  ${CONTAINER_CLI} not supported"
  fi

  if [ "$MODE" != "restart" ]; then

    ${CONTAINER_CLI} volume rm docker_orderer.blockvote.com docker_participant0.voteOrg1.blockvote.com docker_participant0.voteOrg2.blockvote.com

    clearContainers
    removeUnwantedImages

    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/participantOrganizations organizations/orderersOrganization'

    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf votingOrganizations/fabric-ca/org1/msp votingOrganizations/fabric-ca/org1/tls-cert.pem votingOrganizations/fabric-ca/org1/ca-cert.pem votingOrganizations/fabric-ca/org1/IssuerPublicKey votingOrganizations/fabric-ca/org1/IssuerRevocationPublicKey votingOrganizations/fabric-ca/org1/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf votingOrganizations/fabric-ca/org2/msp votingOrganizations/fabric-ca/org2/tls-cert.pem votingOrganizations/fabric-ca/org2/ca-cert.pem votingOrganizations/fabric-ca/org2/IssuerPublicKey votingOrganizations/fabric-ca/org2/IssuerRevocationPublicKey votingOrganizations/fabric-ca/org2/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf votingOrganizations/fabric-ca/ordererOrg/msp votingOrganizations/fabric-ca/ordererOrg/tls-cert.pem votingOrganizations/fabric-ca/ordererOrg/ca-cert.pem votingOrganizations/fabric-ca/ordererOrg/IssuerPublicKey votingOrganizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey votingOrganizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'

    ${CONTAINER_CLI} run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi
}

. ./network.config


COMPOSE_FILE_BASE=compose-vote-net.yaml
COMPOSE_FILE_COUCH=compose-couch.yaml
COMPOSE_FILE_CA=compose-ca.yaml
COMPOSE_FILE_ORG3_BASE=compose-org3.yaml
COMPOSE_FILE_ORG3_COUCH=compose-couch-org3.yaml
COMPOSE_FILE_ORG3_CA=compose-ca-org3.yaml

SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCKET="${SOCK##unix://}"

BIZANTINE_FAULT_TOLERANCE=0

if [[ $# -lt 1 ]] ; then
  echo "test"
  exit 0
else
  MODE=$1
  shift
fi

if [ "$MODE" == "cc" ] && [[ $# -lt 1 ]]; then
  echo $MODE
  exit 0
fi

if [[ $# -ge 1 ]] ; then
  key="$1"
  if [[ "$key" == "createChannel" ]]; then
      export MODE="createChannel"
      shift
  elif [[ "$MODE" == "cc" ]]; then
    if [ "$1" != "-h" ]; then
      export SUBCOMMAND=$key
      shift
    fi
  fi
fi


while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    echo $MODE
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -bft )
    BFT=1
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -cfssl )
    CRYPTO="cfssl"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    CLI_DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -ccl )
    CC_SRC_LANGUAGE="$2"
    shift
    ;;
  -ccn )
    CC_NAME="$2"
    shift
    ;;
  -ccv )
    CC_VERSION="$2"
    shift
    ;;
  -ccs )
    CC_SEQUENCE="$2"
    shift
    ;;
  -ccp )
    CC_SRC_PATH="$2"
    shift
    ;;
  -ccep )
    CC_END_POLICY="$2"
    shift
    ;;
  -cccg )
    CC_COLL_CONFIG="$2"
    shift
    ;;
  -cci )
    CC_INIT_FCN="$2"
    shift
    ;;
  -ccaasdocker )
    CCAAS_DOCKER_RUN="$2"
    shift
    ;;
  -verbose )
    VERBOSE=true
    ;;
  -org )
    ORG="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -cai )
    CA_IMAGETAG="$2"
    shift
    ;;
  -ccic )
    CC_INVOKE_CONSTRUCTOR="$2"
    shift
    ;;
  -ccqc )
    CC_QUERY_CONSTRUCTOR="$2"
    shift
    ;;
  * )
    echo "Key error"
    exit 1
    ;;
  esac
  shift
done

if [[ $BIZANTINE_FAULT_TOLERANCE -eq 1 && "$CRYPTO" == "Certificate Authorities" ]]; then
  echo "This sample does not yet support the use of consensus type BFT and CA together."
fi

if [ $BIZANTINE_FAULT_TOLERANCE -eq 1 ]; then
  export CONFIG_PATH=${PWD}/bft-config
  COMPOSE_FILE_BASE=compose-bft-vote-net.yaml
fi

if [ ! -d "votingOrganizations/participantOrganizations" ]; then
  CRYPTO_MODE="with crypto from '${CRYPTO}'"
else
  CRYPTO_MODE=""
fi

if [ "$MODE" == "prereq" ]; then
  installPrereqs
elif [ "$MODE" == "up" ]; then
  echo "Starting network"
  startNetwork
elif [ "$MODE" == "createChannel" ]; then
  echo "Creating channel '${CHANNEL_NAME}'."
  createVotingChannel $BIZANTINE_FAULT_TOLERANCE
elif [ "$MODE" == "down" ]; then
  echo "Stopping network"
  networkDown
elif [ "$MODE" == "restart" ]; then
  echo "Restarting network"
  networkDown
  networkUp
elif [ "$MODE" == "deployChaincode" ]; then
  deployChaincode
elif [ "$MODE" == "deployCCAAS" ]; then
  deployChaincodeInChannel
elif [ "$MODE" == "cc" ] && [ "$SUBCOMMAND" == "package" ]; then
  packageChaincode
elif [ "$MODE" == "cc" ] && [ "$SUBCOMMAND" == "list" ]; then
  listChaincode
elif [ "$MODE" == "cc" ] && [ "$SUBCOMMAND" == "invoke" ]; then
  invokeChaincode
elif [ "$MODE" == "cc" ] && [ "$SUBCOMMAND" == "query" ]; then
  queryChaincode
else
  exit 1
fi


