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

: ${ZOOCFGDIR:="/etc/kafka"}
: ${ZOOCFG:="zookeeper.properties"}

: ${zk_clientPort:=2181}
: ${zk_dataDir:="/var/lib/zookeeper"}
: ${zk_id:=1}
: ${zk_initLimit:=5}
: ${zk_maxClientCnxns:=0}
: ${zk_syncLimit:=2}
: ${zk_tickTime:=2000}

export ZOOCFG
export ZOOCFGDIR
export zk_clientPort
export zk_dataDir
export zk_id
export zk_initLimit
export zk_maxClientCnxns
export zk_syncLimit
export zk_tickTime

# Download the config file, if given a URL
if [ ! -z "$zk_cfg_url" ]; then
  log "[INFO] Downloading config file from ${zk_cfg_url}"
  curl -sSL --output ${ZOOCFGDIR}/${ZOOCFG} ${zk_cfg_url} || die "Unable to download ${zk_cfg_url}"
elif [ ! -f ${ZOOCFGDIR}/${ZOOCFG} ]
  touch ${ZOOCFGDIR}/${ZOOCFG}
fi

# Set Zookeeper ID
echo $zk_id > $zk_dataDir/myid

# Process env variables
log "[INFO] Processing config file..."
for var in $(env | grep -v '^zk_cfg_' | grep '^zk_' | sort); do
  key=$(echo $var | sed -r 's/zk_(.*)=.*/\1/g' | tr _ .)
  value=$(echo $var | sed -r 's/.*=(.*)/\1/g')
  if egrep -q "(^|^#)${key}" ${ZOOCFGDIR}/${ZOOCFG}; then
    sed -r -i "s\\(^|^#)${key}=.*$\\${key}=${!value}\\g" ${ZOOCFGDIR}/${ZOOCFG}
  else
    echo "$key=${!value}" >> ${ZOOCFGDIR}/${ZOOCFG}
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
log "[INFO] Setting up JMX."
if [ -z ${KAFKA_JMX_OPTS} ]; then
  KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote=true"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.authenticate=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.ssl=false"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
  KAFKA_JMX_OPTS="${KAFKA_JMX_OPTS} -Djava.rmi.server.hostname=${JAVA_RMI_SERVER_HOSTNAME:-$(hostname -f)} "
  export KAFKA_JMX_OPTS
fi

cat ${ZOOCFGDIR}/${ZOOCFG} | log

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ "$1" == "-"* || -z $1 ]]; then
  exec /usr/bin/zookeeper-server-start.sh ${ZOOCFG} "$@" &
  pid=$!
  log "[INFO] Started with PID: ${pid}"
  wait ${pid}
  trap - SIGTERM SIGINT
  wait ${pid}
else
  exec "$@"
fi
