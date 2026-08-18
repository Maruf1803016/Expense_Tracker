// Ink & Ledger persistence: each collection is addressed only beneath the active owner's Firestore document.
import { collection, deleteDoc, doc, onSnapshot, setDoc, type DocumentData, type Unsubscribe } from "firebase/firestore";
import { firestore } from "@/lib/firebase";

export type LedgerCollection = "accounts" | "categories" | "expenses" | "plans" | "tripPlans" | "loans" | "recurringIncomeSources";

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
