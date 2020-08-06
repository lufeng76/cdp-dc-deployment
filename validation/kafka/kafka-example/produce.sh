#!/bin/sh

set +x

source ../../common.properties

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

spark-submit --driver-java-options "-Djava.security.auth.login.config=${PWD}/jaas.conf" --class com.cloudera.kafka.KafkaProducerExample target/scala-2.11/kafkaexample_2.11-1.0.jar ${KAFKA_TOPIC} ${KAFKA_BOOTSTRAP_BROKER} 5 ${SSL_TRUSTSTORE_PATH} ${SSL_TRUSTSTORE_PASS}
