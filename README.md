# FinMann

> A personal finance tracker built for students — log transactions, set budgets, track savings goals, and understand your spending habits.

---

## What is this?

FinMann is a Flutter mobile app designed specifically around the financial reality of students. Most finance apps are built for salaried adults managing investments and EMIs. FinMann focuses on the things students actually deal with — mess bills, Swiggy orders, Uber rides, college fees, monthly allowances, and the slow creep of small purchases that quietly drain a wallet.

The app works completely offline. No account sync, no internet required. Your data lives on your device in a local SQLite database.

---

## Features

### Core
- **Add income & expense transactions** — with category, amount, date, and an optional note
- **Quick Add (NLP)** — type naturally: `"spent 200 on food"` or `"got 5000 allowance"` and the app parses it into a transaction automatically
- **Transaction history** — filterable by income / expense, swipe to delete, tap to edit

### Budgets
- Set monthly spending limits per category (Food, Transport, Entertainment, etc.)
- Live progress bars that turn yellow at 70% and red at 90%
- Overspend alerts showing exactly how much you've gone over

### Savings Goals
- Create goals with a name, emoji, and target amount (e.g. 💻 New Laptop — ₹55,000)
- Animated progress rings that fill as you log savings
- Add money toward any goal incrementally

### Analytics
- **Overview tab** — pie chart of expense breakdown by category + animated category bars
- **Trends tab** — 6-month grouped bar chart comparing income vs expense month by month
- **Spending velocity card** — calculates your daily burn rate and projects your end-of-month total, warns you if you're on track to overspend

---

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform, single codebase for iOS + Android |
| Architecture | BLoC | Predictable state, testable, scales well |
| Local DB | SQLite (`sqflite`) | Offline-first, no backend needed |
| State | `flutter_bloc` + `equatable` | Clean event → state flow |
| DI | `get_it` | Lightweight service locator |
| Charts | `fl_chart` | Smooth, customizable pie + bar charts |
| Animations | `flutter_animate` | Declarative, chainable animations |
| Fonts | `google_fonts` | Space Grotesk (headings) + DM Sans (body) |

---

## Project structure

```
lib/
├── core/
│   ├── constants/        # Category lists, icons, DB config
│   ├── di/               # Service locator (get_it)
│   ├── theme/            # AppColors, AppTheme, typography
│   └── utils/            # Currency formatter, date formatter, NLP parser, router
│
├── data/
│   ├── datasources/      # LocalDatabase (SQLite setup + migrations)
│   ├── models/           # UserModel, TransactionModel, BudgetModel, GoalModel
│   └── repositories/     # AuthRepository, TransactionRepository, BudgetRepository, GoalRepository
│
└── presentation/
    ├── blocs/
    │   ├── auth/         # AuthBloc — login, register, logout
    │   └── transaction/  # TransactionBloc — load, add, edit, delete
    ├── screens/
    │   ├── auth/         # LoginScreen, RegisterScreen
    │   ├── dashboard/    # HomeScreen, DashboardTab
    │   ├── transactions/ # TransactionsTab, AddTransactionSheet, NlpInputSheet
    │   ├── goals/        # GoalsTab
    │   └── analytics/    # AnalyticsTab
    └── widgets/
        ├── charts/       # GoalRing, VelocityCard, BudgetBar
        ├── common/       # FmButton, FmTextField, FmCard, AmountBadge, GradientText
        └── nav/          # AnimatedBottomNav
```

---

## Architecture

FinMann follows a strict BLoC pattern. The data flow is one-directional:

```
UI Widget
  → dispatches Event
    → BLoC processes logic
      → calls Repository
        → Repository talks to SQLite
      → BLoC emits new State
    → UI rebuilds from State
```

BLoCs never touch UI. Widgets never contain business logic. Repositories are the only layer that knows about the database. This makes every piece independently testable and easy to swap out (e.g. replacing SQLite with Supabase later requires only changing the repository layer).

---

## Screens

| Screen | Description |
|---|---|
| Login / Register | Email + password auth stored locally with a simple hash |
| Dashboard | Balance hero card, quick-add buttons, velocity card, budgets, recent transactions |
| Transactions | Full history with income/expense filter, swipe-to-delete, tap-to-edit |
| Goals | Savings goals with animated rings, emoji picker, incremental savings |
| Analytics | Pie chart, category bars, 6-month bar chart, auto-generated insights |

---

## Getting started

**Requirements**
- Flutter SDK 3.0+
- Dart 3.0+
- Xcode (iOS) or Android Studio (Android)

**Run**

```bash
git clone https://github.com/your-username/finmann.git
cd finmann
flutter pub get
flutter run
```

No `.env` file, no API keys, no backend setup. It runs immediately.

---

## Commit history

The project was built in three deliberate stages:

| Stage | Commit | What was built |
|---|---|---|
| 1 | `init: project scaffold, theme, DB, auth + transaction layer` | Core infrastructure — theme, SQLite schema, repositories, DI |
| 2 | `feat: auth, dashboard, transactions, analytics screens` | Working MVP — all screens, BLoC wiring, reusable widgets |
| 3 | `feat: budgets, goals, NLP input, UI/UX overhaul` | Differentiating features, animations, charts upgrade |

---

## Design decisions

**Offline-first** — The app works with zero internet. All data is local SQLite. Cloud sync is a planned future feature (Supabase) but not required for the core use case.

**Student-specific categories** — Categories like Tuition & Fees, Mess/Canteen, Books & Stationery, and Allowance are first-class citizens, not afterthoughts.

**NLP input** — The biggest friction in any finance app is the moment of entry. Reducing it to a single text field that understands natural language makes the habit far easier to maintain.

**No gamification dark patterns** — The streak system and financial score planned for future phases are designed to reward consistency, not punish gaps.

---

## Roadmap

- [ ] Recurring transactions (auto-log monthly bills)
- [ ] Home screen widget showing current balance
- [ ] CSV / PDF export
- [ ] Supabase sync for multi-device support
- [ ] Receipt scanner (OCR photo → transaction)
- [ ] Annual Wrapped — Spotify-style year-end spending recap
- [ ] Peer benchmarks — anonymous comparison with other students

---

## Built by

Kamerade — CS student project.
Built with Flutter, BLoC, and a lot of ₹ signs.
