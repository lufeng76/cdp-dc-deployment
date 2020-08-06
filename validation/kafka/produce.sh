#!/bin/sh

source ../common.properties

export PATH=/opt/cloudera/parcels/KAFKA/bin:$PATH

echo "Client {
com.sun.security.auth.module.Krb5LoginModule required
useTicketCache=true;
};

KafkaClient {
com.sun.security.auth.module.Krb5LoginModule required
useTicketCache=true;
};

KafkaServer {
com.sun.security.auth.module.Krb5LoginModule required
useTicketCache=true;
};" > jaas.conf

echo "security.protocol=SASL_SSL
sasl.kerberos.service.name=kafka
ssl.truststore.location=${SSL_TRUSTSTORE_PATH}
ssl.truststore.password=${SSL_TRUSTSTORE_PASS}" > producer.properties

export KAFKA_OPTS="-Djava.security.auth.login.config=${PWD}/jaas.conf"

KEY=$(( RANDOM % 10 ))
STR=$(echo ${RANDOM} | tr '[0-9]' '[a-zA-Z]')

echo "Writing ${KEY},${STR} ..."
echo "${KEY},${STR}" | kafka-console-producer --broker-list ${KAFKA_BROKERS} --topic ${KAFKA_TOPIC} \
    --property parse.key=true --property key.separator=, \
    --producer.config producer.properties
