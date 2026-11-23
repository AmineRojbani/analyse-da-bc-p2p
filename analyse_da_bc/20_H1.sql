SELECT
    FRGST AS niv_validation,
    COUNT(*) AS effectif_niv,
    MEDIAN(delai_liberation) AS Mediane,
    QUANTILE_CONT(delai_liberation, 0.25) AS q1,
    QUANTILE_CONT(delai_liberation, 0.75) AS q3
FROM demandes
WHERE dans_h1
GROUP BY FRGST
ORDER BY FRGST;