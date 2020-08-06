#!/bin/sh

source ../common.properties

kafka-topics --list --zookeeper ${ZOOKEEPER_QUORUM}${KAFKA_ZNODE}
