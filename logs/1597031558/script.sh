ln -s /opt/cloudera/security/pki/$(hostname -f).jks /opt/cloudera/security/pki/keystore.jks 
ln -s /opt/cloudera/security/pki/$(hostname -f).pem /opt/cloudera/security/pki/key.pem
#ln -s /opt/cloudera/security/pki/$(hostname -f).jks /opt/cloudera/security/pki/server.jks
ln -s /opt/cloudera/security/pki/$(hostname -f).pem /opt/cloudera/security/pki/agent.pem
chmod 444 /opt/cloudera/security/pki/*
chmod 400 /opt/cloudera/security/pki/rootCA.*
keytool -list -keystore /opt/cloudera/security/pki/keystore.jks
keytool -list -keystore /opt/cloudera/security/pki/truststore.jks
rm -f passwd