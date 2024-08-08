#!/bin/bash

getChannelConfig(){
  ORG=$1
  CHANNEL_NAME=$2
  OUTPUT=$3

  peer channel fetch config ${PWD}/votingOrganizations/channel-artificats/blockvote_config.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com -c $CHANNEL_NAME --tls --cafile "$CA_ORDERER"

  configtxlator proto_decode --input ${PWD}/votingOrganizations/channel-artifacts/blockvote_config.pb --type common.Block --output ${PWD}/votingOrganizations/channel-artifacts/config_blockvote.json
  jq .data.data[0].payload.data.config ${PWD}/votingOrganizations/channel-artifacts/config_block.json >"${OUTPUT}"
}

createChannelConfig(){
  CHANNEL_NAME=$1
  FIRST=$2
  MOD=$3
  OUTPUT=$4
  
  echo "Channel artifacts test gen"

  configtxlator proto_encode --input "${FIRST}" --type common.Config --output ${PWD}/votingOrganizations/channel-artifacts/first_config.pb
  configtxlator proto_encode --input "${MOD}" --type common.Config --output ${PWD}/votingOrganizations/channel-artifacts/mod_config.pb
  configtxlator compute_update --channel_id "${CHANNEL_NAME}" --original ${PWD}/votingOrganizations/channel-artifacts/first_config.pb --updated ${PWD}/votingOrganizations/channel-artifacts/modified_config.pb --output ${PWD}/votingOrganizations/channel-artifacts/config_update.pb
  configtxlator proto_decode --input ${PWD}/votingOrganizations/channel-artifacts/config_update.pb --type common.ConfigUpdate --output ${PWD}/votingOrganizations/channel-artifacts/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat ${PWD}/votingOrganizations/channel-artifacts/config_update.json)'}}}' | jq . > ${PWD}/votingOrganizations/channel-artifacts/config_update_in_envelope.json
  configtxlator proto_encode --input ${PWD}/votingOrganizations/channel-artifacts/config_update_in_envelope.json --type common.Envelope --output "${OUTPUT}"
}

signConfig(){
  peer channel signconfigtx -f "${$1}"
}
