#!/bin/bash

. votingOrganizations/config/configUpdate.sh
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}

createBaseParticipantUpdate(){

  getChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

    if [ $ORG -eq 1 ]; then
      HOST="peer0.voteOrg1.blockvote.com"
      PORT=7051
    elif [ $ORG -eq 2 ]; then
      HOST="peer0.voteOrg2.blockvote.com"
      PORT=9051
    fi

    set -x
   jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'}]},"version": "0"}}' ${TEST_NETWORK_HOME}/votingOrganizations/channel-artifacts/${CORE_PEER_LOCALMSPID}config.json > ${TEST_NETWORK_HOME}/votingOrganizations/channel-artifacts/${CORE_PEER_LOCALMSPID}modified_config.json
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
        echo "Channel configuration update for anchor peer failed, make sure you have jq installed"
      fi

    createChannelConfig ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
}

ORG=$1
CHANNEL_NAME=$2

setGlobalsCLI $ORG

createBaseParticipantUpdate

updateAnchorPeer
