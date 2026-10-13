"use client";

import { useMemo, useState } from "react";
import type { FormEvent, ReactNode } from "react";
import { Plus, Search } from "lucide-react";

export type ProspectNeed = {
  id?: string;
  category: string;
  service_description: string;
  catalog_item_id?: string | null;
};

export type ProspectRow = {
  id: string;
  commercial_entity_id: string;
  status: string;
  archived_at?: string | null;
  owner_id: string | null;
  referrer_id?: string | null;
  source: string | null;
  source_other?: string | null;
  created_at: string;
  last_contact_at?: string | null;
  customer_statement?: string | null;
  commercial_perception?: string | null;
  next_action?: string | null;
  next_review_at?: string | null;
  next_condition?: string | null;
  pause_reason?: string | null;
  pause_until?: string | null;
  closed_reason?: string | null;
  entity_name: string;
  entity_type: string;
  legal_name?: string | null;
  email: string | null;
  phone: string | null;
  tax_id?: string | null;
  needs: ProspectNeed[];
  events: { id: number; event_type: string; occurred_at: string; actor_id: string | null; details?: Record<string, unknown> }[];
};

type ProfileOption = { id: string; full_name: string; username?: string | null };
export type IdentityMatch = { id: string; display_name: string; entity_type: string; legal_name?: string | null; tax_id: string | null; email: string | null; phone: string | null };
export type ProspectDraft = {
  id?: string;
  commercial_entity_id?: string;
  entity_type: "company" | "person";
  display_name: string;
  legal_name: string;
  tax_id: string;
  email: string;
  phone: string;
  source: string;
  source_other: string;
  referrer_id: string;
  status: string;
  owner_id: string;
  last_contact_at: string;
  customer_statement: string;
  commercial_perception: string;
  next_action: string;
  next_review_at: string;
  next_condition: string;
  pause_reason: string;
  pause_until: string;
  closed_reason: string;
  needs: ProspectNeed[];
};

const emptyDraft = (): ProspectDraft => ({
  entity_type: "company", display_name: "", legal_name: "", tax_id: "", email: "", phone: "",
  source: "", source_other: "", referrer_id: "", status: "new", owner_id: "", last_contact_at: "",
  customer_statement: "", commercial_perception: "", next_action: "", next_review_at: "",
  next_condition: "", pause_reason: "", pause_until: "", closed_reason: "", needs: [{ category: "", service_description: "" }],
});

const statusLabels: Record<string, string> = {
  new: "Nuevo", contacted: "En contacto", qualifying: "Calificando", converted: "Convertido",
  paused: "Pausado", disqualified: "No califica / baja",
};

export default function ProspectsView({
  prospects, profiles, errorCode, loading, canManage, saving, onRetry, onSave, onConvert,
  onFindMatches,
}: {
  prospects: ProspectRow[];
  profiles: ProfileOption[];
  errorCode: string | null;
  loading: boolean;
  canManage: boolean;
  saving: boolean;
  onRetry: () => Promise<void>;
  onSave: (draft: ProspectDraft, selectedEntityId: string | null) => Promise<boolean>;
  onConvert: (prospect: ProspectRow, title: string) => Promise<boolean>;
  onFindMatches: (draft: ProspectDraft) => Promise<IdentityMatch[]>;
}) {
  const [query, setQuery] = useState("");
  const [draft, setDraft] = useState<ProspectDraft | null>(null);
  const [matches, setMatches] = useState<IdentityMatch[]>([]);
  const [selectedEntityId, setSelectedEntityId] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [convertTarget, setConvertTarget] = useState<ProspectRow | null>(null);
  const [convertTitle, setConvertTitle] = useState("");
  const [humanConfirmed, setHumanConfirmed] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const identitySelected = Boolean(selectedEntityId && selectedEntityId !== "new");

  const displayed = prospects.filter((p) => showHistory ? p.status === "converted" || p.status === "disqualified" || Boolean(p.archived_at) : p.status !== "converted" && p.status !== "disqualified" && !p.archived_at);
  const filtered = useMemo(() => {
    const q = query.trim().toLocaleLowerCase();
    if (!q) return displayed;
    return displayed.filter((p) => [p.entity_name, p.email, p.phone, p.source, p.status, p.next_action, ...p.needs.map((n) => n.service_description)]
      .filter(Boolean).some((value) => String(value).toLocaleLowerCase().includes(q)));
  }, [displayed, query]);

  function startEdit(p?: ProspectRow) {
    setFormError(null); setMatches([]); setSelectedEntityId(null);
    if (!p) { setDraft(emptyDraft()); return; }
    setDraft({ id: p.id, commercial_entity_id: p.commercial_entity_id, entity_type: p.entity_type === "person" ? "person" : "company",
      display_name: p.entity_name, legal_name: p.legal_name || "", tax_id: p.tax_id || "", email: p.email || "", phone: p.phone || "",
      source: p.source || "", source_other: p.source_other || "", referrer_id: p.referrer_id || "", status: p.status, owner_id: p.owner_id || "",
      last_contact_at: p.last_contact_at?.slice(0, 10) || "", customer_statement: p.customer_statement || "",
      commercial_perception: p.commercial_perception || "", next_action: p.next_action || "",
      next_review_at: p.next_review_at?.slice(0, 16) || "", next_condition: p.next_condition || "",
      pause_reason: p.pause_reason || "", pause_until: p.pause_until?.slice(0,16) || "", closed_reason: p.closed_reason || "", needs: p.needs.length ? p.needs.map((n) => ({ ...n })) : [{ category: "", service_description: "" }] });
  }

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault(); if (!draft) return;
    setFormError(null);
    if (!draft.display_name.trim()) { setFormError("Ingresá el nombre de la persona o empresa."); return; }
    if (!draft.source) { setFormError("Elegí el origen del Prospecto."); return; }
    if (draft.source === "other" && !draft.source_other.trim()) { setFormError("Describí el origen seleccionado como Otro."); return; }
    if (draft.status === "paused" && !draft.pause_reason.trim()) { setFormError("Indicá por qué se pausa este Prospecto."); return; }
    if (draft.status === "disqualified" && !draft.closed_reason.trim()) { setFormError("Indicá por qué el Prospecto no califica o se da de baja."); return; }
    if (draft.status !== "disqualified" && !draft.next_action.trim()) { setFormError("Definí el próximo paso para que el Prospecto tenga continuidad en Radar."); return; }
    if (draft.next_action.trim() && !draft.next_review_at && !draft.next_condition.trim()) { setFormError("Para proteger el próximo paso, agregá una fecha o una condición de revisión."); return; }
    if (!draft.id && !selectedEntityId) {
      let found: IdentityMatch[];
      try { found = await onFindMatches(draft); }
      catch (error) { setFormError(error instanceof Error ? error.message : "No pudimos revisar duplicados. No guardamos el Prospecto."); return; }
      if (found.length) { setMatches(found); setFormError("Encontramos posibles identidades existentes. Revisalas y elegí una para evitar duplicarla, o confirmá que no corresponde a ninguna."); return; }
    }
    const saved = await onSave(draft, selectedEntityId);
    if (saved) { setDraft(null); setMatches([]); setSelectedEntityId(null); }
  }

  return <>
    <div className="mb-5 flex flex-wrap items-end justify-between gap-3">
      <div><p className="text-[10px] font-medium uppercase tracking-[.16em] text-[#08B2ED]">Ventas</p>
        <h1 className="mt-1.5 text-[27px] font-semibold tracking-[-.035em] text-[#044474]">Prospectos</h1>
        <p className="mt-1.5 text-sm leading-6 text-slate-500">Bandeja de trabajo comercial: identidad, necesidad, responsable y continuidad.</p></div>
      {canManage && <button onClick={() => startEdit()} className="inline-flex items-center gap-2 rounded-xl bg-[#044474] px-4 py-2.5 text-sm font-bold text-white"><Plus size={16}/>Nuevo Prospecto</button>}
    </div>

    {!errorCode && !canManage && <div role="status" className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
      <b>Acceso de consulta.</b> Tu usuario todavía no tiene habilitado el permiso comercial para crear o editar Prospectos; por eso no aparece el botón. El administrador principal debe habilitar “Administrar Prospectos”.
    </div>}

    {errorCode ? <div role="alert" className="flex flex-col gap-3 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 sm:flex-row sm:items-center sm:justify-between">
      <span>{errorCode === "42501" ? "Permiso insuficiente" : errorCode.startsWith("PGRST") ? "Error de consulta" : "Error técnico"}: no se pudieron cargar Prospectos. Código: <b>{errorCode}</b>. No se muestra como lista vacía.</span>
      <button type="button" onClick={() => void onRetry()} className="w-fit rounded-lg border border-amber-300 px-3 py-2 text-xs font-semibold">Volver a intentar</button>
    </div> : <section className="overflow-hidden rounded-[20px] border border-slate-200/80 bg-white">
      <div className="flex flex-col gap-3 border-b border-slate-100 p-4 sm:flex-row sm:items-center">
        <div className="flex gap-1 rounded-lg bg-slate-100 p-1"><button type="button" onClick={()=>setShowHistory(false)} className={`rounded-md px-3 py-2 text-xs font-semibold ${!showHistory?"bg-white text-[#044474] shadow-sm":"text-slate-500"}`}>Activos</button><button type="button" onClick={()=>setShowHistory(true)} className={`rounded-md px-3 py-2 text-xs font-semibold ${showHistory?"bg-white text-[#044474] shadow-sm":"text-slate-500"}`}>Historial</button></div>
        <label className="flex flex-1 items-center gap-2 rounded-xl border border-slate-200 bg-[#fafcfe] px-3"><Search size={15} className="text-slate-400"/><input value={query} onChange={(event) => setQuery(event.target.value)} className="w-full bg-transparent py-2.5 text-sm outline-none" placeholder="Buscar nombre, correo, teléfono, solicitud u origen..."/></label>
        <span className="text-xs text-slate-500">{filtered.length} prospectos</span>
      </div>
      {loading ? <div className="p-8 text-sm text-slate-500">Cargando Prospectos...</div> : filtered.length ? <div className="divide-y divide-slate-100">
        {filtered.map((p) => { const owner = profiles.find((profile) => profile.id === p.owner_id); return <article key={p.id} className="grid gap-3 px-5 py-4 md:grid-cols-[minmax(0,1.4fr)_minmax(0,1fr)_150px_150px] md:items-center">
          <div className="min-w-0"><h2 className="truncate text-sm font-semibold text-[#044474]">{p.entity_name}{p.entity_type === "person" ? " · Persona" : " · Empresa"}</h2><p className="mt-1 truncate text-xs text-slate-500">{p.needs.map((n) => n.service_description).filter(Boolean).join("; ") || "Solicitud pendiente de completar"}</p><p className="mt-1 text-xs text-slate-500">{p.email || p.phone || "Sin datos de contacto"} · Último contacto: {p.last_contact_at ? new Date(p.last_contact_at).toLocaleDateString("es-PY") : "Sin registrar"}</p></div>
          <div className="text-xs text-slate-600"><span className="text-slate-400">Responsable · </span>{owner?.full_name || owner?.username || "Sin asignar"}<p className="mt-1 text-slate-500">Próximo paso · {p.next_action || "Sin definir"}</p><p className="mt-1 text-slate-500">Percepción · {p.commercial_perception || "Sin registrar"}</p><p className="mt-1 text-slate-500">Historial · {p.events.length} movimiento{p.events.length===1?"":"s"}</p><details className="mt-1"><summary className="cursor-pointer text-cyan-800">Ver historial</summary><ul className="mt-1 space-y-1">{p.events.slice(0,8).map((event)=><li key={event.id}>{new Date(event.occurred_at).toLocaleString("es-PY")} · {eventSummary(event)}</li>)}</ul></details></div>
          <span className="w-fit rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-700">{statusLabels[p.status] || p.status}</span>
          <div className="flex flex-wrap gap-2"><span className="text-xs text-slate-500">{p.source === "other" ? p.source_other || "Otro" : p.source || "Origen no indicado"}</span>{canManage && p.status !== "converted" && <button type="button" onClick={() => startEdit(p)} className="rounded-lg border px-2.5 py-1.5 text-xs font-semibold">Editar</button>}{canManage && p.status === "qualifying" && <button type="button" onClick={() => { setConvertTarget(p); setConvertTitle(p.needs.find((n) => n.service_description)?.service_description || `Oportunidad · ${p.entity_name}`); setHumanConfirmed(false); }} className="rounded-lg bg-cyan-50 px-2.5 py-1.5 text-xs font-semibold text-cyan-900">Convertir</button>}</div>
        </article>; })}
      </div> : <div className="p-8 text-sm text-slate-500">{prospects.length ? "No hay prospectos que coincidan con la búsqueda." : canManage ? "Todavía no hay prospectos. Usá “Nuevo Prospecto” para iniciar el seguimiento comercial." : "Todavía no hay prospectos registrados. Tu usuario tiene acceso de consulta; la creación está pendiente de autorización."}</div>}
    </section>}

    {draft && <div className="fixed inset-0 z-[80] flex items-start justify-center overflow-y-auto bg-slate-950/40 p-3 sm:p-6"><form onSubmit={submit} className="my-4 w-full max-w-3xl rounded-2xl bg-white p-5 shadow-2xl sm:p-7">
      <div className="flex items-start justify-between"><div><p className="text-xs font-bold uppercase tracking-wider text-cyan-700">Ventas · Prospectos</p><h2 className="mt-1 text-xl font-bold text-[#044474]">{draft.id ? "Editar Prospecto" : "Nuevo Prospecto"}</h2></div><button type="button" onClick={() => setDraft(null)} className="rounded-lg border px-3 py-1.5 text-sm">Cerrar</button></div>
      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        <Field label="Tipo de identidad"><select value={draft.entity_type} disabled={Boolean(draft.id || identitySelected)} onChange={(e) => setDraft({ ...draft, entity_type: e.target.value as "company" | "person" })} className="prospect-input"><option value="company">Empresa</option><option value="person">Persona</option></select></Field>
        <Field label={draft.entity_type === "company" ? "Nombre / razón social *" : "Nombre y apellido *"}><input required value={draft.display_name} disabled={identitySelected} onChange={(e) => setDraft({ ...draft, display_name: e.target.value })} className="prospect-input"/></Field>
        {draft.entity_type === "company" && <Field label="Razón legal"><input value={draft.legal_name} disabled={identitySelected} onChange={(e) => setDraft({ ...draft, legal_name: e.target.value })} className="prospect-input"/></Field>}
        <Field label="RUC (si se conoce)"><input value={draft.tax_id} disabled={identitySelected} onChange={(e) => setDraft({ ...draft, tax_id: e.target.value })} className="prospect-input"/></Field>
        <Field label="Correo"><input type="email" value={draft.email} disabled={identitySelected} onChange={(e) => setDraft({ ...draft, email: e.target.value })} className="prospect-input"/></Field>
        <Field label="Teléfono"><input value={draft.phone} disabled={identitySelected} onChange={(e) => setDraft({ ...draft, phone: e.target.value })} className="prospect-input"/></Field>
        <Field label="Origen *"><select required value={draft.source} onChange={(e) => setDraft({ ...draft, source: e.target.value })} className="prospect-input"><option value="">Seleccionar...</option>{["whatsapp","web","meta_ads","referral","existing_client","email","call","event","visit","social_media","other"].map((s) => <option key={s} value={s}>{({whatsapp:"WhatsApp",web:"Web",meta_ads:"Meta Ads",referral:"Referido",existing_client:"Cliente actual",email:"Email",call:"Llamada",event:"Evento",visit:"Visita",social_media:"Redes sociales",other:"Otro"} as Record<string,string>)[s]}</option>)}</select></Field>
        {draft.source === "other" && <Field label="Describí el origen *"><input value={draft.source_other} onChange={(e) => setDraft({ ...draft, source_other: e.target.value })} className="prospect-input"/></Field>}
        <Field label="Estado"><select value={draft.status} onChange={(e) => setDraft({ ...draft, status: e.target.value })} className="prospect-input">{Object.entries(statusLabels).filter(([k]) => k !== "converted").map(([value,label]) => <option key={value} value={value}>{label}</option>)}</select></Field>
        <Field label="Responsable comercial"><select value={draft.owner_id} onChange={(e) => setDraft({ ...draft, owner_id: e.target.value })} className="prospect-input"><option value="">Sin asignar</option>{profiles.map((p) => <option key={p.id} value={p.id}>{p.full_name || p.username || p.id}</option>)}</select></Field>
        <Field label="Referido por"><select value={draft.referrer_id} onChange={(e) => setDraft({ ...draft, referrer_id: e.target.value })} className="prospect-input"><option value="">No indicado</option>{profiles.map((p) => <option key={p.id} value={p.id}>{p.full_name || p.username || p.id}</option>)}</select></Field>
        <Field label="Último contacto"><input type="date" value={draft.last_contact_at} onChange={(e) => setDraft({ ...draft, last_contact_at: e.target.value })} className="prospect-input"/></Field>
        <Field label="Pausa · motivo" wide><input value={draft.pause_reason} onChange={(e) => setDraft({ ...draft, pause_reason: e.target.value })} className="prospect-input" placeholder={draft.status === "paused" ? "Obligatorio para pausar" : "Se requiere cuando el estado es Pausado"}/></Field>
        {draft.status === "paused" && <Field label="Fecha para revisar o reactivar"><input type="datetime-local" value={draft.pause_until} onChange={(e)=>setDraft({...draft,pause_until:e.target.value})} className="prospect-input"/></Field>}
        {draft.status === "disqualified" && <Field label="Motivo de baja *" wide><input value={draft.closed_reason} onChange={(e)=>setDraft({...draft,closed_reason:e.target.value})} className="prospect-input" placeholder="No respondió, sin presupuesto, plazo, competencia..."/></Field>}
        <Field label="Qué dijo el cliente (hecho)" wide><textarea rows={2} value={draft.customer_statement} onChange={(e) => setDraft({ ...draft, customer_statement: e.target.value })} className="prospect-input"/></Field>
        <Field label="Percepción comercial (interpretación)" wide><textarea rows={2} value={draft.commercial_perception} onChange={(e) => setDraft({ ...draft, commercial_perception: e.target.value })} className="prospect-input"/></Field>
        <Field label={`Próximo paso · Radar${draft.status === "disqualified" ? " (opcional para baja)" : " *"}`} wide><input required={draft.status !== "disqualified"} value={draft.next_action} onChange={(e) => setDraft({ ...draft, next_action: e.target.value })} className="prospect-input" placeholder="Acción concreta que mantenga la continuidad"/></Field>
        {draft.next_action.trim() && <><Field label="Revisar en"><input type="datetime-local" value={draft.next_review_at} onChange={(e) => setDraft({ ...draft, next_review_at: e.target.value })} className="prospect-input"/></Field><Field label="O cuando ocurra"><input value={draft.next_condition} onChange={(e) => setDraft({ ...draft, next_condition: e.target.value })} className="prospect-input"/></Field></>}
      </div>
      <div className="mt-5 rounded-xl border p-4"><div className="flex items-center justify-between"><b className="text-sm">Necesidades / servicios solicitados</b><button type="button" onClick={() => setDraft({ ...draft, needs: [...draft.needs, { category: "", service_description: "" }] })} className="rounded-lg border px-2.5 py-1.5 text-xs font-semibold">Agregar necesidad</button></div><div className="mt-3 space-y-2">{draft.needs.map((need,index)=><div key={index} className="grid gap-2 sm:grid-cols-[1fr_2fr_auto]"><input aria-label="Categoría" placeholder="Categoría" value={need.category} onChange={(e)=>setDraft({...draft,needs:draft.needs.map((n,i)=>i===index?{...n,category:e.target.value}:n)})} className="prospect-input"/><input aria-label="Necesidad / servicio" placeholder="Tipo de servicio o texto libre" value={need.service_description} onChange={(e)=>setDraft({...draft,needs:draft.needs.map((n,i)=>i===index?{...n,service_description:e.target.value}:n)})} className="prospect-input"/>{draft.needs.length>1&&<button type="button" aria-label="Quitar necesidad" onClick={()=>setDraft({...draft,needs:draft.needs.filter((_,i)=>i!==index)})} className="rounded-lg border px-3 text-xs">Quitar</button>}</div>)}</div></div>
      {matches.length > 0 && <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-3"><b className="text-sm">Identidades parecidas</b><div className="mt-2 space-y-2">{matches.map((m)=><label key={m.id} className="flex cursor-pointer items-start gap-2 rounded-lg bg-white p-2 text-xs"><input type="radio" name="identity_match" checked={selectedEntityId===m.id} onChange={()=>{setSelectedEntityId(m.id);setDraft(current=>current?{...current,entity_type:m.entity_type==="person"?"person":"company",display_name:m.display_name,legal_name:m.legal_name||"",tax_id:m.tax_id||"",email:m.email||"",phone:m.phone||""}:current)}}/><span><b>{m.display_name}</b> · {m.entity_type} · {[m.tax_id,m.email,m.phone].filter(Boolean).join(" / ")}</span></label>)}</div><label className="mt-3 flex items-center gap-2 text-xs"><input type="radio" name="identity_match" checked={selectedEntityId==="new"} onChange={()=>setSelectedEntityId("new")}/>No corresponde; crear una identidad nueva</label></div>}
      {formError && <p role="alert" className="mt-4 rounded-lg bg-amber-50 p-3 text-sm text-amber-900">{formError}</p>}
      <div className="mt-5 flex justify-end gap-2"><button type="button" onClick={()=>setDraft(null)} className="rounded-xl border px-4 py-2.5 text-sm">Cancelar</button><button disabled={saving || (matches.length>0&&!selectedEntityId)} className="rounded-xl bg-[#044474] px-5 py-2.5 text-sm font-bold text-white disabled:opacity-50">{saving ? "Guardando..." : "Guardar Prospecto"}</button></div>
    </form></div>}

    {convertTarget && <div className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/40 p-3"><form onSubmit={(e)=>{e.preventDefault();if(!humanConfirmed)return;void onConvert(convertTarget,convertTitle).then((ok)=>{if(ok)setConvertTarget(null);});}} className="w-full max-w-xl rounded-2xl bg-white p-6 shadow-2xl"><h2 className="text-xl font-bold text-[#044474]">Convertir a Oportunidad</h2><p className="mt-2 text-sm text-slate-600">La conversión conserva la identidad comercial y el historial del Prospecto. Una persona autorizada confirma; el sistema no convierte por su cuenta.</p><label className="mt-4 block text-sm font-semibold">Título de la oportunidad<input required value={convertTitle} onChange={(e)=>setConvertTitle(e.target.value)} className="prospect-input mt-1"/></label><label className="mt-4 flex items-start gap-2 text-sm"><input type="checkbox" checked={humanConfirmed} onChange={(e)=>setHumanConfirmed(e.target.checked)} className="mt-1"/><span>Confirmo que hay una necesidad concreta, una solución posible y una intención real de avanzar al siguiente paso comercial.</span></label><div className="mt-5 flex justify-end gap-2"><button type="button" onClick={()=>setConvertTarget(null)} className="rounded-xl border px-4 py-2.5 text-sm">Cancelar</button><button disabled={!humanConfirmed||saving} className="rounded-xl bg-[#044474] px-5 py-2.5 text-sm font-bold text-white disabled:opacity-50">{saving?"Convirtiendo...":"Confirmar conversión"}</button></div></form></div>}
    <style jsx global>{`.prospect-input{width:100%;border:1px solid #dbe4ee;border-radius:10px;padding:9px 11px;background:#fff;font-size:14px;outline:none}.prospect-input:focus{border-color:#08B2ED;box-shadow:0 0 0 3px rgba(11,169,232,.1)}.prospect-input:disabled{background:#f1f5f9;color:#64748b}`}</style>
  </>;
}

function Field({label,children,wide=false}:{label:string;children:ReactNode;wide?:boolean}){return <label className={`block text-xs font-semibold text-slate-600 ${wide?"sm:col-span-2":""}`}>{label}<span className="mt-1 block">{children}</span></label>}

function eventSummary(event: ProspectRow["events"][number]) {
  const labels: Record<string, string> = {
    created: "Prospecto registrado",
    status_changed: "Estado actualizado",
    assignment_changed: "Responsable actualizado",
    updated: "Datos de seguimiento actualizados",
    identity_updated: "Identidad comercial actualizada",
    need_added: "Necesidad agregada",
    need_updated: "Necesidad actualizada",
    need_removed: "Necesidad retirada",
  };
  return labels[event.event_type] || event.event_type.replaceAll("_", " ");
}
