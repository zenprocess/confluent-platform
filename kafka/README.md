## Confluent Platform Kafka
This is a highly configurable Dockerized [Confluent Platform Kafka Image](http://docs.confluent.io/2.0.0/).

## How to use this image
The container can be configured via environment variables where any [Kafka property](https://kafka.apache.org/documentation.html#brokerconfigs) can be set after `kafka_` with underscore instead of period ('.') used. For example:

| Environment Variable                    | Property                          | Default                                                   |
| --------------------------------------- | --------------------------------- | ---------------------------------------------------------:|
| kafka_auto_create_topics_enable         | auto.create.topics.enable         | true                                                      |
| kafka_broker_id                         | broker.id                         | 1                                                         |
| kafka_delete_topic_enable               | delete.topic.enable               | true                                                      |
| kafka_dual_commit_enabled               | dual.commit.enabled               | false                                                     |
| kafka_log_cleaner_enable                | log.cleaner.enable                | true                                                      |
| kafka_log_retention_hours               | log.retention.hours               | 168                                                       |
| kafka_num_partitions                    | num.partitions                    | 1                                                         |
| kafka_num_recovery_threads_per_data_dir | num.recovery.threads.per.data.dir | 1                                                         |
| kafka_offsets_storage                   | offsets.storage                   | kafka                                                     |
| kafka_port                              | port                              | 9092                                                      |
| kafka_zookeeper_connect                 | zookeeper.connect                 | ZOOKEEPER_PORT_2181_TCP_ADDR:ZOOKEEPER_PORT_2181_TCP_PORT |

A few sensible, and a few opinionated values, have been set as given above. A basic invocation using a link to a local ZooKeeper instance would be:

```sh
docker run --rm --name kafka -p 9092:9092 --link zookeeper:zookeeper cgswong/confluent-kafka
```

### Using your configuration file
The config directory, `/etc/kafka`, is exposed for mounting to your local host. This facilitates using your own configuration file, `kafka.properties` instead of injecting into the container, while still take advantage of variable substitution. Also, you can download a remote properties file by setting the environment variable `kafka_cfg_url` to the location of the file.

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
