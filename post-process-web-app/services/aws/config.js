/* eslint-disable consistent-return */
const AWS = require('aws-sdk');

const creds = new AWS.EC2MetadataCredentials({
  httpOptions: { timeout: 5000 }, // 5 second timeout
  maxRetries: 10, // retry 10 times
  retryDelayOptions: { base: 200 } // see AWS.Config for information
});

AWS.config.update({
  credentials: creds,
  region: 'us-east-1',
  maxRetries: 15,
  logger: 'console',
  apiVersions: {
    s3: '2006-03-01',
    dynamodb: '2012-08-10',
    sns: '2010-03-31'
    // other service API versions
  }
});
module.exports = AWS;
