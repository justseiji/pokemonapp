const express = require('express');
const router = express.Router();
const pool = require('../database');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure Multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

// GET all monsters
router.get('/', async (req, res) => {
  try {
    const query = `
      SELECT m.Monster_id AS id, m.Monster_name AS name, m.Monster_type AS type, m.spawn_latitude AS lat, m.spwan_longitude AS lng, m.spawn_radius_meters AS radius, m.picture_url
      FROM monsterstbl m
      LEFT JOIN monster_catchestbl c ON m.Monster_id = c.moster_id
      WHERE c.catch_id IS NULL
    `;
    const [rows] = await pool.query(query);
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET single monster
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT Monster_id AS id, Monster_name AS name, Monster_type AS type, spawn_latitude AS lat, spwan_longitude AS lng, spawn_radius_meters AS radius, picture_url FROM monsterstbl WHERE Monster_id = ?', [req.params.id]);
    if (rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ message: 'Monster not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST new monster
router.post('/', async (req, res) => {
  const { name, type, lat, lng, radius, picture_url } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO monsterstbl (Monster_name, Monster_type, spawn_latitude, spwan_longitude, spawn_radius_meters, picture_url) VALUES (?, ?, ?, ?, ?, ?)',
      [name, type, lat || 14.5995, lng || 120.9842, radius || 100.0, picture_url || null]
    );
    res.status(201).json({ id: result.insertId, message: 'Monster created' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT update monster
router.put('/:id', async (req, res) => {
  const { name, type, lat, lng, radius, picture_url } = req.body;
  try {
    await pool.query(
      'UPDATE monsterstbl SET Monster_name = ?, Monster_type = ?, spawn_latitude = ?, spwan_longitude = ?, spawn_radius_meters = ?, picture_url = ? WHERE Monster_id = ?',
      [name, type, lat || 14.5995, lng || 120.9842, radius || 100.0, picture_url || null, req.params.id]
    );
    res.json({ message: 'Monster updated' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST upload new image for a monster
router.post('/:id/image', upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No image uploaded' });
  }
  const pictureUrl = '/uploads/' + req.file.filename;

  try {
    // Check if monster exists and delete old image if necessary
    const [rows] = await pool.query('SELECT picture_url FROM monsterstbl WHERE Monster_id = ?', [req.params.id]);
    if (rows.length > 0 && rows[0].picture_url && rows[0].picture_url.startsWith('/uploads/')) {
      const oldPath = path.join(__dirname, '..', rows[0].picture_url);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    await pool.query('UPDATE monsterstbl SET picture_url = ? WHERE Monster_id = ?', [pictureUrl, req.params.id]);
    res.json({ message: 'Image uploaded successfully', picture_url: pictureUrl });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE image from a monster
router.delete('/:id/image', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT picture_url FROM monsterstbl WHERE Monster_id = ?', [req.params.id]);
    if (rows.length > 0 && rows[0].picture_url && rows[0].picture_url.startsWith('/uploads/')) {
      const oldPath = path.join(__dirname, '..', rows[0].picture_url);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    await pool.query('UPDATE monsterstbl SET picture_url = NULL WHERE Monster_id = ?', [req.params.id]);
    res.json({ message: 'Image deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// DELETE monster
router.delete('/:id', async (req, res) => {
  try {
    // Delete image if exists
    const [rows] = await pool.query('SELECT picture_url FROM monsterstbl WHERE Monster_id = ?', [req.params.id]);
    if (rows.length > 0 && rows[0].picture_url && rows[0].picture_url.startsWith('/uploads/')) {
      const oldPath = path.join(__dirname, '..', rows[0].picture_url);
      if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
    }

    await pool.query('DELETE FROM monsterstbl WHERE Monster_id = ?', [req.params.id]);
    res.json({ message: 'Monster deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
