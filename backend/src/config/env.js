// backend/src/config/env.js
// Loads environment variables from backend/.env once and exposes them as one
// `config` object. The app refuses to start if a required secret is missing,
// so a bad deployment fails loudly instead of running with unsafe defaults.
import dotenv from "dotenv";

// Values already set in the real environment (for example on Render, or by
// the test helper) win over the .env file.
dotenv.config({ quiet: true });

const REQUIRED = ["JWT_SECRET", "DB_HOST", "DB_USER", "DB_NAME"];

const missing = REQUIRED.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missing.join(", ")}. ` +
      "Copy backend/.env.example to backend/.env and fill them in."
  );
}

if (process.env.NODE_ENV === "production" && process.env.JWT_SECRET.length < 32) {
  throw new Error("JWT_SECRET must be at least 32 characters in production.");
}

const nodeEnv = process.env.NODE_ENV || "development";

export const config = {
  port: Number(process.env.PORT) || 5000,
  nodeEnv,
  isProduction: nodeEnv === "production",
  isTest: nodeEnv === "test",
  frontendUrl: process.env.FRONTEND_URL || "http://localhost:5173",
  jwtSecret: process.env.JWT_SECRET,
  appTimezone: process.env.APP_TIMEZONE || "Asia/Manila",
  db: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER,
    // An empty password is allowed for local MySQL installs that have none.
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME,
    // Cloud databases (TiDB, Aiven) require SSL; local MySQL usually does not.
    ssl: process.env.DB_SSL === "true",
    // Optional CA certificate text (Aiven gives you one to download).
    ca: process.env.DB_CA ? process.env.DB_CA.replace(/\\n/g, "\n") : undefined,
  },
};
