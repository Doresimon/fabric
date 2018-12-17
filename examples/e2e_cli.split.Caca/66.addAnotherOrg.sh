#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


#set -e

if [ x$1 == x ]
then
    echo
	echo "please run with args"
	echo "such as 'Alice'"
	exit 1
fi

ORG_NAME=$1
ORG_ID=$2

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')


## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/cryptogen

	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
	else
	    echo "Building cryptogen"
	    make -C $FABRIC_ROOT release
	fi

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	$CRYPTOGEN generate --config=./crypto-config.$ORG_NAME.yaml
	echo
}

## Generate channel configuration transaction, channel.tx
function generateChannelArtifacts() {

	CONFIGTXGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/configtxgen
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
	else
	    echo "Building configtxgen"
	    make -C $FABRIC_ROOT release
	fi

	echo "##########################################################"
	echo "#########  Generating $ORG_NAME Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	$CONFIGTXGEN -printOrg $ORG_NAME\MSP > ./channel-artifacts/$ORG_NAME.json

	echo
	echo "#################################################################"
	echo "### Copy orderer's crypto-config to crypto-config for $ORG_NAME ###"
	echo "#################################################################"
	cp -r crypto-config.old/ordererOrganizations crypto-config/

	echo
}



generateCerts

# generateChannelArtifacts
