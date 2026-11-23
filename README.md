# Simulation de données DA → BC : AutoSys Capteurs SA (entreprise fictive)

Projet individuel supply chain : générer, puis analyser, 24 mois de demandes d'achat (DA) et de bons de commande (BC)
au format SAP (tables EBAN, EKKO, EKPO, LFA1), avec une méthode **reproductible, documentée et contrôlée**.

> **Ce que ce projet est :** un démonstrateur méthodologique sur données simulées, calibrées sur des repères publics
> quand il en existe (Sievo pour la structure des achats) et sur des hypothèses déclarées sinon.
> **Ce qu'il n'est pas :** une description d'une entreprise réelle. Les constats faits sur ces données ne sont pas des découvertes.

## Installation (VS Code)

1. Installer Python 3.11 ou plus récent et l'extension **Python** de VS Code.
2. Ouvrir ce dossier dans VS Code, puis dans un terminal :

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows   (macOS/Linux : source .venv/bin/activate)
pip install -r requirements.txt
```

## Utilisation

```bash
python src/generer_donnees.py     # génère les CSV dans sorties/ (≈ 3 secondes)
python src/valider_donnees.py     # lance les contrôles V1 à V9 + volumes + processus
```

Pour changer l'entreprise ou les hypothèses : modifier **uniquement** `config/parametres.yaml`, puis relancer.
Même graine + mêmes paramètres = exactement les mêmes fichiers (contrôle V8).

Les CSV utilisent `;` comme séparateur et `,` comme décimale (Excel / Power BI en français), encodage UTF-8 avec BOM.
**Les clés (BANFN, EBELN, LIFNR, MATNR...) sont du texte avec zéros devant** : à importer en texte (SQL : `VARCHAR`; Power BI : type « Texte »).

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `config/parametres.yaml` | Tous les paramètres, chacun étiqueté `[SOURCÉ]`, `[CHOIX]`, `[HYPOTHÈSE]` ou `[À CALIBRER]`, et **tous les seuils de validation** |
| `src/generer_donnees.py` | Le générateur. Chaque bloc porte un commentaire `CRITÈRE ...` qui dit quelle exigence il garantit |
| `src/valider_donnees.py` | Les contrôles. Aucun seuil dans le code : ils viennent du fichier de paramètres |
| `src/outils.py`, `src/vocabulaire.py` | Calendrier français, indice de Gini, bruit de saisie ; noms et désignations fictifs |
| `sorties/*.csv` | Tables SAP simulées : **EBAN** (lignes de DA), **EKKO** (en-têtes de BC), **EKPO** (lignes de BC), **LFA1** (fournisseurs) |
| `sorties/MARA.csv`, `T023T.csv` | Tables de base **simplifiées** : articles (numéro, désignation, type, unité, type de planification) et familles d'achat |
| `sorties/verite_terrain/` | Ce que le simulateur « sait » (statut réel de chaque DA, fournisseurs qualifiés par article...). **À ne pas utiliser dans l'analyse** : sert à contrôler et à expliquer |
| `sorties/rapport_generation.json`, `rapport_validation.json` | Graine, empreinte des paramètres, empreintes SHA-256 des fichiers, résultat de chaque contrôle |

## Où est garanti chaque critère

| Exigence | Où dans le code | Contrôle |
|---|---|---|
| Les produits ne viennent pas tous du même fournisseur | `etape_articles` (fournisseurs qualifiés par référence), `choisir_fournisseurs` | V2 |
| Les fournisseurs n'ont pas des parts égales | `etape_fournisseurs` (poids log-normal) | V1, V4 |
| Nombre réaliste de fournisseurs et dépense moyenne | `etape_fournisseurs`, calage dans `etape_demande` | V3, volumes |
| Toutes les DA ne deviennent pas des BC | `etape_processus` (rejet, suppression MRP, abandon, coupure de fin de période) | V6 |
| Des BC existent sans DA | `etape_bc_sans_da` | V6 |
| Montants très asymétriques | `etape_demande` (quantités log-normales) | V5 |
| Délais d'approbation croissants selon le montant | `etape_processus` (paliers S1/S2/S3) | P3 |
| Saisonnalité répétée sur 2 ans, jours ouvrés français | `etape_calendrier`, `outils.construire_calendrier` | V9, V7 |
| Cohérence des dates, quantités, valeurs, clés | `etape_tables` | V7 |
| Reproductibilité | `generer` (graine + flux indépendants par étape) | V8 |

## Résultats actuels (graine 20261107)

53 contrôles réussis sur 53. Quelques chiffres : environ 16 000 lignes de BC par an, 101 M€ puis 106 M€ de dépense,
59 % d'achats directs, 551 et 559 fournisseurs actifs, 92 % des lignes de DA converties, 5,9 % des lignes de BC sans DA.

## Limites à connaître (à citer dans le projet)

1. **Réussir les contrôles ne prouve pas le réalisme.** Plusieurs contrôles réussissent par construction : la forme log-normale (V5), la saisonnalité (V9, même profil appliqué aux deux années), la cohérence (V7), et les contrôles de processus (P3 à P6) qui vérifient que le code reproduit les hypothèses. Ils montrent que le code fait ce que la fiche demande.
2. **Les paramètres de processus n'ont aucune source publique** (délais d'approbation, rejets, délai DA → BC, BC sans DA, écarts de prix). Ce sont des hypothèses `[HYPOTHÈSE]`. Seuls 60/40 directs/indirects, le nombre de fournisseurs et la dépense moyenne viennent d'un repère publié (Sievo, article de synthèse seulement).
3. **Écarts avec la fiche** : 551 et 559 fournisseurs actifs par an (la fiche vise environ 620 ; les 620 existent dans LFA1 mais certains ne reçoivent aucune commande dans l'année) et une dépense moyenne de 183 à 189 k€ (cible 160 k€). Les deux restent dans les intervalles fixés avant la simulation, mais en périphérie.
4. **Sensibilité à la graine.** Sur 8 autres graines (paramètres inchangés), 6 passent tous les contrôles ; la graine 6 échoue sur la part du premier fournisseur (14 % > 12 %) et la graine 8 sur la part de références couvertes par un même fournisseur (16,3 % > 15 %). Les seuils de ces deux contrôles sont donc serrés par rapport à la variabilité aléatoire. Ils n'ont pas été retouchés. À décider par écrit : élargir (en le justifiant) ou conserver.
5. **Prix tirés par famille, pas par désignation** : un stylo et un gant peuvent avoir des prix incohérents entre eux. La cohérence prix/désignation n'est pas modélisée.
6. **Non simulé** : réceptions et factures (`ELIKZ`, `EREKZ` vides), modifications de BC, contrats-cadres, BC rétroactifs, taux de change variable (taux fixe), historique des étapes d'approbation (SAP ne garde que la date finale), plusieurs sociétés.
7. **Bruit de saisie volontaire** : environ 22 % des textes libres (sans numéro d'article) sont altérés (casse, accents, abréviations, coquilles) et les désignations sont tronquées à 40 caractères comme dans SAP. Cela prépare l'étape de nettoyage SQL. Les libellés d'origine sont dans `verite_terrain/articles_meta.csv`.
8. Si une anomalie est programmée puis retrouvée par l'analyse, cela ne prouve rien sur la réalité. Les noms de fournisseurs sont inventés : vérifier avant publication qu'aucun ne correspond à une société réelle.

## Pour renforcer le projet

- Faire relire `parametres.yaml` par un professionnel des achats (notamment les délais et les rejets).
- Comparer la partie commandes à des données réelles (BPI Challenge 2019, journal d'achats d'une entreprise de peintures) pour caler les délais et les taux de BC modifiés.
- Obtenir via l'université un jeu de données réel anonymisé.

## Suite prévue

Chargement des CSV en base SQL, nettoyage, tableau de bord Power BI, analyse des dépenses et du processus avec un cadre choisi (Pareto, Kraljic, Purchasing Chessboard), recommandations.
