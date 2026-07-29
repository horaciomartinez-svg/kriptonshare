/// Gateway de conversión Office → PDF para KRIPTONSHARE (Fase 1).
/// Servicio mínimo en Deno: autentica JWT de Supabase, aplica límites por plan,
/// reenvía a Gotenberg y devuelve el PDF. Sin persistencia ni logs de contenido.

import { decodeBase64Url } from "https://deno.land/std@0.224.0/encoding/base64url.ts";

const GOTENBERG_URL = Deno.env.get("GOTENBERG_URL") ?? "http://gotenberg:3000";
const SUPABASE_JWT_SECRET = Deno.env.get("SUPABASE_JWT_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FREE_MAX_BYTES = parseInt(Deno.env.get("FREE_MAX_BYTES") ?? "10485760", 10);
const PREMIUM_MAX_BYTES = parseInt(
  Deno.env.get("PREMIUM_MAX_BYTES") ?? "104857600",
  10,
);
const PORT = parseInt(Deno.env.get("PORT") ?? "8080", 10);

const ALLOWED_EXTENSIONS = new Set([
  "doc",
  "docx",
  "xls",
  "xlsx",
  "ppt",
  "pptx",
  "odt",
  "ods",
  "odp",
  "rtf",
]);

// Cache en memoria de límites por usuario (5 minutos).
const tierCache = new Map<string, { maxBytes: number; expiresAt: number }>();

// Rate limiting en memoria: { sub -> { minute: number, day: number, resetMinAt: number, resetDayAt: number } }
const rateLimits = new Map<
  string,
  { minute: number; day: number; resetMinAt: number; resetDayAt: number }
>();

interface JwtPayload {
  sub: string;
  exp: number;
  iss?: string;
  aud?: string | string[];
}

function jsonError(status: number, code: string, extra?: Record<string, unknown>): Response {
  return new Response(JSON.stringify({ error: code, ...extra }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function hmacSha256(key: CryptoKey, message: Uint8Array): Promise<ArrayBuffer> {
  return await crypto.subtle.sign("HMAC", key, message);
}

async function importHmacKey(raw: Uint8Array): Promise<CryptoKey> {
  return await crypto.subtle.importKey(
    "raw",
    raw,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

async function verifyJwt(token: string): Promise<JwtPayload> {
  if (!SUPABASE_JWT_SECRET) {
    throw new Error("SUPABASE_JWT_SECRET not configured");
  }

  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid JWT format");

  const [headerB64, payloadB64, signatureB64] = parts;

  // Validar firma HS256
  const signingInput = new TextEncoder().encode(`${headerB64}.${payloadB64}`);
  const secretBytes = new TextEncoder().encode(SUPABASE_JWT_SECRET);
  const key = await importHmacKey(secretBytes);
  const expectedSig = await hmacSha256(key, signingInput);
  const actualSig = decodeBase64Url(signatureB64);

  if (actualSig.byteLength !== expectedSig.byteLength) {
    throw new Error("Invalid signature length");
  }
  const expectedArr = new Uint8Array(expectedSig);
  const actualArr = new Uint8Array(actualSig);
  let equal = true;
  for (let i = 0; i < expectedArr.length; i++) {
    equal &&= expectedArr[i] === actualArr[i];
  }
  if (!equal) throw new Error("Invalid signature");

  // Decodificar payload
  const payloadJson = new TextDecoder().decode(decodeBase64Url(payloadB64));
  const payload = JSON.parse(payloadJson) as JwtPayload;

  // Validar expiración
  const now = Math.floor(Date.now() / 1000);
  if (payload.exp && payload.exp < now) {
    throw new Error("Token expired");
  }

  // Validar issuer (Supabase emite "supabase" por defecto)
  if (payload.iss && !payload.iss.includes("supabase")) {
    throw new Error("Invalid issuer");
  }

  return payload;
}

async function resolveMaxBytes(sub: string): Promise<number> {
  const cached = tierCache.get(sub);
  const now = Date.now();
  if (cached && cached.expiresAt > now) {
    return cached.maxBytes;
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return FREE_MAX_BYTES;
  }

  try {
    const url =
      `${SUPABASE_URL}/rest/v1/users?id=eq.${encodeURIComponent(sub)}&select=max_file_size_bytes`;
    const response = await fetch(url, {
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Accept": "application/vnd.pgrst.object+json",
      },
    });

    if (!response.ok) {
      throw new Error(`Supabase error: ${response.status}`);
    }

    const data = await response.json() as Array<{ max_file_size_bytes: number }>;
    const maxBytes = data?.[0]?.max_file_size_bytes ?? FREE_MAX_BYTES;
    const effectiveMaxBytes = Math.min(maxBytes, PREMIUM_MAX_BYTES);

    tierCache.set(sub, { maxBytes: effectiveMaxBytes, expiresAt: now + 5 * 60 * 1000 });
    return effectiveMaxBytes;
  } catch (err) {
    console.error("[resolveMaxBytes] fallback to free limit:", err);
    return FREE_MAX_BYTES;
  }
}

function checkRateLimit(sub: string): { allowed: boolean; retryAfter?: number } {
  const now = Date.now();
  const minuteLimit = 10;
  const dayLimit = 100;
  const minWindow = 60_000;
  const dayWindow = 86_400_000;

  let entry = rateLimits.get(sub);
  if (!entry || now > entry.resetDayAt) {
    entry = { minute: 0, day: 0, resetMinAt: now + minWindow, resetDayAt: now + dayWindow };
  }

  if (now > entry.resetMinAt) {
    entry.minute = 0;
    entry.resetMinAt = now + minWindow;
  }

  if (entry.minute >= minuteLimit) {
    return { allowed: false, retryAfter: Math.ceil((entry.resetMinAt - now) / 1000) };
  }
  if (entry.day >= dayLimit) {
    return { allowed: false, retryAfter: Math.ceil((entry.resetDayAt - now) / 1000) };
  }

  entry.minute++;
  entry.day++;
  rateLimits.set(sub, entry);
  return { allowed: true };
}

function extractExtension(fileName: string): string | null {
  const idx = fileName.lastIndexOf(".");
  if (idx === -1 || idx === fileName.length - 1) return null;
  return fileName.slice(idx + 1).toLowerCase();
}

async function parseMultipartLimit(
  request: Request,
  maxBytes: number,
): Promise<{ fileName: string; fileBytes: Uint8Array }> {
  const contentType = request.headers.get("Content-Type") ?? "";
  if (!contentType.startsWith("multipart/form-data")) {
    throw new Error("Invalid content type");
  }

  const boundaryMatch = contentType.match(/boundary=([^;\s]+)/);
  if (!boundaryMatch) throw new Error("Missing boundary");
  const boundary = boundaryMatch[1];

  const body = await request.arrayBuffer();
  const data = new Uint8Array(body);

  const boundaryBytes = new TextEncoder().encode(`--${boundary}`);

  let partStart = indexOf(data, boundaryBytes, 0);
  if (partStart === -1) throw new Error("No parts found");

  while (partStart !== -1) {
    partStart += boundaryBytes.length;
    // Skip CRLF
    if (data[partStart] === 0x0D && data[partStart + 1] === 0x0A) {
      partStart += 2;
    }

    const nextBoundary = indexOf(data, boundaryBytes, partStart);
    if (nextBoundary === -1) break;

    // Extract headers until double CRLF
    const headerEnd = indexOf(data, new Uint8Array([0x0D, 0x0A, 0x0D, 0x0A]), partStart);
    if (headerEnd === -1 || headerEnd > nextBoundary) {
      partStart = nextBoundary;
      continue;
    }

    const headerBytes = data.slice(partStart, headerEnd);
    const headers = new TextDecoder().decode(headerBytes);

    const dispositionMatch = headers.match(
      /Content-Disposition:[^;]*;\s*name="([^"]+)"(?:;\s*filename="([^"]+)")?/i,
    );

    if (dispositionMatch && dispositionMatch[1] === "file" && dispositionMatch[2]) {
      const fileName = dispositionMatch[2];
      const contentStart = headerEnd + 4; // skip \r\n\r\n
      // Truncate at end boundary or next boundary, removing trailing CRLF if present
      let contentEnd = nextBoundary;
      // Check if just before boundary there is \r\n (or before end boundary `--`)
      if (contentEnd >= 2 && data[contentEnd - 2] === 0x0D && data[contentEnd - 1] === 0x0A) {
        contentEnd -= 2;
      }

      const partSize = contentEnd - contentStart;
      if (partSize > maxBytes) {
        throw new Error("too_large");
      }
      if (partSize <= 0) {
        throw new Error("empty_file");
      }

      const fileBytes = data.slice(contentStart, contentEnd);
      return { fileName, fileBytes };
    }

    partStart = nextBoundary;
  }

  throw new Error("file_field_missing");
}

function indexOf(haystack: Uint8Array, needle: Uint8Array, from: number): number {
  for (let i = from; i <= haystack.length - needle.length; i++) {
    let match = true;
    for (let j = 0; j < needle.length; j++) {
      if (haystack[i + j] !== needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}

async function convertWithGotenberg(
  fileName: string,
  fileBytes: Uint8Array,
): Promise<Response> {
  const boundary = `----krptn${crypto.randomUUID()}`;
  const encoder = new TextEncoder();

  const pre = encoder.encode(
    `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="files"; filename="${fileName}"\r\n` +
      `Content-Type: application/octet-stream\r\n\r\n`,
  );
  const fieldPdfa = encoder.encode(
    `\r\n--${boundary}\r\n` +
      `Content-Disposition: form-data; name="pdfa"\r\n\r\n` +
      `PDF/A-2b\r\n`,
  );
  const post = encoder.encode(`--${boundary}--\r\n`);

  const body = new Uint8Array(
    pre.length + fileBytes.length + fieldPdfa.length + post.length,
  );
  body.set(pre, 0);
  body.set(fileBytes, pre.length);
  body.set(fieldPdfa, pre.length + fileBytes.length);
  body.set(post, pre.length + fileBytes.length + fieldPdfa.length);

  return await fetch(`${GOTENBERG_URL}/forms/libreoffice/convert`, {
    method: "POST",
    headers: {
      "Content-Type": `multipart/form-data; boundary=${boundary}`,
    },
    body,
  });
}

async function handleRequest(request: Request): Promise<Response> {
  const url = new URL(request.url);
  if (request.method !== "POST" || url.pathname !== "/v1/convert/office") {
    return jsonError(404, "not_found");
  }

  const authHeader = request.headers.get("Authorization") ?? "";
  const tokenMatch = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!tokenMatch) {
    return jsonError(401, "unauthorized");
  }

  let payload: JwtPayload;
  try {
    payload = await verifyJwt(tokenMatch[1]);
  } catch (err) {
    console.error("[auth] JWT verification failed:", err);
    return jsonError(401, "unauthorized");
  }

  const sub = payload.sub;
  const subPrefix = sub.slice(0, 8);

  // Rate limiting
  const rate = checkRateLimit(sub);
  if (!rate.allowed) {
    return jsonError(429, "rate_limited", { retry_after: rate.retryAfter });
  }

  // Límite por plan
  const maxBytes = await resolveMaxBytes(sub);

  let fileName: string;
  let fileBytes: Uint8Array;
  try {
    const parsed = await parseMultipartLimit(request, maxBytes);
    fileName = parsed.fileName;
    fileBytes = parsed.fileBytes;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    if (msg === "too_large") {
      return jsonError(413, "too_large", { limit_bytes: maxBytes });
    }
    if (msg === "empty_file") {
      return jsonError(422, "conversion_failed", { reason: "empty_file" });
    }
    console.error("[parse]", err);
    return jsonError(422, "conversion_failed", { reason: "parse_error" });
  }

  // Validar extensión
  const ext = extractExtension(fileName);
  if (!ext || !ALLOWED_EXTENSIONS.has(ext)) {
    return jsonError(415, "unsupported_format");
  }

  const startTime = Date.now();

  try {
    const gotenbergResponse = await convertWithGotenberg(fileName, fileBytes);
    const durationMs = Date.now() - startTime;

    if (!gotenbergResponse.ok) {
      const body = await gotenbergResponse.text().catch(() => "");
      console.error(
        `[gotenberg] conversion failed status=${gotenbergResponse.status} sub=${subPrefix} ext=${ext} duration=${durationMs}ms`,
      );
      if (gotenbergResponse.status === 504) {
        return jsonError(504, "conversion_timeout");
      }
      return jsonError(422, "conversion_failed", {
        gotenberg_status: gotenbergResponse.status,
      });
    }

    console.log(
      `[convert] ok sub=${subPrefix} ext=${ext} duration=${durationMs}ms`,
    );

    // Devolver el stream del PDF tal cual.
    return new Response(gotenbergResponse.body, {
      status: 200,
      headers: { "Content-Type": "application/pdf" },
    });
  } catch (err) {
    const durationMs = Date.now() - startTime;
    console.error(
      `[convert] error sub=${subPrefix} ext=${ext} duration=${durationMs}ms`,
      err,
    );
    return jsonError(504, "conversion_timeout");
  }
}

Deno.serve({ port: PORT }, handleRequest);
