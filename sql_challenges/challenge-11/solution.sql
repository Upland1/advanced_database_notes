-- ============================================================
-- Lesson 03: SQLAlchemy ORM + Alembic Migrations
-- File: 01_setup_schema.sql
-- Purpose: V1 Schema — teams, users, tasks
--
-- Run this in your FreeSQL worksheet to create the base tables.
-- ============================================================

-- Drop tables if they exist (clean start)
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS teams;

-- ============================================================
-- TEAMS
-- ============================================================
CREATE TABLE teams (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR2(50)  NOT NULL UNIQUE,
    description VARCHAR2(200),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE users (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username    VARCHAR2(50)  NOT NULL UNIQUE,
    email       VARCHAR2(100) NOT NULL,
    full_name   VARCHAR2(100),
    team_id     NUMBER,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_team
        FOREIGN KEY (team_id) REFERENCES teams(id)
);

-- ============================================================
-- TASKS
-- ============================================================
CREATE TABLE tasks (
    id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200) NOT NULL,
    description  VARCHAR2(1000),
    status       VARCHAR2(20)  DEFAULT 'open',
    assigned_to  NUMBER,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP,
    CONSTRAINT fk_tasks_user
        FOREIGN KEY (assigned_to) REFERENCES users(id)
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- Teams
INSERT INTO teams (name, description) VALUES ('Engineering', 'Software development team');
INSERT INTO teams (name, description) VALUES ('Product', 'Product management team');

-- Users
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('alice_dev', 'alice@example.com', 'Alice Smith', 1);
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('bob_dev', 'bob@example.com', 'Bob Jones', 1);
INSERT INTO users (username, email, full_name, team_id)
    VALUES ('carol_pm', 'carol@example.com', 'Carol White', 2);

-- Tasks
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Fix login bug', 'Users cannot log in with SSO', 'open', 1);
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Design new dashboard', 'Create mockups for analytics page', 'in_progress', 3);
INSERT INTO tasks (title, description, status, assigned_to)
    VALUES ('Update dependencies', 'Upgrade numpy and pandas', 'open', 2);

COMMIT;

-- ============================================================
-- VERIFY
-- ============================================================
SELECT 'Teams:' AS section, name FROM teams
UNION ALL
SELECT 'Users:' AS section, username FROM users
UNION ALL
SELECT 'Tasks:' AS section, title FROM tasks;

 

-----
/* ==============================================================================
   ALEMBIC DOWNGRADE QUESTIONS
============================================================================== */

-- 1. What happens to the column?
-- When you downgrade to remove a column, it is dropped (deleted) entirely 
-- from the table's schema in the database.

-- 2. What happens to the data?
-- Any data that was stored in that specific column is permanently deleted. 
-- The rest of the data in the table (the other columns) remains perfectly intact.


/* ==============================================================================
   EXERCISE 5 — CONCEPT CHECK
============================================================================== */

-- 1. Why use ORM instead of raw SQL?
-- * Object-Oriented: You interact with your database using native Python classes 
--   and objects instead of writing raw SQL strings.
-- * Database Agnostic: The ORM translates your Python code into the correct SQL 
--   dialect automatically (easy to switch from SQLite to Oracle to PostgreSQL).
-- * Security: It automatically sanitizes inputs, heavily reducing the risk of 
--   SQL injection attacks.

-- 2. Why use migrations?
-- Migrations act as version control for your database schema (like Git, but 
-- for your database structure). They allow you to safely apply changes (upgrades) 
-- or undo them (downgrades) in a trackable, repeatable way across different 
-- environments (dev, staging, production).

-- 3. When would you rollback?
-- * During development: When you make a mistake creating a new table or column 
--   and want to quickly undo it to try again.
-- * In production: If a new update or feature is deployed but introduces a 
--   critical bug, rolling back safely reverts the DB to its last stable state.

-- 4. Difference between add() and commit()?
-- * session.add() stages the change. It tells SQLAlchemy, "Keep track of this 
--   object, I want to save it soon." (Like adding items to a cart or 'git add').
-- * session.commit() finalizes the transaction. It writes the SQL INSERT/UPDATE 
--   statements to the actual database, making the changes permanent (Like 
--   paying at the checkout or 'git commit').

-- 5. Why are relationships useful?
-- Relationships save you from writing complex SQL JOIN statements. They map 
-- foreign keys directly into convenient Python attributes. Instead of querying 
-- two separate tables, you can access related data like a nested variable.
