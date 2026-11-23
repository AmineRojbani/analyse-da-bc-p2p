# Journal d'audit des données

## Synthèse

| N° | Fichier | Contrôle | Résultat | Verdict |
|---|---|---|---|---|
| 00 | `00_charger.sql` | Chargement des six tables | Effectifs conformes | OK |
| 01 | `01_vues.sql` | Typage | Effectifs des vues identiques | OK |
| 02 | `02_audit_conversions.sql` | Valeurs perdues à la conversion | 0 sur 15 colonnes | OK |
| 03 | `03_audit_cles.sql` | Unicité des clés | 0 doublon | OK |
| 04 | `04_audit_liens.sql` | Liens entre tables | 7 contrôles à 0 ; 1 875 lignes de commande sans demande | À analyser (H3) |
| 05 | `05_audit_colonnes.sql` | Plausibilité des valeurs | 14 contrôles à 0 ; 516 commandes datées après sept. 2026 | Expliqué (fin de période) |
| 06 | `06_audit_statuts.sql` | Statuts et codes | `BSART` constant ; écart `EBAKZ` / `STATU` expliqué | OK |
| 07 | `07_audit_population_approbation.sql` | Population de l'approbation | H1 : 17 982 demandes | Règles fixées |
| 08 | `08_audit_profil_mensuel.sql` | Profil mensuel | Septembre 2026 : 5,8 % sans commande contre environ 3 % | Règle N fixée |
| 09 | `09_audit_grain.sql` | Grain demande → commande | 816 demandes en deux commandes | Règle fixée |
| 10 | `10_audit_prix_devises.sql` | Prix et devises | Dispersion faible ; 1 764 bons en dollars ; aucun taux | H8 conduite ; taux à fixer |

---

## 00. Chargement

**Objet.** Copier chaque CSV dans une table brute `raw_*`, toutes colonnes en texte. Une conversion automatique ferait perdre les zéros initiaux des identifiants (`0010021412`) et casserait les jointures.

**Résultat.**

| Table | Lignes |
|---|---|
| EBAN | 32 000 |
| EKKO | 26 483 |
| EKPO | 32 046 |
| LFA1 | 620 |
| MARA | 408 |
| T023T | 14 |

**Lecture.** Les effectifs correspondent à l'extraction. Aucune ligne n'est perdue ni ajoutée à la lecture.

---

## 01. Typage

**Objet.** Convertir ce qui doit l'être dans des vues `v_*`, sans toucher aux tables brutes : sans dates ni nombres, aucun délai ni aucun montant ne se calcule.

| Nature | Conversion |
|---|---|
| Clés et codes (BANFN, EBELN, LIFNR, MATNR, BSART, LOEKZ...) | Texte |
| Dates | `TRY_CAST(col AS DATE)` |
| Décimaux | `TRY_CAST(REPLACE(col, ',', '.') AS DECIMAL(18,4))` |
| PEINH | `TRY_CAST(col AS INTEGER)` |

Colonnes converties (15) : EBAN (ERDAT, BADAT, LFDAT, FRGDT, BEDAT, MENGE, PREIS, BSMNG, PEINH), EKKO (AEDAT, BEDAT), EKPO (MENGE, NETPR, NETWR, PEINH).

**Résultat.** Les six vues ont les mêmes effectifs que les tables brutes.

**Lecture.** La création des vues ne supprime aucune ligne. La qualité des valeurs converties est contrôlée en 02.

---

## 02. Conversions ratées

**Objet.** `TRY_CAST` renvoie `NULL` sans message quand une valeur est invalide. On compte, par colonne, les valeurs présentes en texte mais vides après conversion. Les cellules vides à l'origine ne comptent pas.

**Résultat.** 0 sur les 15 colonnes.

**Lecture.** Toutes les dates sont lisibles et tous les nombres convertibles. La plausibilité des valeurs est contrôlée en 05.

---

## 03. Unicité des clés

**Objet.** Une clé en double multiplierait les lignes à la jointure et fausserait comptages et montants.

**Résultat.** 0 doublon sur : EBAN (BANFN + BNFPO), EKKO (EBELN), EKPO (EBELN + EBELP), LFA1 (LIFNR), MARA (MATNR), T023T (MATKL).

**Lecture.** Chaque ligne est identifiable de façon unique.

---

## 04. Liens entre les tables

**Objet.** Repérer les lignes sans correspondance (`LEFT JOIN` puis `WHERE colonne_de_droite IS NULL`). Une référence **vide** (absence de référence) se distingue d'une référence **cassée** (renseignée mais introuvable) : seule la seconde est une anomalie de données.

**Résultat.**

| Contrôle | Lignes |
|---|---|
| EKPO sans en-tête EKKO | 0 |
| EKKO sans aucune ligne EKPO | 0 |
| **EKPO sans demande rattachée (BANFN vide)** | **1 875** |
| EKPO avec BANFN absent de EBAN | 0 |
| EBAN avec EBELN absent de EKKO | 0 |
| EKKO avec fournisseur absent de LFA1 | 0 |
| EKPO avec article absent de MARA | 0 |
| EKPO avec famille absente de T023T | 0 |

**Lecture.**
- Aucune référence cassée : les tables se joignent sans perte.
- Les 1 875 lignes sans demande sont un fait du processus (commandes passées sans demande), pas un défaut de données. Elles représentent **5,85 %** des 32 046 lignes de commande.
- Cette requête compte des **lignes**, pas des commandes. La part en nombre de commandes (avec au moins une ligne sans demande, ou entièrement sans demande), la répartition par mois et le nombre de lignes sans code article ne sont pas calculés ici : ils sont établis dans l'analyse de H3. H3 se mesure en lignes de commande ; la part en commandes est donnée en complément.

**Décision.** Le seuil de H3 (moins de 5 %) ne change pas ; le résultat est rapporté tel quel.

---

## 05. Plausibilité des valeurs

**Objet.** Chercher l'impossible : dates hors fenêtre, quantités et prix négatifs, approbation avant création, colonnes jumelles.

**Résultat.**

| Contrôle | Lignes |
|---|---|
| EBAN.ERDAT hors 01/10/2024 – 30/09/2026 | 0 |
| **EKKO.BEDAT hors 01/10/2024 – 30/09/2026** | **516** |
| EBAN.ERDAT vide | 0 |
| EBAN.ERDAT différent de BADAT | 0 |
| EKKO.AEDAT différent de BEDAT | 0 |
| MENGE ≤ 0 (EBAN, EKPO) | 0 |
| PREIS ≤ 0 (EBAN) ; NETPR, NETWR ≤ 0 (EKPO) | 0 |
| PEINH ≤ 0 (EBAN, EKPO) | 0 |
| EBAN.BSMNG supérieur à MENGE | 0 |
| EBAN.FRGDT avant ERDAT | 0 |
| EBAN.LFDAT avant ERDAT | 0 |

**Lecture.**
- `ERDAT` et `BADAT` sont identiques, `AEDAT` et `BEDAT` aussi : ces colonnes jumelles n'apportent rien de plus.
- Les 516 commandes postérieures au 30 septembre 2026 ne sont pas une erreur. La fenêtre porte sur la création des **demandes** ; l'extraction date du 4 novembre 2026.
- Conséquence : les demandes récentes ont eu moins de temps pour être commandées (censure à droite). Mesurée en 08.

---

## 06. Statuts et codes

**Objet.** Établir le sens et la fréquence de chaque colonne de statut avant de s'en servir pour filtrer ou segmenter.

**Résultat.**

| Colonne | Valeurs (nombre de lignes) |
|---|---|
| EBAN.ESTKZ (origine) | B : 12 912 ; R : 19 088 |
| EBAN.FRGST (niveau de validation) | vide : 12 912 ; S1 : 2 306 ; S2 : 9 961 ; S3 : 6 821 |
| EBAN.LOEKZ (rejet ou suppression) | vide : 30 350 ; X : 1 650 |
| EBAN.STATU | B : 29 355 ; N : 2 645 |
| EBAN.EBAKZ (clôture) | X : 28 817 ; vide : 3 183 |
| EBAN.BSART, EKKO.BSART | NB partout |
| EKKO.LOEKZ, EKPO.LOEKZ | toujours vide |

**Lecture.**
1. `BSART` est constant (`NB`) : aucune segmentation par type de document.
2. `STATU = B` (29 355) correspond aux demandes non rejetées ayant une commande ; `STATU = N` (2 645) aux 1 650 rejets plus 995 demandes non rejetées sans commande.
3. `EBAKZ = X` compte 538 lignes de moins que `STATU = B`. Ces 538 lignes sont **commandées en partie seulement** (`BSMNG` > 0 et inférieur à `MENGE`) ; `EBAKZ = X` marque les demandes entièrement commandées (28 817).
4. Les rejets existent seulement dans EBAN : EKKO et EKPO ne contiennent aucune ligne supprimée.

---

## 07. Population de l'approbation

**Objet.** Établir quelles demandes portent une date de libération (`FRGDT`), donc quelles demandes sont mesurables en H1, H2 et H4.

**Résultat.**

| Origine | Libération | Rejet | Commande | Lignes de demande |
|---|---|---|---|---|
| B (MRP) | sans FRGDT | non | oui | 11 969 |
| B (MRP) | sans FRGDT | non | non | 399 |
| B (MRP) | sans FRGDT | oui | non | 544 |
| R (manuelle) | avec FRGDT | non | oui | 17 386 |
| R (manuelle) | avec FRGDT | non | non | 596 |
| R (manuelle) | sans FRGDT | oui | non | 1 106 |

Niveau de validation des demandes manuelles : S1 2 306 (dont 2 235 avec `FRGDT`), S2 9 961 (9 467), S3 6 821 (6 280).

**Lecture.**
- Les 12 912 demandes MRP n'ont ni niveau de validation ni date de libération : elles ne passent pas par une approbation.
- Parmi les 19 088 demandes manuelles, 17 982 ont une date de libération ; les 1 106 autres sont toutes des rejets. `FRGST` est renseigné même pour ces rejets.
- Les 1 650 lignes rejetées (544 MRP, 1 106 manuelles) n'ont aucune commande. H5 est testée formellement à l'analyse.
- Les lignes de commande rattachées à une demande libérée sont au nombre de 17 824.

**Règles fixées.**
- H1 : demandes manuelles non rejetées avec `FRGDT` (17 982 ; par niveau : 2 235, 9 467, 6 280).
- H4 : mêmes demandes ; dénominateur de 17 824 lignes de commande.
- H2 : demandes manuelles libérées, de `FRGDT` à la première commande ; le délai des demandes MRP, de `ERDAT` à la première commande, est présenté à part.

---

## 08. Profil mensuel

**Objet.** Vérifier que l'observation est complète et homogène sur la période : par mois de création, nombre de demandes non rejetées, part sans commande, délai médian ; puis distribution des délais (`08b_audit_distribution_delais.sql`).

**Résultat.**
- Part de demandes sans commande : entre 2,4 % et 3,9 % pour chaque mois, **5,8 % en septembre 2026** (89 sur 1 535).
- Délai médian demande → commande : entre 7 et 10 jours selon le mois, 9 jours en septembre 2026.
- Distribution du délai de `ERDAT` à la première commande (29 355 demandes commandées) :

| Médiane | 90e centile | 95e centile | 99e centile | Maximum |
|---|---|---|---|---|
| 8 jours | 31 jours | 43 jours | 76 jours | 146 jours |

**Lecture.**
- Les demandes de fin de période ont eu moins de temps pour être commandées : leur part sans commande est surestimée (censure à droite). L'effet est net sur septembre 2026.
- Le délai médian ne montre pas d'effet : la censure ne joue que sur les délais longs.

**Règle fixée.** N = 45 jours, valeur proche du 95e centile. Les demandes créées après le 20 septembre 2026 sont exclues de H7. Sensibilité à 30 et 60 jours.

---

## 09. Grain demande → commande

**Objet.** Une ligne de demande peut-elle alimenter plusieurs lignes de commande ? Si oui, une jointure EBAN–EKPO répète la demande et fausse les comptages.

**Résultat.**
- 816 lignes de demande sont reliées à **deux** lignes de commande (1 632 lignes) ; aucune à plus de deux.
- Les deux lignes appartiennent à deux commandes distinctes dans les 816 cas.
- La somme des quantités commandées est égale à la quantité demandée, et `BSMNG` est égal à cette somme, dans les 816 cas.
- L'écart entre les deux dates de commande est de 8 jours en médiane (de 2 à 80 jours).

**Lecture.** Ce sont des commandes fractionnées : la quantité demandée est répartie sur deux commandes. `EBAN.EBELN` et `EBAN.BEDAT` ne gardent que la dernière.

**Règles fixées.**
- La date de commande d'une demande est celle de la **première** commande ; contrôle avec la dernière.
- Les demandes se comptent dans EBAN, jamais dans une jointure avec EKPO.
- Les 538 demandes commandées en partie forment un statut à part.

---

## 10. Prix et devises

**Objet.** Vérifier que les prix permettent H6 et H8, et que les montants s'additionnent en euros.

**Résultat.**

| Mesure | Valeur |
|---|---|
| Articles commandés auprès de plusieurs fournisseurs | 328 |
| Lignes de commande sans code article | 9 040 (28,2 %) |
| Bons de commande en dollars | 1 764 (6,7 % des 26 483) |
| Taux de change dans les six tables | aucun |
| Coefficient de variation du prix unitaire par article, en euros (374 articles de plus de 5 lignes) | médiane 6,8 % ; 90e centile 10,9 % |

**Lecture.**
- Le prix d'un même article reste dans une bande étroite : le critère de H8 (coefficient de variation médian inférieur à 15 %) est atteint. H8 est conduite.
- Ce critère mesure la stabilité du prix d'un article ; il ne dit pas si les prix sont propres à l'article ou communs à sa famille. Toute conclusion sur H8 reste prudente.
- Les commandes en dollars exigent un taux de change, absent des données. H6 et H8 ne se calculent qu'avec un taux unique fixé avant l'analyse.
- Les lignes sans code article (services, achats indirects) sont exclues de H8.

---

## Règles de mesure fixées

| Règle | Valeur |
|---|---|
| Unité de demande | Ligne de demande (BANFN + BNFPO), comptée dans EBAN |
| Unité de commande | Ligne de commande (EBELN + EBELP) |
| Date de commande d'une demande | Première commande |
| Population de H1, H4 | Demandes manuelles non rejetées avec `FRGDT` |
| Population de H2 | Idem ; demandes MRP à part (ERDAT → première commande) |
| Demandes rejetées (LOEKZ = X) | Comptées seulement pour H5 |
| N (H7) | 45 jours (date limite de création : 20/09/2026) ; sensibilité 30 et 60 |
| Commandes partielles | Statut à part |
| Devises | Taux unique en euros, à fixer avant l'analyse |

## Points à trancher avant l'analyse

1. Taux de change à retenir pour les 1 764 bons en dollars.
2. Seuils des hypothèses, à confirmer par l'expert avant de les figer.
3. Unité de H3 : lignes de commande (retenue) avec la part en bons en complément.
