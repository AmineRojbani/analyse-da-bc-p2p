SELECT strftime(ERDAT, '%Y-%m') AS mois_creation,
       COUNT(*) AS demandes,
       COUNT(*) FILTER (WHERE EBELN IS NULL) AS sans_commande,
       ROUND(100.0 * COUNT(*) FILTER (WHERE EBELN IS NULL) / COUNT(*), 1) AS pct_sans_commande,
       MEDIAN(date_diff('day', ERDAT, BEDAT)) FILTER (WHERE EBELN IS NOT NULL) AS delai_median_jours
FROM v_eban
WHERE LOEKZ IS NULL
GROUP BY mois_creation
ORDER BY mois_creation;