#!/bin/bash

NET_HOME=${PWD}

export TLS_STATUS=true
export CA_ORDERER=${NET_HOME}/votingOrganizations/ordererOrganizations/blockvote.com/tlsca/tlsca.blockvote.com-cert.pem
export CA_PARTICIPANT_ORG0=${NET_HOME}/votingOrganizations/peerOrgranizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1-cert.pem
export CA_PARTICIPANT_ORG1=${NET_HOME}/votingOrganizations/peerOrgranizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2-cert.pem
export CA_PARTICIPANT_ORG2=${NET_HOME}/votingOrganizations/peerOrgranizations/voteOrg3.blockvote.com/tlsca/tlsca.voteOrg3-cert.pem

configureGlobalVars(){

  echo "test3" 
  echo "${NET_HOME}"
  local ORG=$1
  export PARTICIPANT=voteOrg${ORG}MSP
  export PARTICIPANT_TLS=${NET_HOME}/votingOrganizations/peerOrgranizations/voteOrg${ORG}.blockvote.com/tlsca/tlsca.voteOrg${ORG}-cert.pem
  export PARTICIPANT_MSPPATH=${NET_HOME}/votingOrganizations/peerOrgranizations/voteOrg${ORG}.blockvote.com/users/Admin@voteOrg${ORG}.blockvote.com/msp
  export PARTICIPANT_ADDRESSPORT=localhost:705${ORG}
}

participantConnectionParametersCheck(){
   PARTICIPANT_CONN_PARMS=()
   PARTICIPANTS=""
    while [ "$#" -gt 0 ]; do
      setGlobals $1
      PARTICIPANT="peer0.voteOrg$1"

      if [ -z "PARTICIPANTS" ]
      then
  	    PARTICIPANTS="$PARTICIPANT"
      else
  	    PARTICIPANTS="$PARTICIPANTS $PARTICIPANT"
      fi
      PARTICIPANT_CONN_PARMS=("${PARTICIPANT_CONN_PARMS[@]}" --peerAddresses $PARTICIPANT_ADDRESSPORT)

      CA=PEER0_voteOrg$1_CA
      TLSINFO=(--tlsRootCertFiles "${!CA}")
      PARTICIPANT_CONN_PARMS=("${PARTICIPANT_CONN_PARMS[@]}" "${TLSINFO[@]}")

      shift
    done
}
