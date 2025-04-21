#!/bin/bash

# Create a file with random text data
dd if=/dev/urandom bs=1K count=512 | tr -dc 'a-zA-Z0-9' > /tmp/data

# this script will load ~1.1 GB of data

# this section loads small key value pairs that do not take up much space
# this is done because a snapshot is taken at 10k pairs because ETCD_SNAPSHOT_COUNT=10000
# if there aren't enough keys, then no snapshot is taken and the following error will be observed
#  error "path:/wal/000000000000000c-0000000000018568.wal, error:fileutil: file already locked"
for i in {1..5000}; do
  echo "$i"
  etcdctl put "small-key-$i" "smallData"
done


# this section loads 8k key values pairs that do take up a lot of space
# Load the data into etcd
for i in {1..8192}; do
  echo "$i"
  etcdctl put "key-$i" "$(cat /tmp/data)"
done

# Delete the data file
rm /tmp/data
