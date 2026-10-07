import { createClient } from "@/lib/supabase/server";
import { handleAssistantPost } from "@/lib/ai/assistant-handler";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  return handleAssistantPost(request, createClient);
}
