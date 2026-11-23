// backend/tests/helpers/env.js
// Imported FIRST by every test file. Points the app at a separate test
// database so tests never touch your real `ambag` data.
process.env.NODE_ENV = "test";
process.env.DB_NAME = process.env.TEST_DB_NAME || "ambag_test";
process.env.JWT_SECRET = process.env.JWT_SECRET || "test-only-secret-not-for-production-use";
