# Node Snapshots

A basic utility to restore a blockchain client from a snapshot stored on AWS S3. The advantage of using a snapshot vs trying to run a sync from the genesis block of the blockchain is that the snapshot runs in hours, whereas the sync from genesis typically runs in days or weeks.

The snapshots can be used with the provided utility or downloaded and used independently. The list of snapshots is currently as follows (with more to follow):

| Chain    | Client | Node Type | Snapshot Name  |
|----------|--------|-----------|----------------|
| Ethereum | Erigon | Archive   | erigon_archive |
| Ethereum | Geth   | Light     | geth_light     |
| Ethereum | Geth   | Full      | geth_full      |
| Ethereum | Geth   | Archive   | geth_archive   |


## Where Do Snapshots Live?

By default, snapshots are written to ```s3://satsuma-snapshots/```. This bucket is in the us-east-1 region of AWS and it is configured for "requester pays" transfers.

The structure of this bucket is to prefix a key with the chain being snapshotted (eth, polygon, etc), then the name of the client, the version, and finally the snapshots themselves. Example:
```
s3://satsuma-snapshots/eth/erigon_archive/v2022.08.01/erigon_archive_1660627832.tar.zstd
```
This path contains the snapshot for timestamp ```1660627832``` for version ```v2022.08.01``` of the ```erigon``` client running an ```archive``` node on the ```eth``` network.

## Instructions

In addition to the snapshots, we have provided some basic scripts to help you quickly get a node up and running if you're using this setup.

*Requirements:* The snapshotting logic must run on an debian-based OS.

There are two scripts:
1. a general-purpose setup script, ```setup.sh``` which installs essential components.
2. a client-specific script, ```launcher.sh``` which downloads a snapshot from S3 and uses it to seed a new client. This script takes a client name as an argument. The name of the client corresponds to a JSON configuration file in the "configs" folder with information about the client, version, etc.

### Example: Launching a Geth Archive Node

1. Spin up an Ubuntu machine with an attached volume
2. Run ```setup.sh``` to install necessary software
3. Run ```launcher.sh --client geth_archive```

The launcher.sh script reads configuration data from a json config file, which tells it where to find the snapshot, which docker image to use, what command to run, etc. The script downloads and unpacks an archive of the most recent snapshot from s3 (this can take a while) and spins up a docker container running the requested client. It then monitors the client until it is at the head of the chain and reports when it is ready.

The provided configuration files serve as examples of how to launch various clients. There is also an expectation that the ```satsuma-snapshots``` bucket should contain a recent snapshot for that specific (client,version) pair. If you notice very stale snapshots or a config file that doesn't seem to have a matching snapshot please report the issue.

NOTE: the client name is a bit overloaded. Instead of the client ```geth```, the client names are things like ```geth_archive```, ```geth_full```, etc. This is due to the fact that, although the snapshots run on the same client, the snapshot data differs significantly depending on the mode of the client.

## Performance and Benchmarking

//TODO

## Future Work

- add additional chains, eth2 clients, etc
- further benchmarking