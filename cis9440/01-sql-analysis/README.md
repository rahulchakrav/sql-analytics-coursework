# SQL Analysis and Data Quality Assessment

**Course:** CIS 9440 — Data Warehousing and Analytics  
**Context:** First homework assignment  
**Author:** Rahul Chakravarty

## Overview

This assignment uses squirrel observation records and park stories to practice SQL analysis. The portfolio focus is the query design: combining two tables, defining record groups, assessing missing values, and producing concise summaries.

The SQL file contains 14 selected answers. The original question letters are retained for traceability.

## Data referenced

| Table | Role in the analysis |
| --- | --- |
| `homework1_dataset.squirrel_observations` | Observation attributes, location and time fields, and behavior indicators |
| `homework1_dataset.squirrel_stories` | Story text, topic indicators, and location and time fields |

The data files, full schema, row counts, dataset source URL, and reuse license were not included in the materials used to prepare this repository. No data is redistributed here.

## Query guide

| Sections | Analysis | Techniques |
| --- | --- | --- |
| A–D | Preview records and calculate filtered counts | SELECT, WHERE, COUNT, GROUP BY, HAVING, ORDER BY |
| E–F | Measure missing age and fur-color information | NULL checks, COUNTIF, SAFE_DIVIDE, ROUND |
| G–H | Filter behavior and location combinations | Boolean conditions and grouped predicates |
| J | Count observations in locations associated with selected stories | CTEs, DISTINCT, pre-aggregation, LEFT JOIN, COALESCE |
| K | Calculate three correlations involving behavior indicators | CAST, CORR, ROUND |
| M | Compare observation counts and average story lengths by location | CTE, AVG, LENGTH, HAVING, LEFT JOIN |
| N | Compare story contexts by age group | Multi-key INNER JOIN, conditional aggregation |
| O–P | Compare counts and completeness by month segment | PARSE_DATE, EXTRACT, CASE, UNION ALL, percentages |

## Selected query design choices

- **Section J** reduces the selected stories to distinct locations and aggregates observations before joining. This avoids multiplying observation counts when a location has several qualifying stories.
- **Section N** aggregates story-topic indicators by location, shift, and date before joining to observations. Each topic count represents observations associated with a context where that topic is present. Topics can overlap, so their counts need not sum to the total.
- **Sections E–F** distinguish missing age, missing fur color, and both missing together. Section F returns six measures: a count and percentage for each condition.
- **Sections O–P** define the beginning of a month as days 1–14 and the ending as days 15 onward. They answer different questions: the distribution of observations versus the within-period completeness of a story field.

## Running the queries

The SQL uses GoogleSQL / BigQuery-style functions such as `COUNTIF`, `SAFE_DIVIDE`, and `INT64` casts. It is not a MySQL script without adaptation.

To run it, you need access to the two course tables with the expected column names and types. Change the table references if your dataset is elsewhere, then execute the statements individually. The date queries assume values compatible with the original `%m%d%Y` parsing expression; inspect date formatting before reuse.

## Results and limitations

The repository includes query text only. It does not include execution logs, result tables, or independently verified findings. The queries were not re-executed while preparing this portfolio copy because the source data was not provided.

A correlation query alone does not establish a substantive finding. Review its output, NULL handling, and underlying observations before drawing conclusions.

## Attribution

The course supplied the assignment and data context. Parts (i) and (l), which included supplied SQL, are excluded from this portfolio selection. Other query bodies are preserved from the submitted homework; only prompt comments and surrounding presentation were changed.
