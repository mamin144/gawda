import type { SupabaseClient } from "@supabase/supabase-js";
import { bearerToken } from "../_shared/auth.ts";

export interface FinalizeDeps {
  // Client bound to the caller's JWT; used only to validate it (getUser).
  userClient(jwt: string): SupabaseClient;
  // service_role client; used for the service-only RPCs and storage delete.
  serviceClient: SupabaseClient;
}

const BUCKET = "certificates";
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Stable error codes raised by the SQL functions, mapped to HTTP statuses.
// Anything else is reported as internal_error without details.
const RPC_ERROR_STATUS: Record<string, number> = {
  forbidden: 403,
  not_found: 404,
  invalid_transition: 409,
  signed_copy_missing: 409,
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function rpcErrorResponse(error: { message?: string }): Response {
  const code = error.message ?? "";
  const status = RPC_ERROR_STATUS[code];
  return status
    ? json(status, { error: code })
    : json(500, { error: "internal_error" });
}

interface InitialRow {
  attachment_id: string;
  storage_path: string;
}

export async function handleFinalize(
  req: Request,
  deps: FinalizeDeps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }

  const jwt = bearerToken(req);
  if (!jwt) return json(401, { error: "unauthorized" });

  try {
    // Authenticate before looking at the body.
    const { data: userData, error: userError } = await deps.userClient(jwt).auth
      .getUser(jwt);
    const user = userData?.user;
    if (userError || !user) return json(401, { error: "unauthorized" });

    let certificateId: unknown;
    try {
      const body = await req.json();
      certificateId =
        body !== null && typeof body === "object" && !Array.isArray(body)
          ? (body as Record<string, unknown>).certificate_id
          : undefined;
    } catch {
      return json(400, { error: "invalid_request" });
    }
    if (typeof certificateId !== "string" || !UUID_RE.test(certificateId)) {
      return json(400, { error: "invalid_request" });
    }

    const service = deps.serviceClient;
    const { data, error } = await service.rpc("finalize_with_signed_copy", {
      p_id: certificateId,
      p_actor: user.id,
    });
    if (error) return rpcErrorResponse(error);

    const rows = (data ?? []) as InitialRow[];
    let deleted = 0;
    for (const row of rows) {
      // Delete the storage object first; only then record the metadata. On a
      // storage failure stop: the certificate stays approved and a retry
      // returns the remaining initial files.
      let removeFailed = false;
      try {
        const { error: removeError } = await service.storage.from(BUCKET)
          .remove([row.storage_path]);
        removeFailed = Boolean(removeError);
      } catch {
        removeFailed = true;
      }
      if (removeFailed) return json(500, { error: "initial_delete_failed" });

      const { error: recordError } = await service.rpc(
        "record_initial_file_deleted",
        {
          p_attachment_id: row.attachment_id,
          p_actor: user.id,
        },
      );
      if (recordError) return rpcErrorResponse(recordError);
      deleted++;
    }

    return json(200, { status: "approved", deleted_initial: deleted });
  } catch {
    return json(500, { error: "internal_error" });
  }
}
