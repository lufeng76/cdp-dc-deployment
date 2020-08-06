#!/bin/sh

source ../common.properties

echo "{
 \"topics\":
  [
    {\"topic\": \"${KAFKA_TOPIC}\"}
  ],
 \"version\":1
}
}" > topics.json

kafka-reassign-partitions --broker-list 0 --generate --zookeeper ${ZOOKEEPER_QUORUM}${KAFKA_ZNODE} --topics-to-move-json-file topics.json
