CREATE OR REPLACE TABLE raw_eban AS
SELECT * FROM read_csv('sorties/EBAN.csv', delim=';', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw_ekko AS
SELECT * FROM read_csv('sorties/EKKO.csv', delim=';', header=true, all_varchar=true); 
CREATE OR REPLACE TABLE raw_ekpo AS
SELECT * FROM read_csv('sorties/EKPO.csv', delim=';', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw_lfa1 AS
SELECT * FROM read_csv('sorties/LFA1.csv', delim=';', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw_mara AS
SELECT * FROM read_csv('sorties/MARA.csv', delim=';', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw_t023t AS
SELECT * FROM read_csv('sorties/T023T.csv', delim=';', header=true, all_varchar=true);


SELECT COUNT(*) AS nb_lignes FROM raw_eban;
SELECT COUNT(*) AS nb_lignes FROM raw_ekko;
SELECT COUNT(*) AS nb_lignes FROM raw_ekpo;
SELECT COUNT(*) AS nb_lignes FROM raw_lfa1;
SELECT COUNT(*) AS nb_lignes FROM raw_mara;
SELECT COUNT(*) AS nb_lignes FROM raw_t023t;

SELECT 'EBAN' AS table_, COUNT(*) AS nb_lignes FROM raw_eban
UNION ALL SELECT 'EKKO', COUNT(*) FROM raw_ekko
UNION ALL SELECT 'EKPO', COUNT(*) FROM raw_ekpo
UNION ALL SELECT 'LFA1', COUNT(*) FROM raw_lfa1
UNION ALL SELECT 'MARA', COUNT(*) FROM raw_mara
UNION ALL SELECT 'T023T', COUNT(*) FROM raw_t023t;