/* eslint-disable no-console */
/* eslint-disable consistent-return */
const AWS = require('./config');

const dynamodb = new AWS.DynamoDB();

const { DYNAMO_DB_NAME } = process.env;

const create = item => {
  // params = {
  //   AttributeDefinitions: [
  //     {
  //       AttributeName: 'uuid',
  //       AttributeType: 'S'
  //     }
  //   ],
  //   KeySchema: [
  //     {
  //       AttributeName: 'uuid',
  //       KeyType: 'HASH'
  //     }
  //   ],
  //   ProvisionedThroughput: {
  //     ReadCapacityUnits: 5,
  //     WriteCapacityUnits: 5
  //   },
  //   TableName: DYNAMO_DB_NAME
  // };

  //  dynamodb.createTable(params, (err, data) => {
  //   if (err) console.log(err, err.stack);
  //   // an error occurred
  //   else console.log(data); // successful response
  // });

  const { uuid, email, phone, filename, s3rawurl } = item;
  const params = {
    Item: {
      uuid: {
        S: uuid
      },
      email: {
        S: email
      },
      phone: {
        S: phone
      },
      filename: {
        S: filename
      },
      s3rawurl: {
        S: s3rawurl
      },
      status: {
        N: '1'
      },
      issubscribed: {
        BOOL: true
      }
    },
    ReturnConsumedCapacity: 'TOTAL',
    TableName: DYNAMO_DB_NAME,
    ReturnValues: 'ALL_OLD'
  };

  return dynamodb.putItem(params);
};

const getAll = () => {
  const documentClient = new AWS.DynamoDB.DocumentClient();

  const params = {
    TableName: DYNAMO_DB_NAME
  };

  return documentClient.scan(params);
};

const getItem = uuid => {
  const params = {
    Key: {
      uuid: {
        S: uuid
      }
    },
    TableName: DYNAMO_DB_NAME
  };

  return dynamodb.getItem(params);
};

const updateItem = item => {
  const { uuid, s3finishedurl } = item;
  const params = {
    Key: {
      uuid: {
        S: uuid
      }
    },
    AttributeUpdates: {
      s3finishedurl: {
        Action: 'PUT',
        Value: {
          /* AttributeValue */

          S: s3finishedurl
        }
      }
      /* '<AttributeName>': ... */
    },
    ReturnValues: 'ALL_NEW',
    TableName: DYNAMO_DB_NAME
  };

  return dynamodb.updateItem(params);
};

const clear = () => {
  const params = {
    TableName: DYNAMO_DB_NAME
  };

  dynamodb.deleteTable(params, (err, data) => {
    if (err) console.log(err, err.stack);
    // an error occurred
    else return data.Item; // successful response
  });
};

module.exports = {
  create,
  getAll,
  clear,
  getItem,
  updateItem
};
