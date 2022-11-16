# 📸 Node Snapshots

A basic utility to restore a blockchain client from a snapshot stored on AWS S3.

Syncing nodes from genesis typically takes days or weeks. Snapshots allow you to bootstrap nodes within a few hours.

## Quick Start

#### Requirements

- Machine running a Debian-based OS.

#### Instructions

Pick a supported snapshot (i.e. `geth_full`) and run:

```bash
mkdir /data/mainnet
./setup.sh
./launcher.sh --client geth_full --datadir /data/mainnet
```

## Snapshot Access

All public snapshots are uploaded to `s3://satsuma-snapshots/`. This bucket is in AWS us-east-1 and is configured for "requester pays" transfers.

#### Bucket Structure

Snapshots are organized with the following structure:

```
s3://satsuma-snapshots/<chain name>/<node client name>/<version>/<snapshot file>
```

For example:

```
s3://satsuma-snapshots/eth/erigon_archive/v2022.08.01/erigon_archive_1660627832.tar.zstd
```

This path contains the snapshot at timestamp `1660627832` for version `v2022.08.01` of the `erigon` client running an `archive` node on the `eth` network.

## Supported Snapshots

These snapshots can be used with the provided scripts or independently. The list of snapshots is currently as follows:

| Chain    | Client | Node Type | Snapshot Name          |
| -------- | ------ | --------- | ---------------------- |
| Ethereum | Erigon | Archive   | eth_erigon_archive     |
| Ethereum | Geth   | Full      | eth_geth_full          |
| Arbitrum | Nitro  | Archive   | arbitrum_nitro_archive |

Looking for another chain or client type? Join our [Telegram community](https://t.me/+9X-jV6P1z45hN2Ux) or open an issue to let us know!

## How This Works

There are two scripts:

1. a general-purpose setup script, `setup.sh` which installs essential components.
2. a client-specific script, `launcher.sh` which downloads a snapshot from S3 and uses it to seed a new client. This script takes a client name as an argument. The name of the client corresponds to a JSON configuration file in the "configs" folder with information about the client, version, etc.

The launcher.sh script reads configuration data from a json config file, which tells it where to find the snapshot, which docker image to use, what command to run, etc. The script downloads and unpacks an archive of the most recent snapshot from s3 (this can take a while) and spins up a docker container running the requested client. It then monitors the client until it is at the head of the chain and reports when it is ready.

The provided configuration files serve as examples of how to launch various clients. There is also an expectation that the `satsuma-snapshots` bucket should contain a recent snapshot for that specific (client,version) pair. If you notice very stale snapshots or a config file that doesn't seem to have a matching snapshot please report an issue.

Note that for `arbitrum_nitro_archive`, you'll need to replace the <Ethereum RPC URL> in the config's `docker_cmd`.

## Performance and Benchmarking

Here are some numbers of how long it takes to stand up clients from snapshots, based on our experimentation. The choice of hardware (e.g. low-memory machines, network storage drives, etc.) will obviously have an impact, as will network/connectivity (to connect to peers and catch up). There are likely a few optimisations to be made and we will update these numbers as we make improvements.

| Chain    | Client         | Time To Download, Extract & Launch | Time To Catch Up To Latest Block | Snapshot Size | Snapshot Age | Instance Type                          |
| -------- | -------------- | ---------------------------------- | -------------------------------- | ------------- | ------------ | -------------------------------------- |
| Ethereum | geth_full      | 78 minutes                         | 93 minutes                       | 746.1 GiB     | 30 hours     | EC2 im4.2x (8 CPU (ARM), 32GB RAM)     |
| Ethereum | erigon_archive | 90 minutes                         | 70 minutes                       | 621.6 GiB     | 13 hours     | EC2 im4.2x (8 CPU (ARM), 32GB RAM)[^1] |

[^1]: erigon test was run on an ARM instance and this required a bit of hackery because the [thorax dockerhub](https://hub.docker.com/r/thorax/erigon/tags) account doesn't appear to include ARM images. The following workaround was used: (1.) run setup.sh as normal. (2.) checkout [erigon from github](https://github.com/ledgerwatch/erigon/) at the correct tag. We have been using [v2022.08.01](https://github.com/ledgerwatch/erigon/releases/tag/v2022.08.01). (3) cd to the erigon repo and run `DOCKER_BUILDKIT=1 docker build .` (4.) edit the launcher.sh to reference the image you just built instead of the `${dockerhub_repo}:${dockerhub_tag}`

## Future Work

- Add support for additional chains, eth2 clients, etc.
- Produce further benchmarking (different instances, different snapshot ages, etc).

## License

Credit to Nathan Bluer for his original work with archiving [BSC](https://github.com/allada/bsc-archive-snapshot) and [mainnet](https://github.com/allada/eth-archive-snapshot).

This repo is licensed under the Apache License, Version 2.0. See [LICENSE]() for details.

Copyright © Riser Data, Inc.
