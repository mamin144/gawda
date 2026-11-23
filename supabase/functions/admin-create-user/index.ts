// Wiring only: builds the Supabase clients from the platform-provided env vars
// and delegates to handleCreateUser. Keys, the caller's JWT and the invited
// email are never logged.
//
// Env vars (Supabase docs, "Environment variables" for Edge Functions):
// SUPABASE_URL, SUPABASE_PUBLISHABLE_KEYS and SUPABASE_SECRET_KEYS (JSON
// objects keyed by key name; the "default" key is used). No fallback to the
// legacy SUPABASE_ANON_KEY / SUPABASE_SERVICE_ROLE_KEY.
// INVITE_REDIRECT_URL is a function secret set by the owner; when it is
// missing the handler answers 500 config_missing (no fallback URL).
import { createClient } from "@supabase/supabase-js";
import { parseDefaultKey } from "../_shared/env.ts";
import { handleCreateUser } from "./handler.ts";

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
  const publishableKey = parseDefaultKey(
    Deno.env.get("SUPABASE_PUBLISHABLE_KEYS"),
  );
  const secretKey = parseDefaultKey(Deno.env.get("SUPABASE_SECRET_KEYS"));
  if (!url || !publishableKey || !secretKey) return misconfigured();

  return handleCreateUser(req, {
    userClient: (jwt: string) =>
      createClient(url, publishableKey, {
        ...CLIENT_OPTIONS,
        global: { headers: { Authorization: `Bearer ${jwt}` } },
      }),
    serviceClient: createClient(url, secretKey, CLIENT_OPTIONS),
    inviteRedirectUrl: Deno.env.get("INVITE_REDIRECT_URL"),
  });
});
