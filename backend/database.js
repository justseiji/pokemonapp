const mysql = require('mysql2/promise');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

// Credentials must come from the environment (.env locally, Elastic Beanstalk env vars in production).
// Never hardcode them here: this file is committed to git.
for (const key of ['DB_HOST', 'DB_USER', 'DB_PASSWORD']) {
  if (!process.env[key]) throw new Error(`Missing required environment variable ${key}`);
}

// We are assuming the existing database has: location, monster_catches, monsters, players, leaderboard tables.
const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'haumonstersDB',
  port: Number(process.env.DB_PORT) || 3306,
  ssl: { rejectUnauthorized: false }, // Required for AWS RDS
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;
