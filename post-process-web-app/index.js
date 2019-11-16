/* eslint-disable no-console */
require('dotenv-flow').config();

const { poller } = require('./services/aws').sqs;

async function main() {
  console.log('Polling');
  poller();
}

main();
