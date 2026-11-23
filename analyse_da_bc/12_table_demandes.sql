CREATE OR REPLACE TABLE demandes AS
WITH cmd AS (
    SELECT p.BANFN, p.BNFPO,
           COUNT(DISTINCT p.EBELN) AS nb_commandes,
           MIN(k.BEDAT)            AS date_premiere_commande
    FROM v_ekpo p
    JOIN v_ekko k ON p.EBELN = k.EBELN
    WHERE p.BANFN IS NOT NULL
    GROUP BY p.BANFN, p.BNFPO
),
base AS (
    SELECT e.BANFN, e.BNFPO, e.ERDAT, e.ESTKZ,
           CASE WHEN e.ESTKZ = 'B' THEN 'MRP' ELSE 'manuelle' END AS origine,
           e.FRGST, e.FRGDT, e.LOEKZ, e.MENGE, e.BSMNG, e.MATKL,
           t.TYPE_ACHAT AS type_achat,
           COALESCE(c.nb_commandes, 0) AS nb_commandes,
           c.date_premiere_commande,
           CASE WHEN e.LOEKZ = 'X'                   THEN 'rejetee'
                WHEN COALESCE(c.nb_commandes, 0) = 0 THEN 'jamais_commandee'
                WHEN e.BSMNG < e.MENGE               THEN 'commandee_en_partie'
                ELSE 'commandee' END AS statut
    FROM v_eban e
    LEFT JOIN cmd c ON e.BANFN = c.BANFN AND e.BNFPO = c.BNFPO
    LEFT JOIN raw_t023t t ON e.MATKL = t.MATKL
)
SELECT b.*,
       cal_lib.rang_ouvre - cal_cre.rang_ouvre AS delai_liberation,
       cal_cmd.rang_ouvre - cal_lib.rang_ouvre AS delai_commande,
       cal_cmd.rang_ouvre - cal_cre.rang_ouvre AS delai_creation_commande,
       DATE_DIFF('day', b.ERDAT, DATE '2026-11-04') AS anciennete_jours,
       (b.origine = 'manuelle' AND b.LOEKZ IS NULL AND b.FRGDT IS NOT NULL) AS dans_h1,
       (b.origine = 'manuelle' AND b.LOEKZ IS NULL AND b.FRGDT IS NOT NULL
        AND b.ERDAT <= DATE '2026-09-20') AS dans_h7
FROM base b
LEFT JOIN calendrier cal_cre ON cal_cre.jour = b.ERDAT
LEFT JOIN calendrier cal_lib ON cal_lib.jour = b.FRGDT
LEFT JOIN calendrier cal_cmd ON cal_cmd.jour = b.date_premiere_commande;