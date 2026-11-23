// backend/src/utils/httpError.js
// An error with an HTTP status and a message that is SAFE to show the user.
// Services throw these for rule violations (403, 404, 409...). Anything that
// is not an HttpError is treated as unexpected and hidden behind a generic
// message by the error handler.
export class HttpError extends Error {
  constructor(status, publicMessage, fields) {
    super(publicMessage);
    this.name = "HttpError";
    this.status = status;
    this.publicMessage = publicMessage;
    // Optional per-field messages, e.g. { startDate: "..." }, for forms.
    this.fields = fields;
  }
}
