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
    
    // Extinguish the monster entirely so it cannot be caught again
    await pool.query('DELETE FROM monsterstbl WHERE monster_id = ?', [monster_id]);
    
    res.json({ message: 'Monster caught successfully!', catch_id: result.insertId });
  } catch (error) {
    console.error('Catch error:', error);
    res.status(500).json({ message: 'Failed to catch monster', error: error.message });
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
