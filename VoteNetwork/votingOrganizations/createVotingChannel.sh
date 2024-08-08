#!/bin/bash

. votingOrganizations/envVar.sh
. votingOrganizations/votingNetworkVariables.sh

CHANNEL_NAME=$1
DELAY=$2
MAX_RETRY_ATTEMPTS=$3
CHANNEL_DETAILS=$4
BYZANTINEF_TOLERANCE=$5
CONTAINER_CLI="docker"
: ${BYZANTINEF_TOLERANCE:=0}
: ${CHANNEL_NAME:="votechannel"}

if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
    echo "Using docker-compose"
else
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
    echo "Using docker compose"
fi

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

generateChannelsGenBlock(){
  configureGlobalVars 1
  setGlobals 1

  local bft=$1
  echo $FABRIC_CFG_PATH

  echo "Generating Genesis Block..."
  
  set -x
  if [ $bft -eq 1 ]; then
      configtxgen -profile ChannelUsingBFT -outputBlock ./votingOrganizations/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
  else
      configtxgen -profile ChannelUsingRaft -outputBlock ./votingOrganizations/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
  fi
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
  	echo $res "Channel Gen Block creation failed"
  fi
}

createChannel(){
 
 	local rc=1
	local COUNTER=1
	local bft_true=$1
	echo "Adding orderer..."
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY_ATTEMPTS ] ; do
		sleep $DELAY
		set -x
    		. votingOrganizations/voteOrderer.sh ${CHANNEL_NAME}> /dev/null 2>&1
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	if [ $res -ne 0 ]; then
  	echo $res "Channel creation failed"
	fi
}

joinChannel(){
  ORG=$1
  setGlobals $ORG

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY_ATTEMPTS ] ; do
    sleep $DELAY
    echo "join test"
    set -x
    	peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  
  if [ $res -ne 0 ]; then
  	echo "After $MAX_RETRY_ATTEMPTS attempts, participant0.voteOrg${ORG} has failed to join channel '$CHANNEL_NAME' "
  fi
}

setBaseParticipant(){
  ORG=$1
  . votingOrganizations/setBaseParticipant.sh $ORG $CHANNEL_NAME
}

FABRIC_CFG_PATH=./config
BLOCKFILE=./votingOrganizations/channel-artifacts/${CHANNEL_NAME}.block

if [ $BYZANTINEF_TOLERANCE -eq 1 ]; then
  FABRIC_CFG_PATH=./bft-config
fi

generateChannelsGenBlock $BYZANTINEF_TOLERANCE

createChannel $BYZANTINEF_TOLERANCE

joinChannel 1
joinChannel 2

setBaseParticipant 1
setBaseParticipant 2

echo "Channels creation done."
