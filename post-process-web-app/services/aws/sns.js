/* eslint-disable no-console */
/* eslint-disable consistent-return */
const AWS = require('./config');

const sns = new AWS.SNS();

const { LOAD_BALANCER_DNS_NAME } = process.env;
let url = LOAD_BALANCER_DNS_NAME + '/gallery/';
url = url.replace(' ', '');

const sendSms = data => {
  const { phone, filename } = data;
  const params = {
    Message: `Jarron's midterm project has completed your black and white photo conversion, find it here at ${url}`,
    PhoneNumber: phone,
    Subject: `B&W ${filename} ready`
  };
  return sns.publish(params);
};
module.exports = { sendSms };
