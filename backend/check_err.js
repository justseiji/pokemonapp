const pool = require('./database');

async function test() {
  try {
    const [rows] = await pool.query('DESCRIBE monster_catchestbl');
    console.log(rows.map(r => r.Field).join(', '));
  } catch(e) {
    console.error(e);
  }
  process.exit(0);
}
test();
