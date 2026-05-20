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

 /* ==============================================================================
   EXERCISE 1 — Model Design
============================================================================== */
-- SQLAlchemy ORM Model

from sqlalchemy import (
    Column, Integer, String, Text,
    ForeignKey, DateTime,
    CheckConstraint
)

from sqlalchemy.orm import relationship
from sqlalchemy.sql import func


class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)

    task_id = Column(
        Integer,
        ForeignKey("tasks.id", ondelete="CASCADE"),
        nullable=False
    )

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    content = Column(
        Text,
        nullable=False
    )

    created_at = Column(
        DateTime,
        server_default=func.current_timestamp()
    )

    __table_args__ = (
        CheckConstraint(
            "content <> ''",
            name="check_comment_content"
        ),
    )

    -- Relationships
    task = relationship(
        "Task",
        back_populates="comments"
    )

    user = relationship(
        "User",
        back_populates="comments"
    )

-- 1. What relationships should Comment have?
-- Comment should have:
-- *one relationship to Task
-- *one relationship to User

-- 2. Should Task have a comments relationship?
-- Yes, one task can contain many comments.

-- 3. What should happen to comments when a task is deleted?
-- The comments should also be deleted automatically.
-- This avoids orphaned comments that belong to non-existing tasks.
-----
 /* ==============================================================================
   EXERCISE 2 — Migration creation
============================================================================== */
-- Generate migration

command.revision(
    alembic_cfg,
    autogenerate=True,
    message="add comments table"
)

--- Inspect Migration file

import glob

migration_files = sorted(
    glob.glob('/content/project/alembic/versions/*.py')
)

for f in migration_files:
    print(f)

--- Open latest migration

latest = migration_files[-1]

with open(latest) as f:
    print(f.read())


-- 1. What does 'upgrade()' do?
-- 'upgrade()' applies the migration changes to the database.
--
-- 2. What does 'downgrade()' do?
-- 'downgrade()' reverses the migration changes.
--
-- 3. What happens if you downgrade this migration?
-- The comments table will be removed from the database.
-- Any data stored in comments will also be permanently deleted.
-----
 /* ==============================================================================
   EXERCISE 3 — CRUD Challenge
============================================================================== */
from sqlalchemy.orm import Session


with Session(engine) as session:

    print("===================================")
    print("CREATING TEAM")
    print("===================================")

    devops = Team(
        name="DevOps",
        description="Infrastructure team"
    )

    session.add(devops)
    session.commit()

    print(f"Created Team: {devops.name}")


    print("\n===================================")
    print("CREATING USER")
    print("===================================")

    sebas = User(
        username="sebis",
        email="sebis@tec.com",
        full_name="sebas oliva",
        team=devops
    )

    session.add(sebas)
    session.commit()

    print(f"Created User: {sebas.username}")


    print("\n===================================")
    print("CREATING TASKS")
    print("===================================")

    task1 = Task(
        title="Setup CI/CD",
        description="Configure GitHub Actions",
        status="high_priority",
        assignee=sebas
    )

    task2 = Task(
        title="Dockerize app",
        description="Create Docker containers",
        status="medium_priority",
        assignee=sebas
    )

    task3 = Task(
        title="Clean logs",
        description="Delete old server logs",
        status="low_priority",
        assignee=sebas
    )

    session.add_all([task1, task2, task3])
    session.commit()

    print("3 tasks created.")


    print("\n===================================")
    print("TASK COUNT")
    print("===================================")

    task_count = session.query(Task).count()

    print(f"Total Tasks: {task_count}")


    print("\n===================================")
    print("CLOSING ONE TASK")
    print("===================================")

    task1.status = "closed"

    session.commit()

    print(f"Task Closed: {task1.title}")


    print("\n===================================")
    print("DELETING LOWEST PRIORITY TASK")
    print("===================================")

    session.delete(task3)

    session.commit()

    print(f"Deleted Task: {task3.title}")


    print("\n===================================")
    print("FINAL TASKS")
    print("===================================")

    remaining_tasks = session.query(Task).all()

    for task in remaining_tasks:
        print(f"- {task.title} ({task.status})")
-----
/* ==============================================================================
   ALEMBIC DOWNGRADE QUESTIONS
============================================================================== */

-- Rollback migration 
command.downgrade(alembic_cfg, "-1")

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
