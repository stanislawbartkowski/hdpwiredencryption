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
The encryption is enabled for the following services: HDFS, MapReduce/TEZ and Yarn.
In this article I'm going to apply self-signed certificates.
# Steps
 * Create self-signed certificates
 * Distribute and install certificates in SSL KeyStore
 * Configure services for encryption
 


