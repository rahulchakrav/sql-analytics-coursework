-- CIS 9440 coursework: SQL analysis and data quality assessment
-- Author: Rahul Chakravarty
-- Dialect: GoogleSQL / BigQuery-style SQL as used in the submitted assignment.
-- Assignment prompts and instructor-provided examples are omitted.
-- Run each statement independently to inspect its result.

-- A: Preview observation records
SELECT *
FROM `homework1_dataset.squirrel_observations`
LIMIT 10;

-- B: Count adult observations
SELECT COUNT(*) AS adult_observation_count
FROM `homework1_dataset.squirrel_observations`
WHERE `age` = 'Adult';

-- C: Summarize observations by primary fur color
SELECT
  `Primary Fur Color`,
  COUNT(*) AS observation_count
FROM homework1_dataset.squirrel_observations
WHERE `Primary Fur Color` IS NOT NULL
GROUP BY `Primary Fur Color`
HAVING COUNT(*) >= 100
ORDER BY observation_count DESC, `Primary Fur Color`;

-- D: Count stories flagged as accidental poems
SELECT COUNT(*) AS accidental_poem_row_count
FROM `homework1_dataset.squirrel_stories`
WHERE `Story Topic: Accidental Poems` IS TRUE;

-- E: Calculate the percentage missing both age and fur color
SELECT
  Round(
    100.0 * SAFE_DIVIDE(
      COUNTIF (`Age` IS NULL AND `Primary Fur Color` IS NULL),
      COUNT(*)
  ),
  2
  ) AS pct_null_age_color
  FROM `homework1_dataset.squirrel_observations`;

-- F: Build six data completeness measures
SELECT
  COUNTIF(`Age` IS NULL) AS sq_null_age,
  ROUND(
    100.0 * SAFE_DIVIDE(COUNTIF(`Age` IS NULL), COUNT(*)),
    2
  ) AS pct_null_age,
COUNTIF(`Primary Fur Color` IS NULL) AS sq_null_color,
ROUND(
  100.0 * SAFE_DIVIDE(COUNTIF(`Primary Fur Color` IS NULL), COUNT(*)),
  2
) AS pct_null_color,
COUNTIF(`Age` IS NULL AND `Primary Fur Color` IS NULL) AS
sq_null_age_color,
  ROUND(
    100.0 * SAFE_DIVIDE(
      COUNTIF(`Age` IS NULL AND `Primary Fur Color` IS NULL),
      COUNT(*)
    ),
    2
    ) AS pct_null_age_color
    FROM `homework1_dataset.squirrel_observations`;

-- G: Select observations with vocalizations
SELECT *
FROM `homework1_dataset.squirrel_observations`
WHERE `Kuks` IS TRUE OR `Quaas` IS TRUE OR `Moans` IS TRUE;

-- H: Count vocal observations above ground
SELECT COUNT(*) AS vocal_above_ground_count
FROM `homework1_dataset.squirrel_observations`
WHERE (`Kuks` IS TRUE OR `Quaas` IS TRUE OR `MOANS` IS TRUE)
  AND `Location` = 'Above Ground';

-- J: Join selected story locations to observation counts
WITH poem_hectares AS (
    SELECT DISTINCT `Hectare`
    FROM `homework1_dataset.squirrel_stories`
    WHERE `Story Topic: Accidental Poems` IS TRUE
      AND `Hectare` IS NOT NULL
),
observation_counts AS (
  SELECT 
    `Hectare`,
    COUNT(*) AS squirrel_count
  FROM `homework1_dataset.squirrel_observations`
  GROUP BY `Hectare`
)
SELECT
  p. `Hectare` AS Hectare,
  COALESCE(o.squirrel_count, 0) AS Squirrel_Count
FROM poem_hectares AS p
LEFT JOIN observation_counts AS o
  ON p. `Hectare` = o.`Hectare`
ORDER BY Hectare;

-- K: Calculate correlations between tail flagging and vocalizations
SELECT
  ROUND(CORR(CAST(`Tail flags` AS INT64), CAST(`Kuks` AS INT64)), 4)
    AS correlation_with_kuks,
  ROUND (CORR(CAST(`Tail flags` AS INT64), CAST(`Quaas` AS INT64)), 4)
    AS correlation_with_quas,
  ROUND (CORR(CAST(`Tail flags` AS INT64), CAST(`Moans` AS INT64)), 4)
    AS correlation_with_moans
FROM `homework1_dataset.squirrel_observations`;

-- M: Summarize observation counts and average story lengths by location
WITH story_summary AS (
  SELECT `Hectare`,
    AVG(LENGTH(`note Squirrel & Park Stories`)) AS Average_Story_Length
  FROM `homework1_dataset.squirrel_stories`
  WHERE `Hectare` IS NOT NULL
  GROUP BY `Hectare`
  HAVING COUNT(*) >= 2
)
SELECT s.`Hectare` AS Hectare,
  COUNT(o.`Hectare`) AS Squirrel_Count,
  s.Average_Story_Length
FROM story_summary AS s 
LEFT JOIN `homework1_dataset.squirrel_observations` AS o
  ON s.`Hectare` = o.`Hectare`
GROUP BY s.`Hectare`, s.Average_Story_Length
ORDER BY Hectare;

-- N: Compare story contexts for adult and juvenile observations
WITH story_contexts AS (
  SELECT
    `Hectare`, `Shift`, `Date`,
    COUNTIF(`Story Topic: Squirrel Experience or Squirrel Story`) > 0
      AS has_squirrel_story,
    COUNTIF(`Story Topic: Dogs`) > 0
      AS has_dog_story,
    COUNTIF(`Story Topic: Park Experience or Census Taker Story`) > 0
      AS has_park_story,
    COUNTIF(`Story Topic: Other Animals`) > 0
      AS has_other_animal_story
  FROM `homework1_dataset.squirrel_stories`
  GROUP BY `Hectare`, `Shift`, `Date`
)
SELECT
  o.`Age`,
  COUNT(*) AS observations_with_stories,
  COUNTIF(s.has_squirrel_story) AS squirrel_story_count,
  COUNTIF(s.has_dog_story) AS dog_story_count,
  COUNTIF(s.has_park_story) AS park_experience_story_count,
  COUNTIF(s.has_other_animal_story) AS other_animals_story_count
FROM `homework1_dataset.squirrel_observations` AS o
JOIN story_contexts AS s
  ON o.`Hectare` = s.`Hectare`
  AND o.`Shift` = s.`Shift`
  AND o.`Date` = s.`Date`
WHERE o.`Age` IN ('Adult', 'Juvenile')
GROUP BY o.`Age`
ORDER BY o.`Age`;

-- O: Compare observation percentages across month segments
WITH observation_dates AS (
  SELECT
    PARSE_DATE('%m%d%Y', CAST(`Date` AS STRING)) AS observation_date
  FROM `homework1_dataset.squirrel_observations`
),
period_counts AS (
  SELECT
    COUNT(*) AS total_observations,
    COUNTIF(EXTRACT(DAY FROM observation_date) <= 14) AS beginning_count,
    COUNTIF(EXTRACT(DAY FROM observation_date) >= 15) AS ending_count
  FROM observation_dates
)
SELECT
  'BEGINNING' AS month_part,
  ROUND(
    100.0 * SAFE_DIVIDE(beginning_count, total_observations),
    2
  ) AS pct_observations
FROM period_counts
UNION ALL
SELECT
  'ENDING' AS month_part,
  ROUND(
    100.0 * SAFE_DIVIDE(ending_count, total_observations),
    2
  ) AS pct_observations
FROM period_counts
ORDER BY month_part;

-- P: Compare story field completeness across month segments
WITH story_dates AS (
  SELECT
    `Story Topic: Other`,
    PARSE_DATE('%m%d%Y', CAST(`Date` AS STRING)) AS story_date
  FROM `homework1_dataset.squirrel_stories`
)
SELECT
  CASE
    WHEN EXTRACT(DAY FROM story_date) <= 14 THEN 'BEGINNING'
    ELSE 'ENDING'
  END AS month_part,
  ROUND(
    100.0 * SAFE_DIVIDE(COUNTIF(`Story Topic: Other` IS NOT NULL), COUNT(*)),
    2
  ) AS pct_non_null_story_topic_other
FROM story_dates
WHERE story_date IS NOT NULL
GROUP BY month_part
ORDER BY month_part;
