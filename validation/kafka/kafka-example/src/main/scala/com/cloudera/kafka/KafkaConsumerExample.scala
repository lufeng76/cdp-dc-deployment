package com.cloudera.kafka

import java.util.Properties
import org.apache.kafka.clients.consumer.KafkaConsumer
import scala.collection.JavaConverters._

object KafkaConsumerExample {
    def main(args: Array[String]): Unit = {
        if (args.length < 5) {
            System.err.println("Usage: KafkaConsumerExample <topic> <bootstrap servers> <group> <truststore> <truststore pass")
            System.exit(1)
        }

        val topic = args(0)
        val bootstrap = args(1)
        val group = args(2)
        val truststore = args(3)
        val trustpassw = args(4)
        val props = new Properties()

        props.put("bootstrap.servers", bootstrap)
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
        props.put("security.protocol", "SASL_SSL")
        props.put("sasl.kerberos.service.name", "kafka")
        props.put("ssl.truststore.location", truststore)
        props.put("ssl.truststore.password", trustpassw)
        props.put("group.id", group)

        val consumer = new KafkaConsumer[String, String](props)

        consumer.subscribe(java.util.Collections.singletonList(topic))

        while (true) {
            val records = consumer.poll(100)
            for (record<-records.asScala) {
                println(record)
            }
        }
    }
}
