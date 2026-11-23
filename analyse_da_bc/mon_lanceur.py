import sys
import duckdb

fichier_sql = sys.argv[1]
con = duckdb.connect("analyse_da_bc/audit.duckdb")
texte = open(fichier_sql, encoding="utf-8").read()

for requete in con.extract_statements(texte):
    resultat = con.sql(requete)
    if resultat is not None:
        resultat.show(max_width=300, max_rows=100)

con.close()