import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  try {
    const supabase = await createClient();
    const auth = await supabase.auth.getUser();
    if (!auth.data.user) return NextResponse.json({ error: "No autorizado" }, { status: 401 });

    const body = await request.json();
    const question = String(body.question || "").trim();
    if (!question) return NextResponse.json({ error: "Escribi una pregunta." }, { status: 400 });

    const results = await Promise.all([
      supabase.from("tasks").select("title,area,task_type,due_date,client_waiting_days,estimated_minutes,status,priority,last_activity_at,created_at").order("created_at", { ascending: false }).limit(80),
      supabase.from("clients").select("name,service,owner_name,contact_name,status,notes").order("name").limit(80),
      supabase.from("followups").select("status,next_action,next_followup_at,last_movement_at,notes").order("next_followup_at").limit(80)
    ]);

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) return NextResponse.json({ error: "Gemini no esta configurado." }, { status: 500 });

    const context = JSON.stringify({ tasks: results[0].data || [], clients: results[1].data || [], followups: results[2].data || [] });
    const instruction = "Sos el asistente interno de Gestion eQuantum. Responde en espanol claro, directo y profesional. Usa solamente los datos suministrados. No inventes informacion. Si faltan datos, decilo. Detecta atrasos, riesgos, falta de seguimiento y prioridades. IMPORTANTE: responde exclusivamente en texto plano. No uses Markdown, encabezados con #, asteriscos, guiones separadores ni tablas. No empieces con frases como Con base en los datos suministrados. Empeza directamente por la respuesta. Para prioridades usa una lista numerada simple, por ejemplo 1. Tarea - motivo. No ejecutes cambios; solo analiza y recomienda. DATOS: " + context + " PREGUNTA: " + question;

    const endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent";
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({
        contents: [{ parts: [{ text: instruction }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 450 }
      }),
      signal: AbortSignal.timeout(8000)
    });

    const data = await response.json();
    if (response.ok) {
      const answer = data?.candidates?.[0]?.content?.parts
        ?.map((part: { text?: string }) => part.text || "")
        .join("")
        .trim();
      return NextResponse.json({ answer: answer || "Sin respuesta." });
    }

    return NextResponse.json(
      { error: "eQ no pudo responder ahora. Proba nuevamente." },
      { status: response.status === 429 || response.status === 503 ? 503 : 500 }
    );
  } catch {
    return NextResponse.json({ error: "No se pudo consultar a Gemini." }, { status: 500 });
  }
}
