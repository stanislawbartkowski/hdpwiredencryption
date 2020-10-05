source source.rc
source custom.rc

CACERT=$SERVER_KEY_LOCATION/$HOST_NAME$CACERT_APP
log "Import $CACERT to $KEYSTORE_FILE"
keytool -importcert -alias $ALIAS_NAME -keystore $KEYSTORE_FILE -storepass $SERVER_KEYPASS_PASSWORD  -trustcacerts -file $CACERT -noprompt
[ $? -ne 0 ] && logfail "Failed while importing CA signed certificate"
