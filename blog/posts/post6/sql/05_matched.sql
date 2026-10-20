-- Aggregate each generation FIRST. Joining both annual panels directly
-- would create every possible parent-year x child-year combination.
CREATE TABLE covered_pairs AS
SELECT l.*, p.parent_average, p.parent_years,
       e.early_average, e.early_years,
       a.mature_average, a.mature_years,
       ps.parent_single, ps.parent_single_age,
       es.early_single, es.early_single_age,
       ms.mature_single, ms.mature_single_age
FROM links AS l
JOIN parent_average AS p ON l.mother_id = p.mother_id
JOIN child_early_average AS e ON l.child_id = e.child_id
JOIN child_mature_average AS a ON l.child_id = a.child_id
JOIN parent_single AS ps ON l.mother_id = ps.mother_id
JOIN child_early_single AS es ON l.child_id = es.child_id
JOIN child_mature_single AS ms ON l.child_id = ms.child_id;

-- Every specification uses exactly these same pairs.
CREATE TABLE matched AS
SELECT * FROM covered_pairs
WHERE parent_single > 0 AND early_single > 0 AND mature_single > 0
  AND parent_average > 0 AND early_average > 0 AND mature_average > 0;

CREATE UNIQUE INDEX matched_child_key ON matched(child_id);
