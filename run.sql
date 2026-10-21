\set ON_ERROR_STOP on
\ir sql/01_schema.sql
\ir sql/02_seed.sql
\ir sql/03_views.sql
\ir sql/04_analysis.sql
\ir sql/05_quality_checks.sql
\ir sql/06_performance.sql
SELECT * FROM commerce.quality_checks ORDER BY check_name;
