## Confluent Platform Schema Registry
This is a highly configurable Dockerized [Confluent Platform Schema Registry](http://docs.confluent.io/2.0.0/schema-registry/docs/index.html).

## How to use this image
The container can be configured via environment variables where any [Schema Registry property](http://docs.confluent.io/2.0.0/schema-registry/docs/config.html) can be set after `sr_` with underscore instead of period ('.') used. For example:

| Environment Variable            | Property                      | Default                                                   |
| ------------------------------- | ----------------------------- | ---------------------------------------------------------:|
| sr_debug                        | debug                         | true                                                      |
| sr_kafkastore_connection_url    | kafkastore.connection.url     | ZOOKEEPER_PORT_2181_TCP_ADDR:ZOOKEEPER_PORT_2181_TCP_PORT |
| sr_kafkastore_topic             | kafkastore.topic              | _schemas                                                  |
| sr_schema_registry_zk_namespace | schema.registry.zk.namespace  | schema_registry                                           |
| sr_port                         | port                          | 8081                                                      |

A few sensible values have been set as given above. A basic invocation using a link to a local ZooKeeper instance would be:

```sh
docker run --rm --name schema-registry -p 8081:8081 --link zookeeper:zookeeper cgswong/confluent-schema-registry
```

### Using your configuration file
The config directory, `/etc/schema-registry`, is exposed for mounting to your local host. This facilitates using your own configuration file, `schema-registry.properties` instead of injecting into the container, while still take advantage of variable substitution. Also, you can download a remote properties file by setting the environment variable `sr_cfg_url` to the location of the file.

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
