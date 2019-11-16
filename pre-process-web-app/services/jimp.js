const Jimp = require('jimp');

async function jimpBlackAndWhite(file) {
  try {
    let postImage = await Jimp.read(file);
    postImage = await postImage
      .quality(100) // set JPEG quality
      .resize(320, Jimp.AUTO)
      .greyscale(); // set greyscale()

    return await postImage.getBufferAsync(Jimp.AUTO);
  } catch (error) {
    throw error;
  }
}

async function jimpRegular(file) {
  try {
    let postImage = await Jimp.read(file);
    postImage = await postImage
      .quality(100) // set JPEG quality
      .resize(320, Jimp.AUTO);

    return await postImage.getBufferAsync(Jimp.AUTO);
  } catch (error) {
    throw error;
  }
}

module.exports = {
  jimpBlackAndWhite,
  jimpRegular
};
