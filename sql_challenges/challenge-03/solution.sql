-- SQL Lesson 10 --
-- 1.1
SELECT MAX(Years_employed)
FROM employees ;

-- 1.2
SELECT *, AVG(Years_employed)
FROM employees 
GROUP BY Role;

-- 1.3
SELECT *, SUM(Years_employed)
FROM employees 
GROUP BY Building;


-- SQL Lesson 11 --
-- 2.1
SELECT role, COUNT(*) 
FROM employees
WHERE role = "Artist";

-- 2.2
SELECT role, COUNT(*) 
FROM employees
GROUP BY role;

-- 2.3
SELECT role, SUM(years_employed)
FROM employees
GROUP BY role
HAVING role = "Engineer";