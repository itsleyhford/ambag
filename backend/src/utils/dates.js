// backend/src/utils/dates.js
// Date helpers that work with "YYYY-MM-DD" strings.
//
// Why: the server may run in UTC (Render), but AMBAG users are in the
// Philippines. "Today" must be today in APP_TIMEZONE (Asia/Manila), otherwise
// an excuse filed at 1:00 AM Manila time would be judged by yesterday's date.

/** Today's date in the given IANA time zone, as "YYYY-MM-DD". */
export function todayInZone(timeZone, now = new Date()) {
  // The "en-CA" locale formats dates as YYYY-MM-DD.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
}

/** Adds (or subtracts, with a negative n) whole days to a "YYYY-MM-DD" string. */
export function addDays(dateStr, n) {
  const date = new Date(`${dateStr}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + n);
  return date.toISOString().slice(0, 10);
}
