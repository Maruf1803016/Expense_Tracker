// Ink & Ledger infrastructure: Firebase's public web configuration initializes client-side, user-scoped ledger access.
import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore, doc, setDoc } from "firebase/firestore";
import { getMessaging, getToken, isSupported, onMessage, type MessagePayload } from "firebase/messaging";

const firebaseConfig = {
  apiKey: "AIzaSyABQIZZqOCCMHUIySQwjnlZwTHC9ORcCPk",
  authDomain: "expense-tracker-79ef7.firebaseapp.com",
  databaseURL: "https://expense-tracker-79ef7-default-rtdb.firebaseio.com",
  projectId: "expense-tracker-79ef7",
  storageBucket: "expense-tracker-79ef7.firebasestorage.app",
  messagingSenderId: "657477735157",
  appId: "1:657477735157:web:d803f2dc7acb282d2d2bbc",
  measurementId: "G-KEL7DMTMXL",
};

const app = getApps().length ? getApp() : initializeApp(firebaseConfig);

export const firebaseAuth = getAuth(app);
export const firestore = getFirestore(app);

type PushRegistrationResult = {
  status: "enabled" | "unsupported" | "blocked" | "unavailable";
  message: string;
};

export async function enableExpenseReminderPush(userId: string): Promise<PushRegistrationResult> {
  if (typeof window === "undefined" || !("Notification" in window) || !("serviceWorker" in navigator)) {
    return { status: "unsupported", message: "This browser does not support device reminders." };
  }

  const supported = await isSupported();
  if (!supported) return { status: "unsupported", message: "Device reminders are not supported in this browser." };

  const permission = await Notification.requestPermission();
  if (permission !== "granted") {
    return { status: "blocked", message: "Allow notifications in your browser settings to receive reminders." };
  }

  const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;
  if (!vapidKey) {
    return { status: "unavailable", message: "Device reminders are being prepared. Please try again shortly." };
  }

  const serviceWorkerRegistration = await navigator.serviceWorker.register("/firebase-messaging-sw.js");
  const messaging = getMessaging(app);
  const token = await getToken(messaging, { vapidKey, serviceWorkerRegistration });
  if (!token) return { status: "unavailable", message: "A device reminder token could not be created. Please try again." };

  await setDoc(doc(firestore, "users", userId, "deviceTokens", token), {
    token,
    enabledAt: new Date().toISOString(),
    userAgent: navigator.userAgent,
  }, { merge: true });

  return { status: "enabled", message: "Device reminders are enabled for this browser." };
}

export async function listenForExpenseReminderMessages(onReminder: (payload: MessagePayload) => void) {
  if (typeof window === "undefined" || !("serviceWorker" in navigator)) return () => undefined;
  if (!(await isSupported())) return () => undefined;
  return onMessage(getMessaging(app), onReminder);
}
