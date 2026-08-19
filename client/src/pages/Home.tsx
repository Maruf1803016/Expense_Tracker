import React, { useCallback, useEffect, useMemo, useState } from "react";
import { ArrowDownRight, ArrowUpRight, ArrowLeft, Plus, Search, Wallet, ShieldCheck, LogOut, X, Edit3, Trash2, Tag, Compass, Calendar, Bell, Layers, CheckCircle2, ChevronLeft, ChevronRight, FolderPlus, HandCoins, FileText, Download, Utensils, ShoppingBasket, Coffee, Pizza, CookingPot, Car, Bus, Train, Plane, Fuel, House, ReceiptText, Lightbulb, Wifi, HeartPulse, Pill, Dumbbell, Stethoscope, ShoppingBag, Shirt, BookOpen, Film, Music, Gamepad2, Ticket, Landmark, CreditCard, BadgeDollarSign, BriefcaseBusiness, Laptop, GraduationCap, Gift, Sparkles, PawPrint, Baby, Wrench, Leaf, PiggyBank, Banknote, CircleDollarSign, Building2, Paperclip, Camera, Image, CircleCheck, Clock3, ClipboardCheck, type LucideIcon } from "lucide-react";
import { jsPDF } from "jspdf";
import { useAuth } from "@/contexts/AuthContext";
import { ensureLedgerStarter, removeLedgerRecord, saveLedgerRecord, subscribeToLedgerCollection, type LedgerCollection } from "@/lib/ledgerStore";
import { enableExpenseReminderPush } from "@/lib/firebase";
import { calendarYearChoices, normaliseCalendarDate } from "@/lib/calendarDate";
import { ledgerErrorMessage } from "@/lib/ledgerError";
import { expectedRoutineDaysInMonth, routineCalendarDays, type RoutineDaysPerWeek } from "@/lib/routineCalendar";
import { formatReminderTime, reminderTimeFromParts, reminderTimeParts } from "@/lib/reminderTime";
import { clampRoutineMonth, isWithinTwoYearRetention, planningIsActive, type PlanningLifecycleState } from "@/lib/planningLifecycle";

// Ink & Ledger design note: the Overview is a daily field note; permanent expense containers stay concise while rich subcategories carry the detail.

type TransactionType = "expense" | "income" | "transfer";

interface Account {
  id: string;
  name: string;
  kind: "asset" | "liability";
  balance: number;
  accountNumber: string;
  color: string;
}

interface Category {
  id: string;
  name: string;
  type: "expense" | "income";
  parentId?: string | null;
  monthlyBudget: number;
  color: string;
  icon: string;
  isPermanent?: boolean;
}

interface Transaction {
  id: string;
  merchantNote: string;
  amount: number;
  type: TransactionType;
  accountId: string;
  destinationAccountId?: string;
  categoryId?: string;
  date: string;
  tag?: { goalId?: string; tripId?: string };
  icon: string;
  loanId?: string;
  cashFlowKind?: "loan-disbursement" | "loan-settlement";
  payee?: string;
  payer?: string;
  settlementStatus?: "paid" | "pending";
  attachments?: TransactionAttachment[];
}

interface TransactionAttachment {
  id: string;
  name: string;
  type: string;
  size: number;
  storageKey: string;
  uploadedAt: string;
}

interface Goal {
  id: string;
  name: string;
  target: number;
  saved: number;
  deadline: string;
  financedAmount?: number;
  fundingHistory: GoalFunding[];
  status?: PlanningLifecycleState;
  completedAt?: string;
}

interface GoalFunding {
  id: string;
  amount: number;
  type: "deposit" | "withdraw";
  date: string;
  note: string;
}

interface Trip {
  id: string;
  name: string;
  budget: number;
  dates: string;
  status?: PlanningLifecycleState;
  completedAt?: string;
}

interface LoanPayment {
  id: string;
  amount: number;
  date: string;
  note: string;
  method: string;
  reference?: string;
  transactionId?: string;
}

interface Loan {
  id: string;
  title: string;
  direction: "borrowed" | "lent";
  counterparty: string;
  totalAmount: number;
  paidAmount: number;
  dueDate: string;
  terms: string;
  paymentHistory: LoanPayment[];
  cashAccountId?: string;
  disbursementTransactionId?: string;
  status?: PlanningLifecycleState;
  completedAt?: string;
}

type ScheduleFrequency = "weekly" | "biweekly" | "monthly";

interface ScheduleOccurrence {
  id: string;
  scheduledFor: string;
  recordedAt: string;
  transactionId: string;
}

interface RecurringSchedule {
  id: string;
  name: string;
  amount: number;
  type: "income" | "expense";
  frequency: ScheduleFrequency;
  accountId: string;
  categoryId: string;
  nextDueDate: string;
  status: "active" | "paused";
  history: ScheduleOccurrence[];
}

type NotificationTone = "urgent" | "notice" | "reminder";

interface AppNotification {
  id: string;
  title: string;
  detail: string;
  tone: NotificationTone;
  createdAt: string;
  read: boolean;
}

interface ReminderSettings {
  id: string;
  enabled: boolean;
  time: string;
  timezone: string;
  currency: SupportedCurrency;
}

interface WorkRoutine {
  id: string;
  name: string;
  daysPerWeek: RoutineDaysPerWeek;
  color: string;
  icon: string;
  createdAt: string;
  status?: "active" | "archived";
  archivedAt?: string;
}

interface RoutineAttendance {
  id: string;
  routineId: string;
  date: string;
  attended: boolean;
  updatedAt: string;
}

type StoredRecord = Record<string, unknown>;
type StoredRecordWithId = StoredRecord & { id: string };

// Ink & Ledger visual note: category symbols remain restrained, line-based, and useful at ledger scale.
const CATEGORY_ICON_MAP: Record<string, LucideIcon> = {
  Utensils, ShoppingBasket, Coffee, Pizza, CookingPot, Car, Bus, Train, Plane, Fuel,
  House, Building2, ReceiptText, Lightbulb, Wifi, HeartPulse, Pill, Dumbbell, Stethoscope,
  ShoppingBag, Shirt, BookOpen, Film, Music, Gamepad2, Ticket, Wallet, Landmark, CreditCard,
  BadgeDollarSign, BriefcaseBusiness, Laptop, GraduationCap, Gift, Sparkles, PawPrint, Baby,
  Wrench, Leaf, PiggyBank, Banknote, CircleDollarSign, HandCoins, Compass, Calendar, Layers, Tag,
};

const CATEGORY_ICON_GROUPS = [
  { label: "Food & home", keys: ["Utensils", "ShoppingBasket", "Coffee", "Pizza", "CookingPot", "House", "Building2", "ReceiptText", "Lightbulb", "Wifi", "Wrench"] },
  { label: "Travel & life", keys: ["Car", "Bus", "Train", "Plane", "Fuel", "HeartPulse", "Pill", "Dumbbell", "Stethoscope", "PawPrint", "Baby", "Leaf"] },
  { label: "Shopping & leisure", keys: ["ShoppingBag", "Shirt", "BookOpen", "Film", "Music", "Gamepad2", "Ticket", "Sparkles", "Gift"] },
  { label: "Money & work", keys: ["Wallet", "Landmark", "CreditCard", "BadgeDollarSign", "PiggyBank", "Banknote", "CircleDollarSign", "HandCoins", "BriefcaseBusiness", "Laptop", "GraduationCap"] },
  { label: "General", keys: ["Compass", "Calendar", "Layers", "Tag"] },
] as const;

const PERMANENT_EXPENSE_CATEGORY_IDS = new Set(["food-dining", "home-utilities", "travel", "personal", "finance-other"]);

function categoryIconForName(name: string, type: Category["type"]) {
  const value = name.toLowerCase();
  if (/food|dining|grocery|restaurant|coffee|cafe/.test(value)) return value.includes("coffee") || value.includes("cafe") ? "Coffee" : value.includes("grocery") ? "ShoppingBasket" : "Utensils";
  if (/home|rent|mortgage/.test(value)) return "House";
  if (/utilit|internet|fiber|bill/.test(value)) return "ReceiptText";
  if (/travel|stay|transit|transport/.test(value)) return value.includes("stay") ? "Building2" : "Plane";
  if (/personal|shopping/.test(value)) return "ShoppingBag";
  if (/salary|freelance|income|bonus/.test(value)) return type === "income" ? "BriefcaseBusiness" : "Wallet";
  if (/gift|dividend/.test(value)) return "Gift";
  return type === "income" ? "Banknote" : "Tag";
}

function CategoryIcon({ icon, size = 16, className = "" }: { icon?: string; size?: number; className?: string }) {
  const Icon = CATEGORY_ICON_MAP[icon ?? ""] ?? Tag;
  return <Icon aria-hidden="true" size={size} strokeWidth={1.8} className={className} />;
}

function IconPicker({ value, onChange }: { value: string; onChange: (value: string) => void }) {
  return <div className="category-icon-picker" aria-label="Choose a category icon">
    <div className="icon-picker-selected"><span className="category-icon-preview"><CategoryIcon icon={value} size={18} /></span><div><b>Category symbol</b><small>Choose a mark that reads clearly in the ledger.</small></div></div>
    {CATEGORY_ICON_GROUPS.map((group) => <div className="icon-picker-group" key={group.label}><span>{group.label}</span><div>{group.keys.map((key) => <button key={key} type="button" className={`icon-picker-option ${value === key ? "active" : ""}`} onClick={() => onChange(key)} aria-label={`Use ${key} icon`} aria-pressed={value === key}><CategoryIcon icon={key} size={17} /></button>)}</div></div>)}
  </div>;
}

function storedString(value: unknown, fallback = "") {
  return typeof value === "string" && value.trim() ? value : fallback;
}

function storedNumber(value: unknown, fallback = 0) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function storedArray(value: unknown) {
  return Array.isArray(value) ? value : [];
}

function storedDate(value: unknown, fallback: string) {
  if (typeof value === "string" && value) return value;
  if (value && typeof value === "object" && "toDate" in value && typeof value.toDate === "function") return dateInputValue(value.toDate());
  return fallback;
}

function readFileAsDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onerror = () => reject(new Error("The selected file could not be read."));
    reader.onload = () => resolve(String(reader.result));
    reader.readAsDataURL(file);
  });
}

function normaliseCategory(record: StoredRecord): Category[] {
  const parentId = storedString(record.parentId ?? record.parent_id) || null;
  const id = storedString(record.id);
  const type = record.type === "income" ? "income" : "expense";
  const name = storedString(record.name, "Untitled category");
  const base: Category = { id, name, type, parentId, monthlyBudget: storedNumber(record.monthlyBudget ?? record.budget), color: storedString(record.color, type === "income" ? "#2c5234" : "#1b3a2b"), icon: storedString(record.icon ?? record.iconKey, categoryIconForName(name, type)), isPermanent: record.isPermanent === true || (type === "expense" && !parentId && PERMANENT_EXPENSE_CATEGORY_IDS.has(id)) };
  const embeddedSubcategories = type === "expense" && !parentId ? storedArray(record.subCategories ?? record.subcategories) : [];
  return [base, ...embeddedSubcategories.map((item, index) => {
    const sub = (item ?? {}) as StoredRecord;
    const name = storedString(sub.name ?? sub.title, `Subcategory ${index + 1}`);
    return { id: storedString(sub.id, `${id}--${name.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`), name, type: "expense" as const, parentId: id, monthlyBudget: 0, color: storedString(sub.color, base.color), icon: storedString(sub.icon ?? sub.iconKey, categoryIconForName(name, "expense")) };
  })];
}

function normaliseTransaction(record: StoredRecord): Transaction {
  const tag = (record.tag ?? {}) as StoredRecord;
  const planId = storedString(record.planId);
  const rawType = record.type;
  const cashFlowKind = record.cashFlowKind === "loan-disbursement" || record.cashFlowKind === "loan-settlement" ? record.cashFlowKind : undefined;
  const attachments = storedArray(record.attachments).map((item, index) => {
    const attachment = (item ?? {}) as StoredRecord;
    return { id: storedString(attachment.id, `attachment-${index}`), name: storedString(attachment.name, "Attachment"), type: storedString(attachment.type, "application/octet-stream"), size: storedNumber(attachment.size), storageKey: storedString(attachment.storageKey), uploadedAt: storedDate(attachment.uploadedAt, dateInputValue(new Date())) };
  }).filter((attachment) => attachment.storageKey);
  return { id: storedString(record.id), merchantNote: storedString(record.merchantNote ?? record.title, "Untitled entry"), amount: storedNumber(record.amount), type: rawType === "income" || rawType === "transfer" ? rawType : "expense", accountId: storedString(record.accountId, "acc-1"), destinationAccountId: storedString(record.destinationAccountId) || undefined, categoryId: storedString(record.webCategoryId ?? record.categoryId) || undefined, date: storedDate(record.date, dateInputValue(new Date())), tag: { goalId: storedString(tag.goalId) || (planId && !storedString(tag.tripId) ? planId : undefined), tripId: storedString(tag.tripId) || undefined }, icon: storedString(record.icon, rawType === "income" ? "ArrowDownRight" : rawType === "transfer" ? "Repeat" : "ShoppingCart"), loanId: storedString(record.loanId) || undefined, cashFlowKind, payee: storedString(record.payee) || undefined, payer: storedString(record.payer) || undefined, settlementStatus: record.settlementStatus === "pending" ? "pending" : "paid", attachments };
}

function normaliseGoal(record: StoredRecord): Goal {
  const fundingHistory = storedArray(record.fundingHistory ?? record.history).map((item, index) => {
    const funding = (item ?? {}) as StoredRecord;
    return { id: storedString(funding.id, `goal-history-${index}`), amount: storedNumber(funding.amount), type: funding.type === "withdraw" ? "withdraw" as const : "deposit" as const, date: storedDate(funding.date, dateInputValue(new Date())), note: storedString(funding.note, funding.type === "withdraw" ? "Goal withdrawal" : "Goal contribution") };
  });
  return { id: storedString(record.id), name: storedString(record.name ?? record.title, "Untitled goal"), target: storedNumber(record.target), saved: storedNumber(record.saved), deadline: storedDate(record.deadline, "By Dec 2026"), financedAmount: storedNumber(record.financedAmount), fundingHistory, status: record.status === "completed" ? "completed" : "active", completedAt: storedString(record.completedAt) || undefined };
}

function normaliseTrip(record: StoredRecord): Trip {
  return { id: storedString(record.id), name: storedString(record.name ?? record.title, "Untitled plan"), budget: storedNumber(record.budget ?? record.target), dates: storedString(record.dates ?? record.dateRange, "Upcoming"), status: record.status === "completed" ? "completed" : "active", completedAt: storedString(record.completedAt) || undefined };
}

function normaliseLoan(record: StoredRecord): Loan {
  const paymentHistory = storedArray(record.paymentHistory).map((item, index) => {
    const payment = (item ?? {}) as StoredRecord;
    return { id: storedString(payment.id, `loan-payment-${index}`), amount: storedNumber(payment.amount), date: storedDate(payment.date, dateInputValue(new Date())), note: storedString(payment.note, "Payment recorded"), method: storedString(payment.method, "Cash in hand"), reference: storedString(payment.reference) || undefined, transactionId: storedString(payment.transactionId) || undefined };
  });
  return { id: storedString(record.id), title: storedString(record.title, "Untitled loan"), direction: record.direction === "lent" ? "lent" : "borrowed", counterparty: storedString(record.counterparty), totalAmount: storedNumber(record.totalAmount), paidAmount: storedNumber(record.paidAmount), dueDate: storedDate(record.dueDate, dateInputValue(new Date())), terms: storedString(record.terms, "Due in full by the due date"), paymentHistory, cashAccountId: storedString(record.cashAccountId) || undefined, disbursementTransactionId: storedString(record.disbursementTransactionId) || undefined, status: record.status === "completed" ? "completed" : "active", completedAt: storedString(record.completedAt) || undefined };
}

function normaliseSchedule(record: StoredRecord): RecurringSchedule {
  const history = storedArray(record.history).map((item, index) => {
    const occurrence = (item ?? {}) as StoredRecord;
    return { id: storedString(occurrence.id, `schedule-occurrence-${index}`), scheduledFor: storedDate(occurrence.scheduledFor, dateInputValue(new Date())), recordedAt: storedDate(occurrence.recordedAt, dateInputValue(new Date())), transactionId: storedString(occurrence.transactionId) };
  });
  return { id: storedString(record.id), name: storedString(record.name, "Untitled schedule"), amount: storedNumber(record.amount ?? record.expectedAmount), type: record.type === "income" ? "income" : "expense", frequency: record.frequency === "weekly" || record.frequency === "biweekly" ? record.frequency : "monthly", accountId: storedString(record.accountId, "acc-1"), categoryId: storedString(record.categoryId), nextDueDate: storedDate(record.nextDueDate, dateInputValue(new Date())), status: record.status === "paused" ? "paused" : "active", history };
}

function normaliseNotification(record: StoredRecord): AppNotification {
  const tone = record.tone === "urgent" || record.tone === "reminder" ? record.tone : record.kind === "daily-expense-reminder" ? "reminder" : "notice";
  return {
    id: storedString(record.id),
    title: storedString(record.title, "Ledger notice"),
    detail: storedString(record.detail ?? record.body, "A ledger update needs your attention."),
    tone,
    createdAt: storedDate(record.createdAt, new Date().toISOString()),
    read: record.read === true || record.unread === false,
  };
}

function normaliseReminderSettings(record: StoredRecord): ReminderSettings {
  const time = storedString(record.time, "22:00");
  const candidateCurrency = storedString(record.currency, "USD");
  return {
    id: storedString(record.id, "daily-expense-reminder"),
    enabled: record.enabled === true,
    time: /^([01]\d|2[0-3]):[0-5]\d$/.test(time) ? time : "22:00",
    timezone: storedString(record.timezone, Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC"),
    currency: isSupportedCurrency(candidateCurrency) ? candidateCurrency : "USD",
  };
}

function normaliseRoutine(record: StoredRecord): WorkRoutine {
  const rawDays = storedNumber(record.daysPerWeek, 5);
  const daysPerWeek: RoutineDaysPerWeek = rawDays === 3 || rawDays === 4 || rawDays === 5 || rawDays === 6 || rawDays === 7 ? rawDays : 5;
  return {
    id: storedString(record.id),
    name: storedString(record.name, "Untitled routine"),
    daysPerWeek,
    color: storedString(record.color, "#b78a3d"),
    icon: storedString(record.icon, "ClipboardCheck"),
    createdAt: storedDate(record.createdAt, new Date().toISOString()),
    status: record.status === "archived" ? "archived" : "active",
    archivedAt: typeof record.archivedAt === "string" ? record.archivedAt : undefined,
  };
}

function normaliseRoutineAttendance(record: StoredRecord): RoutineAttendance {
  return {
    id: storedString(record.id),
    routineId: storedString(record.routineId),
    date: storedDate(record.date, dateInputValue(new Date())),
    attended: record.attended !== false,
    updatedAt: storedDate(record.updatedAt, new Date().toISOString()),
  };
}

function normaliseAccount(record: StoredRecord): Account {
  return { id: storedString(record.id), name: storedString(record.name, "Untitled account"), kind: record.kind === "liability" ? "liability" : "asset", balance: storedNumber(record.balance ?? record.initialBalance), accountNumber: storedString(record.accountNumber, "··· —"), color: storedString(record.color, record.kind === "liability" ? "#8b2626" : "#1b3a2b") };
}

type DraftKind = "transaction" | "goal" | "trip" | "loan" | "schedule" | "category" | "subcategory" | "account" | "profile" | null;

interface TransactionDraft {
  id?: string;
  merchantNote: string;
  amount: string;
  type: TransactionType;
  accountId: string;
  destinationAccountId: string;
  categoryId: string;
  date: string;
  goalId: string;
  tripId: string;
  payee: string;
  payer: string;
  settlementStatus: "paid" | "pending";
  attachments: TransactionAttachment[];
}

const CURRENCY_OPTIONS = [
  { code: "BDT", name: "Bangladeshi taka", symbol: "৳", flag: "🇧🇩", label: "Bangladeshi taka (৳)" },
  { code: "USD", name: "United States dollar", symbol: "$", flag: "🇺🇸", label: "US dollar ($)" },
  { code: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺", label: "Euro (€)" },
  { code: "GBP", name: "British pound", symbol: "£", flag: "🇬🇧", label: "British pound (£)" },
  { code: "INR", name: "Indian rupee", symbol: "₹", flag: "🇮🇳", label: "Indian rupee (₹)" },
  { code: "AED", name: "United Arab Emirates dirham", symbol: "د.إ", flag: "🇦🇪", label: "UAE dirham (د.إ)" },
  { code: "SAR", name: "Saudi riyal", symbol: "ر.س", flag: "🇸🇦", label: "Saudi riyal (ر.س)" },
  { code: "QAR", name: "Qatari riyal", symbol: "ر.ق", flag: "🇶🇦", label: "Qatari riyal (ر.ق)" },
  { code: "KWD", name: "Kuwaiti dinar", symbol: "د.ك", flag: "🇰🇼", label: "Kuwaiti dinar (د.ك)" },
  { code: "OMR", name: "Omani rial", symbol: "ر.ع.", flag: "🇴🇲", label: "Omani rial (ر.ع.)" },
  { code: "MYR", name: "Malaysian ringgit", symbol: "RM", flag: "🇲🇾", label: "Malaysian ringgit (RM)" },
  { code: "SGD", name: "Singapore dollar", symbol: "S$", flag: "🇸🇬", label: "Singapore dollar (S$)" },
  { code: "AUD", name: "Australian dollar", symbol: "A$", flag: "🇦🇺", label: "Australian dollar (A$)" },
  { code: "CAD", name: "Canadian dollar", symbol: "C$", flag: "🇨🇦", label: "Canadian dollar (C$)" },
  { code: "JPY", name: "Japanese yen", symbol: "¥", flag: "🇯🇵", label: "Japanese yen (¥)" },
  { code: "CNY", name: "Chinese yuan", symbol: "CN¥", flag: "🇨🇳", label: "Chinese yuan (CN¥)" },
  { code: "KRW", name: "South Korean won", symbol: "₩", flag: "🇰🇷", label: "South Korean won (₩)" },
  { code: "THB", name: "Thai baht", symbol: "฿", flag: "🇹🇭", label: "Thai baht (฿)" },
  { code: "PKR", name: "Pakistani rupee", symbol: "₨", flag: "🇵🇰", label: "Pakistani rupee (₨)" },
  { code: "TRY", name: "Turkish lira", symbol: "₺", flag: "🇹🇷", label: "Turkish lira (₺)" },
] as const;
type SupportedCurrency = (typeof CURRENCY_OPTIONS)[number]["code"];
const isSupportedCurrency = (value: string): value is SupportedCurrency => CURRENCY_OPTIONS.some((currency) => currency.code === value);
let activeCurrency: SupportedCurrency = "USD";
const fmt = { format: (value: number) => new Intl.NumberFormat("en-US", { style: "currency", currency: activeCurrency, maximumFractionDigits: 2 }).format(value) };

function goalMetrics(goal: Goal) {
  const financed = Math.min(goal.target, Math.max(0, goal.financedAmount ?? 0));
  const personalTarget = Math.max(0, goal.target - financed);
  const remaining = Math.max(0, personalTarget - goal.saved);
  const parsedDeadline = new Date(`${normaliseCalendarDate(goal.deadline, new Date())}T12:00:00`);
  const daysLeft = Number.isNaN(parsedDeadline.getTime()) ? null : Math.max(0, Math.ceil((new Date(parsedDeadline.getFullYear(), parsedDeadline.getMonth(), parsedDeadline.getDate()).getTime() - new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()).getTime()) / 86400000));
  return {
    financed,
    personalTarget,
    remaining,
    percent: personalTarget ? Math.min(100, Math.round((goal.saved / personalTarget) * 100)) : 100,
    daysLeft,
    dailyNeeded: daysLeft && daysLeft > 0 ? remaining / daysLeft : null,
    weeklyNeeded: daysLeft && daysLeft > 0 ? remaining / Math.max(1, daysLeft / 7) : null,
  };
}

function dateInputValue(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function oneYearFromToday() {
  const date = new Date();
  date.setFullYear(date.getFullYear() + 1);
  return dateInputValue(date);
}

function goalDeadlineLabel(value: string) {
  const normalised = normaliseCalendarDate(value, new Date());
  return `By ${new Date(`${normalised}T12:00:00`).toLocaleDateString("en-US", { day: "numeric", month: "short", year: "numeric" })}`;
}

function advanceScheduleDate(date: string, frequency: ScheduleFrequency) {
  const [year, month, day] = date.split("-").map(Number);
  if (!year || !month || !day) return date;
  const next = new Date(year, month - 1, day);
  if (frequency === "weekly") next.setDate(next.getDate() + 7);
  if (frequency === "biweekly") next.setDate(next.getDate() + 14);
  if (frequency === "monthly") {
    const monthlyTarget = new Date(year, month, 1);
    const lastDay = new Date(monthlyTarget.getFullYear(), monthlyTarget.getMonth() + 1, 0).getDate();
    monthlyTarget.setDate(Math.min(day, lastDay));
    return dateInputValue(monthlyTarget);
  }
  return dateInputValue(next);
}

function scheduleDueLabel(nextDueDate: string) {
  const [year, month, day] = nextDueDate.split("-").map(Number);
  const today = new Date();
  const todayUtc = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
  const dueUtc = Date.UTC(year, month - 1, day);
  const difference = Math.round((dueUtc - todayUtc) / 86400000);
  if (difference < 0) return `${Math.abs(difference)} days overdue`;
  if (difference === 0) return "Due today";
  if (difference === 1) return "Due tomorrow";
  return `Due in ${difference} days`;
}

function scheduleFrequencyLabel(frequency: ScheduleFrequency) {
  return frequency === "biweekly" ? "Every two weeks" : frequency[0].toUpperCase() + frequency.slice(1);
}

const INITIAL_ACCOUNTS: Account[] = [
  { id: "acc-1", name: "Daily account", kind: "asset", balance: 19465, accountNumber: "··· 4092", color: "#1b3a2b" },
  { id: "acc-2", name: "Reserve", kind: "asset", balance: 3200, accountNumber: "··· 8110", color: "#2b4c3f" },
  { id: "acc-3", name: "Credit card", kind: "liability", balance: 3276, accountNumber: "··· 2481", color: "#8b2626" },
];

const INITIAL_CATEGORIES: Category[] = [
  { id: "food-dining", name: "Food & Dining", type: "expense", monthlyBudget: 800, color: "#1b3a2b", icon: "Utensils", isPermanent: true },
  { id: "food-groceries", name: "Groceries", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "ShoppingBasket" },
  { id: "food-restaurants", name: "Restaurants & Cafes", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "Coffee" },
  { id: "food-delivery", name: "Delivery & Takeaway", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "Pizza" },
  { id: "food-home-cooking", name: "Home cooking", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "CookingPot" },
  { id: "home-utilities", name: "Home & Bills", type: "expense", monthlyBudget: 1500, color: "#3d5a45", icon: "House", isPermanent: true },
  { id: "home-rent", name: "Rent & Mortgage", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "House" },
  { id: "home-energy", name: "Utilities", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Lightbulb" },
  { id: "home-internet", name: "Phone & Internet", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Wifi" },
  { id: "home-supplies", name: "Household supplies", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "ShoppingBasket" },
  { id: "home-maintenance", name: "Repairs & maintenance", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Wrench" },
  { id: "travel", name: "Transport & Travel", type: "expense", monthlyBudget: 1000, color: "#8c6d36", icon: "Plane", isPermanent: true },
  { id: "transport-local", name: "Fuel, Transit & Rides", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Car" },
  { id: "travel-stays", name: "Trips & Stays", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Train" },
  { id: "travel-tickets", name: "Flights & tickets", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Ticket" },
  { id: "travel-parking", name: "Parking & tolls", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Fuel" },
  { id: "personal", name: "Personal & Lifestyle", type: "expense", monthlyBudget: 400, color: "#5b4a6f", icon: "Sparkles", isPermanent: true },
  { id: "personal-health", name: "Health & Pharmacy", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "HeartPulse" },
  { id: "personal-shopping", name: "Shopping & Clothing", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "ShoppingBag" },
  { id: "personal-leisure", name: "Entertainment & Subscriptions", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Film" },
  { id: "personal-fitness", name: "Fitness & wellbeing", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Dumbbell" },
  { id: "personal-care", name: "Personal care", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Sparkles" },
  { id: "finance-other", name: "Finance & Other", type: "expense", monthlyBudget: 300, color: "#6b5a3c", icon: "Wallet", isPermanent: true },
  { id: "finance-fees", name: "Fees & Taxes", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "ReceiptText" },
  { id: "finance-giving", name: "Gifts & Giving", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Gift" },
  { id: "finance-insurance", name: "Insurance & protection", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Landmark" },
  { id: "finance-other-detail", name: "Other expense", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Tag" },
  { id: "income-salary", name: "Salary", type: "income", monthlyBudget: 0, color: "#2c5234", icon: "BriefcaseBusiness" },
  { id: "income-freelance", name: "Freelance income", type: "income", monthlyBudget: 0, color: "#32603c", icon: "Laptop" },
  { id: "income-business", name: "Business sales", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "BadgeDollarSign" },
  { id: "income-rental", name: "Rental income", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "Building2" },
  { id: "income-interest", name: "Interest & dividends", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "PiggyBank" },
  { id: "income-gifts", name: "Gifts & support", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "Gift" },
];

const PERSONAL_LEDGER_STARTER_ACCOUNT: Account = {
  id: "personal-main-account",
  name: "Main Account",
  kind: "asset",
  balance: 0,
  accountNumber: "—",
  color: "#1b3a2b",
};

const PERSONAL_LEDGER_STARTER_CATEGORIES: Category[] = [
  { id: "food-dining", name: "Food & Dining", type: "expense", monthlyBudget: 0, color: "#1b3a2b", icon: "Utensils", isPermanent: true },
  { id: "food-groceries", name: "Groceries", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "ShoppingBasket" },
  { id: "food-restaurants", name: "Restaurants & Cafes", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "Coffee" },
  { id: "food-delivery", name: "Delivery & Takeaway", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "Pizza" },
  { id: "food-home-cooking", name: "Home cooking", type: "expense", parentId: "food-dining", monthlyBudget: 0, color: "#1b3a2b", icon: "CookingPot" },
  { id: "home-utilities", name: "Home & Bills", type: "expense", monthlyBudget: 0, color: "#3d5a45", icon: "House", isPermanent: true },
  { id: "home-rent-bills", name: "Rent & Mortgage", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "House" },
  { id: "home-energy", name: "Utilities", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Lightbulb" },
  { id: "home-internet", name: "Phone & Internet", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Wifi" },
  { id: "home-supplies", name: "Household supplies", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "ShoppingBasket" },
  { id: "home-maintenance", name: "Repairs & maintenance", type: "expense", parentId: "home-utilities", monthlyBudget: 0, color: "#3d5a45", icon: "Wrench" },
  { id: "travel", name: "Transport & Travel", type: "expense", monthlyBudget: 0, color: "#8c6d36", icon: "Plane", isPermanent: true },
  { id: "travel-transport", name: "Fuel, Transit & Rides", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Car" },
  { id: "travel-stays", name: "Trips & Stays", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Train" },
  { id: "travel-tickets", name: "Flights & tickets", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Ticket" },
  { id: "travel-parking", name: "Parking & tolls", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36", icon: "Fuel" },
  { id: "personal", name: "Personal & Lifestyle", type: "expense", monthlyBudget: 0, color: "#5b4a6f", icon: "Sparkles", isPermanent: true },
  { id: "personal-health", name: "Health & Pharmacy", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "HeartPulse" },
  { id: "personal-shopping", name: "Shopping & Clothing", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "ShoppingBag" },
  { id: "personal-leisure", name: "Entertainment & Subscriptions", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Film" },
  { id: "personal-fitness", name: "Fitness & wellbeing", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Dumbbell" },
  { id: "personal-care", name: "Personal care", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f", icon: "Sparkles" },
  { id: "finance-other", name: "Finance & Other", type: "expense", monthlyBudget: 0, color: "#6b5a3c", icon: "Wallet", isPermanent: true },
  { id: "finance-fees", name: "Fees & Taxes", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "ReceiptText" },
  { id: "finance-giving", name: "Gifts & Giving", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Gift" },
  { id: "finance-insurance", name: "Insurance & protection", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Landmark" },
  { id: "finance-other-detail", name: "Other expense", type: "expense", parentId: "finance-other", monthlyBudget: 0, color: "#6b5a3c", icon: "Tag" },
  { id: "income-salary", name: "Salary", type: "income", monthlyBudget: 0, color: "#2c5234", icon: "BriefcaseBusiness" },
  { id: "income-freelance", name: "Freelance income", type: "income", monthlyBudget: 0, color: "#32603c", icon: "Laptop" },
  { id: "income-business", name: "Business sales", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "BadgeDollarSign" },
  { id: "income-rental", name: "Rental income", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "Building2" },
  { id: "income-interest", name: "Interest & dividends", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "PiggyBank" },
  { id: "income-gifts", name: "Gifts & support", type: "income", monthlyBudget: 0, color: "#3a6e45", icon: "Gift" },
];

const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: "tx-1", merchantNote: "Northline Studio", amount: 1840, type: "income", accountId: "acc-1", categoryId: "income-freelance", date: "2026-08-16", icon: "ArrowDownRight" },
  { id: "tx-2", merchantNote: "Botanica Market", amount: 124.5, type: "expense", accountId: "acc-1", categoryId: "food-groceries", date: "2026-08-15", icon: "ShoppingCart" },
  { id: "tx-3", merchantNote: "Power & Water Board", amount: 165, type: "expense", accountId: "acc-1", categoryId: "home-energy", date: "2026-08-14", icon: "Zap" },
  { id: "tx-4", merchantNote: "Air France · Lisbon", amount: 480, type: "expense", accountId: "acc-3", categoryId: "travel-stays", date: "2026-08-12", tag: { tripId: "trip-1" }, icon: "Compass" },
  { id: "tx-5", merchantNote: "Monthly Salary", amount: 3100, type: "income", accountId: "acc-1", categoryId: "income-salary", date: "2026-08-01", icon: "Briefcase" },
  { id: "tx-6", merchantNote: "Reserve Sweep", amount: 500, type: "transfer", accountId: "acc-1", destinationAccountId: "acc-2", date: "2026-08-10", icon: "Repeat" },
];

const INITIAL_GOALS: Goal[] = [
  { id: "goal-1", name: "Quiet reserve", target: 8000, saved: 3200, deadline: "By Dec 2026", financedAmount: 0, fundingHistory: [{ id: "goal-funding-1", amount: 3200, type: "deposit", date: "2026-08-01", note: "Opening reserve balance" }] },
];

const INITIAL_TRIPS: Trip[] = [
  { id: "trip-1", name: "Autumn in Lisbon", budget: 1200, dates: "12–19 Oct 2026" },
];

const INITIAL_LOANS: Loan[] = [
  {
    id: "loan-1",
    title: "Studio equipment advance",
    direction: "borrowed",
    counterparty: "Tariq Rahman",
    totalAmount: 2400,
    paidAmount: 600,
    dueDate: "2026-11-15",
    terms: "$200 monthly through November",
    paymentHistory: [{ id: "loan-payment-1", amount: 600, date: "2026-08-05", note: "First repayment", method: "Bank transfer", reference: "TRX-240805" }],
  },
];

const INITIAL_SCHEDULES: RecurringSchedule[] = [
  { id: "schedule-1", name: "Monthly salary", amount: 3100, type: "income", frequency: "monthly", accountId: "acc-1", categoryId: "income-salary", nextDueDate: "2026-09-01", status: "active", history: [{ id: "schedule-occurrence-1", scheduledFor: "2026-08-01", recordedAt: "2026-08-01", transactionId: "tx-5" }] },
  { id: "schedule-2", name: "Studio retainer", amount: 1840, type: "income", frequency: "monthly", accountId: "acc-1", categoryId: "income-freelance", nextDueDate: "2026-09-16", status: "active", history: [{ id: "schedule-occurrence-2", scheduledFor: "2026-08-16", recordedAt: "2026-08-16", transactionId: "tx-1" }] },
  { id: "schedule-3", name: "Power & water board", amount: 165, type: "expense", frequency: "monthly", accountId: "acc-1", categoryId: "home-energy", nextDueDate: "2026-08-20", status: "active", history: [{ id: "schedule-occurrence-3", scheduledFor: "2026-08-14", recordedAt: "2026-08-14", transactionId: "tx-3" }] },
  { id: "schedule-4", name: "Market pantry", amount: 124.5, type: "expense", frequency: "weekly", accountId: "acc-1", categoryId: "food-groceries", nextDueDate: "2026-08-22", status: "paused", history: [{ id: "schedule-occurrence-4", scheduledFor: "2026-08-15", recordedAt: "2026-08-15", transactionId: "tx-2" }] },
];

export default function Home() {
  const { user, loading: authLoading, error: authError, signIn, signUp, sendVerification, refreshVerification, requestPasswordReset, signOut, clearError } = useAuth();
  const [activeTab, setActiveTab] = useState<"overview" | "history" | "accounts" | "insights" | "reports" | "inbox" | "horizon" | "settings" | "settings-expenses" | "settings-income" | "settings-currency" | "settings-reminders" | "settings-history">("overview");
  const [filter, setFilter] = useState<"all" | TransactionType>("all");
  const [categoryFilterId, setCategoryFilterId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [historyPendingOnly, setHistoryPendingOnly] = useState(false);
  const [historyOrigin, setHistoryOrigin] = useState<"overview" | "settings-history">("overview");

  const [accounts, setAccounts] = useState<Account[]>(INITIAL_ACCOUNTS);
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [transactions, setTransactions] = useState<Transaction[]>(INITIAL_TRANSACTIONS);
  const [goals, setGoals] = useState<Goal[]>(INITIAL_GOALS);
  const [trips, setTrips] = useState<Trip[]>(INITIAL_TRIPS);
  const [loans, setLoans] = useState<Loan[]>(INITIAL_LOANS);
  const [schedules, setSchedules] = useState<RecurringSchedule[]>(INITIAL_SCHEDULES);
  const [routines, setRoutines] = useState<WorkRoutine[]>([]);
  const [routineAttendance, setRoutineAttendance] = useState<RoutineAttendance[]>([]);
  const [cloudStatus, setCloudStatus] = useState<"demo" | "loading" | "synced" | "error">("demo");
  const [cloudError, setCloudError] = useState<string | null>(null);

  const [draft, setDraft] = useState<DraftKind>(null);
  const [transactionDetail, setTransactionDetail] = useState<Transaction | null>(null);
  const [goalDetail, setGoalDetail] = useState<Goal | null>(null);
  const [tripDetail, setTripDetail] = useState<Trip | null>(null);
  const [loanDetail, setLoanDetail] = useState<Loan | null>(null);
  const [scheduleDetail, setScheduleDetail] = useState<RecurringSchedule | null>(null);
  const [goalAdjustment, setGoalAdjustment] = useState<"deposit" | "withdraw" | null>(null);
  const [goalAdjustmentAmount, setGoalAdjustmentAmount] = useState("");
  const [goalAdjustmentNote, setGoalAdjustmentNote] = useState("");
  const [loanPaymentAmount, setLoanPaymentAmount] = useState("");
  const [loanPaymentMethod, setLoanPaymentMethod] = useState("Cash in hand");
  const [loanCustomPaymentMethod, setLoanCustomPaymentMethod] = useState("");
  const [loanPaymentNote, setLoanPaymentNote] = useState("");
  const [loanPaymentReference, setLoanPaymentReference] = useState("");
  const [editingGoalId, setEditingGoalId] = useState<string | null>(null);
  const [editingTripId, setEditingTripId] = useState<string | null>(null);
  const [editingLoanId, setEditingLoanId] = useState<string | null>(null);
  const [editingScheduleId, setEditingScheduleId] = useState<string | null>(null);

  const [draftTitle, setDraftTitle] = useState("");
  const [draftAmount, setDraftAmount] = useState("");
  const [draftDate, setDraftDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [transactionDraft, setTransactionDraft] = useState<TransactionDraft>({
    merchantNote: "",
    amount: "",
    type: "expense",
    accountId: "acc-1",
    destinationAccountId: "acc-2",
    categoryId: "food-dining",
    date: new Date().toISOString().slice(0, 10),
    goalId: "none",
    tripId: "none",
    payee: "",
    payer: "",
    settlementStatus: "paid",
    attachments: [],
  });

  const [catNameInput, setCatNameInput] = useState("");
  const [catBudgetInput, setCatBudgetInput] = useState("");
  const [catTypeInput, setCatTypeInput] = useState<"expense" | "income">("expense");
  const [catIconInput, setCatIconInput] = useState("Tag");
  const [parentTargetId, setParentTargetId] = useState("");
  const [subNameInput, setSubNameInput] = useState("");
  const [subIconInput, setSubIconInput] = useState("Tag");
  const [accNameInput, setAccNameInput] = useState("");
  const [accKindInput, setAccKindInput] = useState<"asset" | "liability">("asset");
  const [accBalanceInput, setAccBalanceInput] = useState("");
  const [accNumberInput, setAccNumberInput] = useState("");
  const [loanDirectionInput, setLoanDirectionInput] = useState<Loan["direction"]>("borrowed");
  const [loanCounterpartyInput, setLoanCounterpartyInput] = useState("");
  const [loanTermsInput, setLoanTermsInput] = useState("");
  const [loanAccountInput, setLoanAccountInput] = useState("");
  const [goalFinancingInput, setGoalFinancingInput] = useState("");
  const [scheduleTypeInput, setScheduleTypeInput] = useState<RecurringSchedule["type"]>("expense");
  const [scheduleFrequencyInput, setScheduleFrequencyInput] = useState<ScheduleFrequency>("monthly");
  const [scheduleAccountInput, setScheduleAccountInput] = useState("acc-1");
  const [scheduleCategoryInput, setScheduleCategoryInput] = useState("home-utilities");
  const [profileMode, setProfileMode] = useState<"signIn" | "signUp">("signIn");
  const [authEmailInput, setAuthEmailInput] = useState("");
  const [authPasswordInput, setAuthPasswordInput] = useState("");
  const [authSubmitting, setAuthSubmitting] = useState(false);
  const [profileNotice, setProfileNotice] = useState<string | null>(null);
  const [cloudPrerequisitesLoaded, setCloudPrerequisitesLoaded] = useState({ accounts: false, categories: false });
  const [starterRequestedFor, setStarterRequestedFor] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<AppNotification[]>([]);
  const [dismissedFallbackNotificationIds, setDismissedFallbackNotificationIds] = useState<string[]>([]);
  const [reminderSettings, setReminderSettings] = useState<ReminderSettings>({ id: "daily-expense-reminder", enabled: false, time: "22:00", timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", currency: "USD" });
  const [reminderPushStatus, setReminderPushStatus] = useState<string | null>(null);
  const [reminderPushBusy, setReminderPushBusy] = useState(false);
  activeCurrency = reminderSettings.currency;
  const isSettingsRoute = activeTab === "settings" || activeTab.startsWith("settings-");

  useEffect(() => {
    if (!user) {
      setAccounts(INITIAL_ACCOUNTS);
      setCategories(INITIAL_CATEGORIES);
      setTransactions(INITIAL_TRANSACTIONS);
      setGoals(INITIAL_GOALS);
      setTrips(INITIAL_TRIPS);
      setLoans(INITIAL_LOANS);
      setSchedules(INITIAL_SCHEDULES);
      setRoutines([]);
      setRoutineAttendance([]);
      setCloudStatus("demo");
      setCloudError(null);
      setCloudPrerequisitesLoaded({ accounts: false, categories: false });
      setStarterRequestedFor(null);
      setNotifications([]);
      setDismissedFallbackNotificationIds([]);
      setReminderSettings({ id: "daily-expense-reminder", enabled: false, time: "22:00", timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC", currency: "USD" });
      setReminderPushStatus(null);
      return;
    }

    setCloudStatus("loading");
    setCloudError(null);
    setCloudPrerequisitesLoaded({ accounts: false, categories: false });
    setStarterRequestedFor(null);
    const handleError = (error: Error) => {
      setCloudStatus("error");
      setCloudError(ledgerErrorMessage(error, "access"));
    };
    const received = () => setCloudStatus("synced");
    const unsubscribes = [
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "accounts", (records) => { setAccounts(records.map(normaliseAccount)); setCloudPrerequisitesLoaded((current) => ({ ...current, accounts: true })); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "categories", (records) => { const flattened = records.flatMap(normaliseCategory); setCategories(Array.from(new Map(flattened.map((record) => [record.id, record])).values())); setCloudPrerequisitesLoaded((current) => ({ ...current, categories: true })); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "expenses", (records) => { setTransactions(records.map(normaliseTransaction)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "plans", (records) => { setGoals(records.map(normaliseGoal)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "tripPlans", (records) => { setTrips(records.map(normaliseTrip)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "loans", (records) => { setLoans(records.map(normaliseLoan)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "recurringIncomeSources", (records) => { setSchedules(records.map(normaliseSchedule)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "routines", (records) => { setRoutines(records.map(normaliseRoutine)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "routineAttendance", (records) => { setRoutineAttendance(records.map(normaliseRoutineAttendance)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "notifications", (records) => { setNotifications(records.map(normaliseNotification)); received(); }, handleError),
      subscribeToLedgerCollection<StoredRecordWithId>(user.uid, "reminderSettings", (records) => { const normalized = records.map(normaliseReminderSettings); const saved = normalized.find((record) => record.id === "daily-expense-reminder") ?? normalized[0]; if (saved) setReminderSettings(saved); received(); }, handleError),
    ];
    return () => unsubscribes.forEach((unsubscribe) => unsubscribe());
  }, [user]);

  useEffect(() => {
    if (!user || !cloudPrerequisitesLoaded.accounts || !cloudPrerequisitesLoaded.categories || starterRequestedFor === user.uid) return;

    setStarterRequestedFor(user.uid);
    void ensureLedgerStarter(
      user.uid,
      {
        account: { ...PERSONAL_LEDGER_STARTER_ACCOUNT, initialBalance: PERSONAL_LEDGER_STARTER_ACCOUNT.balance },
        categories: PERSONAL_LEDGER_STARTER_CATEGORIES.map((category) => ({ ...category, parent_id: category.parentId ?? null })),
      },
      { hasAccounts: accounts.length > 0, hasCategories: categories.length > 0 },
    ).then(() => {
      setCloudStatus("synced");
    }).catch((error) => {
      setCloudStatus("error");
      setCloudError(ledgerErrorMessage(error, "prepare"));
    });
  }, [accounts.length, categories.length, cloudPrerequisitesLoaded, starterRequestedFor, user]);

  useEffect(() => {
    if (draft !== "schedule" || editingScheduleId) return;
    if (!scheduleAccountInput && accounts[0]) setScheduleAccountInput(accounts[0].id);
    if (!scheduleCategoryInput) {
      const matchingCategory = categories.find((category) => category.type === scheduleTypeInput && !category.parentId) ?? categories.find((category) => category.type === scheduleTypeInput);
      if (matchingCategory) setScheduleCategoryInput(matchingCategory.id);
    }
  }, [accounts, categories, draft, editingScheduleId, scheduleAccountInput, scheduleCategoryInput, scheduleTypeInput]);

  const persistRecord = useCallback(async <T extends { id: string }>(collectionName: LedgerCollection, record: T) => {
    if (!user) return;
    setCloudError(null);
    try {
      await saveLedgerRecord(user.uid, collectionName, record);
      setCloudStatus("synced");
    } catch (error) {
      setCloudStatus("error");
      setCloudError(ledgerErrorMessage(error, "save"));
    }
  }, [user]);

  const uploadEvidence = useCallback(async (file: File): Promise<TransactionAttachment> => {
    if (!user) throw new Error("Sign in before adding an attachment.");
    if (file.size > 8 * 1024 * 1024) throw new Error("Each attachment must be smaller than 8 MB.");
    const dataUrl = await readFileAsDataUrl(file);
    const token = await user.getIdToken();
    const response = await fetch("/api/transaction-evidence", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ filename: file.name, contentType: file.type, dataUrl }),
    });
    const payload = await response.json() as TransactionAttachment | { error?: string };
    if (!response.ok || !("storageKey" in payload)) throw new Error("error" in payload ? payload.error ?? "The attachment could not be stored." : "The attachment could not be stored.");
    return payload;
  }, [user]);

  const viewEvidence = useCallback(async (attachment: TransactionAttachment) => {
    if (!user) {
      setCloudError("Sign in before viewing transaction evidence.");
      return;
    }

    const preview = window.open("", "_blank");
    if (preview) preview.opener = null;
    try {
      const token = await user.getIdToken();
      const response = await fetch(`/api/transaction-evidence/${encodeURIComponent(attachment.storageKey)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        const payload = await response.json().catch(() => null) as { error?: string } | null;
        throw new Error(payload?.error ?? "The attachment could not be retrieved.");
      }
      const file = await response.blob();
      const objectUrl = URL.createObjectURL(file);
      if (preview) preview.location.replace(objectUrl);
      else {
        const download = document.createElement("a");
        download.href = objectUrl;
        download.target = "_blank";
        download.rel = "noreferrer";
        download.click();
      }
      window.setTimeout(() => URL.revokeObjectURL(objectUrl), 60_000);
    } catch (error) {
      preview?.close();
      setCloudError(error instanceof Error ? error.message : "The attachment could not be retrieved. Please try again.");
    }
  }, [user]);

  const deletePersistedRecord = useCallback(async (collectionName: LedgerCollection, recordId: string) => {
    if (!user) return;
    setCloudError(null);
    try {
      await removeLedgerRecord(user.uid, collectionName, recordId);
      setCloudStatus("synced");
    } catch (error) {
      setCloudStatus("error");
      setCloudError(ledgerErrorMessage(error, "remove"));
    }
  }, [user]);

  const markNotificationRead = (notificationId: string) => {
    const persistedNotification = notifications.find((item) => item.id === notificationId);
    if (persistedNotification) {
      if (persistedNotification.read) return;
      const updatedNotification = { ...persistedNotification, read: true };
      setNotifications((current) => current.map((item) => item.id === notificationId ? updatedNotification : item));
      void persistRecord("notifications", { ...updatedNotification, unread: false });
      return;
    }
    setDismissedFallbackNotificationIds((current) => current.includes(notificationId) ? current : [...current, notificationId]);
  };

  const markAllNotificationsRead = () => {
    const unreadPersisted = notifications.filter((item) => !item.read);
    if (unreadPersisted.length) {
      setNotifications((current) => current.map((item) => item.read ? item : { ...item, read: true }));
      unreadPersisted.forEach((item) => { void persistRecord("notifications", { ...item, read: true, unread: false }); });
    }
    setDismissedFallbackNotificationIds((current) => Array.from(new Set([...current, ...fallbackNotificationItems.filter((item) => !item.read).map((item) => item.id)])));
  };

  const createRoutine = (name: string, daysPerWeek: RoutineDaysPerWeek) => {
    const routine: WorkRoutine = {
      id: `routine-${Date.now()}`,
      name: name.trim(),
      daysPerWeek,
      color: "#b78a3d",
      icon: "ClipboardCheck",
      createdAt: new Date().toISOString(),
      status: "active",
    };
    setRoutines((current) => [routine, ...current]);
    void persistRecord("routines", routine);
  };

  const toggleRoutineAttendance = (routineId: string, date: string) => {
    const id = `routine-attendance-${routineId}-${date}`;
    const existing = routineAttendance.find((item) => item.id === id);
    const next: RoutineAttendance = {
      id,
      routineId,
      date,
      attended: !(existing?.attended ?? false),
      updatedAt: new Date().toISOString(),
    };
    setRoutineAttendance((current) => existing ? current.map((item) => item.id === id ? next : item) : [...current, next]);
    void persistRecord("routineAttendance", next);
  };

  const removeRoutine = (routine: WorkRoutine) => {
    if (!window.confirm(`End ${routine.name}? It will leave Plans & Progress, while its attendance stays available in Data History for two years. Your money records are not affected.`)) return;
    const next: WorkRoutine = { ...routine, status: "archived", archivedAt: new Date().toISOString() };
    setRoutines((current) => current.map((item) => item.id === routine.id ? next : item));
    void persistRecord("routines", next);
  };

  const setPlanningCompletion = (kind: "goal" | "trip" | "loan", record: Goal | Trip | Loan, completed: boolean) => {
    const lifecycle = { status: completed ? "completed" as const : "active" as const, completedAt: completed ? new Date().toISOString() : undefined };
    if (kind === "goal") {
      const next = { ...(record as Goal), ...lifecycle };
      setGoals((current) => current.map((item) => item.id === next.id ? next : item));
      void persistRecord("plans", { ...next, title: next.name, history: next.fundingHistory });
      setGoalDetail(next);
    } else if (kind === "trip") {
      const next = { ...(record as Trip), ...lifecycle };
      setTrips((current) => current.map((item) => item.id === next.id ? next : item));
      void persistRecord("tripPlans", { ...next, title: next.name, dateRange: next.dates });
      setTripDetail(next);
    } else {
      const next = { ...(record as Loan), ...lifecycle };
      setLoans((current) => current.map((item) => item.id === next.id ? next : item));
      void persistRecord("loans", next);
      setLoanDetail(next);
    }
  };

  const saveReminderSettings = useCallback(async (nextSettings: ReminderSettings) => {
    if (!user) {
      setReminderPushStatus("Sign in first to save this reminder to your personal ledger.");
      return false;
    }
    setReminderPushBusy(true);
    setReminderPushStatus("Saving your reminder…");
    setCloudError(null);
    try {
      await saveLedgerRecord(user.uid, "reminderSettings", nextSettings);
      setReminderSettings(nextSettings);
      setCloudStatus("synced");
      setReminderPushStatus(nextSettings.enabled ? `Daily reminder saved for ${formatReminderTime(nextSettings.time)}.` : "Daily reminder turned off.");
      return true;
    } catch {
      setCloudStatus("error");
      setCloudError("Your reminder could not be saved to the cloud ledger. Check your connection and try again.");
      setReminderPushStatus("Not saved yet. Please try again.");
      return false;
    } finally {
      setReminderPushBusy(false);
    }
  }, [user]);

  const enableDailyDeviceReminder = async () => {
    if (!user) {
      setReminderPushStatus("Sign in first to save reminders to your personal ledger.");
      return;
    }
    const nextSettings = {
      ...reminderSettings,
      enabled: true,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
    };
    const saved = await saveReminderSettings(nextSettings);
    if (!saved) return;
    setReminderPushBusy(true);
    try {
      const result = await enableExpenseReminderPush(user.uid);
      setReminderPushStatus(result.status === "enabled" ? "Daily reminder saved. Device notifications are ready for this browser." : `Daily reminder saved. ${result.message}`);
    } catch {
      setReminderPushStatus("Daily reminder saved. Device notifications can be enabled later from this browser.");
    } finally {
      setReminderPushBusy(false);
    }
  };

  const deleteCategory = (categoryId: string) => {
    const category = categories.find((item) => item.id === categoryId);
    if (category?.isPermanent) {
      alert("This is a permanent expense type. You can add detailed subcategories beneath it, but the container stays in place.");
      return;
    }
    const idsToDelete = categories.filter((category) => category.id === categoryId || category.parentId === categoryId).map((category) => category.id);
    setCategories((current) => current.filter((category) => !idsToDelete.includes(category.id)));
    idsToDelete.forEach((id) => void deletePersistedRecord("categories", id));
  };

  const submitAuthentication = async () => {
    if (!authEmailInput.trim() || !authPasswordInput) {
      alert("Enter both your email address and password.");
      return;
    }
    setAuthSubmitting(true);
    setProfileNotice(null);
    try {
      if (profileMode === "signUp") {
        await signUp(authEmailInput, authPasswordInput);
        setProfileNotice("Your account is ready. You can request a verification link later from Profile when you are ready.");
      } else {
        await signIn(authEmailInput, authPasswordInput);
      }
      setAuthPasswordInput("");
    } catch {
      // AuthContext exposes an actionable, provider-safe message in this panel.
    } finally {
      setAuthSubmitting(false);
    }
  };

  const handleProfileAction = async (action: "verification" | "refreshVerification" | "passwordReset") => {
    setAuthSubmitting(true);
    setProfileNotice(null);
    clearError();
    try {
      if (action === "verification") {
        await sendVerification();
        setProfileNotice("Verification email sent. Open the link in the same browser, then return here and choose Refresh status.");
      } else if (action === "refreshVerification") {
        await refreshVerification();
        setProfileNotice("Status refreshed. If this still reads Not verified, open the newest verification link in your inbox and try again.");
      } else {
        const resetEmail = user?.email ?? authEmailInput;
        if (!resetEmail?.trim()) {
          setProfileNotice("Enter your email address first, then request a password reset.");
          return;
        }
        await requestPasswordReset(resetEmail);
        setProfileNotice("Password-reset instructions were sent. Check Inbox, Spam, and Promotions, then use the newest link.");
      }
    } catch (caught) {
      setProfileNotice(caught instanceof Error ? caught.message : "That account action could not be completed. Try again in a moment.");
    } finally {
      setAuthSubmitting(false);
    }
  };

  const totals = useMemo(() => {
    let income = 0;
    let expense = 0;
    let ordinaryIncome = 0;
    let ordinaryExpense = 0;
    for (const transaction of transactions) {
      if (transaction.type === "income") {
        income += transaction.amount;
        if (!transaction.cashFlowKind) ordinaryIncome += transaction.amount;
      }
      if (transaction.type === "expense") {
        expense += transaction.amount;
        if (!transaction.cashFlowKind) ordinaryExpense += transaction.amount;
      }
    }
    return { income, expense, ordinaryIncome, ordinaryExpense, loanInflow: income - ordinaryIncome, loanOutflow: expense - ordinaryExpense };
  }, [transactions]);

  const accountsWithBalance = useMemo(() => {
    return accounts.map((account) => {
      let balance = account.balance;
      for (const transaction of transactions) {
        if (transaction.type === "income" && transaction.accountId === account.id) balance += transaction.amount;
        if (transaction.type === "expense" && transaction.accountId === account.id) balance -= transaction.amount;
        if (transaction.type === "transfer") {
          if (transaction.accountId === account.id) balance -= transaction.amount;
          if (transaction.destinationAccountId === account.id) balance += transaction.amount;
        }
      }
      return { ...account, balance };
    });
  }, [accounts, transactions]);

  const loanNetPosition = useMemo(() => loans.reduce((sum, loan) => {
    const outstanding = Math.max(0, loan.totalAmount - loan.paidAmount);
    return sum + (loan.direction === "lent" ? outstanding : -outstanding);
  }, 0), [loans]);

  const netWorth = useMemo(() => {
    return accountsWithBalance.reduce((sum, account) => account.kind === "liability" ? sum - account.balance : sum + account.balance, 0) + loanNetPosition;
  }, [accountsWithBalance, loanNetPosition]);

  const fallbackNotificationItems = useMemo<AppNotification[]>(() => {
    const today = dateInputValue(new Date());
    const inSevenDays = dateInputValue(new Date(Date.now() + 7 * 86400000));
    const loanItems = loans.filter((loan) => loan.paidAmount < loan.totalAmount && loan.dueDate <= inSevenDays).map((loan) => ({ id: `loan-${loan.id}-${loan.dueDate}`, tone: loan.dueDate < today ? "urgent" as const : "notice" as const, title: loan.dueDate < today ? `${loan.title} is overdue` : `${loan.title} is due soon`, detail: `${fmt.format(Math.max(0, loan.totalAmount - loan.paidAmount))} ${loan.direction === "borrowed" ? "owed" : "to collect"}`, createdAt: loan.dueDate, read: dismissedFallbackNotificationIds.includes(`loan-${loan.id}-${loan.dueDate}`) }));
    const scheduleItems = schedules.filter((schedule) => schedule.status === "active" && schedule.nextDueDate <= inSevenDays).map((schedule) => ({ id: `schedule-${schedule.id}-${schedule.nextDueDate}`, tone: schedule.nextDueDate < today ? "urgent" as const : "notice" as const, title: schedule.nextDueDate < today ? `${schedule.name} is overdue` : `${schedule.name} is due soon`, detail: `${fmt.format(schedule.amount)} · ${schedule.type === "income" ? "income" : "bill"}`, createdAt: schedule.nextDueDate, read: dismissedFallbackNotificationIds.includes(`schedule-${schedule.id}-${schedule.nextDueDate}`) }));
    return [...loanItems, ...scheduleItems].slice(0, 5);
  }, [dismissedFallbackNotificationIds, loans, schedules]);

  const notificationItems = useMemo(() => {
    const persistentIds = new Set(notifications.map((item) => item.id));
    return [...notifications, ...fallbackNotificationItems.filter((item) => !persistentIds.has(item.id))]
      .sort((first, second) => second.createdAt.localeCompare(first.createdAt));
  }, [fallbackNotificationItems, notifications]);

  const unreadNotificationCount = useMemo(() => notificationItems.filter((item) => !item.read).length, [notificationItems]);

  const availableBalance = useMemo(() => {
    return accountsWithBalance.filter(a => a.kind === "asset").reduce((sum, a) => sum + a.balance, 0);
  }, [accountsWithBalance]);

  const categorySpent = useMemo(() => {
    const map: Record<string, number> = {};
    for (const transaction of transactions) {
      if (transaction.type === "expense" && transaction.categoryId) {
        map[transaction.categoryId] = (map[transaction.categoryId] ?? 0) + transaction.amount;
        const category = categories.find((c) => c.id === transaction.categoryId);
        if (category?.parentId) {
          map[category.parentId] = (map[category.parentId] ?? 0) + transaction.amount;
        }
      }
    }
    return map;
  }, [transactions, categories]);

  const subcategorySpent = useMemo(() => {
    const map: Record<string, number> = {};
    for (const transaction of transactions) {
      if (transaction.type === "expense" && transaction.categoryId) {
        map[transaction.categoryId] = (map[transaction.categoryId] ?? 0) + transaction.amount;
      }
    }
    return map;
  }, [transactions]);

  const filteredTransactions = useMemo(() => {
    return transactions.filter((transaction) => {
      if (filter !== "all" && transaction.type !== filter) return false;
      if (categoryFilterId) {
        if (transaction.categoryId !== categoryFilterId) {
          const category = categories.find((c) => c.id === transaction.categoryId);
          if (category?.parentId !== categoryFilterId) return false;
        }
      }
      if (query.trim()) {
        const text = query.toLowerCase();
        const merchant = transaction.merchantNote.toLowerCase();
        const category = categories.find((c) => c.id === transaction.categoryId)?.name.toLowerCase() ?? "";
        if (!merchant.includes(text) && !category.includes(text)) return false;
      }
      return true;
    });
  }, [transactions, filter, categoryFilterId, query, categories]);

  const startCreatingGoal = () => {
    setEditingGoalId(null);
    setDraftTitle("");
    setDraftAmount("");
    setDraftDate(oneYearFromToday());
    setGoalFinancingInput("");
    setDraft("goal");
  };

  const startCreatingTrip = () => {
    setEditingTripId(null);
    setDraftTitle("");
    setDraftAmount("");
    setDraftDate(oneYearFromToday());
    setDraft("trip");
  };

  const startCreatingLoan = () => {
    setEditingLoanId(null);
    setLoanDirectionInput("borrowed");
    setLoanCounterpartyInput("");
    setLoanTermsInput("Monthly repayment");
    setLoanAccountInput(accounts[0]?.id ?? "");
    setDraftTitle("");
    setDraftAmount("");
    setDraftDate("2026-12-31");
    setDraft("loan");
  };

  const startCreatingSchedule = () => {
    const expenseCategory = categories.find((category) => category.type === "expense" && !category.parentId)?.id ?? categories.find((category) => category.type === "expense")?.id ?? "";
    setEditingScheduleId(null);
    setScheduleTypeInput("expense");
    setScheduleFrequencyInput("monthly");
    setScheduleAccountInput(accounts[0]?.id ?? "");
    setScheduleCategoryInput(expenseCategory);
    setDraftTitle("");
    setDraftAmount("");
    setDraftDate(dateInputValue(new Date()));
    setDraft("schedule");
  };

  const startEditingGoal = (goal: Goal) => {
    setGoalDetail(null);
    setEditingGoalId(goal.id);
    setDraftTitle(goal.name);
    setDraftAmount(String(goal.target));
    setDraftDate(normaliseCalendarDate(goal.deadline, new Date()));
    setGoalFinancingInput(goal.financedAmount ? String(goal.financedAmount) : "");
    setDraft("goal");
  };

  const startEditingTrip = (trip: Trip) => {
    setTripDetail(null);
    setEditingTripId(trip.id);
    setDraftTitle(trip.name);
    setDraftAmount(String(trip.budget));
    setDraftDate(normaliseCalendarDate(trip.dates, new Date()));
    setDraft("trip");
  };

  const startEditingLoan = (loan: Loan) => {
    setLoanDetail(null);
    setEditingLoanId(loan.id);
    setLoanDirectionInput(loan.direction);
    setLoanCounterpartyInput(loan.counterparty);
    setLoanTermsInput(loan.terms);
    setLoanAccountInput(loan.cashAccountId ?? accounts[0]?.id ?? "");
    setDraftTitle(loan.title);
    setDraftAmount(String(loan.totalAmount));
    setDraftDate(loan.dueDate);
    setDraft("loan");
  };

  const startEditingSchedule = (schedule: RecurringSchedule) => {
    setScheduleDetail(null);
    setEditingScheduleId(schedule.id);
    setScheduleTypeInput(schedule.type);
    setScheduleFrequencyInput(schedule.frequency);
    setScheduleAccountInput(schedule.accountId);
    setScheduleCategoryInput(schedule.categoryId);
    setDraftTitle(schedule.name);
    setDraftAmount(String(schedule.amount));
    setDraftDate(schedule.nextDueDate);
    setDraft("schedule");
  };

  const submitGoalAdjustment = () => {
    const parsed = parseFloat(goalAdjustmentAmount);
    if (!goalDetail || !goalAdjustment || isNaN(parsed) || parsed <= 0) {
      alert("Please enter a valid adjustment amount.");
      return;
    }
    const metrics = goalMetrics(goalDetail);
    const applied = goalAdjustment === "deposit" ? Math.min(parsed, metrics.remaining) : Math.min(parsed, goalDetail.saved);
    if (applied <= 0) {
      alert(goalAdjustment === "deposit" ? "This goal is already fully funded." : "There is no saved balance available to withdraw.");
      return;
    }
    const nextSaved = goalAdjustment === "deposit" ? goalDetail.saved + applied : goalDetail.saved - applied;
    const funding: GoalFunding = { id: `goal-funding-${Date.now()}`, amount: applied, type: goalAdjustment, date: new Date().toISOString().slice(0, 10), note: goalAdjustmentNote.trim() || (goalAdjustment === "deposit" ? "Goal contribution" : "Moved back to available funds") };
    const nextGoal = { ...goalDetail, saved: nextSaved, fundingHistory: [funding, ...(goalDetail.fundingHistory ?? [])] };
    setGoals((current) => current.map((goal) => goal.id === nextGoal.id ? nextGoal : goal));
    void persistRecord("plans", { ...nextGoal, title: nextGoal.name, history: nextGoal.fundingHistory });
    setGoalDetail(nextGoal);
    setGoalAdjustment(null);
    setGoalAdjustmentAmount("");
    setGoalAdjustmentNote("");
  };

  const resetLoanPaymentDraft = () => {
    setLoanPaymentAmount("");
    setLoanPaymentMethod("Cash in hand");
    setLoanCustomPaymentMethod("");
    setLoanPaymentNote("");
    setLoanPaymentReference("");
  };

  const submitLoanPayment = () => {
    const parsed = parseFloat(loanPaymentAmount);
    if (!loanDetail || isNaN(parsed) || parsed <= 0) {
      alert("Please enter a valid payment amount.");
      return;
    }
    const remaining = Math.max(0, loanDetail.totalAmount - loanDetail.paidAmount);
    const applied = Math.min(parsed, remaining);
    const method = loanPaymentMethod === "Custom" ? loanCustomPaymentMethod.trim() || "Custom method" : loanPaymentMethod;
    const transactionId = `tx-loan-settlement-${Date.now()}`;
    const settlementTransaction: Transaction = {
      id: transactionId,
      merchantNote: loanDetail.direction === "borrowed" ? `Loan repayment · ${loanDetail.title}` : `Loan collection · ${loanDetail.title}`,
      amount: applied,
      type: loanDetail.direction === "borrowed" ? "expense" : "income",
      accountId: loanDetail.cashAccountId ?? accounts[0]?.id ?? "acc-1",
      date: new Date().toISOString().slice(0, 10),
      icon: loanDetail.direction === "borrowed" ? "ArrowUpRight" : "ArrowDownRight",
      loanId: loanDetail.id,
      cashFlowKind: "loan-settlement",
    };
    const payment: LoanPayment = {
      id: `loan-payment-${Date.now()}`,
      amount: applied,
      date: new Date().toISOString().slice(0, 10),
      note: loanPaymentNote.trim() || (loanDetail.direction === "borrowed" ? "Payment made" : "Payment received"),
      method,
      reference: loanPaymentReference.trim() || undefined,
      transactionId,
    };
    const nextLoan: Loan = {
      ...loanDetail,
      paidAmount: loanDetail.paidAmount + applied,
      paymentHistory: [payment, ...loanDetail.paymentHistory],
    };
    setLoans((current) => current.map((loan) => loan.id === nextLoan.id ? nextLoan : loan));
    setTransactions((current) => [settlementTransaction, ...current]);
    void persistRecord("loans", nextLoan);
    void persistRecord("expenses", { ...settlementTransaction, title: settlementTransaction.merchantNote });
    setLoanDetail(nextLoan);
    resetLoanPaymentDraft();
  };

  const recordScheduledTransaction = () => {
    if (!scheduleDetail || scheduleDetail.status !== "active") return;
    const recordedAt = dateInputValue(new Date());
    const transaction: Transaction = {
      id: `tx-${Date.now()}`,
      merchantNote: scheduleDetail.name,
      amount: scheduleDetail.amount,
      type: scheduleDetail.type,
      accountId: scheduleDetail.accountId,
      categoryId: scheduleDetail.categoryId,
      date: recordedAt,
      icon: "Repeat",
    };
    const occurrence: ScheduleOccurrence = { id: `schedule-occurrence-${Date.now()}`, scheduledFor: scheduleDetail.nextDueDate, recordedAt, transactionId: transaction.id };
    const nextSchedule: RecurringSchedule = {
      ...scheduleDetail,
      nextDueDate: advanceScheduleDate(scheduleDetail.nextDueDate, scheduleDetail.frequency),
      history: [occurrence, ...scheduleDetail.history],
    };
    setTransactions((current) => [transaction, ...current]);
    setSchedules((current) => current.map((schedule) => schedule.id === nextSchedule.id ? nextSchedule : schedule));
    const scheduledCategory = categories.find((category) => category.id === transaction.categoryId);
    void persistRecord("expenses", { ...transaction, title: transaction.merchantNote, webCategoryId: transaction.categoryId, categoryId: scheduledCategory?.parentId ?? transaction.categoryId, subCategory: scheduledCategory?.parentId ? scheduledCategory.name : undefined });
    void persistRecord("recurringIncomeSources", { ...nextSchedule, expectedAmount: nextSchedule.amount });
    setScheduleDetail(nextSchedule);
  };

  const setScheduleStatus = (schedule: RecurringSchedule, status: RecurringSchedule["status"]) => {
    const nextSchedule = { ...schedule, status };
    setSchedules((current) => current.map((item) => item.id === nextSchedule.id ? nextSchedule : item));
    void persistRecord("recurringIncomeSources", { ...nextSchedule, expectedAmount: nextSchedule.amount });
    setScheduleDetail(nextSchedule);
  };

  const startCreatingTransaction = () => {
    setTransactionDraft({
      merchantNote: "",
      amount: "",
      type: "expense",
      accountId: accounts[0]?.id ?? "",
      destinationAccountId: accounts[1]?.id ?? accounts[0]?.id ?? "",
      categoryId: categories.find(c => c.type === "expense" && !c.parentId)?.id ?? categories.find(c => c.type === "expense")?.id ?? "",
      date: new Date().toISOString().slice(0, 10),
      goalId: "none",
      tripId: "none",
      payee: "",
      payer: "",
      settlementStatus: "paid",
      attachments: [],
    });
    setDraft("transaction");
  };

  const startEditingTransaction = (transaction: Transaction) => {
    setTransactionDetail(null);
    setTransactionDraft({
      id: transaction.id,
      merchantNote: transaction.merchantNote,
      amount: String(transaction.amount),
      type: transaction.type,
      accountId: transaction.accountId,
      destinationAccountId: transaction.destinationAccountId ?? accounts[1]?.id ?? "acc-2",
      categoryId: transaction.categoryId ?? categories.find(c => c.type === "expense" && !c.parentId)?.id ?? "food-dining",
      date: transaction.date,
      goalId: transaction.tag?.goalId ?? "none",
      tripId: transaction.tag?.tripId ?? "none",
      payee: transaction.payee ?? "",
      payer: transaction.payer ?? "",
      settlementStatus: transaction.settlementStatus ?? "paid",
      attachments: transaction.attachments ?? [],
    });
    setDraft("transaction");
  };

  const resetDraft = () => {
    setDraft(null);
    setEditingGoalId(null);
    setEditingTripId(null);
    setEditingLoanId(null);
    setEditingScheduleId(null);
    setDraftTitle("");
    setDraftAmount("");
    setCatNameInput("");
    setCatBudgetInput("");
    setCatIconInput("Tag");
    setSubNameInput("");
    setSubIconInput("Tag");
    setAccNameInput("");
    setAccBalanceInput("");
    setAccNumberInput("");
    setLoanCounterpartyInput("");
    setLoanTermsInput("");
    setGoalFinancingInput("");
    setScheduleTypeInput("expense");
    setScheduleFrequencyInput("monthly");
    setScheduleAccountInput(accounts[0]?.id ?? "acc-1");
    setScheduleCategoryInput(categories.find((category) => category.type === "expense" && !category.parentId)?.id ?? "food-dining");
  };

  const saveDraft = () => {
    if (draft === "transaction") {
      const parsedAmount = parseFloat(transactionDraft.amount);
      if (!transactionDraft.merchantNote.trim() || isNaN(parsedAmount) || parsedAmount <= 0) {
        alert("Please provide a merchant note and a valid amount.");
        return;
      }
      const newTransaction: Transaction = {
        id: transactionDraft.id ?? `tx-${Date.now()}`,
        merchantNote: transactionDraft.merchantNote.trim(),
        amount: parsedAmount,
        type: transactionDraft.type,
        accountId: transactionDraft.accountId,
        destinationAccountId: transactionDraft.type === "transfer" ? transactionDraft.destinationAccountId : undefined,
        categoryId: transactionDraft.type !== "transfer" ? transactionDraft.categoryId : undefined,
        date: transactionDraft.date,
        tag: {
          goalId: transactionDraft.goalId !== "none" ? transactionDraft.goalId : undefined,
          tripId: transactionDraft.tripId !== "none" ? transactionDraft.tripId : undefined,
        },
        icon: transactionDraft.type === "income" ? "ArrowDownRight" : transactionDraft.type === "expense" ? "ShoppingCart" : "Repeat",
        payee: transactionDraft.payee.trim() || undefined,
        payer: transactionDraft.payer.trim() || undefined,
        settlementStatus: transactionDraft.settlementStatus,
        attachments: transactionDraft.attachments,
      };

      if (transactionDraft.id) {
        setTransactions((current) => current.map((t) => t.id === transactionDraft.id ? newTransaction : t));
      } else {
        setTransactions((current) => [newTransaction, ...current]);
      }
      const selectedCategory = categories.find((category) => category.id === newTransaction.categoryId);
      void persistRecord("expenses", { ...newTransaction, title: newTransaction.merchantNote, webCategoryId: newTransaction.categoryId, categoryId: selectedCategory?.parentId ?? newTransaction.categoryId, subCategory: selectedCategory?.parentId ? selectedCategory.name : undefined, planId: newTransaction.tag?.goalId });
      resetDraft();
    } else if (draft === "goal") {
      const parsed = parseFloat(draftAmount);
      if (!draftTitle.trim() || isNaN(parsed) || parsed <= 0) {
        alert("Please enter a valid goal title and target amount.");
        return;
      }
      const financed = Math.min(parsed, Math.max(0, parseFloat(goalFinancingInput) || 0));
      const previousGoal = editingGoalId ? goals.find((goal) => goal.id === editingGoalId) : undefined;
      const deadline = normaliseCalendarDate(draftDate, new Date());
      const nextGoal: Goal = previousGoal ? { ...previousGoal, name: draftTitle.trim(), target: parsed, deadline, financedAmount: financed, saved: Math.min(previousGoal.saved, Math.max(0, parsed - financed)), fundingHistory: previousGoal.fundingHistory ?? [], ...(previousGoal.status === "completed" && new Date(deadline) >= new Date(new Date().toDateString()) && previousGoal.saved < Math.max(0, parsed - financed) ? { status: "active" as const, completedAt: undefined } : {}) } : { id: `goal-${Date.now()}`, name: draftTitle.trim(), target: parsed, saved: 0, deadline, financedAmount: financed, fundingHistory: [], status: "active" };
      setGoals((current) => editingGoalId ? current.map((goal) => goal.id === editingGoalId ? nextGoal : goal) : [nextGoal, ...current]);
      void persistRecord("plans", { ...nextGoal, title: nextGoal.name, history: nextGoal.fundingHistory });
      resetDraft();
    } else if (draft === "trip") {
      const parsed = parseFloat(draftAmount);
      if (!draftTitle.trim() || isNaN(parsed) || parsed <= 0) {
        alert("Please enter a valid trip name and budget.");
        return;
      }
      const dates = normaliseCalendarDate(draftDate, new Date());
      const previousTrip = editingTripId ? trips.find((trip) => trip.id === editingTripId) : undefined;
      const nextTrip: Trip = previousTrip ? { ...previousTrip, name: draftTitle.trim(), budget: parsed, dates, ...(previousTrip.status === "completed" && new Date(dates) >= new Date(new Date().toDateString()) ? { status: "active" as const, completedAt: undefined } : {}) } : { id: `trip-${Date.now()}`, name: draftTitle.trim(), budget: parsed, dates, status: "active" };
      setTrips((current) => editingTripId ? current.map((trip) => trip.id === editingTripId ? nextTrip : trip) : [nextTrip, ...current]);
      void persistRecord("tripPlans", { ...nextTrip, title: nextTrip.name, dateRange: nextTrip.dates });
      resetDraft();
    } else if (draft === "loan") {
      const parsed = parseFloat(draftAmount);
      if (!draftTitle.trim() || !loanCounterpartyInput.trim() || isNaN(parsed) || parsed <= 0 || !draftDate) {
        alert("Please enter a loan name, counterparty, original amount, and due date.");
        return;
      }
      if (!loanAccountInput) {
        alert("Choose the cash account that received or provided this loan.");
        return;
      }
      const previousLoan = editingLoanId ? loans.find((loan) => loan.id === editingLoanId) : undefined;
      const createdLoanId = `loan-${Date.now()}`;
      const disbursementTransactionId = `tx-loan-disbursement-${Date.now()}`;
      const nextLoan: Loan = previousLoan ? { ...previousLoan, title: draftTitle.trim(), direction: loanDirectionInput, counterparty: loanCounterpartyInput.trim(), totalAmount: parsed, paidAmount: Math.min(previousLoan.paidAmount, parsed), dueDate: draftDate, terms: loanTermsInput.trim() || "Due in full by the due date", cashAccountId: loanAccountInput, ...(previousLoan.status === "completed" && new Date(draftDate) >= new Date(new Date().toDateString()) && previousLoan.paidAmount < parsed ? { status: "active" as const, completedAt: undefined } : {}) } : { id: createdLoanId, title: draftTitle.trim(), direction: loanDirectionInput, counterparty: loanCounterpartyInput.trim(), totalAmount: parsed, paidAmount: 0, dueDate: draftDate, terms: loanTermsInput.trim() || "Due in full by the due date", paymentHistory: [], cashAccountId: loanAccountInput, disbursementTransactionId, status: "active" };
      setLoans((current) => editingLoanId ? current.map((loan) => loan.id === editingLoanId ? nextLoan : loan) : [nextLoan, ...current]);
      void persistRecord("loans", nextLoan);
      if (!previousLoan) {
        const disbursementTransaction: Transaction = {
          id: disbursementTransactionId,
          merchantNote: loanDirectionInput === "borrowed" ? `Loan received · ${nextLoan.title}` : `Loan advanced · ${nextLoan.title}`,
          amount: parsed,
          type: loanDirectionInput === "borrowed" ? "income" : "expense",
          accountId: loanAccountInput,
          date: dateInputValue(new Date()),
          icon: loanDirectionInput === "borrowed" ? "ArrowDownRight" : "ArrowUpRight",
          loanId: nextLoan.id,
          cashFlowKind: "loan-disbursement",
        };
        setTransactions((current) => [disbursementTransaction, ...current]);
        void persistRecord("expenses", { ...disbursementTransaction, title: disbursementTransaction.merchantNote });
      }
      resetDraft();
    } else if (draft === "schedule") {
      const parsed = parseFloat(draftAmount);
      const selectedCategory = categories.find((category) => category.id === scheduleCategoryInput);
      if (!draftTitle.trim() || isNaN(parsed) || parsed <= 0 || !draftDate || !scheduleAccountInput || !selectedCategory || selectedCategory.type !== scheduleTypeInput) {
        alert("Please enter a schedule name, amount, matching category, account, and next due date.");
        return;
      }
      const existing = editingScheduleId ? schedules.find((schedule) => schedule.id === editingScheduleId) : undefined;
      const nextSchedule: RecurringSchedule = {
        id: editingScheduleId ?? `schedule-${Date.now()}`,
        name: draftTitle.trim(),
        amount: parsed,
        type: scheduleTypeInput,
        frequency: scheduleFrequencyInput,
        accountId: scheduleAccountInput,
        categoryId: scheduleCategoryInput,
        nextDueDate: draftDate,
        status: existing?.status ?? "active",
        history: existing?.history ?? [],
      };
      setSchedules((current) => editingScheduleId ? current.map((schedule) => schedule.id === editingScheduleId ? nextSchedule : schedule) : [nextSchedule, ...current]);
      void persistRecord("recurringIncomeSources", { ...nextSchedule, expectedAmount: nextSchedule.amount });
      resetDraft();
    } else if (draft === "category") {
      if (!catNameInput.trim()) {
        alert("Please enter a category name.");
        return;
      }
      const newCat: Category = {
        id: `cat-${Date.now()}`,
        name: catNameInput.trim(),
        type: catTypeInput,
        monthlyBudget: catTypeInput === "expense" ? parseFloat(catBudgetInput) || 0 : 0,
        color: catTypeInput === "expense" ? "#1b3a2b" : "#2c5234",
        icon: catIconInput,
      };
      setCategories((current) => [...current, newCat]);
      void persistRecord("categories", { ...newCat, parentId: null, parent_id: null });
      resetDraft();
    } else if (draft === "subcategory") {
      if (!subNameInput.trim() || !parentTargetId) {
        alert("Please select a parent category and enter a subcategory name.");
        return;
      }
      const newSub: Category = {
        id: `sub-${Date.now()}`,
        name: subNameInput.trim(),
        type: "expense",
        parentId: parentTargetId,
        monthlyBudget: 0,
        color: "#3d5a45",
        icon: subIconInput,
      };
      setCategories((current) => [...current, newSub]);
      void persistRecord("categories", { ...newSub, parent_id: newSub.parentId ?? null });
      resetDraft();
    } else if (draft === "account") {
      const parsed = parseFloat(accBalanceInput);
      if (!accNameInput.trim() || isNaN(parsed)) {
        alert("Please enter a valid account name and starting balance.");
        return;
      }
      const newAcc: Account = {
        id: `acc-${Date.now()}`,
        name: accNameInput.trim(),
        kind: accKindInput,
        balance: parsed,
        accountNumber: accNumberInput.trim() || "··· 9912",
        color: accKindInput === "asset" ? "#1b3a2b" : "#8b2626",
      };
      setAccounts((current) => [...current, newAcc]);
      void persistRecord("accounts", { ...newAcc, initialBalance: newAcc.balance });
      resetDraft();
    }
  };

  return (
    <div className="app-container">
      <aside className="sidebar-rail">
        <div className="brand-lockup">
          <span className="brand-mark" aria-hidden="true"><i className="ledger-spine ledger-spine-left" /><i className="ledger-spine ledger-spine-right" /></span>
          <div>
            <strong>Expense</strong>
            <span>Financial Fieldbook</span>
          </div>
        </div>
        <div className="rail-section-label">Your ledger</div>
        <nav className="rail-nav">
          <button className={`rail-button ${activeTab === "overview" ? "active" : ""}`} onClick={() => setActiveTab("overview")}><Wallet size={16} /> Overview</button>
          <button className={`rail-button ${activeTab === "history" ? "active" : ""}`} onClick={() => { setHistoryOrigin("overview"); setActiveTab("history"); }}><Layers size={16} /> History</button>
          <button className={`rail-button ${activeTab === "insights" ? "active" : ""}`} onClick={() => setActiveTab("insights")}><ArrowUpRight size={16} /> Insights</button>
          <button className={`rail-button ${activeTab === "horizon" ? "active" : ""}`} onClick={() => setActiveTab("horizon")}><Compass size={16} /> Plans & Progress</button>
          <button className={`rail-button ${isSettingsRoute ? "active" : ""}`} onClick={() => setActiveTab("settings")}><ShieldCheck size={16} /> Settings</button>
        </nav>
        <div className="rail-footer">
          <div className="rail-kicker">August close</div>
          <div className="rail-metric"><strong>16 days left</strong><span>{fmt.format(totals.ordinaryExpense)} recorded against budget plans.</span></div>
        </div>
      </aside>

      <main className="content-viewport">
        <header className="top-nav-bar">
          <div className="mobile-brand-lockup"><span className="mobile-brand-mark" aria-hidden="true"><i className="ledger-spine ledger-spine-left" /><i className="ledger-spine ledger-spine-right" /></span><div><strong>EXPENSE</strong><span>FIELD BOOK</span></div></div>
          <div className="breadcrumb"><span>/</span><strong>{activeTab === "horizon" ? "Plans & Progress" : activeTab === "inbox" ? "Notification inbox" : activeTab === "accounts" ? "Accounts & Assets" : activeTab === "settings-expenses" ? "Expense categories" : activeTab === "settings-income" ? "Income sources" : activeTab === "settings-currency" ? "Ledger currency" : activeTab === "settings-reminders" ? "Daily ledger reminder" : activeTab[0].toUpperCase() + activeTab.slice(1)}</strong></div>
          <div className="top-nav-actions">
            <div className="notification-wrap">
              <button className={`icon-badge ${unreadNotificationCount ? "has-unread" : ""} ${activeTab === "inbox" ? "is-active" : ""}`} onClick={() => setActiveTab("inbox")} aria-label={`Open notification inbox${unreadNotificationCount ? `, ${unreadNotificationCount} unread` : ""}`} aria-current={activeTab === "inbox" ? "page" : undefined}><Bell size={16} />{unreadNotificationCount > 0 && <i aria-hidden="true">{unreadNotificationCount > 9 ? "9+" : unreadNotificationCount}</i>}</button>
            </div>
            <button className="profile-pill" onClick={() => setDraft("profile")} aria-label={user ? "Open signed-in profile" : "Sign in to cloud ledger"}>{authLoading ? "··" : (user?.email?.slice(0, 2) || "IL").toUpperCase()}</button>
          </div>
        </header>

        <div className="page-body">
          {activeTab === "overview" && (
            <OverviewView
              balance={availableBalance}
              netWorth={netWorth}
              accounts={accountsWithBalance}
              totals={totals}
              categories={categories}
              transactions={filteredTransactions}
              schedules={schedules}
              filter={filter}
              categoryFilterId={categoryFilterId}
              query={query}
              onFilter={setFilter}
              onQuery={setQuery}
              onClearCategory={() => setCategoryFilterId(null)}
              onSelectTransaction={(tx) => setTransactionDetail(tx)}
              onOpenSchedule={(schedule) => setScheduleDetail(schedule)}
              onOpenHistory={() => { setHistoryOrigin("overview"); setHistoryPendingOnly(false); setActiveTab("history"); }}
              onOpenPendingHistory={() => { setHistoryOrigin("overview"); setHistoryPendingOnly(true); setActiveTab("history"); }}
            />
          )}

          {activeTab === "history" && (
            <HistoryView
              totals={totals}
              categories={categories}
              categorySpent={categorySpent}
              transactions={transactions}
              visibleTransactions={filteredTransactions}
              filter={filter}
              categoryFilterId={categoryFilterId}
              query={query}
              onFilter={setFilter}
              onQuery={setQuery}
              onClearCategory={() => setCategoryFilterId(null)}
              onOpenCategory={(id) => setCategoryFilterId(id)}
              onSelectTransaction={(tx) => setTransactionDetail(tx)}
              pendingOnly={historyPendingOnly}
              onPendingOnlyChange={setHistoryPendingOnly}
              archivedGoals={goals.filter((goal) => !planningIsActive(goal) && isWithinTwoYearRetention(goal.completedAt))}
              archivedTrips={trips.filter((trip) => !planningIsActive(trip) && isWithinTwoYearRetention(trip.completedAt))}
              archivedLoans={loans.filter((loan) => !planningIsActive(loan) && isWithinTwoYearRetention(loan.completedAt))}
              onOpenGoal={(goal) => setGoalDetail(goal)}
              onOpenTrip={(trip) => setTripDetail(trip)}
              onOpenLoan={(loan) => setLoanDetail(loan)}
              backLabel={historyOrigin === "settings-history" ? "Back to Data History" : "Back to Overview"}
              onBack={() => setActiveTab(historyOrigin)}
            />
          )}

          {activeTab === "accounts" && (
            <AccountsAssetsView
              accounts={accountsWithBalance}
              netWorth={netWorth}
              onOpenAddAccount={() => setDraft("account")}
              onBack={() => setActiveTab("settings")}
            />
          )}

          {activeTab === "insights" && (
            <InsightsView
              transactions={transactions}
              categories={categories}
              categorySpent={categorySpent}
              onOpenCategory={(id) => { setHistoryOrigin("overview"); setCategoryFilterId(id); setActiveTab("history"); }}
            />
          )}

          {activeTab === "reports" && (
            <ReportsView
              transactions={transactions}
              categories={categories}
              accounts={accountsWithBalance}
              onSelectTransaction={(tx) => setTransactionDetail(tx)}
              onBack={() => setActiveTab("settings")}
            />
          )}

          {activeTab === "inbox" && (
            <NotificationInboxView
              items={notificationItems}
              unreadCount={unreadNotificationCount}
              onBack={() => setActiveTab("overview")}
              onOpenNotice={markNotificationRead}
              onMarkAllRead={markAllNotificationsRead}
            />
          )}

          {activeTab === "horizon" && (
            <HorizonView
              goals={goals}
              trips={trips}
              loans={loans}
              schedules={schedules}
              routines={routines}
              attendance={routineAttendance}
              onOpenAddGoal={startCreatingGoal}
              onOpenAddTrip={startCreatingTrip}
              onOpenAddLoan={startCreatingLoan}
              onOpenAddSchedule={startCreatingSchedule}
              onOpenGoal={(goal) => setGoalDetail(goal)}
              onOpenTrip={(trip) => setTripDetail(trip)}
              onOpenLoan={(loan) => setLoanDetail(loan)}
              onOpenSchedule={(schedule) => setScheduleDetail(schedule)}
              onCreateRoutine={createRoutine}
              onToggleRoutineAttendance={toggleRoutineAttendance}
              onRemoveRoutine={removeRoutine}
            />
          )}

          {activeTab === "settings" && (
            <SettingsView
              categories={categories}
              reminderSettings={reminderSettings}
              onOpenWorkspace={(workspace) => setActiveTab(workspace)}
              onOpenReports={() => setActiveTab("reports")}
              onOpenAccounts={() => setActiveTab("accounts")}
              onOpenHistory={() => setActiveTab("settings-history")}
            />
          )}

          {activeTab === "settings-history" && (
            <RetainedDataView
              routines={routines}
              attendance={routineAttendance}
              goals={goals}
              trips={trips}
              loans={loans}
              onBack={() => setActiveTab("settings")}
              onOpenOverviewHistory={() => { setHistoryOrigin("settings-history"); setActiveTab("history"); }}
            />
          )}

          {(activeTab === "settings-expenses" || activeTab === "settings-income" || activeTab === "settings-currency" || activeTab === "settings-reminders") && (
            <SettingsWorkspaceView
              mode={activeTab.replace("settings-", "") as SettingsWorkspaceMode}
              categories={categories}
              subcategorySpent={subcategorySpent}
              reminderSettings={reminderSettings}
              reminderPushStatus={reminderPushStatus}
              reminderPushBusy={reminderPushBusy}
              signedIn={Boolean(user)}
              onBack={() => setActiveTab("settings")}
              onOpenAddIncomeCategory={() => { setCatTypeInput("income"); setDraft("category"); }}
              onOpenAddSub={(parentId) => { setParentTargetId(parentId); setDraft("subcategory"); }}
              onDeleteCategory={deleteCategory}
              onSaveReminderSettings={saveReminderSettings}
              onEnableDeviceReminder={() => { void enableDailyDeviceReminder(); }}
            />
          )}
        </div>
      </main>

      <nav className="mobile-bottom-nav">
        <button className={`mobile-nav-item ${activeTab === "overview" || activeTab === "history" || activeTab === "accounts" ? "active" : ""}`} onClick={() => setActiveTab("overview")}><Wallet size={18} /><span>Overview</span></button>
        <button className={`mobile-nav-item ${activeTab === "insights" || activeTab === "reports" ? "active" : ""}`} onClick={() => setActiveTab("insights")}><ArrowUpRight size={18} /><span>Insights</span></button>
        <button className="mobile-fab" onClick={startCreatingTransaction} aria-label="Add transaction"><Plus size={22} /></button>
        <button className={`mobile-nav-item ${activeTab === "horizon" ? "active" : ""}`} onClick={() => setActiveTab("horizon")}><Compass size={18} /><span>Plans & Progress</span></button>
        <button className={`mobile-nav-item ${isSettingsRoute ? "active" : ""}`} onClick={() => setActiveTab("settings")}><ShieldCheck size={18} /><span>Settings</span></button>
      </nav>

      {/* Transaction Detail Modal */}
      {transactionDetail && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label="Transaction detail" onMouseDown={() => setTransactionDetail(null)}>
          <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top">
              <div><div className="draft-kicker">Ledger entry</div><h2>{transactionDetail.merchantNote}</h2></div>
              <button className="close-button" onClick={() => setTransactionDetail(null)} aria-label="Close"><X size={17} /></button>
            </div>
            <div className="detail-summary paper-card" style={{ marginTop: 14, marginBottom: 18 }}>
              <div><span className="detail-label">Amount</span><strong className={transactionDetail.type === "income" ? "amount-income" : transactionDetail.type === "expense" ? "amount-expense" : "amount-transfer"}>{fmt.format(transactionDetail.amount)}</strong></div>
              <div><span className="detail-label">Type</span><strong>{transactionDetail.type.toUpperCase()}</strong></div>
              <div><span className="detail-label">Date</span><strong>{transactionDetail.date}</strong></div>
            </div>
            <div className="field-note" style={{ display: "grid", gap: 10 }}>
              <div className="field-note-row"><span>Account</span><b>{accounts.find(a => a.id === transactionDetail.accountId)?.name ?? transactionDetail.accountId}</b></div>
              {transactionDetail.destinationAccountId && <div className="field-note-row"><span>To account</span><b>{accounts.find(a => a.id === transactionDetail.destinationAccountId)?.name}</b></div>}
              {transactionDetail.categoryId && <div className="field-note-row"><span>Category</span><b>{categories.find(c => c.id === transactionDetail.categoryId)?.name ?? transactionDetail.categoryId}</b></div>}
              {transactionDetail.payee && <div className="field-note-row"><span>Payee</span><b>{transactionDetail.payee}</b></div>}
              {transactionDetail.payer && <div className="field-note-row"><span>Payer</span><b>{transactionDetail.payer}</b></div>}
              <div className="field-note-row"><span>Settlement</span><b>{transactionDetail.settlementStatus === "pending" ? "Pending" : "Paid"}</b></div>
              {transactionDetail.cashFlowKind && <div className="field-note-row"><span>Cash-flow source</span><b>{transactionDetail.cashFlowKind === "loan-disbursement" ? "Loan original amount" : "Loan repayment or collection"}</b></div>}
              {transactionDetail.tag?.goalId && <div className="field-note-row"><span>Tagged goal</span><b>{goals.find(g => g.id === transactionDetail.tag?.goalId)?.name}</b></div>}
              {transactionDetail.tag?.tripId && <div className="field-note-row"><span>Tagged trip</span><b>{trips.find(t => t.id === transactionDetail.tag?.tripId)?.name}</b></div>}
            </div>
            {transactionDetail.attachments && transactionDetail.attachments.length > 0 && <div className="transaction-evidence" style={{ marginTop: 18 }}><div className="detail-label" style={{ marginBottom: 7 }}>Receipts & proof</div><div className="evidence-list">{transactionDetail.attachments.map((attachment) => <span className="evidence-chip" key={attachment.id}><Paperclip size={13} /><button type="button" className="evidence-view-button" onClick={() => { void viewEvidence(attachment); }}>{attachment.name}</button></span>)}</div></div>}
            <div className="draft-actions" style={{ marginTop: 24 }}>
              <button className="primary-button draft-submit" onClick={() => startEditingTransaction(transactionDetail)}><Edit3 size={15} /> Modify entry</button>
              <button className="delete-button" onClick={() => { setTransactions(current => current.filter(t => t.id !== transactionDetail.id)); void deletePersistedRecord("expenses", transactionDetail.id); setTransactionDetail(null); }}><Trash2 size={15} /> Remove from ledger</button>
            </div>
          </aside>
        </div>
      )}

      {/* Savings Goal Detail */}
      {goalDetail && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={`${goalDetail.name} savings goal`} onMouseDown={() => { setGoalDetail(null); setGoalAdjustment(null); setGoalAdjustmentAmount(""); setGoalAdjustmentNote(""); }}>
          <aside className="draft-panel plan-detail-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">Savings goal</div><h2>{goalDetail.name}</h2></div><button className="close-button" onClick={() => { setGoalDetail(null); setGoalAdjustment(null); setGoalAdjustmentNote(""); }} aria-label="Close"><X size={17} /></button></div>
            {(() => {
              const metrics = goalMetrics(goalDetail);
              const fundingHistory = goalDetail.fundingHistory ?? [];
              return <>
                <div className="plan-detail-hero paper-card">
                  <div className="plan-detail-kicker">{goalDetail.deadline}</div>
                  <strong>{fmt.format(goalDetail.saved)} <span>of {fmt.format(metrics.personalTarget)} to save</span></strong>
                  <div className="budget-track horizon-progress"><div className="budget-fill" style={{ width: `${metrics.percent}%`, background: "#b78a3d" }} /></div>
                  <div className="horizon-card-foot"><span>{metrics.percent}% personally funded</span><span>{fmt.format(metrics.remaining)} to go</span></div>
                </div>
                <div className="goal-intelligence-grid">
                  <div><span>Deadline pace</span><strong>{metrics.daysLeft === null ? "Set a date" : metrics.daysLeft === 0 ? "Due now" : `${metrics.daysLeft} days left`}</strong></div>
                  <div><span>Daily requirement</span><strong>{metrics.dailyNeeded === null ? "—" : fmt.format(metrics.dailyNeeded)}</strong></div>
                  <div><span>Weekly requirement</span><strong>{metrics.weeklyNeeded === null ? "—" : fmt.format(metrics.weeklyNeeded)}</strong></div>
                  {metrics.financed > 0 && <div><span>Financing contribution</span><strong>{fmt.format(metrics.financed)}</strong></div>}
                </div>
                {goalAdjustment ? (
                  <div className="adjustment-panel">
                    <div className="draft-kicker">{goalAdjustment === "deposit" ? "Add to this goal" : "Move money back"}</div>
                    <label className="form-field"><span>Amount</span><input autoFocus value={goalAdjustmentAmount} onChange={(event) => setGoalAdjustmentAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="0.00" inputMode="decimal" /></label>
                    <label className="form-field"><span>Note <em>(optional)</em></span><input value={goalAdjustmentNote} onChange={(event) => setGoalAdjustmentNote(event.target.value)} placeholder={goalAdjustment === "deposit" ? "e.g. August surplus" : "e.g. Unexpected home repair"} /></label>
                    <div className="draft-actions"><button className="primary-button draft-submit" onClick={submitGoalAdjustment}>{goalAdjustment === "deposit" ? "Record deposit" : "Record withdrawal"}</button><button className="secondary-button" onClick={() => { setGoalAdjustment(null); setGoalAdjustmentAmount(""); setGoalAdjustmentNote(""); }}>Cancel</button></div>
                  </div>
                ) : (
                  <div className="draft-actions plan-detail-actions"><button className="primary-button draft-submit" onClick={() => setGoalAdjustment("deposit")}><ArrowDownRight size={15} /> Deposit</button><button className="secondary-button" onClick={() => setGoalAdjustment("withdraw")}><ArrowUpRight size={15} /> Withdraw</button><button className="text-link" onClick={() => startEditingGoal(goalDetail)}><Edit3 size={14} /> Modify goal</button><button className="text-link" onClick={() => setPlanningCompletion("goal", goalDetail, planningIsActive(goalDetail))}><CheckCircle2 size={14} /> {planningIsActive(goalDetail) ? "Complete goal" : "Reactivate goal"}</button></div>
                )}
                <div className="field-note plan-detail-note"><div className="field-note-row"><span>Whole target</span><b>{fmt.format(goalDetail.target)}</b></div><div className="field-note-row"><span>Personal savings target</span><b>{fmt.format(metrics.personalTarget)}</b></div><div className="field-note-row"><span>Deadline</span><b>{goalDetail.deadline}</b></div><div className="field-note-row"><span>Status</span><b>{metrics.remaining === 0 ? "Complete" : "In progress"}</b></div></div>
                <section className="goal-funding-history"><div className="section-mini-head"><span>Funding history</span><b>{fundingHistory.length} records</b></div>{fundingHistory.length ? <div className="loan-history">{fundingHistory.map((entry) => <div className="loan-history-row" key={entry.id}><div><strong>{entry.type === "deposit" ? "Deposit" : "Withdrawal"}</strong><p>{entry.note}</p><span>{shortDate(entry.date)} · {entry.type === "deposit" ? "Added to goal" : "Returned to funds"}</span></div><b className={entry.type === "deposit" ? "funding-positive" : "funding-negative"}>{entry.type === "deposit" ? "+" : "−"}{fmt.format(entry.amount)}</b></div>)}</div> : <p className="empty-hint">No funding movements recorded yet.</p>}</section>
              </>;
            })()}
          </aside>
        </div>
      )}

      {/* Trip Plan Detail */}
      {tripDetail && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={`${tripDetail.name} trip plan`} onMouseDown={() => setTripDetail(null)}>
          <aside className="draft-panel plan-detail-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">Trip & event plan</div><h2>{tripDetail.name}</h2></div><button className="close-button" onClick={() => setTripDetail(null)} aria-label="Close"><X size={17} /></button></div>
            <div className="plan-detail-hero paper-card">
              <div className="plan-detail-kicker">{tripDetail.dates}</div>
              <strong>{fmt.format(transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === tripDetail.id).reduce((sum, transaction) => sum + transaction.amount, 0))} <span>spent of {fmt.format(tripDetail.budget)}</span></strong>
              <div className="budget-track horizon-progress"><div className="budget-fill" style={{ width: `${Math.min(100, (transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === tripDetail.id).reduce((sum, transaction) => sum + transaction.amount, 0) / tripDetail.budget) * 100)}%`, background: "#8c6d36" }} /></div>
              <div className="horizon-card-foot"><span>{transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === tripDetail.id).length} linked expenses</span><span>{fmt.format(Math.max(0, tripDetail.budget - transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === tripDetail.id).reduce((sum, transaction) => sum + transaction.amount, 0)))} remaining</span></div>
            </div>
            <div className="field-note plan-detail-note"><div className="field-note-row"><span>Working budget</span><b>{fmt.format(tripDetail.budget)}</b></div><div className="field-note-row"><span>Dates</span><b>{tripDetail.dates}</b></div><div className="field-note-row"><span>Linked spend</span><b>{transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === tripDetail.id).length} records</b></div></div>
            <div className="draft-actions plan-detail-actions"><button className="primary-button draft-submit" onClick={() => startEditingTrip(tripDetail)}><Edit3 size={15} /> Modify plan</button><button className="secondary-button" onClick={() => { startCreatingTransaction(); setTransactionDraft((current) => ({ ...current, tripId: tripDetail.id })); setTripDetail(null); }}>Add linked expense</button><button className="text-link" onClick={() => setPlanningCompletion("trip", tripDetail, planningIsActive(tripDetail))}><CheckCircle2 size={14} /> {planningIsActive(tripDetail) ? "Complete plan" : "Reactivate plan"}</button></div>
          </aside>
        </div>
      )}

      {/* Debt & Loan Detail */}
      {loanDetail && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={`${loanDetail.title} debt and loan record`} onMouseDown={() => { setLoanDetail(null); resetLoanPaymentDraft(); }}>
          <aside className="draft-panel plan-detail-panel loan-detail-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">{loanDetail.direction === "borrowed" ? "Debt you owe" : "Money owed to you"}</div><h2>{loanDetail.title}</h2></div><button className="close-button" onClick={() => { setLoanDetail(null); resetLoanPaymentDraft(); }} aria-label="Close"><X size={17} /></button></div>
            <div className="plan-detail-hero paper-card loan-detail-hero">
              <div className="plan-detail-kicker">{loanDetail.counterparty} · due {shortDate(loanDetail.dueDate)}</div>
              <strong>{fmt.format(Math.max(0, loanDetail.totalAmount - loanDetail.paidAmount))} <span>remaining of {fmt.format(loanDetail.totalAmount)}</span></strong>
              <div className="budget-track horizon-progress"><div className="budget-fill" style={{ width: `${loanDetail.totalAmount ? Math.min(100, Math.round((loanDetail.paidAmount / loanDetail.totalAmount) * 100)) : 0}%`, background: loanDetail.direction === "borrowed" ? "#a65a3b" : "#2e654f" }} /></div>
              <div className="horizon-card-foot"><span>{loanDetail.totalAmount ? Math.min(100, Math.round((loanDetail.paidAmount / loanDetail.totalAmount) * 100)) : 0}% settled</span><span>{loanDetail.terms}</span></div>
            </div>
            <div className="field-note plan-detail-note"><div className="field-note-row"><span>{loanDetail.direction === "borrowed" ? "Lender" : "Borrower"}</span><b>{loanDetail.counterparty}</b></div><div className="field-note-row"><span>Cash account</span><b>{accounts.find((account) => account.id === loanDetail.cashAccountId)?.name ?? "No cash account linked"}</b></div><div className="field-note-row"><span>Due date</span><b>{shortDate(loanDetail.dueDate)}</b></div><div className="field-note-row"><span>Settled so far</span><b>{fmt.format(loanDetail.paidAmount)}</b></div></div>
            {loanDetail.paidAmount < loanDetail.totalAmount ? <div className="adjustment-panel loan-payment-panel"><div className="draft-kicker">{loanDetail.direction === "borrowed" ? "Record a repayment" : "Record money received"}</div><div className="loan-payment-grid"><label className="form-field"><span>Payment amount</span><input value={loanPaymentAmount} onChange={(event) => setLoanPaymentAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="0.00" inputMode="decimal" /></label><label className="form-field"><span>How was it paid?</span><select value={loanPaymentMethod} onChange={(event) => setLoanPaymentMethod(event.target.value)}><option>Cash in hand</option><option>Card</option><option>Bank transfer</option><option>bKash</option><option>Nagad</option><option>Custom</option></select></label>{loanPaymentMethod === "Custom" && <label className="form-field loan-payment-full"><span>Custom payment method</span><input value={loanCustomPaymentMethod} onChange={(event) => setLoanCustomPaymentMethod(event.target.value)} placeholder="e.g., Rocket" /></label>}<label className="form-field loan-payment-full"><span>Note <em>(optional)</em></span><textarea value={loanPaymentNote} onChange={(event) => setLoanPaymentNote(event.target.value)} placeholder="What was this payment for?" rows={2} /></label><label className="form-field loan-payment-full"><span>Reference <em>(optional)</em></span><input value={loanPaymentReference} onChange={(event) => setLoanPaymentReference(event.target.value)} placeholder="Transaction ID, last four digits, or receipt" /></label></div><button className="primary-button draft-submit" onClick={submitLoanPayment}>Record payment</button></div> : <div className="loan-settled-note"><CheckCircle2 size={17} /> This record is fully settled.</div>}
            <div className="loan-history"><div className="section-mini-head"><span>Payment history</span><b>{loanDetail.paymentHistory.length} records</b></div>{loanDetail.paymentHistory.length ? loanDetail.paymentHistory.map((payment) => <div className="loan-history-row" key={payment.id}><div><strong>{payment.note}</strong><div className="loan-payment-meta"><span>{shortDate(payment.date)} · {payment.method}</span>{payment.reference && <span>Ref · {payment.reference}</span>}{payment.transactionId && <span>Cash flow recorded</span>}</div></div><b>{fmt.format(payment.amount)}</b></div>) : <div className="empty-hint">No payment has been recorded yet.</div>}</div>
            <div className="draft-actions plan-detail-actions"><button className="text-link" onClick={() => startEditingLoan(loanDetail)}><Edit3 size={14} /> Modify record</button><button className="text-link" onClick={() => setPlanningCompletion("loan", loanDetail, planningIsActive(loanDetail))}><CheckCircle2 size={14} /> {planningIsActive(loanDetail) ? "Complete loan" : "Reactivate loan"}</button></div>
          </aside>
        </div>
      )}

      {/* Recurring income and bill detail */}
      {scheduleDetail && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={`${scheduleDetail.name} recurring schedule`} onMouseDown={() => setScheduleDetail(null)}>
          <aside className="draft-panel plan-detail-panel schedule-detail-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">{scheduleDetail.type === "income" ? "Recurring income" : "Recurring bill"}</div><h2>{scheduleDetail.name}</h2></div><button className="close-button" onClick={() => setScheduleDetail(null)} aria-label="Close"><X size={17} /></button></div>
            <div className={`plan-detail-hero paper-card schedule-detail-hero ${scheduleDetail.type}`}>
              <div className="plan-detail-kicker">{scheduleDetail.status === "active" ? scheduleDueLabel(scheduleDetail.nextDueDate) : "Schedule paused"}</div>
              <strong>{fmt.format(scheduleDetail.amount)} <span>{scheduleFrequencyLabel(scheduleDetail.frequency).toLowerCase()}</span></strong>
              <div className="horizon-card-foot"><span>Next due {shortDate(scheduleDetail.nextDueDate)}</span><span>{scheduleDetail.status === "active" ? "Active" : "Paused"}</span></div>
            </div>
            <div className="field-note plan-detail-note"><div className="field-note-row"><span>Account</span><b>{accounts.find((account) => account.id === scheduleDetail.accountId)?.name ?? scheduleDetail.accountId}</b></div><div className="field-note-row"><span>Category</span><b>{categories.find((category) => category.id === scheduleDetail.categoryId)?.name ?? scheduleDetail.categoryId}</b></div><div className="field-note-row"><span>Frequency</span><b>{scheduleFrequencyLabel(scheduleDetail.frequency)}</b></div><div className="field-note-row"><span>Status</span><b>{scheduleDetail.status === "active" ? "Active and due" : "Paused"}</b></div></div>
            <div className="draft-actions plan-detail-actions schedule-detail-actions">
              {scheduleDetail.status === "active" ? <><button className="primary-button draft-submit" onClick={recordScheduledTransaction}><CheckCircle2 size={15} /> Mark {scheduleDetail.type === "income" ? "received" : "paid"}</button><button className="secondary-button" onClick={() => setScheduleStatus(scheduleDetail, "paused")}>Pause schedule</button></> : <button className="primary-button draft-submit" onClick={() => setScheduleStatus(scheduleDetail, "active")}><CheckCircle2 size={15} /> Resume schedule</button>}
              <button className="text-link" onClick={() => startEditingSchedule(scheduleDetail)}><Edit3 size={14} /> Modify schedule</button>
            </div>
            <section className="schedule-history"><div className="section-mini-head"><span>Recorded occurrences</span><b>{scheduleDetail.history.length} records</b></div>{scheduleDetail.history.length ? <div className="loan-history">{scheduleDetail.history.map((occurrence) => <div className="loan-history-row" key={occurrence.id}><div><strong>{scheduleDetail.type === "income" ? "Income received" : "Bill paid"}</strong><span>Due {shortDate(occurrence.scheduledFor)} · recorded {shortDate(occurrence.recordedAt)}</span></div><b>{fmt.format(scheduleDetail.amount)}</b></div>)}</div> : <p className="empty-hint">No occurrences have been recorded yet.</p>}</section>
          </aside>
        </div>
      )}

      {/* Expanded Profile Modal */}
      {draft === "profile" && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label="User profile" onMouseDown={resetDraft}>
          <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">{user ? "Your personal account" : "Your personal expense tracker"}</div><h2>{user ? "Profile & saved records" : "Keep your money record close."}</h2></div><button className="close-button" onClick={resetDraft} aria-label="Close"><X size={17} /></button></div>
            {authLoading ? <div className="empty-hint" style={{ margin: "26px 0" }}>Checking your session…</div> : user ? <>
              <div style={{ display: "flex", alignItems: "center", gap: 16, margin: "20px 0", padding: "18px", background: "#f8f4ec", borderRadius: 14, border: "1px solid #ded8ca" }}>
                <div className="profile-dot" style={{ width: 52, height: 52, fontSize: 18, background: "#1b3a2b", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "50%", fontWeight: 600 }}>{(user.email?.slice(0, 2) || "IL").toUpperCase()}</div>
                <div><strong style={{ fontSize: 17, display: "block", fontFamily: "Space Grotesk, sans-serif" }}>{user.email?.split("@")[0] || "Ledger owner"}</strong><span style={{ color: "#777", fontSize: 13 }}>{user.email}</span></div>
              </div>
              <div className="field-note" style={{ display: "grid", gap: 10, marginBottom: 20 }}>
                <div className="field-note-row"><span>Saving status</span><b>{cloudStatus === "synced" ? "Saved to your account" : cloudStatus === "loading" ? "Loading your records" : cloudStatus === "error" ? "Needs attention" : "Not signed in"}</b></div>
                <div className="field-note-row"><span>Account access</span><b>Email &amp; password</b></div>
                <div className="field-note-row"><span>Email verification</span><b>{user.emailVerified ? "Verified" : "Not verified"}</b></div>
                <div className="field-note-row"><span>Ledger identity</span><b>{user.uid.slice(0, 10)}…</b></div>
              </div>
              {!user.emailVerified && <div className="profile-action-callout"><div><b>Confirm this email</b><p>No email is sent automatically. When you are ready, choose Send verification email to request one link for {user.email}.</p></div><div className="profile-action-buttons"><button className="secondary-button" disabled={authSubmitting} onClick={() => void handleProfileAction("verification")}>{authSubmitting ? "Sending…" : "Send verification email"}</button><button className="text-link" disabled={authSubmitting} onClick={() => void handleProfileAction("refreshVerification")}>Refresh status</button></div></div>}
              <div className="profile-action-callout profile-recovery-callout"><div><b>Password recovery</b><p>No reset email is sent unless you select the action. A secure link will be sent to {user.email ?? "your account email"} only after you choose Send reset link.</p></div><button className="text-link" disabled={authSubmitting} onClick={() => void handleProfileAction("passwordReset")}>{authSubmitting ? "Sending…" : "Send reset link"}</button></div>
              {cloudError && <p className="empty-hint" role="alert" style={{ color: "#8b2626", marginBottom: 18 }}>{cloudError}</p>}
              {profileNotice && <p className="account-notice" role="status">{profileNotice}</p>}
              <div className="draft-actions"><button className="secondary-button" onClick={resetDraft}><ShieldCheck size={16} /> Continue to ledger</button><button className="delete-button" onClick={() => { void signOut(); resetDraft(); }}><LogOut size={16} /> Sign out</button></div>
            </> : <>
              <p className="draft-copy">Create a personal account to save your expenses, income, accounts, goals, plans, loans, and schedules. When you return, sign in to continue with the same money record.</p>
              <div className="filter-row" style={{ margin: "18px 0" }}><button className={`filter-button ${profileMode === "signIn" ? "active" : ""}`} onClick={() => { setProfileMode("signIn"); setProfileNotice(null); clearError(); }}>Sign in</button><button className={`filter-button ${profileMode === "signUp" ? "active" : ""}`} onClick={() => { setProfileMode("signUp"); setProfileNotice(null); clearError(); }}>Create account</button></div>
              <div className="draft-fields"><label className="form-field"><span>Email address</span><input type="email" value={authEmailInput} onChange={(event) => setAuthEmailInput(event.target.value)} placeholder="you@example.com" autoComplete="email" /></label><label className="form-field"><span>Password</span><input type="password" value={authPasswordInput} onChange={(event) => setAuthPasswordInput(event.target.value)} placeholder="At least 6 characters" minLength={6} autoComplete={profileMode === "signUp" ? "new-password" : "current-password"} /></label></div>
              {profileMode === "signIn" && <button className="text-link profile-forgot-link" disabled={authSubmitting} onClick={() => void handleProfileAction("passwordReset")}>Forgot your password?</button>}
              {(authError || cloudError) && <p className="empty-hint" role="alert" style={{ color: "#8b2626", marginTop: 16 }}>{authError || cloudError}</p>}
              {profileNotice && <p className="account-notice" role="status">{profileNotice}</p>}
              <div className="draft-actions" style={{ marginTop: 22 }}><button className="primary-button draft-submit" disabled={authSubmitting} onClick={() => void submitAuthentication()}>{authSubmitting ? "Working…" : profileMode === "signUp" ? "Create my account" : "Sign in"}</button><button className="secondary-button" onClick={resetDraft}>Explore without an account</button></div>
            </>}
          </aside>
        </div>
      )}

      {/* Standard Draft / Create Panel */}
      {draft && draft !== "profile" && (
        <DraftPanel
          key={`${draft}-${transactionDraft.id ?? "new"}`}
          kind={draft}
          title={draftTitle}
          amount={draftAmount}
          dateVal={draftDate}
          transaction={transactionDraft}
          accounts={accounts}
          categories={categories}
          goals={goals}
          trips={trips}
          editingGoalId={editingGoalId}
          editingTripId={editingTripId}
          editingLoanId={editingLoanId}
          editingScheduleId={editingScheduleId}
          catName={catNameInput}
          catBudget={catBudgetInput}
          catType={catTypeInput}
          catIcon={catIconInput}
          parentTarget={parentTargetId}
          subName={subNameInput}
          subIcon={subIconInput}
          accName={accNameInput}
          accKind={accKindInput}
          accBalance={accBalanceInput}
          accNumber={accNumberInput}
          loanDirection={loanDirectionInput}
          loanCounterparty={loanCounterpartyInput}
          loanTerms={loanTermsInput}
          loanAccount={loanAccountInput}
          goalFinancing={goalFinancingInput}
          scheduleType={scheduleTypeInput}
          scheduleFrequency={scheduleFrequencyInput}
          scheduleAccount={scheduleAccountInput}
          scheduleCategory={scheduleCategoryInput}
          onTitle={setDraftTitle}
          onAmount={setDraftAmount}
          onDate={setDraftDate}
          onTransaction={setTransactionDraft}
          onUploadEvidence={uploadEvidence}
          onViewEvidence={viewEvidence}
          onCatName={setCatNameInput}
          onCatBudget={setCatBudgetInput}
          onCatType={setCatTypeInput}
          onCatIcon={setCatIconInput}
          onParentTarget={setParentTargetId}
          onSubName={setSubNameInput}
          onSubIcon={setSubIconInput}
          onAccName={setAccNameInput}
          onAccKind={setAccKindInput}
          onAccBalance={setAccBalanceInput}
          onAccNumber={setAccNumberInput}
          onLoanDirection={setLoanDirectionInput}
          onLoanCounterparty={setLoanCounterpartyInput}
          onLoanTerms={setLoanTermsInput}
          onLoanAccount={setLoanAccountInput}
          onGoalFinancing={setGoalFinancingInput}
          onScheduleType={setScheduleTypeInput}
          onScheduleFrequency={setScheduleFrequencyInput}
          onScheduleAccount={setScheduleAccountInput}
          onScheduleCategory={setScheduleCategoryInput}
          onClose={resetDraft}
          onSave={saveDraft}
          onOpenAddSub={(parentId) => { setParentTargetId(parentId); setDraft("subcategory"); }}
          onOpenAddIncomeCategory={() => { setCatTypeInput("income"); setDraft("category"); }}
        />
      )}
    </div>
  );
}

function OverviewView({ balance, netWorth, accounts, totals, categories, transactions, schedules, filter, categoryFilterId, query, onFilter, onQuery, onClearCategory, onSelectTransaction, onOpenSchedule, onOpenHistory, onOpenPendingHistory }: {
  balance: number; netWorth: number; accounts: Array<Account & { balance: number }>; totals: { income: number; expense: number; ordinaryIncome: number; ordinaryExpense: number; loanInflow: number; loanOutflow: number }; categories: Category[]; transactions: Transaction[]; schedules: RecurringSchedule[]; filter: "all" | TransactionType; categoryFilterId: string | null; query: string;
  onFilter: (value: "all" | TransactionType) => void; onQuery: (value: string) => void; onClearCategory: () => void; onSelectTransaction: (transaction: Transaction) => void; onOpenSchedule: (schedule: RecurringSchedule) => void; onOpenHistory: () => void; onOpenPendingHistory: () => void;
}) {
  const savingsRate = totals.ordinaryIncome ? Math.round(((totals.ordinaryIncome - totals.ordinaryExpense) / totals.ordinaryIncome) * 100) : 0;
  const selectedCategory = categories.find((category) => category.id === categoryFilterId);
  const upcomingSchedules = schedules.filter((schedule) => schedule.status === "active").slice().sort((a, b) => a.nextDueDate.localeCompare(b.nextDueDate));
  const upcomingIncome = upcomingSchedules.filter((schedule) => schedule.type === "income").slice(0, 3);
  const upcomingBills = upcomingSchedules.filter((schedule) => schedule.type === "expense").slice(0, 3);
  const pendingTransactions = transactions.filter((transaction) => transaction.settlementStatus === "pending").slice(0, 4);
  const assetCount = accounts.filter((account) => account.kind === "asset").length;
  const liabilityCount = accounts.length - assetCount;

  return <>
    <header className="page-header"><div><div className="page-kicker">Today’s field note</div><h1>Money, in order.</h1><p className="page-subtitle">The few signals that matter before the day moves on.</p></div></header>
    <div className="dashboard-grid">
      <div>
        <section className="balance-card">
          <img className="balance-art" src="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&q=80&w=1200" alt="Editorial ledger still life" />
          <div className="balance-content">
            <div className="balance-label"><span /> Available balance</div>
            <div className="balance-number">{fmt.format(balance)}</div>
            <p className="balance-caption">Across your asset accounts, with liabilities held apart for a truthful net worth.</p>
            <div className="balance-foot"><div><span>Cash in, August</span><strong>{fmt.format(totals.income)}</strong></div><div><span>Cash out, August</span><strong>{fmt.format(totals.expense)}</strong></div></div>
          </div>
        </section>
        <div className="summary-strip">
          <article className="mini-stat"><div className="stat-top">Inflow <span className="stat-icon up"><ArrowDownRight size={14} /></span></div><strong>{fmt.format(totals.income)}</strong><p>{totals.loanInflow ? `${fmt.format(totals.loanInflow)} from loan cash` : "Income and received funds"}</p></article>
          <article className="mini-stat"><div className="stat-top">Outflow <span className="stat-icon down"><ArrowUpRight size={14} /></span></div><strong>{fmt.format(totals.expense)}</strong><p>{totals.loanOutflow ? `${fmt.format(totals.loanOutflow)} to loans` : "Recorded expenses and payments"}</p></article>
          <article className="mini-stat"><div className="stat-top">Savings rate <span className="stat-icon gold"><CheckCircle2 size={14} /></span></div><strong>{savingsRate}%</strong><p>Based on regular income and spending</p></article>
        </div>
      </div>
      <aside className="paper-card side-summary overview-net-worth">
        <div className="card-head"><h2>Net worth</h2></div>
        <div className="net-worth"><div className="net-worth-value">{fmt.format(netWorth)}</div><span className="change-tag"><ArrowUpRight size={11} /> accounts plus loan position</span></div>
        <div className="overview-account-glance"><span>{assetCount} asset folio{assetCount === 1 ? "" : "s"}</span><span>{liabilityCount ? `${liabilityCount} liability` : "No liabilities"}</span></div>
      </aside>
    </div>
    <section className="paper-card dashboard-schedule-register">
      <div className="section-head schedule-register-head"><div><div className="page-kicker">Expected money</div><h2>Upcoming income & bills</h2></div><span className="month-hand-date">From your recurring ledger</span></div>
      <div className="schedule-register-grid">
        <div className="schedule-register-column income"><div className="schedule-register-label"><span>Upcoming income</span><b><i />{upcomingIncome.length} active</b></div>{upcomingIncome.length ? upcomingIncome.map((schedule) => <button key={schedule.id} className="schedule-register-row" onClick={() => onOpenSchedule(schedule)}><span><strong>{schedule.name}</strong><small><em>{scheduleDueLabel(schedule.nextDueDate)}</em><span>{scheduleFrequencyLabel(schedule.frequency)}</span></small></span><b>{fmt.format(schedule.amount)}</b></button>) : <p className="empty-hint">No upcoming income schedule.</p>}</div>
        <div className="schedule-register-column expense"><div className="schedule-register-label"><span>Upcoming bills</span><b><i />{upcomingBills.length} active</b></div>{upcomingBills.length ? upcomingBills.map((schedule) => <button key={schedule.id} className="schedule-register-row" onClick={() => onOpenSchedule(schedule)}><span><strong>{schedule.name}</strong><small><em>{scheduleDueLabel(schedule.nextDueDate)}</em><span>{scheduleFrequencyLabel(schedule.frequency)}</span></small></span><b>{fmt.format(schedule.amount)}</b></button>) : <p className="empty-hint">No upcoming bill schedule.</p>}</div>
      </div>
    </section>
    {pendingTransactions.length > 0 && <section className="paper-card pending-register"><div className="section-head pending-register-head"><div><div className="page-kicker">Needs confirmation</div><h2>Pending payments</h2></div><div className="pending-register-action"><span className="pending-count">{pendingTransactions.length} open</span><button className="pending-review-link" onClick={onOpenPendingHistory}>Review in history <ChevronRight size={14} /></button></div></div><p className="budget-note">Keep these in view until money has actually moved. The full ledger has its own pending-only filter so no open item disappears in a long register.</p><div className="pending-transaction-list">{pendingTransactions.map((transaction) => <button className="pending-transaction-row" key={transaction.id} onClick={() => onSelectTransaction(transaction)}><span><em>Pending</em><strong>{transaction.merchantNote}</strong><small>{transaction.date}</small></span><b className={transaction.type === "income" ? "amount-income" : transaction.type === "expense" ? "amount-expense" : "amount-transfer"}>{transaction.type === "income" ? "+" : transaction.type === "expense" ? "−" : "↔"}{fmt.format(transaction.amount)}</b></button>)}</div></section>}
    <div className="lower-grid">
      <section className="paper-card section-card">
        <div className="section-head overview-ledger-head"><div><div className="page-kicker">Last recorded</div><h2>{selectedCategory ? `${selectedCategory.name} ledger` : "Recent ledger"}</h2></div><button className="overview-history-link" onClick={onOpenHistory}>Full history <ChevronRight size={14} /></button></div>
        <div className="filter-row overview-filter-row">{(["all", "expense", "income", "transfer"] as const).map((item) => <button key={item} className={`filter-button ${filter === item ? "active" : ""}`} onClick={() => onFilter(item)}>{item[0].toUpperCase() + item.slice(1)}</button>)}</div>
        {selectedCategory && <button className="filter-note" onClick={onClearCategory}>Viewing {selectedCategory.name} <X size={12} /></button>}
        <div className="search-box"><Search size={15} /><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Search a merchant or category" /></div>
        <div className="transaction-list">{transactions.length ? transactions.slice(0, 3).map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onSelect={onSelectTransaction} />) : <p className="budget-note">No entries match this view. Try another filter or clear the category context.</p>}</div>
      </section>
    </div>
  </>;
}

function AccountsAssetsView({ accounts, netWorth, onOpenAddAccount, onBack }: { accounts: Array<Account & { balance: number }>; netWorth: number; onOpenAddAccount: () => void; onBack: () => void }) {
  const assets = accounts.filter((account) => account.kind === "asset");
  const liabilities = accounts.filter((account) => account.kind === "liability");
  const assetTotal = assets.reduce((sum, account) => sum + account.balance, 0);
  const liabilityTotal = liabilities.reduce((sum, account) => sum + account.balance, 0);
  const renderFolio = (account: Account & { balance: number }) => <article className={`paper-card account-folio-card ${account.kind === "liability" ? "liability" : ""}`} key={account.id}><div className="folio-card-rule" /><div className="folio-card-head"><span className="account-dot" style={{ background: account.color }} /><span>{account.kind === "asset" ? "Asset folio" : "Liability folio"}</span></div><h3>{account.name}</h3><p>Folio {account.accountNumber}</p><strong>{account.kind === "liability" ? `${fmt.format(account.balance)} owed` : fmt.format(account.balance)}</strong></article>;
  return <>
    <header className="page-header page-header-with-action"><div><div className="back-line"><button className="back-control" onClick={onBack}><ArrowLeft size={14} /> Back to Settings</button></div><div className="page-kicker">Account register</div><h1>Accounts & assets.</h1><p className="page-subtitle">Keep every asset and obligation in its own folio.</p></div><button className="add-button" onClick={onOpenAddAccount}><Plus size={15} /> Add account</button></header>
    <section className="account-register-hero"><div><span>Net worth</span><strong>{fmt.format(netWorth)}</strong><p>Assets held apart from credit and other obligations.</p></div><dl><div><dt>Assets held</dt><dd>{fmt.format(assetTotal)}</dd></div><div><dt>Liabilities</dt><dd>{fmt.format(liabilityTotal)}</dd></div><div><dt>Active folios</dt><dd>{accounts.length}</dd></div></dl></section>
    <section className="account-register-section"><div className="section-head"><div><div className="page-kicker">Held capital</div><h2>Asset folios</h2></div><span className="month-hand-date">{assets.length} account{assets.length === 1 ? "" : "s"}</span></div><div className="account-folio-grid">{assets.map(renderFolio)}</div></section>
    <section className="account-register-section liability-register"><div className="section-head"><div><div className="page-kicker">Obligations</div><h2>Liability folios</h2></div><span className="month-hand-date">{liabilities.length} account{liabilities.length === 1 ? "" : "s"}</span></div><div className="account-folio-grid">{liabilities.length ? liabilities.map(renderFolio) : <div className="horizon-empty"><strong>No liabilities recorded.</strong>Register a credit card or other amount owed to keep net worth accurate.</div>}</div></section>
  </>;
}

function HistoryView({ totals, categories, categorySpent, transactions, visibleTransactions, filter, categoryFilterId, query, onFilter, onQuery, onClearCategory, onOpenCategory, onSelectTransaction, pendingOnly, onPendingOnlyChange, archivedGoals, archivedTrips, archivedLoans, onOpenGoal, onOpenTrip, onOpenLoan, backLabel, onBack }: { totals: { income: number; expense: number; ordinaryIncome: number; ordinaryExpense: number; loanInflow: number; loanOutflow: number }; categories: Category[]; categorySpent: Record<string, number>; transactions: Transaction[]; visibleTransactions: Transaction[]; filter: "all" | TransactionType; categoryFilterId: string | null; query: string; onFilter: (value: "all" | TransactionType) => void; onQuery: (value: string) => void; onClearCategory: () => void; onOpenCategory: (id: string) => void; onSelectTransaction: (transaction: Transaction) => void; pendingOnly: boolean; onPendingOnlyChange: (value: boolean) => void; archivedGoals: Goal[]; archivedTrips: Trip[]; archivedLoans: Loan[]; onOpenGoal: (goal: Goal) => void; onOpenTrip: (trip: Trip) => void; onOpenLoan: (loan: Loan) => void; backLabel: string; onBack: () => void }) {
  const expenseTopCategories = categories.filter((category) => category.type === "expense" && !category.parentId);
  const plannedBudget = expenseTopCategories.reduce((sum, category) => sum + category.monthlyBudget, 0);
  const selectedCategory = categories.find((category) => category.id === categoryFilterId);
  const currentMonthKey = monthKey(new Date().toISOString().slice(0, 10));
  const [openMonths, setOpenMonths] = useState<Record<string, boolean>>(() => ({ [currentMonthKey]: true }));
  const monthRows = useMemo(() => {
    const monthKeys = new Set([currentMonthKey, ...transactions.map((transaction) => monthKey(transaction.date))]);
    return Array.from(monthKeys).sort((a, b) => b.localeCompare(a)).map((key) => {
      const entries = transactions.filter((transaction) => monthKey(transaction.date) === key);
      const income = entries.filter((transaction) => transaction.type === "income").reduce((sum, transaction) => sum + transaction.amount, 0);
      const expense = entries.filter((transaction) => transaction.type === "expense").reduce((sum, transaction) => sum + transaction.amount, 0);
      const [year, month] = key.split("-").map(Number);
      const daysInMonth = new Date(year, month, 0).getDate();
      const isCurrent = key === currentMonthKey;
      const elapsedDays = isCurrent ? new Date().getDate() : daysInMonth;
      return { key, label: monthLabel(key), entries, income, expense, net: income - expense, averageDailyExpense: expense / Math.max(1, elapsedDays), isCurrent };
    });
  }, [currentMonthKey, transactions]);
  const registerTransactions = pendingOnly ? visibleTransactions.filter((transaction) => transaction.settlementStatus === "pending") : visibleTransactions;
  const pendingCount = transactions.filter((transaction) => transaction.settlementStatus === "pending").length;
  return <>
    <header className="page-header"><div><div className="back-line"><button className="back-control" onClick={onBack}><ArrowLeft size={14} /> {backLabel}</button></div><div className="page-kicker">Recorded movement</div><h1>History, held to account.</h1><p className="page-subtitle">Follow every month, category, and entry without crowding the daily overview.</p></div></header>
    <section className="paper-card month-hand-section history-budget-section"><div className="section-head month-hand-head"><div><div className="page-kicker">Monthly allocation</div><h2>Month in hand</h2></div><span className="month-hand-date">{monthLabel(currentMonthKey)}</span></div><div className="month-hand-grid"><div className="month-hand-summary"><div className="field-note"><div className="field-note-row"><span>Allocated capital</span><b>{fmt.format(plannedBudget)}</b></div><div className="field-note-row"><span>Expense entries</span><b>{transactions.filter((transaction) => transaction.type === "expense" && !transaction.cashFlowKind).length} records</b></div></div><p className="budget-note">Budget pacing uses regular spending only. Loan movements remain visible in the cash ledger, not in category budgets.</p></div><div className="month-hand-progress"><div className="budget-meter"><div className="budget-label"><span>Planned spending</span><span>{fmt.format(totals.ordinaryExpense)} / {fmt.format(plannedBudget)}</span></div><div className="budget-track"><div className="budget-fill" style={{ width: `${Math.min(100, plannedBudget ? (totals.ordinaryExpense / plannedBudget) * 100 : 0)}%` }} /></div></div><div className="month-hand-progress-note"><strong>{plannedBudget ? Math.round((totals.ordinaryExpense / plannedBudget) * 100) : 0}% committed</strong><span>Loan cash flow is tracked separately.</span></div></div></div><div className="upcoming-list month-category-pulse"><div className="upcoming-title">Category pulse · tap a category to filter its register</div>{expenseTopCategories.slice(0, 4).map((category) => <button className="upcoming-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><span className="category-picker-label"><CategoryIcon icon={category.icon} size={15} />{category.name}</span><b>{fmt.format(categorySpent[category.id] ?? 0)}</b><strong>of {fmt.format(category.monthlyBudget)}</strong></button>)}</div></section>
    <section className="paper-card month-history-section"><div className="section-head month-history-head"><div><div className="page-kicker">Historical overview</div><h2>Ledger by month</h2></div><span className="month-hand-date">{monthRows.length} month{monthRows.length === 1 ? "" : "s"} with records</span></div><div className="month-history-list">{monthRows.map((month) => { const isOpen = Boolean(openMonths[month.key]); return <div className={`month-history-item ${isOpen ? "open" : ""}`} key={month.key}><button type="button" className="month-history-toggle" onClick={() => setOpenMonths((current) => ({ ...current, [month.key]: !current[month.key] }))} aria-expanded={isOpen} aria-controls={`history-month-${month.key}`}><span className="month-history-title"><b>{month.label}</b><small>{month.isCurrent ? "Current month" : `${month.entries.length} ledger entries`}</small></span><span className="month-history-net"><strong className={month.net >= 0 ? "amount-income" : "amount-expense"}>{month.net >= 0 ? "+" : "−"}{fmt.format(Math.abs(month.net))}</strong><small>{isOpen ? "Tap to close" : "Tap to view"}</small></span><ChevronRight size={17} className="month-history-chevron" /></button>{isOpen && <div className="month-history-detail" id={`history-month-${month.key}`}><div className="month-history-metrics"><div><span>Income</span><b className="amount-income">{fmt.format(month.income)}</b></div><div><span>Expenses</span><b className="amount-expense">{fmt.format(month.expense)}</b></div><div><span>Daily outflow</span><b>{fmt.format(month.averageDailyExpense)}</b></div></div><div className="month-history-entry-list">{month.entries.length ? month.entries.slice(0, 5).map((entry) => <div className="month-history-entry" key={entry.id}><span>{entry.merchantNote}</span><b className={entry.type === "income" ? "amount-income" : entry.type === "expense" ? "amount-expense" : "amount-transfer"}>{entry.type === "income" ? "+" : entry.type === "expense" ? "−" : "↔"}{fmt.format(entry.amount)}</b></div>) : <span className="budget-note">No transactions recorded for this month.</span>}</div></div>}</div>; })}</div></section>
    {(archivedGoals.length + archivedTrips.length + archivedLoans.length) > 0 && <section className="paper-card section-card"><div className="section-head"><div><div className="page-kicker">Completed plans</div><h2>Still part of the story.</h2></div><span className="month-hand-date">Kept for two years</span></div><p className="category-section-note">Finished goals, trips, and loans leave Plans & Progress but remain editable here.</p><div className="schedule-list">{archivedGoals.map((goal) => <button key={goal.id} className="paper-card schedule-card" onClick={() => onOpenGoal(goal)}><div className="horizon-card-topline"><span className="schedule-status paused">Goal complete</span><ChevronRight size={17} /></div><div className="horizon-card-main"><div><h3>{goal.name}</h3><span className="horizon-card-action">Completed {shortDate(goal.completedAt ?? goal.deadline)}</span></div><strong>{fmt.format(goal.saved)}</strong></div></button>)}{archivedTrips.map((trip) => <button key={trip.id} className="paper-card schedule-card" onClick={() => onOpenTrip(trip)}><div className="horizon-card-topline"><span className="schedule-status paused">Plan complete</span><ChevronRight size={17} /></div><div className="horizon-card-main"><div><h3>{trip.name}</h3><span className="horizon-card-action">Completed {shortDate(trip.completedAt ?? trip.dates)}</span></div><strong>{fmt.format(trip.budget)}</strong></div></button>)}{archivedLoans.map((loan) => <button key={loan.id} className="paper-card schedule-card" onClick={() => onOpenLoan(loan)}><div className="horizon-card-topline"><span className="schedule-status paused">Loan complete</span><ChevronRight size={17} /></div><div className="horizon-card-main"><div><h3>{loan.title}</h3><span className="horizon-card-action">Completed {shortDate(loan.completedAt ?? loan.dueDate)}</span></div><strong>{fmt.format(loan.totalAmount)}</strong></div></button>)}</div></section>}
    <section className="paper-card section-card history-register"><div className="section-head"><div><div className="page-kicker">Complete register</div><h2>{pendingOnly ? "Pending ledger" : selectedCategory ? `${selectedCategory.name} ledger` : "All entries"}</h2></div><div className="filter-row">{(["all", "expense", "income", "transfer"] as const).map((item) => <button key={item} className={`filter-button ${filter === item && !pendingOnly ? "active" : ""}`} onClick={() => { onPendingOnlyChange(false); onFilter(item); }}>{item[0].toUpperCase() + item.slice(1)}</button>)}<button className={`filter-button pending-history-filter ${pendingOnly ? "active" : ""}`} onClick={() => onPendingOnlyChange(!pendingOnly)}>Pending{pendingCount ? ` (${pendingCount})` : ""}</button></div></div>{pendingOnly && <div className="pending-history-banner"><CircleCheck size={15} /><span>Only entries waiting for payment confirmation are shown.</span><button onClick={() => onPendingOnlyChange(false)}>Show all entries</button></div>}{selectedCategory && <button className="filter-note" onClick={onClearCategory}>Viewing {selectedCategory.name} <X size={12} /></button>}<div className="search-box"><Search size={15} /><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder={pendingOnly ? "Search your pending ledger" : "Search a merchant or category"} /></div><div className="transaction-list">{registerTransactions.length ? registerTransactions.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onSelect={onSelectTransaction} />) : <p className="budget-note">{pendingOnly ? "No pending entries match this search or category context." : "No entries match this view. Try another filter or clear the category context."}</p>}</div></section>
  </>;
}

function TransactionRow({ transaction, categories, onSelect }: { transaction: Transaction; categories: Category[]; onSelect: (transaction: Transaction) => void }) {
  const category = categories.find((item) => item.id === transaction.categoryId);
  const descriptor = transaction.cashFlowKind === "loan-disbursement" ? "Loan cash movement · original amount" : transaction.cashFlowKind === "loan-settlement" ? "Loan cash movement · settlement" : transaction.type === "transfer" ? "Transfer between your accounts" : category?.name ?? "Uncategorised";
  const signed = transaction.type === "income" ? "+" : transaction.type === "expense" ? "−" : "↔";
  const amountClass = transaction.type === "income" ? "amount-income" : transaction.type === "expense" ? "amount-expense" : "amount-transfer";
  return <button className="transaction-row transaction-button" onClick={() => onSelect(transaction)}><div className="transaction-title"><span className="entry-kind">{transaction.cashFlowKind ? "Loan flow" : transaction.type === "income" ? "Inflow" : transaction.type === "expense" ? "Outflow" : "Transfer"}</span><strong title={transaction.merchantNote}>{transaction.merchantNote}</strong><span className="category-picker-label">{category && <CategoryIcon icon={category.icon} size={14} />}{descriptor}{transaction.tag?.goalId ? " · Goal tagged" : ""}{transaction.tag?.tripId ? " · Trip tagged" : ""}</span></div><div className="transaction-amount">{transaction.settlementStatus === "pending" && <span className="pending-payment-chip">Pending</span>}<strong className={amountClass}>{signed}{fmt.format(transaction.amount)}</strong><span className="transaction-date-stamp">{transaction.date}</span></div></button>;
}

function InsightsView({ transactions, categories, categorySpent, onOpenCategory }: { transactions: Transaction[]; categories: Category[]; categorySpent: Record<string, number>; onOpenCategory: (id: string) => void }) {
  const [statsTab, setStatsTab] = useState<"insight" | "summary">("insight");
  const months = ["Mar", "Apr", "May", "Jun", "Jul", "Aug"].map((label, index) => {
    const month = String(index + 3).padStart(2, "0");
    const entries = transactions.filter((transaction) => transaction.date.startsWith(`2026-${month}`));
    return { label, income: entries.filter((transaction) => transaction.type === "income").reduce((sum, transaction) => sum + transaction.amount, 0), expense: entries.filter((transaction) => transaction.type === "expense").reduce((sum, transaction) => sum + transaction.amount, 0) };
  });
  const max = Math.max(...months.flatMap((month) => [month.income, month.expense]), 1);
  const expenseTopCategories = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeTotal = transactions.filter((transaction) => transaction.type === "income").reduce((sum, transaction) => sum + transaction.amount, 0);
  const expenseTotal = transactions.filter((transaction) => transaction.type === "expense").reduce((sum, transaction) => sum + transaction.amount, 0);
  const spent = expenseTopCategories.reduce((sum, category) => sum + (categorySpent[category.id] ?? 0), 0);
  const mix = expenseTopCategories.filter((category) => category.monthlyBudget > 0 && (categorySpent[category.id] ?? 0) > 0).sort((a, b) => (categorySpent[b.id] ?? 0) - (categorySpent[a.id] ?? 0));
  const stops = mix.reduce((parts, category, index) => { const start = parts.end; const size = spent ? ((categorySpent[category.id] ?? 0) / spent) * 100 : 0; return { end: start + size, gradient: `${parts.gradient}${category.color} ${start}% ${start + size}%${index < mix.length - 1 ? ", " : ""}` }; }, { end: 0, gradient: "" });
  const today = new Date();
  const daysInCurrentMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
  const elapsedDays = Math.min(daysInCurrentMonth, today.getDate());
  const budgetPacing = expenseTopCategories.filter((category) => category.monthlyBudget > 0).map((category) => {
    const spentAmount = categorySpent[category.id] ?? 0;
    const averageDaily = spentAmount / Math.max(1, elapsedDays);
    const projected = averageDaily * daysInCurrentMonth;
    const safeSpendToDate = category.monthlyBudget * (elapsedDays / daysInCurrentMonth);
    const status = projected > category.monthlyBudget ? "Overshoot likely" : spentAmount > safeSpendToDate ? "Above safe pace" : "On pace";
    return { category, spentAmount, averageDaily, projected, safeSpendToDate, status, remaining: Math.max(0, category.monthlyBudget - spentAmount) };
  });
  return <>
    <header className="page-header stats-page-header"><div><div className="page-kicker">Analytics & patterns</div><h1>Spending insight<br />& category mix.</h1><p className="page-subtitle">Understand where capital concentrates over time.</p></div><div className="analytics-mode-switch" role="tablist" aria-label="Analytics workspace"><div className="analytics-mode-label">Choose a lens</div><div className="analytics-mode-tabs"><button className={`analytics-mode-tab ${statsTab === "insight" ? "active" : ""}`} onClick={() => setStatsTab("insight")}><strong>Trend & mix</strong><span>Cash flow and category pressure</span></button><button className={`analytics-mode-tab ${statsTab === "summary" ? "active" : ""}`} onClick={() => setStatsTab("summary")}><strong>Monthly summary</strong><span>Net savings and budget bars</span></button></div></div></header>
    {statsTab === "insight" ? <><div className="insights-grid"><article className="paper-card section-card"><h2>Six-month cash flow</h2><div className="trend-chart">{months.map((month) => <div className="trend-column" key={month.label}><div className="bars"><div className="bar income" style={{ height: `${(month.income / max) * 100}%` }} /><div className="bar expense" style={{ height: `${(month.expense / max) * 100}%` }} /></div><span>{month.label}</span></div>)}</div><div className="chart-legend"><div><span className="dot income" /> Inflow</div><div><span className="dot expense" /> Outflow</div></div></article><aside className="paper-card side-summary"><div className="card-head"><h2>Category mix</h2><span className="text-link">Tap a slice</span></div><div className="donut-ring" onClick={() => mix[0] && onOpenCategory(mix[0].id)} style={{ background: stops.gradient ? `conic-gradient(${stops.gradient})` : "#ded8ca" }}><div className="donut-hole"><strong>{fmt.format(spent)}</strong><span>Total out</span></div></div><div className="category-mix-list">{expenseTopCategories.map((category) => <button className="mix-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><div className="category-picker-label"><span className="category-symbol" style={{ color: category.color }}><CategoryIcon icon={category.icon} size={14} /></span><strong>{category.name}</strong></div><b>{fmt.format(categorySpent[category.id] ?? 0)}</b></button>)}</div></aside></div><section className="paper-card budget-pacing-sheet"><div className="section-head"><div><div className="page-kicker">Budget pacing</div><h2>Are your categories on track?</h2></div><span className="month-hand-date">Day {elapsedDays} of {daysInCurrentMonth}</span></div><p className="budget-note">Daily burn rate and projected month-end spend make pressure visible before the month closes.</p><div className="budget-pacing-list">{budgetPacing.map(({ category, spentAmount, averageDaily, projected, safeSpendToDate, status, remaining }) => { const percentage = category.monthlyBudget ? Math.min(100, (spentAmount / category.monthlyBudget) * 100) : 0; const statusClass = status === "On pace" ? "on-pace" : "warning"; return <div className="budget-pacing-row" key={category.id}><div className="budget-pacing-top"><span className="category-picker-label"><CategoryIcon icon={category.icon} size={15} /><strong>{category.name}</strong></span><b>{fmt.format(spentAmount)} <em>of {fmt.format(category.monthlyBudget)}</em></b></div><div className="progress-track"><div className="progress-fill" style={{ width: `${percentage}%`, background: category.color }} /></div><div className="budget-pacing-meta"><span className={`pacing-status ${statusClass}`}>{status}</span><span>{fmt.format(averageDaily)} / day</span><span>Projected {fmt.format(projected)}</span><span>{fmt.format(remaining)} left</span></div>{spentAmount > safeSpendToDate && <div className="pacing-warning">Spending is above the safe pace for day {elapsedDays}.</div>}</div>; })}</div></section></> : <div className="summary-view-grid"><article className="paper-card summary-hero"><div className="page-kicker">Monthly summary</div><h2>Net savings</h2><strong>{fmt.format(incomeTotal - expenseTotal)}</strong><p>Income less recorded expenses. Transfers stay outside this calculation.</p></article><section className="paper-card summary-breakdown"><div className="section-head"><h2>Category breakdown</h2><span className="month-hand-date">August 2026</span></div>{expenseTopCategories.map((category) => { const value = categorySpent[category.id] ?? 0; const base = category.monthlyBudget || Math.max(value, 1); return <button className="summary-category-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><div><span className="category-picker-label"><CategoryIcon icon={category.icon} size={15} />{category.name}</span><b>{fmt.format(value)} <em>of {fmt.format(category.monthlyBudget)}</em></b></div><div className="progress-track"><div className="progress-fill" style={{ width: `${Math.min(100, (value / base) * 100)}%`, background: category.color }} /></div></button>; })}</section></div>}
  </>;
}

function ReportsView({ transactions, categories, accounts, onSelectTransaction, onBack }: { transactions: Transaction[]; categories: Category[]; accounts: Array<Account & { balance: number }>; onSelectTransaction: (transaction: Transaction) => void; onBack: () => void }) {
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [accountId, setAccountId] = useState("all");
  const [categoryId, setCategoryId] = useState("all");
  const [transactionType, setTransactionType] = useState<"all" | TransactionType>("all");

  const categoryName = (id?: string) => categories.find((category) => category.id === id)?.name ?? "Uncategorised";
  const accountName = (id: string) => accounts.find((account) => account.id === id)?.name ?? "Unknown account";
  const filteredLedger = useMemo(() => transactions.filter((transaction) => {
    if (startDate && transaction.date < startDate) return false;
    if (endDate && transaction.date > endDate) return false;
    if (accountId !== "all" && transaction.accountId !== accountId && transaction.destinationAccountId !== accountId) return false;
    if (categoryId !== "all" && transaction.categoryId !== categoryId) return false;
    if (transactionType !== "all" && transaction.type !== transactionType) return false;
    return true;
  }).slice().sort((a, b) => b.date.localeCompare(a.date)), [transactions, startDate, endDate, accountId, categoryId, transactionType]);
  const summary = useMemo(() => {
    const income = filteredLedger.filter((transaction) => transaction.type === "income").reduce((sum, transaction) => sum + transaction.amount, 0);
    const expense = filteredLedger.filter((transaction) => transaction.type === "expense").reduce((sum, transaction) => sum + transaction.amount, 0);
    const transfers = filteredLedger.filter((transaction) => transaction.type === "transfer").reduce((sum, transaction) => sum + transaction.amount, 0);
    return { income, expense, transfers, net: income - expense, count: filteredLedger.length };
  }, [filteredLedger]);
  const allocation = useMemo(() => {
    const values: Record<string, number> = {};
    filteredLedger.filter((transaction) => transaction.type === "expense").forEach((transaction) => {
      const category = categories.find((item) => item.id === transaction.categoryId);
      const id = category?.parentId ?? category?.id ?? "uncategorised";
      values[id] = (values[id] ?? 0) + transaction.amount;
    });
    return Object.entries(values).map(([id, amount]) => { const category = categories.find((item) => item.id === id); return { id, amount, name: categoryName(id), icon: category?.icon }; }).sort((a, b) => b.amount - a.amount).slice(0, 4);
  }, [filteredLedger, categories]);
  const reportPeriod = `${startDate || "All dates"} → ${endDate || "Today"}`;
  const reportFileName = `expense-ledger-${startDate || "all"}-${endDate || "to-date"}`;
  const resetFilters = () => { setStartDate(""); setEndDate(""); setAccountId("all"); setCategoryId("all"); setTransactionType("all"); };
  const downloadBlob = (blob: Blob, extension: string) => {
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${reportFileName}.${extension}`;
    link.click();
    URL.revokeObjectURL(url);
  };
  const exportCsv = () => {
    const rows: Array<Array<string | number>> = [["Expense Tracker report"], ["Period", reportPeriod], ["Records", summary.count], ["Inflow", summary.income], ["Outflow", summary.expense], ["Net movement", summary.net], [], ["Date", "Type", "Description", "Category", "Account", "Amount"], ...filteredLedger.map((transaction) => [transaction.date, transaction.type, transaction.merchantNote, transaction.type === "transfer" ? "Transfer" : categoryName(transaction.categoryId), accountName(transaction.accountId), transaction.amount])];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replace(/"/g, '""')}"`).join(",")).join("\n");
    downloadBlob(new Blob([csv], { type: "text/csv;charset=utf-8" }), "csv");
  };
  const exportPdf = () => {
    const doc = new jsPDF({ unit: "pt", format: "a4" });
    const width = doc.internal.pageSize.getWidth();
    const height = doc.internal.pageSize.getHeight();
    let y = 54;
    const pageHeader = () => {
      doc.setFillColor(27, 58, 43); doc.rect(0, 0, width, 102, "F");
      doc.setTextColor(210, 168, 76); doc.setFont("helvetica", "bold"); doc.setFontSize(8); doc.text("EXPENSE · FINANCIAL FIELDBOOK", 44, 31);
      doc.setTextColor(255, 255, 255); doc.setFontSize(24); doc.text("Report, on record.", 44, 66);
      doc.setTextColor(102, 96, 84); doc.setFontSize(9); doc.text(reportPeriod, 44, 124);
      doc.setDrawColor(222, 214, 198); doc.line(44, 136, width - 44, 136);
    };
    pageHeader(); y = 165;
    doc.setTextColor(35, 43, 39); doc.setFont("helvetica", "bold"); doc.setFontSize(10);
    doc.text(`INFLOW ${fmt.format(summary.income)}`, 44, y); doc.text(`OUTFLOW ${fmt.format(summary.expense)}`, 200, y); doc.text(`NET ${fmt.format(summary.net)}`, 380, y);
    y += 34; doc.setTextColor(112, 102, 88); doc.setFontSize(8); doc.text("DATE", 44, y); doc.text("RECORD", 116, y); doc.text("ACCOUNT", 362, y); doc.text("AMOUNT", width - 44, y, { align: "right" }); y += 15;
    filteredLedger.forEach((transaction) => {
      if (y > height - 50) { doc.addPage(); pageHeader(); y = 165; }
      doc.setDrawColor(229, 221, 208); doc.line(44, y, width - 44, y); y += 16;
      const sign = transaction.type === "income" ? "+" : transaction.type === "expense" ? "−" : "↔";
      doc.setTextColor(72, 66, 56); doc.setFont("helvetica", "bold"); doc.setFontSize(8); doc.text(transaction.date, 44, y);
      doc.setTextColor(31, 40, 36); doc.setFontSize(9); doc.text(transaction.merchantNote.slice(0, 34), 116, y);
      doc.setTextColor(112, 102, 88); doc.setFont("helvetica", "normal"); doc.setFontSize(8); doc.text(accountName(transaction.accountId).slice(0, 22), 362, y);
      doc.setTextColor(transaction.type === "income" ? 44 : 128, transaction.type === "income" ? 99 : 59, transaction.type === "income" ? 59 : 47); doc.setFont("helvetica", "bold"); doc.text(`${sign}${fmt.format(transaction.amount)}`, width - 44, y, { align: "right" }); y += 18;
    });
    if (!filteredLedger.length) { doc.setTextColor(112, 102, 88); doc.setFont("helvetica", "normal"); doc.setFontSize(10); doc.text("No records match the selected filters.", 44, y + 18); }
    doc.save(`${reportFileName}.pdf`);
  };

  return <>
    <header className="page-header reports-page-header"><div><div className="back-line"><button className="back-control" onClick={onBack}><ArrowLeft size={14} /> Back to Settings</button></div><div className="page-kicker">Reports & export</div><h1>Report, on record.</h1><p className="page-subtitle">Cut the ledger to the period and context that needs an answer.</p></div></header>
    <section className="paper-card report-filter-sheet"><div className="section-head report-filter-head"><div><div className="page-kicker">Ledger scope</div><h2>Filter the record</h2></div><button className="text-link report-reset" onClick={resetFilters}>Reset filters <X size={13} /></button></div><div className="report-filter-grid"><LedgerDateField label="From date" value={startDate} onChange={setStartDate} /><LedgerDateField label="To date" value={endDate} onChange={setEndDate} /><label><span>Account</span><select value={accountId} onChange={(event) => setAccountId(event.target.value)}><option value="all">All accounts</option>{accounts.map((account) => <option key={account.id} value={account.id}>{account.name}</option>)}</select></label><label><span>Category</span><select value={categoryId} onChange={(event) => setCategoryId(event.target.value)}><option value="all">All categories</option>{categories.map((category) => <option key={category.id} value={category.id}>{category.parentId ? `↳ ${category.name}` : category.name}</option>)}</select>{categoryId !== "all" && <small className="selected-category-caption"><CategoryIcon icon={categories.find((category) => category.id === categoryId)?.icon} size={13} /> Selected category</small>}</label><label><span>Movement</span><select value={transactionType} onChange={(event) => setTransactionType(event.target.value as "all" | TransactionType)}><option value="all">All movement</option><option value="income">Inflow</option><option value="expense">Outflow</option><option value="transfer">Transfer</option></select></label></div><div className="report-scope-line"><span>Viewing <b>{summary.count}</b> matching record{summary.count === 1 ? "" : "s"}</span><span>{reportPeriod}</span></div></section>
    <section className="report-summary-grid"><article className="paper-card report-stat income"><span>Filtered inflow</span><strong>{fmt.format(summary.income)}</strong><small>Income entries only</small></article><article className="paper-card report-stat expense"><span>Filtered outflow</span><strong>{fmt.format(summary.expense)}</strong><small>Expense entries only</small></article><article className="paper-card report-stat net"><span>Net movement</span><strong>{summary.net >= 0 ? "+" : "−"}{fmt.format(Math.abs(summary.net))}</strong><small>Transfers remain neutral</small></article><article className="paper-card report-stat allocation"><span>Records held</span><strong>{summary.count}</strong><small>{summary.transfers ? `${fmt.format(summary.transfers)} in transfers` : "No transfers in scope"}</small></article></section>
    <section className="paper-card report-register"><div className="section-head report-register-head"><div><div className="page-kicker">Filtered register</div><h2>Entries ready to export</h2></div><div className="report-export-actions"><button className="report-export-button csv" onClick={exportCsv}><Download size={14} /> Download CSV</button><button className="report-export-button pdf" onClick={exportPdf}><FileText size={14} /> Download PDF</button></div></div>{allocation.length > 0 && <div className="report-allocation"><span>Expense allocation</span>{allocation.map((item) => <b key={item.id} className="category-picker-label"><CategoryIcon icon={item.icon} size={13} />{item.name} <em>{fmt.format(item.amount)}</em></b>)}</div>}<div className="transaction-list report-transaction-list">{filteredLedger.length ? filteredLedger.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onSelect={onSelectTransaction} />) : <div className="horizon-empty"><strong>No records in this scope.</strong>Change the date, account, category, or movement filter to reopen the register.</div>}</div></section>
  </>;
}

function NotificationInboxView({ items, unreadCount, onBack, onOpenNotice, onMarkAllRead }: { items: AppNotification[]; unreadCount: number; onBack: () => void; onOpenNotice: (id: string) => void; onMarkAllRead: () => void }) {
  return <>
    <header className="workspace-page-header inbox-page-header"><button className="workspace-back-button" onClick={onBack}><ArrowLeft size={15} /> Back to Overview</button><div><div className="page-kicker">Ledger notices</div><h1>Notification inbox</h1><p className="page-subtitle">Every reminder and ledger notice stays here, even after you have seen it.</p></div></header>
    <section className="paper-card inbox-sheet">
      <div className="inbox-sheet-head"><div><span className={`settings-status-chip ${unreadCount ? "is-active" : ""}`}>{unreadCount ? `${unreadCount} unread` : "All caught up"}</span><h2>{unreadCount ? "Keep the important things in view." : "Your ledger is quiet for now."}</h2></div>{unreadCount > 0 && <button className="secondary-button inbox-mark-read" onClick={onMarkAllRead}><CheckCircle2 size={15} /> Mark all read</button>}</div>
      {items.length ? <div className="notification-list inbox-notification-list">{items.map((item) => <button type="button" className={`notification-item ${item.tone} ${item.read ? "is-read" : "is-unread"}`} key={item.id} onClick={() => onOpenNotice(item.id)} aria-label={item.read ? `${item.title}, read` : `${item.title}, mark as read`}><span className="notification-item-topline"><b>{item.title}</b><time dateTime={item.createdAt}>{new Date(item.createdAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}</time></span><span>{item.detail}</span>{!item.read && <em>Mark as read</em>}</button>)}</div> : <div className="horizon-empty inbox-empty"><Bell size={20} /><strong>Your inbox is ready.</strong><span>Due dates, daily ledger reminders, and future notices will remain here when they arrive.</span></div>}
    </section>
  </>;
}

function WorkRoutineView({ routines, attendance, onCreateRoutine, onToggleRoutineAttendance, onRemoveRoutine }: { routines: WorkRoutine[]; attendance: RoutineAttendance[]; onCreateRoutine: (name: string, daysPerWeek: RoutineDaysPerWeek) => void; onToggleRoutineAttendance: (routineId: string, date: string) => void; onRemoveRoutine: (routine: WorkRoutine) => void }) {
  const activeRoutines = routines.filter((routine) => routine.status !== "archived");
  const [selectedRoutineId, setSelectedRoutineId] = useState<string | null>(null);
  const [composerOpen, setComposerOpen] = useState(false);
  const [name, setName] = useState("");
  const [daysPerWeek, setDaysPerWeek] = useState<RoutineDaysPerWeek>(5);
  const [cursor, setCursor] = useState(() => clampRoutineMonth(new Date()));
  const selectedRoutine = activeRoutines.find((routine) => routine.id === selectedRoutineId) ?? activeRoutines[0] ?? null;
  const calendar = selectedRoutine ? routineCalendarDays(cursor.getFullYear(), cursor.getMonth(), selectedRoutine.daysPerWeek) : [];
  const expectedDays = selectedRoutine ? expectedRoutineDaysInMonth(cursor.getFullYear(), cursor.getMonth(), selectedRoutine.daysPerWeek) : [];
  const attendedDates = new Set(attendance.filter((item) => item.routineId === selectedRoutine?.id && item.attended).map((item) => item.date));
  const attendedThisMonth = expectedDays.filter((date) => attendedDates.has(date)).length;
  const totalAttendedThisMonth = calendar.filter((day) => day.inCurrentMonth && attendedDates.has(day.date)).length;
  const create = () => {
    if (!name.trim()) return;
    onCreateRoutine(name, daysPerWeek);
    setName("");
    setComposerOpen(false);
  };

  return <div className="routine-workspace">
    <section className="routine-intro paper-card"><div><div className="page-kicker">Monthly attendance</div><h2>Show up. See the month.</h2><p>For work, clinic, school, shifts, or any routine that deserves a simple record.</p></div><button className="primary-button" onClick={() => setComposerOpen(true)}><Plus size={15} /> Add routine</button></section>
    {(composerOpen || activeRoutines.length === 0) && <section className="paper-card routine-composer"><div><span className="draft-kicker">New routine</span><h3>What do you want to track?</h3></div><label className="form-field"><span>Routine name</span><input value={name} onChange={(event) => setName(event.target.value)} placeholder="e.g. Clinic days, office, teaching" autoFocus /></label><div className="routine-days-field"><span>Expected days each week</span><div>{([3, 4, 5, 6, 7] as RoutineDaysPerWeek[]).map((days) => <button type="button" key={days} className={days === daysPerWeek ? "selected" : ""} onClick={() => setDaysPerWeek(days)}>{days}<small>days</small></button>)}</div><p>This marks the first {daysPerWeek} days in each Monday–Sunday workweek as expected. You can still record an extra day when you work one.</p></div><div className="draft-actions"><button className="primary-button" onClick={create} disabled={!name.trim()}>Create routine</button>{activeRoutines.length > 0 && <button className="secondary-button" onClick={() => setComposerOpen(false)}>Cancel</button>}</div></section>}
    {activeRoutines.length > 0 && <><div className="routine-selector" aria-label="Choose routine">{activeRoutines.map((routine) => <div key={routine.id} className="routine-selector-item"><button className={selectedRoutine?.id === routine.id ? "active" : ""} onClick={() => setSelectedRoutineId(routine.id)}><span style={{ color: routine.color }}><ClipboardCheck size={17} /></span><strong>{routine.name}</strong><small>{routine.daysPerWeek} days / week</small></button><button type="button" className="delete-button" onClick={() => onRemoveRoutine(routine)} aria-label={`End ${routine.name}`}><Trash2 size={13} /></button></div>)}</div>
      {selectedRoutine && <section className="paper-card routine-calendar-sheet"><div className="routine-calendar-head"><div><span className="draft-kicker">{selectedRoutine.name}</span><h3>{cursor.toLocaleDateString("en-US", { month: "long", year: "numeric" })}</h3></div><div className="routine-month-actions"><button className="calendar-nav-button" onClick={() => setCursor((current) => clampRoutineMonth(new Date(current.getFullYear(), current.getMonth() - 1, 1)))} disabled={cursor.getTime() === clampRoutineMonth(new Date(cursor.getFullYear(), cursor.getMonth() - 1, 1)).getTime()} aria-label="Previous month"><ChevronLeft size={16} /></button><button className="text-link" onClick={() => setCursor(clampRoutineMonth(new Date()))}>This month</button><button className="calendar-nav-button" onClick={() => setCursor((current) => clampRoutineMonth(new Date(current.getFullYear(), current.getMonth() + 1, 1)))} disabled={cursor.getTime() === clampRoutineMonth(new Date(cursor.getFullYear(), cursor.getMonth() + 1, 1)).getTime()} aria-label="Next month"><ChevronRight size={16} /></button></div></div><div className="routine-summary"><div><span>Attended</span><strong>{totalAttendedThisMonth}</strong></div><div><span>Expected</span><strong>{expectedDays.length}</strong></div><div><span>On schedule</span><strong>{attendedThisMonth}/{expectedDays.length}</strong></div></div><div className="routine-weekdays">{["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => <span key={day}>{day}</span>)}</div><div className="routine-calendar-grid">{calendar.map((day) => <button key={day.date} disabled={!day.inCurrentMonth} className={`routine-calendar-day ${day.expected ? "expected" : ""} ${attendedDates.has(day.date) ? "attended" : ""} ${!day.inCurrentMonth ? "outside" : ""}`} onClick={() => day.inCurrentMonth && onToggleRoutineAttendance(selectedRoutine.id, day.date)} aria-label={`${day.date}${attendedDates.has(day.date) ? ", attended. Tap to remove." : ", tap to mark attended."}`}><span>{day.dayOfMonth}</span>{day.expected && <i aria-label="Expected workday" />}</button>)}</div><p className="routine-calendar-note"><i /> Your rolling work view holds this month plus the prior eleven. Attendance remains available for two years in Data History.</p></section>}</>}
  </div>;
}

function HorizonView({ goals, trips, loans, schedules, routines, attendance, onOpenAddGoal, onOpenAddTrip, onOpenAddLoan, onOpenAddSchedule, onOpenGoal, onOpenTrip, onOpenLoan, onOpenSchedule, onCreateRoutine, onToggleRoutineAttendance, onRemoveRoutine }: { goals: Goal[]; trips: Trip[]; loans: Loan[]; schedules: RecurringSchedule[]; routines: WorkRoutine[]; attendance: RoutineAttendance[]; onOpenAddGoal: () => void; onOpenAddTrip: () => void; onOpenAddLoan: () => void; onOpenAddSchedule: () => void; onOpenGoal: (goal: Goal) => void; onOpenTrip: (trip: Trip) => void; onOpenLoan: (loan: Loan) => void; onOpenSchedule: (schedule: RecurringSchedule) => void; onCreateRoutine: (name: string, daysPerWeek: RoutineDaysPerWeek) => void; onToggleRoutineAttendance: (routineId: string, date: string) => void; onRemoveRoutine: (routine: WorkRoutine) => void }) {
  const [horizonTab, setHorizonTab] = useState<"goals" | "trips" | "loans" | "recurring" | "routines">("goals");
  const activeSchedules = schedules.filter((schedule) => schedule.status === "active");
  const activeGoals = goals.filter(planningIsActive);
  const activeTrips = trips.filter(planningIsActive);
  const activeLoans = loans.filter(planningIsActive);
  const scheduledIncome = activeSchedules.filter((schedule) => schedule.type === "income").reduce((sum, schedule) => sum + schedule.amount, 0);
  const scheduledBills = activeSchedules.filter((schedule) => schedule.type === "expense").reduce((sum, schedule) => sum + schedule.amount, 0);
  return (
    <>
      <section className="horizon-hero">
        <div className="horizon-hero-text">
          <div className="page-kicker">Plans & Progress</div>
          <h1>Keep every<br />intention in view.</h1>
          <p>Savings, trips, loans, routine attendance, and recurring money all share one calm home.</p>
          <div className="horizon-actions">
            <button className={`filter-button ${horizonTab === "goals" ? "active" : ""}`} onClick={() => setHorizonTab("goals")}>Savings goals</button>
            <button className={`filter-button ${horizonTab === "trips" ? "active" : ""}`} onClick={() => setHorizonTab("trips")}>Trip & event plans</button>
            <button className={`filter-button ${horizonTab === "loans" ? "active" : ""}`} onClick={() => setHorizonTab("loans")}>Debt & loans</button>
            <button className={`filter-button ${horizonTab === "recurring" ? "active" : ""}`} onClick={() => setHorizonTab("recurring")}>Recurring income & bills</button>
            <button className={`filter-button ${horizonTab === "routines" ? "active" : ""}`} onClick={() => setHorizonTab("routines")}>Work & routines</button>
          </div>
        </div>
        {horizonTab !== "routines" && <button className="primary-button" onClick={horizonTab === "goals" ? onOpenAddGoal : horizonTab === "trips" ? onOpenAddTrip : horizonTab === "loans" ? onOpenAddLoan : onOpenAddSchedule}>
          <Plus size={15} /> {horizonTab === "goals" ? "Add savings goal" : horizonTab === "trips" ? "Add trip plan" : horizonTab === "loans" ? "Add loan record" : "Add recurring schedule"}
        </button>}
      </section>

      {horizonTab === "goals" && (
        <div style={{ display: "grid", gap: 16 }}>
          {activeGoals.map((goal) => {
            const metrics = goalMetrics(goal);
            return (
              <button key={goal.id} className="paper-card horizon-plan-card" onClick={() => onOpenGoal(goal)} aria-label={`Open savings goal ${goal.name}`}>
                <div className="horizon-card-topline"><span>{goal.deadline}</span><ChevronRight size={17} /></div>
                <div className="horizon-card-main"><div><h3>{goal.name}</h3><span className="horizon-card-action">{metrics.daysLeft === null ? "Open goal detail" : `${metrics.daysLeft} days to target`}</span></div><strong>{fmt.format(goal.saved)} <span>of {fmt.format(metrics.personalTarget)}</span></strong></div>
                <div className="budget-track horizon-progress"><div className="budget-fill" style={{ width: `${metrics.percent}%`, background: "#b78a3d" }} /></div>
                <div className="horizon-card-foot"><span>{metrics.dailyNeeded === null ? `${metrics.percent}% held aside` : `${fmt.format(metrics.dailyNeeded)}/day needed`}</span><span>{fmt.format(metrics.remaining)} to go</span></div>
              </button>
            );
          })}
        </div>
      )}

      {horizonTab === "trips" && (
        <div style={{ display: "grid", gap: 16 }}>
          {activeTrips.map((trip) => (
            <button key={trip.id} className="paper-card horizon-plan-card trip-plan-card" onClick={() => onOpenTrip(trip)} aria-label={`Open trip plan ${trip.name}`}>
              <div className="horizon-card-topline"><span>{trip.dates}</span><ChevronRight size={17} /></div>
              <div className="horizon-card-main"><div><h3>{trip.name}</h3><span className="horizon-card-action">Open trip detail</span></div><strong>Working budget: {fmt.format(trip.budget)}</strong></div>
              <p>Linked expenses tagged with this trip automatically accumulate against this ceiling.</p>
            </button>
          ))}
        </div>
      )}

      {horizonTab === "loans" && (
        <div className="loan-workspace">
          <div className="loan-workspace-summary">
            <div><span>Outstanding you owe</span><strong>{fmt.format(activeLoans.filter((loan) => loan.direction === "borrowed").reduce((sum, loan) => sum + Math.max(0, loan.totalAmount - loan.paidAmount), 0))}</strong></div>
            <div><span>Outstanding owed to you</span><strong>{fmt.format(activeLoans.filter((loan) => loan.direction === "lent").reduce((sum, loan) => sum + Math.max(0, loan.totalAmount - loan.paidAmount), 0))}</strong></div>
          </div>
          <div style={{ display: "grid", gap: 16 }}>
            {activeLoans.map((loan) => {
              const remaining = Math.max(0, loan.totalAmount - loan.paidAmount);
              const percentPaid = loan.totalAmount ? Math.min(100, Math.round((loan.paidAmount / loan.totalAmount) * 100)) : 0;
              return <button key={loan.id} className="paper-card horizon-plan-card loan-plan-card" onClick={() => onOpenLoan(loan)} aria-label={`Open ${loan.title} loan record`}>
                <div className="horizon-card-topline"><span className={`loan-direction ${loan.direction}`}>{loan.direction === "borrowed" ? "You owe" : "Owed to you"}</span><ChevronRight size={17} /></div>
                <div className="horizon-card-main"><div><h3>{loan.title}</h3><span className="horizon-card-action">{loan.counterparty} · due {shortDate(loan.dueDate)}</span></div><strong>{fmt.format(remaining)} <span>remaining</span></strong></div>
                <div className="budget-track horizon-progress"><div className="budget-fill" style={{ width: `${percentPaid}%`, background: loan.direction === "borrowed" ? "#a65a3b" : "#2e654f" }} /></div>
                <div className="horizon-card-foot"><span>{percentPaid}% settled</span><span>{loan.terms}</span></div>
              </button>;
            })}
          </div>
        </div>
      )}

      {horizonTab === "recurring" && (
        <div className="schedule-workspace">
          <div className="schedule-workspace-summary">
            <div><span>Upcoming income</span><strong>{fmt.format(scheduledIncome)}</strong><small>{activeSchedules.filter((schedule) => schedule.type === "income").length} active sources</small></div>
            <div><span>Upcoming bills</span><strong>{fmt.format(scheduledBills)}</strong><small>{activeSchedules.filter((schedule) => schedule.type === "expense").length} active schedules</small></div>
          </div>
          <div className="schedule-intro"><div><div className="page-kicker">Recurring ledger</div><h2>Expected money, already in view.</h2></div><p>Record a bill as paid or income as received. The app creates the ledger entry and advances its next due date.</p></div>
          <div className="schedule-list">
            {schedules.slice().sort((a, b) => a.nextDueDate.localeCompare(b.nextDueDate)).map((schedule) => <button key={schedule.id} className={`paper-card schedule-card ${schedule.type} ${schedule.status}`} onClick={() => onOpenSchedule(schedule)} aria-label={`Open recurring schedule ${schedule.name}`}>
              <div className="horizon-card-topline"><span className={`schedule-status ${schedule.status}`}>{schedule.status === "active" ? scheduleDueLabel(schedule.nextDueDate) : "Paused"}</span><ChevronRight size={17} /></div>
              <div className="horizon-card-main"><div><h3>{schedule.name}</h3><span className="horizon-card-action">{schedule.type === "income" ? "Income" : "Bill"} · {scheduleFrequencyLabel(schedule.frequency)}</span></div><strong>{fmt.format(schedule.amount)}</strong></div>
              <div className="horizon-card-foot"><span>Next {shortDate(schedule.nextDueDate)}</span><span>{schedule.history.length} recorded</span></div>
            </button>)}
          </div>
        </div>
      )}

      {horizonTab === "routines" && <WorkRoutineView routines={routines} attendance={attendance} onCreateRoutine={onCreateRoutine} onToggleRoutineAttendance={onToggleRoutineAttendance} onRemoveRoutine={onRemoveRoutine} />}
    </>
  );
}

function LegacySettingsView({ categories, subcategorySpent, reminderSettings, reminderPushStatus, reminderPushBusy, signedIn, onOpenAddIncomeCategory, onOpenAddSub, onDeleteCategory, onSaveReminderSettings, onEnableDeviceReminder, onOpenReports, onOpenAccounts }: {
  categories: Category[]; subcategorySpent: Record<string, number>;
  onOpenAddIncomeCategory: () => void; onOpenAddSub: (parentId: string) => void; onDeleteCategory: (id: string) => void;
  reminderSettings: ReminderSettings; reminderPushStatus: string | null; reminderPushBusy: boolean; signedIn: boolean;
  onSaveReminderSettings: (settings: ReminderSettings) => void; onEnableDeviceReminder: () => void; onOpenReports: () => void; onOpenAccounts: () => void;
}) {
  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeList = categories.filter((c) => c.type === "income");
  const deviceTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  const [openSection, setOpenSection] = useState<"notifications" | "currency" | "accounts" | "expenses" | "income" | "export" | null>(null);
  const toggleSection = (section: typeof openSection) => setOpenSection((current) => current === section ? null : section);
  const timezoneChoices = Array.from(new Set([deviceTimezone, "Asia/Dhaka", "Asia/Kolkata", "Asia/Singapore", "Europe/London", "America/New_York", "UTC"]));

  return (
    <>
      <header className="page-header"><div><div className="page-kicker">Preferences & taxonomy</div><h1>Settings.</h1><p className="page-subtitle">Manage categories, income streams, and personal preferences.</p></div></header>
      <div style={{ display: "grid", gap: 24 }}>
        <article className="paper-card settings-card reminder-settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("notifications")} aria-expanded={openSection === "notifications"}>
            <span className={`settings-status-chip ${reminderSettings.enabled ? "is-active" : ""}`}>{reminderSettings.enabled ? "Configured" : "Not set"}</span>
            <span><span className="page-kicker">Day-end ledger reminder</span><strong>Close the day with a complete ledger.</strong><small>{reminderSettings.enabled ? `Daily check-in set for ${formatReminderTime(reminderSettings.time)}` : "Choose a time when you are ready"}</small></span>
            <ChevronRight className={openSection === "notifications" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "notifications" && <div className="settings-accordion-content">
            <div className="section-head reminder-settings-head">
              <p className="category-section-note">Choose when your personal expense reminder should arrive. It will appear in your inbox and on this device when permission is allowed.</p>
              <button type="button" className={`reminder-toggle ${reminderSettings.enabled ? "is-enabled" : ""}`} onClick={() => reminderSettings.enabled ? onSaveReminderSettings({ ...reminderSettings, enabled: false }) : onEnableDeviceReminder()} disabled={!signedIn || reminderPushBusy} aria-pressed={reminderSettings.enabled}>
                <span aria-hidden="true" />{reminderSettings.enabled ? "Daily reminder on" : reminderPushBusy ? "Connecting device…" : "Enable daily reminder"}
              </button>
            </div>
            <div className="reminder-settings-controls">
              <label className="reminder-time-field"><span>Daily check-in time</span><input type="time" value={reminderSettings.time} disabled={!signedIn} onChange={(event) => onSaveReminderSettings({ ...reminderSettings, time: event.target.value })} /></label>
              <label className="reminder-timezone"><span>Reminder location</span><select value={reminderSettings.timezone} disabled={!signedIn} onChange={(event) => onSaveReminderSettings({ ...reminderSettings, timezone: event.target.value })}>{timezoneChoices.map((timezone) => <option key={timezone} value={timezone}>{timezone === deviceTimezone ? `${timezone} · this device` : timezone}</option>)}</select><small>Your chosen time follows this location’s local clock.</small></label>
            </div>
            {!signedIn && <p className="reminder-settings-note">Sign in to save a reminder that follows your personal ledger.</p>}
            {signedIn && !reminderSettings.enabled && <p className="reminder-settings-note">Enable this once to allow a browser or device notification at your selected time.</p>}
            {reminderPushStatus && <p className="reminder-settings-status" role="status">{reminderPushStatus}</p>}
          </div>}
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("currency")} aria-expanded={openSection === "currency"}>
            <span className="category-symbol"><CircleDollarSign size={17} /></span><span><span className="page-kicker">Ledger currency</span><strong>{CURRENCY_OPTIONS.find((currency) => currency.code === reminderSettings.currency)?.label ?? reminderSettings.currency}</strong><small>Use one display currency across your ledger, insights, and exports.</small></span><ChevronRight className={openSection === "currency" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "currency" && <div className="settings-accordion-content currency-settings-content"><div className="currency-settings-head"><div><span className="page-kicker">Display currency</span><strong>{reminderSettings.currency}</strong></div><p>This affects how the ledger is displayed; it does not convert recorded amounts.</p></div><div className="currency-option-grid" role="list" aria-label="Choose display currency">{CURRENCY_OPTIONS.map((currency) => <button key={currency.code} type="button" role="listitem" className={`currency-option ${reminderSettings.currency === currency.code ? "selected" : ""}`} disabled={!signedIn} onClick={() => onSaveReminderSettings({ ...reminderSettings, currency: currency.code })}><b>{currency.code}</b><span>{currency.label.replace(/\s*\([^)]*\)/, "")}</span><em>{currency.label.match(/\(([^)]+)\)/)?.[1] ?? currency.code}</em></button>)}</div>{!signedIn && <p className="reminder-settings-note">Sign in to save your preferred display currency.</p>}</div>}
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("accounts")} aria-expanded={openSection === "accounts"}>
            <span className="category-symbol"><HandCoins size={17} /></span><span><span className="page-kicker">Accounts</span><strong>Accounts & assets</strong><small>Review balances, liabilities, and account registers.</small></span><ChevronRight className={openSection === "accounts" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "accounts" && <div className="settings-accordion-content export-settings-content"><p className="category-section-note">Keep your cash, cards, assets, and liabilities in one clear register. You can add or update accounts from the workspace.</p><button className="primary-button" onClick={onOpenAccounts}><HandCoins size={15} /> Open Accounts & Assets</button></div>}
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("expenses")} aria-expanded={openSection === "expenses"}>
            <span className="category-symbol"><Wallet size={17} /></span><span><span className="page-kicker">Money taxonomy</span><strong>Expense categories ({expenseTop.length})</strong><small>Five permanent types and their detailed subcategories.</small></span><ChevronRight className={openSection === "expenses" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "expenses" && <div className="settings-accordion-content"><p className="category-section-note">Add as many detailed subcategories as you need beneath the permanent spending types.</p><div className="category-edit-list" style={{ display: "grid", gap: 12 }}>
            {expenseTop.map((cat) => {
              const subs = categories.filter((c) => c.parentId === cat.id);
              return (
                <div key={cat.id} className="category-group-row" style={{ background: "#fcfaf6", border: "1px solid #ded8ca", borderRadius: 12, padding: 14 }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span className="category-symbol" style={{ color: cat.color }}><CategoryIcon icon={cat.icon} size={17} /></span>
                      <strong style={{ fontSize: 15 }}>{cat.name}</strong>
                      {cat.isPermanent && <span className="permanent-category-tag">Permanent type</span>}
                      <span className="cat-budget-tag" style={{ fontSize: 12, color: "#666", background: "#eee", padding: "2px 8px", borderRadius: 6 }}>Budget: {fmt.format(cat.monthlyBudget)}</span>
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <button className="secondary-button" style={{ fontSize: 11, padding: "6px 10px" }} onClick={() => onOpenAddSub(cat.id)}><FolderPlus size={13} /> Add subcategory</button>
                      {!cat.isPermanent && <button className="delete-button" onClick={() => onDeleteCategory(cat.id)} aria-label={`Delete ${cat.name}`}><Trash2 size={13} /></button>}
                    </div>
                  </div>
                  {subs.length > 0 && (
                    <div style={{ marginTop: 10, paddingLeft: 20, display: "grid", gap: 6, borderLeft: "2px solid #e3dec9" }}>
                      {subs.map((sub) => (
                        <div key={sub.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 13, color: "#555" }}>
                          <span className="category-picker-label"><CategoryIcon icon={sub.icon} size={14} /> {sub.name}</span>
                          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                            <b>{fmt.format(subcategorySpent[sub.id] ?? 0)}</b>
                            <button className="delete-button" onClick={() => onDeleteCategory(sub.id)}><Trash2 size={12} /></button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div></div>}
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("income")} aria-expanded={openSection === "income"}>
            <span className="category-symbol"><ArrowUpRight size={17} /></span><span><span className="page-kicker">Income taxonomy</span><strong>Income sources ({incomeList.length})</strong><small>Keep income sources simple, named, and easy to reuse.</small></span><ChevronRight className={openSection === "income" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "income" && <div className="settings-accordion-content"><div className="section-head" style={{ marginBottom: 16 }}><p className="category-section-note">Add a source once, then reuse it on every income entry.</p><button className="add-button" onClick={onOpenAddIncomeCategory}><Plus size={15} /><span>Add income category</span></button></div><div className="category-edit-list" style={{ display: "grid", gap: 10 }}>
            {incomeList.map((inc) => (
              <div key={inc.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 16px", background: "#fcfaf6", border: "1px solid #ded8ca", borderRadius: 12 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="category-symbol" style={{ color: inc.color }}><CategoryIcon icon={inc.icon} size={17} /></span>
                  <strong style={{ fontSize: 15 }}>{inc.name}</strong>
                </div>
                <button className="delete-button" onClick={() => onDeleteCategory(inc.id)}><Trash2 size={13} /></button>
              </div>
            ))}
          </div></div>}
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <button type="button" className="settings-accordion-trigger" onClick={() => toggleSection("export")} aria-expanded={openSection === "export"}>
            <span className="category-symbol"><Download size={17} /></span><span><span className="page-kicker">Data & records</span><strong>Export ledger files</strong><small>Filter your ledger, then download a CSV or an A4 PDF.</small></span><ChevronRight className={openSection === "export" ? "is-open" : ""} size={19} aria-hidden="true" />
          </button>
          {openSection === "export" && <div className="settings-accordion-content export-settings-content"><p className="category-section-note">Open the report workspace to select a date range, account, category, and movement type before exporting the relevant ledger evidence.</p><button className="primary-button" onClick={onOpenReports}><FileText size={15} /> Open Reports & Export</button></div>}
        </article>
      </div>
    </>
  );
}

function RetainedDataView({ routines, attendance, goals, trips, loans, onBack, onOpenOverviewHistory }: { routines: WorkRoutine[]; attendance: RoutineAttendance[]; goals: Goal[]; trips: Trip[]; loans: Loan[]; onBack: () => void; onOpenOverviewHistory: () => void }) {
  const twoYearsAgo = new Date();
  twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
  const retainedAttendance = attendance.filter((item) => new Date(item.date) >= twoYearsAgo);
  const completedGoals = goals.filter((goal) => !planningIsActive(goal) && isWithinTwoYearRetention(goal.completedAt));
  const completedTrips = trips.filter((trip) => !planningIsActive(trip) && isWithinTwoYearRetention(trip.completedAt));
  const completedLoans = loans.filter((loan) => !planningIsActive(loan) && isWithinTwoYearRetention(loan.completedAt));
  const archiveRoutines = routines.filter((routine) => retainedAttendance.some((item) => item.routineId === routine.id));
  const [selectedRoutineId, setSelectedRoutineId] = useState<string | null>(archiveRoutines[0]?.id ?? null);
  const selectedRoutine = archiveRoutines.find((routine) => routine.id === selectedRoutineId) ?? archiveRoutines[0] ?? null;
  const availableMonths = selectedRoutine ? Array.from(new Set(retainedAttendance.filter((item) => item.routineId === selectedRoutine.id).map((item) => item.date.slice(0, 7)))).sort((a, b) => b.localeCompare(a)) : [];
  const [selectedMonth, setSelectedMonth] = useState<string | null>(availableMonths[0] ?? null);
  const activeMonth = availableMonths.includes(selectedMonth ?? "") ? selectedMonth : availableMonths[0] ?? null;
  const [year, monthIndex] = (activeMonth ?? new Date().toISOString().slice(0, 7)).split("-").map(Number);
  const archiveCalendar = selectedRoutine ? routineCalendarDays(year, monthIndex - 1, selectedRoutine.daysPerWeek) : [];
  const archiveMonthEntries = retainedAttendance.filter((item) => item.routineId === selectedRoutine?.id && item.date.startsWith(activeMonth ?? ""));
  const archiveAttendedDates = new Set(archiveMonthEntries.filter((item) => item.attended).map((item) => item.date));
  const archiveExpectedDays = selectedRoutine ? expectedRoutineDaysInMonth(year, monthIndex - 1, selectedRoutine.daysPerWeek) : [];
  const archiveExpectedAttended = archiveExpectedDays.filter((date) => archiveAttendedDates.has(date)).length;
  const selectRoutine = (routineId: string) => {
    const firstMonth = Array.from(new Set(retainedAttendance.filter((item) => item.routineId === routineId).map((item) => item.date.slice(0, 7)))).sort((a, b) => b.localeCompare(a))[0] ?? null;
    setSelectedRoutineId(routineId);
    setSelectedMonth(firstMonth);
  };
  return <><header className="page-header"><div><div className="back-line"><button className="back-control" onClick={onBack}><ArrowLeft size={14} /> Back to Settings</button></div><div className="page-kicker">Data history</div><h1>Two years, kept in reach.</h1><p className="page-subtitle">Your rolling routine view stays focused on twelve months. This archive keeps the retained planning and attendance record accessible for two years.</p></div></header><section className="paper-card section-card"><div className="section-head"><div><div className="page-kicker">Retention summary</div><h2>Stored planning history</h2></div><button className="secondary-button" onClick={onOpenOverviewHistory}>Open full ledger History</button></div><div className="routine-summary"><div><span>Completed goals</span><strong>{completedGoals.length}</strong></div><div><span>Completed plans</span><strong>{completedTrips.length}</strong></div><div><span>Completed loans</span><strong>{completedLoans.length}</strong></div></div><div className="field-note"><div className="field-note-row"><span>Routine records retained</span><b>{retainedAttendance.length}</b></div><div className="field-note-row"><span>Active routines</span><b>{routines.filter((routine) => routine.status !== "archived").length}</b></div></div></section><section className="paper-card section-card routine-archive"><div className="section-head"><div><div className="page-kicker">Work & routine log</div><h2>Routine calendar archive</h2></div><span className="month-hand-date">Last 24 months</span></div><p className="category-section-note">Choose a routine, then a month. The calendar keeps each month readable instead of repeating every day as a long list.</p>{archiveRoutines.length ? <><div className="routine-archive-list" aria-label="Choose a routine archive">{archiveRoutines.map((routine) => { const routineMonths = new Set(retainedAttendance.filter((item) => item.routineId === routine.id).map((item) => item.date.slice(0, 7))); const routineEntries = retainedAttendance.filter((item) => item.routineId === routine.id); return <button type="button" key={routine.id} className={`routine-archive-card ${selectedRoutine?.id === routine.id ? "selected" : ""}`} onClick={() => selectRoutine(routine.id)}><span className="routine-archive-card-icon" style={{ color: routine.color }}><ClipboardCheck size={18} /></span><span><b>{routine.name}</b><small>{routineMonths.size} recorded month{routineMonths.size === 1 ? "" : "s"} · {routineEntries.filter((item) => item.attended).length} attended day{routineEntries.filter((item) => item.attended).length === 1 ? "" : "s"}</small></span><span className="routine-archive-card-meta">{routine.status === "archived" ? "Ended" : "Active"}<ChevronRight size={16} /></span></button>; })}</div>{selectedRoutine && activeMonth && <div className="routine-archive-detail"><div className="routine-archive-months" aria-label={`Choose a month for ${selectedRoutine.name}`}>{availableMonths.map((item) => <button type="button" key={item} className={item === activeMonth ? "selected" : ""} onClick={() => setSelectedMonth(item)}>{monthLabel(item)}</button>)}</div><section className="routine-calendar-sheet archive-calendar-sheet"><div className="routine-calendar-head"><div><span className="draft-kicker">{selectedRoutine.name}</span><h3>{monthLabel(activeMonth)}</h3></div><span className="archive-month-status">{selectedRoutine.status === "archived" ? "Ended routine" : "Routine record"}</span></div><div className="routine-summary"><div><span>Attended</span><strong>{archiveAttendedDates.size}</strong></div><div><span>Expected</span><strong>{archiveExpectedDays.length}</strong></div><div><span>On schedule</span><strong>{archiveExpectedAttended}/{archiveExpectedDays.length}</strong></div></div><div className="routine-weekdays">{["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((day) => <span key={day}>{day}</span>)}</div><div className="routine-calendar-grid archive-calendar-grid">{archiveCalendar.map((day) => <div key={day.date} className={`routine-calendar-day static ${day.expected ? "expected" : ""} ${archiveAttendedDates.has(day.date) ? "attended" : ""} ${!day.inCurrentMonth ? "outside" : ""}`}><span>{day.dayOfMonth}</span>{day.expected && <i aria-label="Expected workday" />}</div>)}</div><p className="routine-calendar-note"><i /> Gold dates were recorded as attended. Expected days remain marked so you can understand the month at a glance.</p></section></div>}</> : <p className="empty-hint">No routine attendance has been recorded in the retained period.</p>}</section></>;
}

type SettingsWorkspaceMode = "expenses" | "income" | "currency" | "reminders";

function SettingsView({ categories, reminderSettings, onOpenWorkspace, onOpenReports, onOpenAccounts, onOpenHistory }: {
  categories: Category[];
  reminderSettings: ReminderSettings;
  onOpenWorkspace: (workspace: `settings-${SettingsWorkspaceMode}`) => void;
  onOpenReports: () => void;
  onOpenAccounts: () => void;
  onOpenHistory: () => void;
}) {
  const expenseCount = categories.filter((category) => category.type === "expense" && !category.parentId).length;
  const incomeCount = categories.filter((category) => category.type === "income").length;
  const currency = CURRENCY_OPTIONS.find((option) => option.code === reminderSettings.currency);

  return <>
    <header className="page-header"><div><div className="page-kicker">Preferences & taxonomy</div><h1>Settings.</h1><p className="page-subtitle">Open one workspace at a time to organise your ledger without losing focus.</p></div></header>
    <section className="settings-destination-grid">
      <button className="paper-card settings-destination reminder" onClick={() => onOpenWorkspace("settings-reminders")}><span className="settings-destination-mark"><Bell size={18} /></span><span className="settings-destination-copy"><span className="settings-destination-topline"><span className="page-kicker">Daily ledger reminder</span><span className={`settings-status-chip ${reminderSettings.enabled ? "is-active" : ""}`}>{reminderSettings.enabled ? "Set" : "Not set"}</span></span><strong>Close the day with a complete ledger.</strong><small>{reminderSettings.enabled ? `Daily check-in at ${formatReminderTime(reminderSettings.time)}` : "Choose a time when you are ready."}</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={() => onOpenWorkspace("settings-currency")}><span className="settings-destination-mark"><CircleDollarSign size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Ledger currency</span><strong>{currency?.label ?? reminderSettings.currency}</strong><small>Display one clear currency across your ledger, insights, and exports.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={onOpenAccounts}><span className="settings-destination-mark"><HandCoins size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Accounts</span><strong>Accounts & assets</strong><small>Review balances, liabilities, and account registers.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={() => onOpenWorkspace("settings-expenses")}><span className="settings-destination-mark"><Wallet size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Money taxonomy</span><strong>Expense categories <em>({expenseCount})</em></strong><small>Permanent spending types and their detailed subcategories.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={() => onOpenWorkspace("settings-income")}><span className="settings-destination-mark"><ArrowUpRight size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Income taxonomy</span><strong>Income sources <em>({incomeCount})</em></strong><small>Reusable sources for every income entry.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={onOpenReports}><span className="settings-destination-mark"><Download size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Data & records</span><strong>Export ledger files</strong><small>Filter records, then download CSV or A4 PDF evidence.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
      <button className="paper-card settings-destination" onClick={onOpenHistory}><span className="settings-destination-mark"><Calendar size={18} /></span><span className="settings-destination-copy"><span className="page-kicker">Data history</span><strong>Two-year retained archive</strong><small>Review completed planning records and retained routine attendance.</small></span><ChevronRight className="settings-destination-arrow" size={20} /></button>
    </section>
  </>;
}

function CurrencyDirectory({ value, disabled, onChange }: { value: SupportedCurrency; disabled: boolean; onChange: (currency: SupportedCurrency) => void }) {
  const [query, setQuery] = useState("");
  const selected = CURRENCY_OPTIONS.find((currency) => currency.code === value) ?? CURRENCY_OPTIONS[0];
  const normalizedQuery = query.trim().toLocaleLowerCase();
  const choices = CURRENCY_OPTIONS.filter((currency) => `${currency.code} ${currency.name} ${currency.symbol}`.toLocaleLowerCase().includes(normalizedQuery));
  return <div className="currency-directory">
    <div className="currency-directory-current"><span className="currency-flag" aria-hidden="true">{selected.flag}</span><div><span>Currently displaying</span><strong>{selected.code} · {selected.name}</strong><small>{selected.symbol} is used across your ledger, insights, and exports.</small></div></div>
    <label className="currency-search"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search currency or country" aria-label="Search currencies" /><span>{choices.length} available</span></label>
    <div className="currency-directory-list" role="list" aria-label="Choose display currency">
      {choices.map((currency) => <button key={currency.code} type="button" role="listitem" className={currency.code === value ? "selected" : ""} disabled={disabled} onClick={() => onChange(currency.code)}><span className="currency-flag" aria-hidden="true">{currency.flag}</span><span className="currency-directory-copy"><b>{currency.code}</b><small>{currency.name}</small></span><em>{currency.symbol}</em>{currency.code === value && <CheckCircle2 size={17} aria-label="Selected" />}</button>)}
    </div>
    {!choices.length && <div className="currency-directory-empty"><Search size={18} /><strong>No match found</strong><span>Try a code such as BDT or USD, a country, or a currency name.</span></div>}
  </div>;
}

function SettingsWorkspaceView({ mode, categories, subcategorySpent, reminderSettings, reminderPushStatus, reminderPushBusy, signedIn, onBack, onOpenAddIncomeCategory, onOpenAddSub, onDeleteCategory, onSaveReminderSettings, onEnableDeviceReminder }: {
  mode: SettingsWorkspaceMode;
  categories: Category[];
  subcategorySpent: Record<string, number>;
  reminderSettings: ReminderSettings;
  reminderPushStatus: string | null;
  reminderPushBusy: boolean;
  signedIn: boolean;
  onBack: () => void;
  onOpenAddIncomeCategory: () => void;
  onOpenAddSub: (parentId: string) => void;
  onDeleteCategory: (id: string) => void;
  onSaveReminderSettings: (settings: ReminderSettings) => void;
  onEnableDeviceReminder: () => void;
}) {
  const expenseParents = categories.filter((category) => category.type === "expense" && !category.parentId);
  const incomeList = categories.filter((category) => category.type === "income");
  const deviceTimezone = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  const timezoneChoices = Array.from(new Set([deviceTimezone, "Asia/Dhaka", "Asia/Kolkata", "Asia/Singapore", "Europe/London", "America/New_York", "UTC"]));
  const [openPicker, setOpenPicker] = useState<"time" | "timezone" | null>(null);
  const [draftReminderTime, setDraftReminderTime] = useState(reminderSettings.time);
  const copy: Record<SettingsWorkspaceMode, { kicker: string; title: string; description: string }> = {
    expenses: { kicker: "Money taxonomy", title: "Expense categories", description: "Permanent spending types with detailed subcategories beneath each one." },
    income: { kicker: "Income taxonomy", title: "Income sources", description: "Name every income source once, then reuse it whenever you add money in." },
    currency: { kicker: "Ledger preference", title: "Ledger currency", description: "Choose one display currency across your ledger, insights, and exports." },
    reminders: { kicker: "Reminder preference", title: "Daily ledger reminder", description: "Set one calm end-of-day cue to record what happened today." },
  };
  const meta = copy[mode];
  const draftTimeParts = reminderTimeParts(draftReminderTime);
  const minuteChoices = Array.from(new Set(["00", "15", "30", "45", draftTimeParts.minute])).sort((left, right) => Number(left) - Number(right));
  const openTimePicker = () => {
    setDraftReminderTime(reminderSettings.time);
    setOpenPicker("time");
  };
  const selectTimezoneChoice = (choice: string) => {
    if (openPicker === "timezone") {
      onSaveReminderSettings({ ...reminderSettings, timezone: choice });
    }
    setOpenPicker(null);
  };
  const confirmReminderTime = () => {
    onSaveReminderSettings({ ...reminderSettings, time: draftReminderTime });
    setOpenPicker(null);
  };

  return <>
    <header className="workspace-page-header"><button className="workspace-back-button" onClick={onBack}><ArrowLeft size={15} /> Back to Settings</button><div><div className="page-kicker">{meta.kicker}</div><h1>{meta.title}</h1><p className="page-subtitle">{meta.description}</p></div></header>
    <section className={`paper-card workspace-sheet settings-workspace ${mode}`}>
      {mode === "expenses" && <><p className="category-section-note">Add detailed subcategories beneath the permanent spending types. Category budgets always remain with the parent.</p><div className="category-groups">{expenseParents.map((parent) => { const children = categories.filter((category) => category.parentId === parent.id); return <article className="category-group" key={parent.id}><div className="category-group-head"><span className="category-symbol" style={{ color: parent.color }}><CategoryIcon icon={parent.icon} size={18} /></span><div><strong>{parent.name}</strong><small><span className="permanent-category-marker">Permanent type</span></small></div><em>Budget: {fmt.format(parent.monthlyBudget ?? 0)}</em></div><button className="category-add-sub" onClick={() => onOpenAddSub(parent.id)}><FolderPlus size={14} /> Add subcategory</button><div className="subcategory-list">{children.map((child) => <div className="subcategory-row" key={child.id}><span><CategoryIcon icon={child.icon} size={14} /> {child.name}</span><strong>{fmt.format(subcategorySpent[child.id] ?? 0)}</strong><button className="delete-button" onClick={() => onDeleteCategory(child.id)} aria-label={`Delete ${child.name}`}><Trash2 size={13} /></button></div>)}</div></article>; })}</div></>}
      {mode === "income" && <><div className="workspace-action-row"><p className="category-section-note">Add a source once, then reuse it on every income entry. Income stays flat and focused.</p><button className="add-button" onClick={onOpenAddIncomeCategory}><Plus size={15} /> Add income category</button></div><div className="income-workspace-list">{incomeList.map((income) => <article className="income-workspace-row" key={income.id}><span className="category-symbol" style={{ color: income.color }}><CategoryIcon icon={income.icon} size={18} /></span><strong>{income.name}</strong><button className="delete-button" onClick={() => onDeleteCategory(income.id)} aria-label={`Delete ${income.name}`}><Trash2 size={14} /></button></article>)}</div></>}
      {mode === "currency" && <><div className="currency-choice-summary"><span>Display currency</span><strong>{reminderSettings.currency}</strong><p>This changes labels only; it does not convert amounts that were already recorded.</p></div><CurrencyDirectory value={reminderSettings.currency} disabled={!signedIn} onChange={(currency) => onSaveReminderSettings({ ...reminderSettings, currency })} />{!signedIn && <p className="reminder-settings-note">Sign in to save your display preference.</p>}</>}
      {mode === "reminders" && <>
        <div className="workspace-reminder-head">
          <div><span className={`settings-status-chip ${reminderSettings.enabled ? "is-active" : ""}`}>{reminderSettings.enabled ? "Configured" : "Not set"}</span><h2>Close the day with a complete ledger.</h2><p>Choose a daily moment for a discreet reminder that keeps your personal record complete.</p></div>
          <button type="button" className={`reminder-toggle ${reminderSettings.enabled ? "is-enabled" : ""}`} onClick={() => reminderSettings.enabled ? onSaveReminderSettings({ ...reminderSettings, enabled: false }) : onEnableDeviceReminder()} disabled={!signedIn || reminderPushBusy} aria-pressed={reminderSettings.enabled}><span aria-hidden="true" />{reminderSettings.enabled ? "Daily reminder on" : reminderPushBusy ? "Connecting device…" : "Enable daily reminder"}</button>
        </div>
        <div className="workspace-picker-grid">
          <button className="workspace-picker-trigger" disabled={!signedIn} onClick={openTimePicker}><span><small>Daily check-in time</small><strong>{formatReminderTime(reminderSettings.time)}</strong><em>Tap to choose the exact time.</em></span><ChevronRight size={18} /></button>
          <button className="workspace-picker-trigger" disabled={!signedIn} onClick={() => setOpenPicker("timezone")}><span><small>Reminder location</small><strong>{reminderSettings.timezone === deviceTimezone ? `${reminderSettings.timezone} · this device` : reminderSettings.timezone}</strong><em>Your selected time follows this location’s local clock.</em></span><ChevronRight size={18} /></button>
        </div>
        {!signedIn && <p className="reminder-settings-note">Sign in to save a reminder that follows your personal ledger.</p>}
        {signedIn && !reminderSettings.enabled && <p className="reminder-settings-note">Enable this once to allow a browser or device notification at your selected time.</p>}
        {reminderPushStatus && <p className="reminder-settings-status" role="status">{reminderPushStatus}</p>}
        {openPicker && <div className="ledger-calendar-backdrop workspace-picker-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setOpenPicker(null); }}>
          <section className={`workspace-choice-sheet ${openPicker === "time" ? "time-picker-sheet" : ""}`} role="dialog" aria-modal="true" aria-label="Choose reminder preference">
            <div className="workspace-choice-head"><div><span className="draft-kicker">{openPicker === "time" ? "Daily check-in time" : "Reminder location"}</span><h3>{openPicker === "time" ? "Choose a moment" : "Choose local time"}</h3></div><button className="close-button" onClick={() => setOpenPicker(null)} aria-label="Close"><X size={16} /></button></div>
            {openPicker === "time" ? <>
              <div className="time-picker-summary" aria-live="polite"><span>Selected check-in</span><strong>{formatReminderTime(draftReminderTime)}</strong><p>Your saved reminder will not change until you confirm.</p></div>
              <div className="time-picker-columns">
                <fieldset className="time-picker-fieldset"><legend>Hour</legend><div className="time-picker-hour-grid">{Array.from({ length: 12 }, (_, index) => index + 1).map((hour) => <button key={hour} type="button" className={hour === draftTimeParts.hour ? "selected" : ""} aria-pressed={hour === draftTimeParts.hour} onClick={() => setDraftReminderTime(reminderTimeFromParts(hour, draftTimeParts.minute, draftTimeParts.meridiem))}>{hour}</button>)}</div></fieldset>
                <fieldset className="time-picker-fieldset"><legend>Minutes</legend><div className="time-picker-minute-grid">{minuteChoices.map((minute) => <button key={minute} type="button" className={minute === draftTimeParts.minute ? "selected" : ""} aria-pressed={minute === draftTimeParts.minute} onClick={() => setDraftReminderTime(reminderTimeFromParts(draftTimeParts.hour, minute, draftTimeParts.meridiem))}>:{minute}</button>)}</div><div className="time-picker-period-grid">{(["AM", "PM"] as const).map((meridiem) => <button key={meridiem} type="button" className={meridiem === draftTimeParts.meridiem ? "selected" : ""} aria-pressed={meridiem === draftTimeParts.meridiem} onClick={() => setDraftReminderTime(reminderTimeFromParts(draftTimeParts.hour, draftTimeParts.minute, meridiem))}>{meridiem}</button>)}</div></fieldset>
              </div>
              <div className="workspace-choice-actions"><button type="button" className="picker-cancel-button" onClick={() => setOpenPicker(null)}>Cancel</button><button type="button" className="picker-confirm-button" onClick={confirmReminderTime}>Save {formatReminderTime(draftReminderTime)}</button></div>
            </> : <div className="workspace-choice-list">{timezoneChoices.map((choice) => { const selected = choice === reminderSettings.timezone; const label = choice === deviceTimezone ? `${choice} · this device` : choice; return <button key={choice} className={selected ? "selected" : ""} onClick={() => selectTimezoneChoice(choice)}><span>{label}</span>{selected && <CheckCircle2 size={15} />}</button>; })}</div>}
          </section>
        </div>}
      </>}
    </section>
  </>;
}

function accountBalance(acc: Account) {
  return acc.balance;
}

function LedgerDateField({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  const normalisedValue = value ? normaliseCalendarDate(value, new Date()) : "";
  const initial = normalisedValue ? new Date(`${normalisedValue}T12:00:00`) : new Date();
  const [isOpen, setIsOpen] = useState(false);
  const [yearPickerOpen, setYearPickerOpen] = useState(false);
  const [cursor, setCursor] = useState(() => new Date(initial.getFullYear(), initial.getMonth(), 1));
  const selected = normalisedValue ? new Date(`${normalisedValue}T12:00:00`) : null;
  const monthStart = new Date(cursor.getFullYear(), cursor.getMonth(), 1);
  const gridStart = new Date(cursor.getFullYear(), cursor.getMonth(), 1 - monthStart.getDay());
  const days = Array.from({ length: 42 }, (_, index) => new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + index));
  const labelDate = selected ? selected.toLocaleDateString("en-US", { weekday: "short", day: "numeric", month: "short", year: "numeric" }) : "Choose date";
  const isSameDay = (left: Date, right: Date | null) => Boolean(right && left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate());
  const yearChoices = calendarYearChoices(cursor.getFullYear());

  return (
    <div className="form-field ledger-date-field">
      <label>{label}</label>
      <button type="button" className="ledger-date-trigger" onClick={() => { setCursor(new Date(initial.getFullYear(), initial.getMonth(), 1)); setYearPickerOpen(false); setIsOpen(true); }}>
        <span><Calendar size={16} /> {labelDate}</span><ChevronRight size={16} />
      </button>
      {isOpen && <div className="ledger-calendar-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) { setYearPickerOpen(false); setIsOpen(false); } }}>
        <section className="ledger-calendar" role="dialog" aria-modal="true" aria-label={`Choose ${label.toLowerCase()}`}>
          <div className="ledger-calendar-top">
            <button type="button" className="calendar-nav-button" aria-label="Previous month" onClick={() => setCursor((current) => new Date(current.getFullYear(), current.getMonth() - 1, 1))}><ChevronLeft size={16} /></button>
            <div className="calendar-heading">
              <span className="draft-kicker">Choose {label.toLowerCase()}</span>
              <button type="button" className="calendar-year-trigger" onClick={() => setYearPickerOpen((open) => !open)} aria-expanded={yearPickerOpen} aria-label="Choose year">{cursor.toLocaleDateString("en-US", { month: "long", year: "numeric" })}</button>
            </div>
            <button type="button" className="calendar-nav-button" aria-label="Next month" onClick={() => setCursor((current) => new Date(current.getFullYear(), current.getMonth() + 1, 1))}><ChevronRight size={16} /></button>
          </div>
          {yearPickerOpen ? <div className="calendar-year-picker" aria-label="Choose year"><div className="calendar-year-picker-head"><button type="button" className="calendar-nav-button" aria-label="Earlier years" onClick={() => setCursor((current) => new Date(current.getFullYear() - yearChoices.length, current.getMonth(), 1))}><ChevronLeft size={16} /></button><span>Choose a year</span><button type="button" className="calendar-nav-button" aria-label="Later years" onClick={() => setCursor((current) => new Date(current.getFullYear() + yearChoices.length, current.getMonth(), 1))}><ChevronRight size={16} /></button></div><div className="calendar-year-grid">{yearChoices.map((year) => <button key={year} type="button" className={year === cursor.getFullYear() ? "selected" : ""} onClick={() => { setCursor((current) => new Date(year, current.getMonth(), 1)); setYearPickerOpen(false); }}>{year}</button>)}</div></div> : <><div className="ledger-calendar-weekdays">{["S", "M", "T", "W", "T", "F", "S"].map((day, index) => <span key={`${day}-${index}`}>{day}</span>)}</div><div className="ledger-calendar-grid">{days.map((day) => <button type="button" key={dateInputValue(day)} className={`ledger-calendar-day ${day.getMonth() !== cursor.getMonth() ? "outside" : ""} ${isSameDay(day, selected) ? "selected" : ""}`} onClick={() => { onChange(dateInputValue(day)); setYearPickerOpen(false); setIsOpen(false); }}>{day.getDate()}</button>)}</div></>}
          <div className="ledger-calendar-actions"><button type="button" className="text-link" onClick={() => { onChange(dateInputValue(new Date())); setYearPickerOpen(false); setIsOpen(false); }}>Today</button><button type="button" className="secondary-button" onClick={() => { setYearPickerOpen(false); setIsOpen(false); }}>Close</button></div>
        </section>
      </div>}
    </div>
  );
}

function DraftPanel({ kind, title, amount, dateVal, transaction, accounts, categories, goals, trips, editingGoalId, editingTripId, editingLoanId, editingScheduleId, catName, catBudget, catType, catIcon, parentTarget, subName, subIcon, accName, accKind, accBalance, accNumber, loanDirection, loanCounterparty, loanTerms, loanAccount, goalFinancing, scheduleType, scheduleFrequency, scheduleAccount, scheduleCategory, onTitle, onAmount, onDate, onTransaction, onUploadEvidence, onViewEvidence, onCatName, onCatBudget, onCatType, onCatIcon, onParentTarget, onSubName, onSubIcon, onAccName, onAccKind, onAccBalance, onAccNumber, onLoanDirection, onLoanCounterparty, onLoanTerms, onLoanAccount, onGoalFinancing, onScheduleType, onScheduleFrequency, onScheduleAccount, onScheduleCategory, onClose, onSave, onOpenAddSub, onOpenAddIncomeCategory }: {
  kind: Exclude<DraftKind, null | "profile">; title: string; amount: string; dateVal: string; transaction: TransactionDraft; accounts: Account[]; categories: Category[]; goals: Goal[]; trips: Trip[]; editingGoalId: string | null; editingTripId: string | null; editingLoanId: string | null; editingScheduleId: string | null; catName: string; catBudget: string; catType: "expense" | "income"; catIcon: string; parentTarget: string; subName: string; subIcon: string; accName: string; accKind: "asset" | "liability"; accBalance: string; accNumber: string; loanDirection: Loan["direction"]; loanCounterparty: string; loanTerms: string; loanAccount: string; goalFinancing: string; scheduleType: RecurringSchedule["type"]; scheduleFrequency: ScheduleFrequency; scheduleAccount: string; scheduleCategory: string;
  onTitle: (value: string) => void; onAmount: (value: string) => void; onDate: (value: string) => void; onTransaction: (value: TransactionDraft | ((current: TransactionDraft) => TransactionDraft)) => void; onUploadEvidence: (file: File) => Promise<TransactionAttachment>; onViewEvidence: (attachment: TransactionAttachment) => Promise<void>; onCatName: (value: string) => void; onCatBudget: (value: string) => void; onCatType: (value: "expense" | "income") => void; onCatIcon: (value: string) => void; onParentTarget: (value: string) => void; onSubName: (value: string) => void; onSubIcon: (value: string) => void; onAccName: (value: string) => void; onAccKind: (value: "asset" | "liability") => void; onAccBalance: (value: string) => void; onAccNumber: (value: string) => void; onLoanDirection: (value: Loan["direction"]) => void; onLoanCounterparty: (value: string) => void; onLoanTerms: (value: string) => void; onLoanAccount: (value: string) => void; onGoalFinancing: (value: string) => void; onScheduleType: (value: RecurringSchedule["type"]) => void; onScheduleFrequency: (value: ScheduleFrequency) => void; onScheduleAccount: (value: string) => void; onScheduleCategory: (value: string) => void; onClose: () => void; onSave: () => void; onOpenAddSub: (parentId: string) => void; onOpenAddIncomeCategory: () => void;
}) {
  const heading = kind === "transaction" ? (transaction.id ? "Edit transaction" : "Draft a transaction") : kind === "goal" ? (editingGoalId ? "Edit savings goal" : "Set a new savings goal") : kind === "trip" ? (editingTripId ? "Edit trip or event plan" : "Plan a trip or event") : kind === "loan" ? (editingLoanId ? "Edit debt or loan" : "Add debt or loan") : kind === "schedule" ? (editingScheduleId ? "Edit recurring schedule" : "Add recurring schedule") : kind === "category" ? (catType === "expense" ? "Add expense category" : "Add income category") : kind === "subcategory" ? "Add subcategory" : "Add bank account or asset";
  const descriptor = kind === "transaction" ? "Record, recategorise, or correct a money movement." : kind === "goal" ? "Give future money a purpose with a clear target." : kind === "trip" ? "Set a budget ceiling before you travel." : kind === "loan" ? "Track what you owe or what is owed to you." : kind === "schedule" ? "Keep regular income and bills visible before their next due date." : kind === "category" ? "Organise your spending or income streams." : kind === "subcategory" ? "Add precise granularity under an expense category." : "Register an asset, bank, or credit liability.";
  const update = (patch: Partial<TransactionDraft>) => onTransaction((current) => ({ ...current, ...patch }));
  const [evidenceNotice, setEvidenceNotice] = useState<string | null>(null);
  const [evidenceUploading, setEvidenceUploading] = useState(false);
  const addEvidence = async (file?: File) => {
    if (!file) return;
    setEvidenceUploading(true);
    setEvidenceNotice(null);
    try {
      const attachment = await onUploadEvidence(file);
      onTransaction((current) => ({ ...current, attachments: [...current.attachments, attachment] }));
    } catch (error) {
      setEvidenceNotice(error instanceof Error ? error.message : "The attachment could not be stored.");
    } finally {
      setEvidenceUploading(false);
    }
  };

  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeList = categories.filter((c) => c.type === "income");
  const scheduleCategories = categories.filter((category) => category.type === scheduleType);
  const categoryPath = (category: Category) => category.parentId ? `${categories.find((parent) => parent.id === category.parentId)?.name ?? "Expense"} → ${category.name}` : category.name;

  const currentCategory = categories.find((category) => category.id === transaction.categoryId);
  const initialParentId = currentCategory?.parentId ?? (currentCategory?.type === "expense" ? currentCategory.id : expenseTop[0]?.id ?? "");
  const [selectedParentId, setSelectedParentId] = useState<string>(initialParentId);
  const [expenseCategoryPickerOpen, setExpenseCategoryPickerOpen] = useState(false);
  const [subcategoryPickerOpen, setSubcategoryPickerOpen] = useState(false);
  const selectedParent = expenseTop.find((category) => category.id === selectedParentId) ?? expenseTop[0];
  const selectedSubcategories = selectedParent ? categories.filter((category) => category.parentId === selectedParent.id) : [];
  const selectedSubcategory = currentCategory?.parentId === selectedParent?.id ? currentCategory : null;
  const scheduleTopCategories = scheduleCategories.filter((category) => !category.parentId);
  const initialScheduleParentId = scheduleType === "expense" ? (categories.find((category) => category.id === scheduleCategory)?.parentId ?? scheduleCategory) : "";
  const [scheduleParentId, setScheduleParentId] = useState(initialScheduleParentId);
  const [scheduleParentPickerOpen, setScheduleParentPickerOpen] = useState(false);
  const [scheduleSubcategoryPickerOpen, setScheduleSubcategoryPickerOpen] = useState(false);
  const scheduleParent = scheduleTopCategories.find((category) => category.id === scheduleParentId) ?? scheduleTopCategories[0];
  const scheduleSubcategories = scheduleParent ? scheduleCategories.filter((category) => category.parentId === scheduleParent.id) : [];
  const scheduleSelectedCategory = scheduleCategories.find((category) => category.id === scheduleCategory);
  const scheduleSelectedSubcategory = scheduleSelectedCategory?.parentId === scheduleParent?.id ? scheduleSelectedCategory : null;

  return (
    <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={heading} onMouseDown={onClose}>
      <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
        <div className="draft-top"><div><div className="draft-kicker">{descriptor}</div><h2>{heading}</h2></div><button className="close-button" onClick={onClose} aria-label="Close"><X size={17} /></button></div>
        
        {kind === "transaction" && <>
          <div className="form-field"><label>Movement</label><div className="type-options">{(["expense", "income", "transfer"] as const).map((type) => <button key={type} className={`type-option ${transaction.type === type ? "active" : ""}`} onClick={() => { if (type === "expense") { const parentId = expenseTop[0]?.id ?? ""; setSelectedParentId(parentId); setExpenseCategoryPickerOpen(false); setSubcategoryPickerOpen(false); update({ type, categoryId: parentId }); } else { update({ type, categoryId: type === "income" ? (incomeList[0]?.id ?? "") : transaction.categoryId }); } }}>{type[0].toUpperCase() + type.slice(1)}</button>)}</div></div>
          <div className="form-field"><label>Merchant or note</label><input value={transaction.merchantNote} onChange={(event) => update({ merchantNote: event.target.value })} placeholder={transaction.type === "transfer" ? "e.g. Contribution to reserve" : "e.g. Sunday market"} autoFocus /></div>
          <div className="form-field"><label>Amount</label><input value={transaction.amount} onChange={(event) => update({ amount: event.target.value.replace(/[^0-9.]/g, "") })} placeholder="0.00" inputMode="decimal" /></div>
          <div className="form-field"><label>{transaction.type === "transfer" ? "From account" : "Account"}</label><select value={transaction.accountId} onChange={(event) => update({ accountId: event.target.value })}>{accounts.map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>
          {transaction.type === "transfer" && <div className="form-field"><label>To account</label><select value={transaction.destinationAccountId} onChange={(event) => update({ destinationAccountId: event.target.value })}>{accounts.filter((account) => account.id !== transaction.accountId).map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>}
          
          {transaction.type === "expense" && (
            <>
              <div className="form-field">
                <label>Category (Expense)</label>
                <button type="button" className="picker-trigger" onClick={() => setExpenseCategoryPickerOpen(true)}>
                  <span className="category-picker-label">{selectedParent && <CategoryIcon icon={selectedParent.icon} size={16} />} {selectedParent ? selectedParent.name : "Choose a category"}</span><ChevronRight size={16} />
                </button>
              </div>
            </>
          )}

          {expenseCategoryPickerOpen && transaction.type === "expense" && (
            <div className="picker-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setExpenseCategoryPickerOpen(false); }}>
              <section className="picker-sheet" role="dialog" aria-modal="true" aria-label="Choose expense category">
                <div className="picker-sheet-top"><div><div className="draft-kicker">Expense category</div><h3>Choose a category</h3></div><button type="button" className="close-button" onClick={() => setExpenseCategoryPickerOpen(false)} aria-label="Close category picker"><X size={16} /></button></div>
                <div className="picker-sheet-list">
                  {expenseTop.map((top) => <button type="button" className={`picker-row ${selectedParent?.id === top.id ? "active" : ""}`} key={top.id} onClick={() => { setSelectedParentId(top.id); update({ categoryId: top.id }); setExpenseCategoryPickerOpen(false); setSubcategoryPickerOpen(true); }}><span><b className="category-picker-label"><CategoryIcon icon={top.icon} size={16} /> {top.name}</b><small>{categories.filter((category) => category.parentId === top.id).length} subcategories</small></span><ChevronRight size={17} /></button>)}
                </div>
              </section>
            </div>
          )}

          {subcategoryPickerOpen && transaction.type === "expense" && selectedParent && (
            <div className="picker-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setSubcategoryPickerOpen(false); }}>
              <section className="picker-sheet" role="dialog" aria-modal="true" aria-label={`Choose subcategory under ${selectedParent.name}`}>
                <div className="picker-sheet-top"><div><div className="draft-kicker">{selectedParent.name}</div><h3>Choose a subcategory</h3></div><button type="button" className="close-button" onClick={() => setSubcategoryPickerOpen(false)} aria-label="Close subcategory picker"><X size={16} /></button></div>
                <p className="picker-sheet-note">Choose a more precise label, keep the parent category, or create a new subcategory.</p>
                <div className="picker-sheet-list">
                  <button type="button" className={`picker-row ${!selectedSubcategory ? "active" : ""}`} onClick={() => { update({ categoryId: selectedParent.id }); setSubcategoryPickerOpen(false); }}><span><b>Use {selectedParent.name}</b><small>Keep this expense at the top level</small></span>{!selectedSubcategory && <CheckCircle2 size={17} />}</button>
                  {selectedSubcategories.map((sub) => <button type="button" className={`picker-row ${selectedSubcategory?.id === sub.id ? "active" : ""}`} key={sub.id} onClick={() => { update({ categoryId: sub.id }); setSubcategoryPickerOpen(false); }}><span><b className="category-picker-label"><CategoryIcon icon={sub.icon} size={16} /> {sub.name}</b><small>Under {selectedParent.name}</small></span>{selectedSubcategory?.id === sub.id && <CheckCircle2 size={17} />}</button>)}
                  <button type="button" className="picker-create-row" onClick={() => { setSubcategoryPickerOpen(false); onOpenAddSub(selectedParent.id); }}><FolderPlus size={16} /> Create subcategory under {selectedParent.name}</button>
                </div>
              </section>
            </div>
          )}

          {transaction.type === "income" && (
            <div className="form-field">
              <label>Category (Income)</label>
              <select value={transaction.categoryId} onChange={(event) => update({ categoryId: event.target.value })}>
                {incomeList.map((inc) => <option value={inc.id} key={inc.id}>{inc.name}</option>)}
              </select>
              <button type="button" className="text-link income-create-link" onClick={onOpenAddIncomeCategory}><Plus size={13} /> Add income category</button>
            </div>
          )}

          <LedgerDateField label="Date" value={transaction.date} onChange={(value) => update({ date: value })} />
          <div className="tag-grid"><div className="form-field"><label>Payee <em>(optional)</em></label><input value={transaction.payee} onChange={(event) => update({ payee: event.target.value })} placeholder={transaction.type === "income" ? "Who paid you?" : "Who received it?"} /></div><div className="form-field"><label>Payer <em>(optional)</em></label><input value={transaction.payer} onChange={(event) => update({ payer: event.target.value })} placeholder={transaction.type === "income" ? "Who sent it?" : "Who paid?"} /></div></div>
          <div className="form-field"><label>Settlement</label><div className="type-options"><button type="button" className={`type-option ${transaction.settlementStatus === "paid" ? "active" : ""}`} onClick={() => update({ settlementStatus: "paid" })}><CircleCheck size={15} /> Paid</button><button type="button" className={`type-option ${transaction.settlementStatus === "pending" ? "active" : ""}`} onClick={() => update({ settlementStatus: "pending" })}><Clock3 size={15} /> Pending</button></div></div>
          <div className="form-field transaction-evidence"><label>Receipts & proof <em>(optional)</em></label><small>Keep a photo, digital receipt, or document with this entry.</small><div className="evidence-actions"><label className="evidence-action"><Camera size={15} /> Take photo<input type="file" accept="image/jpeg,image/png,image/webp" capture="environment" onChange={(event) => { void addEvidence(event.target.files?.[0]); event.currentTarget.value = ""; }} /></label><label className="evidence-action"><Image size={15} /> Choose image<input type="file" accept="image/jpeg,image/png,image/webp" onChange={(event) => { void addEvidence(event.target.files?.[0]); event.currentTarget.value = ""; }} /></label><label className="evidence-action"><FileText size={15} /> Add document<input type="file" accept="application/pdf" onChange={(event) => { void addEvidence(event.target.files?.[0]); event.currentTarget.value = ""; }} /></label></div>{evidenceUploading && <small className="evidence-progress">Saving attachment…</small>}{evidenceNotice && <small className="evidence-error">{evidenceNotice}</small>}{transaction.attachments.length > 0 && <div className="evidence-list">{transaction.attachments.map((attachment) => <span className="evidence-chip" key={attachment.id}><Paperclip size={13} /><button type="button" className="evidence-view-button" onClick={() => { void onViewEvidence(attachment); }}>{attachment.name}</button><button type="button" aria-label={`Remove ${attachment.name}`} onClick={() => onTransaction((current) => ({ ...current, attachments: current.attachments.filter((item) => item.id !== attachment.id) }))}><X size={13} /></button></span>)}</div>}</div>
          <div className="tag-grid"><div className="form-field"><label>Goal tag</label><select value={transaction.goalId} onChange={(event) => update({ goalId: event.target.value })}><option value="none">No goal</option>{goals.map((goal) => <option value={goal.id} key={goal.id}>{goal.name}</option>)}</select></div><div className="form-field"><label>Trip tag</label><select value={transaction.tripId} onChange={(event) => update({ tripId: event.target.value })}><option value="none">No trip</option>{trips.map((trip) => <option value={trip.id} key={trip.id}>{trip.name}</option>)}</select></div></div>
        </>}

        {kind === "goal" && <>
          <div className="form-field"><label>Goal title</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Home reserve" autoFocus /></div>
          <div className="form-field"><label>Target amount</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="5,000" inputMode="decimal" /></div>
          <div className="form-field"><label>Financing contribution <em>(optional)</em></label><input value={goalFinancing} onChange={(event) => onGoalFinancing(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="e.g. 1,500 from a loan or grant" inputMode="decimal" /><small>This reduces the amount you need to personally save.</small></div>
          <LedgerDateField label="Target timeline" value={dateVal} onChange={onDate} />
        </>}

        {kind === "trip" && <>
          <div className="form-field"><label>Plan name</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Autumn in Lisbon" autoFocus /></div>
          <div className="form-field"><label>Working budget</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="1,200" inputMode="decimal" /></div>
          <LedgerDateField label="Plan date" value={dateVal} onChange={onDate} />
        </>}

        {kind === "loan" && <>
          <div className="form-field"><label>Direction</label><div className="type-options"><button className={`type-option ${loanDirection === "borrowed" ? "active" : ""}`} onClick={() => onLoanDirection("borrowed")}>I borrowed</button><button className={`type-option ${loanDirection === "lent" ? "active" : ""}`} onClick={() => onLoanDirection("lent")}>I lent</button></div></div>
          <div className="form-field"><label>Loan name</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Family bridge loan" autoFocus /></div>
          <div className="form-field"><label>{loanDirection === "borrowed" ? "Lender" : "Borrower"}</label><input value={loanCounterparty} onChange={(event) => onLoanCounterparty(event.target.value)} placeholder={loanDirection === "borrowed" ? "e.g. Morgan" : "e.g. Alex"} /></div>
          <div className="form-field"><label>Original amount</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="2,400" inputMode="decimal" /></div>
          <div className="form-field"><label>{loanDirection === "borrowed" ? "Cash received into" : "Cash advanced from"}</label><select value={loanAccount} onChange={(event) => onLoanAccount(event.target.value)} disabled={!accounts.length}>{accounts.length ? accounts.map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>) : <option value="">Preparing your Main Account…</option>}</select><small>{loanDirection === "borrowed" ? "Saving creates an income cash movement in this account." : "Saving creates an expense cash movement from this account."}</small></div>
          <LedgerDateField label="Due date" value={dateVal} onChange={onDate} />
          <div className="form-field"><label>Repayment terms <em>(optional)</em></label><input value={loanTerms} onChange={(event) => onLoanTerms(event.target.value)} placeholder="e.g. $300 on the 1st of each month" /></div>
        </>}

        {kind === "schedule" && <>
          <div className="form-field"><label>Schedule type</label><div className="type-options"><button className={`type-option ${scheduleType === "expense" ? "active" : ""}`} onClick={() => { const nextParent = categories.find((category) => category.type === "expense" && !category.parentId)?.id ?? ""; onScheduleType("expense"); setScheduleParentId(nextParent); onScheduleCategory(nextParent); }}>Recurring bill</button><button className={`type-option ${scheduleType === "income" ? "active" : ""}`} onClick={() => { onScheduleType("income"); onScheduleCategory(categories.find((category) => category.type === "income")?.id ?? ""); }}>Recurring income</button></div></div>
          <div className="form-field"><label>Schedule name</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder={scheduleType === "income" ? "e.g. Monthly salary" : "e.g. Internet service"} autoFocus /></div>
          <div className="form-field"><label>Expected amount</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="0.00" inputMode="decimal" /></div>
          <div className="form-field"><label>Frequency</label><select value={scheduleFrequency} onChange={(event) => onScheduleFrequency(event.target.value as ScheduleFrequency)}><option value="weekly">Weekly</option><option value="biweekly">Every two weeks</option><option value="monthly">Monthly</option></select></div>
          <div className="form-field"><label>Account</label><select value={scheduleAccount} onChange={(event) => onScheduleAccount(event.target.value)} disabled={!accounts.length}>{accounts.length ? accounts.map((account) => <option key={account.id} value={account.id}>{account.name} · {account.kind}</option>) : <option value="">Preparing your Main Account…</option>}</select>{!accounts.length && <small>Your private ledger is preparing its first account.</small>}</div>
          {scheduleType === "expense" ? <>
            <div className="form-field"><label>Expense category</label><button type="button" className="picker-trigger" onClick={() => setScheduleParentPickerOpen(true)} disabled={!scheduleParent}><span className="category-picker-label">{scheduleParent && <CategoryIcon icon={scheduleParent.icon} size={16} />} {scheduleParent?.name ?? "Choose a category"}</span><ChevronRight size={16} /></button><small>Choose the broad budget group for this bill first.</small></div>
            <div className="form-field"><label>Subcategory <em>(optional)</em></label><button type="button" className="picker-trigger" onClick={() => setScheduleSubcategoryPickerOpen(true)} disabled={!scheduleParent}><span className="category-picker-label">{scheduleSelectedSubcategory ? <><CategoryIcon icon={scheduleSelectedSubcategory.icon} size={16} /> {scheduleSelectedSubcategory.name}</> : "No subcategory"}</span><ChevronRight size={16} /></button><small>{scheduleParent ? `Add detail under ${scheduleParent.name} or keep the parent category.` : "Choose an expense category first."}</small></div>
          </> : <div className="form-field"><label>Income category</label><select value={scheduleCategory} onChange={(event) => onScheduleCategory(event.target.value)} disabled={!scheduleCategories.length}>{scheduleCategories.length ? scheduleCategories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>) : <option value="">Preparing income categories…</option>}</select>{scheduleSelectedCategory && <small className="selected-category-caption"><CategoryIcon icon={scheduleSelectedCategory.icon} size={13} /> A flat income category keeps recurring income simple.</small>}</div>}
          <LedgerDateField label="Next due date" value={dateVal} onChange={onDate} />
          <p className="form-field-note">When you mark this schedule paid or received, its matching entry is added to the ledger and the next due date moves forward.</p>
        </>}

        {scheduleParentPickerOpen && scheduleType === "expense" && (
          <div className="picker-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setScheduleParentPickerOpen(false); }}>
            <section className="picker-sheet" role="dialog" aria-modal="true" aria-label="Choose expense category for recurring schedule"><div className="picker-sheet-top"><div><div className="draft-kicker">Recurring bill</div><h3>Choose a category</h3></div><button type="button" className="close-button" onClick={() => setScheduleParentPickerOpen(false)} aria-label="Close category picker"><X size={16} /></button></div><p className="picker-sheet-note">Start with the parent category; detailed subcategories appear next.</p><div className="picker-sheet-list">{scheduleTopCategories.map((top) => <button type="button" className={`picker-row ${scheduleParent?.id === top.id ? "active" : ""}`} key={top.id} onClick={() => { setScheduleParentId(top.id); onScheduleCategory(top.id); setScheduleParentPickerOpen(false); setScheduleSubcategoryPickerOpen(true); }}><span><b className="category-picker-label"><CategoryIcon icon={top.icon} size={16} /> {top.name}</b><small>{scheduleCategories.filter((category) => category.parentId === top.id).length} choices within</small></span><ChevronRight size={17} /></button>)}</div></section>
          </div>
        )}

        {scheduleSubcategoryPickerOpen && scheduleType === "expense" && scheduleParent && (
          <div className="picker-sheet-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) setScheduleSubcategoryPickerOpen(false); }}>
            <section className="picker-sheet" role="dialog" aria-modal="true" aria-label={`Choose subcategory under ${scheduleParent.name}`}><div className="picker-sheet-top"><div><div className="draft-kicker">{scheduleParent.name}</div><h3>Choose a subcategory</h3></div><button type="button" className="close-button" onClick={() => setScheduleSubcategoryPickerOpen(false)} aria-label="Close subcategory picker"><X size={16} /></button></div><p className="picker-sheet-note">Use the parent category on its own, or select the detail that will make this bill easier to recognise.</p><div className="picker-sheet-list"><button type="button" className={`picker-row ${!scheduleSelectedSubcategory ? "active" : ""}`} onClick={() => { onScheduleCategory(scheduleParent.id); setScheduleSubcategoryPickerOpen(false); }}><span><b>Use {scheduleParent.name}</b><small>No subcategory</small></span>{!scheduleSelectedSubcategory && <CheckCircle2 size={17} />}</button>{scheduleSubcategories.map((sub) => <button type="button" className={`picker-row ${scheduleSelectedSubcategory?.id === sub.id ? "active" : ""}`} key={sub.id} onClick={() => { onScheduleCategory(sub.id); setScheduleSubcategoryPickerOpen(false); }}><span><b className="category-picker-label"><CategoryIcon icon={sub.icon} size={16} /> {sub.name}</b><small>Under {scheduleParent.name}</small></span>{scheduleSelectedSubcategory?.id === sub.id && <CheckCircle2 size={17} />}</button>)}</div></section>
          </div>
        )}

        {kind === "category" && <>
          <div className="form-field"><label>Type</label><div className="type-options"><button className={`type-option ${catType === "expense" ? "active" : ""}`} onClick={() => onCatType("expense")}>Expense</button><button className={`type-option ${catType === "income" ? "active" : ""}`} onClick={() => onCatType("income")}>Income</button></div></div>
          <div className="form-field"><label>{catType === "income" ? "Income category name" : "Category name"}</label><input value={catName} onChange={(event) => onCatName(event.target.value)} placeholder={catType === "income" ? "e.g. Rental yield or Bonus" : "e.g. Wellness"} autoFocus /></div>
          <IconPicker value={catIcon} onChange={onCatIcon} />
          {catType === "expense" && <div className="form-field"><label>Monthly budget</label><input value={catBudget} onChange={(event) => onCatBudget(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="400" inputMode="decimal" /></div>}
        </>}

        {kind === "subcategory" && <>
          <div className="form-field"><label>Parent category</label><select value={parentTarget || expenseTop[0]?.id} onChange={(event) => onParentTarget(event.target.value)}>{expenseTop.map((top) => <option value={top.id} key={top.id}>{top.name}</option>)}</select></div>
          <div className="form-field"><label>Subcategory name</label><input value={subName} onChange={(event) => onSubName(event.target.value)} placeholder="e.g. Specialty coffee" autoFocus /></div>
          <IconPicker value={subIcon} onChange={onSubIcon} />
        </>}

        {kind === "account" && <>
          <div className="form-field"><label>Account kind</label><div className="type-options"><button className={`type-option ${accKind === "asset" ? "active" : ""}`} onClick={() => onAccKind("asset")}>Asset / Bank</button><button className={`type-option ${accKind === "liability" ? "active" : ""}`} onClick={() => onAccKind("liability")}>Liability / Debt</button></div></div>
          <div className="form-field"><label>Account name</label><input value={accName} onChange={(event) => onAccName(event.target.value)} placeholder="e.g. Savings or Investment Portfolio" autoFocus /></div>
          <div className="form-field"><label>Starting balance</label><input value={accBalance} onChange={(event) => onAccBalance(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="2500" inputMode="decimal" /></div>
          <div className="form-field"><label>Masked number / Ref</label><input value={accNumber} onChange={(event) => onAccNumber(event.target.value)} placeholder="e.g. ··· 9912" /></div>
        </>}

        <div className="draft-actions">
          <button className="primary-button draft-submit" onClick={onSave}>{kind === "transaction" ? (transaction.id ? "Save changes" : "Save entry") : kind === "goal" ? (editingGoalId ? "Save goal" : "Create goal") : kind === "trip" ? (editingTripId ? "Save plan" : "Create plan") : kind === "loan" ? (editingLoanId ? "Save loan" : "Create loan") : kind === "schedule" ? (editingScheduleId ? "Save schedule" : "Create schedule") : kind === "category" ? "Add category" : kind === "subcategory" ? "Add subcategory" : "Save account"}</button>
          <button className="secondary-button" onClick={onClose}>Cancel</button>
        </div>
      </aside>
    </div>
  );
}

function monthKey(dateStr: string) {
  return dateStr.slice(0, 7);
}

function monthLabel(key: string) {
  const [year, month] = key.split("-").map(Number);
  return new Date(year, month - 1, 1).toLocaleDateString("en-US", { month: "long", year: "numeric" });
}

function shortDate(dateStr: string) {
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  } catch {
    return dateStr;
  }
}
