"use client";

import {useEffect,useMemo,useRef,useState} from "react";
import {createClient} from "@/lib/supabase/client";
import dynamic from "next/dynamic";
import {calculateCommercialFinanceSummary, type FinanceSale} from "@/lib/finance/summary";
import {Banknote,FileText,Landmark,RefreshCw} from "lucide-react";

const FinancialPolicies=dynamic(()=>import("./FinancialPolicies"));

type Invoice={
  id:string;
  sale_id:string|null;
  invoice_number:string|null;
  currency:string;
  total_amount:number;
  status:string;
  issued_at:string|null;
  due_at:string|null;
  commercial_entity_id:string;
};

type Payment={
  status:string;
  id:string;
  invoice_id:string;
  currency:string;
  amount:number;
  payment_method:string|null;
  paid_at:string;
  external_reference:string|null;
};

type BankMovement={
  id:string;
  currency:string;
  amount:number;
  direction:string;
  occurred_at:string;
  description:string|null;
  external_reference:string|null;
};

const money=(value:number,currency:string)=>{
  if(currency==="PYG")
    return new Intl.NumberFormat("es-PY",{
      style:"currency",
      currency:"PYG",
      maximumFractionDigits:0
    }).format(value);

  return new Intl.NumberFormat("es-PY",{
    style:"currency",
    currency
  }).format(value);
};

const invoiceLabel:Record<string,string>={
  draft:"Borrador",
  issued:"Emitida",
  partially_paid:"Pago parcial",
  paid:"Pagada",
  void:"Anulada"
};

export default function FinanceView({canManagePolicies=false}:{canManagePolicies?:boolean}){
  const sb=useMemo(()=>createClient(),[]);
  const request=useRef(0);
  const [sales,setSales]=useState<FinanceSale[]>([]);
  const [invoices,setInvoices]=useState<Invoice[]>([]);
  const [payments,setPayments]=useState<Payment[]>([]);
  const [bank,setBank]=useState<BankMovement[]>([]);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState("");
  const [showPolicies,setShowPolicies]=useState(false);

  async function load(){
    const current=++request.current;
    setLoading(true);
    setError("");

    async function readRows<Row>(query:{
      range:(from:number,to:number)=>PromiseLike<{
        data:Row[]|null;error:unknown;
      }>;
    }):Promise<Row[]>{
      const rows:Row[]=[];
      for(let offset=0;;offset+=500){
        const result=await query.range(offset,offset+499);
        if(result.error) throw result.error;
        const page=result.data||[];
        rows.push(...page);
        if(page.length<500) return rows;
      }
    }

    try{
      const [a,b,c,d]=await Promise.all([
        readRows<Invoice>(sb.from("invoices").select("*").order("id",{ascending:true})),
        readRows<Payment>(sb.from("payments").select("*").order("id",{ascending:true})),
        readRows<BankMovement>(sb.from("bank_movements").select("*").order("id",{ascending:true})),
        readRows<FinanceSale>(sb.from("sales").select("id,currency,gross_amount").order("id",{ascending:true}))
      ]);
      if(current!==request.current) return;
      setInvoices(a.sort((x,y)=>(y.issued_at||"").localeCompare(x.issued_at||"")));
      setPayments(b.sort((x,y)=>y.paid_at.localeCompare(x.paid_at)));
      setBank(c.sort((x,y)=>y.occurred_at.localeCompare(x.occurred_at)));
      setSales(d);
    }catch{
      if(current!==request.current) return;
      setError("No se pudo cargar la información financiera.");
      setSales([]);
      setInvoices([]);
      setPayments([]);
      setBank([]);
    }finally{
      if(current===request.current) setLoading(false);
    }
  }

  useEffect(()=>{load();return ()=>{request.current++}},[]);

  const currencies=Array.from(new Set([
    "PYG",...sales.map(x=>x.currency),...invoices.map(x=>x.currency),
    ...payments.map(x=>x.currency)
  ])).sort((a,b)=>a===b?0:a==="PYG"?-1:b==="PYG"?1:a.localeCompare(b));

  return <>
    <div className="mb-5 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
      <div>
        <p className="text-[10px] font-medium uppercase tracking-[.16em] text-[#08B2ED]">
          Control financiero
        </p>
        <h1 className="mt-1.5 text-[27px] font-semibold tracking-[-.035em] text-[#044474] lg:text-[30px]">
          Finanzas
        </h1>
        <p className="mt-1.5 text-sm leading-6 text-slate-500">
          Facturación, cobros y movimientos bancarios registrados en el sistema.
        </p>
      </div>

      <button
        onClick={load}
        disabled={loading}
        className="inline-flex items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-[#044474]"
      >
        <RefreshCw size={15}/>
        Actualizar
      </button>
    </div>

    {canManagePolicies&&<div className="mb-5">
      <button type="button" aria-expanded={showPolicies} onClick={()=>setShowPolicies(x=>!x)}
        className="rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-[#044474]">
        {showPolicies?"Ocultar políticas y aprobaciones":"Políticas y aprobaciones"}
      </button>
      {showPolicies&&<FinancialPolicies/>}
    </div>}

    {error&&
      <div className="mb-4 rounded-xl border border-red-100 bg-red-50 p-4 text-sm text-red-700">
        No se pudo cargar la información financiera.
      </div>
    }

    {currencies.map(currency=>{
      const totals=calculateCommercialFinanceSummary(sales,invoices,payments,currency);
      return <section key={currency} className="mb-5" aria-label={`Resumen financiero ${currency}`}>
        <h2 className="mb-3 font-semibold text-[#044474]">{currency}</h2>
        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
          <Metric icon={<FileText size={18}/>} label="Vendido"
            value={loading||error?"—":money(totals.sold,currency)}/>
          <Metric icon={<FileText size={18}/>} label="Facturado"
            value={loading||error?"—":money(totals.billed,currency)}/>
          <Metric icon={<Banknote size={18}/>} label="Cobrado"
            value={loading||error?"—":money(totals.collected,currency)}/>
          <Metric icon={<Landmark size={18}/>} label="Pendiente de facturar"
            value={loading||error?"—":money(totals.pendingBilling,currency)}/>
          <Metric icon={<Landmark size={18}/>} label="Pendiente de cobro"
            value={loading||error?"—":money(totals.pending,currency)}/>
        </div>
      </section>;
    })}

    <div className="mt-5 grid gap-5 xl:grid-cols-2">
      <Section title="Facturas">
        {loading?
          <Empty text="Cargando información..."/>:
          invoices.length?
          invoices.map(x=>
            <div key={x.id} className="flex items-center justify-between gap-4 border-b border-slate-100 py-3 last:border-0">
              <div>
                <b className="text-sm text-[#26364b]">
                  {x.invoice_number||"Factura sin número"}
                </b>
                <p className="mt-1 text-xs text-slate-400">
                  {invoiceLabel[x.status]||x.status}
                  {x.issued_at?" · "+new Date(x.issued_at).toLocaleDateString("es-PY"):""}
                </p>
              </div>
              <b className="whitespace-nowrap text-sm text-[#044474]">
                {money(Number(x.total_amount),x.currency)}
              </b>
            </div>
          ):
          <Empty text="Todavía no hay facturas registradas."/>
        }
      </Section>

      <Section title="Cobros">
        {loading?
          <Empty text="Cargando información..."/>:
          payments.length?
          payments.map(x=>
            <div key={x.id} className="flex items-center justify-between gap-4 border-b border-slate-100 py-3 last:border-0">
              <div>
                <b className="text-sm text-[#26364b]">
                  {x.payment_method||"Cobro"}
                </b>
                <p className="mt-1 text-xs text-slate-400">
                  {new Date(x.paid_at).toLocaleDateString("es-PY")}
                  {x.external_reference?" · "+x.external_reference:""}
                </p>
              </div>
              <b className="whitespace-nowrap text-sm text-emerald-700">
                {money(Number(x.amount),x.currency)}
              </b>
            </div>
          ):
          <Empty text="Todavía no hay cobros registrados."/>
        }
      </Section>
    </div>

    <div className="mt-5">
      <Section title="Movimientos bancarios">
        {loading?
          <Empty text="Cargando información..."/>:
          bank.length?
          bank.map(x=>
            <div key={x.id} className="flex items-center justify-between gap-4 border-b border-slate-100 py-3 last:border-0">
              <div>
                <b className="text-sm text-[#26364b]">
                  {x.description||"Movimiento bancario"}
                </b>
                <p className="mt-1 text-xs text-slate-400">
                  {new Date(x.occurred_at).toLocaleDateString("es-PY")}
                  {x.external_reference?" · "+x.external_reference:""}
                </p>
              </div>
              <b className={`whitespace-nowrap text-sm ${x.direction==="credit"?"text-emerald-700":"text-red-600"}`}>
                {x.direction==="credit"?"+":"-"} {money(Number(x.amount),x.currency)}
              </b>
            </div>
          ):
          <Empty text="Todavía no hay movimientos bancarios registrados."/>
        }
      </Section>
    </div>
  </>;
}

function Metric({icon,label,value}:{icon:React.ReactNode;label:string;value:string}){
  return <div className="rounded-[18px] border border-slate-200/80 bg-white p-5">
    <div className="flex items-center gap-2 text-[#08B2ED]">
      {icon}
      <span className="text-xs font-medium text-slate-500">{label}</span>
    </div>
    <b className="mt-3 block text-2xl font-semibold tracking-[-.03em] text-[#044474]">
      {value}
    </b>
  </div>;
}

function Section({title,children}:{title:string;children:React.ReactNode}){
  return <section className="rounded-[20px] border border-slate-200/80 bg-white p-5">
    <h2 className="mb-3 font-semibold text-[#044474]">{title}</h2>
    {children}
  </section>;
}

function Empty({text}:{text:string}){
  return <p className="py-6 text-center text-sm text-slate-400">{text}</p>;
}

