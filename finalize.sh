source source.rc
source custom.rc

log "Finalize, apply permissions"

chown -R $YARN_USER:hadoop $SERVER_KEY_LOCATION
chown -R $YARN_USER:hadoop $CLIENT_KEY_LOCATION
chmod 755 $SERVER_KEY_LOCATION
chmod 755 $CLIENT_KEY_LOCATION
chmod 440 $KEYSTORE_FILE
chmod 440 $TRUSTSTORE_FILE
chmod 440 $CERTIFICATE_NAME
chmod 444 $ALL_JKS
