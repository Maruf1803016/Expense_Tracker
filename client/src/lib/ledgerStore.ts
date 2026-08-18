// Ink & Ledger persistence: each collection is addressed only beneath the active owner's Firestore document.
import { collection, deleteDoc, doc, onSnapshot, runTransaction, setDoc, type DocumentData, type Unsubscribe } from "firebase/firestore";
import { firestore } from "@/lib/firebase";

// Ink & Ledger persistence note: a personal ledger is provisioned only once, inside the signed-in owner’s document tree.

export type LedgerCollection = "accounts" | "categories" | "expenses" | "plans" | "tripPlans" | "loans" | "recurringIncomeSources";

export interface LedgerStarterRecord {
  id: string;
  [key: string]: unknown;
}

function stripUndefined(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stripUndefined);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).flatMap(([key, item]) => item === undefined ? [] : [[key, stripUndefined(item)]]));
  }
  return value;
}

export function subscribeToLedgerCollection<T extends { id: string }>(
  userId: string,
  collectionName: LedgerCollection,
  onData: (records: T[]) => void,
  onError: (error: Error) => void,
): Unsubscribe {
  return onSnapshot(
    collection(firestore, "users", userId, collectionName),
    (snapshot) => {
      onData(snapshot.docs.map((record) => ({ id: record.id, ...record.data() }) as T));
    },
    (error) => onError(error),
  );
}

export async function saveLedgerRecord<T extends { id: string }>(userId: string, collectionName: LedgerCollection, record: T) {
  const { id, ...data } = record;
  await setDoc(doc(firestore, "users", userId, collectionName, id), stripUndefined(data) as DocumentData, { merge: true });
}

export async function removeLedgerRecord(userId: string, collectionName: LedgerCollection, recordId: string) {
  await deleteDoc(doc(firestore, "users", userId, collectionName, recordId));
}

export async function ensureLedgerStarter(
  userId: string,
  starter: { account: LedgerStarterRecord; categories: LedgerStarterRecord[] },
  existing: { hasAccounts: boolean; hasCategories: boolean },
) {
  const markerRef = doc(firestore, "users", userId, "meta", "ledger");

  return runTransaction(firestore, async (transaction) => {
    const marker = await transaction.get(markerRef);
    if (marker.exists()) return false;

    if (!existing.hasAccounts) {
      const { id, ...account } = starter.account;
      transaction.set(doc(firestore, "users", userId, "accounts", id), stripUndefined(account) as DocumentData);
    }

    if (!existing.hasCategories) {
      starter.categories.forEach((category) => {
        const { id, ...data } = category;
        transaction.set(doc(firestore, "users", userId, "categories", id), stripUndefined(data) as DocumentData);
      });
    }

    transaction.set(markerRef, {
      starterVersion: 1,
      completedAt: new Date().toISOString(),
      createdAccount: !existing.hasAccounts,
      createdCategories: !existing.hasCategories,
    });
    return true;
  });
}
