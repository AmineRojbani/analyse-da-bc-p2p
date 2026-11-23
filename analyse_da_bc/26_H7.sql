SELECT
    n.jours AS n_jours,
    COUNT(*) AS demandes_population,
    COUNT(*) FILTER (WHERE d.statut = 'jamais_commandee') AS jamais_commandees,
    ROUND(100.0 * COUNT(*) FILTER (WHERE d.statut = 'jamais_commandee') / COUNT(*), 2) AS part_pct
FROM (VALUES (30), (45), (60)) AS n(jours)
JOIN demandes d ON d.dans_h1 AND d.anciennete_jours >= n.jours
GROUP BY n.jours
ORDER BY n.jours;