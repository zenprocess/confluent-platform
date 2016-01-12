## Confluent Platform ZooKeeper
This is a highly configurable Dockerized [Apache ZooKeeper](http://zookeeper.apache.org/) image which is part of the [Confluent Platform](http://www.Confluent.io).

## How to use this image
The container can be configured via environment variables where any ZooKeeper property can be set after `zk_` with underscore instead of period ('.') used. For example:

| Environment Variable           | Zookeeper Property        | Default |
| ------------------------------ | ------------------------- | -------:|
| zk_tickTime                    | tickTime                  | 2000    |
| zk_initLimit                   | initLimit                 | 5       |
| zk_syncLimit                   | syncLimit                 | 2       |

A few sensible values have been set as given above.

The data directory, `/var/lib/zookeeper`, is exposed for mounting to your local host. This facilitates using external storage for data and snapshots and the transaction logs. The configuration directory, `/etc/kafka`, is also exposed for mounting such that you can use your own configuration file, `zookeeper.properties`, and also take advantage of variable substitution.

### Using your configuration file
This image also provides for a remote properties file to be used, which will also be processed for variable substitution. To download a remote properties file, set the environment variable `zk_cfg_url` to the location of the file.

### Standalone mode
If you are happy with the defaults, just run the container to get ZooKeeper in standalone mode:

```sh
docker run --rm --name zk -p 2181:2181 cgswong/confluent-zookeeper
```

### Cluster mode
To run a cluster just set more `zk_server_X` environment variables, where `X` is the respective ZooKeeper ID, set to the respective IP/hostname. You'll also need to publish the respective cluster ports. For example:

```sh
docker run -d --name zk1 \
  -p 2181:2181 -p 2888:2888 -p 3888:3888 \
  -e zk_id=1 -e zk_server_1=172.17.8.101 -e zk_server_2=172.17.8.102 -e zk_server_3=172.17.8.103 \
  cgswong/confluent-zookeeper
docker run -d --name zk2 \
  --publish 2181:2181 --publish 2888:2888 --publish 3888:3888 \
  -e zk_id=2 -e zk_server_1=172.17.8.101 -e zk_server_2=172.17.8.102 -e zk_server_3=172.17.8.103 \
  cgswong/confluent-zookeeper
docker run -d --name zk3 \
  -p 2181:2181 -p 2888:2888 -p 3888:3888 \
  -e zk_id=3 -e zk_server_1=172.17.8.101 -e zk_server_2=172.17.8.102 -e zk_server_3=172.17.8.103 \
  cgswong/confluent-zookeeper
```

The above commands are run across 3 separate hosts. To form a cluster on a single host change the local port mappings to avoid collisions.

# Acknowledgement
This image is a fork of the main [ConfluentInc Platform](https://github.com/confluentinc/docker-images). As I do contribute back you may see some of these features included, however, some may not be included or take longer to be merged. I created this version not only to contribute back to a really good project, but also to learn, and have a version which was more robust (production ready since this is being used as such), with a more timely update cycle (for the time being anyways).
