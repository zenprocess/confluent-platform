#!/usr/bin/env bash

# Set values
pkg=${BASH_SOURCE##*/}

# set colors
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
purple=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
reset=$(tput sgr0)

# Write messages to screen
log() {
  echo "$(date +"%F %T") $(hostname) [${pkg}] $1"
}

# Write exit failure messages to syslog and exit with failure code (i.e. non-zero)
die() {
  log "${red}[FAIL] $1${reset}" && exit 1
}

: ${SCALA_VERSIONS:="2.9.1 2.9.2 2.10.4 2.11.5"}
: ${DEFAULT_SCALA_VERSION:="2.10.4"}
: ${CP_VERSION:="1.0.1"}

for SCALA_VERSION in ${SCALA_VERSIONS}; do
  cp confluent-platform/Dockerfile confluent-platform/Dockerfile.${CP_VERSION}b${SCALA_VERSION}
  sed -e "s/ENV SCALA_VERSION=.*/ENV SCALA_VERSION=\"${SCALA_VERSION}\"/" -e "s/ENV CP_VERSION=.*/ENV CP_VERSION=\"${CP_VERSION}\"/" -i confluent-platform/Dockerfile.${CP_VERSION}b${SCALA_VERSION}
  TAGS="cgswong/confluent-platform:${CP_VERSION}b${SCALA_VERSION}"
  [ "x$SCALA_VERSION" = "x$DEFAULT_SCALA_VERSION" ] && TAGS="${TAGS} cgswong/confluent-platform:${CP_VERSION}"
  for TAG in ${TAGS}; do
    log "${yellow}Building ${TAG}${reset}"
    docker build -t ${TAG} -f confluent-platform/Dockerfile.${CP_VERSION}b${SCALA_VERSION} confluent-platform/
    [ $? -eq 0 ] && log "${green}(PASS) ${TAG}${reset}" || log "${red}(FAIL) ${TAG}${reset}"
  done
done

log "${yellow}Re-building dependencies...${reset}"
log "${yellow}Building cgswong/confluent-zookeeper:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-zookeeper:${CP_VERSION} zookeeper/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"

log "${yellow}Building cgswong/confluent-kafka:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-kafka:${CP_VERSION} kafka/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"

log "${yellow}Building cgswong/confluent-schema-registry:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-schema-registry:${CP_VERSION} schema-registry/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"

log "${yellow}Building cgswong/confluent-rest-proxy:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-rest-proxy:${CP_VERSION} rest-proxy/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"

log "${yellow}Building cgswong/confluent-tools:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-tools:${CP_VERSION} tools/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"

log "${yellow}Building cgswong/confluent-mirrormaker:${CP_VERSION}${reset}"
docker build -t cgswong/confluent-mirrormaker:${CP_VERSION} mirrormaker/
[ $? -eq 0 ] && log "${green}(PASS)${reset}" || log "${red}FAIL!${reset}"
