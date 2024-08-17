#!/bin/bash

option=$1 #participant admin
userName=$2
organization=$3

function participants_certs_creation(){

  echo "Participants' certifications creation"

  option=$1
  userName=$2
  organization=$3

  mkdir "peerOrgranizations/$organization/certs"
  mkdir "peerOrgranizations/$organization/tlscerts"
  mkdir "peerOrgranizations/$organization/peers/certs"
  mkdir "peerOrgranizations/$organization/memberservprovider/cacerts"
  mkdir "peerOrgranizations/$organization/memberservprovider/tlscacerts"

  cfssl gencert -initca "peerOrgranizations/ca-participants.json" | cfssljson -bare "peerOrgranizations/$organization/certs/cert"

  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/certs/cert.$organization.pem"
  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/tlscerts/tlscert.$organization.pem"
  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/memberservprovider/certs"
  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/memberservprovider/tlscerts"

  if [$option == "peer"]; then
    create_participants_certs "peerOrgranizations/$organization" "$userName"
  elif [$option == "admin"]; then
    generate_user_cets "peerOrgranizations/$organization" "$userName" "$option"
  fi
}

function orderers_certs_creation(){

  option=$1
  userName=$2

  mkdir "ordererOrgranizations/orderers/certs"

  cfssl gencert -initca "ordererOrgranizations/ca-orderers.json" | cfssljson -bare "ordererOrgranizations/certs/cert"

  cp "ordererOrgranizations/certs/cert.pem" "ordererOrgranizations/tlscerts/tlscert.pem"
  cp "ordererOrgranizations/certs/cert.pem" "ordererOrgranizations/memberservprovider/certs"
  cp "ordererOrgranizations/certs/cert.pem" "ordererOrgranizations/memberservprovider/tlscerts/tlscert.pem"

  if [$option == "orderer"]; then
    generate_orderer_certs "ordererOrgranizations/" "$userName"
  elif [$option == "admin"]; then
    generate_user_cets "ordererOrgranizations/" "$userName" "$option"
  fi
}

function create_users_cert(){
  certDir=$1
  userName=$2
  option=$3

  mkdir "usersOrgranizations/$organization/users/$userName/memberservprovider/signcerts"
  mkdir "usersOrgranizations/$organization/users/$userName/memberservprovider/keystore"
  mkdir "usersOrgranizations/$organization/users/$userName/memberservprovider/cacerts"
  mkdir "usersOrgranizations/$organization/users/$userName/memberservprovider/tlscacerts"
  mkdir "usersOrgranizations/$organization/users/$userName/tls"

  cat '
    {
        "CN": "'$userName'",
        "key": {
            "algo": "rsa",
            "size": 256
        },
        "votingDetails": [
            {
                "campaign": "vote-001",
                "date": "01-01-1970",
                "voteOption": "1"
            }
        ],
        "hosts": [
            "'$userName'",
            "localhost",
            "127.0.0.1",
            "0.0.0.0"
        ]
    }
  ' > "usersOrgranizations/$organization/users/$option-$userName-csr.json"

  #generation of participant's certificate
  cfssl gencert -ca="usersOrgranizations/$organization/certs/cert.pem" -ca-key="usersOrgranizations/$organization/certs/cert-key.pem" -config="/usersOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="sign" "/usersOrgranizations/$organization/users/${option}-${userName}csr.json" | cfssljson -bare "usersOrgranizations/$organization/users/${userName}/memberservprovider/signedcerts"

  mv "usersOrgranizations/$organization/users/$userName/memberservprovider/signcerts/cert-key.pem"  "peerOrgranizations/$organization/peer/$userName/memberservprovider/keystore"

  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/memberservprovider/cacerts"
  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="usersOrgranizations/$organization/certs/cert.pem" -ca-key="usersOrgranizations/$organization/certs/cert-key.pem" -config="/usersOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/usersOrgranizations/cert-${userName}conf.json" | cfssljson -bare "usersOrgranizations/$organization/users/${userName}/tls/user"

  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/tls/cacert.crt"
  mv "usersOrgranizations/$organization/users/$userName/tls/user.pem" "peerOrgranizations/$organization/users/$userName/tls/user.key"
  mv "usersOrgranizations/$organization/users/$userName/tls/user-key.pem" "usersOrgranizations/$organization/users/$userName/tls/user.crt"
}

function create_participants_cert(){

  certDir=$1
  userName=$2

  mkdir "peerOrgranizations/$organization/peers/$userName/memberservprovider/signcerts"
  mkdir "peerOrgranizations/$organization/peers/$userName/memberservprovider/keystore"
  mkdir "peerOrgranizations/$organization/peers/$userName/memberservprovider/cacerts"
  mkdir "peerOrgranizations/$organization/peers/$userName/memberservprovider/tlscacerts"
  mkdir "peerOrgranizations/$organization/peers/$userName/tls"

  cat '
    {
        "CN": "'$userName'",
        "key": {
            "algo": "rsa",
            "size": 256
        },
        "votingDetails": [
            {
                "campaign": "vote-001",
                "date": "01-01-1970",
                "voteOption": "1"
            }
        ],
        "hosts": [
            "'$userName'",
            "localhost",
            "127.0.0.1",
            "0.0.0.0"
        ]
    }
  ' > "peerOrgranizations/$organization/peers/participant-$userName.json"

  #generation of participant's certificate
  cfssl gencert -ca="peerOrgranizations/$organization/certs/cert.pem" -ca-key="peerOrgranizations/$organization/certs/cert-key.pem" -config="/peerOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="sign" "/peerOrgranizations/cert-${userName}conf.json" | cfssljson -bare "peerOrgranizations/$organization/peers/${userName}/memberservprovider/signedcerts"

  mv "peerOrgranizations/$organization/peers/$userName/memberservprovider/signcerts/cert-key.pem"  "peerOrgranizations/$organization/peers/$userName/memberservprovider/keystore"

  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/memberservprovider/cacerts"
  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="peerOrgranizations/$organization/certs/cert.pem" -ca-key="peerOrgranizations/$organization/certs/cert-key.pem" -config="/peerOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/peerOrgranizations/cert-${userName}conf.json" | cfssljson -bare "peerOrgranizations/$organization/peers/${userName}/tls/server"

  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/tls/cacert.crt"
  mv "peerOrgranizations/$organization/peers/$userName/tls/server.pem" "peerOrgranizations/$organization/peers/$userName/tls/server.crt"
  mv "peerOrgranizations/$organization/peers/$userName/tls/server-key.pem" "peerOrgranizations/$organization/peers/$userName/tls/server.key"
}

function create_orderers_cert(){

  certDir=$1
  userName=$2

  mkdir "ordererOrgranizations/$organization/orderers/$userName/memberservprovider/signcerts"
  mkdir "ordererOrgranizations/$organization/orderers/$userName/memberservprovider/keystore"
  mkdir "ordererOrgranizations/$organization/orderers/$userName/memberservprovider/cacerts"
  mkdir "ordererOrgranizations/$organization/orderers/$userName/memberservprovider/tlscacerts"
  mkdir "ordererOrgranizations/$organization/orderers/$userName/tls"

  cat '
    {
        "CN": "'$userName'",
        "key": {
            "algo": "rsa",
            "size": 256
        },
        "votingDetails": [
            {
                "campaign": "vote-001",
                "date": "01-01-1970",
                "voteOption": "1"
            }
        ],
        "hosts": [
            "'$userName'",
            "localhost",
            "127.0.0.1",
            "0.0.0.0"
        ]
    }
  ' > "ordererOrgranizations/$organization/orderers/orderer-$userName.json"

  #generation of participant's certificate
  cfssl gencert -ca="peerOrgranizations/$organization/certs/cert.pem" -ca-key="peerOrgranizations/$organization/certs/cert-key.pem" -config="/peerOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="sign" "/peerOrgranizations/cert-${userName}conf.json" | cfssljson -bare "peerOrgranizations/$organization/peers/${userName}/memberservprovider/signedcerts"

  mv "peerOrgranizations/$organization/peers/$userName/memberservprovider/signcerts/cert-key.pem"  "peerOrgranizations/$organization/peers/$userName/memberservprovider/keystore"

  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/memberservprovider/cacerts"
  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="peerOrgranizations/$organization/certs/cert.pem" -ca-key="peerOrgranizations/$organization/certs/cert-key.pem" -config="/peerOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/peerOrgranizations/cert-${userName}conf.json" | cfssljson -bare "peerOrgranizations/$organization/peers/${userName}/tls/server"

  cp "peerOrgranizations/$organization/certs/cert.pem" "peerOrgranizations/$organization/peers/$userName/tls/cacert.crt"
  mv "peerOrgranizations/$organization/peers/$userName/tls/server.pem" "peerOrgranizations/$organization/peers/$userName/tls/server.crt"
  mv "peerOrgranizations/$organization/peers/$userName/tls/server-key.pem" "peerOrgranizations/$organization/peers/$userName/tls/server.key"
}
