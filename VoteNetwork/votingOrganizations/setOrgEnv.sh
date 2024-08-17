#!/bin/bash

ORG=${1:-voteOrg1}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "test3" $DIR

ORDERER_CA=${DIR}/votingOrganizations/ordererOrganizations/blockvote.com/tlsca/tlsca.blockvote.com-cert.pem
PEER0_ORG1_CA=${DIR}/votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1.blockvote.com-cert.pem
PEER0_ORG2_CA=${DIR}/votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2.blockvote.com-cert.pem

if [[ ${ORG,,} == "voteOrg1" || ${ORG,,} == "digibank" ]]; then

   CORE_PEER_LOCALMSPID=voteOrg1MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/users/Admin@voteOrg1.blockvote.com/msp
   CORE_PEER_ADDRESS=localhost:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1.blockvote.com-cert.pem

elif [[ ${ORG,,} == "voteOrg2" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=voteOrg2MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/users/Admin@voteOrg2.blockvote.com/msp
   CORE_PEER_ADDRESS=localhost:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2.blockvote.com-cert.pem

else
   echo "Unknown \"$ORG\", please choose Org1/Digibank or Org2/Magnetocorp"
   exit 1
fi

echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_ORG1_CA=${PEER0_ORG1_CA}"
echo "PEER0_ORG2_CA=${PEER0_ORG2_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
