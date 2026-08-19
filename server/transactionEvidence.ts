import type { Request, Response } from "express";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { Readable } from "node:stream";
import { pipeline } from "node:stream/promises";
import { storageGetSignedUrl, storagePut } from "./storage";

type FirebaseServiceAccount = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
};

const MAX_EVIDENCE_BYTES = 8 * 1024 * 1024;
const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "application/pdf"]);

function getFirebaseAdminApp() {
  const source = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!source) throw new Error("Firebase evidence upload is not configured");
  if (!getApps().length) {
    const account = JSON.parse(source) as FirebaseServiceAccount;
    if (!account.project_id || !account.client_email || !account.private_key) throw new Error("Firebase service account is incomplete");
    initializeApp({ credential: cert({ projectId: account.project_id, clientEmail: account.client_email, privateKey: account.private_key.replace(/\\n/g, "\n") }) });
  }
  return getApps()[0]!;
}

function extensionFor(contentType: string, fileName: string) {
  const proposed = fileName.split(".").pop()?.replace(/[^a-z0-9]/gi, "").toLowerCase();
  if (proposed && proposed.length <= 6) return proposed;
  return contentType === "application/pdf" ? "pdf" : contentType === "image/png" ? "png" : contentType === "image/webp" ? "webp" : "jpg";
}

export function parseEvidencePayload(dataUrl: unknown, contentType: unknown) {
  if (typeof dataUrl !== "string" || typeof contentType !== "string" || !ALLOWED_TYPES.has(contentType)) throw new Error("Choose a JPG, PNG, WEBP image, or PDF document.");
  const encoded = dataUrl.includes(",") ? dataUrl.slice(dataUrl.indexOf(",") + 1) : dataUrl;
  const bytes = Buffer.from(encoded, "base64");
  if (!bytes.length || bytes.length > MAX_EVIDENCE_BYTES) throw new Error("Each attachment must be smaller than 8 MB.");
  return bytes;
}

export function isOwnedEvidenceKey(storageKey: unknown, uid: string) {
  if (typeof storageKey !== "string" || !storageKey || !uid) return false;
  const key = storageKey.replace(/^\/+/, "");
  return !key.includes("..") && key.startsWith(`transaction-evidence/${uid}/`);
}

async function requireEvidenceOwner(req: Request) {
  const authorization = req.header("authorization");
  if (!authorization?.startsWith("Bearer ")) throw new Error("Sign in before viewing transaction evidence.");
  const app = getFirebaseAdminApp();
  return getAuth(app).verifyIdToken(authorization.slice(7));
}

export async function uploadTransactionEvidence(req: Request, res: Response) {
  try {
    const decoded = await requireEvidenceOwner(req);
    const contentType = typeof req.body?.contentType === "string" ? req.body.contentType : "";
    const filename = typeof req.body?.filename === "string" ? req.body.filename.slice(0, 120) : "receipt";
    const bytes = parseEvidencePayload(req.body?.dataUrl, contentType);
    const extension = extensionFor(contentType, filename);
    const keyBase = `transaction-evidence/${decoded.uid}/${Date.now()}-${crypto.randomUUID()}.${extension}`;
    const stored = await storagePut(keyBase, bytes, contentType);
    return res.status(201).json({ id: crypto.randomUUID(), name: filename || `attachment.${extension}`, type: contentType, size: bytes.length, storageKey: stored.key, uploadedAt: new Date().toISOString() });
  } catch (error) {
    const message = error instanceof Error ? error.message : "The attachment could not be stored.";
    console.error("[Transaction evidence] Upload failed", error);
    return res.status(message.startsWith("Sign in") ? 401 : 400).json({ error: message });
  }
}

export async function downloadTransactionEvidence(req: Request, res: Response) {
  try {
    const decoded = await requireEvidenceOwner(req);
    const key = typeof req.params.key === "string" ? req.params.key.replace(/^\/+/, "") : "";
    if (!isOwnedEvidenceKey(key, decoded.uid)) return res.status(403).json({ error: "You cannot view evidence that belongs to another ledger." });

    const signedUrl = await storageGetSignedUrl(key);
    const upstream = await fetch(signedUrl);
    if (!upstream.ok || !upstream.body) {
      console.error(`[Transaction evidence] Storage retrieval failed: ${upstream.status}`);
      return res.status(502).json({ error: "The attachment could not be retrieved." });
    }

    const contentType = upstream.headers.get("content-type") || "application/octet-stream";
    const contentLength = upstream.headers.get("content-length");
    res.status(200).set({ "Content-Type": contentType, "Cache-Control": "private, no-store, max-age=0", "X-Content-Type-Options": "nosniff" });
    if (contentLength) res.set("Content-Length", contentLength);
    await pipeline(Readable.fromWeb(upstream.body as never), res);
  } catch (error) {
    const message = error instanceof Error ? error.message : "The attachment could not be retrieved.";
    console.error("[Transaction evidence] Download failed", error);
    if (!res.headersSent) return res.status(message.startsWith("Sign in") ? 401 : 400).json({ error: message });
  }
}
