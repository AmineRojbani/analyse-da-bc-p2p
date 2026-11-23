SELECT ESTKZ AS origine,
       COALESCE(FRGST, '-') AS niveau_validation,
       CASE WHEN FRGDT IS NULL THEN 'sans FRGDT' ELSE 'avec FRGDT' END AS liberation,
       CASE WHEN LOEKZ = 'X' THEN 'rejetée' ELSE 'non rejetée' END AS rejet,
       CASE WHEN EBELN IS NULL THEN 'sans commande' ELSE 'avec commande' END AS commande,
       COUNT(*) AS lignes_demande
FROM v_eban
GROUP BY ALL
ORDER BY 1, 2, 3, 4, 5;