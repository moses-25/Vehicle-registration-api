# Vehicle Registration API

Vehicle Registration API is a **REST API** built with **Laravel** and
**PostgreSQL** that models a simple vehicle registration system with
role-based access control, token authentication, and full request
auditing.

The project demonstrates how to build a professional, production-style
Laravel API: authenticated with **Sanctum**, protected by
**role-based middleware**, backed by a normalized **PostgreSQL**
schema running in **Docker**, and covered by **PHPUnit** feature tests
and a ready-to-import **Postman collection**.

---

# Project Overview

The API manages two core resources:

- **Users** — system accounts with an `administrator` or `operator`
  role
- **Vehicles** — registered vehicles, each linked to the user who
  registered them

Every authenticated request is recorded in an **activity log**,
capturing who did what, when, and with what result — giving the API a
built-in audit trail.

---

# Features

- Token-based authentication with **Laravel Sanctum**
- Role-based authorization (`administrator` / `operator`) via custom
  middleware
- Full CRUD for **Users** (administrator-only)
- Full CRUD for **Vehicles**, with role-scoped permissions:
  - `administrator` + `operator` → list, register, update
  - `administrator` only → delete
- Automatic **activity logging** middleware on every API request
  (method, path, action, status code, IP address, user)
- Model observer that logs vehicle lifecycle events
  (`created`, `updated`, `deleted`)
- Strict request validation via dedicated **Form Request** classes
- Enum-backed `role` and `type` fields for data integrity
- PostgreSQL database, containerized with **Docker Compose**
  (Postgres + pgAdmin)
- Database seeder with realistic sample users and vehicles
- Feature test suite (**PHPUnit**) covering role permissions
- Ready-to-import **Postman collection** for manual/API testing
- SQL inspection script (`tests/database/queries.sql`) for auditing
  the database directly

---

# Technologies

- PHP 8.3
- Laravel 13
- Laravel Sanctum (API token authentication)
- PostgreSQL 16
- Docker & Docker Compose
- PHPUnit
- Composer

---

# Learning Objectives

Students will practice:

- Designing a RESTful API with Laravel
- Modeling relational data with Eloquent (`User`, `Vehicle`,
  `ActivityLog`)
- Implementing token authentication with Sanctum
- Writing custom middleware for role-based authorization
- Validating input with Form Request classes
- Using PHP backed enums for controlled vocabularies
- Auditing application activity with middleware and model observers
- Running a relational database in Docker
- Writing feature tests against API endpoints
- Testing an API with Postman
- Structuring a Laravel project for real-world maintainability

---

# Roles & Permissions

| Action                | Administrator | Operator |
|------------------------|:-------------:|:--------:|
| Login / Logout / Me     | ✅            | ✅       |
| List users              | ✅            | ❌       |
| Create / update users    | ✅            | ❌       |
| Delete users             | ✅            | ❌       |
| List vehicles            | ✅            | ✅       |
| Register a vehicle       | ✅            | ✅       |
| Update a vehicle         | ✅            | ✅       |
| Delete a vehicle         | ✅            | ❌       |

Every request — successful or rejected — is written to the
`activity_logs` table.

---

# API Endpoints

## Auth

| Method | Endpoint       | Description                        | Access        |
|--------|----------------|-------------------------------------|---------------|
| POST   | `/api/login`   | Authenticate and receive a token    | Public        |
| POST   | `/api/logout`  | Revoke the current token            | Authenticated |
| GET    | `/api/me`      | Get the authenticated user          | Authenticated |

## Users

| Method | Endpoint            | Description        | Access        |
|--------|----------------------|---------------------|---------------|
| GET    | `/api/users`         | List users (paginated) | Administrator |
| POST   | `/api/users`         | Create a user       | Administrator |
| GET    | `/api/users/{id}`    | Show a user         | Administrator |
| PUT/PATCH | `/api/users/{id}` | Update a user       | Administrator |
| DELETE | `/api/users/{id}`    | Delete a user        | Administrator |

## Vehicles

| Method | Endpoint               | Description           | Access                  |
|--------|--------------------------|-------------------------|--------------------------|
| GET    | `/api/vehicles`          | List vehicles (paginated) | Administrator, Operator |
| POST   | `/api/vehicles`          | Register a vehicle      | Administrator, Operator |
| GET    | `/api/vehicles/{id}`     | Show a vehicle          | Administrator, Operator |
| PUT/PATCH | `/api/vehicles/{id}`  | Update a vehicle        | Administrator, Operator |
| DELETE | `/api/vehicles/{id}`     | Delete a vehicle         | Administrator            |

All authenticated endpoints require the header:

```
Authorization: Bearer <token>
Accept: application/json
```

---

# Data Model

## User

- `name`, `email`, `password`
- `role`: `administrator` \| `operator`
- Has many `vehicles` (as creator) and `activityLogs`

## Vehicle

- `plate` (unique), `type`, `brand`, `model`, `year`, `color`
- `owner_name`, `owner_document`
- `type`: `car` \| `suv` \| `truck` \| `motorcycle`
- Belongs to the `User` who registered it (`created_by`), cascade
  deleted with that user

## ActivityLog

- `user_id`, `method`, `path`, `action`, `status_code`, `ip_address`,
  `created_at`
- Recorded automatically for every `/api/*` request

---

# Prerequisites

- PHP 8.3+
- Composer
- Docker & Docker Compose (for PostgreSQL + pgAdmin)

---

# Installation

Clone the repository:

```bash
git clone https://github.com/primetek-africa/vehicle-registration-api
```

Navigate into the project:

```bash
cd vehicle-registration-api
```

Install PHP dependencies:

```bash
composer install
```

Copy the environment file and generate the application key:

```bash
cp .env.example .env
php artisan key:generate
```

---

# Database Setup (Docker)

The database (PostgreSQL) and pgAdmin run in Docker containers defined
in `docker-compose.yml`. Configure your `.env` with the database
credentials you want to use (defaults are provided in
`.env.example`), then start the containers:

```bash
docker compose up -d
```

This starts:

- **PostgreSQL** on the port defined by `DB_PORT` (default `5432`)
- **pgAdmin** on the port defined by `PGADMIN_PORT` (default `5050`)

Verify the containers are healthy:

```bash
docker compose ps
```

---

# Running Migrations & Seeders

With the database container running, apply the migrations:

```bash
php artisan migrate
```

Seed the database with sample users and vehicles:

```bash
php artisan db:seed
```

Or do both in one step, resetting the schema first:

```bash
php artisan migrate:fresh --seed
```

## Seeded accounts

| Role          | Email                          | Password   |
|----------------|----------------------------------|------------|
| Administrator  | `james.anderson@example.com`     | `password` |
| Operator       | `emily.johnson@example.com`      | `password` |

Each seeded user comes with sample vehicles already registered under
their account.

---

# Running the Application

Start the Laravel development server:

```bash
php artisan serve
```

The API is now available at `http://localhost:8000`. Visiting `/`
returns a small JSON status payload confirming the app name and
environment.

---

# Testing

## PHPUnit feature tests

The test suite uses an in-memory SQLite database (configured in
`phpunit.xml`) so it runs independently of the Docker PostgreSQL
container.

```bash
composer test
```

or directly:

```bash
php artisan test
```

Current coverage includes vehicle listing and role-restricted delete
permissions (`tests/Feature/VehicleApiTest.php`).

## Postman collection

A ready-to-use collection is included at:

```
tests/postman/Vehicle Registration API TEST.postman_collection.json
```

Import it into Postman to exercise every endpoint (auth, users,
vehicles) including both valid and invalid-data cases. Update the
bearer tokens in each request with a token obtained from `/api/login`.

## SQL inspection queries

`tests/database/queries.sql` contains a large set of read-only queries
for auditing the database directly (dashboards, per-role activity,
token usage, orphan checks, etc.) — useful when working in pgAdmin or
`psql`.

---

# Project Structure

```text
app/
  Enums/            # UserRole, VehicleType
  Http/
    Controllers/Api/ # AuthController, UserController, VehicleController
    Middleware/       # LogActivityMiddleware, RoleMiddleware
    Requests/         # Form Request validation classes
  Models/            # User, Vehicle, ActivityLog
  Observers/         # VehicleObserver
database/
  factories/          # UserFactory, VehicleFactory
  migrations/
  seeders/
routes/
  api.php             # All API routes
tests/
  Feature/            # PHPUnit feature tests
  database/           # SQL inspection queries
  postman/            # Postman collection
```

---

# Learning Outcomes

After completing this project, students will be able to:

- Build a role-protected REST API with Laravel and Sanctum
- Design normalized relational schemas with foreign keys and enums
- Implement custom authorization middleware
- Add automatic request auditing to an API
- Validate incoming data with dedicated Form Request classes
- Run and manage a PostgreSQL database with Docker
- Write and run feature tests for API endpoints
- Test and document an API with Postman

---

# Future Improvements

Possible enhancements include:

- API resource classes / transformers for response shaping
- Rate limiting per role
- Soft deletes for vehicles and users
- Vehicle ownership history / transfer endpoint
- OpenAPI/Swagger documentation
- Refresh tokens / token expiration policy
- Filtering, sorting, and search on list endpoints
- Docker container for the Laravel app itself (full containerization)

---

# License

This project is licensed under the **MIT License** — see the
[LICENSE](LICENSE) file for details.
