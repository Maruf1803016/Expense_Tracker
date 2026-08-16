/**
 * Ink & Ledger page: asymmetric ledger rail, warm paper surfaces, Fraunces framing,
 * and Space Grotesk numerical evidence. Do not dilute this page with generic dashboard styling.
 */
import { useMemo, useState } from "react";
import {
  ArrowDownRight,
  ArrowUpRight,
  BarChart3,
  Bell,
  CalendarDays,
  Check,
  ChevronDown,
  Compass,
  CreditCard,
  FileDown,
  Home as HomeIcon,
  Landmark,
  MoreHorizontal,
  Plane,
  Plus,
  ReceiptText,
  Search,
  Settings2,
  Sparkles,
  Target,
  WalletCards,
  X,
} from "lucide-react";

type Screen = "Overview" | "Insights" | "Horizon" | "Settings";
type DraftKind = "transaction" | "goal" | "trip" | null;
type Transaction = {
  id: number;
  title: string;
  category: string;
  amount: number;
  kind: "expense" | "income";
  date: string;
  icon: "food" | "income" | "travel" | "home" | "shopping";
  tripPlanId?: number;
};
type Goal = { id: number; name: string; saved: number; target: number; deadline: string; icon: "goal" | "home" };
type TripPlan = { id: number; name: string; spent: number; budget: number; dates: string; color: string };

const heroArt = "/manus-storage/expense-tracker-ledger-hero_27b9b2fb.jpg";
const journeyArt = "/manus-storage/expense-tracker-goal-journey_cd34055f.jpg";
const insightsTexture = "/manus-storage/expense-tracker-insights-texture_3642c4f1.jpg";
const ledgerMark = "/manus-storage/expense-tracker-ledger-mark_1d5d936c.png";

const seedTransactions: Transaction[] = [
  { id: 1, title: "Market & Morning", category: "Food & Dining", amount: 46.8, kind: "expense", date: "Today", icon: "food" },
  { id: 2, title: "Northline Studio", category: "Freelance income", amount: 1840, kind: "income", date: "Today", icon: "income" },
  { id: 3, title: "Rail tickets — Kyoto", category: "Spring Journey", amount: 126, kind: "expense", date: "Yesterday", icon: "travel", tripPlanId: 1 },
  { id: 4, title: "Studio Rent", category: "Home & Utilities", amount: 980, kind: "expense", date: "14 Aug", icon: "home" },
  { id: 5, title: "Field Notes", category: "Personal", amount: 18.5, kind: "expense", date: "13 Aug", icon: "shopping" },
];

const seedGoals: Goal[] = [
  { id: 1, name: "Quiet reserve", saved: 5680, target: 8000, deadline: "By Dec 2026", icon: "goal" },
  { id: 2, name: "A place of our own", saved: 12640, target: 25000, deadline: "By Jun 2027", icon: "home" },
];

const seedTripPlans: TripPlan[] = [
  { id: 1, name: "Spring Journey", spent: 886, budget: 1600, dates: "03–12 Apr 2027", color: "#b78a3d" },
  { id: 2, name: "Family weekend", spent: 214, budget: 640, dates: "18–20 Sep 2026", color: "#607b69" },
];

const navItems: { label: Screen; icon: typeof HomeIcon }[] = [
  { label: "Overview", icon: HomeIcon },
  { label: "Insights", icon: BarChart3 },
  { label: "Horizon", icon: Compass },
  { label: "Settings", icon: Settings2 },
];

const fmt = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 2 });

function TransactionGlyph({ type }: { type: Transaction["icon"] }) {
  const map = {
    food: { icon: ReceiptText, color: "#a86a53", bg: "#f8eee9" },
    income: { icon: ArrowDownRight, color: "#397147", bg: "#edf4ed" },
    travel: { icon: Plane, color: "#9b7430", bg: "#f8f0e2" },
    home: { icon: Landmark, color: "#677365", bg: "#edf0eb" },
    shopping: { icon: Sparkles, color: "#7c6688", bg: "#f1ecf4" },
  }[type];
  const Icon = map.icon;
  return <div className="transaction-icon" style={{ color: map.color, background: map.bg }}><Icon size={17} strokeWidth={1.85} /></div>;
}

function Progress({ value, color }: { value: number; color?: string }) {
  return <div className="progress-track"><div className="progress-fill" style={{ width: `${Math.min(100, value)}%`, background: color ?? "#b78a3d" }} /></div>;
}

export default function Home() {
  const [active, setActive] = useState<Screen>("Overview");
  const [horizon, setHorizon] = useState<"Goals" | "Plans">("Goals");
  const [draft, setDraft] = useState<DraftKind>(null);
  const [filter, setFilter] = useState<"all" | "expense" | "income">("all");
  const [query, setQuery] = useState("");
  const [transactions, setTransactions] = useState(seedTransactions);
  const [goals, setGoals] = useState(seedGoals);
  const [tripPlans, setTripPlans] = useState(seedTripPlans);
  const [draftTitle, setDraftTitle] = useState("");
  const [draftAmount, setDraftAmount] = useState("");
  const [draftType, setDraftType] = useState<"expense" | "income">("expense");

  const filteredTransactions = useMemo(() => transactions.filter((t) => {
    const matchesFilter = filter === "all" || t.kind === filter;
    const search = query.toLowerCase();
    return matchesFilter && (!search || t.title.toLowerCase().includes(search) || t.category.toLowerCase().includes(search));
  }), [transactions, filter, query]);

  const totals = useMemo(() => transactions.reduce((acc, t) => {
    if (t.kind === "income") acc.income += t.amount;
    else acc.expense += t.amount;
    return acc;
  }, { income: 6150, expense: 2346.7 }), [transactions]);

  const currentBalance = 8650 + totals.income - totals.expense;

  function resetDraft() {
    setDraft(null);
    setDraftTitle("");
    setDraftAmount("");
    setDraftType("expense");
  }

  function saveDraft() {
    const safeTitle = draftTitle.trim() || (draft === "goal" ? "New savings goal" : draft === "trip" ? "New trip plan" : "Untitled transaction");
    const amount = Number(draftAmount) || (draft === "trip" ? 1200 : draft === "goal" ? 5000 : 0);
    if (draft === "transaction") {
      setTransactions((current) => [{
        id: Date.now(), title: safeTitle, category: draftType === "income" ? "New income" : "Personal", amount,
        kind: draftType, date: "Just now", icon: draftType === "income" ? "income" : "shopping",
      }, ...current]);
    }
    if (draft === "goal") {
      setGoals((current) => [...current, { id: Date.now(), name: safeTitle, saved: 0, target: amount, deadline: "No deadline", icon: "goal" }]);
      setHorizon("Goals");
      setActive("Horizon");
    }
    if (draft === "trip") {
      setTripPlans((current) => [...current, { id: Date.now(), name: safeTitle, spent: 0, budget: amount, dates: "Dates to be set", color: "#c77c5f" }]);
      setHorizon("Plans");
      setActive("Horizon");
    }
    resetDraft();
  }

  function openContextualDraft() {
    setDraft(active === "Horizon" ? (horizon === "Goals" ? "goal" : "trip") : "transaction");
  }

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <img className="brand-mark" src={ledgerMark} alt="Expense Tracker ledger mark" />
          <div className="brand-word">Expense<small>Financial fieldbook</small></div>
        </div>
        <div className="rail-label">Your ledger</div>
        <nav className="rail-nav" aria-label="Primary navigation">
          {navItems.map(({ label, icon: Icon }) => (
            <button key={label} className={`rail-item ${active === label ? "active" : ""}`} onClick={() => setActive(label)}>
              <Icon size={18} strokeWidth={1.8} /><span>{label}</span>
            </button>
          ))}
        </nav>
        <div className="rail-bottom">
          <div className="month-card">
            <span className="eyebrow">August close</span>
            <strong>16 days left</strong>
            <p>You have used 54% of your planned monthly spend.</p>
          </div>
          <button className="rail-item" onClick={() => setActive("Settings")}><FileDown size={18} strokeWidth={1.8} /><span>Export ledger</span></button>
        </div>
      </aside>

      <main className="content">
        <div className="topline">
          <div className="date-stamp"><CalendarDays size={13} /> Friday, 16 August 2026</div>
          <div className="utility-actions">
            <button className="icon-button" aria-label="Notifications"><Bell size={17} strokeWidth={1.7} /></button>
            <button className="profile-dot" aria-label="Open profile">MM</button>
          </div>
        </div>

        <section className="page-enter" key={active}>
          {active === "Overview" && <OverviewView
            balance={currentBalance} totals={totals} transactions={filteredTransactions} filter={filter} query={query}
            onFilter={setFilter} onQuery={setQuery} onOpenDraft={() => setDraft("transaction")} />}
          {active === "Insights" && <InsightsView />}
          {active === "Horizon" && <HorizonView
            tab={horizon} onTab={setHorizon} goals={goals} plans={tripPlans}
            onCreateGoal={() => setDraft("goal")} onCreatePlan={() => setDraft("trip")} />}
          {active === "Settings" && <SettingsView />}
        </section>
      </main>

      <nav className="mobile-bar" aria-label="Mobile navigation">
        <button className={`mobile-item ${active === "Overview" ? "active" : ""}`} onClick={() => setActive("Overview")}><HomeIcon size={17} /><span>Overview</span></button>
        <button className={`mobile-item ${active === "Insights" ? "active" : ""}`} onClick={() => setActive("Insights")}><BarChart3 size={17} /><span>Insights</span></button>
        <button className="mobile-add" onClick={openContextualDraft} aria-label="Add entry"><Plus size={20} /></button>
        <button className={`mobile-item ${active === "Horizon" ? "active" : ""}`} onClick={() => setActive("Horizon")}><Compass size={17} /><span>Horizon</span></button>
        <button className={`mobile-item ${active === "Settings" ? "active" : ""}`} onClick={() => setActive("Settings")}><Settings2 size={17} /><span>Settings</span></button>
      </nav>

      {draft && <DraftPanel kind={draft} title={draftTitle} amount={draftAmount} transactionType={draftType} onTitle={setDraftTitle} onAmount={setDraftAmount} onType={setDraftType} onClose={resetDraft} onSave={saveDraft} />}
    </div>
  );
}

function OverviewView({ balance, totals, transactions, filter, query, onFilter, onQuery, onOpenDraft }: {
  balance: number; totals: { income: number; expense: number }; transactions: Transaction[]; filter: "all" | "expense" | "income"; query: string;
  onFilter: (v: "all" | "expense" | "income") => void; onQuery: (v: string) => void; onOpenDraft: () => void;
}) {
  const savingsRate = Math.round(((totals.income - totals.expense) / totals.income) * 100);
  return <>
    <header className="page-header">
      <div><div className="page-kicker">Personal finance, considered</div><h1>Keep the whole picture<br />in view.</h1><p className="page-subtitle">A clear fieldbook for the money that moves your days.</p></div>
      <button className="add-button" onClick={onOpenDraft}><Plus size={17} /><span>Add transaction</span></button>
    </header>
    <div className="dashboard-grid">
      <div>
        <section className="balance-card">
          <img className="balance-art" src={heroArt} alt="Editorial ledger still life" />
          <div className="balance-content">
            <div className="balance-label"><span /> Available balance</div>
            <div className="balance-number">{fmt.format(balance)}</div>
            <p className="balance-caption">Across three accounts, with your planned commitments already in view.</p>
            <div className="balance-foot"><div><span>Income, August</span><strong>{fmt.format(totals.income)}</strong></div><div><span>Expenses, August</span><strong>{fmt.format(totals.expense)}</strong></div></div>
          </div>
        </section>
        <div className="summary-strip">
          <article className="mini-stat"><div className="stat-top">Inflow <span className="stat-icon up"><ArrowDownRight size={14} /></span></div><strong>{fmt.format(totals.income)}</strong><p>Scheduled and received</p></article>
          <article className="mini-stat"><div className="stat-top">Outflow <span className="stat-icon down"><ArrowUpRight size={14} /></span></div><strong>{fmt.format(totals.expense)}</strong><p>Across 24 entries</p></article>
          <article className="mini-stat"><div className="stat-top">Savings rate <span className="stat-icon gold"><Target size={14} /></span></div><strong>{savingsRate}%</strong><p>On pace for your target</p></article>
        </div>
      </div>
      <aside className="paper-card side-summary">
        <div className="card-head"><h2>Net worth</h2><button className="text-link">Accounts</button></div>
        <div className="net-worth"><div className="net-worth-value">$18,906.40</div><span className="change-tag"><ArrowUpRight size={11} /> 5.8% this month</span></div>
        <div className="account-list">
          <div className="account-row"><div className="account-left"><i className="account-dot" style={{ background: "#b78a3d" }} /> Daily account</div><strong>$7,840.60</strong></div>
          <div className="account-row"><div className="account-left"><i className="account-dot" style={{ background: "#607b69" }} /> Reserve</div><strong>$8,650.00</strong></div>
          <div className="account-row"><div className="account-left"><i className="account-dot" style={{ background: "#c77c5f" }} /> Visa · 2481</div><strong>$2,415.80</strong></div>
        </div>
      </aside>
    </div>
    <div className="lower-grid">
      <section className="paper-card section-card">
        <div className="section-head"><h2>Recent ledger</h2><div className="filter-row">{(["all", "expense", "income"] as const).map((item) => <button key={item} className={`filter-button ${filter === item ? "active" : ""}`} onClick={() => onFilter(item)}>{item[0].toUpperCase() + item.slice(1)}</button>)}</div></div>
        <div className="search-box"><Search size={15} /><input value={query} onChange={(e) => onQuery(e.target.value)} placeholder="Search a merchant or category" /></div>
        <div className="transaction-list">{transactions.length ? transactions.map((t) => <TransactionRow key={t.id} transaction={t} />) : <p className="budget-note">No entries match this view. Try another filter or a broader search.</p>}</div>
      </section>
      <aside className="paper-card budget-card">
        <div className="section-head"><h2>Month in hand</h2><MoreHorizontal size={18} color="#8b8174" /></div>
        <div className="field-note"><div className="field-note-row"><span>Allocated capital</span><b>$3,600</b></div><div className="field-note-row"><span>Entries logged</span><b>24 records</b></div></div>
        <div className="budget-meter"><div className="budget-label"><span>Planned spending</span><span>$1,967 / $3,600</span></div><div className="budget-track"><div className="budget-fill" style={{ width: "54%" }} /></div></div>
        <p className="budget-note">Your remaining room is holding steady. Dining is the only category ahead of pace.</p>
        <div className="upcoming-list"><div className="upcoming-title">Upcoming</div><div className="upcoming-row"><span>18 Aug</span><b>Client retainer</b><strong>+$1,840</strong></div><div className="upcoming-row"><span>20 Aug</span><b>Internet & mobile</b><strong>−$88</strong></div></div>
      </aside>
    </div>
  </>;
}

function TransactionRow({ transaction }: { transaction: Transaction }) {
  return <div className="transaction-row"><TransactionGlyph type={transaction.icon} /><div className="transaction-title"><strong>{transaction.title}</strong><span>{transaction.category}{transaction.tripPlanId ? " · Trip plan" : ""}</span></div><div className="transaction-amount"><strong className={transaction.kind === "income" ? "amount-income" : "amount-expense"}>{transaction.kind === "income" ? "+" : "−"}{fmt.format(transaction.amount)}</strong><span>{transaction.date}</span></div></div>;
}

function InsightsView() {
  const months = [{ label: "Mar", income: 52, expense: 38 }, { label: "Apr", income: 62, expense: 42 }, { label: "May", income: 46, expense: 32 }, { label: "Jun", income: 75, expense: 43 }, { label: "Jul", income: 57, expense: 49 }, { label: "Aug", income: 82, expense: 44 }];
  return <>
    <header className="page-header"><div><div className="page-kicker">A quieter kind of clarity</div><h1>Patterns worth<br />noticing.</h1><p className="page-subtitle">Your spending, measured in habits rather than alarms.</p></div><button className="secondary-button"><CalendarDays size={15} /> Aug 2026 <ChevronDown size={14} /></button></header>
    <div className="insight-grid">
      <section className="paper-card chart-card"><div className="section-head"><h2>Cash flow</h2><span className="change-tag"><ArrowUpRight size={11} /> +12.4% net</span></div><p className="chart-caption">Income and expenses over the last six months.</p><div className="bars">{months.map((m) => <div className="bar-group" key={m.label}><div className="bar-pair"><i className="bar income" style={{ height: `${m.income}%` }} /><i className="bar expense" style={{ height: `${m.expense}%` }} /></div><span>{m.label}</span></div>)}</div><div className="legend"><span><i className="income-dot" /> Income</span><span><i className="expense-dot" /> Expenses</span></div><div className="analysis-paper"><div className="analysis-paper-copy"><b>August closing note</b>Income held steady while planned travel moved into the ledger.</div><img src={insightsTexture} alt="Abstract ledger analytics paper" /></div></section>
      <section className="paper-card category-card"><div className="section-head"><h2>Expense mix</h2><button className="text-link">Details</button></div><div className="donut-wrap"><div className="donut"><div className="donut-label"><strong>$2,346</strong><span>Spent</span></div></div></div><div className="category-line"><span><i className="cat-marker" style={{ background: "#b78a3d" }} />Food & dining</span><b>38%</b></div><div className="category-line"><span><i className="cat-marker" style={{ background: "#607b69" }} />Home & utility</span><b>25%</b></div><div className="category-line"><span><i className="cat-marker" style={{ background: "#c77c5f" }} />Travel</span><b>19%</b></div></section>
    </div>
    <section className="paper-card section-card" style={{ marginTop: 22 }}><div className="section-head"><h2>Budget performance</h2><span className="page-kicker" style={{ margin: 0 }}>August allocation</span></div><div className="horizon-grid"><BudgetLine label="Food & Dining" used={694} total={800} color="#b78a3d" /><BudgetLine label="Home & Utility" used={1068} total={1400} color="#607b69" /><BudgetLine label="Personal" used={205} total={400} color="#c77c5f" /><BudgetLine label="Travel" used={126} total={1000} color="#9a87a5" /></div></section>
  </>;
}

function BudgetLine({ label, used, total, color }: { label: string; used: number; total: number; color: string }) {
  return <div className="plan-card paper-card"><div className="plan-meta">{label}</div><h3>{fmt.format(used)}</h3><div className="plan-number"><span>of {fmt.format(total)} assigned</span></div><Progress value={(used / total) * 100} color={color} /><div className="plan-foot">{fmt.format(total - used)} remains this month</div></div>;
}

function HorizonView({ tab, onTab, goals, plans, onCreateGoal, onCreatePlan }: { tab: "Goals" | "Plans"; onTab: (v: "Goals" | "Plans") => void; goals: Goal[]; plans: TripPlan[]; onCreateGoal: () => void; onCreatePlan: () => void }) {
  return <>
    <section className="horizon-hero"><img src={journeyArt} alt="Travel planning and savings still life" /><div className="horizon-copy"><div className="page-kicker">Horizon</div><h1>Fund what<br />matters next.</h1><p>Give every future plan a visible place before the moment arrives.</p></div></section>
    <div className="horizon-tabs"><button className={`horizon-tab ${tab === "Goals" ? "active" : ""}`} onClick={() => onTab("Goals")}>Savings goals</button><button className={`horizon-tab ${tab === "Plans" ? "active" : ""}`} onClick={() => onTab("Plans")}>Trip & event plans</button></div>
    {tab === "Goals" ? <><div className="page-header" style={{ marginBottom: 16 }}><div><div className="page-kicker">Set aside with intention</div><h1 style={{ fontSize: "clamp(30px, 3.2vw, 46px)" }}>Your quiet reserves.</h1></div><button className="add-button" onClick={onCreateGoal}><Plus size={16} /><span>New goal</span></button></div><div className="horizon-grid">{goals.map((goal) => <GoalCard goal={goal} key={goal.id} />)}</div></> : <><div className="page-header" style={{ marginBottom: 16 }}><div><div className="page-kicker">Budget the memory, not the aftermath</div><h1 style={{ fontSize: "clamp(30px, 3.2vw, 46px)" }}>Plans with room to enjoy.</h1></div><button className="add-button" onClick={onCreatePlan}><Plus size={16} /><span>New plan</span></button></div><div className="horizon-grid">{plans.map((plan) => <TripCard plan={plan} key={plan.id} />)}</div></>}
  </>;
}

function GoalCard({ goal }: { goal: Goal }) {
  const Icon = goal.icon === "home" ? Landmark : Target; const progress = (goal.saved / goal.target) * 100;
  return <article className="paper-card plan-card"><div className="plan-icon"><Icon size={18} strokeWidth={1.7} /></div><div className="plan-meta">{goal.deadline}</div><h3>{goal.name}</h3><div className="plan-number">{fmt.format(goal.saved)} <span>of {fmt.format(goal.target)}</span></div><Progress value={progress} /><div className="plan-foot">{Math.round(progress)}% held aside · {fmt.format(goal.target - goal.saved)} to go</div></article>;
}
function TripCard({ plan }: { plan: TripPlan }) {
  const progress = (plan.spent / plan.budget) * 100;
  return <article className="paper-card plan-card"><div className="plan-icon" style={{ color: plan.color }}><Plane size={18} strokeWidth={1.7} /></div><div className="plan-meta">{plan.dates}</div><h3>{plan.name}</h3><div className="plan-number">{fmt.format(plan.spent)} <span>of {fmt.format(plan.budget)} spent</span></div><Progress value={progress} color={plan.color} /><div className="plan-foot">{fmt.format(plan.budget - plan.spent)} left for the experience</div></article>;
}

function SettingsView() {
  return <><header className="page-header"><div><div className="page-kicker">Housekeeping</div><h1>The ledger<br />behind the ledger.</h1><p className="page-subtitle">A considered place for the pieces that keep your records useful.</p></div></header><div className="settings-grid"><article className="paper-card settings-card"><div className="set-icon"><WalletCards size={19} /></div><h3>Accounts</h3><p>Three active accounts are keeping your daily balance and net worth in step.</p><button className="secondary-button">Manage accounts</button></article><article className="paper-card settings-card"><div className="set-icon"><CreditCard size={19} /></div><h3>Categories</h3><p>Food, home, travel, and personal categories shape the analysis you see each month.</p><button className="secondary-button">Edit categories</button></article><article className="paper-card settings-card"><div className="set-icon"><FileDown size={19} /></div><h3>Export data</h3><p>Prepare a CSV or an archival PDF when you want a copy beyond this workspace.</p><button className="secondary-button">Prepare export</button></article><article className="paper-card settings-card"><div className="set-icon"><Check size={19} /></div><h3>Monthly rhythm</h3><p>Your currency is USD. Budgets reset on the first day of every month.</p><button className="secondary-button">Review preferences</button></article></div></>;
}

function DraftPanel({ kind, title, amount, transactionType, onTitle, onAmount, onType, onClose, onSave }: { kind: Exclude<DraftKind, null>; title: string; amount: string; transactionType: "expense" | "income"; onTitle: (v: string) => void; onAmount: (v: string) => void; onType: (v: "expense" | "income") => void; onClose: () => void; onSave: () => void }) {
  const heading = kind === "transaction" ? "Draft a transaction" : kind === "goal" ? "Set a new goal" : "Plan the journey";
  const descriptor = kind === "transaction" ? "A record for money moving today." : kind === "goal" ? "Give future money a purpose." : "Set a ceiling before the memories start.";
  return <div className="draft-backdrop" role="dialog" aria-modal="true" aria-label={heading} onMouseDown={onClose}><aside className="draft-panel" onMouseDown={(e) => e.stopPropagation()}><div className="draft-top"><div><div className="draft-kicker">{descriptor}</div><h2>{heading}</h2></div><button className="close-button" onClick={onClose} aria-label="Close"><X size={17} /></button></div>{kind === "transaction" && <div className="form-field"><label>Movement</label><div className="type-options"><button className={`type-option ${transactionType === "expense" ? "active" : ""}`} onClick={() => onType("expense")}>Expense</button><button className={`type-option ${transactionType === "income" ? "active" : ""}`} onClick={() => onType("income")}>Income</button></div></div>}<div className="form-field"><label>{kind === "transaction" ? "Merchant or note" : kind === "goal" ? "Goal title" : "Plan name"}</label><input value={title} onChange={(e) => onTitle(e.target.value)} placeholder={kind === "transaction" ? "e.g. Sunday market" : kind === "goal" ? "e.g. Home reserve" : "e.g. Autumn in Lisbon"} autoFocus /></div><div className="form-field"><label>{kind === "transaction" ? "Amount" : kind === "goal" ? "Target amount" : "Working budget"}</label><input value={amount} onChange={(e) => onAmount(e.target.value.replace(/[^0-9.]/g, ""))} placeholder={kind === "transaction" ? "0.00" : kind === "goal" ? "5,000" : "1,200"} inputMode="decimal" /></div>{kind === "transaction" && <div className="form-field"><label>Account</label><select defaultValue="daily"><option value="daily">Daily account · 2481</option><option value="reserve">Reserve account</option><option value="visa">Visa · 2481</option></select></div>}<button className="primary-button draft-submit" onClick={onSave}>{kind === "transaction" ? "Save entry" : kind === "goal" ? "Create goal" : "Create plan"}</button></aside></div>;
}
