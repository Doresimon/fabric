#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


if [ x$1 == x ]
then
    echo
	echo "please run with args"
	exit 1
fi

ORG_NAME_1=$1
ORG_IP_1=$2
ORG_NAME_2=$3
ORG_IP_2=$4

echo $ORG_NAME_1 = $ORG_IP_1
echo $ORG_NAME_2 = $ORG_IP_2

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

function copyTemplate () {
	echo
	echo "#####################################################################################"
	echo "##### copy docker-compose.$1.yaml from docker-compose.$1.template.yaml      #########"
	echo "#####################################################################################"

	cp ./yaml.template/docker-compose.$1.template.yaml docker-compose.$1.yaml

	echo
}

function replace () {
	ARCH=`uname -s | grep Darwin`
	if [ "$ARCH" == "Darwin" ]; then
		OPTS="-it"
	else
		OPTS="-i"
	fi

	echo
	echo "#####################################################################################"
	echo "################ replace name and IP in docker-compose.$1.yaml ######################"
	echo "#####################################################################################"

	CURRENT_DIR=$PWD
	cd $CURRENT_DIR
	
	sed $OPTS "s/REPLACE_ORG_NAME_1/${ORG_NAME_1}/g" docker-compose.$1.yaml
	sed $OPTS "s/REPLACE_ORG_NAME_2/${ORG_NAME_2}/g" docker-compose.$1.yaml
	
	sed $OPTS "s/REPLACE_ORG_IP_1/${ORG_IP_1}/g" docker-compose.$1.yaml
	sed $OPTS "s/REPLACE_ORG_IP_2/${ORG_IP_2}/g" docker-compose.$1.yaml
}

copyTemplate zookeeper
copyTemplate kafka
copyTemplate order
copyTemplate peer
copyTemplate cli
copyTemplate ca

replace zookeeper
replace kafka
replace order
replace peer
replace cli
replace ca
