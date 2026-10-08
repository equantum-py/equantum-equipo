"use client";

import {useEffect,useMemo,useRef,useState, type FormEvent, type ReactNode} from "react";
import {createClient} from "@/lib/supabase/client";

type FiscalPolicy={id:string;policy_code:string;version:number;classification:string;rate_percent:number;basis_reference:string};
type CommissionPolicy={id:string;policy_code:string;version:number;rate_percent:number};
type Proposal={id:string;version:number;currency:string|null;status:string};
type Item={id:string;proposal_id:string;description:string;quantity:number;unit_price:number;discount_amount:number;tax_amount:number;line_total:number;fiscal_approval_id:string|null};
const classificationLabel:Record<string,string>={taxable:"Gravado",export_zero:"Exportación a tasa cero",exempt:"Exento"};

async function allRows<Row>(query:{range:(from:number,to:number)=>PromiseLike<{data:Row[]|null;error:unknown}>}){
  const rows:Row[]=[];
  for(let offset=0;;offset+=500){
    const result=await query.range(offset,offset+499);
    if(result.error) throw result.error;
    const page=result.data||[];
    rows.push(...page);
    if(page.length<500) return rows;
  }
}

export default function FinancialPolicies(){
  const sb=useMemo(()=>createClient(),[]);
  const generation=useRef(0), mounted=useRef(true), writing=useRef(false);
  const [fiscal,setFiscal]=useState<FiscalPolicy[]>([]);
  const [commission,setCommission]=useState<CommissionPolicy[]>([]);
  const [proposals,setProposals]=useState<Proposal[]>([]);
  const [items,setItems]=useState<Item[]>([]);
  const [actor,setActor]=useState("");
  const [loading,setLoading]=useState(true),[busy,setBusy]=useState(false);
  const [error,setError]=useState(""),[notice,setNotice]=useState("");
  const [classification,setClassification]=useState("taxable");
  const [proposalId,setProposalId]=useState(""),[itemId,setItemId]=useState("");

  async function authorizedActor(){
    const {data:{user},error:authError}=await sb.auth.getUser();
    if(authError||!user) throw new Error("Tu sesión no está disponible. Volvé a iniciar sesión.");
    const [profile,permission]=await Promise.all([
      sb.from("profiles").select("active,is_master").eq("id",user.id).single(),
      sb.rpc("has_financial_info")
    ]);
    if(profile.error||permission.error) throw new Error("No se pudieron verificar tus permisos.");
    if(profile.data?.active!==true||profile.data?.is_master!==true||permission.data!==true)
      throw new Error("Esta configuración requiere una cuenta maestra activa con acceso financiero.");
    return user.id;
  }

  async function load(){
    const current=++generation.current;
    setLoading(true);setError("");setActor("");
    try{
      const uid=await authorizedActor();
      const [a,b,c,d]=await Promise.all([
        allRows<FiscalPolicy>(sb.from("fiscal_policy_versions").select("id,policy_code,version,classification,rate_percent,basis_reference").order("id")),
        allRows<CommissionPolicy>(sb.from("commission_policy_versions").select("id,policy_code,version,rate_percent").order("id")),
        allRows<Proposal>(sb.from("proposals").select("id,version,currency,status").order("id")),
        allRows<Item>(sb.from("proposal_items").select("id,proposal_id,description,quantity,unit_price,discount_amount,tax_amount,line_total,fiscal_approval_id").order("id"))
      ]);
      if(!mounted.current||current!==generation.current) return;
      setFiscal(a.sort((x,y)=>x.policy_code.localeCompare(y.policy_code)||y.version-x.version));
      setCommission(b.sort((x,y)=>x.policy_code.localeCompare(y.policy_code)||y.version-x.version));
      setProposals(c);setItems(d);setActor(uid);
    }catch(e){
      if(!mounted.current||current!==generation.current) return;
      setFiscal([]);setCommission([]);setProposals([]);setItems([]);
      setError(e instanceof Error?e.message:"No se pudo cargar la configuración financiera.");
    }finally{
      if(mounted.current&&current===generation.current) setLoading(false);
    }
  }

  useEffect(()=>{
    mounted.current=true;load();
    return ()=>{mounted.current=false;generation.current++};
  },[]);

  async function save(event:FormEvent<HTMLFormElement>,kind:"fiscal"|"commission"|"approval"){
    event.preventDefault();
    if(writing.current||loading||!actor) return;
    const form=event.currentTarget,fields=new FormData(form);
    writing.current=true;setBusy(true);setError("");setNotice("");
    let saved=false;
    try{
      const uid=await authorizedActor();
      if(uid!==actor) throw new Error("La sesión cambió. Actualizá la configuración antes de guardar.");
      const value=(name:string)=>String(fields.get(name)||"").trim();
      if(kind==="approval"){
        const result=await sb.rpc("approve_proposal_item_fiscal_v3",{
          p_item_id:value("item_id"),p_policy_id:value("policy_id"),
          p_justification:value("justification"),p_evidence_reference:value("evidence_reference")
        });
        if(result.error) throw result.error;
        if(typeof result.data!=="string"||!result.data) throw new Error("No se confirmó la aprobación fiscal.");
      }else{
        const payload={policy_code:value("policy_code"),version:Number(value("version")),
          rate_percent:kind==="fiscal"&&value("classification")!=="taxable"?0:Number(value("rate_percent")),created_by:uid};
        const result=kind==="fiscal"
          ?await sb.from("fiscal_policy_versions").insert({...payload,classification:value("classification"),basis_reference:value("basis_reference")}).select("id").single()
          :await sb.from("commission_policy_versions").insert(payload).select("id").single();
        if(result.error) throw result.error;
        if(!result.data?.id) throw new Error("No se confirmó la creación de la versión.");
      }
      saved=true;
      if(!mounted.current) return;
      form.reset();
      if(kind==="fiscal") setClassification("taxable");
      if(kind==="approval") setItemId("");
      setNotice(kind==="approval"?"Aprobación fiscal registrada. Importes de la propuesta recalculados.":"Versión creada. Las versiones anteriores se conservan.");
      await load();
    }catch(e){
      if(!mounted.current) return;
      const code=(e as {code?:string})?.code;
      setError(code==="23505"?"Ese código y versión ya existen. Elegí una nueva versión."
        :code==="42501"?"Tu cuenta no tiene permiso para realizar esta operación."
        :saved?"El cambio se guardó, pero no se pudo actualizar la pantalla. Actualizá antes de repetirlo."
        :e instanceof Error?e.message:"No se pudo guardar el cambio. Revisá los datos y tus permisos.");
    }finally{
      writing.current=false;
      if(mounted.current) setBusy(false);
    }
  }

  const selectedProposal=proposals.find(p=>p.id===proposalId);
  const selectedItem=items.find(i=>i.id===itemId&&i.proposal_id===proposalId);
  const locked=loading||busy||!actor;
  return <section className="mt-6 space-y-5" aria-label="Políticas fiscales y de comisión">
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div><h2 className="text-xl font-semibold text-[#044474]">Políticas y aprobaciones</h2>
        <p className="mt-1 text-sm text-slate-500">Cada cambio se registra como una nueva versión. Las ventas conservan su política al cierre.</p></div>
      <button type="button" disabled={loading||busy} onClick={()=>load()} className="rounded-xl border px-4 py-2 disabled:opacity-50">Actualizar políticas</button>
    </div>
    {loading&&<p role="status">Cargando configuración…</p>}
    {error&&<p role="alert" className="rounded-xl bg-red-50 p-4 text-sm text-red-700">{error}</p>}
    {notice&&<p role="status" className="rounded-xl bg-emerald-50 p-4 text-sm text-emerald-800">{notice}</p>}
    {actor&&<>
      <div className="grid gap-5 xl:grid-cols-2">
        <Panel title="Nueva versión fiscal">
          <form onSubmit={e=>save(e,"fiscal")}><fieldset disabled={locked} className="space-y-3">
            <PolicyFields/>
            <Field label="Tratamiento"><select name="classification" value={classification} onChange={e=>setClassification(e.target.value)} className="inputV3">
              {Object.entries(classificationLabel).map(([value,label])=><option key={value} value={value}>{label}</option>)}
            </select></Field>
            <RateField zero={classification!=="taxable"}/>
            <Field label="Referencia que fundamenta el tratamiento"><input required name="basis_reference" className="inputV3"/></Field>
            <p className="text-xs text-slate-500">Registrá la clasificación respaldada por la documentación aplicable. La moneda no determina el tratamiento fiscal.</p>
            <SaveButton busy={busy}/>
          </fieldset></form>
          <PolicyList rows={fiscal.map(p=>`${p.policy_code} · v${p.version} · ${classificationLabel[p.classification]||p.classification} · ${p.rate_percent}% · ${p.basis_reference}`)}/>
        </Panel>
        <Panel title="Nueva versión de comisión">
          <form onSubmit={e=>save(e,"commission")}><fieldset disabled={locked} className="space-y-3">
            <PolicyFields/><RateField/>
            <p className="text-xs text-slate-500">La base de comisión excluye el impuesto. Crear una versión no la asigna automáticamente a una propuesta.</p>
            <SaveButton busy={busy}/>
          </fieldset></form>
          <PolicyList rows={commission.map(p=>`${p.policy_code} · v${p.version} · ${p.rate_percent}%`)}/>
        </Panel>
      </div>
      <Panel title="Aprobar tratamiento fiscal de una partida">
        <form onSubmit={e=>save(e,"approval")}><fieldset disabled={locked} className="space-y-3">
          <Field label="Propuesta"><select required value={proposalId} onChange={e=>{setProposalId(e.target.value);setItemId("")}} className="inputV3">
            <option value="">Seleccionar propuesta</option>
            {proposals.map(p=><option key={p.id} value={p.id}>{p.id} · v{p.version} · {p.currency||"Sin moneda"} · {p.status}</option>)}
          </select></Field>
          <Field label="Partida"><select required name="item_id" value={itemId} onChange={e=>setItemId(e.target.value)} className="inputV3">
            <option value="">Seleccionar partida</option>
            {items.filter(i=>i.proposal_id===proposalId).map(i=><option key={i.id} value={i.id}>{i.description} · {i.id}</option>)}
          </select></Field>
          {selectedItem&&<p className="rounded-xl bg-slate-50 p-3 text-sm">{selectedItem.description}: {selectedItem.quantity} × {selectedItem.unit_price}; descuento {selectedItem.discount_amount}; impuesto actual {selectedItem.tax_amount} {selectedProposal?.currency}. {selectedItem.fiscal_approval_id?"Ya tiene una aprobación; se registrará una nueva decisión.":"Sin aprobación fiscal registrada."}</p>}
          <Field label="Versión fiscal"><select required name="policy_id" className="inputV3"><option value="">Seleccionar versión</option>
            {fiscal.map(p=><option key={p.id} value={p.id}>{p.policy_code} · v{p.version} · {classificationLabel[p.classification]} · {p.rate_percent}%</option>)}
          </select></Field>
          <Field label="Justificación"><textarea required name="justification" rows={3} className="inputV3"/></Field>
          <Field label="Referencia de la evidencia"><input required name="evidence_reference" className="inputV3"/></Field>
          <button disabled={!itemId||!selectedProposal?.currency||!fiscal.length} className="rounded-xl bg-[#044474] px-4 py-3 text-sm text-white disabled:opacity-50">{busy?"Guardando…":"Registrar aprobación y recalcular"}</button>
        </fieldset></form>
        {!proposals.length&&<p className="mt-3 text-sm text-slate-500">No hay propuestas disponibles para tu cuenta.</p>}
      </Panel>
    </>}
  </section>;
}

function Panel({title,children}:{title:string;children:ReactNode}){return <section className="rounded-[20px] border border-slate-200 bg-white p-5"><h3 className="mb-4 font-semibold text-[#044474]">{title}</h3>{children}</section>}
function Field({label,children}:{label:string;children:ReactNode}){return <label className="block text-sm text-slate-600"><span className="mb-1 block">{label}</span>{children}</label>}
function PolicyFields(){return <div className="grid gap-3 sm:grid-cols-2"><Field label="Código de política"><input required name="policy_code" className="inputV3"/></Field><Field label="Versión"><input required name="version" type="number" min="1" max="2147483647" step="1" defaultValue="1" className="inputV3"/></Field></div>}
function RateField({zero=false}:{zero?:boolean}){return <Field label="Porcentaje"><input key={zero?"zero":"rate"} required name="rate_percent" type="number" min="0" max="100" step="0.0001" readOnly={zero} defaultValue={zero?"0":undefined} className="inputV3"/></Field>}
function SaveButton({busy}:{busy:boolean}){return <button className="rounded-xl bg-[#044474] px-4 py-3 text-sm text-white">{busy?"Guardando…":"Crear versión"}</button>}
function PolicyList({rows}:{rows:string[]}){return <div className="mt-5 border-t pt-3"><h4 className="text-sm font-medium">Versiones registradas</h4>{rows.length?<ul className="mt-2 max-h-52 space-y-2 overflow-y-auto text-xs text-slate-600">{rows.map((row,index)=><li key={index} className="break-words">{row}</li>)}</ul>:<p className="mt-2 text-sm text-slate-500">Sin versiones registradas.</p>}</div>}
