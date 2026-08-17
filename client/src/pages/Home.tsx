import { useState, useMemo } from "react";
import { Plus, Search, CalendarDays, ArrowUpRight, ArrowDownRight, ArrowRightLeft, Target, Landmark, Plane, Settings2, Home as HomeIcon, BarChart3, ChevronDown, Bell, WalletCards, CreditCard, FileDown, Check, X, Trash2, MoreHorizontal, Sparkles, PiggyBank, ArrowLeft, ChevronRight, FolderPlus, Compass, Receipt } from "lucide-react";

type TransactionType = "expense" | "income" | "transfer";
type IconKey = "food" | "income" | "travel" | "home" | "shopping" | "transfer";
type Screen = "Overview" | "Insights" | "Horizon" | "Settings";
type DraftKind = "transaction" | "goal" | "trip" | "category" | "subcategory" | null;

type Account = { id: string; name: string; kind: "asset" | "liability"; startingBalance: number; color: string };
type Category = { id: string; name: string; monthlyBudget: number; color: string; icon: IconKey; type: "expense" | "income"; parentId?: string };
type Goal = { id: string; name: string; targetAmount: number; targetDate: string; icon: "goal" | "home" };
type Trip = { id: string; name: string; dateRange: string; budget: number; color: string };
type Transaction = {
  id: string;
  type: TransactionType;
  amount: number;
  categoryId?: string;
  accountId: string;
  destinationAccountId?: string;
  date: string;
  merchantNote: string;
  tag?: { goalId?: string; tripId?: string };
  icon: IconKey;
};
type Detail = { kind: "goal" | "trip"; id: string } | null;
type TransactionDraft = {
  id?: string;
  merchantNote: string;
  amount: string;
  type: TransactionType;
  accountId: string;
  destinationAccountId: string;
  categoryId: string;
  goalId: string;
  tripId: string;
  date: string;
};

const heroArt = "/manus-storage/expense-tracker-ledger-hero_27b9b2fb.jpg";
const journeyArt = "/manus-storage/expense-tracker-goal-journey_cd34055f.jpg";
const insightsTexture = "/manus-storage/expense-tracker-insights-texture_3642c4f1.jpg";
const ledgerMark = "/manus-storage/expense-tracker-ledger-mark_1d5d936c.png";
const activePeriod = "2026-08";
const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 2 });

const seedAccounts: Account[] = [
  { id: "daily", name: "Daily account", kind: "asset", startingBalance: 4500, color: "#b78a3d" },
  { id: "reserve", name: "Reserve", kind: "asset", startingBalance: 3200, color: "#607b69" },
  { id: "credit", name: "Credit card · 2481", kind: "liability", startingBalance: 3200, color: "#b6785e" },
];

const seedCategories: Category[] = [
  // Expense top-level
  { id: "food", name: "Food & Dining", monthlyBudget: 800, color: "#b78a3d", icon: "food", type: "expense" },
  { id: "food-groceries", name: "Groceries", monthlyBudget: 0, color: "#b78a3d", icon: "food", type: "expense", parentId: "food" },
  { id: "food-rest", name: "Restaurants & Cafes", monthlyBudget: 0, color: "#b78a3d", icon: "food", type: "expense", parentId: "food" },
  
  { id: "home", name: "Home & Utilities", monthlyBudget: 1400, color: "#607b69", icon: "home", type: "expense" },
  { id: "home-rent", name: "Rent & Mortgage", monthlyBudget: 0, color: "#607b69", icon: "home", type: "expense", parentId: "home" },
  { id: "home-util", name: "Utilities & Fiber", monthlyBudget: 0, color: "#607b69", icon: "home", type: "expense", parentId: "home" },

  { id: "travel", name: "Travel", monthlyBudget: 1000, color: "#c77c5f", icon: "travel", type: "expense" },
  { id: "travel-lodging", name: "Stays & Transit", monthlyBudget: 0, color: "#c77c5f", icon: "travel", type: "expense", parentId: "travel" },

  { id: "personal", name: "Personal", monthlyBudget: 400, color: "#92769b", icon: "shopping", type: "expense" },
  { id: "personal-shop", name: "Shopping & Books", monthlyBudget: 0, color: "#92769b", icon: "shopping", type: "expense", parentId: "personal" },

  // Income flat
  { id: "income-salary", name: "Salary", monthlyBudget: 0, color: "#496d56", icon: "income", type: "income" },
  { id: "income-freelance", name: "Freelance income", monthlyBudget: 0, color: "#496d56", icon: "income", type: "income" },
  { id: "income-gifts", name: "Gifts & Dividends", monthlyBudget: 0, color: "#496d56", icon: "income", type: "income" },
];

const seedGoals: Goal[] = [
  { id: "reserve-goal", name: "Quiet reserve", targetAmount: 8000, targetDate: "By Dec 2026", icon: "goal" },
  { id: "home-goal", name: "A place of our own", targetAmount: 25000, targetDate: "By Jun 2027", icon: "home" },
];

const seedTrips: Trip[] = [
  { id: "spring", name: "Spring Journey", dateRange: "03–12 Apr 2027", budget: 1600, color: "#b78a3d" },
  { id: "family", name: "Family weekend", dateRange: "18–20 Sep 2026", budget: 640, color: "#607b69" },
];

const seedTransactions: Transaction[] = [
  { id: "t01", type: "income", amount: 2800, categoryId: "income-freelance", accountId: "daily", date: "2026-03-04", merchantNote: "Consulting project", icon: "income" },
  { id: "t02", type: "expense", amount: 145, categoryId: "personal-shop", accountId: "daily", date: "2026-03-08", merchantNote: "Studio supplies", icon: "shopping" },
  { id: "t03", type: "income", amount: 2200, categoryId: "income-freelance", accountId: "daily", date: "2026-04-02", merchantNote: "Northline Studio", icon: "income" },
  { id: "t04", type: "expense", amount: 96, categoryId: "travel-lodging", accountId: "credit", date: "2026-04-17", merchantNote: "Rail pass", icon: "travel", tag: { tripId: "spring" } },
  { id: "t05", type: "income", amount: 2600, categoryId: "income-salary", accountId: "daily", date: "2026-05-03", merchantNote: "Client retainer", icon: "income" },
  { id: "t06", type: "expense", amount: 320, categoryId: "food-groceries", accountId: "daily", date: "2026-05-18", merchantNote: "Groceries", icon: "food" },
  { id: "t07", type: "income", amount: 1700, categoryId: "income-salary", accountId: "daily", date: "2026-06-08", merchantNote: "Workshop honorarium", icon: "income" },
  { id: "t08", type: "expense", amount: 570, categoryId: "home-rent", accountId: "daily", date: "2026-06-13", merchantNote: "Home insurance", icon: "home" },
  { id: "t09", type: "income", amount: 3100, categoryId: "income-salary", accountId: "daily", date: "2026-07-01", merchantNote: "Monthly salary", icon: "income" },
  { id: "t10", type: "expense", amount: 215, categoryId: "food-rest", accountId: "daily", date: "2026-07-14", merchantNote: "Supper club", icon: "food" },
  { id: "t11", type: "income", amount: 3100, categoryId: "income-salary", accountId: "daily", date: "2026-08-01", merchantNote: "Monthly salary", icon: "income" },
  { id: "t12", type: "expense", amount: 340, categoryId: "food-groceries", accountId: "daily", date: "2026-08-03", merchantNote: "Market provisions", icon: "food" },
  { id: "t13", type: "expense", categoryId: "home-util", amount: 165, accountId: "daily", date: "2026-08-05", merchantNote: "Fiber internet & utilities", icon: "home" },
  { id: "t14", type: "expense", amount: 480, categoryId: "travel-lodging", accountId: "credit", date: "2026-08-08", merchantNote: "Hotel deposit", icon: "travel", tag: { tripId: "spring" } },
  { id: "t15", type: "expense", amount: 120, categoryId: "personal-shop", accountId: "daily", date: "2026-08-10", merchantNote: "Monograph books", icon: "shopping" },
  { id: "t16", type: "income", amount: 1840, categoryId: "income-freelance", accountId: "daily", date: "2026-08-16", merchantNote: "Northline Studio", icon: "income" },
  { id: "t17", type: "transfer", amount: 500, accountId: "daily", destinationAccountId: "credit", date: "2026-08-12", merchantNote: "Credit card payment", icon: "transfer" },
];

const navItems: { label: Screen; icon: typeof HomeIcon }[] = [
  { label: "Overview", icon: HomeIcon },
  { label: "Insights", icon: BarChart3 },
  { label: "Horizon", icon: Compass },
  { label: "Settings", icon: Settings2 },
];

const blankTransactionDraft = (preset: Partial<TransactionDraft> = {}): TransactionDraft => ({
  merchantNote: "",
  amount: "",
  type: "expense",
  accountId: "daily",
  destinationAccountId: "reserve",
  categoryId: "food-groceries",
  goalId: "none",
  tripId: "none",
  date: "2026-08-16",
  ...preset,
});

function accountBalance(account: Account, transactions: Transaction[]) {
  return transactions.reduce((balance, transaction) => {
    if (transaction.type === "transfer") {
      if (transaction.accountId === account.id) balance += account.kind === "asset" ? -transaction.amount : transaction.amount;
      if (transaction.destinationAccountId === account.id) balance += account.kind === "asset" ? transaction.amount : -transaction.amount;
      return balance;
    }
    if (transaction.accountId !== account.id) return balance;
    if (account.kind === "asset") return balance + (transaction.type === "income" ? transaction.amount : -transaction.amount);
    return balance + (transaction.type === "expense" ? transaction.amount : -transaction.amount);
  }, account.startingBalance);
}

function shortDate(date: string) {
  if (date === "2026-08-16") return "Today";
  if (date === "2026-08-15") return "Yesterday";
  return new Intl.DateTimeFormat("en-US", { day: "2-digit", month: "short" }).format(new Date(`${date}T12:00:00`));
}

function TransactionGlyph({ type }: { type: IconKey }) {
  const map = {
    food: { icon: Receipt, color: "#a86a53", bg: "#f8eee9" },
    income: { icon: ArrowDownRight, color: "#496d56", bg: "#edf4ed" },
    travel: { icon: Plane, color: "#9b7430", bg: "#f8f0e2" },
    home: { icon: Landmark, color: "#677365", bg: "#edf0eb" },
    shopping: { icon: Sparkles, color: "#7c6688", bg: "#f1ecf4" },
    transfer: { icon: ArrowRightLeft, color: "#59636b", bg: "#eef0f2" },
  }[type];
  const Icon = map.icon;
  return <div className="transaction-icon" style={{ color: map.color, background: map.bg }}><Icon size={17} strokeWidth={1.85} /></div>;
}

function Progress({ value, color }: { value: number; color?: string }) {
  return <div className="progress-track"><div className="progress-fill" style={{ width: `${Math.min(100, Math.max(0, value))}%`, background: color ?? "#b78a3d" }} /></div>;
}

export default function Home() {
  const [active, setActive] = useState<Screen>("Overview");
  const [horizon, setHorizon] = useState<"Goals" | "Plans">("Goals");
  const [detail, setDetail] = useState<Detail>(null);
  const [draft, setDraft] = useState<DraftKind>(null);
  const [filter, setFilter] = useState<"all" | TransactionType>("all");
  const [categoryFilterId, setCategoryFilterId] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [transactions, setTransactions] = useState(seedTransactions);
  const [categories, setCategories] = useState(seedCategories);
  const [goals, setGoals] = useState(seedGoals);
  const [trips, setTrips] = useState(seedTrips);
  const [draftTitle, setDraftTitle] = useState("");
  const [draftAmount, setDraftAmount] = useState("");
  const [transactionDraft, setTransactionDraft] = useState<TransactionDraft>(blankTransactionDraft());
  const [parentNameInput, setParentNameInput] = useState("");
  const [parentBudgetInput, setParentBudgetInput] = useState("");
  const [parentTargetId, setParentTargetId] = useState("");
  const [subNameInput, setSubNameInput] = useState("");

  const accountBalances = useMemo(() => seedAccounts.map((account) => ({ ...account, balance: accountBalance(account, transactions) })), [transactions]);
  const availableBalance = accountBalances.filter((account) => account.kind === "asset").reduce((sum, account) => sum + account.balance, 0);
  const netWorth = accountBalances.reduce((sum, account) => sum + (account.kind === "asset" ? account.balance : -account.balance), 0);
  const periodTransactions = useMemo(() => transactions.filter((transaction) => transaction.date.startsWith(activePeriod)), [transactions]);
  
  const totals = useMemo(() => periodTransactions.reduce((sum, transaction) => ({
    income: sum.income + (transaction.type === "income" ? transaction.amount : 0),
    expense: sum.expense + (transaction.type === "expense" ? transaction.amount : 0),
  }), { income: 0, expense: 0 }), [periodTransactions]);

  // Roll up spend by top-level category (includes its own direct spend + subcategories pointing to it)
  const categorySpent = useMemo(() => {
    const direct: Record<string, number> = {};
    periodTransactions.forEach((transaction) => {
      if (transaction.type !== "expense" || !transaction.categoryId) return;
      const cat = categories.find((c) => c.id === transaction.categoryId);
      if (!cat) return;
      const targetId = cat.parentId ?? cat.id;
      direct[targetId] = (direct[targetId] ?? 0) + transaction.amount;
    });
    return direct;
  }, [periodTransactions, categories]);

  const subcategorySpent = useMemo(() => {
    const direct: Record<string, number> = {};
    periodTransactions.forEach((transaction) => {
      if (transaction.type !== "expense" || !transaction.categoryId) return;
      direct[transaction.categoryId] = (direct[transaction.categoryId] ?? 0) + transaction.amount;
    });
    return direct;
  }, [periodTransactions]);

  const goalProgress = useMemo(() => Object.fromEntries(goals.map((goal) => [goal.id, transactions.filter((transaction) => transaction.tag?.goalId === goal.id).reduce((sum, transaction) => sum + transaction.amount, 0)])), [goals, transactions]);
  const tripSpend = useMemo(() => Object.fromEntries(trips.map((trip) => [trip.id, transactions.filter((transaction) => transaction.type === "expense" && transaction.tag?.tripId === trip.id).reduce((sum, transaction) => sum + transaction.amount, 0)])), [trips, transactions]);
  
  const filteredTransactions = useMemo(() => transactions.filter((transaction) => {
    const matchesType = filter === "all" || transaction.type === filter;
    let matchesCategory = true;
    if (categoryFilterId) {
      const targetCat = categories.find((c) => c.id === categoryFilterId);
      if (targetCat) {
        if (!targetCat.parentId) {
          // Top-level filter includes subcategories
          const subIds = categories.filter((c) => c.parentId === targetCat.id).map((c) => c.id);
          matchesCategory = transaction.categoryId === targetCat.id || subIds.includes(transaction.categoryId ?? "");
        } else {
          matchesCategory = transaction.categoryId === targetCat.id;
        }
      }
    }
    const term = query.toLowerCase();
    const catObj = categories.find((item) => item.id === transaction.categoryId)?.name.toLowerCase() ?? "";
    return matchesType && matchesCategory && (!term || transaction.merchantNote.toLowerCase().includes(term) || catObj.includes(term));
  }).sort((a, b) => b.date.localeCompare(a.date)), [transactions, filter, categoryFilterId, query, categories]);

  function resetDraft() {
    setDraft(null);
    setDraftTitle("");
    setDraftAmount("");
    setTransactionDraft(blankTransactionDraft());
    setParentNameInput("");
    setParentBudgetInput("");
    setParentTargetId("");
    setSubNameInput("");
  }

  function openTransactionDraft(preset: Partial<TransactionDraft> = {}) {
    setTransactionDraft(blankTransactionDraft(preset));
    setDraft("transaction");
  }

  function openTransactionEditor(transaction: Transaction) {
    openTransactionDraft({
      id: transaction.id,
      merchantNote: transaction.merchantNote,
      amount: String(transaction.amount),
      type: transaction.type,
      accountId: transaction.accountId,
      destinationAccountId: transaction.destinationAccountId ?? "reserve",
      categoryId: transaction.categoryId ?? "food-groceries",
      goalId: transaction.tag?.goalId ?? "none",
      tripId: transaction.tag?.tripId ?? "none",
      date: transaction.date,
    });
  }

  function saveDraft() {
    if (draft === "transaction") {
      const amount = Number(transactionDraft.amount);
      if (!amount || amount <= 0) return;
      const category = categories.find((item) => item.id === transactionDraft.categoryId);
      const transaction: Transaction = {
        id: transactionDraft.id ?? `t-${Date.now()}`,
        type: transactionDraft.type,
        amount,
        accountId: transactionDraft.accountId,
        destinationAccountId: transactionDraft.type === "transfer" ? transactionDraft.destinationAccountId : undefined,
        categoryId: transactionDraft.type === "transfer" ? undefined : transactionDraft.categoryId,
        date: transactionDraft.date,
        merchantNote: transactionDraft.merchantNote.trim() || (transactionDraft.type === "transfer" ? "Account transfer" : "Untitled entry"),
        icon: transactionDraft.type === "transfer" ? "transfer" : category?.icon ?? "shopping",
        tag: transactionDraft.goalId !== "none" || transactionDraft.tripId !== "none" ? { goalId: transactionDraft.goalId !== "none" ? transactionDraft.goalId : undefined, tripId: transactionDraft.tripId !== "none" ? transactionDraft.tripId : undefined } : undefined,
      };
      setTransactions((current) => transactionDraft.id ? current.map((item) => item.id === transactionDraft.id ? transaction : item) : [transaction, ...current]);
    } else if (draft === "goal") {
      const amount = Number(draftAmount) || 5000;
      setGoals((current) => [...current, { id: `goal-${Date.now()}`, name: draftTitle.trim() || "New savings goal", targetAmount: amount, targetDate: "By Dec 2026", icon: "goal" }]);
      setHorizon("Goals"); setActive("Horizon");
    } else if (draft === "trip") {
      const amount = Number(draftAmount) || 1200;
      setTrips((current) => [...current, { id: `trip-${Date.now()}`, name: draftTitle.trim() || "New trip plan", budget: amount, dateRange: "Dates to be set", color: "#c77c5f" }]);
      setHorizon("Plans"); setActive("Horizon");
    } else if (draft === "category") {
      const expenseTopCount = categories.filter((c) => c.type === "expense" && !c.parentId).length;
      if (expenseTopCount >= 8) {
        alert("Maximum 8 expense categories reached.");
        return;
      }
      const name = parentNameInput.trim();
      if (!name) return;
      const newCat: Category = {
        id: `cat-${Date.now()}`,
        name,
        monthlyBudget: Number(parentBudgetInput) || 0,
        color: "#83755c",
        icon: "shopping",
        type: "expense",
      };
      setCategories((current) => [...current, newCat]);
    } else if (draft === "subcategory") {
      const parent = categories.find((c) => c.id === parentTargetId);
      if (!parent) return;
      const subs = categories.filter((c) => c.parentId === parent.id);
      if (subs.length >= 4) {
        alert("Maximum 4 subcategories allowed per category.");
        return;
      }
      const name = subNameInput.trim();
      if (!name) return;
      const subCat: Category = {
        id: `sub-${Date.now()}`,
        name,
        monthlyBudget: 0,
        color: parent.color,
        icon: parent.icon,
        type: "expense",
        parentId: parent.id,
      };
      setCategories((current) => [...current, subCat]);
    }
    resetDraft();
  }

  function deleteDraftTransaction() {
    if (!transactionDraft.id) return;
    setTransactions((current) => current.filter((transaction) => transaction.id !== transactionDraft.id));
    resetDraft();
  }

  function deleteCategory(id: string) {
    setCategories((current) => current.filter((c) => c.id !== id && c.parentId !== id));
  }

  function openCategory(categoryId: string) {
    setActive("Overview"); setDetail(null); setCategoryFilterId(categoryId); setFilter("all"); setQuery("");
  }

  function openContextualDraft() {
    if (active === "Horizon" && !detail) setDraft(horizon === "Goals" ? "goal" : "trip");
    else openTransactionDraft();
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand"><img className="brand-mark" src={ledgerMark} alt="Expense Tracker ledger mark" /><div className="brand-word">Expense<small>Financial fieldbook</small></div></div>
        <div className="rail-label">Your ledger</div>
        <nav className="rail-nav" aria-label="Primary navigation">
          {navItems.map(({ label, icon: Icon }) => <button key={label} className={`rail-item ${active === label ? "active" : ""}`} onClick={() => { setActive(label); setDetail(null); }}><Icon size={18} strokeWidth={1.8} /><span>{label}</span></button>)}
        </nav>
        <div className="rail-bottom"><div className="month-card"><span className="eyebrow">August close</span><strong>16 days left</strong><p>{fmt.format(totals.expense)} is recorded against your category plans.</p></div><button className="rail-item" onClick={() => setActive("Settings")}><FileDown size={18} strokeWidth={1.8} /><span>Export ledger</span></button></div>
      </aside>

      <main className="content">
        <div className="topline"><div className="date-stamp"><CalendarDays size={13} /> Friday, 16 August 2026</div><div className="utility-actions"><button className="icon-button" aria-label="Notifications"><Bell size={17} strokeWidth={1.7} /></button><button className="profile-dot" aria-label="Open profile">MM</button></div></div>
        <section className="page-enter" key={`${active}-${detail?.id ?? "root"}`}>
          {active === "Overview" && <OverviewView balance={availableBalance} netWorth={netWorth} accounts={accountBalances} totals={totals} categories={categories} categorySpent={categorySpent} transactions={filteredTransactions} filter={filter} categoryFilterId={categoryFilterId} query={query} onFilter={setFilter} onQuery={setQuery} onClearCategory={() => setCategoryFilterId(null)} onOpenCategory={openCategory} onEdit={openTransactionEditor} />}
          {active === "Insights" && <InsightsView transactions={transactions} categories={categories} categorySpent={categorySpent} onOpenCategory={openCategory} />}
          {active === "Horizon" && detail && <PlanDetailView detail={detail} goals={goals} trips={trips} goalProgress={goalProgress} tripSpend={tripSpend} transactions={transactions} categories={categories} accounts={seedAccounts} onBack={() => setDetail(null)} onEdit={openTransactionEditor} onAddGoalFunds={(goal) => openTransactionDraft({ type: "transfer", accountId: "daily", destinationAccountId: "reserve", goalId: goal.id, merchantNote: `Contribution to ${goal.name}` })} onLogTripExpense={(trip) => openTransactionDraft({ type: "expense", accountId: "daily", categoryId: "travel", tripId: trip.id, merchantNote: `${trip.name} expense` })} />}
          {active === "Horizon" && !detail && <HorizonView tab={horizon} onTab={setHorizon} goals={goals} trips={trips} goalProgress={goalProgress} tripSpend={tripSpend} onCreateGoal={() => setDraft("goal")} onCreateTrip={() => setDraft("trip")} onOpenGoal={(goal) => setDetail({ kind: "goal", id: goal.id })} onOpenTrip={(trip) => setDetail({ kind: "trip", id: trip.id })} />}
          {active === "Settings" && <SettingsView accounts={accountBalances} categories={categories} subcategorySpent={subcategorySpent} onDeleteCategory={deleteCategory} onOpenAddCategory={() => setDraft("category")} onOpenAddSub={(parentId) => { setParentTargetId(parentId); setDraft("subcategory"); }} />}
        </section>
      </main>

      <nav className="mobile-bar" aria-label="Mobile navigation">
        <button className={`mobile-item ${active === "Overview" ? "active" : ""}`} onClick={() => { setActive("Overview"); setDetail(null); }}><HomeIcon size={17} /><span>Overview</span></button>
        <button className={`mobile-item ${active === "Insights" ? "active" : ""}`} onClick={() => { setActive("Insights"); setDetail(null); }}><BarChart3 size={17} /><span>Insights</span></button>
        <button className="mobile-add" onClick={openContextualDraft} aria-label="Add entry"><Plus size={20} /></button>
        <button className={`mobile-item ${active === "Horizon" ? "active" : ""}`} onClick={() => { setActive("Horizon"); setDetail(null); }}><Compass size={17} /><span>Horizon</span></button>
        <button className={`mobile-item ${active === "Settings" ? "active" : ""}`} onClick={() => { setActive("Settings"); setDetail(null); }}><Settings2 size={17} /><span>Settings</span></button>
      </nav>

      {draft && <DraftPanel kind={draft} title={draftTitle} amount={draftAmount} transaction={transactionDraft} accounts={seedAccounts} categories={categories} goals={goals} trips={trips} parentName={parentNameInput} parentBudget={parentBudgetInput} parentTarget={parentTargetId} subName={subNameInput} onTitle={setDraftTitle} onAmount={setDraftAmount} onTransaction={setTransactionDraft} onParentName={setParentNameInput} onParentBudget={setParentBudgetInput} onParentTarget={setParentTargetId} onSubName={setSubNameInput} onClose={resetDraft} onSave={saveDraft} onDelete={deleteDraftTransaction} />}
    </div>
  );
}

function OverviewView({ balance, netWorth, accounts, totals, categories, categorySpent, transactions, filter, categoryFilterId, query, onFilter, onQuery, onClearCategory, onOpenCategory, onEdit }: {
  balance: number; netWorth: number; accounts: Array<Account & { balance: number }>; totals: { income: number; expense: number }; categories: Category[]; categorySpent: Record<string, number>; transactions: Transaction[]; filter: "all" | TransactionType; categoryFilterId: string | null; query: string;
  onFilter: (value: "all" | TransactionType) => void; onQuery: (value: string) => void; onClearCategory: () => void; onOpenCategory: (id: string) => void; onEdit: (transaction: Transaction) => void;
}) {
  const savingsRate = totals.income ? Math.round(((totals.income - totals.expense) / totals.income) * 100) : 0;
  const selectedCategory = categories.find((category) => category.id === categoryFilterId);
  const expenseTopCategories = categories.filter((c) => c.type === "expense" && !c.parentId);
  const plannedBudget = expenseTopCategories.reduce((sum, category) => sum + category.monthlyBudget, 0);

  return <>
    <header className="page-header"><div><div className="page-kicker">Personal finance, considered</div><h1>Keep the whole picture<br />in view.</h1><p className="page-subtitle">A clear fieldbook for the money that moves your days.</p></div></header>
    <div className="dashboard-grid"><div><section className="balance-card"><img className="balance-art" src={heroArt} alt="Editorial ledger still life" /><div className="balance-content"><div className="balance-label"><span /> Available balance</div><div className="balance-number">{fmt.format(balance)}</div><p className="balance-caption">Across your asset accounts, with liabilities held apart for a truthful net worth.</p><div className="balance-foot"><div><span>Income, August</span><strong>{fmt.format(totals.income)}</strong></div><div><span>Expenses, August</span><strong>{fmt.format(totals.expense)}</strong></div></div></div></section><div className="summary-strip"><article className="mini-stat"><div className="stat-top">Inflow <span className="stat-icon up"><ArrowDownRight size={14} /></span></div><strong>{fmt.format(totals.income)}</strong><p>Derived from this month’s income</p></article><article className="mini-stat"><div className="stat-top">Outflow <span className="stat-icon down"><ArrowUpRight size={14} /></span></div><strong>{fmt.format(totals.expense)}</strong><p>Derived from recorded expenses</p></article><article className="mini-stat"><div className="stat-top">Savings rate <span className="stat-icon gold"><Target size={14} /></span></div><strong>{savingsRate}%</strong><p>Transfers stay neutral</p></article></div></div>
      <aside className="paper-card side-summary"><div className="card-head"><h2>Net worth</h2><span className="text-link">Assets − debts</span></div><div className="net-worth"><div className="net-worth-value">{fmt.format(netWorth)}</div><span className="change-tag"><ArrowUpRight size={11} /> calculated from accounts</span></div><div className="account-list">{accounts.map((account) => <div className={`account-row ${account.kind === "liability" ? "liability" : ""}`} key={account.id}><div className="account-left"><i className="account-dot" style={{ background: account.color }} />{account.name}</div><strong>{account.kind === "liability" ? `${fmt.format(account.balance)} owed` : fmt.format(account.balance)}</strong></div>)}</div></aside></div>
    <div className="lower-grid"><section className="paper-card section-card"><div className="section-head"><h2>{selectedCategory ? `${selectedCategory.name} ledger` : "Recent ledger"}</h2><div className="filter-row">{(["all", "expense", "income", "transfer"] as const).map((item) => <button key={item} className={`filter-button ${filter === item ? "active" : ""}`} onClick={() => onFilter(item)}>{item[0].toUpperCase() + item.slice(1)}</button>)}</div></div>{selectedCategory && <button className="filter-note" onClick={onClearCategory}>Viewing {selectedCategory.name} <X size={12} /></button>}<div className="search-box"><Search size={15} /><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Search a merchant or category" /></div><div className="transaction-list">{transactions.length ? transactions.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onEdit={onEdit} />) : <p className="budget-note">No entries match this view. Try another filter or clear the category context.</p>}</div></section>
      <aside className="paper-card budget-card"><div className="section-head"><h2>Month in hand</h2><MoreHorizontal size={18} color="#8b8174" /></div><div className="field-note"><div className="field-note-row"><span>Allocated capital</span><b>{fmt.format(plannedBudget)}</b></div><div className="field-note-row"><span>Expense entries</span><b>{transactions.filter((transaction) => transaction.type === "expense").length} records</b></div></div><div className="budget-meter"><div className="budget-label"><span>Planned spending</span><span>{fmt.format(totals.expense)} / {fmt.format(plannedBudget)}</span></div><div className="budget-track"><div className="budget-fill" style={{ width: `${Math.min(100, (totals.expense / plannedBudget) * 100)}%` }} /></div></div><p className="budget-note">Every category total is calculated from this month’s tagged expense records.</p><div className="upcoming-list"><div className="upcoming-title">Category pulse</div>{expenseTopCategories.slice(0, 4).map((category) => <button className="upcoming-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><span>{category.name}</span><b>{fmt.format(categorySpent[category.id] ?? 0)}</b><strong>of {fmt.format(category.monthlyBudget)}</strong></button>)}</div></aside></div>
  </>;
}

function TransactionRow({ transaction, categories, onEdit }: { transaction: Transaction; categories: Category[]; onEdit: (transaction: Transaction) => void }) {
  const category = categories.find((item) => item.id === transaction.categoryId);
  const descriptor = transaction.type === "transfer" ? "Transfer between your accounts" : category?.name ?? "Uncategorised";
  const signed = transaction.type === "income" ? "+" : transaction.type === "expense" ? "−" : "↔";
  const amountClass = transaction.type === "income" ? "amount-income" : transaction.type === "expense" ? "amount-expense" : "amount-transfer";
  return <button className="transaction-row transaction-button" onClick={() => onEdit(transaction)}><TransactionGlyph type={transaction.icon} /><div className="transaction-title"><strong>{transaction.merchantNote}</strong><span>{descriptor}{transaction.tag?.goalId ? " · Goal tagged" : ""}{transaction.tag?.tripId ? " · Trip tagged" : ""}</span></div><div className="transaction-amount"><strong className={amountClass}>{signed}{fmt.format(transaction.amount)}</strong><span>{shortDate(transaction.date)}</span></div></button>;
}

function InsightsView({ transactions, categories, categorySpent, onOpenCategory }: { transactions: Transaction[]; categories: Category[]; categorySpent: Record<string, number>; onOpenCategory: (id: string) => void }) {
  const months = ["Mar", "Apr", "May", "Jun", "Jul", "Aug"].map((label, index) => {
    const month = String(index + 3).padStart(2, "0");
    const entries = transactions.filter((transaction) => transaction.date.startsWith(`2026-${month}`));
    return { label, income: entries.filter((transaction) => transaction.type === "income").reduce((sum, transaction) => sum + transaction.amount, 0), expense: entries.filter((transaction) => transaction.type === "expense").reduce((sum, transaction) => sum + transaction.amount, 0) };
  });
  const max = Math.max(...months.flatMap((month) => [month.income, month.expense]), 1);
  const expenseTopCategories = categories.filter((c) => c.type === "expense" && !c.parentId);
  const spent = Object.values(categorySpent).reduce((sum, value) => sum + value, 0);
  const mix = expenseTopCategories.filter((category) => category.monthlyBudget > 0 && (categorySpent[category.id] ?? 0) > 0).sort((a, b) => (categorySpent[b.id] ?? 0) - (categorySpent[a.id] ?? 0));
  const stops = mix.reduce((parts, category, index) => { const start = parts.end; const size = spent ? ((categorySpent[category.id] ?? 0) / spent) * 100 : 0; return { end: start + size, gradient: `${parts.gradient}${category.color} ${start}% ${start + size}%${index < mix.length - 1 ? ", " : ""}` }; }, { end: 0, gradient: "" });
  return <><header className="page-header"><div><div className="page-kicker">A quieter kind of clarity</div><h1>Patterns worth<br />noticing.</h1><p className="page-subtitle">Each chart reads the same ledger from a different angle.</p></div><button className="secondary-button"><CalendarDays size={15} /> Aug 2026 <ChevronDown size={14} /></button></header><div className="insight-grid"><section className="paper-card chart-card"><div className="section-head"><h2>Cash flow</h2><span className="change-tag"><ArrowUpRight size={11} /> transaction-derived</span></div><p className="chart-caption">Income and expense transactions grouped by month. Transfers do not change the result.</p><div className="bars">{months.map((month) => <div className="bar-group" key={month.label}><div className="bar-pair"><i className="bar income" style={{ height: `${(month.income / max) * 100}%` }} /><i className="bar expense" style={{ height: `${(month.expense / max) * 100}%` }} /></div><span>{month.label}</span></div>)}</div><div className="legend"><span><i className="income-dot" /> Income</span><span><i className="expense-dot" /> Expenses</span></div><div className="analysis-paper"><div className="analysis-paper-copy"><b>August closing note</b>Transfers built reserves without changing the month’s net position.</div><img src={insightsTexture} alt="Abstract ledger analytics paper" /></div></section><section className="paper-card category-card"><div className="section-head"><h2>Expense mix</h2><span className="text-link">Tap a category</span></div><div className="donut-wrap"><div className="donut" style={{ background: `conic-gradient(${stops.gradient || "#d8d1c3 0 100%"})` }}><div className="donut-label"><strong>{fmt.format(spent)}</strong><span>Spent</span></div></div></div>{mix.map((category) => <button className="category-line category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><span><i className="cat-marker" style={{ background: category.color }} />{category.name}</span><b>{spent ? Math.round(((categorySpent[category.id] ?? 0) / spent) * 100) : 0}%</b></button>)}</section></div><section className="paper-card section-card" style={{ marginTop: 22 }}><div className="section-head"><h2>Budget performance</h2><span className="page-kicker" style={{ margin: 0 }}>August allocation</span></div><div className="horizon-grid">{expenseTopCategories.filter((category) => category.monthlyBudget > 0).map((category) => <BudgetLine key={category.id} category={category} used={categorySpent[category.id] ?? 0} onOpen={() => onOpenCategory(category.id)} />)}</div></section></>;
}

function BudgetLine({ category, used, onOpen }: { category: Category; used: number; onOpen: () => void }) {
  return <button className="plan-card paper-card plan-card-button" onClick={onOpen}><div className="plan-meta">{category.name}</div><h3>{fmt.format(used)}</h3><div className="plan-number"><span>of {fmt.format(category.monthlyBudget)} assigned</span></div><Progress value={(used / category.monthlyBudget) * 100} color={category.color} /><div className="plan-foot">{fmt.format(Math.max(0, category.monthlyBudget - used))} remains this month</div></button>;
}

function HorizonView({ tab, onTab, goals, trips, goalProgress, tripSpend, onCreateGoal, onCreateTrip, onOpenGoal, onOpenTrip }: { tab: "Goals" | "Plans"; onTab: (value: "Goals" | "Plans") => void; goals: Goal[]; trips: Trip[]; goalProgress: Record<string, number>; tripSpend: Record<string, number>; onCreateGoal: () => void; onCreateTrip: () => void; onOpenGoal: (goal: Goal) => void; onOpenTrip: (trip: Trip) => void }) {
  return (
    <>
      <section className="horizon-hero"><img src={journeyArt} alt="Travel planning and savings still life" /><div className="horizon-copy"><div className="page-kicker">Horizon</div><h1>Fund what<br />matters next.</h1><p>Goals and trips stay connected to the same transactions you already trust.</p></div></section>
      <div className="horizon-tabs"><button className={`horizon-tab ${tab === "Goals" ? "active" : ""}`} onClick={() => onTab("Goals")}>Savings goals</button><button className={`horizon-tab ${tab === "Plans" ? "active" : ""}`} onClick={() => onTab("Plans")}>Trip & event plans</button></div>
      {tab === "Goals" ? <><div className="page-header compact-header"><div><div className="page-kicker">Set aside with intention</div><h1>Your quiet reserves.</h1></div></div><div className="horizon-grid">{goals.map((goal) => <GoalCard goal={goal} saved={goalProgress[goal.id] ?? 0} key={goal.id} onOpen={() => onOpenGoal(goal)} />)}</div></> : <><div className="page-header compact-header"><div><div className="page-kicker">Budget the memory, not the aftermath</div><h1>Plans with room to enjoy.</h1></div></div><div className="horizon-grid">{trips.map((trip) => <TripCard trip={trip} spent={tripSpend[trip.id] ?? 0} key={trip.id} onOpen={() => onOpenTrip(trip)} />)}</div></>}
    </>
  );
}

function GoalCard({ goal, saved, onOpen }: { goal: Goal; saved: number; onOpen: () => void }) {
  const Icon = goal.icon === "home" ? Landmark : Target; const progress = (saved / goal.targetAmount) * 100;
  return <button className="paper-card plan-card plan-card-button" onClick={onOpen}><div className="plan-icon"><Icon size={18} strokeWidth={1.7} /></div><div className="plan-meta">{goal.targetDate}</div><h3>{goal.name}</h3><div className="plan-number">{fmt.format(saved)} <span>of {fmt.format(goal.targetAmount)}</span></div><Progress value={progress} /><div className="plan-foot">{Math.round(progress)}% held aside · {fmt.format(Math.max(0, goal.targetAmount - saved))} to go</div></button>;
}

function TripCard({ trip, spent, onOpen }: { trip: Trip; spent: number; onOpen: () => void }) {
  const progress = (spent / trip.budget) * 100;
  return <button className="paper-card plan-card plan-card-button" onClick={onOpen}><div className="plan-icon" style={{ color: trip.color }}><Plane size={18} strokeWidth={1.7} /></div><div className="plan-meta">{trip.dateRange}</div><h3>{trip.name}</h3><div className="plan-number">{fmt.format(spent)} <span>of {fmt.format(trip.budget)} spent</span></div><Progress value={progress} color={trip.color} /><div className="plan-foot">{fmt.format(Math.max(0, trip.budget - spent))} left for the experience</div></button>;
}

function PlanDetailView({ detail, goals, trips, goalProgress, tripSpend, transactions, categories, accounts, onBack, onEdit, onAddGoalFunds, onLogTripExpense }: { detail: Detail; goals: Goal[]; trips: Trip[]; goalProgress: Record<string, number>; tripSpend: Record<string, number>; transactions: Transaction[]; categories: Category[]; accounts: Account[]; onBack: () => void; onEdit: (transaction: Transaction) => void; onAddGoalFunds: (goal: Goal) => void; onLogTripExpense: (trip: Trip) => void }) {
  if (!detail) return null;
  const isGoal = detail.kind === "goal";
  const subject = isGoal ? goals.find((goal) => goal.id === detail.id) : trips.find((trip) => trip.id === detail.id);
  if (!subject) return null;
  const records = transactions.filter((transaction) => isGoal ? transaction.tag?.goalId === subject.id : transaction.tag?.tripId === subject.id).sort((a, b) => b.date.localeCompare(a.date));
  const accumulated = isGoal ? goalProgress[subject.id] ?? 0 : tripSpend[subject.id] ?? 0;
  const target = isGoal ? (subject as Goal).targetAmount : (subject as Trip).budget;
  const title = subject.name;
  return <><button className="detail-back" onClick={onBack}><ArrowLeft size={16} /> Back to Horizon</button><header className="page-header detail-header"><div><div className="page-kicker">{isGoal ? "Savings goal" : "Trip & event plan"}</div><h1>{title}</h1><p className="page-subtitle">{isGoal ? (subject as Goal).targetDate : (subject as Trip).dateRange}</p></div></header><section className="paper-card detail-summary"><div><span className="detail-label">{isGoal ? "Held aside" : "Spent so far"}</span><strong>{fmt.format(accumulated)}</strong></div><div><span className="detail-label">{isGoal ? "Target" : "Budget"}</span><strong>{fmt.format(target)}</strong></div><div><span className="detail-label">{isGoal ? "Still to fund" : "Remaining"}</span><strong>{fmt.format(Math.max(0, target - accumulated))}</strong></div></section><section className="paper-card section-card detail-ledger"><div className="section-head"><h2>Tagged ledger</h2><span className="page-kicker" style={{ margin: 0 }}>{records.length} records</span></div><div className="transaction-list">{records.length ? records.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onEdit={onEdit} />) : <p className="budget-note">No linked transactions yet. Use the mobile add action to pre-fill the appropriate ledger tag.</p>}</div></section><section className="paper-card detail-note"><PiggyBank size={18} /><p>{isGoal ? "Funding this goal creates a transfer tagged to the goal. It moves money between accounts without changing your net worth." : "Logging an expense assigns the trip tag directly to a normal expense transaction, so trip spend and category budgets stay in agreement."}</p><span>{accounts.length} accounts remain in the same ledger.</span></section></>;
}

function SettingsView({ accounts, categories, subcategorySpent, onDeleteCategory, onOpenAddCategory, onOpenAddSub }: { accounts: Array<Account & { balance: number }>; categories: Category[]; subcategorySpent: Record<string, number>; onDeleteCategory: (id: string) => void; onOpenAddCategory: () => void; onOpenAddSub: (parentId: string) => void }) {
  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeList = categories.filter((c) => c.type === "income");
  return (
    <>
      <header className="page-header"><div><div className="page-kicker">Housekeeping</div><h1>The ledger<br />behind the ledger.</h1><p className="page-subtitle">Your accounts and categories are the vocabulary every calculation reads.</p></div></header>
      <div className="settings-grid">
        <article className="paper-card settings-card" style={{ gridColumn: "1 / -1" }}>
          <div className="section-head" style={{ marginBottom: 12 }}>
            <h2>Expense categories ({expenseTop.length} of 8 used)</h2>
            <button className="add-button" onClick={onOpenAddCategory} disabled={expenseTop.length >= 8}><Plus size={15} /><span>Add category</span></button>
          </div>
          <p className="budget-note" style={{ marginBottom: 18 }}>Monthly budgets are set at the top-level. Subcategories track detail and roll up automatically.</p>
          <div className="category-edit-list">
            {expenseTop.map((cat) => {
              const subs = categories.filter((c) => c.parentId === cat.id);
              return (
                <div key={cat.id} className="category-group-row">
                  <div className="category-parent-header">
                    <span className="cat-marker" style={{ background: cat.color }} />
                    <strong>{cat.name}</strong>
                    <span className="cat-budget-tag">Budget: {fmt.format(cat.monthlyBudget)}</span>
                    <button className="sub-add-link" onClick={() => onOpenAddSub(cat.id)}><FolderPlus size={14} /> Add subcategory ({subs.length}/4)</button>
                    <button className="delete-button" onClick={() => onDeleteCategory(cat.id)}><Trash2 size={13} /></button>
                  </div>
                  {subs.length > 0 && (
                    <div className="subcategory-sublist">
                      {subs.map((sub) => (
                        <div key={sub.id} className="subcategory-row">
                          <span>↳ {sub.name}</span>
                          <b>{fmt.format(subcategorySpent[sub.id] ?? 0)}</b>
                          <button className="delete-button" onClick={() => onDeleteCategory(sub.id)}><Trash2 size={12} /></button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </article>

        <article className="paper-card settings-card" style={{ gridColumn: "1 / -1", marginTop: 12 }}>
          <div className="section-head" style={{ marginBottom: 12 }}>
            <h2>Income sources ({incomeList.length} of 6 used)</h2>
          </div>
          <div className="category-edit-list">
            {incomeList.map((inc) => (
              <div key={inc.id} className="category-parent-header">
                <span className="cat-marker" style={{ background: inc.color }} />
                <strong>{inc.name}</strong>
                <button className="delete-button" onClick={() => onDeleteCategory(inc.id)}><Trash2 size={13} /></button>
              </div>
            ))}
          </div>
        </article>

        <article className="paper-card settings-card" style={{ marginTop: 12 }}><div className="set-icon"><WalletCards size={19} /></div><h3>Accounts</h3><p>{accounts.filter((account) => account.kind === "asset").length} assets and {accounts.filter((account) => account.kind === "liability").length} liability are contributing to net worth correctly.</p></article>
        <article className="paper-card settings-card" style={{ marginTop: 12 }}><div className="set-icon"><FileDown size={19} /></div><h3>Export data</h3><p>Prepare a CSV or an archival PDF that keeps transactions, goals, and trips together.</p><button className="secondary-button" style={{ marginTop: 12 }}>Prepare export</button></article>
      </div>
    </>
  );
}

function DraftPanel({ kind, title, amount, transaction, accounts, categories, goals, trips, parentName, parentBudget, parentTarget, subName, onTitle, onAmount, onTransaction, onParentName, onParentBudget, onParentTarget, onSubName, onClose, onSave, onDelete }: {
  kind: Exclude<DraftKind, null>; title: string; amount: string; transaction: TransactionDraft; accounts: Account[]; categories: Category[]; goals: Goal[]; trips: Trip[]; parentName: string; parentBudget: string; parentTarget: string; subName: string;
  onTitle: (value: string) => void; onAmount: (value: string) => void; onTransaction: (value: TransactionDraft | ((current: TransactionDraft) => TransactionDraft)) => void; onParentName: (value: string) => void; onParentBudget: (value: string) => void; onParentTarget: (value: string) => void; onSubName: (value: string) => void; onClose: () => void; onSave: () => void; onDelete: () => void;
}) {
  const heading = kind === "transaction" ? (transaction.id ? "Edit transaction" : "Draft a transaction") : kind === "goal" ? "Set a new goal" : kind === "trip" ? "Plan the journey" : kind === "category" ? "Add top-level category" : "Add subcategory";
  const descriptor = kind === "transaction" ? "Record, recategorise, or correct a money movement." : kind === "goal" ? "Give future money a purpose." : kind === "trip" ? "Set a ceiling before the memories start." : "Expand your ledger structure.";
  const update = (patch: Partial<TransactionDraft>) => onTransaction((current) => ({ ...current, ...patch }));
  
  // Build searchable flat category options with path notation ("Parent → Sub")
  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const expenseOptions: Array<{ id: string; label: string }> = [];
  expenseTop.forEach((top) => {
    expenseOptions.push({ id: top.id, label: top.name });
    categories.filter((c) => c.parentId === top.id).forEach((sub) => {
      expenseOptions.push({ id: sub.id, label: `${top.name} → ${sub.name}` });
    });
  });
  const incomeOptions = categories.filter((c) => c.type === "income").map((c) => ({ id: c.id, label: c.name }));
  const activeCategoryOptions = transaction.type === "income" ? incomeOptions : expenseOptions;

  return (
    <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={heading} onMouseDown={onClose}>
      <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
        <div className="draft-top"><div><div className="draft-kicker">{descriptor}</div><h2>{heading}</h2></div><button className="close-button" onClick={onClose} aria-label="Close"><X size={17} /></button></div>
        
        {kind === "transaction" && <>
          <div className="form-field"><label>Movement</label><div className="type-options">{(["expense", "income", "transfer"] as const).map((type) => <button key={type} className={`type-option ${transaction.type === type ? "active" : ""}`} onClick={() => update({ type, categoryId: type === "income" ? "income-salary" : "food-groceries" })}>{type[0].toUpperCase() + type.slice(1)}</button>)}</div></div>
          <div className="form-field"><label>Merchant or note</label><input value={transaction.merchantNote} onChange={(event) => update({ merchantNote: event.target.value })} placeholder={transaction.type === "transfer" ? "e.g. Contribution to reserve" : "e.g. Sunday market"} autoFocus /></div>
          <div className="form-field"><label>Amount</label><input value={transaction.amount} onChange={(event) => update({ amount: event.target.value.replace(/[^0-9.]/g, "") })} placeholder="0.00" inputMode="decimal" /></div>
          <div className="form-field"><label>{transaction.type === "transfer" ? "From account" : "Account"}</label><select value={transaction.accountId} onChange={(event) => update({ accountId: event.target.value })}>{accounts.map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>
          {transaction.type === "transfer" && <div className="form-field"><label>To account</label><select value={transaction.destinationAccountId} onChange={(event) => update({ destinationAccountId: event.target.value })}>{accounts.filter((account) => account.id !== transaction.accountId).map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>}
          {transaction.type !== "transfer" && <div className="form-field"><label>Category path</label><select value={transaction.categoryId} onChange={(event) => update({ categoryId: event.target.value })}>{activeCategoryOptions.map((opt) => <option value={opt.id} key={opt.id}>{opt.label}</option>)}</select></div>}
          <div className="form-field"><label>Date</label><input type="date" value={transaction.date} onChange={(event) => update({ date: event.target.value })} /></div>
          <div className="tag-grid"><div className="form-field"><label>Goal tag</label><select value={transaction.goalId} onChange={(event) => update({ goalId: event.target.value })}><option value="none">No goal</option>{goals.map((goal) => <option value={goal.id} key={goal.id}>{goal.name}</option>)}</select></div><div className="form-field"><label>Trip tag</label><select value={transaction.tripId} onChange={(event) => update({ tripId: event.target.value })}><option value="none">No trip</option>{trips.map((trip) => <option value={trip.id} key={trip.id}>{trip.name}</option>)}</select></div></div>
        </>}

        {kind === "goal" && <><div className="form-field"><label>Goal title</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Home reserve" autoFocus /></div><div className="form-field"><label>Target amount</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="5,000" inputMode="decimal" /></div></>}
        {kind === "trip" && <><div className="form-field"><label>Plan name</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Autumn in Lisbon" autoFocus /></div><div className="form-field"><label>Working budget</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="1,200" inputMode="decimal" /></div></>}
        {kind === "category" && <><div className="form-field"><label>Category name</label><input value={parentName} onChange={(event) => onParentName(event.target.value)} placeholder="e.g. Health & Fitness" autoFocus /></div><div className="form-field"><label>Monthly budget</label><input value={parentBudget} onChange={(event) => onParentBudget(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="400" inputMode="decimal" /></div></>}
        {kind === "subcategory" && <><div className="form-field"><label>Parent category</label><select value={parentTarget || expenseTop[0]?.id} onChange={(event) => onParentTarget(event.target.value)}>{expenseTop.map((top) => <option value={top.id} key={top.id}>{top.name}</option>)}</select></div><div className="form-field"><label>Subcategory name</label><input value={subName} onChange={(event) => onSubName(event.target.value)} placeholder="e.g. Pharmacy & Care" autoFocus /></div></>}

        <div className="draft-actions">
          <button className="primary-button draft-submit" onClick={onSave}>{kind === "transaction" ? "Save entry" : kind === "goal" ? "Create goal" : kind === "trip" ? "Create plan" : kind === "category" ? "Save category" : "Save subcategory"}</button>
          {kind === "transaction" && transaction.id && <button className="delete-button" onClick={onDelete}><Trash2 size={15} /> Delete entry</button>}
        </div>
      </aside>
    </div>
  );
}
