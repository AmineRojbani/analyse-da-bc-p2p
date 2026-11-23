WITH prix_fournisseur AS (
    SELECT MATNR, trimestre, LIFNR, MEDIAN(prix_unitaire_eur) AS prix
    FROM commandes
    WHERE MATNR IS NOT NULL
    GROUP BY MATNR, trimestre, LIFNR
),
ecarts AS (
    SELECT MATNR, trimestre,
           (MAX(prix) - MIN(prix)) / MIN(prix) AS ecart
    FROM prix_fournisseur
    GROUP BY MATNR, trimestre
    HAVING COUNT(*) >= 2
)
SELECT
    COUNT(*) AS groupes_article_trimestre,
    ROUND(100 * MEDIAN(ecart), 2) AS ecart_median_pct,
    ROUND(100 * QUANTILE_CONT(ecart, 0.25), 2) AS q1_pct,
    ROUND(100 * QUANTILE_CONT(ecart, 0.75), 2) AS q3_pct
FROM ecarts;