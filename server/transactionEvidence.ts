import type { Request, Response } from "express";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { storagePut } from "./storage";

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

export async function uploadTransactionEvidence(req: Request, res: Response) {
  try {
    const authorization = req.header("authorization");
    if (!authorization?.startsWith("Bearer ")) return res.status(401).json({ error: "Sign in before attaching transaction evidence." });
    const token = authorization.slice(7);
    const app = getFirebaseAdminApp();
    const decoded = await getAuth(app).verifyIdToken(token);
    const contentType = typeof req.body?.contentType === "string" ? req.body.contentType : "";
    const filename = typeof req.body?.filename === "string" ? req.body.filename.slice(0, 120) : "receipt";
    const bytes = parseEvidencePayload(req.body?.dataUrl, contentType);
    const extension = extensionFor(contentType, filename);
    const keyBase = `transaction-evidence/${decoded.uid}/${Date.now()}-${crypto.randomUUID()}.${extension}`;
    const stored = await storagePut(keyBase, bytes, contentType);
    return res.status(201).json({ id: crypto.randomUUID(), name: filename || `attachment.${extension}`, type: contentType, size: bytes.length, storageKey: stored.key, url: stored.url, uploadedAt: new Date().toISOString() });
  } catch (error) {
    const message = error instanceof Error ? error.message : "The attachment could not be stored.";
    console.error("[Transaction evidence] Upload failed", error);
    return res.status(400).json({ error: message });
  }
}
