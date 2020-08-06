package com.cloudera.kafka

import java.util.Properties
import org.apache.kafka.clients.producer._
import scala.collection.JavaConverters._

object KafkaProducerExample {
    def main(args: Array[String]): Unit = {
        if (args.length < 5) {
            System.err.println("Usage: KafkaProducerExample <topic> <bootstrap servers> <num of messages> <truststore> <truststore pass")
            System.exit(1)
        }

        val topic = args(0)
        val bootstrap = args(1)
        val num = args(2).toInt
        val truststore = args(3)
        val trustpassw = args(4)

        val props = new Properties()
 
        props.put("bootstrap.servers", bootstrap)
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
        props.put("security.protocol", "SASL_SSL")
        props.put("sasl.kerberos.service.name", "kafka")
        props.put("ssl.truststore.location", truststore)
        props.put("ssl.truststore.password", trustpassw)

        val producer = new KafkaProducer[String, String](props)
   
        for (i <- 1 to num) {
            val record = new ProducerRecord(topic, "key", s"hello $i")
            producer.send(record)
        }
    
       val record = new ProducerRecord(topic, "key", "the end "+new java.util.Date)

       producer.send(record)
       producer.close()
    }
}
