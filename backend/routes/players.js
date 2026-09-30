const express = require('express');
const router = express.Router();
const pool = require('../database');
const { requireAuth } = require('../middleware/auth');
const { hashPassword, verifyPassword } = require('../passwords');

router.use(requireAuth);

// Modifying or deleting an account requires that account's current password,
// checked here on the server (the app's "Security Check" dialog alone is bypassable).
async function checkCurrentPassword(req, res) {
  const { current_password } = req.body || {};
  if (!current_password) {
    res.status(400).json({ message: 'current_password is required' });
    return false;
  }
  const [rows] = await pool.query('SELECT password FROM playerstbl WHERE player_id = ?', [req.params.id]);
  if (rows.length === 0) {
    res.status(404).json({ message: 'Player not found' });
    return false;
  }
  const { ok } = await verifyPassword(current_password, rows[0].password);
  if (!ok) {
    res.status(403).json({ message: 'Incorrect password' });
    return false;
  }
  return true;
}

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
  if (!username || !password) {
    return res.status(400).json({ message: 'Username and password required' });
  }
  try {
    const [existing] = await pool.query('SELECT player_id FROM playerstbl WHERE username = ?', [username]);
    if (existing.length > 0) return res.status(400).json({ message: 'Username already exists' });

    const [result] = await pool.query(
      'INSERT INTO playerstbl (username, password, player_name) VALUES (?, ?, ?)',
      [username, await hashPassword(password), player_name || 'Unknown']
    );
    res.status(201).json({ id: result.insertId, message: 'Player created' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT update player (a blank password keeps the existing one)
router.put('/:id', async (req, res) => {
  const { username, password, player_name } = req.body;
  if (!username) {
    return res.status(400).json({ message: 'Username required' });
  }
  try {
    if (!(await checkCurrentPassword(req, res))) return;

    const [existing] = await pool.query('SELECT player_id FROM playerstbl WHERE username = ? AND player_id <> ?', [username, req.params.id]);
    if (existing.length > 0) return res.status(400).json({ message: 'Username already exists' });

    if (password) {
      await pool.query(
        'UPDATE playerstbl SET username = ?, password = ?, player_name = ? WHERE player_id = ?',
        [username, await hashPassword(password), player_name || 'Unknown', req.params.id]
      );
    } else {
      await pool.query(
        'UPDATE playerstbl SET username = ?, player_name = ? WHERE player_id = ?',
        [username, player_name || 'Unknown', req.params.id]
      );
    }
    res.json({ message: 'Player updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE player (body: { current_password })
router.delete('/:id', async (req, res) => {
  try {
    if (!(await checkCurrentPassword(req, res))) return;

    await pool.query('DELETE FROM monster_catchestbl WHERE player_id = ?', [req.params.id]);
    await pool.query('DELETE FROM playerstbl WHERE player_id = ?', [req.params.id]);
    res.json({ message: 'Player deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
