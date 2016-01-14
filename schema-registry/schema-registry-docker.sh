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

# Setup environment
SR_CFGFILE="/etc/schema-registry/schema-registry.properties"

# Download the config file, if given a URL
if [ ! -z "${sr_cfg_url}" ]; then
  log "Downloading config file from ${sr_cfg_url}"
  curl -sSL ${sr_cfg_url} --output ${SR_CFGFILE} || die "Unable to download ${sr_cfg_url}"
fi

: ${sr_debug:=true}
: ${sr_kafkastore_connection_url:="${ZOOKEEPER_PORT_2181_TCP_ADDR}:${ZOOKEEPER_PORT_2181_TCP_PORT}"}
: ${sr_kafkastore_topic:="_schemas"}
: ${sr_port:=8081}
: ${sr_schema_registry_zk_namespace:="schema_registry"}

export sr_debug
export sr_kafkastore_connection_url
export sr_kafkastore_topic
export sr_port
export sr_schema_registry_zk_namespace

# Process general environment variables
for VAR in $(env | grep '^sr_' | grep -v '^sr_cfg_' | sort); do
  key=$(echo "${VAR}" | sed -r "s/sr_(.*)=.*/\1/g" | tr _ .)
  value=$(echo "${VAR}" | sed -r "s/(.*)=.*/\1/g")
  if egrep -q "(^|^#)${key}" ${SR_CFGFILE}; then
    sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${SR_CFGFILE}
  else
    echo "$key=${!value}" >> ${SR_CFGFILE}
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
if [ -z ${SCHEMA_REGISTRY_JMX_OPTS} ]; then
  SCHEMA_REGISTRY_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
  SCHEMA_REGISTRY_JMX_OPTS="${SCHEMA_REGISTRY_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  SCHEMA_REGISTRY_JMX_OPTS="${SCHEMA_REGISTRY_JMX_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  SCHEMA_REGISTRY_JMX_OPTS="${SCHEMA_REGISTRY_JMX_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  SCHEMA_REGISTRY_JMX_OPTS="${SCHEMA_REGISTRY_JMX_OPTS} -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$kafka_advertised_host_name} "
  export SCHEMA_REGISTRY_JMX_OPTS
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  exec /usr/bin/schema-registry-start ${SR_CFGFILE} "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
