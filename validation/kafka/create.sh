#!/bin/sh

source ../common.properties

export PATH=/opt/cloudera/parcels/KAFKA/bin:$PATH

kafka-topics --create --zookeeper ${ZOOKEEPER_QUORUM}${KAFKA_ZNODE} --topic ${KAFKA_TOPIC} --replication-factor 1 --partitions 1
