// frontend/src/App.jsx
// Temporary home page: shows the AMBAG color theme so it can be checked
// on a phone and a laptop. It will be replaced by real pages (login, task board).

const swatches = [
  { name: "cream", hex: "#FFF8EC", use: "Page background", className: "bg-cream text-ink border border-sloth/20" },
  { name: "surface", hex: "#FFFFFF", use: "Cards and modals", className: "bg-surface text-ink border border-sloth/20" },
  { name: "sloth", hex: "#6B4F3A", use: "Headings", className: "bg-sloth text-white" },
  { name: "ink", hex: "#3B2A1E", use: "Body text", className: "bg-ink text-white" },
  { name: "forest", hex: "#2F5D3A", use: "Primary buttons, nav", className: "bg-forest text-white" },
  { name: "leaf", hex: "#3E7C4B", use: "Hover, links, icons", className: "bg-leaf text-white" },
  { name: "mint", hex: "#E4F1E6", use: "Selected / success", className: "bg-mint text-forest" },
  { name: "gold", hex: "#F1D9A8", use: "Pending / needs confirmation", className: "bg-gold text-ink" },
  { name: "amber", hex: "#F2A93B", use: "Small badges and flags", className: "bg-amber text-ink" },
  { name: "danger", hex: "#B3261E", use: "Errors", className: "bg-danger text-white" },
];

function App() {
  return (
    <main className="mx-auto max-w-3xl px-4 py-8 sm:py-12">
      <header className="mb-8">
        <p className="text-sm font-semibold uppercase tracking-wide text-leaf">Ambag</p>
        <h1 className="mt-1 text-3xl font-bold sm:text-4xl">Every contribution, counted fairly.</h1>
        <p className="mt-3 max-w-prose">
          This is the AMBAG color theme. Each color has one job so the app stays calm and easy to read.
        </p>
      </header>

      {/* Example components using the theme */}
      <section aria-labelledby="examples-heading" className="mb-10 rounded-2xl bg-surface p-5 shadow-sm">
        <h2 id="examples-heading" className="mb-4 text-xl font-semibold">How the colors are used</h2>
        <div className="flex flex-wrap items-center gap-3">
          <button type="button" className="rounded-lg bg-forest px-4 py-2.5 font-semibold text-white hover:bg-leaf">
            Claim task
          </button>
          <a href="#examples-heading" className="font-semibold text-leaf underline underline-offset-4 hover:text-forest">
            View activity log
          </a>
          <span className="rounded-full bg-amber px-3 py-1 text-sm font-semibold text-ink">2 flags</span>
          <span className="rounded-full bg-mint px-3 py-1 text-sm font-semibold text-forest">Done</span>
        </div>
        <div className="mt-4 rounded-lg border border-amber/60 bg-gold p-3 text-ink">
          Waiting for a teammate to confirm this invisible work.
        </div>
        <p className="mt-3 text-sm font-semibold text-danger" role="alert">
          Something went wrong. Please try again.
        </p>
      </section>

      <section aria-labelledby="palette-heading">
        <h2 id="palette-heading" className="mb-4 text-xl font-semibold">Palette</h2>
        <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {swatches.map((s) => (
            <li key={s.name} className={`rounded-xl p-4 ${s.className}`}>
              <p className="font-semibold">{s.name}</p>
              <p className="text-sm">{s.hex} · {s.use}</p>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}

export default App;
