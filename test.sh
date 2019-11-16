aws --output json dynamodb create-table \
  --table-name Records \
  --attribute-definitions AttributeName=uuid,AttributeType=S \
  --key-schema AttributeName=uuid,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

aws --output text --query "QueueUrl" sqs create-queue \
  --queue-name test

aws dynamodb delete-table \
  --table-name ${DB_NAME}

aws sqs delete-queue \
  --queue-url https://queue.amazonaws.com/772498430221/test 



aws dynamodb delete-table \
  --table-name Records


aws sns  create-topic \
  --name test

aws sns publish \
  --phone-number 17739928479 \
  --message "blah"

/vagrant/data/jbailey6/ITMO-444/mp2/post-process-web-app/
/vagrant/data/jbailey6/ITMO-444/mp2/pre-process-web-app


aws dynamodb wait table-exists
--table-name Records


  aws s3api create-bucket \
    --bucket jbailey6-itmo444-midterm-raw-image-bucket \
    --region us-east-1 && \
    echo "Bucket: jbailey6-itmo444-midterm-raw-image-bucket created"

# Create post image s3 bucket
echo "Creating Post Image s3 Bucket"
aws s3api create-bucket \
    --bucket jbailey6-itmo444-midterm-post-image-bucket \
    --region us-east-1 && \
    echo "Bucket: jbailey6-itmo444-midterm-post-image-bucket created"


aws --output json ec2 run-instances \
    --image-id ami-02ea09b6148bc4a49 \
    --count 1 \
    --instance-type t2.micro \
    --subnet-id subnet-0f93b391823997175 \
    --key-name default-pair \
    --security-group-ids sg-08b1d5c9d1acd3e88 \
    --associate-public-ip-address \
    --additional-info pre-process-ec2-instance \
    --iam-instance-profile Name=Developer