# Builds a docker image for the Confluent schema registry.
# Expects links to "kafka" and "zookeeper" containers.
#
# Usage:
#   docker build -t confluent/schema-registry schema-registry
#   docker run -d --name schema-registry --link zookeeper:zookeeper --link kafka:kafka \
#       --env SCHEMA_REGISTRY_AVRO_COMPATIBILITY_LEVEL=none confluent/schema-registry

FROM cgswong/confluent-platform:1.0.1

ENV CONFLUENT_USER confluent
ENV CONFLUENT_GROUP confluent
ENV SR_CFGDIR "/etc/schema-registry"
ENV JMX_PORT 19092

COPY schema-registry-docker.sh /usr/local/bin/
COPY log4j.properties ${SR_CFGDIR}/

RUN groupadd -r ${CONFLUENT_GROUP} &&\
    useradd -r -g ${CONFLUENT_GROUP} ${CONFLUENT_USER} &&\
    chown -R ${CONFLUENT_USER}:${CONFLUENT_GROUP} ${SR_CFGDIR}/schema-registry.properties /usr/local/bin/schema-registry-docker.sh &&\
    chmod +x /usr/local/bin/schema-registry-docker.sh

USER $CONFLUENT_USER
VOLUME ["${SR_CFGDIR}"]
# Expose client port (8081/http), JMX
EXPOSE 8081 ${JMX_PORT}

ENTRYPOINT ["/usr/local/bin/schema-registry-docker.sh"]
