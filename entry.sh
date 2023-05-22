#!/bin/bash

#set -e
echo "Hello , this is CODM docker!"

BUCKET="$4"
COLLECT="$5"
OUTPUT="$6"

echo "processing collect '$COLLECT' from bucket $BUCKET to $OUTPUT"

#cd /code


ls -al / && ls -al /local
mkdir -p /local/processing/code/
mkdir -p /local/processing/code/images
mkdir -p /local/processing/code/tmp
cd /local/processing/code

aws s3 sync s3://$BUCKET/$COLLECT/ /local/processing/code/images --no-progress

# try using an overriden settings file
aws s3 cp s3://$BUCKET/$COLLECT/settings.yaml /code/settings.yaml  || true

# try copying a boundary
aws s3 cp s3://$BUCKET/$COLLECT/boundary.json /local/processing/code/boundary.json  || true

cat /local/processing/code/settings.yaml

BOUNDARY="--auto-boundary"
if test -f "boundary.json"; then
    BOUNDARY="--boundary boundary.json"
fi

python3 /code/run.py --rerun-all $BOUNDARY --project-path /local/processing --copy-to /local/processing/output 2>&1 | tee odm_$COLLECT-process.log
echo "response code: " ${PIPESTATUS[0]}
RESPOSE_CODE=${PIPESTATUS[0]}

ls -al

aws s3 sync /local/processing/output s3://$BUCKET/$COLLECT/$OUTPUT/$val --no-progress

# copy the log
aws s3 cp odm_$COLLECT-process.log s3://$BUCKET/$COLLECT/$OUTPUT/odm_$COLLECT-process.log

exit $RESPONSE_CODE






