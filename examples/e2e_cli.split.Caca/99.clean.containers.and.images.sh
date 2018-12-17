#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DOWN_NAME=$1

function clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS
        fi
}

function networkDown () {
    docker-compose -f docker-compose.ca.yaml down

    docker-compose -f docker-compose.peer.yaml down

    docker-compose -f docker-compose.order.yaml down

    docker-compose -f docker-compose.kafka.yaml down

    docker-compose -f docker-compose.zookeeper.yaml down

    docker-compose -f docker-compose.cli.yaml down

#     docker-compose -f docker-compose.couch.yaml down

}

function networkDownOne () {
    docker-compose -f docker-compose.$1.yaml down
}

if [ x$DOWN_NAME == x ]
then
        echo
        echo "shutdown all"
	
        networkDown

        #Cleanup the chaincode containers
        clearContainers

        #Cleanup images
        removeUnwantedImages
else
        networkDownOne $DOWN_NAME
fi
