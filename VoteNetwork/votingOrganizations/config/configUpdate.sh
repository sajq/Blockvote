#!/bin/bash

test_network_home=${test_network_home:-${PWD}}
. ${test_network_home}/votingOrganizations/envVar.sh

getChannelConfig(){
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

 set -x
  peer channel fetch config ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com -c $CHANNEL --tls --cafile "$ORDERER_CA"
{ set +x; } 2>/dev/null

 set -x
  configtxlator proto_decode --input ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.pb --type common.Block --output ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.json
  jq .data.data[0].payload.data.config ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.json > ${PWD}/votingOrganizations/channel-artifacts/"${OUTPUT}"
  { set +x; } 2>/dev/null
}

createChannelConfig(){
  CHANNEL=$1
  FIRST=$2
  MOD=$3
  OUTPUT=$4
  
  echo "Channel artifacts test gen"

  set -x
  configtxlator proto_encode --input ${PWD}/votingOrganizations/channel-artifacts/"${FIRST}" --type common.Config --output ${PWD}/votingOrganizations/channel-artifacts/first_config.pb
  configtxlator proto_encode --input ${PWD}/votingOrganizations/channel-artifacts/"${MOD}" --type common.Config --output ${PWD}/votingOrganizations/channel-artifacts/mod_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original ${PWD}/votingOrganizations/channel-artifacts/first_config.pb --updated ${PWD}/votingOrganizations/channel-artifacts/mod_config.pb --output ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.pb
  configtxlator proto_decode --input ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.pb --type common.ConfigUpdate --output ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.json)'}}}' | jq . > ${PWD}/votingOrganizations/channel-artifacts/blockvote_config_in_envelope.json
  configtxlator proto_encode --input ${PWD}/votingOrganizations/channel-artifacts/blockvote_config_in_envelope.json --type common.Envelope --output ${PWD}/votingOrganizations/channel-artifacts/"${OUTPUT}"
  { set +x; } 2>/dev/null
}

signConfig(){
  ORG=$1
  CONFIGTXFILE=$2
  set -x
  peer channel signconfigtx -f "${$1}"
  { set +x; } 2>/dev/null
}
