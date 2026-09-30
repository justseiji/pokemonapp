const bcrypt = require('bcryptjs');

const hashPassword = (plain) => bcrypt.hash(plain, 10);

// Existing rows were stored in plain text. Accept those once and report that
// the caller should re-hash, so accounts migrate transparently on next login.
async function verifyPassword(plain, stored) {
  if (!stored) return { ok: false, needsRehash: false };
  if (/^\$2[aby]\$/.test(stored)) {
    return { ok: await bcrypt.compare(plain, stored), needsRehash: false };
  }
  return { ok: plain === stored, needsRehash: plain === stored };
}

module.exports = { hashPassword, verifyPassword };
