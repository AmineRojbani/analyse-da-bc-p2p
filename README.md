# Analyse du processus demande d'achat → bon de commande (P2P)

Projet individuel de supply chain sur données **simulées** au format SAP : analyse de 24 mois de demandes d'achat (DA) et de bons de commande (BC) d'une entreprise fictive, AutoSys Capteurs SA (extraction du 4 novembre 2026).

> **Ce que ce projet est :** une démonstration de méthode (audit des données, hypothèses, tests, restitution) sur un jeu simulé.
> **Ce qu'il n'est pas :** une étude d'une entreprise réelle. Les constats portent sur des données simulées.

## Question posée

Le processus DA → BC respecte-t-il ses règles, et où sont les écarts ? Huit hypothèses ont été formulées, avec des **seuils fixés avant de regarder les résultats**.

## Résultats

| Hyp. | Énoncé | Résultat | Verdict |
|---|---|---|---|
| H1 | Le délai de libération augmente avec le niveau de validation | médianes de 1, 3 et 5 jours ouvrés (S1, S2, S3) | Confirmée |
| H2 | Le délai libération → commande est plus long pour l'indirect | indirect 6 j, direct 4 j (demandes manuelles) | Confirmée |
| H3 | Moins de 5 % des lignes de commande sont sans demande | 5,85 % | Rejetée |
| H4 | Moins de 2 % des lignes sont commandées avant libération | 0 % | Confirmée |
| H5 | Une demande rejetée n'est jamais commandée | 0 cas sur 1 650 | Confirmée |
| H6 | Le prix commandé reste proche du prix estimé | écart médian 3,94 % (ok) ; 10,14 % des lignes au-delà de 10 % (seuil 5 %) | Rejetée |
| H7 | Moins de 5 % des demandes libérées ne sont jamais commandées | 3,19 % | Confirmée à 5 % et 10 %, pas à 3 % |
| H8 | Un même article se paie différemment selon le fournisseur | écart médian de 9,49 % entre fournisseurs | Constat descriptif |

Le détail, avec les populations, les tableaux et les graphiques, est dans [`analyse_da_bc/journal_analyse.md`](analyse_da_bc/journal_analyse.md).

## Méthode

1. **Audit** des tables (clés, doublons, liens DA ↔ BC, statuts, devises) : `analyse_da_bc/00` à `10`.
2. **Préparation** : tables de travail `calendrier` (jours ouvrés), `demandes` (une ligne par ligne de DA) et `commandes` (une ligne par ligne de BC) : `11` à `13`.
3. **Hypothèses** H1 à H8, un fichier SQL chacun : `20_H1.sql` à `27_H8.sql`.
4. **Graphiques** : `python analyse_da_bc/graphiques.py tout`.

Principes retenus : seuils figés avant les résultats, un verdict binaire (confirmée ou rejetée), les limites écrites à côté de chaque résultat.

## Outils

SQL (DuckDB 1.1.3), Python (matplotlib), tables simulées au format SAP : EBAN, EKKO, EKPO, LFA1, MARA, T023T.

## Reproduire

Les données simulées sont dans `sorties/`. Les fichiers SQL de `analyse_da_bc/` se lancent dans l'ordre avec :

```bash
python analyse_da_bc/mon_lanceur.py analyse_da_bc/<fichier>.sql
```

## Limites

- Les données sont simulées : un écart retrouvé est une propriété du jeu, pas une découverte sur une entreprise réelle.
- Les jours fériés sont ignorés (week-ends seuls exclus) et le taux de change USD → EUR est fixe (1 EUR = 1,133 USD).
- Les délais ne sont calculés que pour les demandes effectivement commandées.