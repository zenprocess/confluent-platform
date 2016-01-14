#!/bin/bash

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

# Setup environment
RP_CFGFILE="/etc/kafka-rest/kafka-rest.properties"

# Download the config file, if given a URL
if [ ! -z "${rp_cfg_url}" ]; then
  log "Downloading config file from ${sr_cfg_url}"
  curl -sSL ${rp_cfg_url} --output ${RP_CFGFILE} || die "Unable to download ${rp_cfg_url}"
fi

: ${rp_debug:=true}
: ${rp_id:="kafka-rest-1"}
: ${rp_port:=8082}
: ${rp_schema_registry_url:="http://${SR_PORT_8081_TCP_ADDR}:${SR_PORT_8081_TCP_PORT}"}
: ${rp_zookeeper_connect:="${ZOOKEEPER_PORT_2181_TCP_ADDR}:${ZOOKEEPER_PORT_2181_TCP_PORT}"}

export rp_debug
export rp_id
export rp_port
export rp_schema_registry_url
export rp_zookeeper_connect

# Process general environment variables
for VAR in $(env | grep '^rp_' | grep -v '^rp_cfg_' | sort); do
  key=$(echo "${VAR}" | sed -r "s/rp_(.*)=.*/\1/g" | tr _ .)
  value=$(echo "${VAR}" | sed -r "s/(.*)=.*/\1/g")
  if egrep -q "(^|^#)${key}" ${RP_CFGFILE}; then
    sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${RP_CFGFILE}
  else
    echo "$key=${!value}" >> ${RP_CFGFILE}
  fi
done

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
if [ -z ${KAFKAREST_JMX_OPTS} ]; then
  KAFKAREST_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
  KAFKAREST_JMX_OPTS="${KAFKAREST_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  KAFKAREST_JMX_OPTS="${KAFKAREST_JMX_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  KAFKAREST_JMX_OPTS="${KAFKAREST_JMX_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  KAFKAREST_JMX_OPTS="${KAFKAREST_JMX_OPTS} -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$rp_host_name}"
  export KAFKAREST_JMX_OPTS
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  exec /usr/bin/kafka-rest-start ${RP_CFGFILE} "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
