const modules = ["Clientes","Usuarios","Proyectos","Documentos","Informes","Configuración"];

export default function AdminPage() {
  return (
    <main className="min-h-screen bg-brand-soft px-5 py-8">
      <div className="mx-auto max-w-6xl">
        <p className="text-xs font-black uppercase tracking-[.18em] text-brand/55">Administración</p>
        <h1 className="mt-2 text-3xl font-black tracking-tight text-brand">Panel administrador</h1>
        <p className="mt-2 text-sm text-slate-500">Estructura inicial para gestionar el portal interno.</p>

        <div className="mt-7 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {modules.map((module) => (
            <article key={module} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft">
              <p className="text-lg font-black text-brand">{module}</p>
              <p className="mt-2 text-sm leading-6 text-slate-500">Módulo preparado para la siguiente fase.</p>
            </article>
          ))}
        </div>
      </div>
    </main>
  );
}
