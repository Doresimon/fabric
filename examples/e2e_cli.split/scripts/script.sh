#!/bin/bash
# Copyright London Stock Exchange Group All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
# set -o xtrace

echo
echo " ____    _____      _      ____    _____           _____   ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|         | ____| |___ \  | ____|"
echo "\___ \    | |     / _ \   | |_) |   | |    _____  |  _|     __) | |  _|  "
echo " ___) |   | |    / ___ \  |  _ <    | |   |_____| | |___   / __/  | |___ "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|           |_____| |_____| |_____|"
echo

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="fudan0110"}
: ${TIMEOUT:="12"}
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/ordererBob.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PEER0_ORG1_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Alice.example.com/peers/peer0.Alice.example.com/tls/ca.crt
PEER0_ORG2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Bob.example.com/peers/peer0.Bob.example.com/tls/ca.crt
ORDERER_SYSCHAN_ID=e2e-orderer-syschan

CC_NAME=mycc0110-3

CHAINCODE_VERSION=1.0


echo "Channel name : "$CHANNEL_NAME

echo "Chaincode name : "$CC_NAME

echo "Chaincode version : "$CHAINCODE_VERSION

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {
	PEER=$1
	ORG=$2
	if [ 9$ORG -eq 91 ] ; then
		CORE_PEER_LOCALMSPID="AliceMSP"
		CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Alice.example.com/users/Admin@Alice.example.com/msp
		if [ $PEER -eq 0 ]; then
			CORE_PEER_ADDRESS=peer0.Alice.example.com:7051
		else
			CORE_PEER_ADDRESS=peer0.Alice.example.com:7051
		fi
	else
		CORE_PEER_LOCALMSPID="BobMSP"
		CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/Bob.example.com/users/Admin@Bob.example.com/msp
		if [ 9$PEER -eq 90 ]; then
			CORE_PEER_ADDRESS=peer0.Bob.example.com:7051
		else
			CORE_PEER_ADDRESS=peer0.Bob.example.com:7051
		fi
	fi

	env |grep CORE
}

checkOSNAvailability() {
	# Use orderer's MSP for fetching system channel config block
	CORE_PEER_LOCALMSPID="OrdererMSP"
	CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/ordererBob.example.com/msp

	local rc=1
	local starttime=$(date +%s)

	# continue to poll
	# we either get a successful response, or reach TIMEOUT
	while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
	do
		 sleep 3
		 echo "Attempting to fetch system channel '$ORDERER_SYSCHAN_ID' ...$(($(date +%s)-starttime)) secs"
		 if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
			 peer channel fetch 0 -o ordererBob.example.com:7050 -c "$ORDERER_SYSCHAN_ID" >&log.log
			#  peer channel fetch 0 -o ordererBob.example.com:7050 -c "$ORDERER_SYSCHAN_ID"
		 else
			 peer channel fetch 0 0_block.pb -o ordererBob.example.com:7050 -c "$ORDERER_SYSCHAN_ID" --tls --cafile $ORDERER_CA >&log.log
			#  peer channel fetch 0 0_block.pb -o ordererBob.example.com:7050 -c "$ORDERER_SYSCHAN_ID" --tls --cafile $ORDERER_CA
		 fi
		 test $? -eq 0 && VALUE=$(cat log.log | awk '/Received block/ {print $NF}')
		 test "$VALUE" = "0" && let rc=0
	done
	cat log.log
	verifyResult $rc "Ordering Service is not available, Please try again ..."
	echo "===================== Ordering Service is up and running ===================== "
	echo
}

createChannel() {
	setGlobals 0 1
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel create -o ordererBob.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.log
	else
		peer channel create -o ordererBob.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile $ORDERER_CA >&log.log
	fi
	res=$?
	cat log.log
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

updateAnchorPeers() {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer channel update -o ordererBob.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.log
	else
		peer channel update -o ordererBob.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA >&log.log
	fi
	res=$?
	cat log.log
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers updated for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME' ===================== "
	sleep 5
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinChannelWithRetry () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG

	peer channel join -b $CHANNEL_NAME.block  >&log.log
	res=$?
	cat log.log
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "peer${PEER}.org${ORG} failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinChannelWithRetry $1
	else
		COUNTER=1
	fi
	verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0; do
		    joinChannelWithRetry $peer $org
		    echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		    sleep 2
		    echo
        done
	done
}

installChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	peer chaincode install -n $CC_NAME -v $CHAINCODE_VERSION -p github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd >&log.log
	res=$?
	cat log.log
	verifyResult $res "Chaincode installation on peer peer${PEER}.org${ORG} has Failed"
	echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	# while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
	# lets supply it directly as we know it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode instantiate -o ordererBob.example.com:7050 -C $CHANNEL_NAME -n $CC_NAME -v $CHAINCODE_VERSION -c '{"Args":["init","a","100","b","200"]}' -P "OR ('AliceMSP.peer','BobMSP.peer')" >&log.log
	else
		peer chaincode instantiate -o ordererBob.example.com:7050 --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME -v $CHAINCODE_VERSION -c '{"Args":["init","a","100","b","200"]}' -P "OR ('AliceMSP.peer','BobMSP.peer')" >&log.log
	fi
	res=$?
	cat log.log
	verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode is instantiated on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
	echo
}

chaincodeQuery () {
	PEER=$1
	ORG=$2
	setGlobals $PEER $ORG
	EXPECTED_RESULT=$3
	echo "===================== Querying on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local starttime=$(date +%s)

	# continue to poll
	# we either get a successful response, or reach TIMEOUT
	while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
	do
        	sleep 3
        	echo "Attempting to Query peer${PEER}.org${ORG} ...$(($(date +%s)-starttime)) secs"
        	# peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["query","a"]}' >&log.log
        	peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"Args":["query","a"]}' >&log.log
        	test $? -eq 0 && VALUE=$(cat log.log | egrep '^[0-9]+$')
        	test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
	done
	echo
	cat log.log
	if test $rc -eq 0 ; then
		echo "===================== Query successful on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
    	else
		echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.org${ORG} is INVALID !!!!!!!!!!!!!!!!"
        	echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
		exit 1
    	fi
}

# parsePeerConnectionParameters $@
# Helper function that takes the parameters from a chaincode operation
# (e.g. invoke, query, instantiate) and checks for an even number of
# peers and associated org, then sets $PEER_CONN_PARMS and $PEERS
parsePeerConnectionParameters() {
	# check for uneven number of peer and org parameters
	if [ $(( $# % 2 )) -ne 0 ]; then
        	exit 1
	fi

	PEER_CONN_PARMS=""
	PEERS=""
	while [ "$#" -gt 0 ]; do
		PEER="peer$1.org$2"
		PEERS="$PEERS $PEER"
		PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $PEER.example.com:7051"
		if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
        		TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_ORG$2_CA")
        		PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
        	fi
		# shift by two to get the next pair of peer/org parameters
        	shift; shift
	done
	# remove leading space for output
	PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

# chaincodeInvoke <peer> <org> ...
# Accepts as many peer/org pairs as desired and requests endorsement from each
chaincodeInvoke () {
	parsePeerConnectionParameters $@
	res=$?
	verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

	# while 'peer chaincode' command can get the orderer endpoint from the
	# peer (if join was successful), let's supply it directly as we know
	# it using the "-o" option
	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
		peer chaincode invoke -o ordererBob.example.com:7050 -C $CHANNEL_NAME -n $CC_NAME $PEER_CONN_PARMS -c '{"Args":["invoke","a","b","10"]}' >&log.log
	else
        peer chaincode invoke -o ordererBob.example.com:7050  --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME $PEER_CONN_PARMS -c '{"Args":["invoke","a","b","10"]}' >&log.log
	fi
	res=$?
	cat log.log
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
	echo
}

# # Check for orderering service availablility
# echo "Check orderering service availability..."
checkOSNAvailability

# # Create channel
# echo "Creating channel..."
createChannel

# # Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

# # Set the anchor peers for each org in the channel
echo "Updating anchor peers for Alice..."
updateAnchorPeers 0 1
echo "Updating anchor peers for Bob..."
updateAnchorPeers 0 2

# # Install chaincode on peer0.Alice and peer2.Bob
echo "Installing chaincode on peer0.Alice..."
installChaincode 0 1

echo "Install chaincode on peer0.Bob..."
installChaincode 0 2

# # Instantiate chaincode on peer0.Alice
echo "Instantiating chaincode on peer0.Alice..."
instantiateChaincode 0 1

# # Instantiate chaincode on peer0.Bob
echo "Instantiating chaincode on peer0.Bob..."
instantiateChaincode 0 2

# # Query on chaincode on peer0.Alice
echo "Querying chaincode on peer0.Alice..."
# chaincodeQuery 0 1 100

# # Invoke on chaincode on peer0.Alice and peer0.Bob
# echo "Sending invoke transaction on peer0.Alice and peer0.Bob..."
# chaincodeInvoke 0 1 0 2

# Install chaincode on peer1.Bob
# echo "Installing chaincode on peer1.Bob..."
# installChaincode 1 2

# Query on chaincode on peer1.Bob, check if the result is 90
# echo "Querying chaincode on peer1.Bob..."
# chaincodeQuery 1 2 90

#Query on chaincode on peer1.org3 with idemix MSP type, check if the result is 90
# echo "Querying chaincode on peer1.org3..."
# chaincodeQuery 1 3 90

echo
echo "===================== All GOOD, End-2-End execution completed ===================== "
echo

echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

# set +o xtrace

exit 0


# ./scripts/script.sh > ./scripts/run.log &

# peer chaincode list -o ordererAlice.example.com:7050 -C fudan0110 --installed --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/ordererBob.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
# peer chaincode list -o ordererAlice.example.com:7050 -C fudan0110 --instantiated --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/ordererBob.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

