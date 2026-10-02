import { LockKeyhole, Mail, ArrowRight } from "lucide-react";

export default function LoginPage() {
  return (
    <main className="min-h-screen bg-brand-dark px-5 py-8 text-white">
      <div className="mx-auto grid min-h-[calc(100vh-4rem)] max-w-6xl items-center gap-10 lg:grid-cols-[1.05fr_.95fr]">
        <section className="hidden lg:block">
          <span className="inline-flex rounded-full border border-white/15 bg-white/5 px-3 py-1 text-xs font-bold uppercase tracking-[.2em] text-white/70">
            eQuantum Equipo
          </span>
          <h1 className="mt-6 max-w-xl text-5xl font-black leading-[.98] tracking-tight">
            Todo el trabajo del equipo, en un solo lugar.
          </h1>
          <p className="mt-5 max-w-lg text-lg leading-8 text-white/65">
            Proyectos, clientes, documentos, informes y seguimiento interno de eQuantum.
          </p>
        </section>

        <section className="rounded-[2rem] bg-white p-6 text-slate-900 shadow-2xl shadow-black/20 sm:p-8">
          <div className="flex items-center gap-3">
            <span className="grid h-11 w-11 place-items-center rounded-full bg-brand text-sm font-black text-white">eQ</span>
            <div>
              <p className="font-black text-brand">eQuantum</p>
              <p className="text-xs text-slate-500">Portal interno</p>
            </div>
          </div>

          <div className="mt-8">
            <h2 className="text-2xl font-black tracking-tight">Iniciar sesión</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Acceso exclusivo para el equipo de eQuantum.
            </p>
          </div>

          <form className="mt-7 space-y-4">
            <label className="block">
              <span className="mb-2 block text-sm font-bold text-slate-700">Correo</span>
              <span className="flex items-center gap-3 rounded-xl border border-slate-200 px-4 py-3">
                <Mail className="h-4 w-4 text-slate-400" />
                <input type="email" placeholder="nombre@equantum.com.py" className="w-full border-0 bg-transparent outline-none placeholder:text-slate-400" />
              </span>
            </label>

            <label className="block">
              <span className="mb-2 block text-sm font-bold text-slate-700">Contraseña</span>
              <span className="flex items-center gap-3 rounded-xl border border-slate-200 px-4 py-3">
                <LockKeyhole className="h-4 w-4 text-slate-400" />
                <input type="password" placeholder="••••••••" className="w-full border-0 bg-transparent outline-none placeholder:text-slate-400" />
              </span>
            </label>

            <button type="button" className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-5 py-3.5 text-sm font-black text-white">
              Entrar <ArrowRight className="h-4 w-4" />
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-slate-400">
            La autenticación se conectará con Supabase en la siguiente etapa.
          </p>
        </section>
      </div>
    </main>
  );
}
