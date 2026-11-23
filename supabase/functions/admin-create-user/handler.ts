import type { SupabaseClient } from "@supabase/supabase-js";
import { bearerToken } from "../_shared/auth.ts";

export interface CreateUserDeps {
  // Client bound to the caller's JWT: validates it (getUser) and reads the
  // caller's own profile under RLS.
  userClient(jwt: string): SupabaseClient;
  // service_role client: invite, profile/user_sites writes, audit RPC and
  // compensation.
  serviceClient: SupabaseClient;
  // INVITE_REDIRECT_URL function secret. Missing or empty -> config_missing.
  inviteRedirectUrl: string | undefined;
}

const ROLES = new Set(["admin", "site_user"]);
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// Simple sanity check only; the invite itself is the real proof of the address.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const EMAIL_MAX = 254;
// Auth error codes meaning the email is already registered.
const USER_EXISTS_CODES = new Set(["email_exists", "user_already_exists"]);

interface CreateUserInput {
  email: string;
  fullName: string;
  role: "admin" | "site_user";
  siteIds: string[];
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

// Returns the normalized input, or null when the body is invalid.
function parseInput(body: unknown): CreateUserInput | null {
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    return null;
  }
  const b = body as Record<string, unknown>;

  if (typeof b.email !== "string") return null;
  const email = b.email.trim().toLowerCase();
  if (email.length > EMAIL_MAX || !EMAIL_RE.test(email)) return null;

  if (typeof b.full_name !== "string") return null;
  const fullName = b.full_name.trim();
  if (fullName.length === 0) return null;

  if (typeof b.role !== "string" || !ROLES.has(b.role)) return null;
  const role = b.role as CreateUserInput["role"];

  let siteIds: string[] = [];
  if (b.site_ids !== undefined) {
    if (!Array.isArray(b.site_ids)) return null;
    for (const id of b.site_ids) {
      if (typeof id !== "string" || !UUID_RE.test(id)) return null;
    }
    siteIds = (b.site_ids as string[]).map((id) => id.toLowerCase());
    if (new Set(siteIds).size !== siteIds.length) return null;
  }
  // Admins see every site; a mapping for them is meaningless.
  if (role === "admin" && siteIds.length > 0) return null;

  return { email, fullName, role, siteIds };
}

// Reverse-order cleanup after a failure that followed a successful invite.
// Stops at the first failed step (later steps would hit the FKs) and logs
// only the user id and the step name.
async function compensate(
  service: SupabaseClient,
  userId: string,
  done: { profile: boolean; sites: boolean },
): Promise<void> {
  const steps: Array<[string, () => PromiseLike<{ error: unknown }>]> = [];
  if (done.sites) {
    steps.push([
      "delete_user_sites",
      () => service.from("user_sites").delete().eq("user_id", userId),
    ]);
  }
  if (done.profile) {
    steps.push([
      "delete_profile",
      () => service.from("profiles").delete().eq("id", userId),
    ]);
  }
  steps.push([
    "delete_auth_user",
    () => service.auth.admin.deleteUser(userId),
  ]);

  for (const [step, run] of steps) {
    let failed: boolean;
    try {
      const { error } = await run();
      failed = Boolean(error);
    } catch {
      failed = true;
    }
    if (failed) {
      console.error("admin-create-user: compensation failed", {
        user_id: userId,
        step,
      });
      return;
    }
  }
}

export async function handleCreateUser(
  req: Request,
  deps: CreateUserDeps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }

  const jwt = bearerToken(req);
  if (!jwt) return json(401, { error: "unauthorized" });

  try {
    // Authenticate before looking at the body.
    const userClient = deps.userClient(jwt);
    const { data: userData, error: userError } = await userClient.auth
      .getUser(jwt);
    const caller = userData?.user;
    if (userError || !caller) return json(401, { error: "unauthorized" });

    // Authorize from the profile row only (never user_metadata), read with
    // the caller's client so RLS applies: an inactive user cannot see its
    // own row, so it is rejected like a missing profile.
    const { data: profile, error: profileError } = await userClient
      .from("profiles")
      .select("role, is_active")
      .eq("id", caller.id)
      .maybeSingle();
    if (profileError) return json(500, { error: "internal_error" });
    if (
      !profile || profile.role !== "admin" || profile.is_active !== true
    ) {
      return json(403, { error: "forbidden" });
    }

    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return json(400, { error: "invalid_request" });
    }
    const input = parseInput(body);
    if (!input) return json(400, { error: "invalid_request" });

    // No fallback URL: a missing secret must not send invites anywhere else.
    const redirectTo = deps.inviteRedirectUrl;
    if (!redirectTo) return json(500, { error: "config_missing" });

    const service = deps.serviceClient;
    // Only redirectTo: role and sites never go into user_metadata.
    const { data: invited, error: inviteError } = await service.auth.admin
      .inviteUserByEmail(input.email, { redirectTo });
    if (inviteError) {
      return USER_EXISTS_CODES.has(inviteError.code ?? "")
        ? json(409, { error: "user_exists" })
        : json(500, { error: "internal_error" });
    }
    const newId = invited?.user?.id;
    if (!newId) return json(500, { error: "internal_error" });

    const done = { profile: false, sites: false };
    try {
      const { error: insertProfileError } = await service.from("profiles")
        .insert({ id: newId, full_name: input.fullName, role: input.role });
      if (insertProfileError) throw new Error("profile");
      done.profile = true;

      if (input.siteIds.length > 0) {
        // Marked before the call: a reported failure may still have
        // committed, and the rows can only belong to this new profile.
        done.sites = true;
        const { error: sitesError } = await service.from("user_sites").insert(
          input.siteIds.map((siteId) => ({ user_id: newId, site_id: siteId })),
        );
        if (sitesError) throw new Error("user_sites");
      }

      const { error: auditError } = await service.rpc("audit_user_created", {
        p_user: newId,
        p_actor: caller.id,
      });
      if (auditError) throw new Error("audit");
    } catch {
      await compensate(service, newId, done);
      return json(500, { error: "create_failed" });
    }

    return json(201, { id: newId });
  } catch {
    return json(500, { error: "internal_error" });
  }
}
