import { BriefcaseBusiness, FileText, FolderKanban, Users, ArrowUpRight } from "lucide-react";

const cards = [
  { label: "Proyectos activos", value: "8", icon: FolderKanban },
  { label: "Clientes", value: "12", icon: Users },
  { label: "Documentos", value: "24", icon: FileText },
  { label: "Pendientes", value: "6", icon: BriefcaseBusiness },
];

export default function DashboardPage() {
  return (
    <main className="min-h-screen bg-brand-soft">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-10 w-10 place-items-center rounded-full bg-brand text-sm font-black text-white">eQ</span>
            <div>
              <p className="font-black text-brand">eQuantum Equipo</p>
              <p className="text-xs text-slate-500">Panel interno</p>
            </div>
          </div>
          <span className="text-sm font-bold text-slate-500">Administrador</span>
        </div>
      </header>

      <section className="mx-auto max-w-7xl px-5 py-8">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[.18em] text-brand/55">Resumen</p>
            <h1 className="mt-2 text-3xl font-black tracking-tight text-brand">Panel del equipo</h1>
            <p className="mt-2 text-sm text-slate-500">Una vista rápida del trabajo operativo de eQuantum.</p>
          </div>
          <button className="inline-flex items-center gap-2 rounded-xl bg-brand px-4 py-3 text-sm font-black text-white">
            Nuevo proyecto <ArrowUpRight className="h-4 w-4" />
          </button>
        </div>

        <div className="mt-7 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {cards.map(({ label, value, icon: Icon }) => (
            <article key={label} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft">
              <div className="flex items-center justify-between">
                <span className="grid h-10 w-10 place-items-center rounded-xl bg-brand-soft text-brand"><Icon className="h-5 w-5" /></span>
                <span className="text-3xl font-black text-brand">{value}</span>
              </div>
              <p className="mt-5 text-sm font-bold text-slate-700">{label}</p>
            </article>
          ))}
        </div>

        <div className="mt-7 grid gap-5 lg:grid-cols-[1.3fr_.7fr]">
          <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft">
            <div className="flex items-center justify-between">
              <h2 className="font-black text-brand">Proyectos recientes</h2>
              <span className="text-xs font-bold text-slate-400">Vista inicial</span>
            </div>
            <div className="mt-5 divide-y divide-slate-100">
              {["Portal Verde","Corpicia","Marmolería Pietra","Ultramaison"].map((name, i) => (
                <div key={name} className="flex items-center justify-between py-4">
                  <div>
                    <p className="font-bold text-slate-800">{name}</p>
                    <p className="mt-1 text-xs text-slate-400">Proyecto #{String(i + 1).padStart(3, "0")}</p>
                  </div>
                  <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700">Activo</span>
                </div>
              ))}
            </div>
          </section>

          <aside className="rounded-2xl bg-brand p-5 text-white shadow-soft">
            <p className="text-xs font-black uppercase tracking-[.18em] text-white/55">Siguiente etapa</p>
            <h2 className="mt-3 text-2xl font-black">Conectar Supabase</h2>
            <p className="mt-3 text-sm leading-6 text-white/70">
              Usuarios, permisos, clientes y proyectos quedarán vinculados a una base real.
            </p>
          </aside>
        </div>
      </section>
    </main>
  );
}
