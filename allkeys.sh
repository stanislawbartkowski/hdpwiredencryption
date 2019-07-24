source source.rc

TEMPALLKEYS=$KEYS/allkeys.jks

gethost() {
  local -r file=$1
  local -r host=$(openssl x509 -in $file -text -noout -subject | grep subject | cut  -d'=' -f8)
  echo $host
}

rm -f $TEMPALLKEYS

for file in $(ls $KEYS/*cert); do
  host=`gethost $file`
  keytool -import -noprompt -alias $host -file $file -keystore $TEMPALLKEYS -storepass $SERVER_TRUSTSTORE_PASSWORD
  echo $host
done

for file in $(ls $KEYS/*cert); do
  host=`gethost $file`
  scp $TEMPALLKEYS $host:/$ALL_JKS
done
