WITH cv AS (
    SELECT p.MATNR,
           STDDEV(p.NETPR / p.PEINH) / AVG(p.NETPR / p.PEINH) AS coef_variation
    FROM v_ekpo p
    JOIN v_ekko k ON k.EBELN = p.EBELN
    WHERE p.MATNR IS NOT NULL AND k.WAERS = 'EUR'
    GROUP BY p.MATNR
    HAVING COUNT(*) > 5
)
SELECT 'Bons de commande en USD' AS mesure, CAST(COUNT(*) AS VARCHAR) AS valeur
FROM v_ekko WHERE WAERS = 'USD'
UNION ALL
SELECT 'Bons de commande au total', CAST(COUNT(*) AS VARCHAR)
FROM v_ekko
UNION ALL
SELECT 'Lignes de commande sans code article', CAST(COUNT(*) AS VARCHAR)
FROM v_ekpo WHERE MATNR IS NULL
UNION ALL
SELECT 'Articles commandés auprès de plusieurs fournisseurs', CAST(COUNT(*) AS VARCHAR)
FROM (
    SELECT p.MATNR
    FROM v_ekpo p
    JOIN v_ekko k ON k.EBELN = p.EBELN
    WHERE p.MATNR IS NOT NULL
    GROUP BY p.MATNR
    HAVING COUNT(DISTINCT k.LIFNR) > 1
)
UNION ALL
SELECT 'Articles retenus pour le coefficient de variation', CAST(COUNT(*) AS VARCHAR)
FROM cv
UNION ALL
SELECT 'Coefficient de variation médian du prix unitaire', CAST(ROUND(MEDIAN(coef_variation), 3) AS VARCHAR)
FROM cv
UNION ALL
SELECT 'Coefficient de variation, 90e centile', CAST(ROUND(QUANTILE_CONT(coef_variation, 0.9), 3) AS VARCHAR)
FROM cv;