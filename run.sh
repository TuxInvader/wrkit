#!/bin/bash

[ -z "${CONCURRENT+x}" ] && CONCURRENT="50"
[ -z "${CONCURRENT_FIXED+x}" ] && CONCURRENT_FIXED="false"
[ -z "${THREADS+x}" ] && THREADS="1"
[ -z "${CPU_SCALING+x}" ] && CPU_SCALING="1"
[ -z "${CPU_CORES+x}" ] && CPU_CORES="0"
[ -z "${DURATION+x}" ] && DURATION="60"
[ -z "${MIN_DURATION+x}" ] && MIN_DURATION="1"
[ -z "${HOST+x}" ] && HOST="www.example.com"
[ -z "${IPS+x}" ] && IPS="127.0.0.1 127.0.1.1"
[ -z "${PROTO+x}" ] && PROTO="http"
[ -z "${URI+x}" ] && URI="/"
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
CPUS_ACTUAL=$CPUS

# limit cores to CPU_CORES if it was set
if [ "$CPU_CORES" -gt 0 ]
then
  if [ "$CPU_CORES" -lt "$CPUS" ]
  then
    CPUS="$CPU_CORES"
  fi
fi

date +"%F %T: Starting wrk: Available CPUs: ${CPUS_ACTUAL}, Using: ${CPUS}, IPS: ${#IP_ARRAY[*]}"
date +"%F %T: Target IPS: ${IPS}"

for cpu in $(seq 0 $((  $CPUS -1  )) )
do
  if [ "$RANDOMIZE" == "true" ]
  then
    scaling=$(( $RANDOM % $CPU_SCALING + 1 ))
    threads=$(( $RANDOM % $THREADS + 1 ))
    if [ "$CONCURRENT_FIXED" == "true" ]
    then
      concurrent=$CONCURRENT
    else
      concurrent=$(( $RANDOM % $CONCURRENT + $threads ))
    fi
    duration=$(( $RANDOM % $DURATION + $MIN_DURATION ))
    pause=$(( $RANDOM % $PAUSE + 1 ))
    launch "$cpu" "$scaling" "$concurrent" "$threads" "$duration" "$pause"
  else
    launch "$cpu" "$CPU_SCALING" "$CONCURRENT" "$THREADS" "$DURATION" "$PAUSE"
  fi
done

sleeps=0
while [ "$running" == "true" ];
do
  procs=$(ps -ef | grep wrk | grep -v grep | wc -l)
  [ "$(( $sleeps % 6 ))" -eq "0" ] && date +"%F %T: Waiting for $procs wrk processes to complete"
  if [ "${procs}" -eq 0 ]
  then
    date +"%F %T: All wrk processes have completed."
    running=false
  fi
  sleep 5
  sleeps=$(( $sleeps + 1 ))
done


