#!/bin/bash

option=$1 #participant admin
userName=$2
organization=$3

function participants_certs_creation(){

  echo "Participants' certifications creation"

  option=$1
  userName=$2
  organization=$3

  mkdir "participantOrgranizations/$organization/certs"
  mkdir "participantOrgranizations/$organization/tlscerts"
  mkdir "participantOrgranizations/$organization/participants/certs"
  mkdir "participantOrgranizations/$organization/memberservprovider/cacerts"
  mkdir "participantOrgranizations/$organization/memberservprovider/tlscacerts"

  cfssl gencert -initca "participantsOrgranizations/ca-participants.json" | cfssljson -bare "participantsOrgranizations/$organization/certs/cert"

  cp "participantOrgranizations/$organization/certs/cert.pem" "participantOrgranizations/$organization/certs/cert.$organization.pem"
  cp "participantOrgranizations/$organization/certs/cert.pem" "participantOrgranizations/$organization/tlscerts/tlscert.$organization.pem"
  cp "participantOrgranizations/$organization/certs/cert.pem" "participantOrgranizations/$organization/memberservprovider/certs"
  cp "participantOrgranizations/$organization/certs/cert.pem" "participantOrgranizations/$organization/memberservprovider/tlscerts"

  if [$option == "participant"]; then
    create_participants_certs "participantOrgranizations/$organization" "$userName"
  elif [$option == "admin"]; then
    generate_user_cets "participantOrgranizations/$organization" "$userName" "$option"
  fi
}

function orderers_certs_creation(){

  option=$1
  userName=$2

  mkdir "orderersOrgranizations/orderers/certs"

  cfssl gencert -initca "orderersOrgranizations/ca-orderers.json" | cfssljson -bare "orderersOrgranizations/certs/cert"

  cp "orderersOrgranizations/certs/cert.pem" "orderersOrgranizations/tlscerts/tlscert.pem"
  cp "orderersOrgranizations/certs/cert.pem" "orderersOrgranizations/memberservprovider/certs"
  cp "orderersOrgranizations/certs/cert.pem" "orderersOrgranizations/memberservprovider/tlscerts/tlscert.pem"

  if [$option == "orderer"]; then
    generate_orderer_certs "orderersOrgranizations/" "$userName"
  elif [$option == "admin"]; then
    generate_user_cets "orderersOrgranizations/" "$userName" "$option"
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

  mv "usersOrgranizations/$organization/users/$userName/memberservprovider/signcerts/cert-key.pem"  "participantsOrgranizations/$organization/participants/$userName/memberservprovider/keystore"

  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/memberservprovider/cacerts"
  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="usersOrgranizations/$organization/certs/cert.pem" -ca-key="usersOrgranizations/$organization/certs/cert-key.pem" -config="/usersOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/usersOrgranizations/cert-${userName}conf.json" | cfssljson -bare "usersOrgranizations/$organization/users/${userName}/tls/user"

  cp "usersOrgranizations/$organization/certs/cert.pem" "usersOrgranizations/$organization/users/$userName/tls/cacert.crt"
  mv "usersOrgranizations/$organization/users/$userName/tls/user.pem" "participantsOrgranizations/$organization/users/$userName/tls/user.key"
  mv "usersOrgranizations/$organization/users/$userName/tls/user-key.pem" "usersOrgranizations/$organization/users/$userName/tls/user.crt"
}

function create_participants_cert(){

  certDir=$1
  userName=$2

  mkdir "participantsOrgranizations/$organization/participants/$userName/memberservprovider/signcerts"
  mkdir "participantsOrgranizations/$organization/participants/$userName/memberservprovider/keystore"
  mkdir "participantsOrgranizations/$organization/participants/$userName/memberservprovider/cacerts"
  mkdir "participantsOrgranizations/$organization/participants/$userName/memberservprovider/tlscacerts"
  mkdir "participantsOrgranizations/$organization/participants/$userName/tls"

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
  ' > "participantsOrgranizations/$organization/participants/participant-$userName.json"

  #generation of participant's certificate
  cfssl gencert -ca="participantsOrgranizations/$organization/certs/cert.pem" -ca-key="participantsOrgranizations/$organization/certs/cert-key.pem" -config="/participantsOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="sign" "/participantsOrgranizations/cert-${userName}conf.json" | cfssljson -bare "participantsOrgranizations/$organization/participants/${userName}/memberservprovider/signedcerts"

  mv "participantsOrgranizations/$organization/participants/$userName/memberservprovider/signcerts/cert-key.pem"  "participantsOrgranizations/$organization/participants/$userName/memberservprovider/keystore"

  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/memberservprovider/cacerts"
  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="participantsOrgranizations/$organization/certs/cert.pem" -ca-key="participantsOrgranizations/$organization/certs/cert-key.pem" -config="/participantsOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/participantsOrgranizations/cert-${userName}conf.json" | cfssljson -bare "participantsOrgranizations/$organization/participants/${userName}/tls/server"

  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/tls/cacert.crt"
  mv "participantsOrgranizations/$organization/participants/$userName/tls/server.pem" "participantsOrgranizations/$organization/participants/$userName/tls/server.crt"
  mv "participantsOrgranizations/$organization/participants/$userName/tls/server-key.pem" "participantsOrgranizations/$organization/participants/$userName/tls/server.key"
}

function create_orderers_cert(){

  certDir=$1
  userName=$2

  mkdir "orderersOrgranizations/$organization/orderers/$userName/memberservprovider/signcerts"
  mkdir "orderersOrgranizations/$organization/orderers/$userName/memberservprovider/keystore"
  mkdir "orderersOrgranizations/$organization/orderers/$userName/memberservprovider/cacerts"
  mkdir "orderersOrgranizations/$organization/orderers/$userName/memberservprovider/tlscacerts"
  mkdir "orderersOrgranizations/$organization/orderers/$userName/tls"

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
  ' > "orderersOrgranizations/$organization/orderers/orderer-$userName.json"

  #generation of participant's certificate
  cfssl gencert -ca="participantsOrgranizations/$organization/certs/cert.pem" -ca-key="participantsOrgranizations/$organization/certs/cert-key.pem" -config="/participantsOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="sign" "/participantsOrgranizations/cert-${userName}conf.json" | cfssljson -bare "participantsOrgranizations/$organization/participants/${userName}/memberservprovider/signedcerts"

  mv "participantsOrgranizations/$organization/participants/$userName/memberservprovider/signcerts/cert-key.pem"  "participantsOrgranizations/$organization/participants/$userName/memberservprovider/keystore"

  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/memberservprovider/cacerts"
  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/memberservprovider/tlscacerts"


  #generation of server's TLS certificate
  cfssl gencert -ca="participantsOrgranizations/$organization/certs/cert.pem" -ca-key="participantsOrgranizations/$organization/certs/cert-key.pem" -config="/participantsOrgranizations/cert-signed-conf.json" -cn="$userName" -hostname="$userName,localhost,127.0.0.1" -profile="tls" "/participantsOrgranizations/cert-${userName}conf.json" | cfssljson -bare "participantsOrgranizations/$organization/participants/${userName}/tls/server"

  cp "participantsOrgranizations/$organization/certs/cert.pem" "participantsOrgranizations/$organization/participants/$userName/tls/cacert.crt"
  mv "participantsOrgranizations/$organization/participants/$userName/tls/server.pem" "participantsOrgranizations/$organization/participants/$userName/tls/server.crt"
  mv "participantsOrgranizations/$organization/participants/$userName/tls/server-key.pem" "participantsOrgranizations/$organization/participants/$userName/tls/server.key"
}
