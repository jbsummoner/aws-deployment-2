/* eslint-disable consistent-return */
const AWS = require('./config');
const { jimpRegular, jimpBlackAndWhite } = require('../jimp');

const s3 = new AWS.S3();

// const { user } = require('./db.service');

const { S3_BUCKET_RAW_IMAGE, S3_BUCKET_POST_IMAGE } = process.env;

const rawUpload = async file => {
  let rawImage;
  // eslint-disable-next-line no-use-before-define
  await jimpRegular(file.data).then(image => (rawImage = image));

  const params = {
    ACL: 'public-read',
    Bucket: S3_BUCKET_RAW_IMAGE,
    Body: rawImage,
    Key: file.name
  };

  s3.upload(params, (err, data) => {
    // handle error
    if (err) {
      // eslint-disable-next-line no-console
      console.log('Error', err);
      throw err;
    }
    // success

    return data;
  });

  return {
    location: `https://${S3_BUCKET_RAW_IMAGE}.s3.amazonaws.com/${file.name}`,
    filename: file.name
  };
};

const postUpload = async file => {
  let postImage;
  // eslint-disable-next-line no-use-before-define
  await jimpBlackAndWhite(file.data).then(image => (postImage = image));

  const params = {
    ACL: 'public-read',
    Bucket: S3_BUCKET_POST_IMAGE,
    Body: postImage,
    Key: file.name
  };
  s3.upload(params, (err, data) => {
    // handle error
    if (err) {
      // eslint-disable-next-line no-console
      console.log('Error', err);
    }
    // success
    if (data) {
      return data;
    }
  });

  return {
    location: `https://${S3_BUCKET_POST_IMAGE}.s3.amazonaws.com/${file.name}`,
    filename: file.name
  };
};

async function clearS3Buckets() {
  // let keys = await user.getAllFilenames();
  // keys = keys.map(entry => {
  //   return {
  //     Key: entry.dataValues.filename
  //   };
  // });
  // const rawParams = {
  //   Bucket: S3_BUCKET_RAW_IMAGE,
  //   Delete: {
  //     Objects: keys,
  //     Quiet: false
  //   }
  // };
  // s3.deleteObjects(rawParams, (err, data) => {
  //   if (err) {
  //     // eslint-disable-next-line no-console
  //     console.log(err.name, err.message);
  //   }
  //   // an error occurred
  //   // eslint-disable-next-line no-console
  //   else console.log(data);
  // });
  // const postParams = {
  //   Bucket: S3_BUCKET_POST_IMAGE,
  //   Delete: {
  //     Objects: keys,
  //     Quiet: false
  //   }
  // };
  // s3.deleteObjects(postParams, (err, data) => {
  //   if (err) {
  //     // eslint-disable-next-line no-console
  //     console.log(err.name, err.message);
  //   }
  //   // an error occurred
  //   // eslint-disable-next-line no-console
  //   else console.log(data);
  // });
}

module.exports = {
  rawUpload,
  postUpload,
  clearS3Buckets
};
