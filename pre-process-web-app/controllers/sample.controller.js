const UUID = require('node-uuid');

const { s3, dynamodb: userService, sqs } = require('../services').awsService;

const getEntries = async (req, res, next) => {
  let users;
  try {
    const response = await userService.getAll().promise();
    users = response.Items;

    return res.json({
      users
    });
  } catch (e) {
    return next(e);
  }
};

// eslint-disable-next-line consistent-return
const postEntry = async (req, res, next) => {
  const { email, phone } = await req.body;
  const { photos } = req.files;
  const uuid = UUID.v4();
  const status = '1';
  const issubscribed = true;
  let payload;

  try {
    if (photos.length > 0) {
      res.json({
        msg: 'Only one photo'
      });
      // await photos.forEach(photo => {
      //   awsService.rawUpload(photo);
      //   awsService.postUpload(photo);
      // });
    } else {
      const { location: s3rawurl, filename } = await s3.rawUpload(photos);
      const user = await {
        uuid,
        email,
        phone,
        filename,
        s3rawurl,
        status,
        issubscribed
      };

      payload = await userService.create(user).promise();
      await sqs.sendMessage(user).promise();

      return res.json({
        ...payload
      });
    }
  } catch (e) {
    return next(e);
  }
};

const reset = async (req, res, next) => {
  try {
    const keys = await s3.clearS3Buckets();
    const users = await userService.clear();

    return res.json({
      msg: 'App reset',
      users,
      keys
    });
  } catch (e) {
    return next(e);
  }
};

module.exports = {
  getEntries,
  postEntry,
  reset
};
