#!/bin/sh

set +x

source ../common.properties

#### HIVE QUERY FILE ####
echo "!connect jdbc:hive2://${HIVE_HOST}:${HIVE_PORT}/default;principal=hive/_HOST@${KERBEROS_REALM};ssl=true;sslTrustStore=${SSL_TRUSTSTORE_PATH};trustStorePassword=${SSL_TRUSTSTORE_PASS} . . org.apache.hive.jdbc.HiveDriver


CREATE EXTERNAL TABLE testdata (num INT, chr STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' STORED AS TEXTFILE LOCATION '${HIVE_BASE}';

SELECT * FROM testdata;" > hive.ql

beeline -f hive.ql
