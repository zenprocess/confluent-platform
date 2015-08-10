# Builds a docker image for Kafka MirrorMaker.
# Expects links to "kafka" and "zookeeper" containers.
#
# Usage:
#   docker build -t confluent/mirror-maker mirror-maker
#   docker run -d --name mirror-maker --link zookeeper:zookeeper --link kafka:kafka \
#       confluent/mirror-maker

FROM cgswong/confluent-platform:1.0b2.11.5

ENV CONFLUENT_USER confluent
ENV CONFLUENT_GROUP confluent

COPY mirror-maker-docker.sh /usr/local/bin/

RUN groupadd -r ${CONFLUENT_GROUP} &&\
    useradd -r -g ${CONFLUENT_GROUP} ${CONFLUENT_USER} &&\
    chown -R ${CONFLUENT_USER}:${CONFLUENT_GROUP} /etc/kafka-rest /usr/local/bin/mirror-maker-docker.sh &&\
    chmod +x /usr/local/bin/mirror-maker-docker.sh &&\


USER ${CONFLUENT_USER}

EXPOSE 8082

CMD [ "/usr/local/bin/mirror-maker-docker.sh" ]
