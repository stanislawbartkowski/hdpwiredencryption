# HDP Wired Encryption
https://docs.hortonworks.com/HDPDocuments/HDP3/HDP-3.1.0/configuring-wire-encryption/content/wire_encryption.html

Wired Encryption masks all data which moves into the cluster, inside and out of the HDP cluster. In addition to authorization and authentication, it is another layer of security. Traffic is encrypted not only while dealing with the external world but also internally. Unfortunately, it comes with a price, usually, there is a performance penalty around 10-15% because all data in traffic is to be encrypted and decrypted.<br>

Wired Encryption is adding not only the next layer of security but also another layer of complexity. Unlike Kerberos, it is not automated and manual changes are necessary. It could be a painstaking process for the first time. The HDP documentation provides all necessary information but it is very general and the HDP administrator can be confused trying to extract  practical steps to implement encryption.<br>

In this article, I'm going to alleviate this pain and confusion and provide some practical steps and tools how to deal with that.<br>
<br>
# Prerequisities
The HDP cluster should be installed and healthy. Java and *keytool* is required.<br>

The Wired Encryption does not interact with Kerberos, it does not matter if the cluster is Kerberized or not.<br>
Encryption required certificates which can be signed by Certificate Authority or self-signed. CA-signed certficates are recommended, self-signed certificates make data be encrypted but do not guarantee a full confidentiality.<br>
The encryption method desribed in this article is enabled for the following services: WebHDFS, MapReduce/TEZ and Yarn.<br>
There should passwordless root ssh connection between the host where the tool is installed and all other hosts in the cluster.

# Security concern
The tool ships the scripts to the cluster nodes and executes them. The scripts when the task is completed. Scripts *source.rc* and *custom.rc* contains the key and truststore passwords in plain text and it makes the potential security risk. The scripts are transported to *root/re* directory on all hosts.

# Tools description
The tool comprised several simple and self-explaining bash scripts. The scripts generate and distribute across the cluster self-signed certificates.<br>
 
 Script | Description
------------ | -------------
allkeys.sh | Collects and prepares and distributes the keystore connecting all keys
custom.rc | Custom rc allowing overwriting defaults in source.rc
genkey.sh | Creates self-signed certificate, keystore and truststore
finalize.sh | Completes the procedure, applies all necessary ownerships and permissions to keystores and keys
hosts.txt | List of hostnames of the cluster. The tool is using this list to distribute the certificates
run.sh | The launcher script
source.rc | Settings of common environment variables. The setting can be customized in custom.rc
<br>
The variable description in source.rc. The defaults for key and truststore locations reflect defaults in Ambari configuration panel. <br>

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
SERVER_STOREPASS_PASSWORD| Server keystore password | $SERVER_KEYPASS_PASSWORD | Yes
SERVER_TRUSTSTORE_PASSWORD | Server truststore password | $SERVER_KEYPASS_PASSWORD | Yes
ORGDATA | Organization name | "OU=hw,O=hw,L=paloalto,ST=ca,C=us" | Yes

# Installation and customization
Copy files from *templates* directory and modify.
* hosts.txt : contains the list of all hostnames in the cluster. A passwordless ssh root connection should be configured.
* source.rc : contains some common names and location. Variables in source.rc can be overwritten in custom.rc
* custom.rc : modify the value of the following variables: SERVER_KEYPASS_PASSWORD, SERVER_STOREPASS_PASSWORD, SERVER_TRUSTSTORE_PASSWORD,CLIENT_ALLKEYS_PASSWORD and ORGDATA

# Certificates

## Self-signed certificate 

### Steps
 * Create self-signed certificates
 * Distribute and install certificates in SSL KeyStore
 * Create and distribute a client truststore containing public certificates for all hosts
 * Configure services for encryption

### Create and distribute server certrificate

> ./run.sh 0 <br>
<br>
The tool generates a self-signed certificate for every host and creates server keystore and truststore. Important: the tool wipes out all previous content of /etc/security/clientKeys and serverKeys without warning.<br>
After that, on all hosts, the following directory structure should be created.<br>

* /etc/security/clientKeys : empty directory
* /etc/security/serverKeys
  * keystore.jks
  * \<hostname\>.cert
  * truststore.jks
 
 Verify<br>
 > keytool -list -v  -keystore /etc/security/serverKeys/keystore.jks<br>
 <br>
 Make sure that organization name reflects the customized name found in custom.rc and CN is equal to the full hostname.
 
 # CA-signed certificates
 
## Steps
 * Create self-signed certificates
 * Creates and collects all CSR (Certficate Signing Requests)
 * Manual step: send CSRs to Certtificate Authority to have them signed
 * Next steps are automated assuming that signed certificates follow prescribed structure
 * Distribute and install CA-signed certificates in SSL keystores
 * Create and distribute a client truststore containing public certificates for all hosts
 * Configure services for encryption

## Create self-signed certificates and CSRs

> ./run 3 <br>

Self-signed certificates are created on every node, for every node a CSR is generated and all CSRs are collected in *csrs* directory.

```
ll csrs/
razem 16
-rw-r--r-- 1 root root 743 10-13 09:43 bushily1.fyre.ibm.com.csr
-rw-r--r-- 1 root root 743 10-13 09:43 bushily2.fyre.ibm.com.csr
-rw-r--r-- 1 root root 743 10-13 09:43 bushily3.fyre.ibm.com.csr
-rw-r--r-- 1 root root 737 10-13 09:43 exile1.fyre.ibm.com.csr
```
## Send CSRs to CA Center for signing.

Pick up all CSR files from *csrs* directory and send them for signing.

## Distribute CA-signed certificate across the cluster and prepare a client truststore.

This step can be done by the tool assuming that CA-signed certificates match the below format. Otherwise, preparing a signed keystores and distribute them should be conducted manually.<br>

All CA-signed certificates should be collected in *certs* directory. Certificate for every node including the certifcate chain should be stored in *PEM* format. The certificate file name is expected to follow the format: *\<host name\>.cert.node*.

Example, the list of all hosts in the cluster.
```
exile1.fyre.ibm.com
bushily1.fyre.ibm.com
bushily2.fyre.ibm.com
bushily3.fyre.ibm.com
```
The corresponding *certs* directory.
```
ll certs/

bushily1.fyre.ibm.com.cert.pem
bushily2.fyre.ibm.com.cert.pem
bushily3.fyre.ibm.com.cert.pem
exile1.fyre.ibm.com.cert.pem
```

>./run.sh 4<br>

Signed certificates are imported into appropriate keystores and server truststore is created containig the CA-signed certifcate only.
```
ls /etc/security/serverKeys/ -ltr
exile1.fyre.ibm.com.csr
exile1.fyre.ibm.com.cert.pem
keystore.jks
exile1.fyre.ibm.com.cert
truststore.jks
```
 
## Create and distribute client trustore

>./run.sh 1<br>

The tool creates a client trustore containing the public certificates from all hosts. The trustore is then shipped to all hosts and saved in */etc/security/clientKeys/allkeys.jks* file.<br>
Verify the content of the trustore<br>
> keytool -list -v  -keystore /etc/security/clientKeys/allkeys.jks

The number of entries should be equal to the number of hosts found in *hosts.txt* file
## Finalize

> ./run.sh 2 <br>

 In this step, the tool applies proper ownerships and permissions for keystores and truststores. All files in /etc/security/serverKeys should be visible only for users belonging to *hadoop* group and closed for all other users. File */etc/security/clientKeys/allkeys.jks* should be visible by all.
 
# Configure services for Wired Encryption

The next step is to enable SSL for basic Hadoop services: WebHDFS, MapReduce2, TEZ and Yarn. After applying the settings, the cluster should be restarted and put the changed into force.

### HDFS, server-ssl.xml

| Parameter | Add/modify | Value
| ---- | ---- | ----
| ssl.server.truststore.location | Modify | /etc/security/serverKeys/truststore.jks
| ssl.server.truststore.password | Modify | $SERVER_TRUSTSTORE_PASSWORD
| ssl.server.truststore.type | Accept default | jks
| sl.server.keystore.location | Accept default | /etc/security/serverKeys/keystore.jks
| ssl.server.keystore.password | Modify | $SERVER_KEYPASS_PASSWORD
| ssl.server.keystore.type | Accept default | jks
| ssl.server.keystore.keypassword |Modify | $SERVER_KEYPASS_PASSWORD 

### HDFS, client-ssl.xml 

| Parameter | Add/modify | Value
| ---- | ---- | ----
| ssl.client.truststore.location | Modify | /etc/security/clientKeys/allkeys.jks
| ssl.client.truststore.password | Modify | CLIENT_ALLKEYS_PASSWORD
| ssl.client.truststore.type | Accept default | jks

### HDFS, custom core-site.xml

| Parameter | Add/modify | Value
| ---- | ---- | ----
| hadoop.rpc.protection | Add | privacy (remove authentication)

### HDFS, custom-hdfs.xml
| Parameter | Add/modify | Value
| ---- | ---- | ----
| dfs.encrypt.data.transfer | Add new | true
| dfs.encrypt.data.transfer.algorithm | Add new | 3des

### HDFS, hdfs-site.xml
| Parameter | Add/modify | Value
| ---- | ---- | ----
| dfs.http.policy | Modify | HTTPS_ONLY
| dfs.datanode.https.address | Accept default | 0.0.0.0:50475
| dfs.namenode.https-address | Accept default or Add | \<hostname>\:50470
| dfs.namenode.secondary.https-address | Add only if HA not activated | \<secondary namenode hostname>\:50091

### Yarn, yarn-site.xml
| Parameter | Add/modify | Value
| ---- | ---- | ----
| yarn.http.policy | Modify | HTTPS_ONLY
| yarn.log.server.url | Modify | Change to HTTPS URL : https://\<host\>:19889/jobhistory/logs
| yarn.resourcemanager.webapp.https.address | Accept default | \<host name\>:8090
| yarn.nodemanager.webapp.https.address | Accept default |  0.0.0.0:8042
| yarn.log.server.web-service.url | Modify | Change to HTTPS URL : https://\<host name\>:8190/ws/v1/applicationhistory

### MapReduce2, mapred-site.xml
| Parameter | Add/modify | Value
| ---- | ---- | ----
| mapreduce.jobhistory.http.policy | Modify | HTTPS_ONLY

### MapReduce2, custom mapred-site.xml
| Parameter | Add/modify | Value
| ---- | ---- | ----
| mapreduce.jobhistory.webapp.https.address | Add | \<JHS\>:\<JHS_HTTPS_PORT\> <br> (Yarn history server and secure port)
| mapreduce.ssl.enabled | Add | true
| mapreduce.shuffle.ssl.enabled | Add | true
 
### TEZ, customer tez-site.xml 
| Parameter | Add/modify | Value
| ---- | ---- | ----
| tez.runtime.shuffle.ssl.enable | Add | true
| tez.runtime.shuffle.keep-alive.enabled | Add | true

# Ambari metrics
After setting a wired encryption, Ambari Metrcis component is up and running but metrics are dead. To enable them, the certificate of the host where HDFS NameNode is installed should be imported into Ambari truststore.<br>
The certificate can be downloaded from /etc/security/serverKey/\<hostname\>.cert or copied and pasted from output.<br>

> openssl s_client -connect  \<namenode host\>:50470<br>

The next step is to import the certificate into Ambari truststore<br>

>ambari-server setup-security
```bash
Using python  /usr/bin/python
Security setup options...
===========================================================================
Choose one of the following options: 
  [1] Enable HTTPS for Ambari server.
  [2] Encrypt passwords stored in ambari.properties file.
  [3] Setup Ambari kerberos JAAS configuration.
  [4] Setup truststore.
  [5] Import certificate to truststore.
===========================================================================
Enter choice, (1-5): 5
```
Use 4) if the truststore is not created yet or directly 5) otherwise.<br>
After fixing the truststore, restart Ambari server.

# Verification
### General
Run a health-check for all services. <br>
Launch HDFS, Yarn, and MapReduce2 UIs. Pay attention that browser is using secure, https, connection.
### WebHDFS
Review again HDFS parameters (here NameNode hostname is *mdp1.sb.com*)
* dfs.namenode.http-address *mdp1.sb.com:50070*
* dfs.namenode.https-address *mdp1.sb.com:50470*

The expected result is that non-secure connection on port 50070 is closed and WebHDFS is enabled for secure 50470 port.
<br>
> nc -zv mdp1.sb.com 50070<br>
```
Ncat: Version 7.50 ( https://nmap.org/ncat )
Ncat: Connection refused
```
> nc -zv mdp1.sb.com 50470<br>
```
Ncat: Connected to 192.168.122.129:50470.
Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
```
Test WebHDFS on secure connection.<br>
Kerberos authentication enabled.<br>

> curl -i -k --negotiate -u : -X GET https://mdp1.sb.com:50470/webhdfs/v1/?op=LISTSTATUS<br>

Kerberos authentication disabled.<br>

> curl -i -k -X GET https://mdp1.sb.com:50470/webhdfs/v1/?op=LISTSTATUS
```
HTTP/1.1 401 Authentication required
..........
.........
{"FileStatuses":{"FileStatus":[
{"accessTime":0,"blockSize":0,"childrenNum":3,"fileId":16392,"group":"hadoop","length":0,"modificationTime":1553698288837,"owner":"yarn","pathSuffix":"app-logs","permission":"1777","replication":0,"storagePolicy":0,"type":"DIRECTORY"},
....................
er":"hdfs","pathSuffix":"warehouse","permission":"755","replication":0,"storagePolicy":0,"type":"DIRECTORY"}
]}}
```

