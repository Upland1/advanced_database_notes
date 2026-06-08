-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- File: 01_setup_oltp.sql
-- Purpose: Create source OLTP tables + seed data
--
-- Self-contained — no dependencies on previous lessons.
-- Run this on https://freesql.com/
-- ============================================================

-- Clean up if re-running (child before parent)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE task_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tasks';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE users';     EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- USERS — who works on tasks
-- ============================================================
CREATE TABLE users (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  DEFAULT 'developer' NOT NULL,
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP
);

-- ============================================================
-- TASKS — what needs to be done
-- ============================================================
CREATE TABLE tasks (
    id            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200)  NOT NULL,
    description   VARCHAR2(500),
    status        VARCHAR2(20)   DEFAULT 'open' NOT NULL,
    priority      VARCHAR2(10)   DEFAULT 'medium' NOT NULL,
    assigned_to   NUMBER         REFERENCES users(id),
    created_by    NUMBER         REFERENCES users(id),
    created_at    TIMESTAMP      DEFAULT SYSTIMESTAMP,
    updated_at    TIMESTAMP      DEFAULT SYSTIMESTAMP,
    completed_at  TIMESTAMP,
    CONSTRAINT chk_task_status CHECK (
        status IN ('open', 'in_progress', 'blocked', 'completed', 'cancelled')
    ),
    CONSTRAINT chk_task_priority CHECK (
        priority IN ('low', 'medium', 'high', 'critical')
    )
);

-- ============================================================
-- TASK_ASSIGNMENTS — historical record of task assignments
-- Tracks who was assigned to each task and when.
-- Populated automatically by trg_task_assignment_log.
-- ============================================================
CREATE TABLE task_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id       NUMBER       NOT NULL REFERENCES tasks(id),
    assigned_to   NUMBER       NOT NULL REFERENCES users(id),
    assigned_by   NUMBER       REFERENCES users(id),
    valid_from    TIMESTAMP    NOT NULL,
    valid_to      TIMESTAMP    -- NULL = current assignment
);

-- Index for date-range lookups (find who was assigned at a point in time)
CREATE INDEX idx_assignments_lookup
ON task_assignments (task_id, valid_from, valid_to);
-- ============================================================
-- TRIGGER: Automatically log task assignments
-- Fires on INSERT (initial assignment) and UPDATE (reassignment)
-- ============================================================
CREATE OR REPLACE TRIGGER trg_task_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tasks
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Initial assignment: log who was assigned at creation time
        INSERT INTO task_assignments (task_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.id, :NEW.assigned_to, :NEW.created_by, :NEW.created_at);
    ELSIF UPDATING THEN
        -- Close the previous assignment
        UPDATE task_assignments
           SET valid_to = :NEW.updated_at
         WHERE task_id = :OLD.id
           AND valid_to IS NULL;

        -- Open the new assignment
        INSERT INTO task_assignments (task_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.id, :NEW.assigned_to, NULL, :NEW.updated_at);
    END IF;
END;
/

 

-- ============================================================
-- SEED DATA — 8 users, 40 tasks across 3 months
-- ============================================================

-- Users
INSERT INTO users (name, email, team, role) VALUES ('Alice Chen',   'alice@example.com',   'Platform',   'senior');
INSERT INTO users (name, email, team, role) VALUES ('Bob Martinez', 'bob@example.com',     'Platform',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Carol Smith',  'carol@example.com',   'Frontend',   'senior');
INSERT INTO users (name, email, team, role) VALUES ('Dave Kim',     'dave@example.com',    'Frontend',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Eve Johnson',  'eve@example.com',     'Data',       'senior');
INSERT INTO users (name, email, team, role) VALUES ('Frank Lee',    'frank@example.com',   'Data',       'developer');
INSERT INTO users (name, email, team, role) VALUES ('Grace Wang',   'grace@example.com',   'Platform',   'developer');
INSERT INTO users (name, email, team, role) VALUES ('Henry Brown',  'henry@example.com',   'Frontend',   'developer');
COMMIT;

-- Tasks — spread across Feb–Apr 2026 with varied statuses and priorities
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Fix login redirect bug', 'Users redirected to home instead of dashboard after SSO login', 'completed', 'high', 1, 1, TIMESTAMP '2026-02-01 09:00:00', TIMESTAMP '2026-02-02 14:00:00', TIMESTAMP '2026-02-02 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Design new dashboard mockups', 'Create Figma mockups for analytics dashboard with KPI cards', 'completed', 'medium', 3, 3, TIMESTAMP '2026-02-03 10:00:00', TIMESTAMP '2026-02-10 16:00:00', TIMESTAMP '2026-02-10 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Upgrade numpy and pandas', 'Update to latest stable versions, fix breaking changes', 'completed', 'low', 5, 5, TIMESTAMP '2026-02-05 11:00:00', TIMESTAMP '2026-02-07 15:00:00', TIMESTAMP '2026-02-07 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('API rate limiting', 'Implement rate limiting on public API endpoints', 'completed', 'high', 1, 2, TIMESTAMP '2026-02-06 09:00:00', TIMESTAMP '2026-02-12 11:00:00', TIMESTAMP '2026-02-12 11:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Write unit tests for auth', 'Cover login, logout, token refresh, and password reset flows', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-07 10:00:00', TIMESTAMP '2026-02-14 17:00:00', TIMESTAMP '2026-02-14 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Database backup automation', 'Automate daily backup to S3 with 30-day retention policy', 'completed', 'medium', 1, 5, TIMESTAMP '2026-02-08 11:00:00', TIMESTAMP '2026-02-10 10:00:00', TIMESTAMP '2026-02-10 10:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Mobile responsive navigation', 'Side menu does not collapse on screens under 768px', 'completed', 'high', 3, 4, TIMESTAMP '2026-02-10 09:00:00', TIMESTAMP '2026-02-14 16:00:00', TIMESTAMP '2026-02-14 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('User profile page', 'Allow users to edit avatar, bio, and notification preferences', 'completed', 'low', 4, 3, TIMESTAMP '2026-02-12 10:00:00', TIMESTAMP '2026-02-20 14:00:00', TIMESTAMP '2026-02-20 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Optimize report query', 'Weekly report generation takes 45 seconds — needs optimization', 'completed', 'critical', 5, 6, TIMESTAMP '2026-02-14 09:00:00', TIMESTAMP '2026-02-15 18:00:00', TIMESTAMP '2026-02-15 18:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Set up CI/CD pipeline', 'GitHub Actions workflow for automated test + deploy', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-17 09:00:00', TIMESTAMP '2026-02-25 12:00:00', TIMESTAMP '2026-02-25 12:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Error tracking integration', 'Connect Sentry for production error alerting', 'completed', 'medium', 1, 2, TIMESTAMP '2026-02-19 10:00:00', TIMESTAMP '2026-02-24 15:00:00', TIMESTAMP '2026-02-24 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Dark mode toggle', 'Add dark/light theme switcher with localStorage persistence', 'completed', 'low', 3, 4, TIMESTAMP '2026-02-21 11:00:00', TIMESTAMP '2026-03-01 16:00:00', TIMESTAMP '2026-03-01 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Refactor user service', 'Split monolithic user service into auth, profile, and admin modules', 'completed', 'medium', 1, 2, TIMESTAMP '2026-02-24 09:00:00', TIMESTAMP '2026-03-05 17:00:00', TIMESTAMP '2026-03-05 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('SQL query performance audit', 'Review slow queries from pg_stat_statements, optimize top 5', 'completed', 'high', 5, 6, TIMESTAMP '2026-02-26 10:00:00', TIMESTAMP '2026-03-02 14:00:00', TIMESTAMP '2026-03-02 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Add search functionality', 'Implement full-text search on tasks and comments', 'completed', 'medium', 2, 1, TIMESTAMP '2026-02-28 11:00:00', TIMESTAMP '2026-03-10 16:00:00', TIMESTAMP '2026-03-10 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Email notification service', 'Send email alerts when tasks are assigned or overdue', 'completed', 'medium', 7, 1, TIMESTAMP '2026-03-02 09:00:00', TIMESTAMP '2026-03-12 15:00:00', TIMESTAMP '2026-03-12 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Loading state components', 'Add skeleton loaders and spinner components to all data views', 'completed', 'low', 4, 3, TIMESTAMP '2026-03-04 10:00:00', TIMESTAMP '2026-03-11 14:00:00', TIMESTAMP '2026-03-11 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('API documentation', 'Document all REST endpoints with request/response examples', 'completed', 'low', 8, 3, TIMESTAMP '2026-03-06 11:00:00', TIMESTAMP '2026-03-18 17:00:00', TIMESTAMP '2026-03-18 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Implement caching layer', 'Add Redis caching for frequently accessed API endpoints', 'completed', 'high', 1, 2, TIMESTAMP '2026-03-09 09:00:00', TIMESTAMP '2026-03-16 12:00:00', TIMESTAMP '2026-03-16 12:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Data export feature', 'Allow users to export task data as CSV and Excel', 'completed', 'medium', 6, 5, TIMESTAMP '2026-03-11 10:00:00', TIMESTAMP '2026-03-20 16:00:00', TIMESTAMP '2026-03-20 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Password reset flow', 'Implement secure password reset with email token', 'completed', 'critical', 1, 2, TIMESTAMP '2026-03-13 09:00:00', TIMESTAMP '2026-03-15 11:00:00', TIMESTAMP '2026-03-15 11:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Notification preferences UI', 'Build settings page for email and in-app notification toggles', 'completed', 'medium', 3, 4, TIMESTAMP '2026-03-16 10:00:00', TIMESTAMP '2026-03-23 15:00:00', TIMESTAMP '2026-03-23 15:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Batch task operations', 'Allow selecting multiple tasks and changing status/assignee in bulk', 'completed', 'medium', 2, 1, TIMESTAMP '2026-03-18 11:00:00', TIMESTAMP '2026-03-27 14:00:00', TIMESTAMP '2026-03-27 14:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Performance monitoring dashboard', 'Build real-time dashboard for API latency and error rates', 'completed', 'high', 5, 6, TIMESTAMP '2026-03-20 09:00:00', TIMESTAMP '2026-03-30 17:00:00', TIMESTAMP '2026-03-30 17:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Keyboard shortcuts', 'Add keyboard navigation shortcuts for power users', 'completed', 'low', 4, 3, TIMESTAMP '2026-03-23 10:00:00', TIMESTAMP '2026-03-28 16:00:00', TIMESTAMP '2026-03-28 16:00:00');
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Webhook integration', 'Allow external services to subscribe to task events via webhooks', 'in_progress', 'medium', 2, 1, TIMESTAMP '2026-03-25 11:00:00', TIMESTAMP '2026-03-25 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Role-based access control', 'Implement admin, manager, and developer roles with permissions', 'in_progress', 'high', 1, 2, TIMESTAMP '2026-03-27 09:00:00', TIMESTAMP '2026-03-27 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Drag-and-drop task board', 'Kanban-style board with drag-and-drop status changes', 'in_progress', 'medium', 3, 4, TIMESTAMP '2026-03-30 10:00:00', TIMESTAMP '2026-03-30 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Task dependencies', 'Allow tasks to depend on other tasks (blocked by relationship)', 'open', 'medium', 2, 1, TIMESTAMP '2026-04-01 11:00:00', TIMESTAMP '2026-04-01 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Real-time collaboration', 'WebSocket-based live updates when multiple users view the same task', 'open', 'high', 7, 1, TIMESTAMP '2026-04-02 09:00:00', TIMESTAMP '2026-04-02 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Mobile app push notifications', 'Push notifications for task assignments and due dates', 'open', 'medium', 8, 3, TIMESTAMP '2026-04-03 10:00:00', TIMESTAMP '2026-04-03 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Automated task assignment', 'AI-based assignment based on workload and expertise', 'open', 'low', 5, 6, TIMESTAMP '2026-04-04 11:00:00', TIMESTAMP '2026-04-04 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Time tracking integration', 'Allow logging hours spent on each task', 'blocked', 'medium', 6, 5, TIMESTAMP '2026-04-05 09:00:00', TIMESTAMP '2026-04-05 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Multi-language support', 'i18n framework with Spanish and French translations', 'blocked', 'low', 4, 3, TIMESTAMP '2026-04-06 10:00:00', TIMESTAMP '2026-04-06 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Audit log viewer', 'Admin interface to browse and filter audit logs', 'open', 'medium', 1, 2, TIMESTAMP '2026-04-07 11:00:00', TIMESTAMP '2026-04-07 11:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('SAML/SSO integration', 'Enterprise SSO via SAML for company-wide deployment', 'open', 'high', 1, 2, TIMESTAMP '2026-04-08 09:00:00', TIMESTAMP '2026-04-08 09:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Custom fields for tasks', 'Allow admins to add custom fields to task forms', 'open', 'medium', 3, 4, TIMESTAMP '2026-04-09 10:00:00', TIMESTAMP '2026-04-09 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Weekly digest email', 'Automated weekly summary of team activity and completed tasks', 'cancelled', 'low', 5, 6, TIMESTAMP '2026-04-10 11:00:00', TIMESTAMP '2026-04-12 14:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Gantt chart view', 'Timeline view for project planning and milestone tracking', 'cancelled', 'low', 3, 4, TIMESTAMP '2026-04-11 09:00:00', TIMESTAMP '2026-04-13 10:00:00', NULL);
INSERT INTO tasks (title, description, status, priority, assigned_to, created_by, created_at, updated_at, completed_at) VALUES
('Legacy data migration', 'Migrate 50K tasks from old system with field mapping', 'cancelled', 'medium', 1, 5, TIMESTAMP '2026-04-12 10:00:00', TIMESTAMP '2026-04-14 16:00:00', NULL);
COMMIT;

-- ============================================================
-- DEMO: Task reassignment
-- Task 5 ("Write unit tests for auth") was created by Alice,
-- initially assigned to Bob. On Feb 10, it was reassigned to Grace.
-- The trigger automatically logs this change.
-- ============================================================

-- Show the assignment before reassignment
SELECT ta.task_id, t.title,
       u_from.name AS assigned_to,
       ta.valid_from
FROM task_assignments ta
JOIN tasks t ON t.id = ta.task_id
JOIN users u_from ON u_from.id = ta.assigned_to
WHERE ta.task_id = 5 AND ta.valid_to IS NULL;

-- Reassign task 5 from Bob (id=2) to Grace (id=7)
UPDATE tasks
SET assigned_to = 7,
    updated_at  = TIMESTAMP '2026-02-10 10:00:00'
WHERE id = 5;

COMMIT;

-- Show the full assignment history for task 5
SELECT ta.task_id, t.title,
       u.name AS assigned_to,
       ta.valid_from,
       ta.valid_to,
       CASE WHEN ta.valid_to IS NULL THEN 'current' ELSE 'historical' END AS status
FROM task_assignments ta
JOIN tasks t ON t.id = ta.task_id
JOIN users u ON u.id = ta.assigned_to
WHERE ta.task_id = 5
ORDER BY ta.valid_from;

-- Verify
SELECT 'users: ' || COUNT(*) AS count FROM users
UNION ALL
SELECT 'tasks: ' || COUNT(*) AS count FROM tasks
UNION ALL
SELECT 'task_assignments: ' || COUNT(*) AS count FROM task_assignments;

 

__________________________

-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- File: 02_setup_dw.sql
-- Purpose: Create star schema tables for the data warehouse
--
-- Self-contained — run after 01_setup_oltp.sql.
-- Run this on https://freesql.com/
-- ============================================================

-- Clean up if re-running (child before parent)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_task_daily';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_status';       EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_date';         EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_user';         EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- DIM_USER — user attributes (denormalized)
-- Surrogate key separates DW from source system
-- ============================================================
CREATE TABLE dim_user (
    user_key    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     NUMBER       NOT NULL,  -- source system ID
    name        VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    role        VARCHAR2(30)  NOT NULL,
    CONSTRAINT uq_dim_user_source UNIQUE (user_id)
);

-- ============================================================
-- DIM_DATE — calendar hierarchy
-- Pre-computed attributes make date-based queries trivial
-- ============================================================
CREATE TABLE dim_date (
    date_key    NUMBER PRIMARY KEY,  -- integer: YYYYMMDD
    full_date   DATE       NOT NULL,
    year        NUMBER(4)  NOT NULL,
    quarter     NUMBER(1)  NOT NULL,
    month       NUMBER(2)  NOT NULL,
    month_name  VARCHAR2(10) NOT NULL,
    day         NUMBER(2)  NOT NULL,
    day_name    VARCHAR2(10) NOT NULL,
    is_weekend  NUMBER(1)  NOT NULL,  -- 1 = Saturday/Sunday
    CONSTRAINT uq_dim_date UNIQUE (full_date)
);

-- ============================================================
-- DIM_STATUS — task status categories
-- Small dimension, but separating it enables category grouping
-- ============================================================
CREATE TABLE dim_status (
    status_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    status_name VARCHAR2(20) NOT NULL,
    category    VARCHAR2(20) NOT NULL,  -- active, done, cancelled
    CONSTRAINT uq_dim_status UNIQUE (status_name)
);

-- Seed statuses
INSERT INTO dim_status (status_name, category) VALUES ('open',        'active');
INSERT INTO dim_status (status_name, category) VALUES ('in_progress', 'active');
INSERT INTO dim_status (status_name, category) VALUES ('blocked',     'active');
INSERT INTO dim_status (status_name, category) VALUES ('completed',   'done');
INSERT INTO dim_status (status_name, category) VALUES ('cancelled',   'cancelled');
COMMIT;

-- ============================================================
-- FACT_TASK_DAILY — daily task metrics
-- One row per (date, user, status, priority) combination
-- This is the grain: daily snapshot by user and status
--
-- NOTE: user_key reflects the HISTORICAL assignee from
-- task_assignments (OLTP), NOT the current assigned_to.
-- If a task was reassigned mid-life, creation credit goes
-- to the original assignee, completion credit to the
-- assignee at completion time.
-- ============================================================
CREATE TABLE fact_task_daily (
    fact_key          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key          NUMBER       NOT NULL REFERENCES dim_date(date_key),
    user_key          NUMBER       NOT NULL REFERENCES dim_user(user_key),
    status_key        NUMBER       NOT NULL REFERENCES dim_status(status_key),
    priority          VARCHAR2(10) NOT NULL,
    tasks_created     NUMBER       DEFAULT 0,
    tasks_completed   NUMBER       DEFAULT 0,
    avg_completion_hours NUMBER    DEFAULT NULL,
    CONSTRAINT uq_fact UNIQUE (date_key, user_key, status_key, priority)
);

-- Verify
SELECT 'dim_user: '   || COUNT(*) FROM dim_user
UNION ALL
SELECT 'dim_status: ' || COUNT(*) FROM dim_status
UNION ALL
SELECT 'dim_date: '   || COUNT(*) FROM dim_date;
-- (dim_date will be populated by the ETL pipeline)

 

 

 

-------

 

# Lesson 08: Exercise — Assignment History

A support ticketing system. Tickets get reassigned between agents. You need
to track who was assigned when the ticket was created vs when it was resolved.

---

## Step 1 — Source Tables (OLTP)

Create two tables:

**`tickets`** — current state of each ticket. Needs:
- ticket_id, title, status, priority, created_at, resolved_at, assigned_to

**`ticket_assignments`** — history of who was assigned when. Needs:
- assignment_id, ticket_id, assigned_to, assigned_by, valid_from, valid_to

```sql
-- Your code here
-- Clean up existing structures if re-running
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets';            EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- TICKETS: Current state of support tickets
CREATE TABLE tickets (
    ticket_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR2(200) NOT NULL,
    status      VARCHAR2(20)  DEFAULT 'open' NOT NULL,
    priority    VARCHAR2(10)  DEFAULT 'medium' NOT NULL,
    assigned_to NUMBER        NOT NULL, -- Agent ID from source
    created_at  TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    CONSTRAINT chk_ticket_status CHECK (status IN ('open', 'in_progress', 'blocked', 'resolved', 'cancelled')),
    CONSTRAINT chk_ticket_priority CHECK (priority IN ('low', 'medium', 'high', 'critical'))
);

-- TICKET_ASSIGNMENTS: Historical tracking ledger
CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER    NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER    NOT NULL,
    assigned_by   NUMBER,   -- Can capture who performed the reassignment
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP -- NULL indicates the active assignment
);

-- Composite index to facilitate historical lookup point-in-time joins
CREATE INDEX idx_ticket_assign_lookup 
ON ticket_assignments (ticket_id, valid_from, valid_to);
```

---

## Step 2 — Sample Data

Insert at least 5 tickets. Make sure at least one gets reassigned (different
person in `ticket_assignments` than the current `assigned_to` in `tickets`).

```sql
-- Your code here
-- Insert 5 tickets with historical separation
INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Inbound API Timeout Error', 'open', 'high', 10, TIMESTAMP '2026-06-01 08:30:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('UI Component Alignment Bug', 'open', 'low', 11, TIMESTAMP '2026-06-01 09:15:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Memory Leak on File Upload', 'open', 'critical', 12, TIMESTAMP '2026-06-02 10:00:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Password Reset email failure', 'open', 'medium', 10, TIMESTAMP '2026-06-02 11:00:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Billing webhook retry failures', 'open', 'high', 13, TIMESTAMP '2026-06-03 14:00:00');
COMMIT;

-- Execution of Ticket Reassignment Scenario:
-- Ticket 1 (assigned_to = 10) gets reassigned to Agent 11 on June 2nd, then resolved by Agent 11 on June 3rd.
UPDATE tickets 
SET assigned_to = 11,
    status = 'in_progress',
    created_at = TIMESTAMP '2026-06-02 15:00:00' -- Setting context timestamp for trigger evaluation
WHERE ticket_id = 1;

UPDATE tickets
SET status = 'resolved',
    resolved_at = TIMESTAMP '2026-06-03 16:30:00'
WHERE ticket_id = 1;
COMMIT;
```

---

## Step 3 — Trigger

Write a trigger on `tickets` that:
- On INSERT or UPDATE of `assigned_to`, logs the change to `ticket_assignments`
- Closes the previous active assignment (sets its `valid_to`)
- Inserts a new row with `valid_from = now()` and `valid_to = NULL`

```sql
-- Your code here
CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Initial assignment logging
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at, NULL);
        
    ELSIF UPDATING THEN
        -- Close current operational window for the old agent
        UPDATE ticket_assignments
           SET valid_to = :NEW.created_at -- Assuming modification timestamp aligns with state transition
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        -- Open new operational window for incoming agent
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at, NULL);
    END IF;
END;
/
```

**Test it:** Reassign a ticket, then query `ticket_assignments` to confirm
both the old and new assignment are recorded.

---

## Step 4 — Data Warehouse Tables (Star Schema)

Create two tables:

**`dim_agent`** — agent details. Needs: agent_key, agent_name, team

**`fact_ticket_daily`** — daily counts per agent/status/priority. Needs:
date_key, agent_key, status, priority, tickets_created, tickets_resolved

```sql
-- Your code here
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent';          EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- DIM_AGENT: Agent dimension table
CREATE TABLE dim_agent (
    agent_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id   NUMBER NOT NULL, -- Core system source link
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50) NOT NULL,
    CONSTRAINT uq_dim_agent_source UNIQUE (agent_id)
);

-- FACT_TICKET_DAILY: Aggregation snapshot table
CREATE TABLE fact_ticket_daily (
    fact_key         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key         NUMBER NOT NULL, -- Format: YYYYMMDD
    agent_key        NUMBER NOT NULL REFERENCES dim_agent(agent_key),
    status           VARCHAR2(20) NOT NULL,
    priority         VARCHAR2(10) NOT NULL,
    tickets_created  NUMBER DEFAULT 0,
    tickets_resolved NUMBER DEFAULT 0,
    CONSTRAINT uq_fact_ticket_grain UNIQUE (date_key, agent_key, status, priority)
);
```

---

## Step 5 — Populate dim_agent

Insert 3-4 agents with their teams.

```sql
-- Your code here
INSERT INTO dim_agent (agent_id, agent_name, team) VALUES (10, 'Guillermo Diaz', 'L2 Core Support');
INSERT INTO dim_agent (agent_id, agent_name, team) VALUES (11, 'Mauricio Gomez', 'L1 Frontend Support');
INSERT INTO dim_agent (agent_id, agent_name, team) VALUES (12, 'Diego Ramirez',  'L3 Architecture Tier');
INSERT INTO dim_agent (agent_id, agent_name, team) VALUES (13, 'Axel Torres',    'L2 Core Support');
COMMIT;
```

---

## Step 6 — ETL Logic (Colab)

In your Colab notebook, write pandas code that:
1. Extracts `tickets` and `ticket_assignments` from FreeSQL
2. For each ticket, finds who was assigned at `created_at` using:
   `valid_from <= created_at AND (valid_to IS NULL OR valid_to > created_at)`
3. Same for `resolved_at`
4. Groups by date, agent, status, priority and counts
5. Inserts into `fact_ticket_daily`
 
import oracledb
import pandas as pd
import numpy as np
from sqlalchemy import create_engine

print("Step 1/5: Libraries loaded successfully.")

# 2. CONNECT TO FREESQL
# ------------------------------------------------------------
USERNAME = "A01645073_SCHEMA_3B17T"
PASSWORD = "1ORXIWD2#4DR6R1CG40CZN6Oo9YH8Y"
DSN = "tcps://db.freesql.com:2484/23ai_34ui2"

engine = create_engine(
    f"oracle+oracledb://{USERNAME}:{PASSWORD}@",
    connect_args={"dsn": DSN}
)

# Quick validation check to verify source tables exist
df_test = pd.read_sql("SELECT COUNT(*) AS ticket_count FROM tickets", engine)
print(f"Step 2/5: Connected! Tickets found in operational source: {df_test.iloc[0]['ticket_count']}")

# 3. PHASE 1 — EXTRACT
# ------------------------------------------------------------
print("\nExtracting data from source tables...")
df_tickets = pd.read_sql("SELECT * FROM tickets", con=engine)
df_assignments = pd.read_sql("SELECT * FROM ticket_assignments", con=engine)
df_dim_agent = pd.read_sql("SELECT agent_key, agent_id FROM dim_agent", con=engine)

# Standardize date types to datetime objects for temporal evaluations
for col in ['created_at', 'resolved_at']:
    df_tickets[col] = pd.to_datetime(df_tickets[col])
for col in ['valid_from', 'valid_to']:
    df_assignments[col] = pd.to_datetime(df_assignments[col])

print(f"Step 3/5: Extracted {len(df_tickets)} tickets and {len(df_assignments)} assignment intervals.")

# 4. PHASE 2 — TRANSFORM (Contextual Lookup & Daily Aggregation)
# ------------------------------------------------------------
print("\nTransforming data (calculating point-in-time assignees)...")

def find_historical_agent(ticket_id, timestamp):
    if pd.isnull(timestamp):
        return np.nan
    # Find who was assigned at this exact milestone timestamp
    mask = (df_assignments['ticket_id'] == ticket_id) & \
           (df_assignments['valid_from'] <= timestamp) & \
           ((df_assignments['valid_to'].isnull()) | (df_assignments['valid_to'] > timestamp))
    
    matched = df_assignments[mask]
    return matched['assigned_to'].values[0] if not matched.empty else np.nan

# Map operational ticket dates to their historical point-in-time agents
df_tickets['creator_agent_id'] = df_tickets.apply(lambda row: find_historical_agent(row['ticket_id'], row['created_at']), axis=1)
df_tickets['resolver_agent_id'] = df_tickets.apply(lambda row: find_historical_agent(row['ticket_id'], row['resolved_at']), axis=1)

# Translate operational IDs to Data Warehouse Agent Surrogate Keys
agent_mapping = dict(zip(df_dim_agent['agent_id'], df_dim_agent['agent_key']))
df_tickets['creator_agent_key'] = df_tickets['creator_agent_id'].map(agent_mapping)
df_tickets['resolver_agent_key'] = df_tickets['resolver_agent_id'].map(agent_mapping)

# Build the aggregation matrix dictionary
fact_records = {}

def update_fact_store(date_key, agent_key, status, priority, metric_type):
    if pd.isnull(agent_key) or pd.isnull(date_key):
        return
    composite_key = (int(date_key), int(agent_key), status, priority)
    if composite_key not in fact_records:
        fact_records[composite_key] = {'tickets_created': 0, 'tickets_resolved': 0}
    fact_records[composite_key][metric_type] += 1

# Process metrics out of raw tickets dataframe rows
for _, row in df_tickets.iterrows():
    # Record Creation Fact
    created_date_key = row['created_at'].strftime('%Y%m%d')
    update_fact_store(created_date_key, row['creator_agent_key'], row['status'], row['priority'], 'tickets_created')
    
    # Record Resolution Fact
    if pd.notnull(row['resolved_at']):
        resolved_date_key = row['resolved_at'].strftime('%Y%m%d')
        update_fact_store(resolved_date_key, row['resolver_agent_key'], row['status'], row['priority'], 'tickets_resolved')

# Flatten compilation mapping store back into a Structured Fact DataFrame
fact_data = []
for k, metrics in fact_records.items():
    fact_data.append({
        'date_key': k[0],
        'agent_key': k[1],
        'status': k[2],
        'priority': k[3],
        'tickets_created': metrics['tickets_created'],
        'tickets_resolved': metrics['tickets_resolved']
    })

df_fact_table = pd.DataFrame(fact_data)
print("Step 4/5: Transformation matrix calculated successfully.")

# 5. PHASE 3 — LOAD (Upsert into target Data Warehouse)
# ------------------------------------------------------------
print("\nLoading metrics into 'fact_ticket_daily' via SQL MERGE upsert...")

fact_insert_sql = """
MERGE INTO fact_ticket_daily f
USING (
    SELECT :1 AS date_key, :2 AS agent_key, :3 AS status, 
           :4 AS priority, :5 AS tickets_created, :6 AS tickets_resolved 
    FROM dual
) src
ON (
    f.date_key = src.date_key AND 
    f.agent_key = src.agent_key AND 
    f.status = src.status AND 
    f.priority = src.priority
)
WHEN MATCHED THEN
    UPDATE SET 
        f.tickets_created = src.tickets_created,
        f.tickets_resolved = src.tickets_resolved
WHEN NOT MATCHED THEN
    INSERT (date_key, agent_key, status, priority, tickets_created, tickets_resolved)
    VALUES (src.date_key, src.agent_key, src.status, src.priority, src.tickets_created, src.tickets_resolved)
"""

raw_connection = engine.raw_connection()
cursor = raw_connection.cursor()
rows_inserted = 0

try:
    for _, row in df_fact_table.iterrows():
        cursor.execute(fact_insert_sql, [
            int(row['date_key']),
            int(row['agent_key']),
            row['status'],
            row['priority'],
            int(row['tickets_created']),
            int(row['tickets_resolved'])
        ])
        rows_inserted += 1
    
    raw_connection.commit()
    print(f"Step 5/5: SUCCESS! ETL execution loaded {rows_inserted} rows into fact_ticket_daily.")

except Exception as e:
    raw_connection.rollback()
    print(f"Failed during Load execution cycle: {str(e)}")

finally:
    cursor.close()
    raw_connection.close()
---

## Step 7 — Verify

Write a query joining `fact_ticket_daily` and `dim_agent` to show tickets
created and resolved per agent per day. The reassigned ticket should show
the original agent for creation and the new agent for resolution.

```sql
-- Your code here
SELECT 
    TO_NUMBER(TO_CHAR(t.created_at, 'YYYYMMDD')) AS date_key,
    a.agent_name AS assigned_agent,
    t.status,
    t.priority,
    COUNT(CASE WHEN ta_create.assignment_id IS NOT NULL THEN 1 END) AS tickets_created,
    COUNT(CASE WHEN t.status = 'resolved' AND ta_resolve.assignment_id IS NOT NULL THEN 1 END) AS tickets_resolved
FROM tickets t
-- Left join for initial creation attribution mapping
LEFT JOIN ticket_assignments ta_create 
  ON t.ticket_id = ta_create.ticket_id
 AND ta_create.valid_from <= t.created_at
 AND (ta_create.valid_to IS NULL OR ta_create.valid_to > t.created_at)
-- Left join for resolution attribution mapping
LEFT JOIN ticket_assignments ta_resolve 
  ON t.ticket_id = ta_resolve.ticket_id
 AND ta_resolve.valid_from <= t.resolved_at
 AND (ta_resolve.valid_to IS NULL OR ta_resolve.valid_to > t.resolved_at)
-- Agent Identification Join
LEFT JOIN (
    SELECT agent_id, agent_name FROM dim_agent
) a ON a.agent_id = NVL(ta_resolve.assigned_to, ta_create.assigned_to)
GROUP BY TO_NUMBER(TO_CHAR(t.created_at, 'YYYYMMDD')), a.agent_name, t.status, t.priority
ORDER BY date_key ASC;