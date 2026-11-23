CREATE OR REPLACE TABLE calendrier AS
SELECT CAST(d AS DATE) AS jour,
       isodow(d) <= 5 AS est_ouvre,
       SUM(CASE WHEN isodow(d) <= 5 THEN 1 ELSE 0 END) OVER (ORDER BY d) AS rang_ouvre
FROM generate_series(DATE '2024-09-01', DATE '2026-12-31', INTERVAL 1 DAY) t(d);