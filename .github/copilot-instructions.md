# Project Context: Ship Supply Management System (SSMS)

You are an expert AI pair programmer assisting in the development of a high-performance **Ship Supply ERP System**.

## 1. Project Architecture & Strategy

- **Core Philosophy:** A hybrid app where **Windows** is for heavy operations (Data Entry) and **iOS** is for management (Review/Approval).
- **Architecture:** - **Frontend:** Flutter (UI).
  - **Backend/Logic:** Rust (Business Logic, Calculations, DB Access).
  - **Bridge:** **`flutter_rust_bridge` (FRB)**. 
    - *CRITICAL:* Since iOS is a target, we CANNOT use separate executables (`Process.run`). All Rust code must be compiled as a static library and accessed via FFI.

## 2. Technology Stack

### Backend (Rust)
- **Role:** Handles complex profit calculations, database transactions, and API requests.
- **Crate:** `flutter_rust_bridge` (v2 preferred).
- **ORM:** SeaORM (Strict usage).
- **Database:** - **Remote:** PostgreSQL (Production).
  - **Local:** SQLite (Offline Cache).
- **Serialization:** Serde.

### Frontend (Flutter)
- **Language:** Dart (Flutter 3.x+).
- **Target Platforms:** Windows (Primary), iOS (Secondary).
- **State Management:** `flutter_riverpod`.
- **UI Packages:**
  - `pluto_grid` (Windows Data Grids).
  - `syncfusion_flutter_calendar` (Operations Timeline).
  - `flex_color_scheme` & `google_fonts` (Theming).

## 3. UI/UX Design System: "The Linear Aesthetic"

**Design Philosophy:** "Clean SaaS". Minimalist, slate-colored, professional.

### Visual Rules
- **Font:** Strictly **Inter** (`GoogleFonts.inter()`).
- **Colors (Slate/Zinc Palette):**
  - **Background:** Off-White (`#F8F9FA`).
  - **Surface:** Pure White (`#FFFFFF`) with thin borders (`#E2E8F0`).
  - **Primary Text:** Slate 800 (`#1E293B`).
  - **Brand:** Deep Navy (`#0F172A`).
  - **Accent:** Muted Indigo (`#6366F1`).
  - **Status Colors:** Muted/Pastel tones (No bright neon colors).
- **Shapes:** `BorderRadius.circular(8)` (Buttons/Inputs), `BorderRadius.circular(12)` (Cards). **No heavy shadows.**

## 4. Platform Specific Instructions (Adaptive UI)

**A. If Windows (Desktop):**
- **Layout:** Left Sidebar Navigation + Top Breadcrumbs.
- **Data Display:** Dense **Data Grids** (`PlutoGrid`).
- **Features:** Full CRUD (Create, Read, Update, Delete).

**B. If iOS (Mobile):**
- **Layout:** Bottom Navigation Bar.
- **Data Display:** **ListViews** with Cards or `ListTile`.
- **Features:** Read-Only / Approval / Status View.

## 5. Module: Operations Calendar (Timeline)

- **Package:** `syncfusion_flutter_calendar`.
- **Windows View:** `CalendarView.resource` (Group events by **Port**).
- **iOS View:** `CalendarView.schedule` (Agenda List).
- **Logic:** Fetch `ShipVisit` (ETA/ETD) via Rust FFI.
- **Visuals:** Rectangular blocks (`Radius.circular(4)`), grouped by Port name on the left Y-axis.

## 6. Business Logic & Workflow

### Order Status Flow
Enforce this strictly in Rust/DB:
`NEW` -> `QUOTED` -> `AGREED` -> `WAITING_GOODS` -> `PREPARED` -> `ON_WAY` -> `DELIVERED` -> `INVOICED`.

## 7. Development Workflow & Git Automation (STRICT)

**Remote Repo:** `https://github.com/brk4lp/Ship-Supply-Management-System`

**Protocol:** After completing ANY feature or bug fix, you MUST follow this interactive protocol strictly. Do NOT generate script files.

### Step 1: Validation
Tell the user:
> "Feature implemented. Now running tests..."
Provide the command: `flutter test`

### Step 2: Strict Confirmation
**DO NOT** provide git push commands yet.
Ask the user:
> "Tests passed? Do you confirm pushing these changes to the remote repository? (YES/NO)"

### Step 3: Deployment (Only if YES)
If and ONLY IF the user replies "YES", provide the following commands exactly:

```bash
git add .
git commit -m "feat: <write a short summary of changes here>"
git push [https://github.com/brk4lp/Ship-Supply-Management-System](https://github.com/brk4lp/Ship-Supply-Management-System) main