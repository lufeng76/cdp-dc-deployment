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
ssl.truststore.password=${SSL_TRUSTSTORE_PASS}
group.id=${KAFKA_CONSUMER_GROUP}" > consumer.properties

export KAFKA_OPTS="-Djava.security.auth.login.config=${PWD}/jaas.conf"

kafka-console-consumer --new-consumer --bootstrap-server ${KAFKA_BOOTSTRAP_BROKER} --topic ${KAFKA_TOPIC} --from-beginning \
    --property print.key=true --property key.separator=, \
    --consumer.config consumer.properties
