#!/bin/sh
#
# MIT License
#
# (C) Copyright 2020-2023 Hewlett Packard Enterprise Development LP
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
# File: etcd_defrag.sh
#
# Examples:
# ./etcd_defrag.sh --defrag all --skip none
# ./etcd_defrag.sh --defrag all --skip cray-hbtd-etcd
# ./etcd_defrag.sh --defrag cray-hbtd-etcd


function main() {
    ARGS=`getArgs "$@"`

    DEFRAG_CLUSTER_NAME=`echo "$ARGS" | getNamedArg defrag`
    SKIP_CLUSTER_NAME=`echo "$ARGS" | getNamedArg skip`

}


function getArgs() {
    for arg in "$@"; do
        echo "$arg"
    done
}


function getNamedArg() {
    ARG_NAME=$1

    sed --regexp-extended --quiet --expression="
        s/^--$ARG_NAME=(.*)\$/\1/p  # Get arguments in format '--arg=value': [s]ubstitute '--arg=value' by 'value', and [p]rint
        /^--$ARG_NAME\$/ {          # Get arguments in format '--arg value' ou '--arg'
            n                       # - [n]ext, because in this format, if value exists, it will be the next argument
            /^--/! p                # - If next doesn't starts with '--', it is the value of the actual argument
            /^--/ {                 # - If next starts with '--', it is the next argument and the actual argument is a boolean one
                # Then just repla[c]ed by TRUE
                c TRUE
            }
        }
    "
}

main "$@"

echo "Running etcd defrag for: $DEFRAG_CLUSTER_NAME"
echo "Skip defrag for: $SKIP_CLUSTER_NAME"

if [ $DEFRAG_CLUSTER_NAME != "all" ]
then
  lines=$(kubectl get statefulsets.apps -A | grep bitnami-etcd | awk '{print $1 "." $2}' | grep $DEFRAG_CLUSTER_NAME)
  echo "etcd clusters found: $lines"
  for line in $lines
  do
      ns=$(echo $line | awk 'BEGIN { FS = "." } ; {print $1}')
      cluster=$(echo $line | awk 'BEGIN { FS = "." } ; {print $2}')
      members=$(kubectl get endpoints ${cluster} -n ${ns} -o jsonpath='{.subsets[*].addresses[*].targetRef.name}')
      for member in $members
      do
        echo "Defragging $member"
        output=$(kubectl -n $ns exec -i $member -- /bin/sh -c 'etcdctl --command-timeout=600s defrag')
      done
  done
  echo "Completed"
else
  if [ $SKIP_CLUSTER_NAME != "none" ]
  then
    echo "Skipping defrag for: $SKIP_CLUSTER_NAME"
    lines=$(kubectl get statefulsets.apps -A | grep bitnami-etcd | awk '{print $1 "." $2}' | grep -v -w $SKIP_CLUSTER_NAME)
  else
    lines=$(kubectl get statefulsets.apps -A | grep bitnami-etcd | awk '{print $1 "." $2}')
  fi
  for line in $lines
  do
      ns=$(echo $line | awk 'BEGIN { FS = "." } ; {print $1}')
      cluster=$(echo $line | awk 'BEGIN { FS = "." } ; {print $2}')
      members=$(kubectl get endpoints ${cluster} -n ${ns} -o jsonpath='{.subsets[*].addresses[*].targetRef.name}')
      for member in $members
      do
        echo "Defragging $member"
        if [ $cluster == "cray-vault-etcd" ]; then
          output=$(kubectl -n $ns exec -i $member -- /bin/sh -c 'etcdctl --cacert /etc/etcdtls/operator/etcd-tls/etcd-client-ca.crt --cert /etc/etcdtls/operator/etcd-tls/etcd-client.crt --key /etc/etcdtls/operator/etcd-tls/etcd-client.key --endpoints https://localhost:2379 --command-timeout=600s defrag')
        else
          output=$(kubectl -n $ns exec -i $member -- /bin/sh -c 'ETCDCTL_API=3 etcdctl --command-timeout=600s defrag')
        fi
      done
  done
  echo "Completed"
fi
