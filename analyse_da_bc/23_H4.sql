-- H4 : moins de 2 % des lignes de commande sont passees avant la liberation de leur demande.
-- Population : lignes dont la demande a une date de liberation (17 824).
SELECT
    COUNT(*) FILTER (WHERE commande_avant_liberation) AS lignes_avant_liberation,
    COUNT(*) AS lignes_population,
    ROUND(100.0 * COUNT(*) FILTER (WHERE commande_avant_liberation) / COUNT(*), 2) AS part_pct
FROM commandes
WHERE date_liberation IS NOT NULL;