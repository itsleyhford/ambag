// backend/server.js
// Entry point: starts the HTTP server. Run with `npm run dev` (auto-restart)
// or `npm start` (production).
import { createApp } from "./src/app.js";
import { config } from "./src/config/env.js";
import { pool } from "./src/config/db.js";

const app = createApp();

app.listen(config.port, async () => {
  console.log(`AMBAG API running on http://localhost:${config.port}`);
  // Quick database check so a wrong password shows up immediately.
  try {
    await pool.query("SELECT 1");
    console.log(`Connected to MySQL database "${config.db.database}"`);
  } catch (error) {
    console.error("Could not connect to MySQL. Check DB_* values in backend/.env.", error.message);
  }
});
