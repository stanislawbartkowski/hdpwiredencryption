source source.rc
source custom.rc

rm -rf $CLIENT_KEY_LOCATION $SERVER_KEY_LOCATION
mkdir -p $SERVER_KEY_LOCATION $CLIENT_KEY_LOCATION

log "Create self-signed certificate"

keytool -genkey -alias $HOST_NAME -keyalg RSA -keysize 1024 -dname "CN=$HOST_NAME,$ORGDATA" -keystore $KEYSTORE_FILE -storepass $SERVER_KEYPASS_PASSWORD

[ $? -ne 0 ] && logfail "Failed while creating self-signed certificate"

log "Export certificate from keystore"

keytool -export -alias $HOST_NAME -keystore $KEYSTORE_FILE \
  -rfc -file $CERTIFICATE_NAME -storepass $SERVER_KEYPASS_PASSWORD

[ $? -ne 0 ] && logfail "Failed while exporting certificate"

log "Import certificate into truststore"

keytool -import -noprompt -alias $HOST_NAME -file $CERTIFICATE_NAME \
  -keystore $TRUSTSTORE_FILE -storepass $SERVER_TRUSTSTORE_PASSWORD

[ $? -ne 0 ] && logfail "Failed while importing certificate"
