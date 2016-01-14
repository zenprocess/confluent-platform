## Confluent Platform Kafka MirrorMaker
This is a highly configurable Dockerized [Kafka MirrorMaker](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330) image.

## How to use this image
The container can be configured via environment variables where any MirrorMaker property can be set after `mm_`, producer configurations after `mm_pd_` and consumer configurations after `mm_cs_` with underscore instead of period ('.') used in all cased as the alternate separator. For example:

| Environment Variable        | Property              | Default                                                   |
| --------------------------- | --------------------- | ---------------------------------------------------------:|
| mm_streams                  | streams               | 2                                                         |
| mm_topics                   | topics                | .*                                                        |
| mm_cs_group_id              | group.id              | mirrormaker                                               |
| mm_pd_client_id             | client.id             | mirrormaker                                               |
| mm_cs_zookeeper_connect     | zookeeper.connect     | ZOOKEEPER_PORT_2181_TCP_ADDR:ZOOKEEPER_PORT_2181_TCP_PORT |
| mm_pd_compression_codec     | compression.codec     | snappy                                                    |
| mm_pd_metadata_broker_list  | metadata.broker.list  | KAFKA_PORT_9092_TCP_ADDR:KAFKA_PORT_9092_TCP_PORT         |
| mm_pd_producer_type         | producer.type         | async                                                     |
| mm_pd_request_required_acks | request.required.acks | 1                                                         |

A few sensible, and some opinionated values, have been set as given above. A basic invocation using a link to local ZooKeeper and Kafka instances would be:

```sh
docker run --rm --name mirrormaker --link zookeeper:zookeeper --link kafka:kafka cgswong/confluent-mirrormaker
```

### Using your configuration file
The config directory, `/etc/kafka-mirrormaker`, is exposed for mounting to your local host. This facilitates using your own configuration files, `consumer.properties` and `producer.properties` instead of injecting into the container, while still take advantage of variable substitution. Also, you can download remote properties files by setting the environment variables `mm_pd_cfg_url` and `mm_cs_cfg_url` to the location of the producer and consumer properties files respectively.

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
