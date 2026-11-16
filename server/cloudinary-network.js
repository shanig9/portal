const https = require('node:https');
const agents = new Map();

// Some mobile hotspots provide working NAT64/IPv6 but no working IPv4 route.
// Leave unset on normal networks and on hosted deployments.
function cloudinaryNetworkOptions() {
  const configured = process.env.CLOUDINARY_IP_FAMILY?.trim();
  if (!configured) return {};
  const family = Number(configured);
  if (family !== 4 && family !== 6) throw new Error('CLOUDINARY_IP_FAMILY must be 4, 6, or empty.');
  if (!agents.has(family)) agents.set(family, new https.Agent({ family, keepAlive: true }));
  return { agent: agents.get(family) };
}

module.exports = { cloudinaryNetworkOptions };
