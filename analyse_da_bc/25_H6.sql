SELECT
    COUNT(*) AS lignes_population,
    ROUND(100 * MEDIAN(ecart), 2) AS ecart_median_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ecart > 0.10) / COUNT(*), 2) AS part_sup_10_pct
FROM (
    SELECT ABS(prix_unitaire_eur - prix_estime_unitaire) / prix_estime_unitaire AS ecart
    FROM commandes
    WHERE prix_estime_unitaire > 0
);