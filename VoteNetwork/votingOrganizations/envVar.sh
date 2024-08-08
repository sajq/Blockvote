#!/bin/bash

votenetwork_home=${PWD}

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${votenetwork_home}/votingOrganizations/orderersOrganizations/blockvote.com/tlsca/tlsca.blockvote.com-cert.pem
export PEER0_ORG1_CA=${votenetwork_home}/votingOrganizations/participantOrganizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1.blockvote.com-cert.pem
export PEER0_ORG2_CA=${votenetwork_home}/votingOrganizations/participantOrganizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2.blockvote.com-cert.pem

# Set environment variables for the peer org
setGlobals() {

echo "votenetwork: " $votenetwork_home

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="voteOrg1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${votenetwork_home}/votingOrganizations/participantOrganizations/voteOrg1.blockvote.com/users/Admin@voteOrg1.blockvote.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="voteOrg2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${votenetwork_home}/votingOrganizations/participantOrganizations/voteOrg2.blockvote.com/users/Admin@voteOrg2.blockvote.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  else
    echo "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}


# Set environment variables for use in the CLI container
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_ADDRESS=participant0.voteOrg1.blockvote.com:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_ADDRESS=participant0.voteOrg2.blockvote.com:9051
  else
    echo "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="participant0.voteOrg$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
