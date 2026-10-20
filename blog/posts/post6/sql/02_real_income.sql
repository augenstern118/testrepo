-- Negative survey codes become NULL in Python before these queries run.
-- Keep reported zeros here: they are genuine zero-wage years.
CREATE TABLE mother_real AS
SELECT e.mother_id, e.income_year,
       e.income_year - m.birth_year AS age,
       e.nominal_wages * b.cpi_u / p.cpi_u AS real_wages
FROM mother_income AS e
JOIN mothers AS m ON e.mother_id = m.mother_id
JOIN cpi AS p ON e.income_year = p.year
CROSS JOIN (SELECT cpi_u FROM cpi WHERE year = 2018) AS b
WHERE e.nominal_wages >= 0;

CREATE TABLE child_real AS
SELECT e.child_id, e.income_year,
       e.income_year - c.birth_year AS age,
       e.nominal_wages * b.cpi_u / p.cpi_u AS real_wages
FROM child_income AS e
JOIN children AS c ON e.child_id = c.child_id
JOIN cpi AS p ON e.income_year = p.year
CROSS JOIN (SELECT cpi_u FROM cpi WHERE year = 2018) AS b
WHERE e.nominal_wages >= 0;

CREATE UNIQUE INDEX mother_year_key ON mother_real(mother_id, income_year);
CREATE UNIQUE INDEX child_year_key ON child_real(child_id, income_year);
