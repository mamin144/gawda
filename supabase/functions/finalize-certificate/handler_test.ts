import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { handleFinalize } from "./handler.ts";
import { bearerToken } from "../_shared/auth.ts";

const USER_ID = "11111111-1111-4111-8111-111111111111";
const CERT_ID = "22222222-2222-4222-8222-222222222222";
const JWT = "header.payload.signature";

type RpcResult = { data: unknown; error: { message: string } | null };
type RemoveResult = { data: unknown; error: { message: string } | null };

interface FakeOptions {
  user?: { id: string } | null;
  userError?: { message: string } | null;
  finalize?: RpcResult;
  record?: (args: Record<string, unknown>) => RpcResult;
  remove?: (paths: string[]) => RemoveResult;
}

// Fake user and service clients that log every call in order.
function fakes(opts: FakeOptions = {}) {
  const calls: string[] = [];
  const rpcArgs: Array<[string, Record<string, unknown>]> = [];
  const jwts: string[] = [];

  const userClient = (jwt: string) => {
    jwts.push(jwt);
    return {
      auth: {
        getUser: (token?: string) => {
          calls.push(`getUser:${token}`);
          return Promise.resolve({
            data: {
              user: opts.userError
                ? null
                : (opts.user === undefined ? { id: USER_ID } : opts.user),
            },
            error: opts.userError ?? null,
          });
        },
      },
    } as unknown as SupabaseClient;
  };

  const serviceClient = {
    rpc: (name: string, args: Record<string, unknown>) => {
      calls.push(
        `rpc:${name}:${(args.p_attachment_id ?? args.p_id) as string}`,
      );
      rpcArgs.push([name, args]);
      if (name === "finalize_with_signed_copy") {
        return Promise.resolve(opts.finalize ?? { data: [], error: null });
      }
      return Promise.resolve(
        opts.record ? opts.record(args) : { data: null, error: null },
      );
    },
    storage: {
      from: (bucket: string) => ({
        remove: (paths: string[]) => {
          calls.push(`remove:${bucket}:${paths.join(",")}`);
          return Promise.resolve(
            opts.remove
              ? opts.remove(paths)
              : { data: [{ name: paths[0] }], error: null },
          );
        },
      }),
    },
  } as unknown as SupabaseClient;

  return { deps: { userClient, serviceClient }, calls, rpcArgs, jwts };
}

function post(body: unknown, auth: string | null = `Bearer ${JWT}`): Request {
  const headers = new Headers({ "content-type": "application/json" });
  if (auth !== null) headers.set("authorization", auth);
  return new Request("http://localhost/finalize-certificate", {
    method: "POST",
    headers,
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

async function json(res: Response): Promise<unknown> {
  assertEquals(res.headers.get("content-type"), "application/json");
  return await res.json();
}

const rpcError = (message: string): RpcResult => ({
  data: null,
  error: { message },
});

// ---------------------------------------------------------------------------
// bearerToken
// ---------------------------------------------------------------------------
Deno.test("bearerToken: extracts the token with a case-insensitive scheme", () => {
  const req = (v: string) =>
    new Request("http://x", { headers: { authorization: v } });
  assertEquals(bearerToken(req("Bearer abc")), "abc");
  assertEquals(bearerToken(req("bearer abc")), "abc");
  assertEquals(bearerToken(req("BEARER   abc  ")), "abc");
});

Deno.test("bearerToken: missing, empty or non-bearer header is null", () => {
  const req = (v?: string) =>
    new Request("http://x", {
      headers: v === undefined ? {} : { authorization: v },
    });
  assertEquals(bearerToken(req()), null);
  assertEquals(bearerToken(req("")), null);
  assertEquals(bearerToken(req("Bearer")), null);
  assertEquals(bearerToken(req("Bearer   ")), null);
  assertEquals(bearerToken(req("Basic abc")), null);
  assertEquals(bearerToken(req("Bearer a b")), null);
});

// ---------------------------------------------------------------------------
// handleFinalize
// ---------------------------------------------------------------------------
Deno.test("401 without a JWT, no client is used", async () => {
  const f = fakes();
  const res = await handleFinalize(
    post({ certificate_id: CERT_ID }, null),
    f.deps,
  );
  assertEquals(res.status, 401);
  assertEquals(await json(res), { error: "unauthorized" });
  assertEquals(f.calls, []);
  assertEquals(f.jwts, []);
});

Deno.test("401 when getUser returns an error, no RPC is called", async () => {
  const f = fakes({ userError: { message: "invalid JWT" } });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 401);
  assertEquals(await json(res), { error: "unauthorized" });
  assertEquals(f.calls, [`getUser:${JWT}`]);
});

Deno.test("401 when getUser returns no user", async () => {
  const f = fakes({ user: null });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 401);
  assertEquals(await json(res), { error: "unauthorized" });
  assertEquals(f.calls, [`getUser:${JWT}`]);
});

Deno.test("405 for a non-POST request", async () => {
  const f = fakes();
  const res = await handleFinalize(
    new Request("http://localhost/finalize-certificate", {
      method: "GET",
      headers: { authorization: `Bearer ${JWT}` },
    }),
    f.deps,
  );
  assertEquals(res.status, 405);
  assertEquals(await json(res), { error: "method_not_allowed" });
  assertEquals(f.calls, []);
});

Deno.test("400 when the body is not JSON", async () => {
  const f = fakes();
  const res = await handleFinalize(post("{not json"), f.deps);
  assertEquals(res.status, 400);
  assertEquals(await json(res), { error: "invalid_request" });
  assertEquals(f.calls.filter((c) => c.startsWith("rpc")), []);
});

Deno.test("400 when certificate_id is missing or not a uuid string", async () => {
  for (
    const body of [
      {},
      { certificate_id: 42 },
      { certificate_id: "not-a-uuid" },
      [],
      null,
    ]
  ) {
    const f = fakes();
    const res = await handleFinalize(post(body), f.deps);
    assertEquals(res.status, 400, JSON.stringify(body));
    assertEquals(await json(res), { error: "invalid_request" });
    assertEquals(f.calls.filter((c) => c.startsWith("rpc")), []);
  }
});

Deno.test("403 maps from an RPC forbidden", async () => {
  const f = fakes({ finalize: rpcError("forbidden") });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 403);
  assertEquals(await json(res), { error: "forbidden" });
});

Deno.test("404 maps from an RPC not_found", async () => {
  const f = fakes({ finalize: rpcError("not_found") });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 404);
  assertEquals(await json(res), { error: "not_found" });
});

Deno.test("409 maps from invalid_transition and signed_copy_missing", async () => {
  for (const code of ["invalid_transition", "signed_copy_missing"]) {
    const f = fakes({ finalize: rpcError(code) });
    const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
    assertEquals(res.status, 409);
    assertEquals(await json(res), { error: code });
    assertEquals(f.calls.filter((c) => c.startsWith("remove")), []);
  }
});

Deno.test("500 internal_error for any other RPC error, without details", async () => {
  const f = fakes({
    finalize: rpcError(
      'permission denied for table certificates at "secret detail"',
    ),
  });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "internal_error" });
});

Deno.test("a storage failure gives 500 and does not call record_initial_file_deleted", async () => {
  const f = fakes({
    finalize: {
      data: [
        { attachment_id: "a1", storage_path: "s/2026/1/1/one.pdf" },
        { attachment_id: "a2", storage_path: "s/2026/1/1/two.pdf" },
      ],
      error: null,
    },
    remove: () => ({ data: null, error: { message: "storage down" } }),
  });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "initial_delete_failed" });
  assertEquals(f.calls, [
    `getUser:${JWT}`,
    `rpc:finalize_with_signed_copy:${CERT_ID}`,
    "remove:certificates:s/2026/1/1/one.pdf",
  ]);
});

Deno.test("happy path: finalize, then remove -> record per file in order", async () => {
  const f = fakes({
    finalize: {
      data: [
        { attachment_id: "a1", storage_path: "s/2026/1/1/one.pdf" },
        { attachment_id: "a2", storage_path: "s/2026/1/1/two.pdf" },
      ],
      error: null,
    },
  });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 200);
  assertEquals(await json(res), { status: "approved", deleted_initial: 2 });
  assertEquals(f.jwts, [JWT]);
  assertEquals(f.calls, [
    `getUser:${JWT}`,
    `rpc:finalize_with_signed_copy:${CERT_ID}`,
    "remove:certificates:s/2026/1/1/one.pdf",
    "rpc:record_initial_file_deleted:a1",
    "remove:certificates:s/2026/1/1/two.pdf",
    "rpc:record_initial_file_deleted:a2",
  ]);
  assertEquals(f.rpcArgs, [
    ["finalize_with_signed_copy", { p_id: CERT_ID, p_actor: USER_ID }],
    ["record_initial_file_deleted", {
      p_attachment_id: "a1",
      p_actor: USER_ID,
    }],
    ["record_initial_file_deleted", {
      p_attachment_id: "a2",
      p_actor: USER_ID,
    }],
  ]);
});

Deno.test("happy path with no initial files left (retry) returns deleted_initial 0", async () => {
  const f = fakes({ finalize: { data: [], error: null } });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 200);
  assertEquals(await json(res), { status: "approved", deleted_initial: 0 });
});

Deno.test("a record RPC error stops and maps like other RPC errors", async () => {
  const f = fakes({
    finalize: {
      data: [
        { attachment_id: "a1", storage_path: "s/2026/1/1/one.pdf" },
        { attachment_id: "a2", storage_path: "s/2026/1/1/two.pdf" },
      ],
      error: null,
    },
    record: () => rpcError("invalid_transition"),
  });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 409);
  assertEquals(await json(res), { error: "invalid_transition" });
  assertEquals(f.calls.filter((c) => c.startsWith("remove")), [
    "remove:certificates:s/2026/1/1/one.pdf",
  ]);
});

Deno.test("a thrown storage remove is treated as initial_delete_failed", async () => {
  const f = fakes({
    finalize: {
      data: [{ attachment_id: "a1", storage_path: "s/2026/1/1/one.pdf" }],
      error: null,
    },
    remove: () => {
      throw new Error("network down");
    },
  });
  const res = await handleFinalize(post({ certificate_id: CERT_ID }), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "initial_delete_failed" });
  assertEquals(f.calls.filter((c) => c.includes("record_initial")), []);
});
