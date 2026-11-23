CREATE OR REPLACE TABLE commandes AS
SELECT p.EBELN, p.EBELP, p.BANFN, p.BNFPO,
       p.MATNR, p.MATKL, k.LIFNR, k.WAERS,
       k.BEDAT AS date_commande,
       strftime(k.BEDAT, '%Y') || '-T' || CAST(QUARTER(k.BEDAT) AS VARCHAR) AS trimestre,
       p.MENGE,
       (p.BANFN IS NULL) AS sans_demande,
       p.NETPR / p.PEINH / CASE WHEN k.WAERS = 'USD' THEN 1.133 ELSE 1 END AS prix_unitaire_eur,
       e.PREIS / e.PEINH AS prix_estime_unitaire,
       d.FRGDT AS date_liberation,
       (k.BEDAT < d.FRGDT) AS commande_avant_liberation
FROM v_ekpo p
JOIN v_ekko k ON p.EBELN = k.EBELN
LEFT JOIN v_eban e ON p.BANFN = e.BANFN AND p.BNFPO = e.BNFPO
LEFT JOIN demandes d ON p.BANFN = d.BANFN AND p.BNFPO = d.BNFPO;