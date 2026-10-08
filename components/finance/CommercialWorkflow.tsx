"use client";
import {useEffect,useMemo,useRef,useState,type FormEvent,type ReactNode} from "react";
import {createClient} from "@/lib/supabase/client";

type Entity={id:string;display_name:string};
type Policy={id:string;policy_code:string;version:number;rate_percent:number};
type Proposal={id:string;opportunity_id:string;version:number;currency:string|null;total_amount:number|null;status:string};
type Sale={id:string;currency:string;gross_amount:number;net_amount:number;tax_amount:number};
type Invoice={id:string;invoice_number:string|null;currency:string;total_amount:number;status:string};
type Line={key:number;description:string;quantity:string;unit_price:string;discount_amount:string};
const blankLine=(key:number):Line=>({key,description:"",quantity:"1",unit_price:"",discount_amount:"0"});
async function rows<T>(query:{range:(a:number,b:number)=>PromiseLike<{data:T[]|null;error:unknown}>}){
  const all:T[]=[];for(let i=0;;i+=500){const r=await query.range(i,i+499);if(r.error)throw r.error;all.push(...(r.data||[]));if((r.data||[]).length<500)return all}
}

export default function CommercialWorkflow({onChange}:{onChange:()=>Promise<void>}){
  const sb=useMemo(()=>createClient(),[]),alive=useRef(true),generation=useRef(0),writing=useRef(false),requestId=useRef("");
  const [actor,setActor]=useState(""),[loading,setLoading]=useState(true),[busy,setBusy]=useState(false);
  const [error,setError]=useState(""),[notice,setNotice]=useState("");
  const [entities,setEntities]=useState<Entity[]>([]),[fiscal,setFiscal]=useState<Policy[]>([]),[commission,setCommission]=useState<Policy[]>([]);
  const [proposals,setProposals]=useState<Proposal[]>([]),[sales,setSales]=useState<Sale[]>([]),[invoices,setInvoices]=useState<Invoice[]>([]);
  const [lines,setLines]=useState<Line[]>([blankLine(0)]),nextLine=useRef(1);
  const [invoiceId,setInvoiceId]=useState("");
  async function master(){
    const u=await sb.auth.getUser();if(u.error||!u.data.user)throw new Error("Iniciá sesión para operar.");
    const [p,f]=await Promise.all([sb.from("profiles").select("active,is_master").eq("id",u.data.user.id).single(),sb.rpc("has_financial_info")]);
    if(p.error||f.error||p.data?.active!==true||p.data?.is_master!==true||f.data!==true)throw new Error("Se requiere Master activo con acceso financiero.");
    return u.data.user.id;
  }
  async function load(){
    const current=++generation.current;setLoading(true);setActor("");
    try{
      const uid=await master();const [e,f,c,p,s,i]=await Promise.all([
        rows<Entity>(sb.from("commercial_entities").select("id,display_name").eq("status","active").order("id")),
        rows<Policy>(sb.from("fiscal_policy_versions").select("id,policy_code,version,rate_percent").order("id")),
        rows<Policy>(sb.from("commission_policy_versions").select("id,policy_code,version,rate_percent").order("id")),
        rows<Proposal>(sb.from("proposals").select("id,opportunity_id,version,currency,total_amount,status").order("id")),
        rows<Sale>(sb.from("sales").select("id,currency,gross_amount,net_amount,tax_amount").order("id")),
        rows<Invoice>(sb.from("invoices").select("id,invoice_number,currency,total_amount,status").order("id"))
      ]);
      if(!alive.current||current!==generation.current)return;
      setEntities(e);setFiscal(f);setCommission(c);setProposals(p);setSales(s);setInvoices(i);setActor(uid);
    }catch(e){if(alive.current&&current===generation.current)setError(e instanceof Error?e.message:"No se pudo cargar el circuito comercial.")}
    finally{if(alive.current&&current===generation.current)setLoading(false)}
  }
  useEffect(()=>{alive.current=true;load();return()=>{alive.current=false;generation.current++}},[]);
  async function submit(event:FormEvent<HTMLFormElement>,kind:"proposal"|"close"|"invoice"|"payment"){
    event.preventDefault();if(writing.current||loading||!actor)return;
    const form=event.currentTarget,fd=new FormData(form),value=(k:string)=>String(fd.get(k)||"").trim();
    writing.current=true;setBusy(true);setError("");setNotice("");let saved=false;
    try{
      if(await master()!==actor)throw new Error("La sesión cambió. Actualizá antes de operar.");
      let result;
      if(kind==="proposal"){
        if(!requestId.current)requestId.current=crypto.randomUUID();
        result=await sb.rpc("create_proposal_workflow_v3",{p_request_id:requestId.current,p_entity_id:value("entity"),p_title:value("title"),p_currency:value("currency"),
          p_items:lines.map(({description,quantity,unit_price,discount_amount})=>({description,quantity,unit_price,discount_amount})),
          p_fiscal_policy_id:value("fiscal"),p_commission_policy_id:value("commission")||null,p_justification:value("reason"),p_evidence_reference:value("evidence")});
      }else if(kind==="close")result=await sb.rpc("close_proposal_workflow_v3",{p_proposal_id:value("proposal")});
      else if(kind==="invoice")result=await sb.rpc("create_workflow_invoice_v3",{p_sale_id:value("sale"),p_invoice_number:value("number"),p_subtotal:value("subtotal"),p_tax:value("tax"),
        p_issued_at:new Date(value("issued")).toISOString(),p_due_at:value("due")?new Date(value("due")).toISOString():null});
      else{
        const invoice=invoices.find(i=>i.id===invoiceId);if(!invoice)throw new Error("Seleccioná una factura disponible.");
        result=await sb.rpc("register_invoice_payment",{p_invoice_id:invoice.id,p_amount:value("amount"),p_currency:invoice.currency,p_payment_method:value("method"),p_external_reference:value("reference"),p_paid_at:new Date(value("paid")).toISOString()});
      }
      if(result.error)throw result.error;
      if(typeof result.data!=="string"||!result.data)throw new Error("No se confirmó la operación.");
      saved=true;if(!alive.current)return;
      setNotice(`Operación registrada: ${result.data}.`);
      if(kind==="proposal"){requestId.current="";setLines([blankLine(nextLine.current++)]);}
      if(kind==="payment")setInvoiceId("");
      form.reset();await load();await onChange();
    }catch(e){
      if(alive.current)setError(saved?"La operación quedó registrada. Actualizá la pantalla antes de repetirla."
        :(e as {code?:string})?.code==="42501"?"No tenés permiso para esta operación."
        :(e as {code?:string})?.code==="22023"?"Revisá los importes, aprobaciones y referencias. Un número o referencia ya usado debe conservar los mismos datos."
        :(e as {code?:string})?.code==="55000"?"La propuesta ya está cerrada. Sus importes históricos se conservan."
        :e instanceof Error?e.message:"No se confirmó el resultado. Actualizá y verificá los registros antes de repetir la operación.");
    }finally{writing.current=false;if(alive.current)setBusy(false)}
  }
  const locked=loading||busy||!actor;
  return <section className="mt-5 space-y-5" aria-label="Circuito comercial y financiero">
    <div className="flex flex-wrap justify-between gap-3"><div><h2 className="text-xl font-semibold text-[#044474]">Operaciones comerciales</h2><p className="mt-1 text-sm text-slate-500">Propuesta → Venta → Factura → Cobro. Cada paso queda registrado por separado.</p></div>
      <button type="button" disabled={loading||busy} onClick={()=>{setError("");load()}} className="rounded-xl border px-4 py-2">Actualizar operaciones</button></div>
    {loading&&<p role="status">Cargando operaciones…</p>}{error&&<p role="alert" className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p>}{notice&&<p role="status" className="rounded-xl bg-emerald-50 p-4 text-sm text-emerald-800 break-words">{notice}</p>}
    {actor&&<>
      <Panel title="1. Crear propuesta y aprobar fiscalidad">
        <form onSubmit={e=>submit(e,"proposal")}><fieldset disabled={locked} className="space-y-3">
          <Field label="Empresa"><select required name="entity" className="inputV3"><option value="">Seleccionar empresa</option>{entities.map(e=><option key={e.id} value={e.id}>{e.display_name}</option>)}</select></Field>
          <Field label="Título"><input required name="title" className="inputV3"/></Field>
          <Field label="Moneda"><select name="currency" className="inputV3">{['PYG','USD','BRL','EUR'].map(c=><option key={c}>{c}</option>)}</select></Field>
          {lines.map((line,index)=><div key={line.key} className="rounded-xl border p-3"><p className="mb-2 text-sm font-medium">Partida {index+1}</p><div className="grid gap-3 sm:grid-cols-2">
            {([['description','Descripción'],['quantity','Cantidad'],['unit_price','Precio unitario'],['discount_amount','Descuento']] as const).map(([key,label])=><Field key={key} label={label}><input required className="inputV3" type={key==='description'?'text':'number'} min={key==='quantity'?'0.0001':'0'} step={key==='quantity'?'0.0001':'0.01'} value={line[key]} onChange={e=>setLines(ls=>ls.map(l=>l.key===line.key?{...l,[key]:e.target.value}:l))}/></Field>)}</div>
            {lines.length>1&&<button type="button" onClick={()=>setLines(ls=>ls.filter(l=>l.key!==line.key))} className="mt-2 text-sm text-red-700">Quitar partida</button>}</div>)}
          <button type="button" disabled={lines.length>=100} onClick={()=>setLines(ls=>[...ls,blankLine(nextLine.current++)])} className="rounded-xl border px-3 py-2 text-sm">Agregar partida</button>
          <Field label="Política fiscal para estas partidas"><select required name="fiscal" className="inputV3"><option value="">Seleccionar versión</option>{fiscal.map(p=><option key={p.id} value={p.id}>{p.policy_code} · v{p.version} · {p.rate_percent}%</option>)}</select></Field>
          <Field label="Comisión"><select name="commission" className="inputV3"><option value="">Sin comisión configurada</option>{commission.map(p=><option key={p.id} value={p.id}>{p.policy_code} · v{p.version} · {p.rate_percent}%</option>)}</select></Field>
          <Field label="Justificación fiscal"><textarea required name="reason" rows={2} className="inputV3"/></Field><Field label="Referencia de evidencia"><input required name="evidence" className="inputV3"/></Field>
          <p className="text-xs text-slate-500">La política elegida se aplica a todas estas partidas. Podés aprobar un tratamiento distinto por partida desde Políticas y aprobaciones antes de cerrar.</p>
          <Save busy={busy} label="Crear propuesta"/>
        </fieldset></form>
      </Panel>
      <div className="grid gap-5 xl:grid-cols-2"><Panel title="2. Cerrar propuesta como venta"><form onSubmit={e=>submit(e,"close")}><fieldset disabled={locked} className="space-y-3">
        <Field label="Propuesta aprobada"><select required name="proposal" className="inputV3"><option value="">Seleccionar propuesta</option>{proposals.filter(p=>!['accepted','rejected'].includes(p.status)).map(p=><option key={p.id} value={p.id}>{p.id} · v{p.version} · {p.total_amount} {p.currency}</option>)}</select></Field>
        <p className="text-xs text-slate-500">El cierre conserva importes, fiscalidad y comisión. No crea factura ni cobro.</p><Save busy={busy} label="Cerrar y registrar venta"/>
      </fieldset></form></Panel>
      <Panel title="3. Registrar factura"><form onSubmit={e=>submit(e,"invoice")}><fieldset disabled={locked} className="space-y-3">
        <Field label="Venta"><select required name="sale" className="inputV3"><option value="">Seleccionar venta</option>{sales.map(s=><option key={s.id} value={s.id}>{s.id} · neto {s.net_amount} · impuesto {s.tax_amount} {s.currency}</option>)}</select></Field>
        <Field label="Número de factura"><input required name="number" className="inputV3"/></Field><Field label="Importe neto a facturar"><input required name="subtotal" type="number" min="0" step="0.01" className="inputV3"/></Field><Field label="Impuesto a facturar"><input required name="tax" type="number" min="0" step="0.01" className="inputV3"/></Field>
        <Field label="Emisión"><input required name="issued" type="datetime-local" className="inputV3"/></Field><Field label="Vencimiento"><input name="due" type="datetime-local" className="inputV3"/></Field>
        <p className="text-xs text-slate-500">La moneda viene de la venta. El importe no puede superar el neto o impuesto pendiente de facturar.</p><Save busy={busy} label="Registrar factura"/>
      </fieldset></form></Panel></div>
      <Panel title="4. Registrar cobro"><form onSubmit={e=>submit(e,"payment")}><fieldset disabled={locked} className="space-y-3">
        <Field label="Factura"><select required value={invoiceId} onChange={e=>setInvoiceId(e.target.value)} className="inputV3"><option value="">Seleccionar factura</option>{invoices.filter(i=>['issued','partially_paid'].includes(i.status)).map(i=><option key={i.id} value={i.id}>{i.invoice_number||i.id} · {i.total_amount} {i.currency}</option>)}</select></Field>
        <Field label="Importe cobrado"><input required name="amount" type="number" min="0.01" step="0.01" className="inputV3"/></Field><Field label="Medio de pago"><input required name="method" className="inputV3"/></Field><Field label="Referencia única del cobro"><input required name="reference" className="inputV3"/></Field><Field label="Fecha del cobro"><input required name="paid" type="datetime-local" className="inputV3"/></Field>
        <p className="text-xs text-slate-500">El cobro usa la moneda de la factura. La referencia identifica la operación para evitar duplicados al reintentar.</p><Save busy={busy} label="Registrar cobro"/>
      </fieldset></form></Panel>
    </>}
  </section>;
}
function Panel({title,children}:{title:string;children:ReactNode}){return <section className="rounded-[20px] border border-slate-200 bg-white p-5"><h3 className="mb-4 font-semibold text-[#044474]">{title}</h3>{children}</section>}
function Field({label,children}:{label:string;children:ReactNode}){return <label className="block text-sm text-slate-600"><span className="mb-1 block">{label}</span>{children}</label>}
function Save({busy,label}:{busy:boolean;label:string}){return <button className="rounded-xl bg-[#044474] px-4 py-3 text-sm text-white">{busy?'Guardando…':label}</button>}
