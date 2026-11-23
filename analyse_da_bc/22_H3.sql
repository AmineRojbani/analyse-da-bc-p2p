SELECT
    COUNT(*) FILTER (WHERE sans_demande) AS lignes_sans_demande,
    COUNT(*) AS lignes_total,
    ROUND(100.0 * COUNT(*) FILTER (WHERE sans_demande) / COUNT(*), 2) AS part_pct
FROM commandes;