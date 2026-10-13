"use client";

import { useEffect, useMemo, useState } from "react";
import { Search } from "lucide-react";
import { createClient } from "@/lib/supabase/client";

type Prospect = {
  id: string;
  commercial_entity_id: string;
  status: string;
  owner_id: string | null;
  source: string | null;
  created_at: string;
  entity_name: string;
  email: string | null;
  phone: string | null;
};

type Profile = { id: string; full_name: string | null; username: string | null };

export default function ProspectsView() {
  const supabase = useMemo(() => createClient(), []);
  const [prospects, setProspects] = useState<Prospect[]>([]);
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [errorCode, setErrorCode] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState("");

  useEffect(() => {
    let active = true;
    async function load() {
      const access = await supabase.rpc("is_internal_user");
      if (access.error || access.data !== true) {
        if (active) {
          setErrorCode(access.error?.code || "INTERNAL_ACCESS_REQUIRED");
          setLoading(false);
        }
        return;
      }

      const result = await supabase
        .from("prospects")
        .select("id,commercial_entity_id,status,owner_id,source,created_at")
        .is("archived_at", null)
        .order("created_at", { ascending: false });
      if (result.error) {
        if (active) {
          setErrorCode(result.error.code || "PROSPECTS_READ_FAILED");
          setLoading(false);
        }
        return;
      }

      const rows = result.data || [];
      const entityIds = [...new Set(rows.map((row) => row.commercial_entity_id))];
      if (!entityIds.length) {
        if (active) {
          setProspects([]);
          setErrorCode(null);
          setLoading(false);
        }
        return;
      }

      const [entities, owners] = await Promise.all([
        supabase
          .from("commercial_entities")
          .select("id,display_name,email,phone")
          .in("id", entityIds),
        supabase.from("profiles").select("id,full_name,username"),
      ]);
      if (entities.error || owners.error) {
        if (active) {
          setErrorCode(entities.error?.code || owners.error?.code || "PROSPECT_DETAILS_READ_FAILED");
          setLoading(false);
        }
        return;
      }

      const byId = new Map((entities.data || []).map((entity) => [entity.id, entity]));
      const visible = rows.flatMap((row) => {
        const entity = byId.get(row.commercial_entity_id);
        return entity
          ? [{
              ...row,
              entity_name: entity.display_name,
              email: entity.email,
              phone: entity.phone,
            }]
          : [];
      });
      if (active) {
        setProspects(visible);
        setProfiles((owners.data || []) as Profile[]);
        setErrorCode(null);
        setLoading(false);
      }
    }

    void load();
    return () => { active = false; };
  }, [supabase]);

  const filtered = useMemo(() => {
    const q = query.trim().toLocaleLowerCase();
    if (!q) return prospects;
    return prospects.filter((prospect) =>
      [prospect.entity_name, prospect.email, prospect.phone, prospect.source, prospect.status]
        .filter(Boolean)
        .some((value) => String(value).toLocaleLowerCase().includes(q)),
    );
  }, [prospects, query]);

  return (
    <>
      <div className="mb-5">
        <p className="text-[10px] font-medium uppercase tracking-[.16em] text-[#08B2ED]">Ventas</p>
        <h1 className="mt-1.5 text-[27px] font-semibold tracking-[-.035em] text-[#044474]">Prospectos</h1>
        <p className="mt-1.5 text-sm leading-6 text-slate-500">
          Contactos que todavía no son clientes. Esta vista permite consultar los registros autorizados.
        </p>
      </div>

      <div className="mb-4 rounded-xl border border-blue-100 bg-blue-50 p-3 text-sm text-blue-900">
        Alta, edición, calificación y conversión no están habilitadas en esta entrega.
      </div>

      {errorCode ? (
        <div role="alert" className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
          No se pudieron cargar Prospectos. Código: <b>{errorCode}</b>. Esto no significa que la lista esté vacía.
        </div>
      ) : (
        <section className="overflow-hidden rounded-[20px] border border-slate-200/80 bg-white">
          <div className="flex flex-col gap-3 border-b border-slate-100 p-4 sm:flex-row sm:items-center">
            <label className="flex flex-1 items-center gap-2 rounded-xl border border-slate-200 bg-[#fafcfe] px-3">
              <Search size={15} className="text-slate-400" />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                className="w-full bg-transparent py-2.5 text-sm outline-none"
                placeholder="Buscar nombre, correo, teléfono u origen..."
              />
            </label>
            <span className="text-xs text-slate-500">{filtered.length} prospectos</span>
          </div>
          {loading ? (
            <div className="p-8 text-sm text-slate-500">Cargando Prospectos...</div>
          ) : filtered.length ? (
            <div className="divide-y divide-slate-100">
              {filtered.map((prospect) => {
                const owner = profiles.find((profile) => profile.id === prospect.owner_id);
                return (
                  <article key={prospect.id} className="grid gap-2 px-5 py-4 md:grid-cols-[minmax(0,1.4fr)_minmax(0,1fr)_150px_150px] md:items-center">
                    <div className="min-w-0">
                      <h2 className="truncate text-sm font-semibold text-[#044474]">{prospect.entity_name}</h2>
                      <p className="mt-1 text-xs text-slate-500">{prospect.email || prospect.phone || "Sin datos de contacto"}</p>
                    </div>
                    <div className="text-xs text-slate-600">
                      <span className="text-slate-400">Responsable · </span>
                      {owner?.full_name || owner?.username || "Sin asignar"}
                    </div>
                    <span className="w-fit rounded-full bg-slate-100 px-2.5 py-1 text-xs text-slate-700">
                      {prospect.status === "new" ? "Nuevo" : prospect.status}
                    </span>
                    <span className="text-xs text-slate-500">{prospect.source || "Origen no indicado"}</span>
                  </article>
                );
              })}
            </div>
          ) : (
            <div className="p-8 text-sm text-slate-500">
              {prospects.length ? "No hay prospectos que coincidan con la búsqueda." : "No hay prospectos registrados."}
            </div>
          )}
        </section>
      )}
    </>
  );
}
