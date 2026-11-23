// Parses the platform-provided SUPABASE_PUBLISHABLE_KEYS / SUPABASE_SECRET_KEYS
// value (a JSON object keyed by key name) and returns its "default" entry.
// Missing, empty or malformed input yields null (the caller answers 500); there
// is no fallback to another key.
export function parseDefaultKey(raw: string | undefined): string | null {
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
