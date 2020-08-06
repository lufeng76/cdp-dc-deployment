#!/bin/sh

source ../common.properties

echo "{
 \"partitions\":
  [
    {\"topic\": \"${KAFKA_TOPIC}\", \"partition\": 0}
  ]
}" > partitions.json

kafka-preferred-replica-election --zookeeper ${ZOOKEEPER_QUORUM}${KAFKA_ZNODE} --path-to-json-file partitions.json
