#!/bin/bash

[ -z "${CONCURRENT+x}" ] && CONCURRENT="100"
[ -z "${THREADS+x}" ] && THREADS="1"
[ -z "${CPU_SCALING+x}" ] && CPU_SCALING="1"
[ -z "${DURATION+x}" ] && DURATION="30"
[ -z "${HOST+x}" ] && HOST="www.example.com"
[ -z "${IPS+x}" ] && IPS="127.0.0.1 127.0.1.1"
[ -z "${PROTO+x}" ] && PROTO="http"
[ -z "${URI+x}" ] && URI="/foo"
[ -z "${RANDOMIZE+x}" ] && RANDOMIZE="false"
[ -z "${PAUSE+x}" ] && PAUSE="1"

if [ -z "${PORT+x}" ]
then
  if [ "$PROTO" = "http" ]
  then
    PORT=80
  else
    PORT=443
  fi
fi

running=true

_term() { 
  echo "Exiting"
  for wrk in "${wrks}"
  do
    kill -TERM "$wrk" 2>/dev/null
  done
  running=false
}

launch() {
  cpu=$1
  scaling=$2
  concurrent=$3
  threads=$4
  duration=$5
  pause=$6

  for procs in $(seq 0 $(( $scaling -1 )) )
  do
    target="${IP_ARRAY[$(( $RANDOM % ${#IP_ARRAY[*]} ))]}"
    date +"%F %T: Launching: taskset -c $cpu wrk -c ${concurrent} -t ${threads} -d ${duration}m -H \"Host: ${HOST}\" \"${PROTO}://${target}:${PORT}${URI}\""
    taskset -c "$cpu" wrk -c "${concurrent}" -t "${threads}" -d "${duration}m" -H "Host: ${HOST}" "${PROTO}://${target}:${PORT}${URI}" &
    wrks="${wrks} $!"
  done
  date +"%F %T: Pausing: $pause seconds"
  sleep $pause
}

trap _term SIGTERM

IP_ARRAY=( $IPS )
CPUS=$(getconf _NPROCESSORS_ONLN)

date +"%F %T: Starting wrk: CPUS: ${CPUS}, IPS: ${#IP_ARRAY[*]}"
date +"%F %T: Target IPS: ${IPS}"

for cpu in $(seq 0 $((  $CPUS -1  )) )
do
  if [ "$RANDOMIZE" == "true" ]
  then
    scaling=$(( $RANDOM % $CPU_SCALING + 1 ))
    threads=$(( $RANDOM % $THREADS + 1 ))
    concurrent=$(( $RANDOM % $CONCURRENT + $threads ))
    duration=$(( $RANDOM % $DURATION + 1 ))
    pause=$(( $RANDOM % $PAUSE + 1 ))
    launch "$cpu" "$scaling" "$concurrent" "$threads" "$duration" "$pause"
  else
    launch "$cpu" "$CPU_SCALING" "$CONCURRENT" "$THREADS" "$DURATION" "$PAUSE"
  fi
done

sleeps=0
while [ "$running" == "true" ];
do
  sleeps=$(( $sleeps + 1 ))
  [ "$(( $sleeps % 6 ))" -eq "0" ] && date +"%F %T: Waiting for wrk to be done"
  sleep 5
  procs=$(ps -ef | grep wrk | grep -v grep)
  if [ -z "${procs}" ]
  then
    date +"%F %T: All wrk processes have completed."
    running=false
  fi
done


