#!/bin/bash

: ${SCALA_VERSIONS:="2.11.11 2.12.2"}
: ${DEFAULT_SCALA_VERSION:="2.11.11"}
: ${CONFLUENT_PLATFORM_VERSION:="3.2.2"}
: ${KAFKA_VERSION:="0.10.2.0"}
: ${ZOOKEEPER_VERSION:="3.4.10"}
: ${DOCKER_BUILD_OPTS:="--rm=true "}
: ${DOCKER_TAG_OPTS:="-f "}
: ${PACKAGE_URL:="http://packages.confluent.io/archive/3.2.2"}

#PRIVATE_REPOSITORY=""
#PUSH_TO_DOCKER_HUB=
