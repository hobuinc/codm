#!/bin/bash


BUCKET=$(cat terraform.tfstate | jq .outputs.bucket.value -r)

DIR="drone_dataset_brighton_beach-master"
if [ -d "$DIR" ]
then
    if [ "$(ls -A $DIR)" ]; then
     echo "$DIR exists, reusing data"
    else
        echo "$DIR is empty, fetching example data"
        curl -OL https://github.com/pierotofy/drone_dataset_brighton_beach/archive/refs/heads/master.zip
        unzip master.zip
        rm master.zip
    fi
else
    echo "Directory $DIR does not exist. Fetching."
    curl -OL https://github.com/pierotofy/drone_dataset_brighton_beach/archive/refs/heads/master.zip
    unzip master.zip
    rm master.zip
fi


aws s3 sync $DIR/images/ "s3://$BUCKET/brighton_beach/"

aws s3 cp settings.yaml "s3://$BUCKET/brighton_beach/settings.yaml"
aws s3 cp process "s3://$BUCKET/brighton_beach/process"
