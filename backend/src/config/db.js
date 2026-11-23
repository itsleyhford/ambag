// backend/src/config/db.js
// One shared MySQL connection pool for the whole app, plus a helper that runs
// several queries as ONE transaction (all succeed, or none are saved).
import mysql from "mysql2/promise";
import { config } from "./env.js";

/**
 * SSL settings for cloud databases (TiDB Cloud, Aiven).
 * - With DB_CA set, the server certificate is checked against that CA.
 * - Without it, Node's built-in trusted CAs are used (works for TiDB Cloud).
 * Local MySQL uses DB_SSL=false, so no SSL object is passed.
 */
function buildSslOptions() {
  if (!config.db.ssl) return undefined;
  return {
    minVersion: "TLSv1.2",
    rejectUnauthorized: true,
    ...(config.db.ca ? { ca: config.db.ca } : {}),
  };
}

export function buildConnectionOptions({ includeDatabase = true } = {}) {
  return {
    host: config.db.host,
    port: config.db.port,
    user: config.db.user,
    password: config.db.password,
    ...(includeDatabase ? { database: config.db.database } : {}),
    ssl: buildSslOptions(),
    // Return DATE/DATETIME columns as plain strings ("2026-12-02") so dates
    // never shift because of the server's time zone.
    dateStrings: true,
    timezone: "Z",
  };
}

export const pool = mysql.createPool({
  ...buildConnectionOptions(),
  waitForConnections: true,
  connectionLimit: 10,
});

/**
 * Runs `work(conn)` inside a database transaction.
 *
 * Every query inside `work` must use the `conn` it receives (not `pool`),
 * otherwise that query would run outside the transaction.
 *
 * - If `work` finishes, COMMIT saves every change together.
 * - If `work` throws (a rule failed, a query failed), ROLLBACK undoes every
 *   change made so far, and the error is passed on to the caller.
 * - The connection always goes back to the pool.
 */
export async function withTransaction(work) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await work(conn);
    await conn.commit();
    return result;
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}

export async function closePool() {
  await pool.end();
}
