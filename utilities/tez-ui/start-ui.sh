export S3_BUCKET=$1
export APPLICATION_ID=$2
export JOB_RUN_ID=$3

export S3_LOG_URI=s3://${S3_BUCKET}/hive-logs

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_REGION=us-east-1

docker run --rm -d \
    --name emr-tez-ui \
    -p 8088:8088 -p 8188:8188 -p 9999:9999 \
    -e AWS_REGION=us-east-1 -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN \
    -e S3_LOG_URI -e JOB_RUN_ID -e APPLICATION_ID \
    emr/tez-ui
