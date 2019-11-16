/* eslint-disable no-console */
/* eslint-disable consistent-return */
const AWS = require('./config');
const { getItem, updateItem } = require('./dynamodb');
const { postUpload } = require('./s3');
const { sendSms } = require('./sns');

const { SQS_URL } = process.env;

const sqs = new AWS.SQS({ endpoint: 'https://sqs.us-east-1.amazonaws.com/772498430221/test' });

const sendMessage = item => {
  const { uuid } = item;
  const params = {
    MessageAttributes: {
      uuid: {
        DataType: 'String',
        StringValue: uuid
      }
    },
    MessageBody: JSON.stringify({ uuid }),
    // MessageDeduplicationId: "TheWhistler",  // Required for FIFO queues
    // MessageId: "Group1",  // Required for FIFO queues
    QueueUrl: SQS_URL
  };

  return sqs.sendMessage(params);
};

const receiveAndDeleteMessage = () => {
  const params = {
    AttributeNames: ['uuid'],
    MaxNumberOfMessages: 10,
    MessageAttributeNames: ['All'],
    QueueUrl: SQS_URL,
    VisibilityTimeout: 20,
    WaitTimeSeconds: 1
  };

  sqs.receiveMessage(params, (err, data) => {
    if (err) {
      console.log('Receive Error', err);
    } else if (data.Messages) {
      const { Messages } = data;

      Messages.forEach(async message => {
        const key = message.MessageAttributes.uuid.StringValue;
        const response = await getItem(key).promise();
        const { Item } = await response;
        const {
          uuid: { S: uuid },
          filename: { S: filename },
          s3rawurl: { S: s3rawurl },
          phone: { S: phone }
        } = await Item;

        const file = await {
          data: s3rawurl,
          name: filename
        };

        const { location: s3finishedurl } = await postUpload(file);

        const toUpdateItem = {
          uuid,
          s3finishedurl
        };

        const toSms = {
          filename,
          phone
        };

        await updateItem(toUpdateItem).promise();
        await sendSms(toSms).promise();
        // eslint-disable-next-line no-use-before-define
        await deleteMessage(message);
      });
    }
  });
};

const poller = () => {
  setInterval(() => {
    receiveAndDeleteMessage();
  }, 15000);
};

function deleteMessage(message) {
  const deleteParams = {
    QueueUrl: SQS_URL,
    ReceiptHandle: message.ReceiptHandle
  };
  sqs.deleteMessage(deleteParams, (err, data) => {
    if (err) {
      console.log('Delete Error', err);
    } else {
      return data;
    }
  });
}
module.exports = {
  sendMessage,
  receiveAndDeleteMessage,
  poller
};
