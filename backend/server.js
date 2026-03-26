const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env'), override: true });

const app = express();
app.use(cors());
app.use(express.json());

// Main Routes
app.use('/auth', require('./routes/auth'));
app.use('/players', require('./routes/players'));
app.use('/monsters', require('./routes/monsters'));
app.use('/game', require('./routes/game'));
app.use('/ec2', require('./routes/ec2'));

app.get('/', (req, res) => {
  res.json({ message: 'Welcome to HAUPokemon Backend API' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`HAUPokemon Server started on port ${PORT}`);
});
