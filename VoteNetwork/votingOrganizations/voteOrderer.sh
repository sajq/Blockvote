#!/bin/bash

channelN=$1

export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/votingOrganizations/ordererOrganizations/blockvote.com/orderers/orderer.blockvote.com/tls/server.crt /dev/null 2>&1
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/votingOrganizations/ordererOrganizations/blockvote.com/orderers/orderer.blockvote.com/tls/server.key /dev/null 2>&1

osnadmin channel join --channelID ${channelN} --config-block ./votingOrganizations/channel-artifacts/${channelN}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >> log.txt 2>&1
