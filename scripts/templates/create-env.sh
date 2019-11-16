# Make output dir
mkdir ${OUTPUT_DIR}

# Create raw image s3 bucket
echo "Creating Raw Image s3 Bucket"
aws s3api create-bucket \
    --bucket ${S3_BUCKET_RAW_IMAGE} \
    --region ${AWS_REGION} && \
    echo "Bucket: ${S3_BUCKET_RAW_IMAGE} created"

# Create post image s3 bucket
echo "Creating Post Image s3 Bucket"
aws s3api create-bucket \
    --bucket ${S3_BUCKET_POST_IMAGE} \
    --region ${AWS_REGION} && \
    echo "Bucket: ${S3_BUCKET_POST_IMAGE} created"

# Create Dynamodb Instance
echo "Creating Dynamodb table..."
aws --output json dynamodb create-table \
  --table-name ${DYNAMO_DB_NAME} \
  --attribute-definitions AttributeName=uuid,AttributeType=S \
  --key-schema AttributeName=uuid,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Wait for Dynamodb table to be available...
echo "Waiting for Dynamodb table to be available..."
aws dynamodb wait table-exists \
--table-name ${DYNAMO_DB_NAME} && \
echo "Dynamodb table available"

# Create SQS
echo "Creating SQS..."
SQS_URL="$(aws --output text --query "QueueUrl" sqs create-queue \
  --queue-name ${SQS_NAME})"
echo "SQS_URL=${SQS_URL}" > ${OUTPUT_DIR}aws.variables.txt
echo "SQS ${SQS_URL} created | ${SQS_URL} added to ${OUTPUT_DIR}aws.variables.txt"

# Create VPC
echo "Creating VPC"
VPC_ID="$(aws --output text --query "Vpc.VpcId" ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --instance-tenancy default)"

echo "Waiting for VPC to available"
aws ec2 wait vpc-available \
    --vpc-ids ${VPC_ID} && \
    echo "VPC_ID=${VPC_ID}" >> ${OUTPUT_DIR}aws.variables.txt
echo "VPC ${VPC_ID} created | ${VPC_ID} added to ${OUTPUT_DIR}aws.variables.txt"

# Modify VPC attributes
echo "Modifying VPC attributes..."
aws ec2 modify-vpc-attribute \
    --vpc-id ${VPC_ID} \
    --enable-dns-support "{\"Value\":true}" && \
    echo "${VPC_ID} dns support enabled"

aws ec2 modify-vpc-attribute \
    --vpc-id ${VPC_ID} \
    --enable-dns-hostnames "{\"Value\":true}" && \
    echo "${VPC_ID} dns hostnames enabled"


# Create Internet Gateway
echo "Creating Internet Gateway..."
INTERNET_GATEWAY_ID="$(aws --output text --query "InternetGateway.InternetGatewayId" ec2 create-internet-gateway)"
echo "INTERNET_GATEWAY_ID=${INTERNET_GATEWAY_ID}" >> ${OUTPUT_DIR}aws.variables.txt
echo "Internet Gateway ${INTERNET_GATEWAY_ID} created | ${INTERNET_GATEWAY_ID} added to ${OUTPUT_DIR}aws.variables.txt"

# Attach Internet gateway
echo "Attaching Internet Gateway..."
aws ec2 attach-internet-gateway \
    --internet-gateway-id ${INTERNET_GATEWAY_ID} \
    --vpc-id ${VPC_ID} && \
    echo "Internet Gateway ${INTERNET_GATEWAY_ID} attched to VPC ${VPC_ID}" 

# Create Subnets
echo "Creating Subnet 1..."
SUBNET1="$(aws --output text --query "Subnet.SubnetId" ec2 create-subnet \
    --vpc-id ${VPC_ID} \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${AWS_REGION}a)"
echo "SUBNET1=${SUBNET1}" >> ${OUTPUT_DIR}aws.variables.txt
echo "SUBNET ${SUBNET1} created | ${SUBNET1} added to ${OUTPUT_DIR}aws.variables.txt"

echo "Creating Subnet 2..."
SUBNET2="$(aws --output text --query "Subnet.SubnetId" ec2 create-subnet \
    --vpc-id ${VPC_ID} \
    --cidr-block 10.0.2.0/28 \
    --availability-zone ${AWS_REGION}c)"
echo "SUBNET2=${SUBNET2}" >> ${OUTPUT_DIR}aws.variables.txt
echo "SUBNET ${SUBNET2} created | ${SUBNET2} added to ${OUTPUT_DIR}aws.variables.txt"

# Get VPC main routing table
echo "Creating VPC routing table..."
ROUTING_TABLE_ID="$(aws --output text --query "RouteTables[?VpcId=='${VPC_ID}'].RouteTableId"  \
    ec2 describe-route-tables)"
echo "ROUTING_TABLE_ID=${ROUTING_TABLE_ID}" >> ${OUTPUT_DIR}aws.variables.txt
echo "Routing Table: ${ROUTING_TABLE_ID} created | ${ROUTING_TABLE_ID} added to ${OUTPUT_DIR}aws.variables.txt"

# Create route for all ipv4 traffic to enter Internet Gateway
echo "Enabling IPV4 traffic to Internet Gateway..."
aws --output json ec2 create-route \
    --route-table-id ${ROUTING_TABLE_ID} \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id ${INTERNET_GATEWAY_ID} && \
    echo "Route added for ipv4 ${INTERNET_GATEWAY_ID}"

# Associate Subnet with routing table
echo "Adding subnets to routing table..."
aws ec2 associate-route-table \
    --route-table-id ${ROUTING_TABLE_ID} \
    --subnet-id ${SUBNET1} && \
    echo "Route table associated with ${SUBNET1}"

aws ec2 associate-route-table \
    --route-table-id ${ROUTING_TABLE_ID} \
    --subnet-id ${SUBNET2} && \
    echo "Route table associated with ${SUBNET2}"

# Create security groups
echo "Creating security group..."
SECURITY_GROUP_ID="$(aws ec2 create-security-group \
    --group-name ${SECURITY_GROUP_NAME} \
    --description "${NAME} ITMO444 midterm group" \
    --vpc-id ${VPC_ID})"
echo "SECURITY_GROUP_ID=${SECURITY_GROUP_ID}" >> ${OUTPUT_DIR}aws.variables.txt
echo "SECURITY_GROUP ${SECURITY_GROUP_ID} created | ${SECURITY_GROUP_ID} added to ${OUTPUT_DIR}aws.variables.txt"

# Add port authorization
# HTTP
echo "Enabling HTTP traffic..."
aws ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp  \
    --port 80 \
    --cidr 0.0.0.0/0 && \
    echo "SECURITY_GROUP ${SECURITY_GROUP_ID} inbound HTTP"     

# HTTPS
echo "Enabling HTTPS traffic..."
aws ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 && \
    echo "SECURITY_GROUP ${SECURITY_GROUP_ID} inbound HTTPS"  

# SSH
echo "Enabling SSH traffic..."
aws ec2 authorize-security-group-ingress \
    --group-id ${SECURITY_GROUP_ID} \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 && \
    echo "SECURITY_GROUP ${SECURITY_GROUP_ID} inbound SSH"  

# Create Target Group
echo "Creating Target Group..."
TARGET_GROUP_ARN=$(aws --output text --query "TargetGroups[].TargetGroupArn" elbv2 create-target-group \
    --name my-ip-targets-http \
    --protocol HTTP \
    --port 80 \
    --target-type ip \
    --vpc-id ${VPC_ID})
echo "TARGET_GROUP_ARN=${TARGET_GROUP_ARN}" >> ${OUTPUT_DIR}aws.variables.txt
echo "Target Group: ${TARGET_GROUP_ARN} created | ${TARGET_GROUP_ARN} added to ${OUTPUT_DIR}aws.variables.txt"

# Modify Target group stickiness attribute
echo "Modifying Target Groups stickiness attribute..."
aws --output json elbv2 modify-target-group-attributes \
    --target-group-arn ${TARGET_GROUP_ARN} \
    --attributes "Key=stickiness.enabled,Value=true" "Key=stickiness.type,Value=lb_cookie" && \
    echo "Added Target Group stickiness attribute"

# Create Load Balancers
echo "Creating Load Balancers..."
LOAD_BALANCER_VARS="$(aws --output text --query "LoadBalancers[].[LoadBalancerArn,DNSName]" elbv2 create-load-balancer \
    --name ${ELB_NAME} \
    --scheme internet-facing \
    --type application \
    --security-groups ${SECURITY_GROUP_ID} \
    --subnets ${SUBNET1} ${SUBNET2} | tr '\n' ' ')"
echo "LOAD_BALANCER_VARS=${LOAD_BALANCER_VARS}" >> ${OUTPUT_DIR}aws.variables.txt
LOAD_BALANCER_ARN="$(grep "LOAD_BALANCER_VARS" ${OUTPUT_DIR}aws.variables.txt | cut -d '=' -f 2 | cut --output-delimiter='     ' -f 1)"
LOAD_BALANCER_DNS_NAME="$(grep "LOAD_BALANCER_VARS" ${OUTPUT_DIR}aws.variables.txt | cut -d '=' -f 2 | cut --output-delimiter='     ' -f 2)"
echo "LOAD_BALANCER_DNS_NAME=${LOAD_BALANCER_DNS_NAME}" >> ${OUTPUT_DIR}aws.variables.txt
echo "LOAD_BALANCER_ARN=${LOAD_BALANCER_ARN}" >> ${OUTPUT_DIR}aws.variables.txt

# Create ELB listners
echo "Creating Load Balancers HTTP/HTTPS listners..."
aws elbv2 create-listener \
    --load-balancer-arn ${LOAD_BALANCER_ARN} \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} && \
    echo "ELB HTTP listener created"

# aws elbv2 create-listener \
#     --load-balancer-arn ${LOAD_BALANCER_ARN} \
#     --protocol HTTPS \
#     --port 443 \
#     --default-actions Type=forward,TargetGroupArn=${TARGET_GROUP_ARN} && \
#     echo "ELB HTTPS listener created"

# Appened RDS Hostname and start scrtipt to end of install file 
cat <<EOT >> ./install-app-env.sh


# Adding additional variables
echo 'DYNAMO_DB_NAME="${DYNAMO_DB_NAME}"' >> /etc/environment
echo 'LOAD_BALANCER_DNS_NAME="${LOAD_BALANCER_DNS_NAME}"' >> /etc/environment
echo 'SQS_URL="${SQS_URL}"' >> /etc/environment

# Run App
git clone git@github.com:jarronb/jbailey6.git /project

cd /project/ITMO-444/mp2/pre-process-web-app/
sudo npm run install-start
EOT

# Appened RDS Hostname and start scrtipt to end of install file 
cat <<EOT >> ./install-app-poller-env.sh


# Adding additional variables
echo 'DYNAMO_DB_NAME="${DYNAMO_DB_NAME}"' >> /etc/environment
echo 'LOAD_BALANCER_DNS_NAME="${LOAD_BALANCER_DNS_NAME}"' >> /etc/environment
echo 'SQS_URL="${SQS_URL}"' >> /etc/environment

# Run App
git clone git@github.com:jarronb/jbailey6.git /project

cd /project/ITMO-444/mp2/post-process-web-app
sudo npm run install-start
EOT

# Create EC2 instances
echo "Creating EC2 instances..."
aws --output json ec2 run-instances \
    --image-id ${EC2_IMAGE} \
    --count 2 \
    --instance-type t2.micro \
    --subnet-id ${SUBNET1} \
    --key-name ${EC2_KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --user-data file://${USER_DATA_FILE_PATH} \
    --associate-public-ip-address \
    --iam-instance-profile Name=${AWS_EC2_INSTANCE_PROFILE}

# Get Instances IDs
EC2_INSTANCE_IDS="$(aws ec2 describe-instances --filters  "Name=instance-state-name,Values=pending" "Name=image-id,Values=${EC2_IMAGE}" --query "Reservations[].Instances[].[InstanceId]" --output text | tr '\n' ' ')"
echo "EC2 instances ${EC2_INSTANCE_IDS} created"

EC2_IP_ADDRESSES="$(aws ec2 describe-instances --output text --filters  "Name=instance-state-name,Values=pending,running" "Name=image-id,Values=${EC2_IMAGE}" --query "Reservations[].Instances[].[PrivateIpAddress]" | tr '\n' ' ')"
echo "EC2_INSTANCE_IDS=${EC2_INSTANCE_IDS}" >> ${OUTPUT_DIR}aws.variables.txt
echo "EC2_IP_ADDRESSES=${EC2_IP_ADDRESSES}" >> ${OUTPUT_DIR}aws.variables.txt

# Create EC2 polling instances
echo "Creating EC2 polling instances..."
aws --output json ec2 run-instances \
    --image-id ${EC2_IMAGE} \
    --count 2 \
    --instance-type t2.micro \
    --subnet-id ${SUBNET1} \
    --key-name ${EC2_KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --user-data file://${USER_DATA_FILE_PATH2} \
    --associate-public-ip-address \
    --iam-instance-profile Name=${AWS_EC2_INSTANCE_PROFILE}

# Get Instances IDs
ALL_EC2_INSTANCE_IDS="$(aws ec2 describe-instances --filters  "Name=instance-state-name,Values=pending" "Name=image-id,Values=${EC2_IMAGE}" --query "Reservations[].Instances[].[InstanceId]" --output text | tr '\n' ' ')"
echo "EC2 instances ${ALL_EC2_INSTANCE_IDS} created"

ALL_IP_ADDRESSES="$(aws ec2 describe-instances --output text --filters  "Name=instance-state-name,Values=pending,running" "Name=image-id,Values=${EC2_IMAGE}" --query "Reservations[].Instances[].[PrivateIpAddress]" | tr '\n' ' ')"
echo "ALL_EC2_INSTANCE_IDS=${ALL_EC2_INSTANCE_IDS}" >> ${OUTPUT_DIR}aws.variables.txt
echo "ALL_IP_ADDRESSES=${ALL_IP_ADDRESSES}" >> ${OUTPUT_DIR}aws.variables.txt

# Wait for EC2 Instances  status OK
echo "Wating on EC2 instances..."
aws ec2 wait instance-exists && \
echo "EC2 instances created"

# Register Targets
echo "Registering EC2 instances with load balancer..."
IP_ADDRESS1="$(grep 'EC2_IP_ADDRESSES' ${OUTPUT_DIR}aws.variables.txt | cut -d '=' -f 2 | cut -d ' ' -f 1) "
IP_ADDRESS2="$(grep 'EC2_IP_ADDRESSES' ${OUTPUT_DIR}aws.variables.txt | cut -d '=' -f 2 | cut -d ' ' -f 2)"
aws elbv2 register-targets \
    --target-group-arn ${TARGET_GROUP_ARN} \
    --targets "Id=${IP_ADDRESS1},Port=80" "Id=${IP_ADDRESS2},Port=80" && \
    echo "EC2 targets registered"

# Wait on EC2 instances
echo "Waiting for EC2 Instances to be ready..."
aws ec2 wait instance-status-ok \
    --instance-ids ${EC2_INSTANCE_IDS} ${ALL_EC2_INSTANCE_IDS} && \
    echo "Web App will be running at: http://${LOAD_BALANCER_DNS_NAME}"