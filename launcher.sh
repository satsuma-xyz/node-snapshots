#!/bin/bash                                                                                                                                                                                   

set -euxo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

SHORT=c:,d:,h
LONG=config:,datadir:,help
OPTS=$(getopt -a -n launcher --options $SHORT --longoptions $LONG -- "$@")

eval set -- "$OPTS"

while :
do
  case "$1" in
    -c | --config )
      config="$2"
      shift 2
      ;;
    -d | --datadir)
      datadir="$2"
      shift 2
      ;;
    -h | --help)
     echo "Launches a client docker container. Requires a configuration file, specified with --config / -c, and a location to write the snapshot to, specified with -d / --datadir (Note: snapshots are large)."
      exit 2
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      ;;
  esac
done

if [ -z "$config" ]
then
   echo "ERROR: Must specify a config file."
   exit 1
fi

if [ -z "$datadir" ]
then
   echo "ERROR: Must specify a data dir to write snapshot to."
   exit 1
fi

config_file="configs/${config}.json"
if ! test -f "$config_file"; then
    echo "ERROR: $config file does not exist."
    exit 1
fi

snapshots_bucket=$(jq -r .snapshots_bucket "$config_file")
chain=$(jq -r .chain "$config_file")
client=$(jq -r .client "$config_file")
release=$(jq -r .release "$config_file")
dockerhub_src=$(jq -r .dockerhub_src "$config_file")
docker_port_mappings=$(jq -r .docker_port_mappings "$config_file")
docker_cmd=$(jq -r .docker_cmd "$config_file")
start_time=$(date +%s)

cd $datadir

# The process that produces the snapshots retains two copies of snapshots per (client, version) pair.
# The snapshots are named in a standard format with a timestamp in the name. This means that the lexicographical order
# of the snapshots is also the creation order. Selecting the last snapshot listed means selecting the most recent
# snapshot.
latest=$(aws s3 ls "s3://${snapshots_bucket}/${chain}/${client}/${release}/" | awk '{print $4}' | tail -1)
aws s3 cp "s3://${snapshots_bucket}/${chain}/${client}/${release}/${latest}" - | pv | /zstd/zstd --long=31 -d | tar -xf -
docker run -d --name $client -v /$client/:/$client $docker_port_mappings ${dockerhub_src}:${release} $docker_cmd --datadir $datadir
elapsed=$(( $(date +%s) - start_time ))
echo "Downloaded snapshot and launched docker container in $elapsed seconds."
