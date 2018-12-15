#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


#set -e

ORG_NAME=$1
: ${ORG_NAME:="Alice"}
echo $ORG_NAME

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	echo
	echo "####################################################################"
	echo "##### Generate docker-compose.ca.yaml using ca certificate #########"
	echo "####################################################################"

	cp ./yaml.template/docker-compose.ca.template.yaml docker-compose.ca.yaml

        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/${ORG_NAME}.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/REPLACE_CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.ca.yaml
        # sed $OPTS "s/REPLACE_ORG_NAME/${ORG_NAME}/g" docker-compose.ca.yaml
}

function replace () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	echo
	echo "####################################################################"
	echo "##### Generate docker-compose.kafka.yaml using ca certificate #########"
	echo "####################################################################"

	cp ./yaml.template/docker-compose.$1.template.yaml docker-compose.$1.yaml

        CURRENT_DIR=$PWD
        cd $CURRENT_DIR
		
        sed $OPTS "s/REPLACE_ORG_NAME/${ORG_NAME}/g" docker-compose.$1.yaml
}

replacePrivateKey
replace zookeeper
replace kafka
replace order
replace peer
replace cli
replace ca
