#!/bin/sh
#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

prune_day_begin=$1
prune_day_end=$2

endpoint=$(cat ${HOME}/.aws/s3_endpoint)

function prune_folder() {
  short_name=$1
  #
  # Prune all but the latest file per day for a week
  #
  for day in `seq $prune_day_begin $prune_day_end`;
  do
    epoch_secs=$(echo "`date +%s` - (86400 * $day)" | bc)
    date_str=$(date -d @$epoch_secs +'%Y-%m-%d')
    backups=$(aws s3api list-objects-v2 --output text --endpoint-url ${endpoint}  --prefix ${short_name} --bucket "etcd-backup" --query "Contents[?contains(LastModified, '$date_str')].{Key: Key, LastModified: LastModified }" | sort -k 2 | awk '{print $1}')
    if [ "$backups" != "None" ] && [ ! -z "$backups" ]; then
      echo ""
      delete_these=$(echo "$backups" | head -n -1)
      keep_this=$(echo "$backups" | tail -1)
      echo "*** Keeping the latest snapshot in S3 for $short_name from $date_str:"
      echo "$keep_this"
      if [ ! -z "$delete_these" ] || [ "$delete_these" == "None" ]; then
        echo ""
        echo "*** Deleting the following snapshots in S3 for $short_name from $date_str:"
        echo "$delete_these"
	for bu in $delete_these;
	do
           aws s3 rm --endpoint $endpoint s3://etcd-backup/${bu}
	done
      else
        echo ""
        echo "*** No snapshots to delete in S3 for $short_name from $date_str:"
      fi
    fi
    if [ $day -eq $prune_day_end ]; then
      backups=$(aws s3api list-objects-v2 --output text --endpoint-url ${endpoint}  --prefix ${short_name} --bucket "etcd-backup" --query "Contents[?LastModified < '$date_str'].{Key: Key, LastModified: LastModified }" | sort -k 2 | awk '{print $1}')
      if [ "$backups" != "None" ] && [ ! -z "$backups" ]; then
        echo "*** Deleting snapshots in S3 for $short_name older than $date_str:"
        echo "$backups"
	for bu in $backups;
	do
           aws s3 rm --endpoint $endpoint s3://etcd-backup/${bu}
	done
      fi
    fi
  done
}

for snapshot_dir in $(ls /snapshots/ -1)
do
  short_name=$(echo $snapshot_dir | awk 'BEGIN{FS=OFS="-"}{NF--; NF--; print}')
  echo ""
  echo "Syncing snapshots from bitnami PVC to S3 for: $short_name"
  cd /snapshots/${snapshot_dir}
  aws s3 sync . s3://etcd-backup/${short_name} --endpoint-url ${endpoint}
  echo "Retaining latest backup from each day older than $prune_day_begin days and deleting those older than $prune_day_end days in S3 for: $short_name"
  prune_folder $short_name
  echo ""
done
