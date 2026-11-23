import os
import sys
import duckdb
import statistics
import matplotlib.pyplot as plt

DOSSIER = "analyse_da_bc/graphiques"
COULEUR = "#4C78A8"
COULEUR_SEUIL = "#C44E52"


def requete(sql):
    con = duckdb.connect("analyse_da_bc/audit.duckdb", read_only=True)
    lignes = con.sql(sql).fetchall()
    con.close()
    return lignes


def enregistrer(fig, nom):
    os.makedirs(DOSSIER, exist_ok=True)
    fig.savefig(f"{DOSSIER}/{nom}.png", dpi=150)
    plt.close(fig)


def graphique_h1():
    lignes = requete("""
        SELECT FRGST,
               MEDIAN(delai_liberation),
               QUANTILE_CONT(delai_liberation, 0.25),
               QUANTILE_CONT(delai_liberation, 0.75)
        FROM demandes
        WHERE dans_h1
        GROUP BY FRGST
        ORDER BY FRGST
    """)

    niveaux = [l[0] for l in lignes]
    mediane = [l[1] for l in lignes]
    q1 = [l[2] for l in lignes]
    q3 = [l[3] for l in lignes]
    barres = [[m - a for m, a in zip(mediane, q1)],
              [b - m for m, b in zip(mediane, q3)]]

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.bar(niveaux, mediane, yerr=barres, capsize=6, color="#4C78A8")
    ax.set_xlabel("Niveau de validation")
    ax.set_ylabel("Délai de libération (jours ouvrés)")
    ax.set_title("H1 : médiane et quartiles du délai par niveau")
    fig.tight_layout()

    enregistrer(fig, "h1_delai_par_niveau")


def graphique_h1_distribution():
    lignes = requete("""
        SELECT FRGST, delai_liberation, COUNT(*)
        FROM demandes
        WHERE dans_h1
        GROUP BY FRGST, delai_liberation
    """)

    max_jours = 15  # au-delà, on regroupe dans "15+"
    niveaux = ["S1", "S2", "S3"]
    effectif = {n: [0] * (max_jours + 1) for n in niveaux}
    for niveau, delai, nb in lignes:
        position = min(delai, max_jours)
        effectif[niveau][position] += nb

    # même échelle verticale pour les trois graphiques
    parts = {n: [100 * nb / sum(effectif[n]) for nb in effectif[n]] for n in niveaux}
    ymax = max(max(p) for p in parts.values()) * 1.1
    etiquettes = [str(j) for j in range(max_jours)] + [f"{max_jours}+"]

    for niveau in niveaux:
        fig, ax = plt.subplots(figsize=(7, 4))
        ax.bar(range(max_jours + 1), parts[niveau], color="#4C78A8")
        ax.set_xticks(range(max_jours + 1))
        ax.set_xticklabels(etiquettes)
        ax.set_ylim(0, ymax)
        ax.set_xlabel("Délai de libération (jours ouvrés)")
        ax.set_ylabel("Part des demandes du niveau (%)")
        ax.set_title(f"H1 : distribution du délai de libération, niveau {niveau} "
                     f"({sum(effectif[niveau])} demandes)")
        fig.tight_layout()
        enregistrer(fig, f"h1_distribution_{niveau.lower()}")

def graphique_h2():
    requete_base = """
        SELECT type_achat,
               MEDIAN({d}),
               QUANTILE_CONT({d}, 0.25),
               QUANTILE_CONT({d}, 0.75)
        FROM demandes
        WHERE {filtre} AND {d} IS NOT NULL
        GROUP BY type_achat
        ORDER BY type_achat
    """
    manuelle = requete(requete_base.format(d="delai_commande", filtre="dans_h1"))
    mrp = requete(requete_base.format(d="delai_creation_commande", filtre="origine = 'MRP'"))

    fig, axes = plt.subplots(1, 2, figsize=(9, 4.5), sharey=True)
    groupes = [
        (axes[0], manuelle, "Demandes manuelles\n(libération → première commande)"),
        (axes[1], mrp, "Demandes MRP\n(création → première commande)"),
    ]
    for ax, lignes, titre in groupes:
        types = [l[0] for l in lignes]
        mediane = [l[1] for l in lignes]
        q1 = [l[2] for l in lignes]
        q3 = [l[3] for l in lignes]
        barres = [[m - a for m, a in zip(mediane, q1)],
                  [b - m for m, b in zip(mediane, q3)]]
        ax.bar(types, mediane, yerr=barres, capsize=6, color=["#4C78A8", "#F58518"])
        ax.set_title(titre)
    axes[0].set_ylabel("Délai (jours ouvrés)")
    fig.suptitle("H2 : médiane et quartiles du délai avant la première commande, par type d'achat")
    fig.tight_layout()

    enregistrer(fig, "h2_delai_par_type_achat")

def graphique_h3():
    (sans, total), = requete("""
        SELECT COUNT(*) FILTER (WHERE sans_demande), COUNT(*)
        FROM commandes
    """)
    part = 100.0 * sans / total

    fig, ax = plt.subplots(figsize=(5, 4))
    ax.bar(["Lignes sans demande"], [part], color=COULEUR, width=0.5)
    ax.axhline(5, color=COULEUR_SEUIL, linestyle="--")
    ax.text(0.28, 5.1, "Seuil : 5 %", color=COULEUR_SEUIL)
    ax.text(0, part / 2, f"{part:.2f} %\n({sans:,} sur {total:,})".replace(",", " "),
            ha="center", color="white", fontsize=10)
    ax.set_ylim(0, max(part, 5) * 1.3)
    ax.set_ylabel("Part des lignes de commande (%)")
    ax.set_title("H3 : lignes de commande sans demande")
    fig.tight_layout()

    enregistrer(fig, "h3_part_sans_demande")



#H6
def graphique_h6():
    valeurs = [l[0] for l in requete("""
        SELECT 100 * ABS(prix_unitaire_eur - prix_estime_unitaire) / prix_estime_unitaire
        FROM commandes
        WHERE prix_estime_unitaire > 0
    """)]
    mediane = statistics.median(valeurs)
    part_10 = 100.0 * sum(v > 10 for v in valeurs) / len(valeurs)
    plafond = 30
    affichees = [min(v, plafond) for v in valeurs]

    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.hist(affichees, bins=[i for i in range(0, plafond + 1)], color=COULEUR)
    ax.axvline(mediane, color="black", linestyle="-", label=f"Médiane : {mediane:.2f} %")
    ax.axvline(5, color=COULEUR_SEUIL, linestyle="--", label="Seuil de la médiane : 5 %")
    ax.axvline(10, color=COULEUR_SEUIL, linestyle=":",
               label=f"Au-delà de 10 % : {part_10:.2f} % des lignes (seuil : 5 %)")
    ax.set_xlabel(f"Écart relatif entre prix commandé et prix estimé (%, regroupé à {plafond}+)")
    ax.set_ylabel("Nombre de lignes de commande")
    ax.set_title(f"H6 : écart de prix ({len(valeurs):,} lignes)".replace(",", " "))
    ax.legend()
    fig.tight_layout()

    enregistrer(fig, "h6_ecart_prix")


#H7

def graphique_h7():
    lignes = requete("""
        SELECT n.jours,
               100.0 * COUNT(*) FILTER (WHERE d.statut = 'jamais_commandee') / COUNT(*)
        FROM (VALUES (30), (45), (60)) AS n(jours)
        JOIN demandes d ON d.dans_h1 AND d.anciennete_jours >= n.jours
        GROUP BY n.jours
        ORDER BY n.jours
    """)
    etiquettes = [f"N = {l[0]} jours" for l in lignes]
    parts = [l[1] for l in lignes]

    fig, ax = plt.subplots(figsize=(6.5, 4.5))
    barres = ax.bar(etiquettes, parts, color=COULEUR, width=0.5)
    for barre, part in zip(barres, parts):
        ax.text(barre.get_x() + barre.get_width() / 2, part + 0.15, f"{part:.2f} %", ha="center")
    for seuil in (3, 5):
        ax.axhline(seuil, color=COULEUR_SEUIL, linestyle="--")
        ax.text(2.45, seuil + 0.1, f"Seuil {seuil} %", color=COULEUR_SEUIL, ha="right")
    ax.set_ylim(0, 6)
    ax.set_ylabel("Part de demandes jamais commandées (%)")
    ax.set_title("H7 : demandes libérées jamais commandées")
    fig.tight_layout()

    enregistrer(fig, "h7_jamais_commandees")

#H8

def graphique_h8():
    valeurs = [l[0] for l in requete("""
        WITH prix_fournisseur AS (
            SELECT MATNR, trimestre, LIFNR, MEDIAN(prix_unitaire_eur) AS prix
            FROM commandes
            WHERE MATNR IS NOT NULL
            GROUP BY MATNR, trimestre, LIFNR
        )
        SELECT 100 * (MAX(prix) - MIN(prix)) / MIN(prix)
        FROM prix_fournisseur
        GROUP BY MATNR, trimestre
        HAVING COUNT(*) >= 2
    """)]
    mediane = statistics.median(valeurs)
    plafond = 50
    affichees = [min(v, plafond) for v in valeurs]

    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.hist(affichees, bins=[i * 2 for i in range(0, plafond // 2 + 1)], color=COULEUR)
    ax.axvline(mediane, color="black", label=f"Médiane : {mediane:.2f} %")
    ax.set_xlabel(f"Écart entre fournisseur le moins cher et le plus cher (%, regroupé à {plafond}+)")
    ax.set_ylabel("Nombre de groupes article-trimestre")
    ax.set_title(f"H8 : écart de prix entre fournisseurs ({len(valeurs):,} groupes)".replace(",", " "))
    ax.legend()
    fig.tight_layout()

    enregistrer(fig, "h8_ecart_fournisseurs")  


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage : python analyse_da_bc/graphiques.py h1")
        sys.exit(1)
    nom = "graphique_" + sys.argv[1]
    if nom not in globals():
        print(f"Graphique inconnu : {sys.argv[1]}")
        sys.exit(1)
    globals()[nom]()