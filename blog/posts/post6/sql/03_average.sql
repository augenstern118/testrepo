-- GROUP BY collapses person-year rows to one row per person.
-- AVG aggregates wage LEVELS (including zeros); COUNT records coverage.
-- WHERE filters input rows; HAVING filters the resulting groups.
CREATE TABLE parent_average AS
SELECT mother_id, AVG(real_wages) AS parent_average,
       COUNT(*) AS parent_years
FROM mother_real
WHERE age BETWEEN 35 AND 40
GROUP BY mother_id
HAVING COUNT(*) >= 3;

CREATE TABLE child_early_average AS
SELECT child_id, AVG(real_wages) AS early_average,
       COUNT(*) AS early_years
FROM child_real
WHERE age BETWEEN 20 AND 25
GROUP BY child_id
HAVING COUNT(*) >= 2;

CREATE TABLE child_mature_average AS
SELECT child_id, AVG(real_wages) AS mature_average,
       COUNT(*) AS mature_years
FROM child_real
WHERE age BETWEEN 30 AND 39
GROUP BY child_id
HAVING COUNT(*) >= 2;
