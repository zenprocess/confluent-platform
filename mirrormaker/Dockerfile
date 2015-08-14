# Builds a docker image for Kafka MirrorMaker.
# Expects links to "kafka" and "zookeeper" containers.
#
# Usage:
#   docker build -t confluent/mirror-maker mirror-maker
#   docker run -d --name mirror-maker confluent/mirror-maker

FROM cgswong/confluent-platform:1.0b2.11.5

ENV CONFLUENT_USER confluent
ENV CONFLUENT_GROUP confluent
ENV MM_CFG_DIR "/etc/kafka-mirrormaker"

COPY mirror-maker-docker.sh /usr/local/bin/

RUN groupadd -r ${CONFLUENT_GROUP} &&\
    useradd -r -g ${CONFLUENT_GROUP} ${CONFLUENT_USER} &&\
    mkdir -p /etc/kafka-mirrormaker &&\
    chown -R ${CONFLUENT_USER}:${CONFLUENT_GROUP} /usr/local/bin/mirror-maker-docker.sh ${MM_CFG_DIR} &&\
    chmod +x /usr/local/bin/mirror-maker-docker.sh &&\


USER ${CONFLUENT_USER}

VOLUME [ "${MM_CFG_DIR}" ]

CMD [ "/usr/local/bin/mirrormaker-docker.sh" ]
