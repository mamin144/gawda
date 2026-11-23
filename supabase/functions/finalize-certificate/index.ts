// Wiring only: builds the Supabase clients from the platform-provided env vars
// and delegates to handleFinalize. Keys and the caller's JWT are never logged.
//
// Env vars (Supabase docs, "Environment variables" for Edge Functions):
// SUPABASE_URL, SUPABASE_PUBLISHABLE_KEYS and SUPABASE_SECRET_KEYS (JSON
// objects keyed by key name; the "default" key is used). No fallback to the
// legacy SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY.
import { createClient } from "@supabase/supabase-js";
import { handleFinalize } from "./handler.ts";

function defaultKey(name: string): string | null {
  const raw = Deno.env.get(name);
  if (!raw) return null;
  try {
    const parsed: unknown = JSON.parse(raw);
    if (parsed !== null && typeof parsed === "object") {
      const key = (parsed as Record<string, unknown>).default;
      if (typeof key === "string" && key.length > 0) return key;
    }
  } catch {
    // fall through: treated as missing
  }
  return null;
}

const CLIENT_OPTIONS = {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
    detectSessionInUrl: false,
  },
};

function misconfigured(): Response {
  return new Response(JSON.stringify({ error: "server_misconfigured" }), {
    status: 500,
    headers: { "content-type": "application/json" },
  });
}

Deno.serve((req) => {
  const url = Deno.env.get("SUPABASE_URL");
  const publishableKey = defaultKey("SUPABASE_PUBLISHABLE_KEYS");
  const secretKey = defaultKey("SUPABASE_SECRET_KEYS");
  if (!url || !publishableKey || !secretKey) return misconfigured();

  return handleFinalize(req, {
    userClient: (jwt: string) =>
      createClient(url, publishableKey, {
        ...CLIENT_OPTIONS,
        global: { headers: { Authorization: `Bearer ${jwt}` } },
      }),
    serviceClient: createClient(url, secretKey, CLIENT_OPTIONS),
  });
});
