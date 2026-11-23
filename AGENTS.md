# AGENTS.md — Project: AMBAG

AMBAG is a web app that records each group member's real contribution in a
group project so teachers can grade fairly. "Ambag" means "contribution."
I am a solo student developer. Explain your code clearly so I can defend it
to the panel.

## Tech stack (do not change without asking me)

- Frontend: React + Vite + JavaScript, Tailwind CSS v4 (colors defined in src/index.css @theme)
- Backend: Node.js + Express
- Database: MySQL 8.0 locally (development, managed with MySQL Workbench);
  TiDB Cloud Starter in production (MySQL-compatible, SSL required).
  Do not use triggers or stored procedures; they must work on both.
- AI: Gemini API (paid tier), called ONLY from the backend
- Hosting: Vercel (frontend), Render (backend), TiDB Cloud Starter (database)

## Users and roles

- Teacher: creates classes, projects and milestones; sees the dashboard,
  peer ratings, fairness reports and flags.
- Student: joins a class with a code; claims tasks, uploads work receipts,
  rates teammates, uses the AI check-in.
- Admin: manages accounts.

## Business rules (always enforce on the BACKEND, not only the UI)

- Every task has exactly one primary owner; co-owner shares add up to 100%.
- A task cannot be marked Done without a work receipt.
- The activity log is append-only: never edit or delete entries. Corrections
  are new linked entries.
- Peer ratings are visible ONLY to the teacher; students never see who rated them.
- Students can only see their own groups; teachers can only see their own classes.
- The AI only suggests and summarizes from stored data and lists its sources.
  It NEVER sets or changes a grade. Only the teacher decides.
- Invisible work and AI check-in answers count only after a teammate
  confirms them or the teacher approves them.
  - TiDB does not support triggers or stored procedures; put all rules in the Express services layer.

## Security rules (required in every piece of code)

- Use parameterized queries / prepared statements (mysql2 `?` placeholders).
  Never build SQL with string concatenation.
- Hash passwords with bcrypt. Never store or log plain-text passwords.
- Use JWT or secure sessions; check the user's role AND ownership on EVERY
  protected route (authorization, not just login).
- Validate and sanitize all input on the server (express-validator or zod).
- Keep secrets (DB password, JWT secret, Gemini API key) in environment
  variables. Never put them in frontend code and never commit them to Git.
  `.env` files must stay in `.gitignore`.
- Use helmet, CORS limited to my frontend URL, and rate limiting on login
  and AI routes.
- Validate file uploads for work receipts (type and size limits) on the server.
- Return generic error messages to users; log details only on the server.
- Prevent XSS: never use dangerouslySetInnerHTML with user content.
- Point out any security risk you notice in my code, even if I didn't ask.

## UI/UX rules

- If the ui-ux-pro-max, frontend-design, taste or impeccable skills are
  installed, use them when designing or building any page or component.
- Keep one consistent design. Use ONLY these colors (defined in
  frontend/src/index.css @theme; do not invent new colors):
  - cream (#FFF8EC) page background; surface (#FFFFFF) cards and modals
  - sloth brown (#6B4F3A) headings; ink (#3B2A1E) body text
  - forest (#2F5D3A) primary buttons and nav; leaf green (#3E7C4B) hover,
    links and icons; mint (#E4F1E6) selected/success backgrounds
  - gold (#F1D9A8) soft highlight areas (pending, needs confirmation);
    amber (#F2A93B) small badges and flags only, as a background with ink
    text, never as a text color
  - danger (#B3261E) error messages
- Mobile-first and responsive; most students use phones.
- Accessible: readable contrast, labels on every form field, keyboard
  navigation, clear focus states.
- Always handle loading, empty and error states with friendly messages.
- Show offline status clearly when the connection drops (offline queue).

## How to work with me

- Before writing big features, give a short plan and ask if anything is unclear.
- Build in small steps: one feature or page at a time.
- Use clear file and folder names and add short comments on tricky logic.
- After each change, tell me which files you created or changed and how to
  test them.
- Do NOT run `git commit` or `git push`. I review and commit the changes myself.
- After every update, end your reply with the git commands for me to run
  myself, in one copy-paste code block, in this format:
  ```
  git status
  git add .
  git commit -m "clear message describing the change"
  ```
  Add `git push` only once a remote is set up. Never run these yourself.
- Priority order: Phase 1 (task board, contribution log, peer ratings,
  fairness report), then Phase 2 (AI check-in and summaries).

## Folder structure (follow this; ask before changing it)

```
ambag/
├── backend/
│   ├── src/
│   │   ├── config/        # db connection, env loading
│   │   ├── routes/        # Express routes per feature
│   │   ├── controllers/   # request/response handling
│   │   ├── services/      # business rules and logic
│   │   ├── models/        # SQL queries per table
│   │   ├── middleware/    # auth, roles, validation, errors
│   │   └── utils/
│   ├── database/
│   │   └── schema.sql     # all CREATE TABLE statements
│   ├── .env.example
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── src/
│   │   ├── pages/         # one file per page
│   │   ├── components/    # reusable UI pieces
│   │   ├── services/      # API calls to the backend
│   │   ├── context/       # auth/user state
│   │   ├── hooks/
│   │   └── styles/
│   ├── .env.example
│   └── package.json
├── AGENTS.md
├── CLAUDE.md
└── README.md
```

## Code rules

- Write complete files. Never leave placeholders like "..." or "rest of code here".
- When adding a package, install it so package.json is updated, and tell me
  the npm install command you used.
- Keep .env.example updated with every environment variable (no real secrets).
- When a feature touches the database, update backend/database/schema.sql.
- Keep the README updated with setup and run steps.
- Check that imports, file paths and variable names match across files.
  If you are unsure about something, say so instead of guessing.
