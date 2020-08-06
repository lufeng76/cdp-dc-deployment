#!/bin/sh

source ../common.properties

export PATH=/opt/cloudera/parcels/KAFKA/bin:$PATH

kafka-consumer-groups  --describe --group ${KAFKA_CONSUMER_GROUP} --bootstrap-server ${KAFKA_BOOTSTRAP_BROKER} --new-consumer
