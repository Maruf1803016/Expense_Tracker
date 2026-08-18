// Ink & Ledger infrastructure: Firebase's public web configuration initializes client-side, user-scoped ledger access.
import { getApp, getApps, initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

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
