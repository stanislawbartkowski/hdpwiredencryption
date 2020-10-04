source source.rc
source custom.rc

TEMPALLKEYS=$KEYS/allkeys.jks

gethost() {
  local -r file=$1
  local -r host=$(openssl x509 -in $file -text -noout -subject | grep subject | cut  -d'=' -f8)
  echo $host
}


rm -f $TEMPALLKEYS

log "Import certficates into $TEMPALLKEYS"

for file in $(ls $KEYS/*cert); do
  host=`gethost $file`
  keytool -import -noprompt -alias $host -file $file -keystore $TEMPALLKEYS -storepass $SERVER_TRUSTSTORE_PASSWORD
  [ $? -ne 0 ] && logfail "Failed while importing"

  echo $host
done

log "Distribute $TEMPALLKEY across the cluster"

for file in $(ls $KEYS/*cert); do
  host=`gethost $file`
  log "Copy to $host"
  scp $TEMPALLKEYS $host:/$ALL_JKS
  [ $? -ne 0 ] && logfail "Failed while copying"
done
