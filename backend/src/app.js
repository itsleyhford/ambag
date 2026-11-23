// backend/src/app.js
// Builds the Express app (middleware + routes) without starting a server.
// server.js starts it; the tests import createApp() directly with supertest.
import express from "express";
import helmet from "helmet";
import cors from "cors";
import cookieParser from "cookie-parser";
import { config } from "./config/env.js";
import { errorHandler, notFoundHandler } from "./middleware/errorHandler.js";

export function createApp() {
  const app = express();

  // Behind Render's proxy, trust the first hop so rate limiting sees real IPs.
  if (config.isProduction) app.set("trust proxy", 1);

  app.use(helmet()); // secure HTTP headers
  app.use(
    cors({
      origin: config.frontendUrl, // only our frontend may call the API
      credentials: true, // allow the login cookie
    })
  );
  app.use(express.json({ limit: "100kb" }));
  app.use(cookieParser());

  app.get("/api/health", (req, res) => {
    res.json({ status: "ok" });
  });

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
