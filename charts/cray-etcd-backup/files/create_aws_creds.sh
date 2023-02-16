#!/bin/sh
#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
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

access_key=$(kubectl get secret -n default etcd-backup-s3-credentials -ojsonpath='{.data.access_key}' | base64 -d)
secret_key=$(kubectl get secret -n default etcd-backup-s3-credentials -ojsonpath='{.data.secret_key}' | base64 -d)
http_s3_endpoint=$(kubectl get secret -n default etcd-backup-s3-credentials -ojsonpath='{.data.http_s3_endpoint}' | base64 -d)

mkdir -p /${HOME}/.aws

cat > /${HOME}/.aws/credentials <<EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
EOF

cat > /${HOME}/.aws/config <<EOF
[default]
region=foo
EOF

echo $http_s3_endpoint > /${HOME}/.aws/s3_endpoint
