## Confluent Platform Tools
Provides command line tools for the [Confluent Platform](http://www.Confluent.io).

## How to use this image
Typically you would link the container, either on a local machine or a remote machine, to ZooKeeper, Kafka, and Schema Registry instances. The below is an example locally linked invocation:
```sh
docker run -it --rm --link zookeeper:zookeeper --link kafka:kafka --link schema_registry:schema_registry cgswong/confluent-tools \
  kafka-avro-console-consumer --property print.key=true --topic test --from-beginning
```

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
