"use client";

import { useState } from "react";
import {
  BarChart3, Bell, BriefcaseBusiness, CheckCircle2, ChevronRight, ClipboardList,
  FileText, FolderKanban, LayoutDashboard, LogOut, Menu, Plus, Users, X
} from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

const nav = [
  { label: "Inicio", icon: LayoutDashboard, active: true },
  { label: "Proyectos", icon: FolderKanban },
  { label: "Clientes", icon: Users },
  { label: "Tareas", icon: CheckCircle2 },
  { label: "Documentos", icon: FileText },
  { label: "Informes", icon: BarChart3 },
  { label: "Equipo", icon: BriefcaseBusiness },
  { label: "Usuarios y accesos", icon: ClipboardList },
];

const metrics = [
  ["Proyectos activos", "4", "En ejecución"],
  ["Tareas pendientes", "6", "Por resolver"],
  ["Clientes activos", "5", "Con proyectos"],
  ["Documentos", "24", "Centralizados"],
];

const projects = [
  ["Portal Verde", "Ecommerce & Marketing", "Activo"],
  ["Corpicia", "Ecommerce", "Activo"],
  ["Marmolería Pietra", "Web & CRM", "Activo"],
  ["Ultramaison", "Shopify", "Activo"],
];

export default function DashboardPage() {
  const router = useRouter();
  const [open, setOpen] = useState(false);

  async function logout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.replace("/login");
    router.refresh();
  }

  return (
    <main className="min-h-screen bg-[#f3f6fb] text-slate-900">
      <aside className={`fixed inset-y-0 left-0 z-50 flex w-[260px] flex-col bg-[#071f4f] text-white transition-transform lg:translate-x-0 ${open ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="flex h-[76px] items-center gap-3 border-b border-white/10 px-5">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-white text-sm font-black text-[#071f4f]">eQ</span>
          <div><p className="font-black">eQuantum Equipo</p><p className="text-xs text-white/55">Gestión interna</p></div>
          <button onClick={() => setOpen(false)} className="ml-auto lg:hidden"><X className="h-5 w-5" /></button>
        </div>
        <nav className="flex-1 space-y-1 px-3 py-5">
          {nav.map(({label,icon:Icon,active}) => (
            <button key={label} className={`flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left text-sm font-bold transition ${active ? "bg-[#12477f] text-white" : "text-white/70 hover:bg-white/5 hover:text-white"}`}>
              <Icon className="h-[18px] w-[18px]" />{label}
            </button>
          ))}
        </nav>
        <div className="border-t border-white/10 p-3">
          <div className="mb-2 rounded-xl bg-white/10 px-3 py-3">
            <p className="text-sm font-black">Derlis Aguilera</p><p className="text-xs text-white/55">Administrador</p>
          </div>
          <button onClick={logout} className="flex w-full items-center justify-center gap-2 rounded-xl border border-white/20 px-3 py-2.5 text-sm font-bold hover:bg-white/10">
            <LogOut className="h-4 w-4" /> Cerrar sesión
          </button>
        </div>
      </aside>

      {open && <button aria-label="Cerrar menú" onClick={() => setOpen(false)} className="fixed inset-0 z-40 bg-slate-950/40 lg:hidden" />}

      <div className="lg:pl-[260px]">
        <header className="sticky top-0 z-30 flex h-[76px] items-center justify-between border-b border-slate-200 bg-white/95 px-4 backdrop-blur sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <button onClick={() => setOpen(true)} className="grid h-10 w-10 place-items-center rounded-xl border border-slate-200 lg:hidden"><Menu className="h-5 w-5" /></button>
            <div><p className="font-black text-[#071f4f]">Inicio</p><p className="text-xs text-slate-400">Centro operativo de eQuantum</p></div>
          </div>
          <div className="flex items-center gap-2">
            <button className="grid h-10 w-10 place-items-center rounded-full bg-slate-100 text-slate-500"><Bell className="h-4 w-4" /></button>
            <span className="grid h-10 w-10 place-items-center rounded-full bg-[#0879b9] text-sm font-black text-white">DA</span>
          </div>
        </header>

        <section className="mx-auto max-w-[1500px] px-4 py-6 sm:px-6 lg:px-8">
          <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-xs font-black uppercase tracking-[.18em] text-[#0788c9]">Centro de control</p>
              <h1 className="mt-2 text-3xl font-black tracking-tight text-[#071f4f] sm:text-4xl">Buenos días, Derlis</h1>
              <p className="mt-2 text-sm text-slate-500 sm:text-base">Proyectos, prioridades y operación del equipo en un solo lugar.</p>
            </div>
            <button className="inline-flex w-fit items-center gap-2 rounded-xl bg-[#071f4f] px-4 py-3 text-sm font-black text-white"><Plus className="h-4 w-4" /> Nuevo proyecto</button>
          </div>

          <section className="mt-6 rounded-[22px] bg-gradient-to-r from-[#0b3f7c] to-[#105a9d] p-5 text-white sm:p-6">
            <p className="text-xs font-black uppercase tracking-[.16em] text-cyan-200">Resumen operativo</p>
            <h2 className="mt-2 text-xl font-black sm:text-2xl">Lo importante de hoy</h2>
            <div className="mt-4 grid gap-3 md:grid-cols-3">
              <div className="rounded-xl border border-white/15 bg-white/10 p-4"><p className="text-xs font-bold text-white/60">PROYECTOS</p><p className="mt-2 text-sm leading-6">4 proyectos se encuentran actualmente en ejecución.</p></div>
              <div className="rounded-xl border border-white/15 bg-white/10 p-4"><p className="text-xs font-bold text-white/60">PRIORIDAD</p><p className="mt-2 text-sm leading-6">Revisar tareas pendientes y próximos entregables del equipo.</p></div>
              <div className="rounded-xl border border-white/15 bg-white/10 p-4"><p className="text-xs font-bold text-white/60">SEGUIMIENTO</p><p className="mt-2 text-sm leading-6">Centralizar avances, documentos y actividad de cada cliente.</p></div>
            </div>
          </section>

          <div className="mt-4 grid grid-cols-2 gap-3 xl:grid-cols-4">
            {metrics.map(([label,value,note]) => <article key={label} className="rounded-2xl border border-slate-200 bg-white p-4 sm:p-5"><p className="text-xs font-bold text-slate-500">{label}</p><p className="mt-2 text-3xl font-black text-[#071f4f]">{value}</p><p className="mt-1 text-xs text-slate-400">{note}</p></article>)}
          </div>

          <div className="mt-4 grid gap-4 xl:grid-cols-[1.35fr_.65fr]">
            <section className="rounded-2xl border border-slate-200 bg-white p-5">
              <div className="flex items-center justify-between"><div><h2 className="font-black text-[#071f4f]">Proyectos activos</h2><p className="mt-1 text-xs text-slate-400">Seguimiento general</p></div><button className="text-xs font-black text-[#0879b9]">Ver todos</button></div>
              <div className="mt-4 divide-y divide-slate-100">
                {projects.map(([name,type,status]) => <div key={name} className="flex items-center gap-3 py-4"><span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-[#f1f6fb] text-[#0b4c86]"><FolderKanban className="h-5 w-5" /></span><div className="min-w-0 flex-1"><p className="truncate text-sm font-black">{name}</p><p className="mt-1 text-xs text-slate-400">{type}</p></div><span className="hidden rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700 sm:block">{status}</span><ChevronRight className="h-4 w-4 text-slate-300" /></div>)}
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200 bg-white p-5">
              <h2 className="font-black text-[#071f4f]">Prioridades</h2><p className="mt-1 text-xs text-slate-400">Pendientes del equipo</p>
              <div className="mt-5 space-y-3">
                {["Revisar avances de proyectos","Actualizar documentación","Seguimiento a clientes"].map((x,i)=><div key={x} className="flex gap-3 rounded-xl bg-[#f6f8fb] p-3"><span className="grid h-7 w-7 shrink-0 place-items-center rounded-lg bg-white text-xs font-black text-[#0b4c86]">{i+1}</span><p className="text-sm font-bold leading-6">{x}</p></div>)}
              </div>
            </section>
          </div>
        </section>
      </div>
    </main>
  );
}
