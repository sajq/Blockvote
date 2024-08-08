#!/bin/bash

function createVoteOrg0(){

  echo "Creating Certificate Authorities for VoteOrg1"
  mkdir "participantsOrgranizations/voteOrg1.blockvote.com"

  export CA_VOTEORG0="${PWD}/participantsOrgranizations/voteOrg1.blockvote.com"
  fabric-ca-client enroll -u voteOrg1admin --caname ca-voteorg1 --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "participantsOrgranizations/voteOrg1/voteMSP_config.yaml"


  mkdir "/participantsOrgranizations/voteOrg1.blockvote.com/msp/tlscacerts"
  cp "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "/participantsOrgranizations/voteOrg1.blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "participantsOrgranizations/voteOrg1.blockvote.com/tlsca"
  cp "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "participantsOrgranizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1-cert.pem"

  mkdir "participantsOrgranizations/voteOrg1.blockvote.com/ca"
  cp "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "participantsOrgranizations/voteOrg1.blockvote.com/ca/ca.voteOrg1-cert.pem"

  echo "Registering admin of voteOrg1"
      fabric-ca-client register --id.name admin_voteOrg1 --id.secret adminPsswd --id.type admin --caname ca-voteorg1 --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering participant0"
    fabric-ca-client register --id.name participant0 --id.secret participantPsswd --id.type peer --caname ca-voteorg1 --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering MSP of participant0"
        fabric-ca-client enroll -u voteOrg1admin --caname ca-voteorg1 -M "participantsOrgranizations/voteOrg1/msp" --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering user of voteOrg1"
      fabric-ca-client register --id.name user-voteOrg1 --id.secret userPsswd --id.type user --caname ca-voteorg1 --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg1/voteMSP_config.yaml" "participantsOrgranizations/voteOrg1/msp/config.yaml"

  echo "Registering participant0 tls certificate"
        fabric-ca-client enroll -u voteOrg1-participant0 --caname ca-voteorg1 -M "participantsOrgranizations/voteOrg1/tls" --enrollment.profile tls --csr.hosts voteOrg1 --tls.certifiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg1/tls/tlscacerts/" "participantsOrgranizations/voteOrg1/tls/voteOrg1-ca.crt"
  cp "participantsOrgranizations/voteOrg1/tls/signcerts/" "participantsOrgranizations/voteOrg1/tls/voteOrg1-server.crt"
  cp "participantsOrgranizations/voteOrg1/tls/keystore/" "participantsOrgranizations/voteOrg1/tls/voteOrg1-server.key"

  echo "Registering MSP of user"
    fabric-ca-client enroll -u voteOrg1-user --caname ca-org1 -M "/participantsOrgranizations/voteOrg1/users/user1@voteOrg1.blockvote.com/msp" --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg1/voteMSP_config.yaml" "/participantsOrgranizations/voteOrg1/users/user1@voteOrg1.blockvote.com/msp/config.yaml"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u voteOrg1-admin --caname ca-org1 -M "/participantsOrgranizations/voteOrg1/users/admin@voteOrg1.blockvote.com/msp" --tls.certfiles "participantsOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg1/voteMSP_config.yaml" "/participantsOrgranizations/voteOrg1/users/admin@voteOrg1.blockvote.com/msp/config.yaml"
}

function createVoteOrg1(){

  echo "Creating Certificate Authorities for VoteOrg2"
  mkdir "participantsOrgranizations/voteOrg2.blockvote.com"

  export CA_VOTEORG1="${PWD}/participantsOrgranizations/voteOrg2.blockvote.com"
  fabric-ca-client enroll -u voteOrg2admin --caname ca-voteorg2 --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "participantsOrgranizations/voteOrg2/voteMSP_config.yaml"


  mkdir "/participantsOrgranizations/voteOrg2.blockvote.com/msp/tlscacerts"
  cp "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "/participantsOrgranizations/voteOrg2.blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "participantsOrgranizations/voteOrg2.blockvote.com/tlsca"
  cp "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "participantsOrgranizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2-cert.pem"

  mkdir "participantsOrgranizations/voteOrg2.blockvote.com/ca"
  cp "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "participantsOrgranizations/voteOrg2.blockvote.com/ca/ca.voteOrg2-cert.pem"

  echo "Registering admin of voteOrg2"
      fabric-ca-client register --id.name admin_voteOrg2 --id.secret adminPsswd --id.type admin --caname ca-voteorg2 --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering participant2"
    fabric-ca-client register --id.name participant1 --id.secret participantPsswd --id.type peer --caname ca-voteorg2 --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering MSP of participant2"
        fabric-ca-client enroll -u voteOrg2admin --caname ca-voteorg2 -M "participantsOrgranizations/voteOrg2/msp" --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering user of voteOrg2"
      fabric-ca-client register --id.name user-voteOrg2 --id.secret userPsswd --id.type user --caname ca-voteorg2 --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg2/voteMSP_config.yaml" "participantsOrgranizations/voteOrg2/msp/config.yaml"

  echo "Registering participant1 tls certificate"
        fabric-ca-client enroll -u voteOrg2-participant1 --caname ca-voteorg2 -M "participantsOrgranizations/voteOrg2/tls" --enrollment.profile tls --csr.hosts voteOrg2 --tls.certifiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg2/tls/tlscacerts/" "participantsOrgranizations/voteOrg2/tls/voteOrg2-ca.crt"
  cp "participantsOrgranizations/voteOrg2/tls/signcerts/" "participantsOrgranizations/voteOrg2/tls/voteOrg2-server.crt"
  cp "participantsOrgranizations/voteOrg2/tls/keystore/" "participantsOrgranizations/voteOrg2/tls/voteOrg2-server.key"

  echo "Registering MSP of user"
    fabric-ca-client enroll -u voteOrg2-user --caname ca-org1 -M "/participantsOrgranizations/voteOrg2/users/user1@voteOrg2.blockvote.com/msp" --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg2/voteMSP_config.yaml" "/participantsOrgranizations/voteOrg2/users/user1@voteOrg2.blockvote.com/msp/config.yaml"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u voteOrg2-admin --caname ca-org1 -M "/participantsOrgranizations/voteOrg2/users/admin@voteOrg2.blockvote.com/msp" --tls.certfiles "participantsOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "participantsOrgranizations/voteOrg2/voteMSP_config.yaml" "/participantsOrgranizations/voteOrg2/users/admin@voteOrg2.blockvote.com/msp/config.yaml"
}

function createVoteOrgOrderer(){

  echo "Creating Certificate Authorities for VoteOrg1"
  mkdir "orderersOrgranizations/blockvote.com"

  export CA_ORDERER="${PWD}/orderersOrgranizations/blockvote.com"
  fabric-ca-client enroll -u voteOrg1admin --caname ca-orderer --tls.certfiles "orderersOrgranizations/voteOrderer/voteOrderer-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "orderersOrgranizations/blockvote.com/voteMSP_config.yaml"

  mkdir "/orderersOrgranizations/blockvote.com/msp/tlscacerts"
  cp "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem" "orderersOrgranizations/blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "orderersOrgranizations/blockvote.com/tlsca"
  cp "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem" "orderersOrgranizations/blockvote.com/tlsca/tlsca.orderers-cert.pem"

  mkdir "orderersOrgranizations/blockvote.com/ca"
  cp "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem" "orderersOrgranizations/blockvote.com/ca/ca.orderers-cert.pem"

  echo "Registering admin of orderer"
      fabric-ca-client register --id.name admin_orderer --id.secret adminPsswd --id.type admin --caname ca-orderer --tls.certfiles "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  echo "Registering orderer"
    fabric-ca-client register --id.name orderer --id.secret ordererPsswd --id.type peer --caname ca-orderer --tls.certfiles "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  echo "Registering MSP of orderer"
        fabric-ca-client enroll -u orderer --caname ca-orderer -M "orderersOrgranizations/blockvote.com/msp" --tls.certfiles "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "orderersOrgranizations/blockvote.com/voteMSP_config.yaml" "orderersOrgranizations/blockvote.com/msp/config.yaml"

  echo "Registering orderer tls certificate"
        fabric-ca-client enroll -u orderer --caname ca-orderer -M "orderersOrgranizations/blockvote.com/tls" --enrollment.profile tls --csr.hosts orderer.blockvote.com --tls.certifiles "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "orderersOrgranizations/blockvote.com/tls/tlscacerts/" "orderersOrgranizations/blockvote.com/tls/orderer-ca.crt"
  cp "orderersOrgranizations/blockvote.com/tls/signcerts/" "orderersOrgranizations/blockvote.com/tls/orderer-server.crt"
  cp "orderersOrgranizations/blockvote.com/tls/keystore/" "orderersOrgranizations/blockvote.com/tls/orderer-server.key"

  mkdir "orderersOrgranizations/blockvote.com/msp/tlscacerts"
  cp "orderersOrgranizations/blockvote.com/msp/tlscacerts/" "/orderersOrgranizations/blockvote.com/msp/tlscacerts/tlsca.blockvote.cert.pem"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u ordererAdmin --caname ca-orderer -M "/orderersOrgranizations/blockvote.com/users/admin@orderer.blockvote.com/msp" --tls.certfiles "orderersOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "orderersOrgranizations/blockvote.com/msp/voteMSP_config.yaml" "/orderersOrgranizations/blockvote.com/users/admin@orderer.blockvote.com/msp/config.yaml"
}
