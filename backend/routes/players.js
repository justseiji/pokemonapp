const express = require('express');
const router = express.Router();
const pool = require('../database');

// GET all players
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT player_id as id, username, player_name FROM playerstbl');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET single player
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT player_id as id, username, player_name FROM playerstbl WHERE player_id = ?', [req.params.id]);
    if (rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ message: 'Player not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST new player
router.post('/', async (req, res) => {
  const { username, password, player_name } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO playerstbl (username, password, player_name) VALUES (?, ?, ?)',
      [username, password, player_name || 'Unknown']
    );
    res.status(201).json({ id: result.insertId, message: 'Player created' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT update player
router.put('/:id', async (req, res) => {
  const { username, password, player_name } = req.body;
  try {
    await pool.query(
      'UPDATE playerstbl SET username = ?, password = ?, player_name = ? WHERE player_id = ?',
      [username, password, player_name || 'Unknown', req.params.id]
    );
    res.json({ message: 'Player updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE player
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM playerstbl WHERE player_id = ?', [req.params.id]);
    res.json({ message: 'Player deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
