// verify_p0.mjs : independent P0 evidence check (read-only, no network, no changes).
// Run from the PROJECT ROOT:   node verify_p0.mjs
// Then paste the whole output back to Claude.
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { execSync } from "node:child_process";

const root = process.cwd();
const home = os.homedir();
const out = [];
const log = (s = "") => { out.push(s); console.log(s); };
const h = (t) => log(`\n===== ${t} =====`);
const run = (cmd) => {
  try { return execSync(cmd, { cwd: root, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], shell: true, timeout: 60000 }).trim(); }
  catch (e) { return "ERROR: " + String(e.stderr || e.message).trim().split("\n")[0]; }
};
const redact = (s) => s
  .replace(/sb_(publishable|secret)_[A-Za-z0-9_-]+/g, "sb_$1_***REDACTED***")
  .replace(/eyJ[A-Za-z0-9._-]{20,}/g, "eyJ***REDACTED***")
  .replace(/("?[Aa]uthorization"?\s*:\s*")[^"]+/g, "$1***REDACTED***");

// 1. Tool versions
h("1. TOOL VERSIONS");
for (const [name, cmd] of [["git", "git --version"], ["node", "node --version"], ["python3", "python3 --version || python --version"],
  ["flutter", "flutter --version --machine"], ["dart", "dart --version"], ["supabase", "supabase --version"],
  ["supabase (npx, no install)", "npx --no-install supabase --version"]]) {
  let v = run(cmd);
  if (name === "flutter" && !v.startsWith("ERROR")) { try { v = "Flutter " + JSON.parse(v).frameworkVersion; } catch { v = v.split("\n")[0]; } }
  log(`${name.padEnd(28)} ${v.split("\n")[0]}`);
}

// 2. Skills
h("2. SKILLS");
// Claude Code discovers project skills in .claude/skills; .agents/skills is the source (skills-lock.json).
const skillDirs = [".claude/skills", ".agents/skills"].map((d) => path.join(root, d));
const found = [];
for (const base of skillDirs) {
  if (!fs.existsSync(base)) { log(`(missing folder) ${base}`); continue; }
  for (const d of fs.readdirSync(base, { withFileTypes: true })) {
    if (!d.isDirectory() && !d.isSymbolicLink()) continue;
    const f = path.join(base, d.name, "SKILL.md");
    if (!fs.existsSync(f)) continue;
    const m = fs.readFileSync(f, "utf8").match(/^name:\s*["']?([^\n"']+)/m);
    found.push({ name: (m ? m[1].trim() : d.name), dir: d.name, where: base.startsWith(root) ? "project" : "global" });
  }
}
const uniq = [...new Map(found.map((s) => [s.name, s])).values()];
log(`Skills with a SKILL.md: ${found.length} entries, ${uniq.length} unique names`);
log(uniq.map((s) => `  - ${s.name} [${s.where}]`).sort().join("\n"));
const req = [
  ["using-superpowers"], ["brainstorming"], ["writing-plans"], ["executing-plans"], ["subagent-driven-development"],
  ["test-driven-development"], ["systematic-debugging"], ["verification-before-completion"],
  ["flutter-apply-architecture-best-practices"], ["flutter declarative routing", /declarative-routing/],
  ["flutter json serialization", /json-serialization/], ["flutter responsive layout", /responsive-layout/],
  ["flutter-add-widget-test"], ["dart-run-static-analysis"], ["dart-use-pattern-matching"], ["dart-add-unit-test"],
  ["dart-fix-runtime-errors"], ["supabase"], ["supabase-postgres-best-practices"], ["ui-ux-pro-max"],
  ["insecure-defaults"], ["sharp-edges"], ["audit-context-building"],
].map((r) => (Array.isArray(r) ? r : [r]));
log("\nRequired skills check:");
let missing = 0;
for (const [label, rx] of req) {
  const hit = uniq.find((s) => (rx ? rx.test(s.name) : s.name === label));
  if (!hit) missing++;
  log(`  ${hit ? "OK     " : "MISSING"} ${label}${hit ? `  -> ${hit.name}` : ""}`);
}
log(`\nMissing required: ${missing}`);
// .claude/skills must be an identical copy of .agents/skills.
const listTree = (base) => {
  const acc = new Map();
  (function w(d) {
    if (!fs.existsSync(d)) return;
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) w(p); else acc.set(path.relative(base, p).split(path.sep).join("/"), fs.readFileSync(p));
    }
  })(base);
  return acc;
};
const src = listTree(path.join(root, ".agents/skills")), dst = listTree(path.join(root, ".claude/skills"));
const diff = [...new Set([...src.keys(), ...dst.keys()])].filter((k) => !src.has(k) || !dst.has(k) || !src.get(k).equals(dst.get(k)));
log(`.claude/skills identical to .agents/skills: ${diff.length ? "NO (" + diff.length + " differ, e.g. " + diff.slice(0, 3).join(", ") + ")" : "yes (" + src.size + " files)"}`);
log("Bloc-related skills present: " + (uniq.filter((s) => /bloc/i.test(s.name)).map((s) => s.name).join(", ") || "none"));

// 3. Claude Code configuration
h("3. CLAUDE CODE CONFIG (project)");
const readJson = (rel) => { try { return JSON.parse(fs.readFileSync(path.join(root, rel), "utf8")); } catch (e) { return { __error: String(e.message) }; } };
const mcp = readJson(".mcp.json");
if (mcp.__error) log(".mcp.json: NOT FOUND or invalid (" + mcp.__error + ")");
else {
  const servers = mcp.mcpServers || {};
  log(".mcp.json servers: " + (Object.keys(servers).join(", ") || "none"));
  const url = (servers.supabase && servers.supabase.url) || "";
  log("\nSupabase MCP checks:");
  log(`  url present:            ${/^https:\/\/mcp\.supabase\.com\/mcp\?/.test(url) ? "yes" : "NO"}`);
  log(`  read_only=true:         ${/[?&]read_only=true(&|$)/.test(url) ? "yes" : "NO"}`);
  log(`  project_ref present:    ${/[?&]project_ref=[a-z0-9]+/.test(url) ? "yes" : "NO"}`);
  log(`  forbidden groups:       ${/account|branching|feedback|notebooks/.test(url) ? "YES (remove them)" : "none"}`);
  log(`  dart server:            ${servers.dart && servers.dart.command === "dart" && (servers.dart.args || []).includes("mcp-server") ? "OK" : "MISSING"}`);
  log(`  context7 server:        ${servers.context7 && /^https:\/\/mcp\.context7\.com\//.test(servers.context7.url || "") ? "OK" : "MISSING"}`);
}
const st = readJson(".claude/settings.json");
if (st.__error) log("\n.claude/settings.json: NOT FOUND or invalid (" + st.__error + ")");
else {
  // Security checks are enforced, not relaxed: every forbidden action must still be denied.
  const deny = (st.permissions && st.permissions.deny) || [];
  const allow = (st.permissions && st.permissions.allow) || [];
  const shellDenies = ["Bash(rm -rf *)", "Bash(git push --force*)", "Bash(supabase db reset*)", "Bash(supabase projects delete*)"];
  const readDenies = ["Read(**/.env)", "Read(**/.env.*)", "Read(**/*.xlsx)", "Read(**/*.xlsm)", "Read(app/env/dev.json)"];
  const shellMissing = shellDenies.filter((r) => !deny.includes(r));
  const readMissing = readDenies.filter((r) => !deny.includes(r));
  log("\n.claude/settings.json checks:");
  log(`  deny rules total:       ${deny.length}`);
  log(`  deny shell actions:     ${shellMissing.length ? "MISSING: " + shellMissing.join(", ") : "all " + shellDenies.length + " OK"}`);
  log(`  deny secret/file reads: ${readMissing.length ? "MISSING: " + readMissing.join(", ") : "all " + readDenies.length + " OK"}`);
  const risky = allow.filter((r) => /rm -rf|push --force|db reset|projects delete|\.env|xlsx|xlsm/.test(r));
  log(`  risky allow rules:      ${risky.join(", ") || "none"}`);
  log(`  enabledMcpjsonServers:  ${(st.enabledMcpjsonServers || []).join(", ") || "none"}`);
}
const cm = fs.existsSync(path.join(root, "CLAUDE.md")) ? fs.readFileSync(path.join(root, "CLAUDE.md"), "utf8") : "";
log(`\nCLAUDE.md imports AGENTS.md: ${/^@AGENTS\.md\s*$/m.test(cm) ? "yes" : "NO"}`);
log(`Legacy opencode.json present: ${fs.existsSync(path.join(root, "opencode.json")) ? "YES (retired, remove it)" : "no"}`);
// Read-only look at the user-scope Claude config: the Supabase MCP must be project-level only.
const g = path.join(home, ".claude.json");
try {
  const gj = JSON.parse(fs.readFileSync(g, "utf8"));
  const gs = JSON.stringify(gj.mcpServers || {});
  log(`Global (user-scope) Supabase MCP entry: ${/supabase/i.test(gs) ? "YES - remove it (project-level only)" : "none"}`);
} catch { log("Global (user-scope) Supabase MCP entry: none (no readable ~/.claude.json)"); }

// 4. Docs layout
h("4. FILES");
const must = ["AGENTS.md", "CLAUDE.md", ".mcp.json", ".claude/settings.json", ".gitignore", "docs/PROJECT_PLAN.md", "docs/OPENCODE_PROMPT.md", "docs/OPEN_QUESTIONS.md", "docs/SKILLS_LOG.md", "docs/PROGRESS.md"];
for (const f of must) log(`  ${fs.existsSync(path.join(root, f)) ? "OK     " : "MISSING"} ${f}`);
const stray = ["P0_EXIT_REPORT.md", "docs/P0_EXIT_REPORT.md", "OPENCODE_PROMPT.md", "OPEN_QUESTIONS.md", "SKILLS_LOG.md"].filter((f) => fs.existsSync(path.join(root, f)));
log("  Stray files in wrong place: " + (stray.join(", ") || "none"));
log("  docs/: " + (fs.existsSync(path.join(root, "docs")) ? fs.readdirSync(path.join(root, "docs")).join(", ") : "NO docs folder"));
const gi = fs.existsSync(path.join(root, ".gitignore")) ? fs.readFileSync(path.join(root, ".gitignore"), "utf8") : "";
for (const pat of [".env", "*.xlsx", "*.xlsm", ".claude/settings.local.json"]) log(`  .gitignore has ${pat}: ${gi.includes(pat) ? "yes" : "NO"}`);

// 5. Git
h("5. GIT");
log("git log --oneline -n 15:\n" + run("git log --oneline -n 15"));
log("\ngit status --short:\n" + (run("git status --short") || "(clean)"));
const tracked = run("git ls-files").split("\n");
log("\nTracked files that must NOT be tracked: " + (tracked.filter((f) => /\.(xlsx|xlsm)$|(^|\/)\.env/.test(f)).join(", ") || "none"));

// 6. Secret scan (file names only)
h("6. SECRET SCAN (file names only, no contents)");
const skip = new Set([".git", "node_modules", "build", ".dart_tool", ".agents", ".claude"]);
const hits = { secret: [], service_role: [], jwt: [], publishable: [] };
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    if (skip.has(e.name)) continue;
    const p = path.join(d, e.name);
    if (e.isDirectory()) { walk(p); continue; }
    let st; try { st = fs.statSync(p); } catch { continue; }
    if (st.size > 1_000_000) continue;
    let t; try { t = fs.readFileSync(p, "utf8"); } catch { continue; }
    const rel = path.relative(root, p);
    if (/sb_secret_[A-Za-z0-9_-]{10,}/.test(t)) hits.secret.push(rel);
    if (/service_role/.test(t) && !/\.md$/.test(rel) && rel !== "verify_p0.mjs") hits.service_role.push(rel);
    if (/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/.test(t)) hits.jwt.push(rel);
    if (/sb_publishable_[A-Za-z0-9_-]{10,}/.test(t)) hits.publishable.push(rel);
  }
})(root);
log(`  sb_secret_ keys in:          ${hits.secret.join(", ") || "none"}`);
log(`  'service_role' (non-docs) in: ${hits.service_role.join(", ") || "none"}`);
log(`  JWT-like tokens in:          ${hits.jwt.join(", ") || "none"}`);
log(`  publishable key appears in:  ${hits.publishable.join(", ") || "none"}   (should be gitignored env files only)`);

h("DONE");
log("Paste this entire output back to Claude. Nothing was modified.");
