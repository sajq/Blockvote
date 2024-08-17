#!/bin/bash

function createVoteOrg0(){

  echo "Creating Certificate Authorities for VoteOrg1"
  mkdir "peerOrgranizations/voteOrg1.blockvote.com"

  export CA_VOTEORG0="${PWD}/peerOrgranizations/voteOrg1.blockvote.com"
  fabric-ca-client enroll -u voteOrg1admin --caname ca-voteorg1 --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "peerOrgranizations/voteOrg1/voteMSP_config.yaml"


  mkdir "/peerOrgranizations/voteOrg1.blockvote.com/msp/tlscacerts"
  cp "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "/peerOrgranizations/voteOrg1.blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "peerOrgranizations/voteOrg1.blockvote.com/tlsca"
  cp "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "peerOrgranizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1-cert.pem"

  mkdir "peerOrgranizations/voteOrg1.blockvote.com/ca"
  cp "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem" "peerOrgranizations/voteOrg1.blockvote.com/ca/ca.voteOrg1-cert.pem"

  echo "Registering admin of voteOrg1"
      fabric-ca-client register --id.name admin_voteOrg1 --id.secret adminPsswd --id.type admin --caname ca-voteorg1 --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering participant0"
    fabric-ca-client register --id.name participant0 --id.secret participantPsswd --id.type peer --caname ca-voteorg1 --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering MSP of participant0"
        fabric-ca-client enroll -u voteOrg1admin --caname ca-voteorg1 -M "peerOrgranizations/voteOrg1/msp" --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  echo "Registering user of voteOrg1"
      fabric-ca-client register --id.name user-voteOrg1 --id.secret userPsswd --id.type user --caname ca-voteorg1 --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg1/voteMSP_config.yaml" "peerOrgranizations/voteOrg1/msp/config.yaml"

  echo "Registering participant0 tls certificate"
        fabric-ca-client enroll -u voteOrg1-participant0 --caname ca-voteorg1 -M "peerOrgranizations/voteOrg1/tls" --enrollment.profile tls --csr.hosts voteOrg1 --tls.certifiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg1/tls/tlscacerts/" "peerOrgranizations/voteOrg1/tls/voteOrg1-ca.crt"
  cp "peerOrgranizations/voteOrg1/tls/signcerts/" "peerOrgranizations/voteOrg1/tls/voteOrg1-server.crt"
  cp "peerOrgranizations/voteOrg1/tls/keystore/" "peerOrgranizations/voteOrg1/tls/voteOrg1-server.key"

  echo "Registering MSP of user"
    fabric-ca-client enroll -u voteOrg1-user --caname ca-org1 -M "/peerOrgranizations/voteOrg1/users/user1@voteOrg1.blockvote.com/msp" --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg1/voteMSP_config.yaml" "/peerOrgranizations/voteOrg1/users/user1@voteOrg1.blockvote.com/msp/config.yaml"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u voteOrg1-admin --caname ca-org1 -M "/peerOrgranizations/voteOrg1/users/admin@voteOrg1.blockvote.com/msp" --tls.certfiles "peerOrgranizations/voteOrg1/voteOrg1-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg1/voteMSP_config.yaml" "/peerOrgranizations/voteOrg1/users/admin@voteOrg1.blockvote.com/msp/config.yaml"
}

function createVoteOrg1(){

  echo "Creating Certificate Authorities for VoteOrg2"
  mkdir "peerOrgranizations/voteOrg2.blockvote.com"

  export CA_VOTEORG1="${PWD}/peerOrgranizations/voteOrg2.blockvote.com"
  fabric-ca-client enroll -u voteOrg2admin --caname ca-voteorg2 --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "peerOrgranizations/voteOrg2/voteMSP_config.yaml"


  mkdir "/peerOrgranizations/voteOrg2.blockvote.com/msp/tlscacerts"
  cp "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "/peerOrgranizations/voteOrg2.blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "peerOrgranizations/voteOrg2.blockvote.com/tlsca"
  cp "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "peerOrgranizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2-cert.pem"

  mkdir "peerOrgranizations/voteOrg2.blockvote.com/ca"
  cp "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem" "peerOrgranizations/voteOrg2.blockvote.com/ca/ca.voteOrg2-cert.pem"

  echo "Registering admin of voteOrg2"
      fabric-ca-client register --id.name admin_voteOrg2 --id.secret adminPsswd --id.type admin --caname ca-voteorg2 --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering participant2"
    fabric-ca-client register --id.name participant1 --id.secret participantPsswd --id.type peer --caname ca-voteorg2 --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering MSP of participant2"
        fabric-ca-client enroll -u voteOrg2admin --caname ca-voteorg2 -M "peerOrgranizations/voteOrg2/msp" --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  echo "Registering user of voteOrg2"
      fabric-ca-client register --id.name user-voteOrg2 --id.secret userPsswd --id.type user --caname ca-voteorg2 --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg2/voteMSP_config.yaml" "peerOrgranizations/voteOrg2/msp/config.yaml"

  echo "Registering participant1 tls certificate"
        fabric-ca-client enroll -u voteOrg2-participant1 --caname ca-voteorg2 -M "peerOrgranizations/voteOrg2/tls" --enrollment.profile tls --csr.hosts voteOrg2 --tls.certifiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg2/tls/tlscacerts/" "peerOrgranizations/voteOrg2/tls/voteOrg2-ca.crt"
  cp "peerOrgranizations/voteOrg2/tls/signcerts/" "peerOrgranizations/voteOrg2/tls/voteOrg2-server.crt"
  cp "peerOrgranizations/voteOrg2/tls/keystore/" "peerOrgranizations/voteOrg2/tls/voteOrg2-server.key"

  echo "Registering MSP of user"
    fabric-ca-client enroll -u voteOrg2-user --caname ca-org1 -M "/peerOrgranizations/voteOrg2/users/user1@voteOrg2.blockvote.com/msp" --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg2/voteMSP_config.yaml" "/peerOrgranizations/voteOrg2/users/user1@voteOrg2.blockvote.com/msp/config.yaml"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u voteOrg2-admin --caname ca-org1 -M "/peerOrgranizations/voteOrg2/users/admin@voteOrg2.blockvote.com/msp" --tls.certfiles "peerOrgranizations/voteOrg2/voteOrg2-ca-certificate.pem"

  cp "peerOrgranizations/voteOrg2/voteMSP_config.yaml" "/peerOrgranizations/voteOrg2/users/admin@voteOrg2.blockvote.com/msp/config.yaml"
}

function createVoteOrgOrderer(){

  echo "Creating Certificate Authorities for VoteOrg1"
  mkdir "ordererOrgranizations/blockvote.com"

  export CA_ORDERER="${PWD}/ordererOrgranizations/blockvote.com"
  fabric-ca-client enroll -u voteOrg1admin --caname ca-orderer --tls.certfiles "ordererOrgranizations/voteOrderer/voteOrderer-ca-certificate.pem"

  cat "/templates/vote_msp_config_template.yaml" > "ordererOrgranizations/blockvote.com/voteMSP_config.yaml"

  mkdir "/ordererOrgranizations/blockvote.com/msp/tlscacerts"
  cp "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem" "ordererOrgranizations/blockvote.com/msp/tlscacerts-ca.crt"

  mkdir "ordererOrgranizations/blockvote.com/tlsca"
  cp "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem" "ordererOrgranizations/blockvote.com/tlsca/tlsca.orderers-cert.pem"

  mkdir "ordererOrgranizations/blockvote.com/ca"
  cp "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem" "ordererOrgranizations/blockvote.com/ca/ca.orderers-cert.pem"

  echo "Registering admin of orderer"
      fabric-ca-client register --id.name admin_orderer --id.secret adminPsswd --id.type admin --caname ca-orderer --tls.certfiles "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  echo "Registering orderer"
    fabric-ca-client register --id.name orderer --id.secret ordererPsswd --id.type peer --caname ca-orderer --tls.certfiles "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  echo "Registering MSP of orderer"
        fabric-ca-client enroll -u orderer --caname ca-orderer -M "ordererOrgranizations/blockvote.com/msp" --tls.certfiles "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "ordererOrgranizations/blockvote.com/voteMSP_config.yaml" "ordererOrgranizations/blockvote.com/msp/config.yaml"

  echo "Registering orderer tls certificate"
        fabric-ca-client enroll -u orderer --caname ca-orderer -M "ordererOrgranizations/blockvote.com/tls" --enrollment.profile tls --csr.hosts orderer.blockvote.com --tls.certifiles "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "ordererOrgranizations/blockvote.com/tls/tlscacerts/" "ordererOrgranizations/blockvote.com/tls/orderer-ca.crt"
  cp "ordererOrgranizations/blockvote.com/tls/signcerts/" "ordererOrgranizations/blockvote.com/tls/orderer-server.crt"
  cp "ordererOrgranizations/blockvote.com/tls/keystore/" "ordererOrgranizations/blockvote.com/tls/orderer-server.key"

  mkdir "ordererOrgranizations/blockvote.com/msp/tlscacerts"
  cp "ordererOrgranizations/blockvote.com/msp/tlscacerts/" "/ordererOrgranizations/blockvote.com/msp/tlscacerts/tlsca.blockvote.cert.pem"

  echo "Registering MSP of admin"
    fabric-ca-client enroll -u ordererAdmin --caname ca-orderer -M "/ordererOrgranizations/blockvote.com/users/admin@orderer.blockvote.com/msp" --tls.certfiles "ordererOrgranizations/blockvote.com/orderer-ca-certificate.pem"

  cp "ordererOrgranizations/blockvote.com/msp/voteMSP_config.yaml" "/ordererOrgranizations/blockvote.com/users/admin@orderer.blockvote.com/msp/config.yaml"
}
