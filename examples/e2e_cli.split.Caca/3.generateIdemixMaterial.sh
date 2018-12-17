#!/bin/bash +x
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


#set -e

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')


function generateIdemixMaterial (){
	IDEMIXGEN=$FABRIC_ROOT/release/$OS_ARCH/bin/idemixgen
	CURDIR=`pwd`
	IDEMIXMATDIR=$CURDIR/crypto-config/idemix

	if [ -f "$IDEMIXGEN" ]; then
            echo "Using idemixgen -> $IDEMIXGEN"
	else
	    echo "Building idemixgen"
	    make -C $FABRIC_ROOT release
	fi

	echo
	echo "####################################################################"
	echo "##### Generate idemix crypto material using idemixgen tool #########"
	echo "####################################################################"

	mkdir -p $IDEMIXMATDIR
	cd $IDEMIXMATDIR

	# Generate the idemix issuer keys
	$IDEMIXGEN ca-keygen

	# Generate the idemix signer keys
	$IDEMIXGEN signerconfig -u OU1 -e OU1 -r 1

	cd $CURDIR
}

generateIdemixMaterial
