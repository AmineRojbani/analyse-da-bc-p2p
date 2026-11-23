SELECT
    COUNT(*) FILTER (WHERE nb_commandes > 0) AS rejetees_commandees,
    COUNT(*) AS demandes_rejetees
FROM demandes
WHERE statut = 'rejetee';