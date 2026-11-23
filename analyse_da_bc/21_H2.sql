SELECT 
    type_achat AS type_achat,
    COUNT(*) AS effectif,
    MEDIAN(delai_commande) AS Mediane,
    QUANTILE_CONT(delai_commande, 0.25) AS q1,
    QUANTILE_CONT(delai_commande, 0.75) AS q3
FROM demandes
WHERE dans_h1 AND delai_commande IS NOT NULL 
GROUP BY type_achat
ORDER BY type_achat;


SELECT 
    type_achat AS type_achat,
    COUNT(*) AS effectif,
    MEDIAN(delai_creation_commande) AS Mediane,
    QUANTILE_CONT(delai_creation_commande, 0.25) AS q1,
    QUANTILE_CONT(delai_creation_commande, 0.75) AS q3
FROM demandes
WHERE origine = 'MRP' AND delai_creation_commande IS NOT NULL
GROUP BY type_achat
ORDER BY type_achat;