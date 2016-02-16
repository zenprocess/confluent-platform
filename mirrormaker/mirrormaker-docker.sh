#!/usr/bin/env bash

# Setup shutdown handlers
pid=0
trap 'shutdown_handler' SIGTERM SIGINT

# Write messages to screen
log() {
  echo "$(date +"[%F %X,000]") $(hostname) $1"
}

# Write exit failure messages to syslog and exit with failure code (i.e. non-zero)
die() {
  log "[FAIL] $1" && exit 1
}

shutdown_handler() {
  # Handle Docker shutdown signals to allow correct exit codes upon container shutdown
  log "[INFO] Requesting container shutdown..."
  kill -SIGINT "${pid}"
  log "[INFO] Container stopped."
  exit 0
}

dload() {
  # Download the config file
  url=$1
  dest=$2
  if [ ! -z "${url}" ] && [ ! -z "${dest}" ] && [ $# -eq 2 ]; then
    log "[INFO] Downloading config file from ${url}"
    curl -sSL ${url} --output ${dest} || die "Unable to download ${url}"
  fi
}

varSub() {
  # Process variables and environment
  destFile=$1
  process=$2
  noProcess=$3
  log "[INFO] Processing variables..."
  for var in $(env | grep "^${process}" | grep -v "^${noProcess}" | sort); do
    key=$(echo "${var}" | sed -r "s/${process}(.*)=.*/\1/g" | tr A-Z a-z | tr _ .)
    value=$(echo "${var}" | sed -r 's/.*=(.*)/\1/g')
    if egrep -q "(^|^#)${key}" ${destFile}; then
      sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${value}\\g" ${destFile}
    else
      echo "${key}=${value}" >> ${destFile}
    fi
  done
}

# Setup environment
MM_CS_CFGFILE="/etc/kafka-mirrormaker/consumer.properties"
MM_PD_CFGFILE="/etc/kafka-mirrormaker/producer.properties"

#: ${mm_cs_group_id:="mirrormaker"}
#: ${mm_cs_zookeeper_connect:="${ZOOKEEPER_PORT_2181_TCP_ADDR}:${ZOOKEEPER_PORT_2181_TCP_PORT}"}
#: ${mm_pd_client_id:="mirrormaker"}
#: ${mm_pd_compression_codec:="snappy"}
#: ${mm_pd_metadata_broker_list:="${KAFKA_PORT_9092_TCP_ADDR}:${KAFKA_PORT_9092_TCP_PORT}"}
#: ${mm_pd_producer_type:="async"}
#: ${mm_pd_request_required_acks:=1}
: ${mm_streams:=2}
: ${mm_topics:=".*"}

#export mm_cs_group_id
#export mm_cs_zookeeper_connect
#export mm_pd_client_id
#export mm_pd_compression_codec
#export mm_pd_metadata_broker_list
#export mm_pd_producer_type
#export mm_pd_request_required_acks
export mm_streams
export mm_topics

# Download the config file, if given a URL
dload ${mm_pd_cfg_url} ${MM_PD_CFGFILE}
dload ${mm_cs_cfg_url} ${MM_CS_CFGFILE}

# Process the environment variables
varSub ${MM_PD_CFGFILE} mm_pd_ mm_pd_cfg_
varSub ${MM_CS_CFGFILE} mm_cs_ mm_cs_cfg_

# Check for needed consumer/producer properties
##grep zookeeper.connect ${MM_CS_CFGFILE} &>/dev/null
##[[ $? -ne 0 ]] && die "[MM] Missing mandatory consumer setting: zookeeper.connect"
##grep metadata.broker.list ${MM_PD_CFGFILE} &>/dev/null
##[[ $? -ne 0 ]] && die "[MM] Missing mandatory producer setting: metadata.broker.list"

# The built-in start scripts set the first three system properties here, but
# we add two more to make remote JMX easier/possible to access in a Docker
# environment:
#
#   1. RMI port - pinning this makes the JVM use a stable one instead of
#      selecting random high ports each time it starts up.
#   2. RMI hostname - normally set automatically by heuristics that may have
#      hard-to-predict results across environments.
#
# These allow saner configuration for firewalls, EC2 security groups, Docker
# hosts running in a VM with Docker Machine, etc. See:
#
# https://issues.apache.org/jira/browse/CASSANDRA-7087
if [ -z ${KAFKA_JMX_OPTS} ]; then
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-localhost}"
  export KAFKA_JMX_OPTS
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  [[ "$@" !=  *"--num.streams"* ]] && params=" --num.streams ${mm_streams}"
  [[ "$@" !=  *"--whitelist"* && "$@" !=  *"--blacklist"* ]] && params=${params}" --whitelist=\"${mm_topics}\" "
  exec /usr/bin/kafka-run-class kafka.tools.MirrorMaker --producer.config ${MM_PD_CFGFILE} --consumer.config ${MM_CS_CFGFILE} "$@" $params &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
