const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const pool = require('../database');

// POST /auth/login
router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password required' });
  }

  try {
    const [rows] = await pool.query('SELECT player_id as id, username FROM playerstbl WHERE username = ? AND password = ?', [username, password]);
    
    if (rows.length > 0) {
      const player = rows[0];
      const token = jwt.sign({ id: player.id, username: player.username }, process.env.JWT_SECRET || 'fallback_secret', { expiresIn: '2h' });
      res.json({ token, player });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /auth/register
router.post('/register', async (req, res) => {
  const { player_name, username, password } = req.body;
  if (!player_name || !username || !password) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  try {
    const [existing] = await pool.query('SELECT * FROM playerstbl WHERE username = ?', [username]);
    if (existing.length > 0) return res.status(400).json({ message: 'Username already exists' });
    
    const [result] = await pool.query(
      'INSERT INTO playerstbl (player_name, username, password) VALUES (?, ?, ?)',
      [player_name, username, password]
    );

    res.status(201).json({ message: 'Account created successfully', player_id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
