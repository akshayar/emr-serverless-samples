# EMR Serverless Samples

This repository contains example code for getting started with EMR Serverless and using it with Apache Spark and Apache Hive.

In addition, it provides Container Images for both the Spark History Server and Tez UI in order to debug your jobs.

For full details about using EMR Serverless, please see the [EMR Serverless documentation](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/emr-serverless.html).

## Pre-Requisites

_These demos assume you are using an Administrator-level role in your AWS account_

1. **Amazon EMR Serverless is currently in preview.** Please follow the sign-up steps at https://pages.awscloud.com/EMR-Serverless-Preview.html to request access.

2. Create an Amazon S3 bucket in the us-east-1 region

```shell
export S3_BUCKET=<>
aws s3 mb s3://${S3_BUCKET} --region us-east-1

aws s3 cp s3://elasticmapreduce/emr-serverless-preview/artifacts/latest/dev/cli/service.json ./service.json
aws configure add-model --service-model file://service.json

aws configure set region us-east-1
aws emr-serverless list-applications

```

3. Create an EMR Serverless execution role (replacing `BUCKET-NAME` with the one you created above)

This role provides both S3 access for specific buckets as well as full read and write access to the Glue Data Catalog.

```shell
aws iam create-role --role-name emr-serverless-job-role --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "emr-serverless.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

aws iam put-role-policy --role-name emr-serverless-job-role --policy-name S3Access --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadFromOutputAndInputBuckets",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::*.elasticmapreduce",
                "arn:aws:s3:::*.elasticmapreduce/*",
                "arn:aws:s3:::noaa-gsod-pds",
                "arn:aws:s3:::noaa-gsod-pds/*",
                "arn:aws:s3:::'${S3_BUCKET}'",
                "arn:aws:s3:::'${S3_BUCKET}'/*"
            ]
        },
        {
            "Sid": "WriteToOutputDataBucket",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::'${S3_BUCKET}'/*"
            ]
        }
    ]
}'

aws iam put-role-policy --role-name emr-serverless-job-role --policy-name GlueAccess --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "GlueCreateAndReadDataCatalog",
        "Effect": "Allow",
        "Action": [
            "glue:CreateDatabase",
            "glue:GetDatabase",
            "glue:GetDataBases",
            "glue:CreateTable",
            "glue:GetTable",
            "glue:GetTables",
            "glue:DeleteTable",
            "glue:UpdateTable",
            "glue:GetPartition",
            "glue:GetPartitions",
            "glue:CreatePartition",
            "glue:DeletePartition",
            "glue:BatchCreatePartition",
            "glue:GetUserDefinedFunctions",
            "glue:BatchDeletePartition"
        ],
        "Resource": ["*"]
      }
    ]
  }'
```
  

## Examples

- [EMR Serverless PySpark job](/examples/pyspark/README.md)

  This sample script shows how to use EMR Serverless to run a PySpark job that analyzes data from the open [NOAA Global Surface Summary of Day](https://registry.opendata.aws/noaa-gsod/) dataset.

- [EMR Serverless Hive query](/examples/hive/README.md)

  This sample script shows how to use Hive in EMR Serverless to query the same NOAA data.

## Utilities

- [Spark UI](/utilities/spark-ui/)

  You can use this Dockerfile to run Spark history server in your container.

- [Tez UI](/utilities/tez-ui/)

  You can use this Dockerfile to run Tez UI and Application Timeline Server in your container.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
