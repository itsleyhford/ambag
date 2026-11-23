// backend/tests/foundation.test.js
import "./helpers/env.js";
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import { createApp } from "../src/app.js";
import { closePool, withTransaction } from "../src/config/db.js";
import { todayInZone, addDays } from "../src/utils/dates.js";
import { resetTestDb, q } from "./helpers/testDb.js";

const app = createApp();

before(resetTestDb);
after(closePool);

test("GET /api/health returns ok", async () => {
  const res = await request(app).get("/api/health");
  assert.equal(res.status, 200);
  assert.deepEqual(res.body, { status: "ok" });
});

test("unknown route returns a JSON 404", async () => {
  const res = await request(app).get("/api/does-not-exist");
  assert.equal(res.status, 404);
  assert.equal(res.body.error, "Not found.");
});

test("seed creates 5 tasks for Group 1 and 1 for Group 2", async () => {
  const rows = await q("SELECT group_id, COUNT(*) AS n FROM task GROUP BY group_id ORDER BY group_id");
  assert.deepEqual(rows.map((r) => [r.group_id, Number(r.n)]), [[1, 5], [2, 1]]);
});

test("withTransaction rolls back everything when the work throws", async () => {
  const [{ n: before }] = await q("SELECT COUNT(*) AS n FROM activity_event");
  await assert.rejects(
    withTransaction(async (conn) => {
      await conn.query("INSERT INTO activity_event (group_id, user_id, type) VALUES (1, 3, 'rollback_test')");
      throw new Error("simulated failure");
    }),
    /simulated failure/
  );
  const [{ n: afterCount }] = await q("SELECT COUNT(*) AS n FROM activity_event");
  assert.equal(Number(afterCount), Number(before));
});

test("todayInZone uses Manila time, not UTC", () => {
  // 17:30 UTC on Dec 1 is already 01:30 on Dec 2 in Manila.
  assert.equal(todayInZone("Asia/Manila", new Date("2026-12-01T17:30:00Z")), "2026-12-02");
  assert.equal(addDays("2026-12-02", -7), "2026-11-25");
  assert.equal(addDays("2026-12-31", 1), "2027-01-01");
});
