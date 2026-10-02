"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { AlertCircle, ArrowRight, Loader2, LockKeyhole, Mail } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const supabase = createClient();
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });

      if (signInError) {
        setError("Correo o contraseña incorrectos.");
        return;
      }

      router.replace("/dashboard");
      router.refresh();
    } catch {
      setError("No pudimos iniciar sesión. Intentá nuevamente.");
    } finally {
      setLoading(false);
    }
  }

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

          <form className="mt-7 space-y-4" onSubmit={handleSubmit}>
            <label className="block">
              <span className="mb-2 block text-sm font-bold text-slate-700">Correo</span>
              <span className="flex items-center gap-3 rounded-xl border border-slate-200 px-4 py-3 focus-within:border-brand/50 focus-within:ring-2 focus-within:ring-brand/10">
                <Mail className="h-4 w-4 text-slate-400" />
                <input
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder="nombre@equantum.com.py"
                  className="w-full border-0 bg-transparent outline-none placeholder:text-slate-400"
                />
              </span>
            </label>

            <label className="block">
              <span className="mb-2 block text-sm font-bold text-slate-700">Contraseña</span>
              <span className="flex items-center gap-3 rounded-xl border border-slate-200 px-4 py-3 focus-within:border-brand/50 focus-within:ring-2 focus-within:ring-brand/10">
                <LockKeyhole className="h-4 w-4 text-slate-400" />
                <input
                  type="password"
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  placeholder="••••••••"
                  className="w-full border-0 bg-transparent outline-none placeholder:text-slate-400"
                />
              </span>
            </label>

            {error && (
              <div className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm font-semibold text-red-700">
                <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="mt-2 flex w-full items-center justify-center gap-2 rounded-xl bg-brand px-5 py-3.5 text-sm font-black text-white transition hover:bg-brand-dark disabled:cursor-not-allowed disabled:opacity-60"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" /> Ingresando...
                </>
              ) : (
                <>
                  Entrar <ArrowRight className="h-4 w-4" />
                </>
              )}
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-slate-400">
            Acceso protegido con Supabase Auth.
          </p>
        </section>
      </div>
    </main>
  );
}
