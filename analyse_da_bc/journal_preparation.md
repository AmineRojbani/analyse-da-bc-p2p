# Journal de préparation (phase 2)

Ce journal raconte la phase 2 : de quoi les hypothèses ont besoin, ce que les tables brutes ne fournissent pas, et ce que l'on construit en conséquence. Il se complète au fil du travail : chaque mesure de préparation y est inscrite avec le besoin qui la justifie.

## Synthèse

| Étape | Besoin | Décision | Statut |
|---|---|---|---|
| 1 | Les hypothèses H1–H8 demandent des mesures que les tables brutes ne contiennent pas | Lister, hypothèse par hypothèse, ce qu'il faut ajouter | Fait |
| 2 | Certaines hypothèses comptent des demandes, d'autres des lignes de commande | Construire deux tables de travail, une par grain | Fait |
| 3 | Plusieurs hypothèses réclament les mêmes colonnes | Construire ces colonnes communes en premier | Fait |
| 4 | Des choix restent ouverts (taux USD, jours ouvrés) | Les trancher au moment où la colonne concernée est construite | Fait |
| 5 | Vérifier que rien n'a été perdu ni dupliqué | Totaux de contrôle : 32 000 demandes, 32 046 lignes de commande | Fait |

---

## 1. Point de départ : ce que les hypothèses demandent

L'audit a établi que les six tables sont propres : conversions sans perte, clés uniques, liens cohérents. Mais « propres » ne veut pas dire « prêtes à répondre ». H1 parle d'un délai entre création et libération : aucune colonne ne contient ce délai, il faut le calculer. H7 parle de demandes « jamais commandées » : aucune colonne ne porte ce statut, il faut le déduire de plusieurs champs.

Le besoin est donc simple : pour chaque hypothèse, savoir ce qu'il faut ajouter aux données pour que l'analyse se réduise à un `GROUP BY` et une médiane. Le tableau ci-dessous a été construit dans ce but, une ligne par hypothèse.

| Hyp. | Table | Ce qu'il faut ajouter | Pourquoi (le besoin) | Calcul qui en découle |
|---|---|---|---|---|
| H1 | Demandes | `delai_liberation` (création → libération, jours ouvrés) ; `FRGST` ; indicateur « manuelle non rejetée avec libération » | H1 compare un délai selon le niveau de validation. Sans colonne de délai par demande, impossible de grouper. L'indicateur écarte le MRP (pas de libération) et les rejetées (règle de population de l'audit 07). | Médiane du délai par `FRGST` |
| H2 | Demandes | `date_premiere_commande` (date de la plus ancienne commande de la demande) ; `delai_commande` (libération → première commande) ; `delai_creation_commande` pour le MRP ; `type_achat` | H2 compare direct et indirect. `type_achat` vient de T023T via la famille d'article : il faut le rapatrier sur la demande. Le MRP n'a pas de libération, son délai se mesure depuis la création et se présente à part. | Médiane du délai par `type_achat` |
| H3 | Commandes | Aucune mesure nouvelle. `BANFN` indique déjà si la ligne a une demande. Colonnes reprises d'EKPO : `MATKL`, `EBELN`. Indicateur de confort : `sans_demande` (`BANFN IS NULL`) | H3 se teste avec les colonnes d'origine. Le tableau de travail reprend la famille (pour voir si le phénomène se concentre) et le numéro de commande (pour compter aussi en bons) ; l'indicateur écrit la règle une seule fois. | Part globale et par famille |
| H4 | Commandes | `date_commande` ; `date_liberation` de la demande liée ; `commande_avant_liberation` | La comparaison exige les deux dates sur la même ligne, donc une jointure faite une fois pour toutes. Le dénominateur est restreint aux lignes dont la demande est libérée (17 824). | Part de lignes commandées avant libération |
| H5 | Demandes | Aucune | Le rejet est dans `LOEKZ` et le lien demande → commande dans EKPO (`BANFN`, `BNFPO`) : H5 se teste par une jointure, sans colonne préparée. (`nb_commandes` existe dans la table, mais pour `statut` et H7.) | Demandes rejetées ayant au moins une ligne de commande (attendu : 0) |
| H6 | Commandes | `prix_unitaire_eur` ; `prix_estime_unitaire` (l'écart relatif se calcule dans la requête d'analyse) | Les prix sont en devises et par quantité de prix (PEINH). Il faut les ramener à un prix unitaire en euros, comparable à l'estimé de la demande. | Médiane de l'écart ; part au-delà de 10 % |
| H7 | Demandes | `nb_commandes` (nombre de commandes par demande) ; `statut` (rejetée, commandée, commandée en partie, jamais commandée) ; `anciennete_jours` ; indicateur `dans_h7` (population de H7 : demande créée il y a plus de N jours) | Le statut combine rejet, commande et quantité commandée. L'ancienneté sert à exclure les demandes créées trop près de l'extraction (censure à droite, N = 45). | Part « jamais commandée » parmi les demandes plus anciennes que N |
| H8 | Commandes | `prix_unitaire_eur` ; `MATNR` ; `LIFNR` ; `trimestre` ; exclusion des lignes sans article | H8 compare des fournisseurs pour un même article et une même période : il faut le trimestre et un prix comparable. Les 9 040 lignes sans `MATNR` ne se comparent pas. | Écart de prix entre fournisseurs, par article et trimestre |

**Ce que ce tableau nous apprend.** Les ajouts sont de quatre sortes seulement : des délais, des statuts, des indicateurs de population et un prix unitaire en euros. Aucune hypothèse n'exige de traitement exotique. On continue.

---

## 2. Deux tables, parce que deux grains

En remplissant la colonne « Table », une séparation s'est imposée. H1, H2, H5 et H7 parlent de demandes ; H3, H4, H6 et H8 parlent de lignes de commande. Ce ne sont pas les mêmes unités : l'audit 09 a montré que 816 demandes sont scindées en exactement deux commandes. Compter des demandes dans une jointure demandes–commandes les compterait deux fois.

Décision : deux tables de travail.

| Table | Grain | Effectif attendu | Sert à |
|---|---|---|---|
| Demandes | une ligne par demande (BANFN + BNFPO) | 32 000 | H1, H2, H5, H7 |
| Commandes | une ligne par ligne de commande (EBELN + EBELP) | 32 046 | H3, H4, H6, H8 |

Le contrôle est immédiat : le nombre de lignes de chaque table doit être identique à celui de la table source. Si une jointure a dupliqué ou perdu des lignes, l'écart se voit tout de suite. On continue.

---

## 3. Colonnes communes à construire d'abord

Dans le tableau, certaines colonnes reviennent ou en conditionnent d'autres. On les construit avant les colonnes propres à chaque hypothèse.

| Table | Colonne | Pourquoi d'abord |
|---|---|---|
| Demandes | `date_premiere_commande` | Base de H2 et H7 ; règle fixée à l'audit 08 : la date de commande d'une demande est celle de sa première commande |
| Demandes | `nb_commandes` | Nécessaire au statut et à H7 ; gère les 816 demandes scindées |
| Demandes | `origine` (MRP / manuelle) | Sépare les populations de H1, H2 et H4 |
| Demandes | `type_achat` | Base de H2 |
| Demandes | `statut` | Base de H7 (jamais commandée, distincte des rejetées) |
| Commandes | `prix_unitaire_eur` | Base de H6 et H8 ; dépend du taux USD (voir §5) |
| Commandes | `date_commande` | Base de H4 |
| Commandes | `sans_demande` | Indicateur de confort pour H3 (`BANFN IS NULL`) |

---

## 4. Règles de l'audit qui s'appliquent ici

La préparation n'invente pas de règle : elle applique celles déjà fixées.

- La demande se compte dans EBAN, jamais dans la jointure.
- La date de commande d'une demande est celle de la première commande.
- Le MRP est exclu de H1 et H4 et présenté à part dans H2.
- Les demandes rejetées ne servent qu'à H5.
- Les commandes partielles forment un statut distinct.
- Les demandes créées après le 20 septembre 2026 sont exclues de H7 (N = 45 ; sensibilité à 30 et 60).
- Les clés restent du texte ; les conversions passent par les vues typées `v_*`.

---

## 5. Points ouverts

Ces deux points n'étaient pas résolubles avant d'arriver ici : on les tranche en construisant la colonne qui en dépend.

| Point | Colonne concernée | Ce qu'il faut décider |
|---|---|---|
| Taux USD → EUR | `prix_unitaire_eur` | **Tranché : 1 USD = 1 / 1,133 EUR, soit 1 EUR = 1,133 USD.** Aucun taux dans les six tables ; les 1 764 commandes en USD (6,7 %) sont concernées. Moyenne simple des 25 moyennes mensuelles du taux de référence BCE EUR/USD, d'octobre 2024 (première commande) à octobre 2026 (dernière commande en USD). Octobre 2024 à juillet 2026 : moyennes mensuelles de la Bundesbank, calculées sur les taux BCE. Août à octobre 2026 : moyennes calculées à partir de taux journaliers arrondis à deux décimales, donc approximatives. Sans ces trois mois, la moyenne serait 1,132 : l'écart est négligeable. |
| Jours ouvrés | `delai_liberation`, `delai_commande` | **Tranché : on exclut les samedis et dimanches ; les jours fériés français sont ignorés.** Table `calendrier` avec un rang de jour ouvré cumulé ; le délai en jours ouvrés est la différence de rang entre deux dates (voir §5 bis). |

Ces choix sont faits avant de regarder les résultats des hypothèses, comme les seuils.

### 5 bis. Le calendrier en pratique

Une table `calendrier` contient un jour par ligne, un indicateur « jour ouvré » (lundi à vendredi) et un compteur qui augmente de 1 à chaque jour ouvré. Le délai entre deux dates est la différence entre leurs compteurs.

```sql
CREATE OR REPLACE TABLE calendrier AS
SELECT CAST(d AS DATE) AS jour,
       isodow(d) <= 5 AS est_ouvre,
       SUM(CASE WHEN isodow(d) <= 5 THEN 1 ELSE 0 END) OVER (ORDER BY d) AS rang_ouvre
FROM generate_series(DATE '2024-09-01', DATE '2026-12-31', INTERVAL 1 DAY) t(d);
```

Vérifié : vendredi 2 → lundi 5 octobre 2026 = 1 jour ouvré (3 jours calendaires) ; lundi 5 → vendredi 9 = 4. Un samedi ou un dimanche prend le compteur du vendredi précédent : samedi → lundi compte donc 1 jour ouvré. La convention est appliquée à tous les délais.

---

## 6. Construction : ce qui a été fait

Les décisions des sections 2 à 5 sont prises : on construit. Chaque étape est suivie d'un contrôle d'effectifs avant de passer à la suivante. Les médianes et les parts par hypothèse ne sont pas regardées ici : elles relèvent de la phase 3.

### 6.1 Le calendrier (`11_calendrier.sql`)

**Besoin.** H1 et H2 mesurent des délais en jours ouvrés ; aucune table ne les donne.
**Fait.** Table `calendrier`, un jour par ligne du 2024-09-01 au 2026-12-31, avec un compteur de jours ouvrés (week-ends exclus, jours fériés ignorés). Le délai entre deux dates est la différence de compteur.
**Contrôle.** 852 jours, 609 jours ouvrés (121 semaines × 5 + 4).

### 6.2 La table Demandes (`12_table_demandes.sql`)

Construite par étapes, chacune justifiée par une hypothèse.

| Étape | Besoin | Colonnes ajoutées | Contrôle |
|---|---|---|---|
| 1. Grain et commandes liées | Compter des demandes sans les doubler quand elles sont scindées en deux commandes | `origine`, `nb_commandes`, `date_premiere_commande` (bloc intermédiaire regroupé par demande avant la jointure) | 32 000 lignes = 32 000 demandes distinctes ; 2 645 sans commande, 28 539 avec une commande, 816 avec deux ; 12 912 MRP |
| 2. Statut | H7 isole les jamais commandées en les distinguant des rejetées : aucune colonne ne le dit | `statut` (rejetée, jamais commandée, commandée en partie, commandée ; l'ordre des tests compte) | 28 817 / 1 650 / 995 / 538, conforme à l'audit 06 |
| 3. Type d'achat et délais | H2 compare direct et indirect ; H1 et H2 mesurent des délais | `type_achat` (via T023T), `delai_liberation`, `delai_commande`, `delai_creation_commande` (jours ouvrés) | 32 000 lignes conservées ; 17 982 délais de libération (population de H1) ; aucun délai négatif |
| 4. Populations et ancienneté | Appliquer une fois pour toutes les populations de H1 et la censure à droite de H7 | `anciennete_jours`, `dans_h1`, `dans_h7` | `dans_h1` = 17 982 ; `dans_h7` = 17 633, 349 demandes écartées car créées il y a moins de 45 jours |

### 6.3 La table Commandes (`13_table_commandes.sql`)

**Besoin.** H3, H4, H6 et H8 portent sur des lignes de commande, avec des prix à ramener en euros et à comparer à la demande.
**Fait.** Une ligne par ligne de commande, jointe à son en-tête (fournisseur, devise, date) et, quand elle existe, à sa demande.

| Colonne | Hypothèse | Rôle |
|---|---|---|
| `sans_demande` | H3 | Indicateur de confort : ligne sans demande liée (`BANFN IS NULL`) |
| `prix_unitaire_eur` | H6, H8 | Prix net ÷ quantité de prix, converti en euros (USD ÷ 1,133) |
| `prix_estime_unitaire` | H6 | Prix estimé de la demande liée (déjà en euros) |
| `date_commande`, `date_liberation`, `commande_avant_liberation` | H4 | Les deux dates sur la même ligne |
| `trimestre`, `MATNR`, `LIFNR` | H8 | Comparer des fournisseurs pour un même article et une même période |

**Contrôle.** 32 046 lignes = 32 046 lignes distinctes ; 1 875 sans demande ; 17 824 lignes avec une demande libérée (dénominateur de H4) ; 9 040 sans article (exclues de H8) ; 2 248 lignes en USD ; aucun prix vide ; 9 trimestres ; quantité totale 663 754 534, identique à EKPO.

### 6.4 Bilan de la phase

Les deux tables conservent leur grain et leurs totaux : rien n'a été perdu ni dupliqué. Toutes les décisions ouvertes sont tranchées (taux, calendrier, populations, règle de la première commande, N = 45). Un besoin imprévu qui apparaîtrait pendant l'analyse s'ajouterait ici, avec sa date.

**Limites de l'étape.** Environ un tiers des colonnes sont des reprises ou des indicateurs de confort (`sans_demande`, `trimestre`, `origine`) plutôt que des mesures nouvelles. Trois valeurs sont figées dans le code : le taux USD (fichier 13), la date d'extraction et la limite de création de H7 (fichier 12) ; elles sont notées en tête de chaque fichier. `dans_h7` fixe N = 45 : la sensibilité à 30 et 60 jours se calcule avec `anciennete_jours`.

## 7. On continue : phase 3, les analyses

Prochaine étape : tester H1 à H8 dans l'ordre, avec les seuils fixés avant de regarder les résultats. Chaque hypothèse devient une requête sur l'une des deux tables, du type `WHERE dans_h1 GROUP BY FRGST`, et un constat chiffré consigné dans un nouveau journal.
