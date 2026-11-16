async function authenticate(verifyToken, token, { timeoutMs = 20000 } = {}) {
  let timer;
  try {
    return await Promise.race([
      Promise.resolve().then(() => verifyToken(token)),
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(Object.assign(
          new Error('Sign-in verification is temporarily unavailable. Please try again.'),
          { status: 503 })), timeoutMs);
      }),
    ]);
  } catch (error) {
    if (error.status === 503) throw error;
    if (['auth/insufficient-permission', 'auth/internal-error', 'app/network-error',
      'app/invalid-credential', 'ENOTFOUND', 'ETIMEDOUT', 'ECONNRESET'].includes(error.code)) {
      console.error('Server sign-in verification failed:', error.code);
      throw Object.assign(new Error('The server cannot verify sign-in right now. Please try again later.'), { status: 503 });
    }
    throw Object.assign(new Error('Your session expired. Sign in again.'), { status: 401 });
  } finally { clearTimeout(timer); }
}

module.exports = { authenticate };
