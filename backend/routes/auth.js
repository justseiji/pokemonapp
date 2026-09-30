const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const pool = require('../database');
const { getJwtSecret } = require('../middleware/auth');
const { hashPassword, verifyPassword } = require('../passwords');

// POST /auth/login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password required' });
  }

  try {
    const [rows] = await pool.query('SELECT player_id as id, player_name, username, password FROM playerstbl WHERE username = ?', [username]);
    const { ok, needsRehash } = await verifyPassword(password, rows[0]?.password);

    if (!ok) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const { password: _stored, ...player } = rows[0];
    if (needsRehash) {
      await pool.query('UPDATE playerstbl SET password = ? WHERE player_id = ?', [await hashPassword(password), player.id]);
    }

    const token = jwt.sign({ id: player.id, username: player.username }, getJwtSecret(), { expiresIn: '2h' });
    res.json({ token, player });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Login failed' });
  }
});

// POST /auth/register
router.post('/register', async (req, res) => {
  const { player_name, username, password } = req.body;
  if (!player_name || !username || !password) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    const [existing] = await pool.query('SELECT player_id FROM playerstbl WHERE username = ?', [username]);
    if (existing.length > 0) return res.status(400).json({ message: 'Username already exists' });
    
    const [result] = await pool.query(
      'INSERT INTO playerstbl (player_name, username, password) VALUES (?, ?, ?)',
      [player_name, username, await hashPassword(password)]
    );

    res.status(201).json({ message: 'Account created successfully', player_id: result.insertId });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Registration failed' });
  }
});

module.exports = router;
