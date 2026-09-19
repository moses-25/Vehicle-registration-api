-- ============================================================================
-- Vehicle Registration API — Database Inspection Queries
-- ----------------------------------------------------------------------------
-- Target database : Vehicle_registration_db
-- Target user     : Vehicle_admin
-- Run in          : pgAdmin Query Tool, or `psql -f database/inspection.sql`
--
-- Every query below is self-contained. They are grouped by the business rule
-- they help you verify, so you can jump straight to the one that answers your
-- question.
--
-- Convention:
--   - Q0.x  = dashboard / summary
--   - Q1.x  = users and roles
--   - Q2.x  = vehicles and their owners
--   - Q3.x  = activity log / audit trail
--   - Q4.x  = Sanctum tokens
--   - Q5.x  = cross-cutting reports
-- ============================================================================


-- ============================================================================
-- Q0 — OPERATIONAL DASHBOARD
-- The single query to run first. One row per metric.
-- ============================================================================

-- Q0.1  Everything at a glance
SELECT 'Users (total)'                        AS metric, COUNT(*)::text AS value FROM users
UNION ALL SELECT '  administrators',             COUNT(*)::text FROM users WHERE role = 'administrator'
UNION ALL SELECT '  operators',                  COUNT(*)::text FROM users WHERE role = 'operator'
UNION ALL SELECT 'Vehicles (total)',             COUNT(*)::text FROM vehicles
UNION ALL SELECT '  registered by admins',       COUNT(*)::text
             FROM vehicles v JOIN users u ON u.id = v.created_by
             WHERE u.role = 'administrator'
UNION ALL SELECT '  registered by operators',    COUNT(*)::text
             FROM vehicles v JOIN users u ON u.id = v.created_by
             WHERE u.role = 'operator'
UNION ALL SELECT 'Active API tokens',            COUNT(*)::text FROM personal_access_tokens
UNION ALL SELECT 'Activity log rows',            COUNT(*)::text FROM activity_logs
UNION ALL SELECT 'Requests last 24h',            COUNT(*)::text
             FROM activity_logs WHERE created_at >= NOW() - INTERVAL '1 day'
ORDER BY metric;


-- Q0.2  Row counts per application table
SELECT 'users'                AS table_name, COUNT(*) AS rows FROM users
UNION ALL SELECT 'vehicles',                  COUNT(*) FROM vehicles
UNION ALL SELECT 'personal_access_tokens',    COUNT(*) FROM personal_access_tokens
UNION ALL SELECT 'activity_logs',             COUNT(*) FROM activity_logs
UNION ALL SELECT 'sessions',                  COUNT(*) FROM sessions
UNION ALL SELECT 'cache',                     COUNT(*) FROM cache
UNION ALL SELECT 'jobs',                      COUNT(*) FROM jobs
UNION ALL SELECT 'failed_jobs',               COUNT(*) FROM failed_jobs
ORDER BY table_name;


-- Q0.3  List every table in the public schema (sanity check after migrations)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type   = 'BASE TABLE'
ORDER BY table_name;


-- ============================================================================
-- Q1 — USERS AND ROLES
-- Business rules: only 'administrator' can manage users.
-- ============================================================================

-- Q1.1  All users with their role
SELECT id, name, email, role, email_verified_at, created_at
FROM users
ORDER BY id;


-- Q1.2  Administrators only (the accounts with delete privilege on vehicles)
SELECT id, name, email, created_at
FROM users
WHERE role = 'administrator'
ORDER BY id;


-- Q1.3  Operators only (cannot manage users, cannot delete vehicles)
SELECT id, name, email, created_at
FROM users
WHERE role = 'operator'
ORDER BY id;


-- Q1.4  Sanity check: are there any roles outside the enum?
--       Should always return zero rows.
SELECT id, name, email, role
FROM users
WHERE role NOT IN ('administrator', 'operator');


-- Q1.5  Duplicate emails (should never return rows — unique index enforces this)
SELECT email, COUNT(*) AS occurrences
FROM users
GROUP BY email
HAVING COUNT(*) > 1;


-- ============================================================================
-- Q2 — VEHICLES AND THEIR OWNERS
-- Business rules: plate unique, type enum, created_by NOT NULL, cascade delete.
-- ============================================================================

-- Q2.1  All vehicles with the user who registered each one
SELECT
    v.id,
    v.plate,
    v.type,
    v.brand || ' ' || v.model  AS vehicle,
    v.year,
    v.color,
    v.owner_name,
    v.owner_document,
    u.id                       AS registered_by_id,
    u.name                     AS registered_by_name,
    u.role                     AS registered_by_role,
    v.created_at
FROM vehicles v
JOIN users u ON u.id = v.created_by
ORDER BY v.id;


-- Q2.2  Duplicate plates (should always return zero rows)
SELECT plate, COUNT(*) AS occurrences
FROM vehicles
GROUP BY plate
HAVING COUNT(*) > 1;


-- Q2.3  Distribution of vehicle types
SELECT type, COUNT(*) AS total
FROM vehicles
GROUP BY type
ORDER BY total DESC, type;


-- Q2.4  Sanity check: invalid types outside the enum
--       Should always return zero rows through normal API use.
SELECT id, plate, type
FROM vehicles
WHERE type NOT IN ('car', 'suv', 'truck', 'motorcycle');


-- Q2.5  Vehicles per owner (the user who registered them)
SELECT
    u.id,
    u.name,
    u.role,
    COUNT(v.id) AS vehicle_count
FROM users u
LEFT JOIN vehicles v ON v.created_by = u.id
GROUP BY u.id, u.name, u.role
ORDER BY vehicle_count DESC, u.id;


-- Q2.6  Vehicles owned by a specific person (owner_name), regardless of
--       who registered them in the system
SELECT v.id, v.plate, v.brand, v.model, v.year, v.owner_name,
       u.email AS registered_by
FROM vehicles v
JOIN users u ON u.id = v.created_by
WHERE v.owner_name = 'James Anderson'
ORDER BY v.id;


-- Q2.7  Orphan check: vehicles whose created_by user no longer exists
--       Should always return zero rows (FK cascade prevents this).
SELECT v.id, v.plate, v.created_by
FROM vehicles v
LEFT JOIN users u ON u.id = v.created_by
WHERE u.id IS NULL;


-- ============================================================================
-- Q3 — ACTIVITY LOG (AUDIT TRAIL)
-- Business rule: every /api/* request is logged with who, what, when, status.
-- ============================================================================

-- Q3.1  Latest 50 requests, with the responsible user
SELECT
    a.id,
    a.created_at,
    COALESCE(u.email, '—anonymous—')  AS who,
    a.method,
    a.path,
    a.action,
    a.status_code,
    a.ip_address
FROM activity_logs a
LEFT JOIN users u ON u.id = a.user_id
ORDER BY a.id DESC
LIMIT 50;


-- Q3.2  Only the rejected requests, with a human-readable reason
SELECT
    a.created_at,
    a.user_id,
    u.email,
    a.method || ' ' || a.path  AS endpoint,
    a.status_code,
    CASE a.status_code
        WHEN 401 THEN 'Unauthenticated'
        WHEN 403 THEN 'Forbidden (role check failed)'
        WHEN 404 THEN 'Not found'
        WHEN 422 THEN 'Validation failed'
        WHEN 500 THEN 'Server error — investigate'
        ELSE 'Other'
    END AS reason
FROM activity_logs a
LEFT JOIN users u ON u.id = a.user_id
WHERE a.status_code >= 400
ORDER BY a.id DESC;


-- Q3.3  Failed login attempts only (public endpoint, user_id is NULL)
SELECT id, created_at, method, path, status_code, ip_address
FROM activity_logs
WHERE path = 'api/login'
  AND status_code = 401
ORDER BY id DESC;


-- Q3.4  Requests logged after a user was deleted
--       (activity_logs.user_id is NULL, but path isn't /api/login)
SELECT
    a.id,
    a.created_at,
    a.method || ' ' || a.path AS endpoint,
    a.status_code
FROM activity_logs a
WHERE a.user_id IS NULL
  AND a.path <> 'api/login'
ORDER BY a.id DESC;


-- Q3.5  Endpoint hit count, grouped by method + path + status
SELECT
    method,
    path,
    action,
    status_code,
    COUNT(*) AS hits
FROM activity_logs
GROUP BY method, path, action, status_code
ORDER BY hits DESC, path;


-- Q3.6  Status code summary over the last day
SELECT
    status_code,
    COUNT(*)         AS requests,
    MIN(created_at)  AS first_seen,
    MAX(created_at)  AS last_seen
FROM activity_logs
WHERE created_at >= NOW() - INTERVAL '1 day'
GROUP BY status_code
ORDER BY status_code;


-- Q3.7  Requests per hour for the last 24 hours (traffic shape)
SELECT
    date_trunc('hour', created_at) AS hour,
    COUNT(*)                       AS requests
FROM activity_logs
WHERE created_at >= NOW() - INTERVAL '1 day'
GROUP BY hour
ORDER BY hour;


-- Q3.8  Top talkers — which IP addresses made the most requests
SELECT ip_address, COUNT(*) AS requests
FROM activity_logs
GROUP BY ip_address
ORDER BY requests DESC
LIMIT 10;


-- Q3.9  Write operations only (POST / PUT / PATCH / DELETE)
SELECT
    a.created_at,
    u.email,
    a.method,
    a.path,
    a.status_code
FROM activity_logs a
LEFT JOIN users u ON u.id = a.user_id
WHERE a.method IN ('POST', 'PUT', 'PATCH', 'DELETE')
ORDER BY a.id DESC;


-- ============================================================================
-- Q4 — SANCTUM TOKENS
-- Business rules: tokens are per-login, revocable, and belong to one user.
-- ============================================================================

-- Q4.1  Currently live tokens, joined to their user
SELECT
    t.id            AS token_id,
    u.id            AS user_id,
    u.email,
    u.role,
    t.name          AS token_label,
    t.last_used_at,
    t.created_at
FROM personal_access_tokens t
JOIN users u
  ON u.id = t.tokenable_id
 AND t.tokenable_type = 'App\\Models\\User'
ORDER BY t.created_at DESC;


-- Q4.2  Live token count per user
SELECT
    u.id,
    u.email,
    COUNT(t.id)             AS token_count,
    MAX(t.last_used_at)     AS last_used_at,
    MAX(t.created_at)       AS newest_token
FROM users u
LEFT JOIN personal_access_tokens t
       ON t.tokenable_id   = u.id
      AND t.tokenable_type = 'App\\Models\\User'
GROUP BY u.id, u.email
ORDER BY u.id;


-- Q4.3  Tokens that were issued but never used
SELECT id, tokenable_id, name, created_at
FROM personal_access_tokens
WHERE last_used_at IS NULL
ORDER BY created_at DESC;


-- Q4.4  Stale tokens (issued more than 30 days ago, never used)
SELECT id, tokenable_id, name, created_at
FROM personal_access_tokens
WHERE last_used_at IS NULL
  AND created_at < NOW() - INTERVAL '30 days'
ORDER BY created_at;


-- Q4.5  Orphan token check: tokens whose owner no longer exists
--       Should always return zero rows.
SELECT t.id, t.tokenable_id, t.name
FROM personal_access_tokens t
LEFT JOIN users u
       ON u.id = t.tokenable_id
      AND t.tokenable_type = 'App\\Models\\User'
WHERE u.id IS NULL;


-- ============================================================================
-- Q5 — CROSS-CUTTING REPORTS
-- ============================================================================

-- Q5.1  Activity per role — who is doing what, and how often they get rejected
SELECT
    u.role,
    u.email,
    COUNT(a.id)                                   AS total_requests,
    COUNT(*) FILTER (WHERE a.status_code < 400)   AS successful,
    COUNT(*) FILTER (WHERE a.status_code = 401)   AS unauthorized,
    COUNT(*) FILTER (WHERE a.status_code = 403)   AS forbidden,
    COUNT(*) FILTER (WHERE a.status_code = 422)   AS validation_errors,
    MAX(a.created_at)                             AS last_seen
FROM users u
LEFT JOIN activity_logs a ON a.user_id = u.id
GROUP BY u.role, u.email
ORDER BY u.role, u.email;


-- Q5.2  Which endpoints a given role actually hits
SELECT
    u.role,
    a.method || ' ' || a.path AS endpoint,
    COUNT(*) AS hits
FROM activity_logs a
JOIN users u ON u.id = a.user_id
GROUP BY u.role, endpoint
ORDER BY u.role, hits DESC;


-- Q5.3  Full session trail for a single user (change email as needed)
SELECT
    a.created_at,
    a.method,
    a.path,
    a.status_code,
    a.ip_address
FROM activity_logs a
JOIN users u ON u.id = a.user_id
WHERE u.email = 'emily.johnson@example.com'
ORDER BY a.created_at DESC
LIMIT 100;


-- Q5.4  Vehicles added today (or any day) — replace the interval
SELECT
    v.id,
    v.plate,
    v.brand,
    v.model,
    u.email AS registered_by,
    v.created_at
FROM vehicles v
JOIN users u ON u.id = v.created_by
WHERE v.created_at::date = CURRENT_DATE
ORDER BY v.created_at DESC;


-- Q5.5  Last login per user — derived from personal_access_tokens
SELECT
    u.id,
    u.email,
    MAX(t.created_at) AS last_login_at
FROM users u
LEFT JOIN personal_access_tokens t
       ON t.tokenable_id   = u.id
      AND t.tokenable_type = 'App\\Models\\User'
GROUP BY u.id, u.email
ORDER BY last_login_at DESC NULLS LAST;


-- ============================================================================
-- APPENDIX — Raw dumps (SELECT * equivalents)
-- For when you just want to eyeball a table.
-- ============================================================================

-- A.1  Users (password hidden)
SELECT id, name, email, role, email_verified_at, created_at, updated_at
FROM users
ORDER BY id;

-- A.2  Vehicles
SELECT id, plate, type, brand, model, year, color,
       owner_name, owner_document, created_by, created_at, updated_at
FROM vehicles
ORDER BY id;

-- A.3  Activity logs (latest first)
SELECT id, user_id, method, path, action, status_code, ip_address, created_at
FROM activity_logs
ORDER BY id DESC
LIMIT 200;

-- A.4  Personal access tokens (token hash omitted)
SELECT id, tokenable_type, tokenable_id, name,
       last_used_at, expires_at, created_at, updated_at
FROM personal_access_tokens
ORDER BY id DESC;

-- A.5  Migrations (what ran, in which batch)
SELECT id, migration, batch
FROM migrations
ORDER BY id;

-- A.6  Cache keys
SELECT key, expiration, length(value) AS value_bytes
FROM cache
ORDER BY key;

-- A.7  Jobs queue (should be empty with QUEUE_CONNECTION=sync)
SELECT id, queue, attempts, reserved_at, available_at, created_at
FROM jobs
ORDER BY id;

-- A.8  Failed jobs (should be empty unless something blew up)
SELECT id, uuid, connection, queue, failed_at
FROM failed_jobs
ORDER BY failed_at DESC;
