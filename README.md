# CODM – Cloud OpenDroneMap

CODM is a [Serverless framework](https://www.serverless.com/) configuration for
running OpenDroneMap on AWS.


## Architecture

CODM uses Docker, AWS Batch, S3, Lambda, and SNS to provide a cloud infrastructure
for running OpenDroneMap in AWS. The benefits of this architecture include the ability
to configure and execute ODM by simply copying data to S3 to signal activity.

![CODM Diagram](/images/codm-diagram.png)

## Installation

Like many things AWS, installation requires an active account with permissions to create
things. CODM creates Batch configuration, SNS topics, Lambda functions, and a number
of supporting roles to do its work. CODM has only been tested with a superuser account
with permissions to do all of that.


### Required Software

Installation assumes you're going to use Conda to provide the required software. We
also need Docker to extend and build the ODM image with CODM's ``ENTRYPOINT`` and
execution script.

* Docker
* Conda (Conda Forge)
* NodeJS
* Serverless
* AWS CLI


### Install Prerequisites

    conda create -n codm -c conda-forge nodejs
    conda activate codm
    pip install awscli
    npm install -g serverless
    npm install -g serverless-python-requirements

### Environment Variables

The installation requires some AWS environment variables set to define the
user and region where we are installing CODM. It is easiest to set these
in the conda environment directly so they are not forgotten on any subsequent
runs. After setting the variables, make sure to cycle the environment so the
variables stick:

    conda env config vars set AWS_ACCESS_KEY_ID=AKIAJUNKSERROREMFEOI
    conda env config vars set AWS_SECRET_ACCESS_KEY=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
    conda env config vars set AWS_DEFAULT_REGION=us-west-2
    conda env deactivate
    conda activate codm


## Deployment

1. print the environment variables for your AWS region. The variable you are interested in is the GPU AMI ID

    ./print-variables.sh


2. Execute the Serverless deployment, getting the GPU AMI from the ``./print-variables.sh`` call.

    sls deploy --service codm --stage dev --ami "ami-0752de6b19d3111d7

3. Push the Docker image

    ./deploy-docker.sh codm2

## Usage

1. User copies data to ``s3://bucket/prefix/*.jpg``
2. User copies an empty ``process`` file to ``s3://bucket/prefix/process`` to
   signal ODM to start the execution.
3. An S3 event trigger sees ``process`` file and fires the dispatch
   Lambda function for the files in ``s3://bucket/prefix/``
4. The dispatch function creates a new Batch job for the data
   in ``s3://bucket/prefix/``
5. Batch runs the ODM job and uploads results to ``s3://bucket/prefix/output``
6. Notifications of success or failure are sent to the SNS topic.


## Configuration

CODM uses the ``settings.yaml`` that [OpenDroneMap provides](https://github.com/OpenDroneMap/ODM/blob/master/settings.yaml) to provide configuration. It works at multiple levels:

1. The administrator can copy a default ``settings.yaml`` to ``s3://bucket/settings.yaml``
   and this will be copied into the ODM execution and used. It is suggested that
   the default settings have simple configuration with low resolution and parameters.

2. A user can copy a ``settings.yaml`` to ``s3://bucket/prefix/settings.yaml`` as
   part of their invocation to override any default settings provided by #1.

### Geospatial Metadata

If your imagery doesn't have embedded geospatial information, you might need to
copy a ``geo.txt`` that maps the coordinates for each image to
``s3://bucket//prefix/geo.txt``. This is likely going to be needed for big
collections, which otherwise might not match or converge.


