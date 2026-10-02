"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { KeyRound, Loader2, ShieldCheck } from "lucide-react";

export default function MfaPage() {
  const router = useRouter();
  const [qr, setQr] = useState("");
  const [secret, setSecret] = useState("");
  const [factorId, setFactorId] = useState("");
  const [code, setCode] = useState("");
  const [mode, setMode] = useState<"loading"|"enroll"|"challenge">("loading");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    (async () => {
      const s = createClient();
      const { data: { user } } = await s.auth.getUser();
      if (!user) return router.replace("/login");

      const { data: profile } = await s.from("profiles").select("active,is_master").eq("id", user.id).single();
      if (!profile?.active) { await s.auth.signOut(); return router.replace("/login"); }

      const { data: aal } = await s.auth.mfa.getAuthenticatorAssuranceLevel();
      if (profile.is_master && aal?.currentLevel === "aal2") return router.replace("/dashboard");

      const { data: factors } = await s.auth.mfa.listFactors();
      const verified = factors?.totp?.find(f => f.status === "verified");
      if (verified) { setFactorId(verified.id); setMode("challenge"); return; }

      if (!profile.is_master) return router.replace("/dashboard");

      const { data, error } = await s.auth.mfa.enroll({ factorType: "totp", friendlyName: "Gestión eQuantum" });
      if (error) { setError(error.message); setMode("enroll"); return; }
      setFactorId(data.id);
      setQr(data.totp.qr_code);
      setSecret(data.totp.secret);
      setMode("enroll");
    })();
  }, [router]);

  async function verify(e: FormEvent) {
    e.preventDefault();
    if (!factorId || code.trim().length !== 6) { setError("Ingresá el código de 6 dígitos."); return; }
    setBusy(true); setError("");
    const s = createClient();
    const { data: challenge, error: ce } = await s.auth.mfa.challenge({ factorId });
    if (ce) { setError(ce.message); setBusy(false); return; }
    const { error: ve } = await s.auth.mfa.verify({ factorId, challengeId: challenge.id, code: code.trim() });
    if (ve) { setError("Código incorrecto o vencido. Probá con el código actual."); setBusy(false); return; }
    router.replace("/dashboard"); router.refresh();
  }

  if (mode === "loading") return <main className="grid min-h-screen place-items-center bg-[#061f48] text-white">Verificando seguridad...</main>;

  return <main className="grid min-h-screen place-items-center bg-[#061f48] p-4">
    <section className="w-full max-w-md rounded-3xl bg-white p-7 text-slate-900 shadow-2xl">
      <span className="grid h-12 w-12 place-items-center rounded-xl bg-[#08295c] text-white"><ShieldCheck /></span>
      <h1 className="mt-5 text-2xl font-black text-[#08295c]">Verificación en dos pasos</h1>
      {mode === "enroll" ? <>
        <p className="mt-2 text-sm leading-6 text-slate-500">La cuenta maestra requiere 2FA. Escaneá este QR con Google Authenticator, Microsoft Authenticator, 1Password u otra app TOTP.</p>
        {qr && <div className="mx-auto mt-5 w-fit rounded-2xl border bg-white p-3" dangerouslySetInnerHTML={{__html: qr}} />}
        {secret && <div className="mt-4 rounded-xl bg-slate-50 p-3"><p className="text-xs font-bold text-slate-500">Clave manual</p><code className="mt-1 block break-all text-xs">{secret}</code></div>}
      </> : <p className="mt-2 text-sm leading-6 text-slate-500">Abrí tu aplicación Authenticator e ingresá el código actual para continuar.</p>}
      <form onSubmit={verify} className="mt-6 space-y-4">
        <label className="block text-sm font-bold">Código de seguridad
          <div className="mt-2 flex items-center gap-3 rounded-xl border px-4 py-3"><KeyRound className="h-4 w-4 text-slate-400"/><input inputMode="numeric" autoComplete="one-time-code" maxLength={6} required value={code} onChange={e=>setCode(e.target.value.replace(/\D/g,"").slice(0,6))} placeholder="000000" className="w-full bg-transparent text-lg font-black tracking-[.3em] outline-none"/></div>
        </label>
        {error && <p className="rounded-xl bg-red-50 p-3 text-sm font-bold text-red-700">{error}</p>}
        <button disabled={busy} className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#08295c] p-3.5 font-black text-white disabled:opacity-60">{busy?<Loader2 className="h-4 w-4 animate-spin"/>:<ShieldCheck className="h-4 w-4"/>}{busy?"Verificando...":"Verificar y entrar"}</button>
      </form>
      <p className="mt-5 text-center text-xs text-slate-400">Nunca compartas el código ni la clave de configuración.</p>
    </section>
  </main>;
}
