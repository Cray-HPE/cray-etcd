#!/bin/bash

# Create a file with random text data
dd if=/dev/urandom bs=1K count=512 | tr -dc 'a-zA-Z0-9' > data

# Load the data into etcd
for i in {1..8192}; do
  echo "$i"
  etcdctl put "key-$i" "$(cat data)"
done

# Delete the data file
rm data
