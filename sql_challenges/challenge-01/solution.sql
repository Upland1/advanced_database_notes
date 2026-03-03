-- SQL Lesson 1 --
SELECT Title FROM movies;
SELECT Director FROM movies;
SELECT Title, Director Year FROM movies;
SELECT Title, Year FROM movies;
SELECT * FROM movies;

-- SQL Lesson 2 --
SELECT * FROM Movies WHERE id=6;
SELECT * FROM Movies WHERE Year>=2000 AND Year<=2010;
SELECT * FROM Movies WHERE Year NOT BETWEEN 2000 AND 2010;
SELECT * FROM Movies ORDER BY Year ASC LIMIT 5;

-- SQL Lesson 3 --
SELECT * FROM movies WHERE Title LIKE "Toy Story%";
SELECT * FROM movies WHERE director="John Lasseter";
SELECT * FROM movies WHERE director!="John Lasseter";
SELECT * FROM movies WHERE Title LIKE "WALL-%";

-- SQL Lesson 4 --
SELECT DISTINCT director FROM movies ORDER BY Director;
SELECT * FROM movies ORDER BY Year DESC LIMIT 4;
SELECT * FROM movies ORDER BY title ASC LIMIT 5;
SELECT * FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5;

-- SQL Lesson 5 --
SELECT City, Population FROM north_american_cities WHERE Country="Canada";
SELECT * FROM north_american_cities WHERE Country="United States" ORDER BY latitude DESC;
SELECT * FROM north_american_cities WHERE Longitude< -87.629798 ORDER BY longitude;
SELECT * FROM north_american_cities WHERE country="Mexico" ORDER BY population DESC LIMIT 2;
SELECT * FROM north_american_cities WHERE country="United States" ORDER BY population DESC LIMIT 2 OFFSET 2;