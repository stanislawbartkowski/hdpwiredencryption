# HDP Wired Encryption
https://docs.hortonworks.com/HDPDocuments/HDP3/HDP-3.1.0/configuring-wire-encryption/content/wire_encryption.html

Wired Encryption masks all data which moves into the cluster, inside and out of the HDP cluster. In addition to authorization and authentication, it is another layer of security. Traffic is encrypted not only while dealing with external world but also internally. Unfortunately, it comes with price, usually there is a performance penalty around 10-15% because all data in traffic is to be encrypted and decrypted.<br>
Wired Encryption is adding not only next layer of security but also another layer of complexity. Unlike Kerberos, it is not automated and manual changes are necessary. If could be a painstaking process for the first time. The HDP documentation provides all necessary information but it is very general and the HDP administrator can be confused trying to extract a practical steps to implement encryption.
<br>
In this article I'm going to alleviate this pain and confusion and provide some practical steps and tools how to deal with that.<br>
<br>
# Prerequisities
The HDP cluster should be installed and healthy.<br>
The Wired Encryption does not interact with Kerberos, it does not matter if the cluster is Kerberized or not.<br>
Encryption required certificates. Certificates can be signed by Trusted Authority. It is recommended but not always available. Another method is to use self-signed certificates which causes data to be encrypted and does not guarantee a full confidentiality.<br>
The encryption is enabled for the following services: HDFS, MapReduce/TEZ and Yarn.<br>
In this article I'm going to apply self-signed certificates.<br>
There should passwordless root ssh connection between the hosts where the tools is installed and all other hosts in the cluster.
# Steps
 * Create self-signed certificates
 * Distribute and install certificates in SSL KeyStore
 * Configure services for encryption
 # Certificates
 ## Tools description
 The tool comprised several simple and self explaining bash scripts. The scripts generate and distribute across the cluster self-signed certificates.<br>
 
 Script | Description
------------ | -------------
allkeys.sh | Collects and prepares and distributes the keystore connecting all keys
custom.rc | Custom rc allowing overwriting defaults in source.rc
finalize.sh | Completes the procedure, applies all necessary ownerships and permissions to keystores and keys
hosts.txt | List of hostnames of the cluster. The tool is using this list to distribute the certificates
run.sh | The launcher script
source.rc | Settings of common environment variables. The setting can be customized in custom.rc
<br>
The variable description in source.rc. The defaults for key and truststore locations reflects defaults in Ambari configuration panel. <br>

Variable | Description | Default | Customize
-------- | ----------- | ----------- | -----------
SERVER_KEY_LOCATION | Directory to keep server keys | /etc/security/serverKeys | No
CLIENT_KEY_LOCATION | Directory to keep client keys | /etc/security/clientKeys | No:q!
HOST_NAME | Host name, assigned automatically | $HOSTNAME | No
KEYSTORE_FILE | Server keystore file | $SERVER_KEY_LOCATION/keystore.jks | No
TRUSTSTORE_FILE | Server truststore file | $SERVER_KEY_LOCATION/truststore.jks | No
CERTIFICATE_NAME | Server certificate file | $SERVER_KEY_LOCATION/$HOST_NAME.cert | No
ALL_JKS | Client keys | $CLIENT_KEY_LOCATION/allkeys.jks | No
YARN_USER | Yarn user | yarn | No
KEYS | Temporary directory | keys | No
SERVER_KEYPASS_PASSWORD | Server key password | test1234 | Yes
SERVER_STOREPASS_PASSWORD| Server keystore password | $SERVER_KEYPASS_PASSWORD | Yes
SERVER_TRUSTSTORE_PASSWORD | Server truststore password | $SERVER_KEYPASS_PASSWORD | Yes
ORGDATA | DN certificate name | "OU=hw,O=hw,L=paloalto,ST=ca,C=us" | Yes
## Installation and customization
Copy files from *templates* directory and modify.
* hosts.txt : contains the list of all hostnames in the cluster. A passwordless ssh root connection should be configured.
* custom.rc : modify the value of the following variables: SERVER_KEYPASS_PASSWORD, SERVER_STOREPASS_PASSWORD, SERVER_TRUSTSTORE_PASSWORD and ORGDATA
## Create and distribute server certrificate

> ./run.sh 0 <br>
<br>
The tool generates self-signed certificate for every hosts and creates server keystore and truststore.





