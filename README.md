# Webotapp Driving School Management ERP

A complete, production-ready Driving School Management ERP and SaaS platform designed specifically for the Indian market, motor training institutes, and multi-branch commercial driver academies.

Built in **Light Mode with a compact, high-density view and small typography** for maximum operational speed.

---

## Key Features

- **Multi-Tenant SaaS Architecture**: Shared database with tenant isolation via `BelongsToTenant` Eloquent global scopes.
- **Multi-Branch Operations**: Branch-level data scoping, branch switching from topbar, headquarters vs branch managers.
- **Configurable RBAC**: Business Owner, Branch Manager, Admission Executive, Driving Instructor, Student, and Platform Super Admin.
- **CRM & Enquiry Pipeline**: Lead capture from Walk-ins, Phone, Website, and Justdial with complete call follow-up timelines.
- **Student Admissions & Document Vault**: Transactional admission creation, student codes, document upload, and verification.
- **Smart Training Scheduler & Conflict Prevention**: Prevents double-booking of instructors, dual-control vehicles, and students.
- **7-Day Master Calendar**: Visual weekly calendar matrix with daily slot breakdowns.
- **Lesson Attendance & Odometer Tracking**: Actual time recording, start/end odometer readings, km driven calculation, and student feedback.
- **Training Progress Engine**: Automated calculation of completed practical and theory hours with RTO DL Test readiness indicators.
- **RTO Mock Test Module**: Road signs, signals, and regulations simulator with automated pass/fail scoring.
- **Government-Compliant Certificates**: Certificate generation with unique verification codes and public QR authentication at `/certificates/verify/{code}`.
- **GST Invoicing & Fee Receipts**: SAC Code 999293 (Driving tuition), automated 18% GST (CGST 9% + SGST 9%), partial installment tracking, and printable tax invoices.
- **Fleet & Expense Management**: Dual-control car registry, statutory document expiry alerts (PUC, Insurance, Fitness), fuel logs, and workshop servicing records.
- **Public Website & Online Admission**: Public landing page with course catalog and online callback inquiry form.

---

## Technology Stack

- **Backend**: Laravel 13 (PHP 8.4+)
- **Database**: MySQL 8+ / MariaDB with decimal fields, foreign key constraints, indexes, and transactions
- **Frontend**: Blade, Tailwind CSS, Alpine.js (Light mode, compact view, small fonts)
- **Authentication**: Laravel Session Authentication & Sanctum

---

## Installation & Setup

### 1. Database Setup
Create a MySQL database:
```sql
CREATE DATABASE drivingschool_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Environment Configuration
Ensure `.env` contains:
```env
APP_NAME="Webotapp Driving School ERP"
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=drivingschool_erp
DB_USERNAME=root
DB_PASSWORD=
DB_SOCKET=/Users/pabanbhuyanmacmini/.local/share/webotapp/mysql.sock
```

### 3. Migrations & Seeders
Execute migrations and seed realistic demo data:
```bash
php artisan migrate:fresh --seed
```

### 4. Build Frontend Assets
```bash
npm run build
```

### 5. Run Local Server
```bash
php artisan serve
```
Open [http://localhost:8000](http://localhost:8000) in your browser.

---

## Docker Setup & Usage

This project includes a multi-stage Docker setup with four services:
- **`web`** (`nginx:1.27-alpine`): Serves static/built Vite assets and proxies PHP requests to `app` on port `8080` (configurable via `APP_PORT`).
- **`app`** (`php:8.4-fpm-alpine`): PHP-FPM 8.4 runtime with Laravel 13, Composer dependencies, and compiled Vite assets.
- **`queue`** (`php:8.4-fpm-alpine`): Background worker running `php artisan queue:work`.
- **`db`** (`mysql:8.4`): MySQL 8.4 database with persistent `mysql_data` volume and UTF8MB4 encoding.

### 1. Configure Environment
Copy the Docker environment template to `.env` and generate an application key:
```bash
cp .env.docker.example .env
```

### 2. Build & Start Containers
```bash
docker compose up -d --build
```

### 3. Initialize Application Key, Database & Demo Data
Generate `APP_KEY` (if not already set in `.env`), run migrations, and seed the demo data:
```bash
# Generate APP_KEY and write it to .env
KEY=$(docker compose run --rm --no-deps --entrypoint php app artisan key:generate --show | tr -d '\r\n')
sed -i.bak "s|^APP_KEY=.*|APP_KEY=${KEY}|" .env && rm -f .env.bak

# Restart app & queue to pick up the new APP_KEY
docker compose up -d app queue

# Run migrations and seed demo data
docker compose exec app php artisan migrate --seed --force
```

Open [http://localhost:8080](http://localhost:8080) in your browser.

### Useful Docker Commands
```bash
# View container status
docker compose ps

# Tail application logs
docker compose logs -f app web queue

# Run Artisan commands
docker compose exec app php artisan migrate:status
docker compose exec app php artisan tinker

# Stop containers (preserves database & storage volumes)
docker compose down

# Stop containers and remove volumes (resets database)
docker compose down -v
```

---

## Pre-Configured Demo Accounts

All demo accounts use password: `password123`

| Role | Email | Access Scope |
|---|---|---|
| **Business Owner** | `owner@apexdriving.com` | Complete access to all branches, finances, reports, settings |
| **Branch Manager** | `manager@apexdriving.com` | Koramangala branch operations, scheduling, fleet |
| **Admission Counselor** | `admissions@apexdriving.com` | Leads CRM, student registrations, document verification |
| **Driving Instructor** | `rajesh.instructor@apexdriving.com` | Lesson roster, attendance check-in, student rating |
| **Student (Arjun)** | `student@apexdriving.com` | Student portal, scheduled lessons, progress |
| **Platform Super Admin** | `superadmin@webotapp.com` | Multi-tenant SaaS administration |

> **Tip:** You can switch between personas with a single click using the **Instant 1-Click Demo Login** buttons on the login screen or top-right profile menu!

---

## Running Automated Tests

Run the test suite with PHPUnit:
```bash
php artisan test
```
All 11 tests covering Authentication, Admissions, Scheduling Conflict Engine, Billing, Progress, and Public Portal execute cleanly with 41 assertions.
