WITH multi AS (
    SELECT BANFN, BNFPO,
           COUNT(*) AS nb_lignes,
           COUNT(DISTINCT EBELN) AS nb_commandes,
           SUM(MENGE) AS qte_commandee
    FROM v_ekpo
    WHERE BANFN IS NOT NULL
    GROUP BY BANFN, BNFPO
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS demandes_en_plusieurs_lignes,
       MAX(m.nb_lignes) AS max_lignes_par_demande,
       COUNT(*) FILTER (WHERE m.nb_commandes = m.nb_lignes) AS commandes_distinctes,
       COUNT(*) FILTER (WHERE m.qte_commandee = e.MENGE) AS somme_egale_quantite_demandee,
       COUNT(*) FILTER (WHERE m.qte_commandee = e.BSMNG) AS somme_egale_bsmng
FROM multi m
JOIN v_eban e ON e.BANFN = m.BANFN AND e.BNFPO = m.BNFPO;