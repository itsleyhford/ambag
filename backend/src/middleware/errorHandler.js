// backend/src/middleware/errorHandler.js
// The last middleware: turns any error into a JSON response.
// Users only ever see safe, generic messages. Full details are logged on the
// server so the developer can debug without leaking internals (SQL, stack
// traces, table names) to the browser.
import { ZodError } from "zod";
import { HttpError } from "../utils/httpError.js";

export function notFoundHandler(req, res) {
  res.status(404).json({ error: "Not found." });
}

// Express recognizes an error handler by its 4 parameters, so `next` must stay.
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) {
    const body = { error: err.publicMessage };
    if (err.fields) body.fields = err.fields;
    return res.status(err.status).json(body);
  }

  if (err instanceof ZodError) {
    // Keep the first message for each field, e.g. { email: "Enter a valid email." }
    const fields = {};
    for (const issue of err.issues) {
      const key = issue.path.join(".") || "form";
      if (!fields[key]) fields[key] = issue.message;
    }
    return res.status(400).json({ error: "Please check the highlighted fields.", fields });
  }

  // Malformed JSON body sent by the client.
  if (err.type === "entity.parse.failed") {
    return res.status(400).json({ error: "The request could not be read." });
  }
  if (err.type === "entity.too.large") {
    return res.status(413).json({ error: "The request is too large." });
  }

  console.error("[unexpected error]", req.method, req.originalUrl, err);
  return res.status(500).json({ error: "Something went wrong. Please try again." });
}
