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
  ["supabase (npx, no install)", "npx --no-install supabase --version"], ["opencode", "opencode --version"]]) {
  let v = run(cmd);
  if (name === "flutter" && !v.startsWith("ERROR")) { try { v = "Flutter " + JSON.parse(v).frameworkVersion; } catch { v = v.split("\n")[0]; } }
  log(`${name.padEnd(28)} ${v.split("\n")[0]}`);
}

// 2. Skills
h("2. SKILLS");
const skillDirs = [".agents/skills", ".opencode/skills", ".claude/skills"].map((d) => path.join(root, d))
  .concat([".agents/skills", ".config/opencode/skills", ".claude/skills"].map((d) => path.join(home, d)));
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
log("Bloc-related skills present: " + (uniq.filter((s) => /bloc/i.test(s.name)).map((s) => s.name).join(", ") || "none"));

// 3. opencode.json
h("3. opencode.json (project)");
const oc = ["opencode.json", "opencode.jsonc"].map((f) => path.join(root, f)).find((f) => fs.existsSync(f));
if (!oc) log("NOT FOUND in project root");
else {
  const txt = fs.readFileSync(oc, "utf8");
  log(redact(txt));
  const url = (txt.match(/https:\/\/mcp\.supabase\.com\/mcp[^"'\s]*/) || [""])[0];
  log("\nSupabase MCP checks:");
  log(`  url present:            ${url ? "yes" : "NO"}`);
  log(`  read_only=true:         ${/read_only=true/.test(url) ? "yes" : "NO"}`);
  log(`  project_ref present:    ${/project_ref=[a-z0-9]+/.test(url) ? "yes" : "NO"}`);
  log(`  forbidden groups:       ${/account|branching|feedback|notebooks/.test(url) ? "YES (remove them)" : "none"}`);
  // OpenCode V2 config keys: "plugins" (array) and "permissions" (array of rules).
  const pluginsArr = (txt.match(/"plugins"\s*:\s*\[([^\]]*)\]/) || [null, null])[1];
  const pluginsOk = pluginsArr !== null && pluginsArr.trim().length > 0;
  log(`  plugins (V2 array):     ${pluginsOk ? "OK  " + pluginsArr.trim() : "MISSING or EMPTY"}`);

  const permArr = (txt.match(/"permissions"\s*:\s*\[([\s\S]*?)\n\s*\]/) || [null, null])[1];
  const permRules = permArr ? (permArr.match(/"effect"\s*:/g) || []).length : 0;
  const permOk = permArr !== null && permRules > 0;
  log(`  permissions (V2 array): ${permOk ? "OK  " + permRules + " rules" : "MISSING or EMPTY"}`);

  // Security checks are enforced, not relaxed: every forbidden action must still be denied.
  const denyOf = (res) => new RegExp(`"resource"\\s*:\\s*"${res.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}"\\s*,\\s*"effect"\\s*:\\s*"deny"`).test(permArr || "");
  const shellDenies = ["rm -rf *", "git push --force*", "supabase db reset*", "supabase projects delete*"];
  const readDenies = ["*.env", "*.env.*", "*.xlsx", "*.xlsm"];
  const shellMissing = shellDenies.filter((r) => !denyOf(r));
  const readMissing = readDenies.filter((r) => !denyOf(r));
  log(`  deny shell actions:     ${shellMissing.length ? "MISSING: " + shellMissing.join(", ") : "all " + shellDenies.length + " OK"}`);
  log(`  deny secret/file reads: ${readMissing.length ? "MISSING: " + readMissing.join(", ") : "all " + readDenies.length + " OK"}`);
}
const g = path.join(home, ".config/opencode/opencode.json");
if (fs.existsSync(g) && /supabase/i.test(fs.readFileSync(g, "utf8"))) log(`\nWARNING: global config ${g} mentions supabase. Remove it (project-level only).`);

// 4. Docs layout
h("4. FILES");
const must = ["AGENTS.md", "opencode.json", ".gitignore", "docs/PROJECT_PLAN.md", "docs/OPENCODE_PROMPT.md", "docs/OPEN_QUESTIONS.md", "docs/SKILLS_LOG.md", "docs/PROGRESS.md"];
for (const f of must) log(`  ${fs.existsSync(path.join(root, f)) ? "OK     " : "MISSING"} ${f}`);
const stray = ["P0_EXIT_REPORT.md", "docs/P0_EXIT_REPORT.md", "OPENCODE_PROMPT.md", "OPEN_QUESTIONS.md", "SKILLS_LOG.md"].filter((f) => fs.existsSync(path.join(root, f)));
log("  Stray files in wrong place: " + (stray.join(", ") || "none"));
log("  docs/: " + (fs.existsSync(path.join(root, "docs")) ? fs.readdirSync(path.join(root, "docs")).join(", ") : "NO docs folder"));
const gi = fs.existsSync(path.join(root, ".gitignore")) ? fs.readFileSync(path.join(root, ".gitignore"), "utf8") : "";
for (const pat of [".env", "*.xlsx", "*.xlsm"]) log(`  .gitignore has ${pat}: ${gi.includes(pat) ? "yes" : "NO"}`);

// 5. Git
h("5. GIT");
log("git log --oneline -n 15:\n" + run("git log --oneline -n 15"));
log("\ngit status --short:\n" + (run("git status --short") || "(clean)"));
const tracked = run("git ls-files").split("\n");
log("\nTracked files that must NOT be tracked: " + (tracked.filter((f) => /\.(xlsx|xlsm)$|(^|\/)\.env/.test(f)).join(", ") || "none"));

// 6. Secret scan (file names only)
h("6. SECRET SCAN (file names only, no contents)");
const skip = new Set([".git", "node_modules", "build", ".dart_tool", ".agents", ".opencode", ".claude"]);
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
    if (/service_role/.test(t) && !/\.md$/.test(rel)) hits.service_role.push(rel);
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
