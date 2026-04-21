-- Lesson 04: Setup
-- Create a simple accounts table for the transfer demo

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250

 

 

-- Lesson 04: Class Exercises
-- Students: work through these in order. Don't skip the verify steps.

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- Your SQL here:
SELECT * FROM accounts WHERE account_id IN (1, 3);
UPDATE accounts SET balance = balance - 50 WHERE account_id = 3;
UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;
COMMIT;
-- verify
SELECT * FROM accounts WHERE account_id IN (1, 3);


-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

-- Your SQL here:
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2;
UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3;
-- IF insufficient_balance THEN
SELECT * FROM accounts WHERE account_id IN (2, 3);
ROLLBACK;
-- ELSE Commit the transaction
COMMIT;
-- verify
SELECT * FROM accounts WHERE account_id IN (2, 3);
 

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

-- Your SQL here:
-- 1:
SELECT * FROM accounts WHERE owner_name = 'Alice';
UPDATE accounts SET balance = balance + 25 WHERE OWNER_NAME = 'Alice';
-- 2:
SAVEPOINT AFTER_ALICE;
-- 3
UPDATE accounts SET balance = balance - 25 WHERE ACCOUNT_ID = 3;
-- 4
ROLLBACK TO AFTER_ALICE;
-- 5 
UPDATE accounts SET balance = balance - 25 WHERE ACCOUNT_ID = 2;
-- 6
COMMIT;

-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
-- Test it with: EXEC deposit_funds(3, 75);

-- Your SQL here:
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount IN NUMBER
) AS 
    v_current_balance NUMBER;
BEGIN
    -- 1
    IF 0 >= p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Deposit amount must be positive');
    END IF;
    -- 2
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_account_id;
    -- 3
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deposit successful.');    
    -- 4
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transfer failed. All changes rolled back.');
        RAISE; 
END;
/

EXEC deposit_funds(3, 75);

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?
-- the confirmation notification should be outside the transaction as it is just a log confirmation that everything went alright,
-- and both reserve time slot and create appointment record should be inside the transaction due to its manipulation through the database
-- values.

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?
-- that everytime he calls his transaction, inside my procedure it will call commit and finlaize all pending changes in
-- the developer's session, not just the ones inside my procedure.

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?
-- yes, you can call a function inside a SELECT statement because it acts as an extension of database's built-in functions.
-- no, you cannot call a procedure inside a SELECT statement because procedures are used for actions, not for return scalar values.