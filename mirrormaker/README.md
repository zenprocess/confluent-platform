# Docker Kafka MirrorMaker
Docker container that runs Kafka's MirrorMaker - a service which acts as both a consumer and producer to replicate, or mirror messages from one Kafka cluster (source/consumer) to another (destination/producer). Setting up a mirror is easy - simply start up the MirrorMaker processes after bringing up the source and target clusters. At a minimum, MirrorMaker takes one or more consumer configurations, a producer configuration and either a whitelist or a blacklist. You need to point the consumer to the source cluster's ZooKeeper, and the producer to the mirror cluster's Kafka Brokers (note that transparently ZooKeeper will still be used).

## Usage
The container expects the following environment variables to be passed in:

- `MM_CS_ZOOKEEPER_CONNECT` - Comma delimited list of ZooKeeper hosts for source, including port and chroot (format `[ip/hostname]:[port]`). Bear in mind any chroot used should **only** be used on the last ZooKeeper entry, for example `MM_CS_ZOOKEEPER_CONNECT=172.17.8.101:2181,172.17.8.102:2181,172.17.8.103:2181/chroot/kafka1`.
- `MM_PD_METADATA_BROKER_LIST` - Brokers to receive mirrored messages.

It also requires either of the command line arguments `--whitelist` or `--blacklist` to be set. As an example, to replicate all topics set `--whitelist=\".*\"`.

The following MirrorMaker settings can also be used:
- `MM_PRODUCERS` - Number of producer threads to use in writing messages to the destination cluster. **Defaults to 1**. Increase for better write throughput (up to the total number of partitions).
- `MM_STREAMS` - Number of consumer streams to use in reading topic messages. **Defaults to 1**. Increase for better read throughout, though note that your partition count should be greater than or equal to the total number of consumers, including MirrorMaker otherwise warning messages will occur.

Any consumer or producer setting can be set via Docker environment variable substitution using the prefix `MM_CS_` for consumer settings and `MM_PD_` for producer settings, ensuring upper case and underscore (instead of periods) are used for the appropriate variable. For example to set the consumer setting for `auto.offset.reset=largest` you would use `MM_CS_AUTO_OFFSET_RESET=largest`; for the producer setting for `request.required.acks=1` use `MM_PD_REQUEST_REQUIRED_ACKS=1`. The following are some default settings:

- `MM_CS_GROUP_ID` - Consumer side string to uniquely identify a group of consumer processes. **Defaults to `mm-1`**.
- `MM_PD_CLIENT_ID` - Producer side string sent in each request to help trace calls. **Defaults to `mm-1`**.

You can also use your own consumer and producer configuration files via a volume mount, for example `-v $PWD/mirrormaker-consumer.config:/etc/kafka-mirrormaker/mirrormaker-consumer.config -v $PWD/mirrormaker-producer.config:/etc/kafka-mirrormaker/mirrormaker-producer.config`, or download URL using `MM_CS_CFG_URL` for the consumer and `MM_PD_CFG_URL` for the producer. Within your files you can also take advantage of the same variable substitution.

### Basic command
Assuming the source Kafka ZooKeeper is running on a node with IP 172.17.8.101 and the default 2181 port, with the destination Kafka Broker on another node with IP 172.17.8.102 and default port 9092:

```sh
docker run --name mirrormaker -e MM_CS_ZOOKEEPER_CONNECT=172.17.8.101:2181 -e MM_PD_METADATA_BROKER_LIST=172.17.8.102:9092 cgswong/mirrormaker-ssh --whitelist=\".*\"
```

A more complex setup with a source Kafka ZooKeeper cluster running on a nodes 172.17.8.101, 172.17.8.102 and 172.17.8.103 at the default 2181 port under `/chroot/kafka`, with a destination Kafka cluster on nodes 172.17.10.101, 172.17.10.102 and 172.17.10.103 with default port 9092 and setting a few MirrorMaker, consumer and producer settings:

```sh
docker run --name mirrormaker -e MM_CS_ZOOKEEPER_CONNECT=172.17.8.101:2181,172.17.8.102:2181,172.17.8.103:2181/chroot/kafka -e MM_PD_METADATA_BROKER_LIST=172.17.10.101:9092,172.17.10.102:9092,172.17.10.103:9092 -e MM_STREAMS=3 -e MM_PRODUCERS=3 -e MM_CS_GROUP_ID=mirrormaker -e MM_PD_CLIENT_ID=mirrormaker -e MM_PD_REQUEST_REQUIRED_ACKS=1 cgswong/mirrormaker-ssh --whitelist=\"mm-test,metrics\"
```

### Loading additional consumer configruations
To use multiple consumer configurations you would use a volume mount (`-v $PWD:/etc/kafka-mirrormaker`) containing your additional consumer configuration file and make reference to the additional file as an additional MirrorMaker command line option:

```sh
docker run --name mirrormaker -e MM_CS_ZOOKEEPER_CONNECT=172.17.8.101:2181 -e MM_PD_METADATA_BROKER_LIST=172.17.8.102:9092 -v $PWD:/etc/kafka-mirrormaker cgswong/mirrormaker-ssh --blacklist=\"metrics,_schemas\" --consumer.config /etc/kafka-mirrormaker/mirrormaker-consumer2.config
```

In the above `mirrormaker-consumer2` is the name of your provided 2nd consumer configuration file provided from your Docker host volume mount.

## MirrorMaker Documentation
https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330
