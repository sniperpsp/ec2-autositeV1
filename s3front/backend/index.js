const express = require('express');
const AWS = require('aws-sdk');
const cors = require('cors');
const app = express();
const port = 3001;

app.use(cors());

AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});

const s3 = new AWS.S3();

app.get('/generate-presigned-url', (req, res) => {
  const params = {
    Bucket: process.env.S3_BUCKET_NAME,
    Key: `${process.env.S3_BUCKET_PATH}/${req.query.filename}`,
    Expires: 60, // URL válida por 60 segundos
    ContentType: req.query.filetype
  };

  s3.getSignedUrl('putObject', params, (err, url) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.send({ url });
  });
});

app.listen(port, () => {
  console.log(`Servidor rodando na porta ${port}`);
});