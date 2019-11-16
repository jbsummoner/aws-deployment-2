# AWS Deployment using AWS CLI

## Table of Contents

- [AWS Deployment using AWS CLI](#aws-deployment-using-aws-cli)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
    - [Folder structure](#folder-structure)
    - [File description](#file-description)
    - [AWS Infrastructure created](#aws-infrastructure-created)
  - [Pre-deployment](#pre-deployment)
  - [Deploy infrastructure and application](#deploy-infrastructure-and-application)
  - [Destroy infrastructure and application](#destroy-infrastructure-and-application)

## Description

The repo has scripts to a Node.js image processing web application connected to a DynamoDB, and two s3 buckets.  
The application is deployed on to AWS EC2 Ubuntu instances behind a Internet Gateway, AWS virtual private cloud, two subnets, SQS Message Queue, and a Elastic Load Balancer.
In addition a AWS queue poller application on to AWS EC2 Ubuntu instances.

### Folder structure

mp2/
├── post-process-web-app
│   ├── index.js
│   ├── package.json
│   ├── package-lock.json
│   ├── README.MD
│   └── services
│       ├── aws
│       │   ├── config.js
│       │   ├── dynamodb.js
│       │   ├── index.js
│       │   ├── s3.js
│       │   ├── sns.js
│       │   └── sqs.js
│       ├── index.js
│       └── jimp.js
├── pre-process-web-app
│   ├── controllers
│   │   ├── index.js
│   │   └── sample.controller.js
│   ├── index.js
│   ├── middleware
│   │   ├── errorHandler.middleware.js
│   │   └── index.js
│   ├── package.json
│   ├── package-lock.json
│   ├── public
│   │   ├── gallery
│   │   │   └── index.html
│   │   ├── index.html
│   │   ├── site.js
│   │   └── style.css
│   ├── README.MD
│   ├── routes
│   │   ├── index.js
│   │   └── sample.routes.js
│   ├── server.js
│   ├── services
│   │   ├── aws
│   │   │   ├── config.js
│   │   │   ├── dynamodb.js
│   │   │   ├── index.js
│   │   │   ├── s3.js
│   │   │   ├── sns.js
│   │   │   └── sqs.js
│   │   ├── index.js
│   │   └── jimp.js
│   └── test
│       └── routes
│           └── sample.routes.test.js
├── README.md
├── scripts
│   ├── run.sh
│   └── templates
│       ├── create-env.sh
│       ├── destroy-env.sh
│       ├── install-app-env.sh
│       └── install-app-poller-env.sh
└── test.sh

### File description

- `run.sh` gets user input and provide the variables to each template file.
- `create-env.sh` create aws infrastructure.
- `install-app-env.sh` clones repo and start node app.
- `install-app-poller-env.sh` clones repo and start aws polling node app.
- `destroy-env.sh1` destroys the previously created AWS infrastructure.

### AWS Infrastructure created

- 1 internet gateway
- 1 VPC
- 2 Subnets
- 1 Security group
- 2 s3 buckets
- 1 DynamoDB
- 1 SQS queue
- 1 Target group
- 1 ELB application load balancer
- 2 EC2 instances
- Publishes SNS

## Pre-deployment

- Must have awscli properly setup.
- Need a EC2 instance keypair.
- Need a EC2 instance profile for AWS EC2 service with at least S3 and RDS full privileges.
- Keypair must exist in region you choose.

Note: Github deployment key is preseeded in AMI image w/ git, nodes, and aws installed.

## Deploy infrastructure and application

- Must be linux/Unix environment
- Run `run.sh` script
- Load Balance DNS name is returned at the end of the script, will take a couple seconds to propagate.

## Destroy infrastructure and application

- Run `destroy.sh` script
