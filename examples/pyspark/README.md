# EMR Serverless PySpark job

This example shows how to run a PySpark job on EMR Serverless that analyzes data from the [NOAA Global Surface Summary of Day](https://registry.opendata.aws/noaa-gsod/) dataset from the Registry of Open Data on AWS.

The script analyzes data from a given year and finds the weather location with the most extreme rain, wind, snow, and temperature.

_ℹ️ Throughout this demo, I utilize environment variables to allow for easy copy/paste_

## Setup

_You should have already completed the pre-requisites in this repo's [README](/README.md)._

- Define some environment variables to be used later

```shell

export S3_BUCKET=<YOUR_BUCKET_NAME>

```

```shell
export ROLE_ARN=`aws iam get-role --role-name emr-serverless-job-role --query Role.Arn --output text`
echo ${ROLE_ARN}
```


- Now, let's create and start an Application on EMR Serverless. Applications are where you submit jobs and are associated with a specific open source framework and release version. For this application, we'll configure [pre-initialized capacity](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/application-capacity-api.html) to ensure this application can begin running jobs immediately.

_ℹ️ Please note that leaving a pre-initialized application running WILL incur costs in your AWS Account._

```shell
aws emr-serverless list-applications

aws emr-serverless create-application \
  --type SPARK \
  --name serverless-demo \
  --release-label "emr-6.5.0-preview" \
    --initial-capacity '{
        "DRIVER": {
            "workerCount": 2,
            "resourceConfiguration": {
                "cpu": "2vCPU",
                "memory": "4GB"
            }
        },
        "EXECUTOR": {
            "workerCount": 10,
            "resourceConfiguration": {
                "cpu": "4vCPU",
                "memory": "4GB"
            }
        }
    }' \
    --maximum-capacity '{
        "cpu": "200vCPU",
        "memory": "200GB",
        "disk": "1000GB"
    }'

```

- This will return information about your application. In this case, we've created an application that can handle 2 simultaneous Spark apps with an initial set of 10 executors, each with 4vCPU and 4GB of memory, that can scale up to 200vCPU or 50 executors.

```json
{
    "applicationId": "00et0dhmhuokmr09",
    "arn": "arn:aws:emr-serverless:us-east-1:123456789012:/applications/00et0dhmhuokmr09",
    "name": "serverless-demo"
}
```

- We'll set an `APPLICATION_ID` environment variable to reuse later.

```shell
aws emr-serverless list-applications

export  APPLICATION_ID=`aws emr-serverless list-applications --query applications[0].id --output text`

echo $APPLICATION_ID

```

- Get the state of your application

```shell
aws emr-serverless get-application \
    --application-id ${APPLICATION_ID}

aws emr-serverless get-application     --application-id $APPLICATION_ID --query application.state --output text
```

- Once your application is in `CREATED` state, you can go ahead and start it.

```shell
aws emr-serverless start-application \
    --application-id $APPLICATION_ID
    
aws emr-serverless get-application     --application-id $APPLICATION_ID --query application.state --output text
```

- Once your application is in `STARTED` state, you can submit jobs.

With [pre-initialized capacity](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/application-capacity-api.html), you can define a minimum amount of resources that EMR Serverless keeps ready to respond to interactive queries. EMR Serverless will scale your application up as necessary to respond to workloads, but return to the pre-initialized capacity when there is no activity. You can start or stop an application to effectively pause your application so that you are not billed for resources you're not using. If you don't need second-level response times in your workloads, you can use the default capacity and EMR Serverless will decomission all resources when a job is complete and scale back up as more workloads come in.

## Run wordcount Job
- Submit the job
```shell
JOB_RUN_ID=`aws emr-serverless start-job-run \
    --application-id ${APPLICATION_ID} \
    --execution-role-arn ${ROLE_ARN} \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://us-east-1.elasticmapreduce/emr-containers/samples/wordcount/scripts/wordcount.py",
            "entryPointArguments": ["s3://'${S3_BUCKET}'/output"],
            "sparkSubmitParameters": "--conf spark.executor.cores=1 --conf spark.executor.memory=4g --conf spark.driver.cores=1 --conf spark.driver.memory=4g --conf spark.executor.instances=1"
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
           "s3MonitoringConfiguration": {
             "logUri": "s3://'${S3_BUCKET}'/logs"
           }
        }
    }' --query jobRunId --output text`

echo $JOB_RUN_ID

```
- View the job and it's status.
```shell
aws emr-serverless list-job-runs --application-id $APPLICATION_ID

aws emr-serverless get-job-run --application-id $APPLICATION_ID --job-run-id ${JOB_RUN_ID}

aws emr-serverless get-job-run --application-id $APPLICATION_ID --job-run-id ${JOB_RUN_ID} --query jobRun.state --output text

```
- We can monitor Job logs
```shell
aws s3 ls  --recursive s3://${S3_BUCKET}/logs/applications/$APPLICATION_ID/jobs/$JOB_RUN_ID/

```
- We can download and view job logs
```shell
aws s3 cp  s3://${S3_BUCKET}/logs/applications/${APPLICATION_ID}/jobs/${JOB_RUN_ID}/SPARK_DRIVER/stdout.gz - | gunzip
aws s3 cp  s3://${S3_BUCKET}/logs/applications/${APPLICATION_ID}/jobs/${JOB_RUN_ID}/SPARK_DRIVER/stderr.gz - | gunzip


```
- View the output of job
```shell
aws s3 ls --recursive s3://${S3_BUCKET}/output
mkdir -p  temp/output/
aws s3 cp --recursive s3://${S3_BUCKET}/output temp/output/

cat `ls temp/output/* | xargs`
```
- We can also launch Spark History Server to monitor job.
```shell
cd ~/environment/emr-serverless-samples/utilities/spark-ui
export AWS_ACCESS_KEY_ID=AKIAaaaa
export AWS_SECRET_ACCESS_KEY=bbbb
export AWS_SESSION_TOKEN=yyyy

./start-ui.sh ${S3_BUCKET} ${APPLICATION_ID} ${JOB_RUN_ID}

```
## Run Spark Job with integration with Glue Catalog

- Refer to the configuration that is required for Glue Catalog integration
```scala
config("hive.metastore.client.factory.class",
                    "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory") 
```

- First, make sure the `copy-data.py` script is uploaded to an S3 bucket in the `us-east-1 region.
```shell
aws s3 cp ~/environment/emr-serverless-samples/examples/pyspark/copy-data.py s3://${S3_BUCKET}/code/pyspark/
```


Now that you've created your application, you can submit jobs to it at any time.

We define our `sparkSubmitParameters` with resources that match our pre-initialized capacity, but EMR Serverless will still automatically scale as necessary.

_ℹ️ Note that with Spark jobs, you must account for Spark overhead and configure our executor with less memory than the application._

In this case, we're also configuring Spark logs to be delivered to our S3 bucket.

```shell
JOB_RUN_ID=`aws emr-serverless start-job-run \
    --application-id ${APPLICATION_ID} \
    --execution-role-arn ${ROLE_ARN} \
    --job-driver '{
        "sparkSubmit": {
            "entryPoint": "s3://'${S3_BUCKET}'/code/pyspark/copy-data.py",
            "entryPointArguments": ["s3://noaa-gsod-pds/2021/","s3://'${S3_BUCKET}'/output/noaa_gsod_pds","default.noaa_gsod_pds"]
            
        }
    }' \
    --configuration-overrides '{
        "monitoringConfiguration": {
           "s3MonitoringConfiguration": {
             "logUri": "s3://'${S3_BUCKET}'/logs"
           }
        }
    }' --query jobRunId --output text`

echo $JOB_RUN_ID
```
- The job should start within a few seconds since we're making use of pre-initialized capacity.
```shell
aws emr-serverless list-job-runs --application-id $APPLICATION_ID

aws emr-serverless get-job-run --application-id $APPLICATION_ID \
   --job-run-id ${JOB_RUN_ID}

aws emr-serverless get-job-run --application-id $APPLICATION_ID \
   --job-run-id ${JOB_RUN_ID} --query jobRun.state --output text

```
- We can also look at our logs while the job is running.
```shell
aws s3 ls  --recursive s3://${S3_BUCKET}/logs/applications/$APPLICATION_ID/jobs/$JOB_RUN_ID/

aws s3 cp  s3://${S3_BUCKET}/logs/applications/${APPLICATION_ID}/jobs/${JOB_RUN_ID}/SPARK_DRIVER/stdout.gz - | gunzip
aws s3 cp  s3://${S3_BUCKET}/logs/applications/${APPLICATION_ID}/jobs/${JOB_RUN_ID}/SPARK_DRIVER/stderr.gz - | gunzip

```
- We can also launch Spark History Server to monitor job.

```shell
cd ~/environment/emr-serverless-samples/utilities/spark-ui

./start-ui.sh ${S3_BUCKET} ${APPLICATION_ID} ${JOB_RUN_ID}
```

- View the output of job
```shell
aws s3 ls --recursive s3://${S3_BUCKET}/output/noaa_gsod_pds
aws s3 ls --recursive s3://${S3_BUCKET}/output/noaa_gsod_pds_aggregate

```

## Clean up

- When you're all done, make sure to call `stop-application` to decommission your capacity and `delete-application` if you're all done.


```shell
aws emr-serverless stop-application \
    --application-id $APPLICATION_ID
```

- Delete application
```shell
aws emr-serverless delete-application \
    --application-id $APPLICATION_ID
```

## Spark UI Debugging

- (Optional) Follow the steps in [building the Spark UI Docker container](/utilities/spark-ui/) to build the container locally

- Get credentials 

```shell
export AWS_ACCESS_KEY_ID=AKIAaaaa
export AWS_SECRET_ACCESS_KEY=bbbb
export AWS_SESSION_TOKEN=yyyy
```

- Start UI

```shell
cd ~/environment/emr-serverless-samples/utilities/spark-ui

./start-ui.sh ${S3_BUCKET} ${APPLICATION_ID} ${JOB_RUN_ID}

```

- Access the Spark UI via http://localhost:18080

- When you're done, stop the Docker image

```shell
./stop-ui.sh
```
