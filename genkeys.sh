source source.rc

rm -rf $CLIENT_KEY_LOCATION $SERVER_KEY_LOCATION
mkdir -p $SERVER_KEY_LOCATION $CLIENT_KEY_LOCATION

keytool -genkey -alias $HOST_NAME -keyalg RSA -keysize 1024 \
  -dname "CN=$HOST_NAME,$ORGDATA" \
  -keypass $SERVER_KEYPASS_PASSWORD -keystore $KEYSTORE_FILE \
  -storepass $SERVER_STOREPASS_PASSWORD \

keytool -export -alias $HOST_NAME -keystore $KEYSTORE_FILE \
  -rfc -file $CERTIFICATE_NAME -storepass $SERVER_STOREPASS_PASSWORD

keytool -import -noprompt -alias $HOST_NAME -file $CERTIFICATE_NAME \
  -keystore $TRUSTSTORE_FILE -storepass $SERVER_TRUSTSTORE_PASSWORD
