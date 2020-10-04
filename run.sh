source source.rc
source custom.rc


printhelp() {
  echo "run.sh /phase/"
  echo ""
  echo "phase parameter:"
  echo " 0 - generate keys"
  echo " 1 - generate allkeys"
  echo " 2 - finalize"
}



copyremote() {
  local -r host=$1
  local -r script=$2
  log "copy $script to $host"
  scp $script $host:$EXCATALOG/$script
  [ $? -ne 0 ] && logfail "Failed while copying to remove host"
}

runcommand() {
  local -r script=$1
  while read -r host; do
    [ -z "$host" ] && continue
    echo "copy scripts to remote $host"
    ssh -n $host mkdir -p $EXCATALOG
    [ $? -ne 0 ] && logfail "Cannot create remove catalog $EXCATALOG"
    copyremote $host custom.rc
    copyremote $host source.rc
    copyremote $host $script
    ssh -n $host "cd $EXCATALOG; ./$script"
    echo $PWD
  done <hosts.txt
}

collectallkeys() {
  rm -rf $KEYS
  mkdir $KEYS
  log "Collects certificate from all hosts"
  while read -r host; do
    scp $host:$SERVER_KEY_LOCATION/$host.cert $KEYS
    [ $? -ne 0 ] && logfail "Cannot copy back certficate from remote location"
  done <hosts.txt
}

PAR=$1
EXCATALOG=re
KEYSDIR=keys

case $PAR in
   0) echo "$PAR - generate keys on all hosts"
      runcommand genkeys.sh
     ;;
   1) echo "$PAR - generate allkeys store"
     collectallkeys
     ./allkeys.sh
     ;;
   2) echo "$PAR - finalize"
     runcommand finalize.sh
     ;;
   *) echo "Incorrect parameter"
      printhelp
      ;;
esac
