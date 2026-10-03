"use client";

import { useState } from "react";

export default function EQAssistant() {
  const [open,setOpen]=useState(false);
  const [question,setQuestion]=useState("");
  const [answer,setAnswer]=useState("");
  const [busy,setBusy]=useState(false);

  async function ask() {
    const q=question.trim();
    if(!q)return;
    setBusy(true); setAnswer("");
    try {
      const response=await fetch("/api/ai/assistant",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({question:q})});
      const data=await response.json();
      setAnswer(data.answer||data.error||"No se pudo obtener respuesta.");
    } catch { setAnswer("No se pudo conectar con el asistente."); }
    finally { setBusy(false); }
  }

  return <>
    <button onClick={()=>setOpen(true)} className="fixed bottom-5 right-5 z-[60] rounded-2xl bg-[#123f72] px-4 py-3 text-sm font-medium text-white shadow-lg hover:bg-[#0d355f]">✦ Preguntar a eQ</button>
    {open&&<div className="fixed inset-0 z-[70] flex justify-end bg-slate-950/20" onClick={()=>setOpen(false)}>
      <section onClick={e=>e.stopPropagation()} className="flex h-full w-full max-w-[470px] flex-col bg-white shadow-2xl">
        <div className="flex items-start justify-between border-b px-6 py-5">
          <div><p className="text-[10px] font-medium uppercase tracking-[.16em] text-[#1789bd]">GEMINI</p><h2 className="mt-1 text-xl font-semibold text-[#12365f]">Preguntar a eQ</h2><p className="mt-1 text-xs text-slate-400">Analiza tareas, clientes y seguimientos reales.</p></div>
          <button onClick={()=>setOpen(false)} className="rounded-lg px-3 py-2 text-slate-500 hover:bg-slate-100">Cerrar</button>
        </div>
        <div className="flex-1 overflow-y-auto p-6">
          {!answer?<div className="rounded-2xl bg-[#f5f8fb] p-5"><p className="text-sm font-medium text-[#12365f]">¿Qué querés saber?</p><div className="mt-3 space-y-2">{["¿Qué tengo que priorizar hoy?","¿Qué clientes están sin seguimiento?","¿Hay tareas atrasadas o sin movimiento?"].map(q=><button key={q} onClick={()=>setQuestion(q)} className="block w-full rounded-xl border bg-white px-3 py-2.5 text-left text-xs text-slate-600">{q}</button>)}</div></div>:<div className="whitespace-pre-wrap rounded-2xl bg-[#f5f8fb] p-5 text-sm leading-6 text-slate-700">{answer}</div>}
        </div>
        <div className="border-t p-5">
          <textarea value={question} onChange={e=>setQuestion(e.target.value)} onKeyDown={e=>{if(e.key==="Enter"&&!e.shiftKey){e.preventDefault();ask()}}} rows={3} placeholder="Ej.: ¿Qué clientes necesitan atención?" className="w-full resize-none rounded-xl border border-slate-200 p-3 text-sm outline-none focus:border-sky-400"/>
          <button disabled={busy||!question.trim()} onClick={ask} className="mt-3 w-full rounded-xl bg-[#123f72] px-4 py-3 text-sm font-medium text-white disabled:opacity-50">{busy?"Analizando operación...":"Preguntar a eQ"}</button>
          <p className="mt-2 text-center text-[10px] text-slate-400">eQ analiza y recomienda. No modifica datos sin aprobación.</p>
        </div>
      </section>
    </div>}
  </>;
}
