#!/bin/sh

source ../common.properties

kafka-topics --describe --zookeeper ${ZOOKEEPER_QUORUM}${KAFKA_ZNODE} --topic ${KAFKA_TOPIC}
