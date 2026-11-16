const path = require('node:path');
require('dotenv').config({ path: path.join(__dirname, '.env'), quiet: true });
const { v2: cloudinary } = require('cloudinary');
const { cloudinaryNetworkOptions } = require('./cloudinary-network');
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true,
});
cloudinary.api.ping({ timeout: 15000, ...cloudinaryNetworkOptions() }).then(() => {
  console.log('Cloudinary credentials and connection: verified');
}).catch((error) => {
  const detail = error.error || error;
  let message = String(detail.message || detail.name || 'Connection failed');
  for (const key of ['CLOUDINARY_API_KEY', 'CLOUDINARY_API_SECRET']) {
    if (process.env[key]) message = message.split(process.env[key]).join('[redacted]');
  }
  console.error(`Cloudinary check failed (${detail.http_code || detail.code || 'connection error'}): ${message.slice(0, 240)}`);
  process.exitCode = 1;
});
