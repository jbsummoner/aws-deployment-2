const AWS = require('./config');
const s3 = require('./s3');
const dynamodb = require('./dynamodb');
const sqs = require('./sqs');
const sns = require('./sns');

module.exports = {
  AWS,
  s3,
  dynamodb,
  sqs,
  sns
};
