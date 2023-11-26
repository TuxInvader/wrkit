#!/bin/bash

[ -z "${CONCURRENT+x}" ] && CONCURRENT="100"
[ -z "${THREADS+x}" ] && THREADS="1"
[ -z "${CPU_SCALING+x}" ] && CPU_SCALING="1"
[ -z "${DURATION+x}" ] && DURATION="30m"
[ -z "${HOST+x}" ] && HOST="www.example.com"
[ -z "${IPS+x}" ] && IPS="127.0.0.1 127.0.1.1"
[ -z "${PROTO+x}" ] && PROTO="http"
[ -z "${URI+x}" ] && URI="/foo"

running=true

_term() { 
  echo "Exiting"
  for wrk in "${wrks}"
  do
    kill -TERM "$wrk" 2>/dev/null
  done
  running=false
}

trap _term SIGTERM

IP_ARRAY=( $IPS )
CPUS=$(getconf _NPROCESSORS_ONLN)

date +"%F %T: Starting wrk: CPUS: ${CPUS}, IPS: ${#IP_ARRAY[*]}"
date +"%F %T: Target IPS: ${IPS}"

for cpu in $(seq 0 $((  $CPUS -1  )) )
do
  for procs in $(seq 0 $(( $CPU_SCALING -1 )) )
  do
    target="${IP_ARRAY[$(( $RANDOM % ${#IP_ARRAY[*]} ))]}"
    date +"%F %T: Launching: taskset -c $cpu wrk -c ${CONCURRENT} -t ${THREADS} -d ${DURATION} -H \"HOST: ${HOST}\" \"${PROTO}://${target}${URI}\""
    taskset -c $cpu wrk -c ${CONCURRENT} -t ${THREADS} -d ${DURATION} -H "HOST: ${HOST}" "${PROTO}://${target}${URI}" &
    wrks="${wrks} $!"
  done
  sleep 1
done

while [ "$running" == "true" ];
do
  date +"%F %T: Waiting for wrk to be done"
  sleep 5
  procs=$(ps -ef | grep wrk | grep -v grep)
  if [ -z "${procs}" ]
  then
    date +"%F %T: All wrk processes have completed."
    running=false
  fi
done


