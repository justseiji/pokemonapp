const mysql = require('mysql2/promise');
require('dotenv').config();

// We are assuming the existing database has: location, monster_catches, monsters, players, leaderboard tables.
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'haumonstersdb.can4iow42krd.us-east-1.rds.amazonaws.com',
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'Pickachu123',
  database: 'haumonstersDB',
  port: 3306,
  ssl: { rejectUnauthorized: false }, // Required for AWS RDS
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;


