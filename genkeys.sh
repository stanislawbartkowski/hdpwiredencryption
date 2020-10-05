source source.rc
source custom.rc

initdir() {
  rm -rf $CLIENT_KEY_LOCATION $SERVER_KEY_LOCATION
  mkdir -p $SERVER_KEY_LOCATION $CLIENT_KEY_LOCATION

  log "Create self-signed certificate"

  keytool -genkey -alias $ALIAS_NAME -keyalg RSA -keysize 1024 -dname "CN=$HOST_NAME,$ORGDATA" -keystore $KEYSTORE_FILE -storepass $SERVER_KEYPASS_PASSWORD

  [ $? -ne 0 ] && logfail "Failed while creating self-signed certificate"
}

exportcert() {
  log "Export certificate from keystore"

  keytool -export -alias $ALIAS_NAME -keystore $KEYSTORE_FILE -rfc -file $CERTIFICATE_NAME -storepass $SERVER_KEYPASS_PASSWORD

  [ $? -ne 0 ] && logfail "Failed while exporting certificate"

  log "Import certificate into truststore"

  keytool -import -noprompt -alias $ALIAS_NAME -file $CERTIFICATE_NAME -keystore $TRUSTSTORE_FILE -storepass $SERVER_TRUSTSTORE_PASSWORD

  [ $? -ne 0 ] && logfail "Failed while importing certificate"
}

gencsr() {
  log "Generate CSR from keystore"
  keytool -keystore $KEYSTORE_FILE -certreq -alias $ALIAS_NAME -keyalg rsa -file $CSR_NAME -storepass $SERVER_KEYPASS_PASSWORD

  [ $? -ne 0 ] && logfail "Failed while generating CSR file"
}

PAR=$1

case $PAR in 
  0) 
     initdir
     exportcert
     ;;
  1) 
     initdir
     gencsr
     ;;
  2) 
     exportcert
     ;;
  *) logfail "Incorrect parameter, should be 0,1 or 2";;
esac


