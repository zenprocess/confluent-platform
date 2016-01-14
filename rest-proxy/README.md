## Confluent Platform Kafka RESET Proxy
This is a highly configurable Dockerized [Confluent Platform Kafka REST Proxy](http://docs.confluent.io/2.0.0/kafka-rest/docs/index.html).

## How to use this image
The container can be configured via environment variables where any [Kafka REST Proxy property](http://docs.confluent.io/2.0.0/kafka-rest/docs/config.html) can be set after `rp_` with underscore instead of period ('.') used. For example:

| Environment Variable    | Property            | Default                                                   |
| ------------------------| --------------------| ---------------------------------------------------------:|
| rp_debug                | debug               | true                                                      |
| rp_id                   | id                  | kafka-rest-1                                              |
| rp_port                 | port                | 8082                                                      |
| rp_schema_registry_url  | schema.registry.url | http://SR_PORT_8081_TCP_ADDR:SR_PORT_8081_TCP_PORT        |
| rp_zookeeper_connect    | zookeeper.connect   | ZOOKEEPER_PORT_2181_TCP_ADDR:ZOOKEEPER_PORT_2181_TCP_PORT |

A few sensible values have been set as given above. A basic invocation using a link to a local ZooKeeper and Schema Registry instance would be:

```sh
docker run --rm --name schema-registry -p 8081:8081 --link zookeeper:zookeeper --link SR:SR cgswong/confluent-kafka-rest
```

### Using your configuration file
The config directory, `/etc/kafka-rest`, is exposed for mounting to your local host. This facilitates using your own configuration file, `kafka-rest.properties` instead of injecting into the container, while still take advantage of variable substitution. Also, you can download a remote properties file by setting the environment variable `rp_cfg_url` to the location of the file.

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
