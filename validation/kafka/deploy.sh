#!/bin/sh

set +x

source ../common.properties

if [ "${KAFKA_BASE}" == "" ]; then
    echo "KAFKA_BASE can't be empty!"
    exit 1
fi

if $(hadoop fs -test -d ${KAFKA_BASE}); then
    hdfs dfs -rm -R -f ${KAFKA_BASE}
fi

if $(! hadoop fs -test -d ${KAFKA_BASE}); then
    echo Creating path ${KAFKA_BASE}/
    hdfs dfs -mkdir -p ${KAFKA_BASE}/
fi

hdfs dfs -put -f data*.csv ${KAFKA_BASE}
