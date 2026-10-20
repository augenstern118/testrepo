-- Select the observed year closest to a predeclared target age.
-- Break ties using the earlier income year, before checking positivity.
CREATE TABLE parent_single AS
SELECT e.mother_id, e.real_wages AS parent_single, e.age AS parent_single_age
FROM mother_real AS e
WHERE e.age BETWEEN 35 AND 40
  AND e.income_year = (
      SELECT q.income_year FROM mother_real AS q
      WHERE q.mother_id = e.mother_id AND q.age BETWEEN 35 AND 40
      ORDER BY ABS(q.age - 38), q.income_year LIMIT 1
  );

CREATE TABLE child_early_single AS
SELECT e.child_id, e.real_wages AS early_single, e.age AS early_single_age
FROM child_real AS e
WHERE e.age BETWEEN 20 AND 25
  AND e.income_year = (
      SELECT q.income_year FROM child_real AS q
      WHERE q.child_id = e.child_id AND q.age BETWEEN 20 AND 25
      ORDER BY ABS(q.age - 23), q.income_year LIMIT 1
  );

CREATE TABLE child_mature_single AS
SELECT e.child_id, e.real_wages AS mature_single, e.age AS mature_single_age
FROM child_real AS e
WHERE e.age BETWEEN 30 AND 39
  AND e.income_year = (
      SELECT q.income_year FROM child_real AS q
      WHERE q.child_id = e.child_id AND q.age BETWEEN 30 AND 39
      ORDER BY ABS(q.age - 35), q.income_year LIMIT 1
  );
