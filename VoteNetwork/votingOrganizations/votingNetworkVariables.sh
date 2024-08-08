#!/bin/bash

NET_HOME=${PWD}

export TLS_STATUS=true
export CA_ORDERER=/votingOrganizations/ordererOrganizations/blockvote.com/orderersOrgranizations/tlscerts/tlscert.pem
export CA_PARTICIPANT_ORG0=/votingOrganizations/participantsOrgranizations/voteOrg0.blockvote.com/tlsca/tlsca.voteOrg0-cert.pem
export CA_PARTICIPANT_ORG1=/votingOrganizations/participantsOrgranizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1-cert.pem
export CA_PARTICIPANT_ORG2=/votingOrganizations/participantsOrgranizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2-cert.pem

configureGlobalVars(){
  local ORG=$1
  export PARTICIPANT=voteOrg${ORG}MSP
  export PARTICIPANT_TLS=/votingOrganizations/participantsOrgranizations/voteOrg${ORG}.blockvote.com/tlsca/tlsca.voteOrg${ORG}-cert.pem
  export PARTICIPANT_MSPPATH=${TEST_NETWORK_HOME}/votingOrganizations/participantsOrgranizations/voteOrg${ORG}.blockvote.com/users/Admin@voteOrg${ORG}.blockvote.com/msp
  export PARTICIPANT_ADDRESSPORT=localhost:705${ORG}
}

participantConnectionParametersCheck(){
   PARTICIPANT_CONN_PARMS=()
   PARTICIPANTS=""
    while [ "$#" -gt 0 ]; do
      setGlobals $1
      PARTICIPANT="participant0.voteOrg$1"

      if [ -z "PARTICIPANTS" ]
      then
  	    PARTICIPANTS="$PARTICIPANT"
      else
  	    PARTICIPANTS="$PARTICIPANTS $PARTICIPANT"
      fi
      PARTICIPANT_CONN_PARMS=("${PARTICIPANT_CONN_PARMS[@]}" --peerAddresses $PARTICIPANT_ADDRESSPORT)

      CA=PARTICIPANT0_voteOrg$1_CA
      TLSINFO=(--tlsRootCertFiles "${!CA}")
      PARTICIPANT_CONN_PARMS=("${PARTICIPANT_CONN_PARMS[@]}" "${TLSINFO[@]}")

      shift
    done
}
