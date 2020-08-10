export jkspassword=cloudera
echo $jkspassword > passwd
echo $jkspassword >> passwd
keytool -genkeypair -alias $(hostname -f) -keyalg RSA -keystore /opt/cloudera/security/pki/$(hostname -f).jks -keysize 2048 -dname "CN=$(hostname -f)" -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera < passwd
keytool -certreq -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).csr -ext san=dns:$(hostname -f),dns:${HOSTNAME}${1}  -storepass cloudera
openssl x509 -req -CA /opt/cloudera/security/pki/rootCA.crt -CAkey /opt/cloudera/security/pki/rootCA.key -CAcreateserial -days 500 -sha256 -in /opt/cloudera/security/pki/$(hostname -f).csr -out /opt/cloudera/security/pki/$(hostname -f).crt
cat /opt/cloudera/security/pki/rootCA.crt >> /opt/cloudera/security/pki/$(hostname -f).crt
echo "yes" | keytool -importcert -alias $(hostname -f) -keystore /opt/cloudera/security/pki/$(hostname -f).jks -file /opt/cloudera/security/pki/$(hostname -f).crt  -storepass cloudera
keytool -importkeystore -srckeystore /opt/cloudera/security/pki/$(hostname -f).jks -destkeystore /opt/cloudera/security/pki/$(hostname -f).p12 -srcalias $(hostname -f) -srcstoretype jks -deststoretype pkcs12  -storepass cloudera < passwd
openssl pkcs12 -in /opt/cloudera/security/pki/$(hostname -f).p12 -out /opt/cloudera/security/pki/$(hostname -f).pem -password pass:cloudera -passin pass:cloudera -passout pass:cloudera