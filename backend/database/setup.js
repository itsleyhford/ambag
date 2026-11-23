// backend/database/setup.js
// Creates the database (if needed), then runs schema.sql and seed.sql.
//
//   npm run db:setup          -> schema + demo data
//   npm run db:setup -- --no-seed  -> schema only (empty tables)
//
// It DROPS and recreates all tables, so it refuses to run in production.
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import mysql from "mysql2/promise";
import { config } from "../src/config/env.js";
import { buildConnectionOptions } from "../src/config/db.js";

const here = path.dirname(fileURLToPath(import.meta.url));

export async function setupDatabase({ withSeed = true } = {}) {
  if (config.isProduction) {
    throw new Error("db:setup drops all tables, so it is disabled when NODE_ENV=production.");
  }

  // Connect without choosing a database first, so we can create it.
  const conn = await mysql.createConnection({
    ...buildConnectionOptions({ includeDatabase: false }),
    multipleStatements: true, // needed to run whole .sql files
  });

  try {
    // A database name cannot be a ? placeholder, so it is safely escaped
    // with escapeId (it comes from our own .env, not from users).
    const dbName = mysql.escapeId(config.db.database);
    await conn.query(`CREATE DATABASE IF NOT EXISTS ${dbName} CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci`);
    await conn.query(`USE ${dbName}`);

    const schema = await readFile(path.join(here, "schema.sql"), "utf8");
    await conn.query(schema);

    if (withSeed) {
      const seed = await readFile(path.join(here, "seed.sql"), "utf8");
      await conn.query(seed);
    }
  } finally {
    await conn.end();
  }
}

// Run only when called directly (`node database/setup.js`), not when imported by tests.
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const withSeed = !process.argv.includes("--no-seed");
  setupDatabase({ withSeed })
    .then(() => {
      console.log(`Database "${config.db.database}" is ready${withSeed ? " with demo data" : ""}.`);
    })
    .catch((error) => {
      console.error("Database setup failed:", error.message);
      process.exitCode = 1;
    });
}
