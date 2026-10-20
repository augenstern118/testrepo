-- C00002.00 is the mother's NLSY79 ID. It also groups maternal siblings.
-- SELECT chooses the columns; JOIN matches this family key to one mother.
CREATE TABLE links AS
SELECT c.child_id, c.family_id, m.mother_id,
       c.birth_year AS child_birth_year, c.sex AS child_sex,
       m.birth_year AS mother_birth_year
FROM children AS c
JOIN mothers AS m ON c.family_id = m.mother_id
WHERE m.sex = 2 AND m.sample_code BETWEEN 5 AND 8;

CREATE UNIQUE INDEX links_child_key ON links(child_id);
