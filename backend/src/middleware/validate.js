// backend/src/middleware/validate.js
// Validates and cleans request input with a zod schema BEFORE it reaches the
// controller. Invalid input never touches the services or the database.
//
// Usage: router.post("/", validate(createTaskSchema), controller.create)
//        router.get("/:taskId", validate(taskIdParams, "params"), ...)
export function validate(schema, source = "body") {
  return (req, res, next) => {
    // parse() throws a ZodError on bad input; the error handler turns it
    // into a 400 response with per-field messages.
    const parsed = schema.parse(req[source] ?? {});
    if (source === "query") {
      // Express 5 makes req.query read-only, so store cleaned query values here.
      req.validatedQuery = parsed;
    } else {
      req[source] = parsed;
    }
    next();
  };
}
