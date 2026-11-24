import { assertEquals } from "@std/assert";
import type { SupabaseClient } from "@supabase/supabase-js";
import { handleCreateUser } from "./handler.ts";

const ADMIN_ID = "11111111-1111-4111-8111-111111111111";
const NEW_ID = "22222222-2222-4222-8222-222222222222";
const SITE_A = "33333333-3333-4333-8333-333333333333";
const SITE_B = "44444444-4444-4444-8444-444444444444";
const JWT = "header.payload.signature";
const REDIRECT = "https://app.example.test/invite";

type Result = { data: unknown; error: Record<string, unknown> | null };
const ok = (data: unknown = null): Result => ({ data, error: null });
const fail = (error: Record<string, unknown>): Result => ({
  data: null,
  error,
});

interface FakeOptions {
  user?: { id: string } | null;
  userError?: { message: string } | null;
  // The caller's own profile as RLS lets the user client see it.
  callerProfile?: { role: string; is_active: boolean } | null;
  invite?: Result;
  profileInsert?: Result;
  sitesInsert?: Result;
  audit?: Result;
  sitesDelete?: Result;
  profileDelete?: Result;
  deleteUser?: Result;
  throwOnInvite?: boolean;
  // Service-side sites table; the fake applies the handler's filters.
  sites?: SiteRow[];
  sitesSelectError?: Record<string, unknown>;
  // Result of rpc('auth_user_exists').
  userExists?: Result;
}

interface SiteRow {
  id: string;
  is_active: boolean;
  archived_at: string | null;
}

const ACTIVE_SITES: SiteRow[] = [
  { id: SITE_A, is_active: true, archived_at: null },
  { id: SITE_B, is_active: true, archived_at: null },
];

// Fake user and service clients that log every call in order.
function fakes(
  opts: FakeOptions = {},
  config: { redirect: string | undefined } = { redirect: REDIRECT },
) {
  const redirect = config.redirect;
  const calls: string[] = [];
  const inserts: Array<[string, unknown]> = [];
  const rpcArgs: Array<[string, Record<string, unknown>]> = [];
  const invites: Array<[string, unknown]> = [];
  const jwts: string[] = [];
  const siteFilters: string[][] = [];

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
                : (opts.user === undefined ? { id: ADMIN_ID } : opts.user),
            },
            error: opts.userError ?? null,
          });
        },
      },
      from: (table: string) => ({
        select: (cols: string) => ({
          eq: (col: string, val: string) => ({
            maybeSingle: () => {
              calls.push(`user:select:${table}:${cols}:${col}=${val}`);
              const profile = opts.callerProfile === undefined
                ? { role: "admin", is_active: true }
                : opts.callerProfile;
              return Promise.resolve(ok(profile));
            },
          }),
        }),
      }),
    } as unknown as SupabaseClient;
  };

  const serviceClient = {
    auth: {
      admin: {
        inviteUserByEmail: (email: string, options: unknown) => {
          calls.push("invite");
          invites.push([email, options]);
          if (opts.throwOnInvite) return Promise.reject(new Error("network"));
          return Promise.resolve(
            opts.invite ?? ok({ user: { id: NEW_ID, email } }),
          );
        },
        deleteUser: (id: string) => {
          calls.push(`deleteUser:${id}`);
          return Promise.resolve(opts.deleteUser ?? ok({ user: null }));
        },
      },
    },
    from: (table: string) => ({
      // Thenable query builder supporting .in / .eq / .is filters.
      select: (cols: string) => {
        const filters: string[] = [];
        const preds: Array<(row: Record<string, unknown>) => boolean> = [];
        const builder = {
          in: (col: string, vals: unknown[]) => {
            filters.push(`in:${col}:${vals.join(",")}`);
            preds.push((r) => vals.includes(r[col]));
            return builder;
          },
          eq: (col: string, val: unknown) => {
            filters.push(`eq:${col}:${val}`);
            preds.push((r) => r[col] === val);
            return builder;
          },
          is: (col: string, val: unknown) => {
            filters.push(`is:${col}:${val}`);
            preds.push((r) => r[col] === val);
            return builder;
          },
          then: (
            resolve: (r: Result) => unknown,
            reject?: (e: unknown) => unknown,
          ) => {
            calls.push(`select:${table}:${cols}`);
            siteFilters.push(filters);
            const rows = (opts.sites ?? ACTIVE_SITES) as unknown as Array<
              Record<string, unknown>
            >;
            const r = opts.sitesSelectError ? fail(opts.sitesSelectError) : ok(
              rows.filter((row) => preds.every((p) => p(row))).map((
                row,
              ) => ({ id: row.id })),
            );
            return Promise.resolve(r).then(resolve, reject);
          },
        };
        return builder;
      },
      insert: (rows: unknown) => {
        calls.push(`insert:${table}`);
        inserts.push([table, rows]);
        const r = table === "profiles" ? opts.profileInsert : opts.sitesInsert;
        return Promise.resolve(r ?? ok());
      },
      delete: () => ({
        eq: (col: string, val: string) => {
          calls.push(`delete:${table}:${col}=${val}`);
          const r = table === "profiles"
            ? opts.profileDelete
            : opts.sitesDelete;
          return Promise.resolve(r ?? ok());
        },
      }),
    }),
    rpc: (name: string, args: Record<string, unknown>) => {
      calls.push(`rpc:${name}`);
      rpcArgs.push([name, args]);
      if (name === "auth_user_exists") {
        return Promise.resolve(opts.userExists ?? ok(false));
      }
      return Promise.resolve(opts.audit ?? ok());
    },
  } as unknown as SupabaseClient;

  return {
    deps: { userClient, serviceClient, inviteRedirectUrl: redirect },
    calls,
    inserts,
    rpcArgs,
    invites,
    jwts,
    siteFilters,
  };
}

function post(
  body: unknown,
  auth: string | null = `Bearer ${JWT}`,
  method = "POST",
): Request {
  const headers = new Headers({ "content-type": "application/json" });
  if (auth !== null) headers.set("authorization", auth);
  return new Request("http://localhost/admin-create-user", {
    method,
    headers,
    body: method === "GET"
      ? undefined
      : typeof body === "string"
      ? body
      : JSON.stringify(body),
  });
}

async function json(res: Response): Promise<unknown> {
  assertEquals(res.headers.get("content-type"), "application/json");
  return await res.json();
}

const SITE_USER_BODY = {
  email: "  New.User@Example.TEST ",
  full_name: "  New User  ",
  role: "site_user",
  site_ids: [SITE_A, SITE_B],
};

const CALLER_CHECK = [
  `getUser:${JWT}`,
  `user:select:profiles:role, is_active:id=${ADMIN_ID}`,
];

const SITES_SELECT = "select:sites:id";
const EXISTS_RPC = "rpc:auth_user_exists";
// Pre-invite checks for SITE_USER_BODY (sites, then email) and for an admin
// body without sites (email only).
const PRE_INVITE_SITE_USER = [...CALLER_CHECK, SITES_SELECT, EXISTS_RPC];
const PRE_INVITE_ADMIN = [...CALLER_CHECK, EXISTS_RPC];

// ---------------------------------------------------------------------------
// Method and authentication
// ---------------------------------------------------------------------------
Deno.test("405 for a non-POST request, no client is used", async () => {
  const f = fakes();
  const res = await handleCreateUser(post(null, undefined, "GET"), f.deps);
  assertEquals(res.status, 405);
  assertEquals(await json(res), { error: "method_not_allowed" });
  assertEquals(f.calls, []);
});

Deno.test("401 without a JWT, no client is used", async () => {
  const f = fakes();
  const res = await handleCreateUser(post(SITE_USER_BODY, null), f.deps);
  assertEquals(res.status, 401);
  assertEquals(await json(res), { error: "unauthorized" });
  assertEquals(f.calls, []);
  assertEquals(f.jwts, []);
});

Deno.test("401 when getUser returns an error", async () => {
  const f = fakes({ userError: { message: "invalid JWT" } });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 401);
  assertEquals(await json(res), { error: "unauthorized" });
  assertEquals(f.calls, [`getUser:${JWT}`]);
});

Deno.test("401 when getUser returns no user", async () => {
  const f = fakes({ user: null });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 401);
  assertEquals(f.calls, [`getUser:${JWT}`]);
});

// ---------------------------------------------------------------------------
// Authorization (caller profile read through the caller's user client)
// ---------------------------------------------------------------------------
Deno.test("403 for a site_user caller, nothing is created", async () => {
  const f = fakes({ callerProfile: { role: "site_user", is_active: true } });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 403);
  assertEquals(await json(res), { error: "forbidden" });
  assertEquals(f.calls, CALLER_CHECK);
  assertEquals(f.jwts, [JWT]);
});

Deno.test("403 for an inactive admin caller", async () => {
  const f = fakes({ callerProfile: { role: "admin", is_active: false } });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 403);
  assertEquals(await json(res), { error: "forbidden" });
  assertEquals(f.calls, CALLER_CHECK);
});

Deno.test("403 when the caller has no visible profile", async () => {
  const f = fakes({ callerProfile: null });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 403);
  assertEquals(await json(res), { error: "forbidden" });
  assertEquals(f.calls, CALLER_CHECK);
});

// ---------------------------------------------------------------------------
// Body validation (after authorization, before any write)
// ---------------------------------------------------------------------------
Deno.test("400 when the body is not JSON", async () => {
  const f = fakes();
  const res = await handleCreateUser(post("{not json"), f.deps);
  assertEquals(res.status, 400);
  assertEquals(await json(res), { error: "invalid_request" });
  assertEquals(f.calls, CALLER_CHECK);
});

Deno.test("400 for invalid bodies, nothing is invited", async () => {
  const cases: unknown[] = [
    null,
    [],
    "text",
    { ...SITE_USER_BODY, email: undefined },
    { ...SITE_USER_BODY, email: 42 },
    { ...SITE_USER_BODY, email: "" },
    { ...SITE_USER_BODY, email: "no-at-sign" },
    { ...SITE_USER_BODY, email: "a@b" },
    { ...SITE_USER_BODY, email: "a b@example.test" },
    { ...SITE_USER_BODY, email: "a@@example.test" },
    { ...SITE_USER_BODY, email: `${"a".repeat(250)}@example.test` },
    { ...SITE_USER_BODY, full_name: undefined },
    { ...SITE_USER_BODY, full_name: "" },
    { ...SITE_USER_BODY, full_name: "   " },
    { ...SITE_USER_BODY, full_name: 7 },
    { ...SITE_USER_BODY, role: undefined },
    { ...SITE_USER_BODY, role: "superuser" },
    { ...SITE_USER_BODY, role: "Admin" },
    { ...SITE_USER_BODY, site_ids: null },
    { ...SITE_USER_BODY, site_ids: SITE_A },
    { ...SITE_USER_BODY, site_ids: ["not-a-uuid"] },
    { ...SITE_USER_BODY, site_ids: [SITE_A, 5] },
    { ...SITE_USER_BODY, site_ids: [SITE_A, SITE_A] },
    { ...SITE_USER_BODY, site_ids: [SITE_A, SITE_A.toUpperCase()] },
    {
      email: "a@example.test",
      full_name: "A",
      role: "admin",
      site_ids: [SITE_A],
    },
  ];
  for (const body of cases) {
    const f = fakes();
    const res = await handleCreateUser(post(body), f.deps);
    assertEquals(res.status, 400, `body: ${JSON.stringify(body)}`);
    assertEquals(await json(res), { error: "invalid_request" });
    assertEquals(f.calls, CALLER_CHECK, `body: ${JSON.stringify(body)}`);
  }
});

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
Deno.test("500 config_missing when INVITE_REDIRECT_URL is missing, no invite", async () => {
  for (const redirect of [undefined, ""]) {
    const f = fakes({}, { redirect });
    const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
    assertEquals(res.status, 500);
    assertEquals(await json(res), { error: "config_missing" });
    assertEquals(f.calls, CALLER_CHECK);
  }
});

// ---------------------------------------------------------------------------
// Happy paths
// ---------------------------------------------------------------------------
Deno.test("201 site_user: invite, profile, user_sites, audit in order", async () => {
  const f = fakes();
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 201);
  assertEquals(await json(res), { id: NEW_ID });
  assertEquals(f.calls, [
    ...PRE_INVITE_SITE_USER,
    "invite",
    "insert:profiles",
    "insert:user_sites",
    "rpc:audit_user_created",
  ]);
  // Email trimmed and lowercased; only redirectTo is passed (no user_metadata).
  assertEquals(f.invites, [["new.user@example.test", {
    redirectTo: REDIRECT,
  }]]);
  assertEquals(f.inserts, [
    ["profiles", { id: NEW_ID, full_name: "New User", role: "site_user" }],
    ["user_sites", [
      { user_id: NEW_ID, site_id: SITE_A },
      { user_id: NEW_ID, site_id: SITE_B },
    ]],
  ]);
  assertEquals(f.rpcArgs, [
    ["auth_user_exists", { p_email: "new.user@example.test" }],
    ["audit_user_created", { p_user: NEW_ID, p_actor: ADMIN_ID }],
  ]);
});

Deno.test("201 admin without site_ids: no user_sites insert", async () => {
  const f = fakes();
  const res = await handleCreateUser(
    post({ email: "boss@example.test", full_name: "Boss", role: "admin" }),
    f.deps,
  );
  assertEquals(res.status, 201);
  assertEquals(await json(res), { id: NEW_ID });
  assertEquals(f.calls, [
    ...PRE_INVITE_ADMIN,
    "invite",
    "insert:profiles",
    "rpc:audit_user_created",
  ]);
  assertEquals(f.inserts, [
    ["profiles", { id: NEW_ID, full_name: "Boss", role: "admin" }],
  ]);
});

Deno.test("201 admin with an empty site_ids list", async () => {
  const f = fakes();
  const res = await handleCreateUser(
    post({
      email: "boss@example.test",
      full_name: "Boss",
      role: "admin",
      site_ids: [],
    }),
    f.deps,
  );
  assertEquals(res.status, 201);
  assertEquals(f.inserts.map(([t]) => t), ["profiles"]);
});

Deno.test("201 site_user with no site_ids (open question)", async () => {
  const f = fakes();
  const res = await handleCreateUser(
    post({ email: "s@example.test", full_name: "S", role: "site_user" }),
    f.deps,
  );
  assertEquals(res.status, 201);
  assertEquals(f.inserts.map(([t]) => t), ["profiles"]);
});

Deno.test("site ids are lowercased before insert", async () => {
  const f = fakes();
  const res = await handleCreateUser(
    post({ ...SITE_USER_BODY, site_ids: [SITE_A.toUpperCase()] }),
    f.deps,
  );
  assertEquals(res.status, 201);
  assertEquals(f.inserts[1], ["user_sites", [{
    user_id: NEW_ID,
    site_id: SITE_A,
  }]]);
});

// ---------------------------------------------------------------------------
// Invite failures (no user was created, nothing to compensate)
// ---------------------------------------------------------------------------
Deno.test("409 user_exists when the invite reports an already registered email", async () => {
  for (const code of ["email_exists", "user_already_exists"]) {
    const f = fakes({
      invite: fail({
        message: "A user with this email address has already been registered",
        status: 422,
        code,
      }),
    });
    const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
    assertEquals(res.status, 409);
    assertEquals(await json(res), { error: "user_exists" });
    assertEquals(f.calls, [...PRE_INVITE_SITE_USER, "invite"]);
  }
});

Deno.test("500 internal_error for any other invite error, without details", async () => {
  const f = fakes({
    invite: fail({
      message: "secret detail",
      status: 500,
      code: "unexpected_failure",
    }),
  });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "internal_error" });
  assertEquals(f.calls, [...PRE_INVITE_SITE_USER, "invite"]);
});

Deno.test("500 internal_error when the invite throws", async () => {
  const f = fakes({ throwOnInvite: true });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "internal_error" });
});

Deno.test("500 internal_error when the invite returns no user", async () => {
  const f = fakes({ invite: ok({ user: null }) });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "internal_error" });
  assertEquals(f.calls, [...PRE_INVITE_SITE_USER, "invite"]);
});

// ---------------------------------------------------------------------------
// Compensation (reverse order: user_sites, profile, auth user)
// ---------------------------------------------------------------------------
Deno.test("compensation: profile insert failure deletes the auth user", async () => {
  const f = fakes({ profileInsert: fail({ message: "boom", code: "23505" }) });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "create_failed" });
  assertEquals(f.calls, [
    ...PRE_INVITE_SITE_USER,
    "invite",
    "insert:profiles",
    `deleteUser:${NEW_ID}`,
  ]);
});

Deno.test("compensation: user_sites failure removes the profile before deleteUser", async () => {
  const f = fakes({ sitesInsert: fail({ message: "fk", code: "23503" }) });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "create_failed" });
  assertEquals(f.calls, [
    ...PRE_INVITE_SITE_USER,
    "invite",
    "insert:profiles",
    "insert:user_sites",
    // The attempted insert is cleaned up too (a reported failure may still
    // have committed); safe because the profile row was created by this call.
    `delete:user_sites:user_id=${NEW_ID}`,
    `delete:profiles:id=${NEW_ID}`,
    `deleteUser:${NEW_ID}`,
  ]);
});

Deno.test("compensation: audit failure removes user_sites, profile, then the auth user", async () => {
  const f = fakes({ audit: fail({ message: "forbidden" }) });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "create_failed" });
  assertEquals(f.calls, [
    ...PRE_INVITE_SITE_USER,
    "invite",
    "insert:profiles",
    "insert:user_sites",
    "rpc:audit_user_created",
    `delete:user_sites:user_id=${NEW_ID}`,
    `delete:profiles:id=${NEW_ID}`,
    `deleteUser:${NEW_ID}`,
  ]);
});

Deno.test("compensation: audit failure for an admin (no user_sites) skips that step", async () => {
  const f = fakes({ audit: fail({ message: "forbidden" }) });
  const res = await handleCreateUser(
    post({ email: "boss@example.test", full_name: "Boss", role: "admin" }),
    f.deps,
  );
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "create_failed" });
  assertEquals(f.calls, [
    ...PRE_INVITE_ADMIN,
    "invite",
    "insert:profiles",
    "rpc:audit_user_created",
    `delete:profiles:id=${NEW_ID}`,
    `deleteUser:${NEW_ID}`,
  ]);
});

Deno.test("compensation failure still returns create_failed and logs only id and step", async () => {
  const logged: unknown[][] = [];
  const original = console.error;
  console.error = (...args: unknown[]) => {
    logged.push(args);
  };
  try {
    const f = fakes({
      audit: fail({ message: "forbidden" }),
      profileDelete: fail({ message: "db down" }),
    });
    const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
    assertEquals(res.status, 500);
    assertEquals(await json(res), { error: "create_failed" });
    // Stops at the failed step: deleteUser would hit the profiles FK anyway.
    assertEquals(f.calls.slice(-2), [
      `delete:user_sites:user_id=${NEW_ID}`,
      `delete:profiles:id=${NEW_ID}`,
    ]);
    assertEquals(logged, [[
      "admin-create-user: compensation failed",
      { user_id: NEW_ID, step: "delete_profile" },
    ]]);
    const text = JSON.stringify(logged);
    assertEquals(text.includes("example.test"), false);
  } finally {
    console.error = original;
  }
});

Deno.test("compensation: a failed deleteUser is logged and still returns create_failed", async () => {
  const logged: unknown[][] = [];
  const original = console.error;
  console.error = (...args: unknown[]) => {
    logged.push(args);
  };
  try {
    const f = fakes({
      profileInsert: fail({ message: "boom" }),
      deleteUser: fail({ message: "auth down" }),
    });
    const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
    assertEquals(res.status, 500);
    assertEquals(await json(res), { error: "create_failed" });
    assertEquals(logged, [[
      "admin-create-user: compensation failed",
      { user_id: NEW_ID, step: "delete_auth_user" },
    ]]);
  } finally {
    console.error = original;
  }
});

// ---------------------------------------------------------------------------
// Pre-invite validation: sites and existing email (no invite email is sent)
// ---------------------------------------------------------------------------
Deno.test("rejects unknown site id before invite", async () => {
  // SITE_B does not exist in the sites table.
  const f = fakes({ sites: [ACTIVE_SITES[0]] });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 400);
  assertEquals(await json(res), { error: "invalid_sites" });
  assertEquals(f.invites.length, 0);
  assertEquals(f.calls, [...CALLER_CHECK, SITES_SELECT]);
  assertEquals(f.siteFilters, [[
    `in:id:${SITE_A},${SITE_B}`,
    "eq:is_active:true",
    "is:archived_at:null",
  ]]);
});

Deno.test("rejects archived site id before invite", async () => {
  const f = fakes({
    sites: [
      ACTIVE_SITES[0],
      { id: SITE_B, is_active: false, archived_at: "2026-11-01T00:00:00Z" },
    ],
  });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 400);
  assertEquals(await json(res), { error: "invalid_sites" });
  assertEquals(f.invites.length, 0);
});

Deno.test("returns 409 without inviting when a profile already exists for the email", async () => {
  const f = fakes({ userExists: ok(true) });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 409);
  assertEquals(await json(res), { error: "user_exists" });
  assertEquals(f.invites.length, 0);
  assertEquals(f.calls, [...CALLER_CHECK, SITES_SELECT, EXISTS_RPC]);
  assertEquals(f.rpcArgs, [[
    "auth_user_exists",
    { p_email: "new.user@example.test" },
  ]]);
});

Deno.test("500 internal_error when the sites query fails, no invite", async () => {
  const f = fakes({ sitesSelectError: { message: "db down" } });
  const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
  assertEquals(res.status, 500);
  assertEquals(await json(res), { error: "internal_error" });
  assertEquals(f.invites.length, 0);
  assertEquals(f.calls, [...CALLER_CHECK, SITES_SELECT]);
});

Deno.test("500 internal_error when auth_user_exists fails, no invite", async () => {
  for (const r of [fail({ message: "permission denied" }), ok(null)]) {
    const f = fakes({ userExists: r });
    const res = await handleCreateUser(post(SITE_USER_BODY), f.deps);
    assertEquals(res.status, 500);
    assertEquals(await json(res), { error: "internal_error" });
    assertEquals(f.invites.length, 0);
    assertEquals(f.calls, PRE_INVITE_SITE_USER);
  }
});

Deno.test("sites check is skipped when no site_ids are requested", async () => {
  const f = fakes();
  const res = await handleCreateUser(
    post({ email: "s@example.test", full_name: "S", role: "site_user" }),
    f.deps,
  );
  assertEquals(res.status, 201);
  assertEquals(f.siteFilters, []);
  assertEquals(f.calls.slice(0, 4), [...PRE_INVITE_ADMIN, "invite"]);
});
