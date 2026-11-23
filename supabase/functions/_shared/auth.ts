// Extracts the bearer token from the Authorization header. The scheme is
// matched case-insensitively. A missing header, another scheme, an empty token
// or a token containing whitespace yields null (the caller answers 401).
export function bearerToken(req: Request): string | null {
  const header = req.headers.get("authorization");
  if (!header) return null;
  const match = /^bearer\s+(\S+)\s*$/i.exec(header.trim());
  return match ? match[1] : null;
}
