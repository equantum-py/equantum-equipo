"use client";

import { useMemo, useState } from "react";
import { BarChart3, Bell, CheckCircle2, Gauge, Lightbulb, LogOut, Menu, MessageSquare, Plus, Radar, Sparkles, Users, X, Zap } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

type View = "dashboard"|"tasks"|"triage"|"radar"|"bi"|"improvements"|"chat"|"users";
const nav:{id:View;label:string;icon:any}[]=[
  {id:"dashboard",label:"Inicio",icon:Gauge},{id:"tasks",label:"Tareas",icon:CheckCircle2},
  {id:"triage",label:"Triage de Tareas",icon:Zap},{id:"radar",label:"Radar de Seguimiento",icon:Radar},
  {id:"bi",label:"Business Intelligence",icon:BarChart3},{id:"improvements",label:"Mejoras IA",icon:Sparkles},
  {id:"chat",label:"Chat interno",icon:MessageSquare},{id:"users",label:"Usuarios y accesos",icon:Users},
];
const tasks=[
 {title:"Corregir checkout del sitio del cliente",client:"Portal Verde",owner:"Derlis",priority:"Crítica",hours:2,status:"En curso"},
 {title:"Preparar propuesta comercial",client:"Prospecto ecommerce",owner:"Derlis",priority:"Alta",hours:1.5,status:"Pendiente"},
 {title:"Actualizar catálogo Shopify",client:"Ultramaison",owner:"Equipo",priority:"Media",hours:2,status:"Pendiente"},
 {title:"Revisar contenidos web",client:"Corpicia",owner:"Equipo",priority:"Media",hours:1,status:"Pendiente"},
 {title:"Seguimiento de entrega",client:"Marmolería Pietra",owner:"Derlis",priority:"Baja",hours:1.5,status:"Pendiente"},
];
const cards=[["Tareas activas","5","Carga vigente"],["Críticas","1","Atención inmediata"],["Altas","1","Resolver después de críticas"],["Seguimientos","3","Radar requiere atención"],["Completadas hoy","1","Ejecución diaria"]];

export default function DashboardPage(){
 const router=useRouter(); const [view,setView]=useState<View>("dashboard"); const [menu,setMenu]=useState(false);
 const [messages,setMessages]=useState(["Daniel: Revisé el avance de Portal Verde.","Derlis: Perfecto, seguimos con checkout."]);
 const title=nav.find(n=>n.id===view)?.label||"Inicio";
 const today=useMemo(()=>new Date().toLocaleDateString("es-PY",{weekday:"long",day:"numeric",month:"long"}),[]);
 async function logout(){const s=createClient();await s.auth.signOut();router.replace("/login");router.refresh();}
 function go(v:View){setView(v);setMenu(false)}
 return <main className="min-h-screen bg-[#f2f6fb] text-[#14243b]">
  <aside className={`fixed inset-y-0 left-0 z-50 flex w-[258px] flex-col bg-gradient-to-b from-[#061f48] to-[#08295c] p-3 text-white transition-transform lg:translate-x-0 ${menu?"translate-x-0":"-translate-x-full"}`}>
   <div className="flex items-center gap-3 border-b border-white/10 px-2 py-4"><span className="grid h-11 w-11 place-items-center rounded-xl bg-white font-black text-[#08295c]">eQ</span><div><b className="text-sm">Gestión Inteligente</b><span className="block text-[10px] text-blue-200/70">equipo.equantum.com.py</span></div><button onClick={()=>setMenu(false)} className="ml-auto lg:hidden"><X size={18}/></button></div>
   <nav className="mt-3 flex-1 space-y-1 overflow-y-auto">{nav.map(n=><button key={n.id} onClick={()=>go(n.id)} className={`flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left text-sm font-bold ${view===n.id?"bg-[#1ca5e9]/20 text-white":"text-blue-50/80 hover:bg-white/5"}`}><span className="grid h-7 w-7 place-items-center rounded-lg bg-white/10"><n.icon size={15}/></span>{n.label}</button>)}</nav>
   <div className="rounded-xl bg-white/10 p-3"><b className="block text-xs">Derlis Aguilera</b><span className="text-[11px] text-blue-100/60">Administrador global</span></div>
   <button onClick={logout} className="mt-2 flex items-center justify-center gap-2 rounded-xl border border-white/20 py-2.5 text-sm font-bold"><LogOut size={15}/>Cerrar sesión</button>
  </aside>
  {menu&&<button onClick={()=>setMenu(false)} className="fixed inset-0 z-40 bg-black/40 lg:hidden"/>}
  <div className="lg:pl-[258px]">
   <header className="sticky top-0 z-30 flex h-[72px] items-center justify-between border-b border-[#dfe7f1] bg-white px-4 lg:px-6"><div className="flex items-center gap-3"><button onClick={()=>setMenu(true)} className="rounded-lg bg-slate-100 p-2 lg:hidden"><Menu size={19}/></button><div><h2 className="font-black text-[#08295c]">{title}</h2><small className="text-slate-400">{today}</small></div></div><div className="flex items-center gap-2"><span className="hidden rounded-full bg-[#eef7ff] px-3 py-2 text-[11px] font-black text-[#08295c] sm:inline">● Sistema operativo</span><span className="grid h-9 w-9 place-items-center rounded-full bg-gradient-to-br from-[#0ba9e8] to-[#08295c] text-xs font-black text-white">DA</span></div></header>
   <div className="mx-auto max-w-[1440px] p-4 lg:p-6">
    {view==="dashboard"&&<Dashboard cards={cards}/>}
    {view==="tasks"&&<Tasks/>}
    {view==="triage"&&<Triage/>}
    {view==="radar"&&<RadarView/>}
    {view==="bi"&&<BI/>}
    {view==="improvements"&&<Improvements/>}
    {view==="chat"&&<Chat messages={messages} setMessages={setMessages}/>}
    {view==="users"&&<UsersView/>}
   </div>
  </div>
 </main>
}
function Head({eyebrow,title,sub,action}:{eyebrow:string,title:string,sub:string,action?:string}){return <div className="mb-5 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><div><p className="text-[11px] font-black uppercase tracking-[.15em] text-[#0ba9e8]">{eyebrow}</p><h1 className="mt-1 text-2xl font-black text-[#08295c] lg:text-3xl">{title}</h1><p className="mt-1 text-sm text-slate-500">{sub}</p></div>{action&&<button className="w-fit rounded-xl bg-[#08295c] px-4 py-3 text-sm font-black text-white"><Plus className="mr-1 inline" size={15}/>{action}</button>}</div>}
function Dashboard({cards}:{cards:string[][]}){return <><Head eyebrow="Centro de control" title="Buenos días, Derlis" sub="Tu jornada, prioridades y lectura empresarial en un solo lugar." action="Nueva tarea"/>
 <section className="rounded-[20px] bg-gradient-to-r from-[#083873] to-[#0d5799] p-5 text-white"><p className="text-[11px] font-black uppercase tracking-[.15em] text-cyan-200">Inteligencia del día</p><h2 className="mt-2 text-xl font-black">Resumen ejecutivo de la jornada</h2><div className="mt-4 grid gap-3 md:grid-cols-3">{[["HECHOS","Hay 5 tareas activas, 1 crítica y 1 completada hoy."],["LECTURA","La prioridad actual es corregir checkout porque afecta una operación activa."],["SUGERENCIA","La demanda visible se concentra en soporte. Seguir acumulando datos permitirá detectar tendencia."]].map(x=><div key={x[0]} className="rounded-xl border border-white/15 bg-white/10 p-4"><b className="text-[11px] text-cyan-100">{x[0]}</b><p className="mt-2 text-sm leading-5">{x[1]}</p></div>)}</div></section>
 <div className="mt-4 grid grid-cols-2 gap-3 lg:grid-cols-5">{cards.map(c=><div key={c[0]} className="rounded-2xl border border-[#dfe7f1] bg-white p-4"><span className="text-[11px] font-bold text-slate-500">{c[0]}</span><b className="mt-2 block text-3xl text-[#08295c]">{c[1]}</b><small className="text-slate-400">{c[2]}</small></div>)}</div>
 <div className="mt-4 grid gap-4 xl:grid-cols-[1.2fr_.8fr]"><Panel title="Prioridades de hoy · Triage">{tasks.slice(0,4).map((t,i)=><Row key={t.title} n={i+1} title={t.title} sub={t.client} tag={t.priority}/>)}</Panel><Panel title="Señales que requieren atención">{["1 tarea crítica afecta operación activa","3 seguimientos necesitan continuidad","2 tareas llevan más de 3 días sin movimiento"].map((x,i)=><div key={x} className="mb-2 rounded-xl bg-[#f6f9fc] p-3 text-sm"><b className="mr-2 text-[#0ba9e8]">0{i+1}</b>{x}</div>)}</Panel></div></>}
function Tasks(){return <><Head eyebrow="Operación" title="Tareas" sub="Trabajo activo del equipo, responsables y estado." action="Nueva tarea"/><Panel title="Todas las tareas">{tasks.map((t,i)=><Row key={t.title} n={i+1} title={t.title} sub={t.client+" · "+t.owner+" · "+t.hours+" h"} tag={t.status}/>)}</Panel></>}
function Triage(){return <><Head eyebrow="Prioridad inteligente" title="Triage de Tareas" sub="Orden sugerido según urgencia, impacto, espera y bloqueo."/><div className="grid gap-3">{tasks.map((t,i)=><div key={t.title} className="rounded-2xl border bg-white p-4"><div className="flex gap-4"><b className="text-2xl text-[#0ba9e8]">{String(i+1).padStart(2,"0")}</b><div className="flex-1"><h3 className="font-black text-[#08295c]">{t.title}</h3><p className="text-sm text-slate-500">{t.client} · {t.owner}</p></div><span className="h-fit rounded-full bg-orange-50 px-3 py-1 text-xs font-black text-orange-700">{t.priority}</span></div></div>)}</div></>}
function RadarView(){return <><Head eyebrow="Continuidad" title="Radar de Seguimiento" sub="Asuntos que no pueden quedar olvidados."/><section className="rounded-[20px] bg-[#08295c] p-5 text-white"><h2 className="text-xl font-black">3 asuntos requieren seguimiento</h2><div className="mt-4 grid gap-3 md:grid-cols-3">{[["VENCIDOS","1 seguimiento superó su fecha prevista."],["SILENCIOS","2 asuntos llevan varios días sin movimiento."],["PRÓXIMA ACCIÓN","Atender primero vencidos y silencios largos."]].map(x=><div key={x[0]} className="rounded-xl bg-white/10 p-4"><b className="text-xs text-cyan-200">{x[0]}</b><p className="mt-2 text-sm">{x[1]}</p></div>)}</div></section></>}
function BI(){return <><Head eyebrow="Business Intelligence" title="Lectura empresarial" sub="Qué nos está diciendo el trabajo acumulado."/><div className="grid gap-4 md:grid-cols-3">{[["DEMANDA","Soporte y ecommerce concentran la mayor carga."],["CAPACIDAD","8 horas estimadas permanecen abiertas."],["CLIENTES","Portal Verde concentra la prioridad operativa actual."]].map(x=><Panel key={x[0]} title={x[0]}><p className="text-sm leading-6 text-slate-600">{x[1]}</p></Panel>)}</div><div className="mt-4 grid gap-4 lg:grid-cols-2"><Panel title="Carga por tipo"><Bars/></Panel><Panel title="Lecturas"><p className="text-sm leading-7 text-slate-600">La base histórica irá mejorando a medida que el equipo registre tareas, tiempos, clientes y seguimientos de forma consistente.</p></Panel></div></>}
function Improvements(){return <><Head eyebrow="Calidad de información" title="Mejoras IA" sub="Sugerencias que siempre requieren aprobación humana."/><div className="grid gap-3 md:grid-cols-2">{["Mejorar títulos poco descriptivos","Detectar tareas múltiples","Crear seguimientos faltantes","Recuperar silencios operativos"].map((x,i)=><Panel key={x} title={x}><p className="text-sm text-slate-500">Sugerencia #{i+1}. Revisar y aplicar solo si aporta claridad al equipo.</p><div className="mt-4 flex gap-2"><button className="rounded-lg bg-[#08295c] px-3 py-2 text-xs font-bold text-white">Aceptar</button><button className="rounded-lg border px-3 py-2 text-xs font-bold">Rechazar</button></div></Panel>)}</div></>}
function Chat({messages,setMessages}:{messages:string[],setMessages:(x:string[])=>void}){const [v,setV]=useState("");return <><Head eyebrow="Equipo" title="Chat interno" sub="Conversaciones operativas en un solo lugar."/><Panel title="# general"><div className="min-h-[320px] space-y-2">{messages.map(m=><div key={m} className="rounded-xl bg-[#f4f7fb] p-3 text-sm">{m}</div>)}</div><div className="mt-3 flex gap-2"><input value={v} onChange={e=>setV(e.target.value)} className="min-w-0 flex-1 rounded-xl border px-3 py-2" placeholder="Escribir mensaje..."/><button onClick={()=>{if(v.trim()){setMessages([...messages,"Derlis: "+v]);setV("")}}} className="rounded-xl bg-[#08295c] px-4 text-sm font-bold text-white">Enviar</button></div></Panel></>}
function UsersView(){return <><Head eyebrow="Gerencia" title="Usuarios y accesos" sub="Control de miembros, roles y permisos." action="Nuevo usuario"/><div className="grid gap-3 md:grid-cols-3">{[["Derlis Aguilera","Administrador global"],["Daniel Sosa","Operaciones"],["Equipo eQuantum","Colaborador"]].map(x=><Panel key={x[0]} title={x[0]}><p className="text-sm text-slate-500">{x[1]}</p><span className="mt-3 inline-block rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700">Activo</span></Panel>)}</div></>}
function Panel({title,children}:{title:string,children:React.ReactNode}){return <section className="rounded-2xl border border-[#dfe7f1] bg-white p-4 shadow-[0_5px_20px_rgba(20,50,85,.04)]"><h2 className="mb-3 font-black text-[#08295c]">{title}</h2>{children}</section>}
function Row({n,title,sub,tag}:{n:number,title:string,sub:string,tag:string}){return <div className="flex items-center gap-3 border-b border-slate-100 py-3 last:border-0"><span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-[#eef7ff] text-xs font-black text-[#0b76b7]">{n}</span><div className="min-w-0 flex-1"><p className="truncate text-sm font-black">{title}</p><p className="truncate text-xs text-slate-400">{sub}</p></div><span className="hidden rounded-full bg-[#eef7ff] px-2 py-1 text-[10px] font-black text-[#08295c] sm:block">{tag}</span></div>}
function Bars(){return <div className="flex h-44 items-end gap-4">{[75,55,42,30,22].map((h,i)=><div key={i} className="flex flex-1 flex-col items-center justify-end gap-2"><b className="text-xs text-[#08295c]">{h}</b><div className="w-full max-w-12 rounded-t-lg bg-[#0ba9e8]" style={{height:h+"%"}}/><small className="text-[9px] text-slate-400">{["Soporte","Web","Shopify","SEO","CRM"][i]}</small></div>)}</div>}
