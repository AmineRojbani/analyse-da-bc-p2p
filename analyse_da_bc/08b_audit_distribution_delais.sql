WITH premiere_commande AS (
    SELECT e.BANFN, e.BNFPO, e.ERDAT, MIN(k.BEDAT) AS date_commande
    FROM v_eban e
    JOIN v_ekpo p ON p.BANFN = e.BANFN AND p.BNFPO = e.BNFPO
    JOIN v_ekko k ON k.EBELN = p.EBELN
    GROUP BY e.BANFN, e.BNFPO, e.ERDAT
)
SELECT COUNT(*) AS demandes_commandees,
       MEDIAN(date_diff('day', ERDAT, date_commande)) AS mediane,
       QUANTILE_CONT(date_diff('day', ERDAT, date_commande), 0.90) AS p90,
       QUANTILE_CONT(date_diff('day', ERDAT, date_commande), 0.95) AS p95,
       QUANTILE_CONT(date_diff('day', ERDAT, date_commande), 0.99) AS p99,
       MAX(date_diff('day', ERDAT, date_commande)) AS maximum
FROM premiere_commande;