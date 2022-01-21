# Spark UI

You can use this Docker image to start the Apache Spark History Server (SHS) and view the Spark UI locally.

## Pre-requisite

- Install Docker

## Build Docker image

You can either build this Docker image yourself, or use the public image here: `ghcr.io/aws-samples/emr-serverless-spark-ui:latest`

1. Download the Dockerfile in the `spark-ui` directory from the GitHub repository.
2. Login to ECR
```shell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 755674844232.dkr.ecr.us-east-1.amazonaws.com
```
3. Build the image
```shell
cd ~/environment/emr-serverless-samples/utilities/spark-ui
docker build -t emr/spark-ui .
```

## Start the Spark History Server

You can use a pair of AWS access key and secret key, or temporary AWS credentials.

1. Set your AWS access key and secret key, and optionally session token.

```shell
export AWS_ACCESS_KEY_ID="ASIAxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyy"
export AWS_SESSION_TOKEN="zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
```

3. Run start-ui.sh

```shell
./start-ui.sh <S3_BUCKET> <ApplicationID> <jobId>
```

4. Access the Spark UI via http://localhost:18080