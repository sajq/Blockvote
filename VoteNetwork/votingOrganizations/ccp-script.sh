#!/bin/bash

function one_line_pem {
	
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {

    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        votingOrganizations/templates/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        votingOrganizations/templates/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1.blockvote.com-cert.pem
CAPEM=votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/ca/ca.voteOrg1.blockvote.com-cert.pem

if [ -f "votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/tlsca/tlsca.voteOrg1.blockvote.com-cert.pem" ]; then
   echo "File exists"
fi

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/connection-voteOrg1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > votingOrganizations/peerOrganizations/voteOrg1.blockvote.com/connection-voteOrg1.yaml

ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/tlsca/tlsca.voteOrg2.blockvote.com-cert.pem
CAPEM=votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/ca/ca.voteOrg2.blockvote.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/connection-voteOrg2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > votingOrganizations/peerOrganizations/voteOrg2.blockvote.com/connection-voteOrg2.yaml
