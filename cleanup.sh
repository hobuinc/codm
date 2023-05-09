#!/bin/bash

set -e

rm -rf builds
rm -rf lambda-*

BUCKET=$(cat terraform.tfstate | jq .outputs.bucket.value -r)

echo "wiping up $BUCKET bucket"
aws s3 rm "s3://$BUCKET" --recursive
rm -rf drone_dataset_brighton_beach-master
