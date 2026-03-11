-- SQL Lesson 6 --
-- 1.1-
SELECT *
FROM Movies 
INNER JOIN Boxoffice
ON Boxoffice.movie_id = Movies.id;

-- 1.2- 
SELECT *
FROM Movies 
INNER JOIN Boxoffice
ON Boxoffice.movie_id = Movies.id
WHERE International_sales > Domestic_Sales;

-- 1.3- 
SELECT *
FROM Movies 
INNER JOIN Boxoffice
ON Boxoffice.movie_id = Movies.id
ORDER BY Rating DESC;


-- SQL Lesson 7 --
--2.1- 
SELECT DISTINCT building 
FROM Employees
INNER JOIN Buildings
WHERE Buildings.building_name = Employees.Building;

--2.2-
SELECT * 
FROM Buildings;

--2.3-
SELECT DISTINCT b.building_name, e.role
FROM Buildings as b
LEFT JOIN Employees as e
ON b.Building_name = e.Building;
