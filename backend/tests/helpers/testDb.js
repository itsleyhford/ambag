// backend/tests/helpers/testDb.js
// Rebuilds the test database with fresh demo data before each test file.
import { setupDatabase } from "../../database/setup.js";
import { pool } from "../../src/config/db.js";

export async function resetTestDb() {
  await setupDatabase({ withSeed: true });
}

/** Runs a query on the test database and returns the rows. */
export async function q(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}
