#!/bin/bash

function prepareChaincode(){
  ORG=$1
  echo "Preparing chaincode for voteOrg${ORG}..." 
  echo $CORE_PEER_MSPCONFIGPATH
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  if test $? -ne 0; then
    peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
    res=$?
  fi
  { set +x; } 2>/dev/null
  cat log.txt
  if [ $? -ne 0 ]; then
    echo "Chaincode preparation for voteOrg${ORG} has failed."
  else
    echo "Chaincode has been prepared!"
  fi
}        

function chaincodeQueryDeploy(){
  ORG=$1
  set -x
  peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  if [ $? -ne 0 ]; then
    echo "Query not deployed"
  else
    echo "Query deployed!"
  fi
}

function chaincodeDefApprove(){
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "Chaincode definition not approved"
  else
    echo "Chaincode definition approved!"
  fi
}

function commitTest(){
  ORG=$1
  shift 1
  setGlobals $ORG
  local rc=1
  local COUNTER=1

  echo "Commit testing..."

    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
      sleep $DELAY
      set -x
      peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
      res=$?
      echo $res
      cat log.txt
      { set +x; } 2>/dev/null
      let rc=0
      for var in "$@"; do
        grep "$var" log.txt &>/dev/null || let rc=1
      done
      COUNTER=$(expr $COUNTER + 1)
    done
    cat log.txt
    if test $rc -eq 0; then
      echo "Commit successful."
    else
      echo "Commit unsuccessful."
    fi
}

function chaincodeDefCommit(){
  parsePeerConnectionParameters $@
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com --tls --cafile "$ORDERER_CA" --channelID $CHANNEL_NAME --name ${CC_NAME} "${PEER_CONN_PARMS[@]}" --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  echo "Chaincode definition committed"
}

function queryCommit() {
  ORG=$1
  setGlobals $ORG
 
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    echo "Query commited"
  else
    echo "Query not commited"
  fi
}

function chaincodeInvoke(){
  parsePeerConnectionParameters $@

  local COUNTER=1
  local fcn_call='{"function":"'${CC_INIT_FCN}'","Args":[]}'

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.blockvote.com --tls --cafile "$ORDERER_CA" -C $CHANNEL_NAME -n ${CC_NAME} "${PEER_CONN_PARMS[@]}" --isInit -c ${fcn_call} >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done

  echo "Transaction invoke"
}

function chaincodeQuery() {
  ORG=$1

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["org.hyperledger.fabric:GetMetadata"]}' >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done

  if test $rc -eq 0; then
    echo "Query successful"
  else
    echo "Query unsuccessful"
  fi
}

function resolveSequence() {

  #if the sequence is not "auto", then use the provided sequence
  if [[ "${CC_SEQUENCE}" != "auto" ]]; then
    return 0
  fi

  local rc=1
  local COUNTER=1
  # first, find the sequence number of the committed chaincode
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    set -x
    COMMITTED_CC_SEQUENCE=$(peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} | sed -n "/Version:/{s/.*Sequence: //; s/, Endorsement Plugin:.*$//; p;}")
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  # if there are no committed versions, then set the sequence to 1
  if [ -z $COMMITTED_CC_SEQUENCE ]; then
    CC_SEQUENCE=1
    return 0
  fi

  rc=1
  COUNTER=1
  # next, find the sequence number of the approved chaincode
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    set -x
    APPROVED_CC_SEQUENCE=$(peer lifecycle chaincode queryapproved --channelID $CHANNEL_NAME --name ${CC_NAME} | sed -n "/sequence:/{s/^sequence: //; s/, version:.*$//; p;}")
    res=$?
    { set +x; } 2>/dev/null
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  # if the committed sequence and the approved sequence match, then increment the sequence
  # otherwise, use the approved sequence
  if [ $COMMITTED_CC_SEQUENCE == $APPROVED_CC_SEQUENCE ]; then
    CC_SEQUENCE=$((COMMITTED_CC_SEQUENCE+1))
  else
    CC_SEQUENCE=$APPROVED_CC_SEQUENCE
  fi

}

queryInstalledOnPeer() {

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    peer lifecycle chaincode queryinstalled >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done

}

queryCommittedOnChannel() {
  CHANNEL_NAME=$1
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do

    peer lifecycle chaincode querycommitted -C $CHANNEL_NAME >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done
  if test $rc -ne 0; then
    echo "Chaincode fetch failed"
  fi

}


listAllCommitted() {

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    CHANNEL_LIST=$(peer channel list | sed '1,1d')
    COUNTER=$(expr $COUNTER + 1)
  done
  if test $rc -eq 0; then
    for channel in $CHANNEL_LIST
    do
      queryCommittedOnChannel "$channel"
    done
  else
      echo "Chaincode fetch failed"
  fi

}

chaincodeInvoke() {
  ORG=$1
  CHANNEL_NAME=$2
  CC_NAME=$3
  CC_INVOKE_CONSTRUCTOR=$4

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    peer chaincode invoke -o localhost:7050 -C $CHANNEL_NAME -n ${CC_NAME} -c ${CC_INVOKE_CONSTRUCTOR} --tls --cafile $ORDERER_CA  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA  >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done
  if test $rc -eq 0; then
    echo "Invoke successful"
  else
    echo "Invoke unsuccessful"
  fi
}

chaincodeQuery() {
  ORG=$1
  CHANNEL_NAME=$2
  CC_NAME=$3
  CC_QUERY_CONSTRUCTOR=$4

  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c ${CC_QUERY_CONSTRUCTOR} >&log.txt
    COUNTER=$(expr $COUNTER + 1)
  done
  if test $rc -eq 0; then
    echo "Query successful"
  else
    echo "Query unsuccessful"
  fi
}

