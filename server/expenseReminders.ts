import type { Request, Response } from "express";
import { cert, getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { sdk } from "./_core/sdk";

type FirebaseServiceAccount = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
};

type ReminderSettings = {
  enabled?: boolean;
  time?: string;
  timezone?: string;
  lastSentLocalDate?: string;
};

type DeviceToken = {
  token?: string;
};

function getAdminFirestore() {
  const source = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!source) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is not configured");

  if (!getApps().length) {
    const account = JSON.parse(source) as FirebaseServiceAccount;
    if (!account.project_id || !account.client_email || !account.private_key) {
      throw new Error("Firebase service account is incomplete");
    }
    initializeApp({
      credential: cert({
        projectId: account.project_id,
        clientEmail: account.client_email,
        privateKey: account.private_key.replace(/\\n/g, "\n"),
      }),
    });
  }

  return getFirestore();
}

export function safeTimezone(value: unknown) {
  const timezone = typeof value === "string" && value ? value : "UTC";
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: timezone }).format();
    return timezone;
  } catch {
    return "UTC";
  }
}

function localClock(now: Date, timezone: string) {
  const pieces = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const value = (kind: Intl.DateTimeFormatPartTypes) => pieces.find((piece) => piece.type === kind)?.value ?? "00";
  return {
    day: `${value("year")}-${value("month")}-${value("day")}`,
    time: `${value("hour")}:${value("minute")}`,
  };
}

export function dueNow(settings: ReminderSettings, now: Date) {
  const timezone = safeTimezone(settings.timezone);
  const clock = localClock(now, timezone);
  const selectedTime = /^([01]\d|2[0-3]):[0-5]\d$/.test(settings.time ?? "") ? settings.time! : "22:00";
  return { due: Boolean(settings.enabled) && clock.time === selectedTime, timezone, localDay: clock.day, selectedTime };
}

async function sendToDevices(tokens: string[], title: string, body: string) {
  if (!tokens.length) return { sent: 0, failures: 0 };

  let sent = 0;
  let failures = 0;
  for (let start = 0; start < tokens.length; start += 500) {
    const response = await getMessaging().sendEachForMulticast({
      tokens: tokens.slice(start, start + 500),
      notification: { title, body },
      data: { kind: "daily-expense-reminder", url: "/" },
      webpush: { fcmOptions: { link: "/" } },
    });
    sent += response.successCount;
    failures += response.failureCount;
  }
  return { sent, failures };
}

export async function sendDueExpenseReminders(req: Request, res: Response) {
  try {
    const caller = await sdk.authenticateRequest(req);
    if (!caller.isCron || !caller.taskUid) return res.status(403).json({ error: "cron-only" });

    const firestore = getAdminFirestore();
    const now = new Date();
    const settingsSnapshot = await firestore.collectionGroup("reminderSettings").where("enabled", "==", true).get();
    let dueCount = 0;
    let sentCount = 0;
    let deliveryFailures = 0;

    for (const settingDocument of settingsSnapshot.docs) {
      const settings = settingDocument.data() as ReminderSettings;
      const reminder = dueNow(settings, now);
      if (!reminder.due) continue;

      const userDocument = settingDocument.ref.parent.parent;
      if (!userDocument) continue;
      const notificationDocument = userDocument.collection("notifications").doc(`daily-expense-${reminder.localDay}`);
      let claimed = false;

      await firestore.runTransaction(async (transaction) => {
        const current = await transaction.get(settingDocument.ref);
        const latest = current.data() as ReminderSettings | undefined;
        if (!latest || latest.enabled !== true || latest.lastSentLocalDate === reminder.localDay) return;

        transaction.update(settingDocument.ref, {
          lastSentLocalDate: reminder.localDay,
          lastSentAt: now.toISOString(),
          lastReminderTimezone: reminder.timezone,
        });
        transaction.set(notificationDocument, {
          kind: "daily-expense-reminder",
          title: "Your day, thoughtfully recorded.",
          body: "Take a moment to bring today’s spending into your field book.",
          unread: true,
          createdAt: now.toISOString(),
          reminderTime: reminder.selectedTime,
          localDay: reminder.localDay,
        }, { merge: true });
        claimed = true;
      });

      if (!claimed) continue;
      dueCount += 1;
      const devices = await userDocument.collection("deviceTokens").get();
      const tokens = devices.docs.map((document) => (document.data() as DeviceToken).token).filter((token): token is string => Boolean(token));
      const delivery = await sendToDevices(tokens, "Your day, thoughtfully recorded.", "Take a moment to bring today’s spending into your field book.");
      sentCount += delivery.sent;
      deliveryFailures += delivery.failures;
    }

    return res.json({ ok: true, scanned: settingsSnapshot.size, dueCount, sentCount, deliveryFailures });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown scheduled reminder error";
    console.error("[Expense reminders] Scheduled delivery failed", error);
    return res.status(500).json({ error: message, timestamp: new Date().toISOString() });
  }
}
