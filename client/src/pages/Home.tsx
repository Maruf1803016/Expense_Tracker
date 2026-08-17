import React, { useState, useMemo } from "react";
import { ArrowDownRight, ArrowUpRight, Plus, Search, Wallet, ShieldCheck, LogOut, X, Edit3, Trash2, Tag, Compass, Calendar, Layers, CheckCircle2, ChevronRight, FolderPlus } from "lucide-react";

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
}

interface Goal {
  id: string;
  name: string;
  target: number;
  saved: number;
  deadline: string;
}

interface Trip {
  id: string;
  name: string;
  budget: number;
  dates: string;
}

type DraftKind = "transaction" | "goal" | "trip" | "category" | "subcategory" | "account" | "profile" | null;

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
}

const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 2 });

const INITIAL_ACCOUNTS: Account[] = [
  { id: "acc-1", name: "Daily account", kind: "asset", balance: 19465, accountNumber: "··· 4092", color: "#1b3a2b" },
  { id: "acc-2", name: "Reserve", kind: "asset", balance: 3200, accountNumber: "··· 8110", color: "#2b4c3f" },
  { id: "acc-3", name: "Credit card", kind: "liability", balance: 3276, accountNumber: "··· 2481", color: "#8b2626" },
];

const INITIAL_CATEGORIES: Category[] = [
  { id: "food", name: "Food & Dining", type: "expense", monthlyBudget: 800, color: "#1b3a2b" },
  { id: "food-groceries", name: "Groceries", type: "expense", parentId: "food", monthlyBudget: 0, color: "#1b3a2b" },
  { id: "food-restaurants", name: "Restaurants & Cafes", type: "expense", parentId: "food", monthlyBudget: 0, color: "#1b3a2b" },
  { id: "home", name: "Home & Utilities", type: "expense", monthlyBudget: 1500, color: "#3d5a45" },
  { id: "home-rent", name: "Rent & Mortgage", type: "expense", parentId: "home", monthlyBudget: 0, color: "#3d5a45" },
  { id: "home-utilities", name: "Utilities & Fiber", type: "expense", parentId: "home", monthlyBudget: 0, color: "#3d5a45" },
  { id: "travel", name: "Travel", type: "expense", monthlyBudget: 1000, color: "#8c6d36" },
  { id: "travel-stays", name: "Stays & Transit", type: "expense", parentId: "travel", monthlyBudget: 0, color: "#8c6d36" },
  { id: "personal", name: "Personal", type: "expense", monthlyBudget: 400, color: "#5b4a6f" },
  { id: "personal-shopping", name: "Shopping & Books", type: "expense", parentId: "personal", monthlyBudget: 0, color: "#5b4a6f" },
  { id: "income-salary", name: "Salary", type: "income", monthlyBudget: 0, color: "#2c5234" },
  { id: "income-freelance", name: "Freelance income", type: "income", monthlyBudget: 0, color: "#32603c" },
  { id: "income-gifts", name: "Gifts & Dividends", type: "income", monthlyBudget: 0, color: "#3a6e45" },
];

const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: "tx-1", merchantNote: "Northline Studio", amount: 1840, type: "income", accountId: "acc-1", categoryId: "income-freelance", date: "2026-08-16", icon: "ArrowDownRight" },
  { id: "tx-2", merchantNote: "Botanica Market", amount: 124.5, type: "expense", accountId: "acc-1", categoryId: "food-groceries", date: "2026-08-15", icon: "ShoppingCart" },
  { id: "tx-3", merchantNote: "Power & Water Board", amount: 165, type: "expense", accountId: "acc-1", categoryId: "home-utilities", date: "2026-08-14", icon: "Zap" },
  { id: "tx-4", merchantNote: "Air France · Lisbon", amount: 480, type: "expense", accountId: "acc-3", categoryId: "travel-stays", date: "2026-08-12", tag: { tripId: "trip-1" }, icon: "Compass" },
  { id: "tx-5", merchantNote: "Monthly Salary", amount: 3100, type: "income", accountId: "acc-1", categoryId: "income-salary", date: "2026-08-01", icon: "Briefcase" },
  { id: "tx-6", merchantNote: "Reserve Sweep", amount: 500, type: "transfer", accountId: "acc-1", destinationAccountId: "acc-2", date: "2026-08-10", icon: "Repeat" },
];

const INITIAL_GOALS: Goal[] = [
  { id: "goal-1", name: "Quiet reserve", target: 8000, saved: 3200, deadline: "By Dec 2026" },
];

const INITIAL_TRIPS: Trip[] = [
  { id: "trip-1", name: "Autumn in Lisbon", budget: 1200, dates: "12–19 Oct 2026" },
];

export default function Home() {
  const [activeTab, setActiveTab] = useState<"overview" | "insights" | "horizon" | "settings">("overview");
  const [filter, setFilter] = useState<"all" | TransactionType>("all");
  const [categoryFilterId, setCategoryFilterId] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const [accounts, setAccounts] = useState<Account[]>(INITIAL_ACCOUNTS);
  const [categories, setCategories] = useState<Category[]>(INITIAL_CATEGORIES);
  const [transactions, setTransactions] = useState<Transaction[]>(INITIAL_TRANSACTIONS);
  const [goals, setGoals] = useState<Goal[]>(INITIAL_GOALS);
  const [trips, setTrips] = useState<Trip[]>(INITIAL_TRIPS);

  const [draft, setDraft] = useState<DraftKind>(null);
  const [transactionDetail, setTransactionDetail] = useState<Transaction | null>(null);

  const [draftTitle, setDraftTitle] = useState("");
  const [draftAmount, setDraftAmount] = useState("");
  const [draftDate, setDraftDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [transactionDraft, setTransactionDraft] = useState<TransactionDraft>({
    merchantNote: "",
    amount: "",
    type: "expense",
    accountId: "acc-1",
    destinationAccountId: "acc-2",
    categoryId: "food-groceries",
    date: new Date().toISOString().slice(0, 10),
    goalId: "none",
    tripId: "none",
  });

  const [catNameInput, setCatNameInput] = useState("");
  const [catBudgetInput, setCatBudgetInput] = useState("");
  const [catTypeInput, setCatTypeInput] = useState<"expense" | "income">("expense");
  const [parentTargetId, setParentTargetId] = useState("");
  const [subNameInput, setSubNameInput] = useState("");
  const [accNameInput, setAccNameInput] = useState("");
  const [accKindInput, setAccKindInput] = useState<"asset" | "liability">("asset");
  const [accBalanceInput, setAccBalanceInput] = useState("");
  const [accNumberInput, setAccNumberInput] = useState("");

  const totals = useMemo(() => {
    let income = 0;
    let expense = 0;
    for (const transaction of transactions) {
      if (transaction.type === "income") income += transaction.amount;
      if (transaction.type === "expense") expense += transaction.amount;
    }
    return { income, expense };
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

  const netWorth = useMemo(() => {
    return accountsWithBalance.reduce((sum, account) => account.kind === "liability" ? sum - account.balance : sum + account.balance, 0);
  }, [accountsWithBalance]);

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

  const startCreatingTransaction = () => {
    setTransactionDraft({
      merchantNote: "",
      amount: "",
      type: "expense",
      accountId: accounts[0]?.id ?? "acc-1",
      destinationAccountId: accounts[1]?.id ?? "acc-2",
      categoryId: categories.find(c => c.type === "expense")?.id ?? "food-groceries",
      date: new Date().toISOString().slice(0, 10),
      goalId: "none",
      tripId: "none",
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
      categoryId: transaction.categoryId ?? "food-groceries",
      date: transaction.date,
      goalId: transaction.tag?.goalId ?? "none",
      tripId: transaction.tag?.tripId ?? "none",
    });
    setDraft("transaction");
  };

  const resetDraft = () => {
    setDraft(null);
    setDraftTitle("");
    setDraftAmount("");
    setCatNameInput("");
    setCatBudgetInput("");
    setSubNameInput("");
    setAccNameInput("");
    setAccBalanceInput("");
    setAccNumberInput("");
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
      };

      if (transactionDraft.id) {
        setTransactions((current) => current.map((t) => t.id === transactionDraft.id ? newTransaction : t));
      } else {
        setTransactions((current) => [newTransaction, ...current]);
      }
      resetDraft();
    } else if (draft === "goal") {
      const parsed = parseFloat(draftAmount);
      if (!draftTitle.trim() || isNaN(parsed) || parsed <= 0) {
        alert("Please enter a valid goal title and target amount.");
        return;
      }
      setGoals((current) => [{ id: `goal-${Date.now()}`, name: draftTitle.trim(), target: parsed, saved: 0, deadline: draftDate || "By Dec 2026" }, ...current]);
      resetDraft();
    } else if (draft === "trip") {
      const parsed = parseFloat(draftAmount);
      if (!draftTitle.trim() || isNaN(parsed) || parsed <= 0) {
        alert("Please enter a valid trip name and budget.");
        return;
      }
      setTrips((current) => [{ id: `trip-${Date.now()}`, name: draftTitle.trim(), budget: parsed, dates: draftDate || "Upcoming" }, ...current]);
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
      };
      setCategories((current) => [...current, newCat]);
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
      };
      setCategories((current) => [...current, newSub]);
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
      resetDraft();
    }
  };

  return (
    <div className="app-container">
      <aside className="sidebar-rail">
        <div className="brand-lockup">
          <span className="brand-mark"><Layers size={20} /></span>
          <div>
            <strong>Expense</strong>
            <span>Financial Fieldbook</span>
          </div>
        </div>
        <div className="rail-section-label">Your ledger</div>
        <nav className="rail-nav">
          <button className={`rail-button ${activeTab === "overview" ? "active" : ""}`} onClick={() => setActiveTab("overview")}><Wallet size={16} /> Overview</button>
          <button className={`rail-button ${activeTab === "insights" ? "active" : ""}`} onClick={() => setActiveTab("insights")}><ArrowUpRight size={16} /> Insights</button>
          <button className={`rail-button ${activeTab === "horizon" ? "active" : ""}`} onClick={() => setActiveTab("horizon")}><Compass size={16} /> Goals & Plans</button>
          <button className={`rail-button ${activeTab === "settings" ? "active" : ""}`} onClick={() => setActiveTab("settings")}><ShieldCheck size={16} /> Settings</button>
        </nav>
        <div className="rail-footer">
          <div className="rail-kicker">August close</div>
          <div className="rail-metric"><strong>16 days left</strong><span>{fmt.format(totals.expense)} recorded against budget plans.</span></div>
          <button className="text-link" onClick={() => alert("Statement export generated: CSV & PDF downloaded.")} style={{ marginTop: 12, display: "inline-block" }}>Export ledger</button>
        </div>
      </aside>

      <main className="content-viewport">
        <header className="top-nav-bar">
          <div className="mobile-brand-lockup"><span className="mobile-brand-mark"><Layers size={16} /></span><div><strong>EXPENSE</strong><span>FIELD BOOK</span></div></div>
          <div className="breadcrumb"><span>/</span><strong>{activeTab === "horizon" ? "Goals & Plans" : activeTab[0].toUpperCase() + activeTab.slice(1)}</strong></div>
          <div className="top-nav-actions">
            <button className="icon-badge" onClick={() => alert("No pending alerts.")} aria-label="Notifications"><Calendar size={16} /></button>
            <button className="profile-pill" onClick={() => setDraft("profile")} aria-label="User profile">MM</button>
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
              categorySpent={categorySpent}
              transactions={filteredTransactions}
              filter={filter}
              categoryFilterId={categoryFilterId}
              query={query}
              onFilter={setFilter}
              onQuery={setQuery}
              onClearCategory={() => setCategoryFilterId(null)}
              onOpenCategory={(id) => setCategoryFilterId(id)}
              onSelectTransaction={(tx) => setTransactionDetail(tx)}
            />
          )}

          {activeTab === "insights" && (
            <InsightsView
              transactions={transactions}
              categories={categories}
              categorySpent={categorySpent}
              onOpenCategory={(id) => { setCategoryFilterId(id); setActiveTab("overview"); }}
            />
          )}

          {activeTab === "horizon" && (
            <HorizonView
              goals={goals}
              trips={trips}
              onOpenAddGoal={() => setDraft("goal")}
              onOpenAddTrip={() => setDraft("trip")}
            />
          )}

          {activeTab === "settings" && (
            <SettingsView
              accounts={accounts}
              categories={categories}
              subcategorySpent={subcategorySpent}
              onOpenAddAccount={() => setDraft("account")}
              onOpenAddCategory={() => { setCatTypeInput("expense"); setDraft("category"); }}
              onOpenAddIncomeCategory={() => { setCatTypeInput("income"); setDraft("category"); }}
              onOpenAddSub={(parentId) => { setParentTargetId(parentId); setDraft("subcategory"); }}
              onDeleteCategory={(id) => setCategories(current => current.filter(c => c.id !== id && c.parentId !== id))}
            />
          )}
        </div>
      </main>

      <nav className="mobile-bottom-nav">
        <button className={`mobile-nav-item ${activeTab === "overview" ? "active" : ""}`} onClick={() => setActiveTab("overview")}><Wallet size={18} /><span>Overview</span></button>
        <button className={`mobile-nav-item ${activeTab === "insights" ? "active" : ""}`} onClick={() => setActiveTab("insights")}><ArrowUpRight size={18} /><span>Insights</span></button>
        <button className="mobile-fab" onClick={startCreatingTransaction} aria-label="Add transaction"><Plus size={22} /></button>
        <button className={`mobile-nav-item ${activeTab === "horizon" ? "active" : ""}`} onClick={() => setActiveTab("horizon")}><Compass size={18} /><span>Goals & Plans</span></button>
        <button className={`mobile-nav-item ${activeTab === "settings" ? "active" : ""}`} onClick={() => setActiveTab("settings")}><ShieldCheck size={18} /><span>Settings</span></button>
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
              {transactionDetail.tag?.goalId && <div className="field-note-row"><span>Tagged goal</span><b>{goals.find(g => g.id === transactionDetail.tag?.goalId)?.name}</b></div>}
              {transactionDetail.tag?.tripId && <div className="field-note-row"><span>Tagged trip</span><b>{trips.find(t => t.id === transactionDetail.tag?.tripId)?.name}</b></div>}
            </div>
            <div className="draft-actions" style={{ marginTop: 24 }}>
              <button className="primary-button draft-submit" onClick={() => startEditingTransaction(transactionDetail)}><Edit3 size={15} /> Modify entry</button>
              <button className="delete-button" onClick={() => { setTransactions(current => current.filter(t => t.id !== transactionDetail.id)); setTransactionDetail(null); }}><Trash2 size={15} /> Remove from ledger</button>
            </div>
          </aside>
        </div>
      )}

      {/* Expanded Profile Modal */}
      {draft === "profile" && (
        <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label="User profile" onMouseDown={resetDraft}>
          <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
            <div className="draft-top"><div><div className="draft-kicker">Authenticated session</div><h2>User Profile & Security</h2></div><button className="close-button" onClick={resetDraft} aria-label="Close"><X size={17} /></button></div>
            <div style={{ display: "flex", alignItems: "center", gap: 16, margin: "20px 0", padding: "18px", background: "#f8f4ec", borderRadius: 14, border: "1px solid #ded8ca" }}>
              <div className="profile-dot" style={{ width: 52, height: 52, fontSize: 18, background: "#1b3a2b", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", borderRadius: "50%", fontWeight: 600 }}>MM</div>
              <div><strong style={{ fontSize: 17, display: "block", fontFamily: "Space Grotesk, sans-serif" }}>Maruf Mahmud</strong><span style={{ color: "#777", fontSize: 13 }}>maruf.owner@expense-tracker.app</span></div>
            </div>
            <div className="field-note" style={{ display: "grid", gap: 10, marginBottom: 20 }}>
              <div className="field-note-row"><span>Subscription</span><b>Owner Tier (Active)</b></div>
              <div className="field-note-row"><span>Security</span><b>End-to-end encrypted</b></div>
              <div className="field-note-row"><span>Cloud Sync</span><b>Connected to Firestore</b></div>
              <div className="field-note-row"><span>Storage</span><b>Zero-knowledge sandbox</b></div>
            </div>
            <div style={{ display: "grid", gap: 12, marginBottom: 24 }}>
              <label style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 14px", background: "#fcfaf6", borderRadius: 10, border: "1px solid #ded8ca", fontSize: 14, cursor: "pointer" }}>
                <span>Biometric lock on start</span>
                <input type="checkbox" defaultChecked style={{ accentColor: "#b78a3d", width: 16, height: 16 }} />
              </label>
              <label style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 14px", background: "#fcfaf6", borderRadius: 10, border: "1px solid #ded8ca", fontSize: 14, cursor: "pointer" }}>
                <span>Monthly budget summaries</span>
                <input type="checkbox" defaultChecked style={{ accentColor: "#b78a3d", width: 16, height: 16 }} />
              </label>
            </div>
            <div className="draft-actions">
              <button className="primary-button draft-submit" onClick={resetDraft}><ShieldCheck size={16} /> Save preferences</button>
              <button className="delete-button" onClick={() => { alert("Signed out of local demo session."); resetDraft(); }}><LogOut size={16} /> Sign out of session</button>
            </div>
          </aside>
        </div>
      )}

      {/* Standard Draft / Create Panel */}
      {draft && draft !== "profile" && (
        <DraftPanel
          kind={draft}
          title={draftTitle}
          amount={draftAmount}
          dateVal={draftDate}
          transaction={transactionDraft}
          accounts={accounts}
          categories={categories}
          goals={goals}
          trips={trips}
          catName={catNameInput}
          catBudget={catBudgetInput}
          catType={catTypeInput}
          parentTarget={parentTargetId}
          subName={subNameInput}
          accName={accNameInput}
          accKind={accKindInput}
          accBalance={accBalanceInput}
          accNumber={accNumberInput}
          onTitle={setDraftTitle}
          onAmount={setDraftAmount}
          onDate={setDraftDate}
          onTransaction={setTransactionDraft}
          onCatName={setCatNameInput}
          onCatBudget={setCatBudgetInput}
          onCatType={setCatTypeInput}
          onParentTarget={setParentTargetId}
          onSubName={setSubNameInput}
          onAccName={setAccNameInput}
          onAccKind={setAccKindInput}
          onAccBalance={setAccBalanceInput}
          onAccNumber={setAccNumberInput}
          onClose={resetDraft}
          onSave={saveDraft}
          onOpenAddSub={(parentId) => { setParentTargetId(parentId); setDraft("subcategory"); }}
        />
      )}
    </div>
  );
}

function OverviewView({ balance, netWorth, accounts, totals, categories, categorySpent, transactions, filter, categoryFilterId, query, onFilter, onQuery, onClearCategory, onOpenCategory, onSelectTransaction }: {
  balance: number; netWorth: number; accounts: Array<Account & { balance: number }>; totals: { income: number; expense: number }; categories: Category[]; categorySpent: Record<string, number>; transactions: Transaction[]; filter: "all" | TransactionType; categoryFilterId: string | null; query: string;
  onFilter: (value: "all" | TransactionType) => void; onQuery: (value: string) => void; onClearCategory: () => void; onOpenCategory: (id: string) => void; onSelectTransaction: (transaction: Transaction) => void;
}) {
  const savingsRate = totals.income ? Math.round(((totals.income - totals.expense) / totals.income) * 100) : 0;
  const selectedCategory = categories.find((category) => category.id === categoryFilterId);
  const expenseTopCategories = categories.filter((c) => c.type === "expense" && !c.parentId);
  const plannedBudget = expenseTopCategories.reduce((sum, category) => sum + category.monthlyBudget, 0);

  return <>
    <header className="page-header"><div><div className="page-kicker">Personal finance, considered</div><h1>Keep the whole picture<br />in view.</h1><p className="page-subtitle">A clear fieldbook for the money that moves your days.</p></div></header>
    <div className="dashboard-grid">
      <div>
        <section className="balance-card">
          <img className="balance-art" src="https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&q=80&w=1200" alt="Editorial ledger still life" />
          <div className="balance-content">
            <div className="balance-label"><span /> Available balance</div>
            <div className="balance-number">{fmt.format(balance)}</div>
            <p className="balance-caption">Across your asset accounts, with liabilities held apart for a truthful net worth.</p>
            <div className="balance-foot"><div><span>Income, August</span><strong>{fmt.format(totals.income)}</strong></div><div><span>Expenses, August</span><strong>{fmt.format(totals.expense)}</strong></div></div>
          </div>
        </section>
        <div className="summary-strip">
          <article className="mini-stat"><div className="stat-top">Inflow <span className="stat-icon up"><ArrowDownRight size={14} /></span></div><strong>{fmt.format(totals.income)}</strong><p>Derived from monthly income</p></article>
          <article className="mini-stat"><div className="stat-top">Outflow <span className="stat-icon down"><ArrowUpRight size={14} /></span></div><strong>{fmt.format(totals.expense)}</strong><p>Derived from recorded expenses</p></article>
          <article className="mini-stat"><div className="stat-top">Savings rate <span className="stat-icon gold"><CheckCircle2 size={14} /></span></div><strong>{savingsRate}%</strong><p>Transfers stay neutral</p></article>
        </div>
      </div>
      <aside className="paper-card side-summary">
        <div className="card-head"><h2>Net worth</h2><span className="text-link">Assets − debts</span></div>
        <div className="net-worth"><div className="net-worth-value">{fmt.format(netWorth)}</div><span className="change-tag"><ArrowUpRight size={11} /> calculated from accounts</span></div>
        <div className="account-list">{accounts.map((account) => <div className={`account-row ${account.kind === "liability" ? "liability" : ""}`} key={account.id}><div className="account-left"><i className="account-dot" style={{ background: account.color }} />{account.name} <small style={{ color: "#888", display: "block" }}>{account.accountNumber}</small></div><strong>{account.kind === "liability" ? `${fmt.format(account.balance)} owed` : fmt.format(account.balance)}</strong></div>)}</div>
      </aside>
    </div>
    <section className="paper-card month-hand-section">
      <div className="section-head month-hand-head"><div><div className="page-kicker">Monthly allocation</div><h2>Month in hand</h2></div><span className="month-hand-date">August 2026</span></div>
      <div className="month-hand-grid">
        <div className="month-hand-summary">
          <div className="field-note"><div className="field-note-row"><span>Allocated capital</span><b>{fmt.format(plannedBudget)}</b></div><div className="field-note-row"><span>Expense entries</span><b>{transactions.filter((transaction) => transaction.type === "expense").length} records</b></div></div>
          <p className="budget-note">A single view of this month’s planned capital, recorded outflow, and category-level pressure.</p>
        </div>
        <div className="month-hand-progress">
          <div className="budget-meter"><div className="budget-label"><span>Planned spending</span><span>{fmt.format(totals.expense)} / {fmt.format(plannedBudget)}</span></div><div className="budget-track"><div className="budget-fill" style={{ width: `${Math.min(100, plannedBudget ? (totals.expense / plannedBudget) * 100 : 0)}%` }} /></div></div>
          <div className="month-hand-progress-note"><strong>{plannedBudget ? Math.round((totals.expense / plannedBudget) * 100) : 0}% committed</strong><span>Transfers remain neutral.</span></div>
        </div>
      </div>
      <div className="upcoming-list month-category-pulse"><div className="upcoming-title">Category pulse · tap a category to inspect its ledger</div>{expenseTopCategories.slice(0, 4).map((category) => <button className="upcoming-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><span>{category.name}</span><b>{fmt.format(categorySpent[category.id] ?? 0)}</b><strong>of {fmt.format(category.monthlyBudget)}</strong></button>)}</div>
    </section>
    <div className="lower-grid">
      <section className="paper-card section-card">
        <div className="section-head"><h2>{selectedCategory ? `${selectedCategory.name} ledger` : "Recent ledger"}</h2><div className="filter-row">{(["all", "expense", "income", "transfer"] as const).map((item) => <button key={item} className={`filter-button ${filter === item ? "active" : ""}`} onClick={() => onFilter(item)}>{item[0].toUpperCase() + item.slice(1)}</button>)}</div></div>
        {selectedCategory && <button className="filter-note" onClick={onClearCategory}>Viewing {selectedCategory.name} <X size={12} /></button>}
        <div className="search-box"><Search size={15} /><input value={query} onChange={(event) => onQuery(event.target.value)} placeholder="Search a merchant or category" /></div>
        <div className="transaction-list">{transactions.length ? transactions.map((transaction) => <TransactionRow key={transaction.id} transaction={transaction} categories={categories} onSelect={onSelectTransaction} />) : <p className="budget-note">No entries match this view. Try another filter or clear the category context.</p>}</div>
      </section>
    </div>
  </>;
}

function TransactionRow({ transaction, categories, onSelect }: { transaction: Transaction; categories: Category[]; onSelect: (transaction: Transaction) => void }) {
  const category = categories.find((item) => item.id === transaction.categoryId);
  const descriptor = transaction.type === "transfer" ? "Transfer between your accounts" : category?.name ?? "Uncategorised";
  const signed = transaction.type === "income" ? "+" : transaction.type === "expense" ? "−" : "↔";
  const amountClass = transaction.type === "income" ? "amount-income" : transaction.type === "expense" ? "amount-expense" : "amount-transfer";
  return <button className="transaction-row transaction-button" onClick={() => onSelect(transaction)}><div className="transaction-title"><strong>{transaction.merchantNote}</strong><span>{descriptor}{transaction.tag?.goalId ? " · Goal tagged" : ""}{transaction.tag?.tripId ? " · Trip tagged" : ""}</span></div><div className="transaction-amount"><strong className={amountClass}>{signed}{fmt.format(transaction.amount)}</strong><span>{transaction.date}</span></div></button>;
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
  return <>
    <header className="page-header stats-page-header"><div><div className="page-kicker">Analytics & patterns</div><h1>Spending insight<br />& category mix.</h1><p className="page-subtitle">Understand where capital concentrates over time.</p></div><div className="stats-tabs" role="tablist" aria-label="Stats view"><button className={`filter-button ${statsTab === "insight" ? "active" : ""}`} onClick={() => setStatsTab("insight")}>Insight</button><button className={`filter-button ${statsTab === "summary" ? "active" : ""}`} onClick={() => setStatsTab("summary")}>Summary</button></div></header>
    {statsTab === "insight" ? <div className="insights-grid"><article className="paper-card section-card"><h2>Six-month cash flow</h2><div className="trend-chart">{months.map((month) => <div className="trend-column" key={month.label}><div className="bars"><div className="bar income" style={{ height: `${(month.income / max) * 100}%` }} /><div className="bar expense" style={{ height: `${(month.expense / max) * 100}%` }} /></div><span>{month.label}</span></div>)}</div><div className="chart-legend"><div><span className="dot income" /> Inflow</div><div><span className="dot expense" /> Outflow</div></div></article><aside className="paper-card side-summary"><div className="card-head"><h2>Category mix</h2><span className="text-link">Tap a slice</span></div><div className="donut-ring" onClick={() => mix[0] && onOpenCategory(mix[0].id)} style={{ background: stops.gradient ? `conic-gradient(${stops.gradient})` : "#ded8ca" }}><div className="donut-hole"><strong>{fmt.format(spent)}</strong><span>Total out</span></div></div><div className="category-mix-list">{expenseTopCategories.map((category) => <button className="mix-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><div><i className="account-dot" style={{ background: category.color }} /><strong>{category.name}</strong></div><b>{fmt.format(categorySpent[category.id] ?? 0)}</b></button>)}</div></aside></div> : <div className="summary-view-grid"><article className="paper-card summary-hero"><div className="page-kicker">Monthly summary</div><h2>Net savings</h2><strong>{fmt.format(incomeTotal - expenseTotal)}</strong><p>Income less recorded expenses. Transfers stay outside this calculation.</p></article><section className="paper-card summary-breakdown"><div className="section-head"><h2>Category breakdown</h2><span className="month-hand-date">August 2026</span></div>{expenseTopCategories.map((category) => { const value = categorySpent[category.id] ?? 0; const base = category.monthlyBudget || Math.max(value, 1); return <button className="summary-category-row category-trigger" key={category.id} onClick={() => onOpenCategory(category.id)}><div><span><i className="account-dot" style={{ background: category.color }} />{category.name}</span><b>{fmt.format(value)} <em>of {fmt.format(category.monthlyBudget)}</em></b></div><div className="progress-track"><div className="progress-fill" style={{ width: `${Math.min(100, (value / base) * 100)}%`, background: category.color }} /></div></button>; })}</section></div>}
  </>;
}

function HorizonView({ goals, trips, onOpenAddGoal, onOpenAddTrip }: { goals: Goal[]; trips: Trip[]; onOpenAddGoal: () => void; onOpenAddTrip: () => void }) {
  const [horizonTab, setHorizonTab] = useState<"goals" | "trips">("goals");
  return (
    <>
      <section className="horizon-hero">
        <div className="horizon-hero-text">
          <div className="page-kicker">Horizon</div>
          <h1>Fund what<br />matters next.</h1>
          <p>Goals and trips stay connected to the same transactions you already trust.</p>
          <div className="horizon-actions">
            <button className={`filter-button ${horizonTab === "goals" ? "active" : ""}`} onClick={() => setHorizonTab("goals")}>Savings goals</button>
            <button className={`filter-button ${horizonTab === "trips" ? "active" : ""}`} onClick={() => setHorizonTab("trips")}>Trip & event plans</button>
          </div>
        </div>
        <button className="primary-button" onClick={horizonTab === "goals" ? onOpenAddGoal : onOpenAddTrip}>
          <Plus size={15} /> {horizonTab === "goals" ? "Add savings goal" : "Add trip plan"}
        </button>
      </section>

      {horizonTab === "goals" && (
        <div style={{ display: "grid", gap: 16 }}>
          {goals.map((goal) => {
            const pct = Math.min(100, Math.round((goal.saved / goal.target) * 100));
            return (
              <article key={goal.id} className="paper-card" style={{ padding: 24 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                  <div>
                    <span style={{ fontSize: 11, textTransform: "uppercase", letterSpacing: "0.08em", color: "#8c6d36", display: "block", marginBottom: 4 }}>{goal.deadline}</span>
                    <h3 style={{ fontSize: 20, fontFamily: "Fraunces, serif" }}>{goal.name}</h3>
                  </div>
                  <strong style={{ fontSize: 18, fontFamily: "Space Grotesk, sans-serif" }}>{fmt.format(goal.saved)} <span style={{ fontSize: 13, color: "#777", fontWeight: 400 }}>of {fmt.format(goal.target)}</span></strong>
                </div>
                <div className="budget-track" style={{ height: 10, borderRadius: 5, background: "#ede7d6" }}>
                  <div className="budget-fill" style={{ width: `${pct}%`, background: "#b78a3d", borderRadius: 5 }} />
                </div>
                <div style={{ display: "flex", justifyContent: "space-between", fontSize: 13, color: "#666", marginTop: 8 }}>
                  <span>{pct}% held aside</span>
                  <span>{fmt.format(goal.target - goal.saved)} to go</span>
                </div>
              </article>
            );
          })}
        </div>
      )}

      {horizonTab === "trips" && (
        <div style={{ display: "grid", gap: 16 }}>
          {trips.map((trip) => (
            <article key={trip.id} className="paper-card" style={{ padding: 24 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                <div>
                  <span style={{ fontSize: 11, textTransform: "uppercase", letterSpacing: "0.08em", color: "#8c6d36", display: "block", marginBottom: 4 }}>{trip.dates}</span>
                  <h3 style={{ fontSize: 20, fontFamily: "Fraunces, serif" }}>{trip.name}</h3>
                </div>
                <strong style={{ fontSize: 18, fontFamily: "Space Grotesk, sans-serif" }}>Working budget: {fmt.format(trip.budget)}</strong>
              </div>
              <p style={{ color: "#666", fontSize: 14 }}>Linked expenses tagged with this trip automatically accumulate against this ceiling.</p>
            </article>
          ))}
        </div>
      )}
    </>
  );
}

function SettingsView({ accounts, categories, subcategorySpent, onOpenAddAccount, onOpenAddCategory, onOpenAddIncomeCategory, onOpenAddSub, onDeleteCategory }: {
  accounts: Account[]; categories: Category[]; subcategorySpent: Record<string, number>;
  onOpenAddAccount: () => void; onOpenAddCategory: () => void; onOpenAddIncomeCategory: () => void; onOpenAddSub: (parentId: string) => void; onDeleteCategory: (id: string) => void;
}) {
  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeList = categories.filter((c) => c.type === "income");

  return (
    <>
      <header className="page-header"><div><div className="page-kicker">Preferences & taxonomy</div><h1>Settings & accounts.</h1><p className="page-subtitle">Manage asset nodes, expense hierarchies, and income streams.</p></div></header>
      <div style={{ display: "grid", gap: 24 }}>
        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <div className="section-head" style={{ marginBottom: 16 }}>
            <h2>Accounts, Assets & Liabilities</h2>
            <button className="add-button" onClick={onOpenAddAccount}><Plus size={15} /><span>Add account</span></button>
          </div>
          <div style={{ display: "grid", gap: 12 }}>
            {accounts.map((acc) => (
              <div key={acc.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 16px", background: "#fcfaf6", border: "1px solid #ded8ca", borderRadius: 12 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  <i className="account-dot" style={{ background: acc.color, width: 12, height: 12, borderRadius: "50%", display: "inline-block" }} />
                  <div>
                    <strong style={{ fontSize: 15, fontFamily: "Space Grotesk, sans-serif", display: "block" }}>{acc.name}</strong>
                    <span style={{ color: "#777", fontSize: 12 }}>{acc.kind === "asset" ? "Asset / Bank account" : "Liability / Debt"} · {acc.accountNumber}</span>
                  </div>
                </div>
                <strong style={{ fontSize: 16, fontFamily: "Space Grotesk, sans-serif" }}>{acc.kind === "liability" ? `${fmt.format(acc.balance)} owed` : fmt.format(accountBalance(acc))}</strong>
              </div>
            ))}
          </div>
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <div className="section-head" style={{ marginBottom: 16 }}>
            <h2>Expense Categories ({expenseTop.length})</h2>
            <button className="add-button" onClick={onOpenAddCategory}><Plus size={15} /><span>Add expense category</span></button>
          </div>
          <div className="category-edit-list" style={{ display: "grid", gap: 12 }}>
            {expenseTop.map((cat) => {
              const subs = categories.filter((c) => c.parentId === cat.id);
              return (
                <div key={cat.id} className="category-group-row" style={{ background: "#fcfaf6", border: "1px solid #ded8ca", borderRadius: 12, padding: 14 }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span className="cat-marker" style={{ background: cat.color, width: 10, height: 10, borderRadius: "50%", display: "inline-block" }} />
                      <strong style={{ fontSize: 15 }}>{cat.name}</strong>
                      <span className="cat-budget-tag" style={{ fontSize: 12, color: "#666", background: "#eee", padding: "2px 8px", borderRadius: 6 }}>Budget: {fmt.format(cat.monthlyBudget)}</span>
                    </div>
                    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <button className="secondary-button" style={{ fontSize: 11, padding: "6px 10px" }} onClick={() => onOpenAddSub(cat.id)}><FolderPlus size={13} /> Add subcategory</button>
                      <button className="delete-button" onClick={() => onDeleteCategory(cat.id)}><Trash2 size={13} /></button>
                    </div>
                  </div>
                  {subs.length > 0 && (
                    <div style={{ marginTop: 10, paddingLeft: 20, display: "grid", gap: 6, borderLeft: "2px solid #e3dec9" }}>
                      {subs.map((sub) => (
                        <div key={sub.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", fontSize: 13, color: "#555" }}>
                          <span>↳ {sub.name}</span>
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
          </div>
        </article>

        <article className="paper-card settings-card" style={{ padding: 24 }}>
          <div className="section-head" style={{ marginBottom: 16 }}>
            <h2>Income Sources ({incomeList.length})</h2>
            <button className="add-button" onClick={onOpenAddIncomeCategory}><Plus size={15} /><span>Add income category</span></button>
          </div>
          <div className="category-edit-list" style={{ display: "grid", gap: 10 }}>
            {incomeList.map((inc) => (
              <div key={inc.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 16px", background: "#fcfaf6", border: "1px solid #ded8ca", borderRadius: 12 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <span className="cat-marker" style={{ background: inc.color, width: 10, height: 10, borderRadius: "50%", display: "inline-block" }} />
                  <strong style={{ fontSize: 15 }}>{inc.name}</strong>
                </div>
                <button className="delete-button" onClick={() => onDeleteCategory(inc.id)}><Trash2 size={13} /></button>
              </div>
            ))}
          </div>
        </article>
      </div>
    </>
  );
}

function accountBalance(acc: Account) {
  return acc.balance;
}

function DraftPanel({ kind, title, amount, dateVal, transaction, accounts, categories, goals, trips, catName, catBudget, catType, parentTarget, subName, accName, accKind, accBalance, accNumber, onTitle, onAmount, onDate, onTransaction, onCatName, onCatBudget, onCatType, onParentTarget, onSubName, onAccName, onAccKind, onAccBalance, onAccNumber, onClose, onSave, onOpenAddSub }: {
  kind: Exclude<DraftKind, null | "profile">; title: string; amount: string; dateVal: string; transaction: TransactionDraft; accounts: Account[]; categories: Category[]; goals: Goal[]; trips: Trip[]; catName: string; catBudget: string; catType: "expense" | "income"; parentTarget: string; subName: string; accName: string; accKind: "asset" | "liability"; accBalance: string; accNumber: string;
  onTitle: (value: string) => void; onAmount: (value: string) => void; onDate: (value: string) => void; onTransaction: (value: TransactionDraft | ((current: TransactionDraft) => TransactionDraft)) => void; onCatName: (value: string) => void; onCatBudget: (value: string) => void; onCatType: (value: "expense" | "income") => void; onParentTarget: (value: string) => void; onSubName: (value: string) => void; onAccName: (value: string) => void; onAccKind: (value: "asset" | "liability") => void; onAccBalance: (value: string) => void; onAccNumber: (value: string) => void; onClose: () => void; onSave: () => void; onOpenAddSub: (parentId: string) => void;
}) {
  const heading = kind === "transaction" ? (transaction.id ? "Edit transaction" : "Draft a transaction") : kind === "goal" ? "Set a new savings goal" : kind === "trip" ? "Plan a trip or event" : kind === "category" ? (catType === "expense" ? "Add expense category" : "Add income category") : kind === "subcategory" ? "Add subcategory" : "Add bank account or asset";
  const descriptor = kind === "transaction" ? "Record, recategorise, or correct a money movement." : kind === "goal" ? "Give future money a purpose with a clear target." : kind === "trip" ? "Set a budget ceiling before you travel." : kind === "category" ? "Organise your spending or income streams." : kind === "subcategory" ? "Add precise granularity under an expense category." : "Register an asset, bank, or credit liability.";
  const update = (patch: Partial<TransactionDraft>) => onTransaction((current) => ({ ...current, ...patch }));

  const expenseTop = categories.filter((c) => c.type === "expense" && !c.parentId);
  const incomeList = categories.filter((c) => c.type === "income");

  const [selectedParentId, setSelectedParentId] = useState<string>(expenseTop[0]?.id ?? "");

  return (
    <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={heading} onMouseDown={onClose}>
      <aside className="draft-panel" onMouseDown={(event) => event.stopPropagation()}>
        <div className="draft-top"><div><div className="draft-kicker">{descriptor}</div><h2>{heading}</h2></div><button className="close-button" onClick={onClose} aria-label="Close"><X size={17} /></button></div>
        
        {kind === "transaction" && <>
          <div className="form-field"><label>Movement</label><div className="type-options">{(["expense", "income", "transfer"] as const).map((type) => <button key={type} className={`type-option ${transaction.type === type ? "active" : ""}`} onClick={() => update({ type, categoryId: type === "income" ? (incomeList[0]?.id ?? "income-salary") : "food-groceries" })}>{type[0].toUpperCase() + type.slice(1)}</button>)}</div></div>
          <div className="form-field"><label>Merchant or note</label><input value={transaction.merchantNote} onChange={(event) => update({ merchantNote: event.target.value })} placeholder={transaction.type === "transfer" ? "e.g. Contribution to reserve" : "e.g. Sunday market"} autoFocus /></div>
          <div className="form-field"><label>Amount</label><input value={transaction.amount} onChange={(event) => update({ amount: event.target.value.replace(/[^0-9.]/g, "") })} placeholder="0.00" inputMode="decimal" /></div>
          <div className="form-field"><label>{transaction.type === "transfer" ? "From account" : "Account"}</label><select value={transaction.accountId} onChange={(event) => update({ accountId: event.target.value })}>{accounts.map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>
          {transaction.type === "transfer" && <div className="form-field"><label>To account</label><select value={transaction.destinationAccountId} onChange={(event) => update({ destinationAccountId: event.target.value })}>{accounts.filter((account) => account.id !== transaction.accountId).map((account) => <option value={account.id} key={account.id}>{account.name} · {account.kind}</option>)}</select></div>}
          
          {transaction.type === "expense" && (
            <div className="form-field">
              <label>Category (Expense)</label>
              <select value={transaction.categoryId} onChange={(event) => update({ categoryId: event.target.value })}>
                {expenseTop.map((top) => {
                  const subs = categories.filter((c) => c.parentId === top.id);
                  return (
                    <React.Fragment key={top.id}>
                      <option value={top.id}>📂 {top.name} (Top level)</option>
                      {subs.map((sub) => (
                        <option value={sub.id} key={sub.id}>&nbsp;&nbsp;&nbsp;&nbsp;↳ {sub.name}</option>
                      ))}
                    </React.Fragment>
                  );
                })}
              </select>
              <div style={{ marginTop: 8 }}>
                <button type="button" className="text-link" style={{ fontSize: 12, display: "inline-flex", alignItems: "center", gap: 4 }} onClick={() => {
                  const parentId = transaction.categoryId && categories.find(c => c.id === transaction.categoryId)?.parentId ? categories.find(c => c.id === transaction.categoryId)!.parentId! : expenseTop[0]?.id;
                  if (parentId) onOpenAddSub(parentId);
                }}>
                  <FolderPlus size={13} /> + Create new subcategory under selected category
                </button>
              </div>
            </div>
          )}

          {transaction.type === "income" && (
            <div className="form-field">
              <label>Category (Income)</label>
              <select value={transaction.categoryId} onChange={(event) => update({ categoryId: event.target.value })}>
                {incomeList.map((inc) => <option value={inc.id} key={inc.id}>{inc.name}</option>)}
              </select>
            </div>
          )}

          <div className="form-field"><label>Date</label><input type="date" value={transaction.date} onChange={(event) => update({ date: event.target.value })} /></div>
          <div className="tag-grid"><div className="form-field"><label>Goal tag</label><select value={transaction.goalId} onChange={(event) => update({ goalId: event.target.value })}><option value="none">No goal</option>{goals.map((goal) => <option value={goal.id} key={goal.id}>{goal.name}</option>)}</select></div><div className="form-field"><label>Trip tag</label><select value={transaction.tripId} onChange={(event) => update({ tripId: event.target.value })}><option value="none">No trip</option>{trips.map((trip) => <option value={trip.id} key={trip.id}>{trip.name}</option>)}</select></div></div>
        </>}

        {kind === "goal" && <>
          <div className="form-field"><label>Goal title</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Home reserve" autoFocus /></div>
          <div className="form-field"><label>Target amount</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="5,000" inputMode="decimal" /></div>
          <div className="form-field"><label>Target timeline</label><input value={dateVal} onChange={(event) => onDate(event.target.value)} placeholder="e.g. By Dec 2026" /></div>
        </>}

        {kind === "trip" && <>
          <div className="form-field"><label>Plan name</label><input value={title} onChange={(event) => onTitle(event.target.value)} placeholder="e.g. Autumn in Lisbon" autoFocus /></div>
          <div className="form-field"><label>Working budget</label><input value={amount} onChange={(event) => onAmount(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="1,200" inputMode="decimal" /></div>
          <div className="form-field"><label>Dates</label><input value={dateVal} onChange={(event) => onDate(event.target.value)} placeholder="e.g. 12–19 Oct 2026" /></div>
        </>}

        {kind === "category" && <>
          <div className="form-field"><label>Type</label><div className="type-options"><button className={`type-option ${catType === "expense" ? "active" : ""}`} onClick={() => onCatType("expense")}>Expense</button><button className={`type-option ${catType === "income" ? "active" : ""}`} onClick={() => onCatType("income")}>Income</button></div></div>
          <div className="form-field"><label>{catType === "income" ? "Income category name" : "Category name"}</label><input value={catName} onChange={(event) => onCatName(event.target.value)} placeholder={catType === "income" ? "e.g. Rental yield or Bonus" : "e.g. Wellness"} autoFocus /></div>
          {catType === "expense" && <div className="form-field"><label>Monthly budget</label><input value={catBudget} onChange={(event) => onCatBudget(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="400" inputMode="decimal" /></div>}
        </>}

        {kind === "subcategory" && <>
          <div className="form-field"><label>Parent category</label><select value={parentTarget || expenseTop[0]?.id} onChange={(event) => onParentTarget(event.target.value)}>{expenseTop.map((top) => <option value={top.id} key={top.id}>{top.name}</option>)}</select></div>
          <div className="form-field"><label>Subcategory name</label><input value={subName} onChange={(event) => onSubName(event.target.value)} placeholder="e.g. Specialty coffee" autoFocus /></div>
        </>}

        {kind === "account" && <>
          <div className="form-field"><label>Account kind</label><div className="type-options"><button className={`type-option ${accKind === "asset" ? "active" : ""}`} onClick={() => onAccKind("asset")}>Asset / Bank</button><button className={`type-option ${accKind === "liability" ? "active" : ""}`} onClick={() => onAccKind("liability")}>Liability / Debt</button></div></div>
          <div className="form-field"><label>Account name</label><input value={accName} onChange={(event) => onAccName(event.target.value)} placeholder="e.g. Savings or Investment Portfolio" autoFocus /></div>
          <div className="form-field"><label>Starting balance</label><input value={accBalance} onChange={(event) => onAccBalance(event.target.value.replace(/[^0-9.]/g, ""))} placeholder="2500" inputMode="decimal" /></div>
          <div className="form-field"><label>Masked number / Ref</label><input value={accNumber} onChange={(event) => onAccNumber(event.target.value)} placeholder="e.g. ··· 9912" /></div>
        </>}

        <div className="draft-actions">
          <button className="primary-button draft-submit" onClick={onSave}>{kind === "transaction" ? (transaction.id ? "Save changes" : "Save entry") : kind === "goal" ? "Create goal" : kind === "trip" ? "Create plan" : kind === "category" ? "Add category" : kind === "subcategory" ? "Add subcategory" : "Save account"}</button>
          <button className="secondary-button" onClick={onClose}>Cancel</button>
        </div>
      </aside>
    </div>
  );
}

function shortDate(dateStr: string) {
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  } catch {
    return dateStr;
  }
}
