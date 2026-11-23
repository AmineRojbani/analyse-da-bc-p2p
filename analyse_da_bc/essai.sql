SELECT COUNT(*) AS nb_lignes,
       COUNT(DISTINCT (EBELN, EBELP)) AS lignes_distinctes,
       COUNT(*) FILTER (WHERE sans_demande) AS sans_demande,
       COUNT(*) FILTER (WHERE date_liberation IS NOT NULL) AS pop_h4,
       COUNT(*) FILTER (WHERE MATNR IS NULL) AS sans_article,
       COUNT(*) FILTER (WHERE WAERS = 'USD') AS lignes_usd,
       COUNT(*) FILTER (WHERE prix_unitaire_eur IS NULL) AS prix_vides,
       COUNT(DISTINCT trimestre) AS nb_trimestres,
       SUM(MENGE) AS quantite_totale
FROM commandes;
