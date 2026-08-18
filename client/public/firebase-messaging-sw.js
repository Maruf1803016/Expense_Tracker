/* Firebase Cloud Messaging service worker for Ink & Ledger background reminders. */
importScripts("https://www.gstatic.com/firebasejs/12.6.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.6.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyABQIZZqOCCMHUIySQwjnlZwTHC9ORcCPk",
  authDomain: "expense-tracker-79ef7.firebaseapp.com",
  projectId: "expense-tracker-79ef7",
  messagingSenderId: "657477735157",
  appId: "1:657477735157:web:d803f2dc7acb282d2d2bbc",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || "A quick expense check-in";
  const options = {
    body: payload.notification?.body || "Take a moment to record today’s spending.",
    icon: "/favicon.ico",
    badge: "/favicon.ico",
    data: { url: payload.fcmOptions?.link || "/" },
  };
  self.registration.showNotification(title, options);
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data?.url || "/"));
});
