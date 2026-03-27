const express = require('express');
const router = express.Router();
const pool = require('../database');

// POST /game/catch
router.post('/catch', async (req, res) => {
  const { player_id, monster_id, location_id } = req.body;

  if (!player_id || !monster_id) {
    return res.status(400).json({ message: 'Player ID and Monster ID required' });
  }

  try {
    // Insert record into monster_catchestbl
    const lat = req.body.latitude || 0;
    const lng = req.body.longitude || 0;

    const [result] = await pool.query(
      'INSERT INTO monster_catchestbl (player_id, moster_id, location_id, latitude, longitude, catch_datetime) VALUES (?, ?, ?, ?, ?, NOW())',
      [player_id, monster_id, location_id || 1, lat, lng]
    );

    // Instead of deleting the monster, we leave it in monsterstbl so its name and photo can be referenced.
    // The monsters endpoint has been updated to exclude caught monsters.


    res.json({ message: 'Monster caught successfully!', catch_id: result.insertId });
  } catch (error) {
    console.error('Catch error:', error);
    res.status(500).json({ message: 'Failed to catch monster', error: error.message });
  }
});

// GET /game/catches/:player_id
// Retrieve all monsters caught by a specific player
router.get('/catches/:player_id', async (req, res) => {
  try {
    const query = `
      SELECT c.catch_id, c.catch_datetime, m.Monster_id as id, m.Monster_name as name, m.Monster_type as type, m.picture_url
      FROM monster_catchestbl c
      JOIN monsterstbl m ON c.moster_id = m.Monster_id
      WHERE c.player_id = ?
      ORDER BY c.catch_datetime DESC
    `;
    const [rows] = await pool.query(query, [req.params.player_id]);
    res.json(rows);
  } catch (error) {
    console.error('Fetch catches error:', error);
    res.status(500).json({ message: 'Error fetching catches', error: error.message });
  }
});

// DELETE /game/catches/:catch_id
// Deletes a caught monster (releases it back to the wild) and lowers leaderboard score
router.delete('/catches/:catch_id', async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM monster_catchestbl WHERE catch_id = ?', [req.params.catch_id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Catch not found' });
    }
    res.json({ message: 'Catch deleted, monster released back to the wild.' });
  } catch (error) {
    console.error('Delete catch error:', error);
    res.status(500).json({ message: 'Error deleting catch', error: error.message });
  }
});

// GET /game/leaderboard
// Top 10 Monster Hunters dynamically computed
router.get('/leaderboard', async (req, res) => {
  try {
    const query = `
      SELECT p.player_id as id, p.username, COUNT(c.catch_id) as score, MIN(c.catch_datetime) as first_catch_time
      FROM playerstbl p
      JOIN monster_catchestbl c ON p.player_id = c.player_id
      GROUP BY p.player_id
      ORDER BY score DESC, first_catch_time ASC
      LIMIT 10
    `;
    const [rows] = await pool.query(query);
    res.json(rows);
  } catch (error) {
    console.error('Leaderboard error:', error);
    res.status(500).json({ message: 'Error fetching leaderboard', error: error.message });
  }
});

module.exports = router;
