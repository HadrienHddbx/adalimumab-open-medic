# Adalimumab : princeps et biosimilaires en ville (Open Medic, 2014-2025)

## Question

Comment ont évolué, depuis 2014, les volumes, la base de remboursement par boîte et
la part du princeps (HUMIRA) pour l'adalimumab, avant et après l'arrivée des
biosimilaires ? Que rapporterait aujourd'hui à l'assurance maladie une substitution
totale du princeps restant par des biosimilaires ?

## Données

- **Open Medic** (Assurance Maladie) : fichiers annuels 2014 à 2025, médicaments
  délivrés en pharmacie de ville et remboursés. Données agrégées : boîtes (`BOITES`),
  montant remboursé (`REM`), base de remboursement (`BSE`), par code CIP13, âge,
  sexe et région.
- **Fichier descriptif des variables d'Open Medic** : définitions des variables et
  tables de correspondance codes / libellés
  ([téléchargement](https://www.assurance-maladie.ameli.fr/content/descriptif-des-variables-de-la-serie-open-medic)).
- **Source des fichiers** : [Open Medic, base complète sur les dépenses de médicaments
  interrégimes](https://www.data.gouv.fr/datasets/open-medic-base-complete-sur-les-depenses-de-medicaments-interregimes)
  (data.gouv.fr, Assurance Maladie). Fichiers téléchargés en novembre 2026
  <!-- À VÉRIFIER : date exacte de ton téléchargement -->.
- Les fichiers bruts ne sont pas versionnés (volumineux, et librement téléchargeables).

## Méthode

Tout le traitement est dans `script_adalimumab_open_medic.R`. Les choix de méthode
et les difficultés rencontrées :

1. **Périmètre.** L'adalimumab est repéré par son code ATC5 (`L04AB04`), identique
   dans tous les fichiers. Un premier filtre sur le libellé (`L_ATC5`) a été
   abandonné : cette colonne n'existe pas dans les fichiers anciens.
2. **Nombres au format français.** `REM` et `BSE` sont lues en texte (point pour les
   milliers, virgule pour les décimales). Une fonction les convertit en numérique
   et ne touche pas une colonne déjà convertie : relancer le nettoyage deux fois
   multipliait les valeurs par 100.
3. **Marques et statut.** Les fichiers à partir de 2018 contiennent le libellé de
   chaque présentation (`l_cip13`) : la marque est son premier mot (HUMIRA est le
   princeps, les autres marques sont des biosimilaires, une marque non identifiée
   est mise à part).
4. **Années sans libellé (2014 à 2017).** Seuls les codes sont disponibles. Ni la
   base publique des médicaments ni le fichier descriptif ne permettent de les
   nommer : les références d'avant 2018 ne figurent plus dans ces tables. On
   applique donc une hypothèse : les biosimilaires de l'adalimumab n'ayant été
   commercialisés qu'à partir d'octobre 2018, tout l'adalimumab de ces années est
   du princeps.
5. **Une fonction par fichier, une boucle pour toutes les années.** La fonction
   `traiter_fichier_open_medic()` traite un fichier ; l'année est lue dans son nom ;
   les résultats sont empilés dans un seul tableau (une ligne par marque et par
   année). Des contrôles arrêtent le traitement si une colonne attendue manque ou
   si un fichier ancien est utilisé après 2018 sans libellés.
6. **Indicateurs par année.** Prix moyen pondéré par statut (base de remboursement
   divisée par le nombre de boîtes), écart relatif entre biosimilaires et princeps,
   part du princeps dans les boîtes.
7. **Économie potentielle d'une substitution totale** (budget impact simplifié) :

   ΔC = Q × (s_scen − s_obs) × (c_ref − c_bio)

   où Q est le volume total de boîtes, s la part de biosimilaires (observée ou
   visée, 100 % pour une substitution totale) et c le prix moyen par boîte du
   princeps (ref) et des biosimilaires (bio). Elle mesure ce qui resterait à
   gagner à l'écart de prix de l'année, pas des économies déjà réalisées.

## Résultats

![Base de remboursement par boîte](outputs/figures/prix_princeps_biosimilaires.png)

![Part du princeps](outputs/figures/part_princeps.png)

### Tableau des indicateurs

| Année | Prix princeps (€/boîte) | Prix biosimilaires (€/boîte) | Écart de prix | Part du princeps (boîtes) | Économie potentielle (M€) | En % de la base |
|---|---|---|---|---|---|---|
| 2014 | 948 | – | – | 100 % | – | – |
| 2015 | 945 | – | – | 100 % | – | – |
| 2016 | 888 | – | – | 100 % | – | – |
| 2017 | 832 | – | – | 100 % | – | – |
| 2018 | 772 | 510 | −33,9 % | 99,8 % | 172,3 | 33,9 % |
| 2019 | 655 | 510 | −22,1 % | 89,0 % | 94,2 | 20,2 % |
| 2020 | 652 | 504 | −22,8 % | 76,1 % | 89,7 | 18,3 % |
| 2021 | 614 | 492 | −19,9 % | 67,9 % | 73,6 | 14,4 % |
| 2022 | 567 | 483 | −14,9 % | 58,8 % | 47,6 | 9,4 % |
| 2023 | 533 | 447 | −16,2 % | 48,7 % | 43,2 | 8,6 % |
| 2024 | 520 | 435 | −16,4 % | 42,6 % | 40,0 | 7,7 % |
| 2025 | 443 | 435 | −1,7 % | 31,5 % | 2,6 | 0,5 % |

### Avant les biosimilaires (2014-2017)

Le princeps est seul sur le marché (hypothèse posée dans la méthode). Sa base de
remboursement par boîte baisse tendanciellement, de 948 € en 2014 à 832 € en 2017
(−12 %), surtout à partir de 2016. Nos données ne permettent pas d'expliquer cette
baisse : le prix est fixé par le Comité économique des produits de santé (CEPS) et nous
n'avons pas identifié de décision datée sur cette période (piste : rapports d'activité
du CEPS).

L'année 2018 est une année de transition : les biosimilaires n'arrivent qu'en octobre,
si bien que les indicateurs de cette année comparent un prix de biosimilaire observé
sur quelques semaines à un prix moyen du princeps sur douze mois. L'écart de −33,9 % et
l'économie de 172 M€ sont donc surestimés et ne sont pas comparables aux années
suivantes. Nous prenons 2019 comme première année de référence.

### Après l'arrivée des biosimilaires (2019-2025)

- **Part du princeps.** Elle passe de 99,8 % des boîtes en 2018 à 89,0 % en 2019, puis à
  31,5 % en 2025.
- **Prix.** La base de remboursement du princeps baisse par deux paliers d'environ
  15 % : de 772 € à 655 € entre 2018 et 2019, et de 520 € à 443 € entre 2024 et 2025.
  Entre les deux, la baisse est lente (655 € à 520 €, soit −21 % en cinq ans). Les
  biosimilaires restent proches de 510 € puis de 435 € à partir de 2024. L'écart de prix
  passe de −22,1 % en 2019 à −16,4 % en 2024, puis à **−1,7 % en 2025**.
- **Lecture de la convergence.** Le prix du princeps est administré : il ne baisse pas
  parce que ses ventes reculent. La baisse de sa part de marché et celle de son prix
  sont deux conséquences de l'arrivée des biosimilaires, pas un mécanisme de marché
  l'un sur l'autre. Le premier palier correspond à la baisse du 2 novembre 2018 (prix
  public du princeps fixé à 658,31 €, à comparer à notre moyenne de 655 € en 2019), qui
  s'inscrit dans la décote de 20 % du princeps prévue à l'arrivée du premier
  biosimilaire par l'accord-cadre entre le CEPS et l'industrie ; le second correspond
  à une décision tarifaire de janvier 2025
  <!-- À VÉRIFIER : décisions au Journal officiel (Légifrance). Le prix de 2025 observé (443 €) est supérieur à celui annoncé (422,32 €) : mix de présentations ou date d'application ? -->.

### Économies potentielles d'une substitution totale

Ce qui resterait à gagner si le princeps restant était remplacé par des biosimilaires
au prix moyen observé passe de **94,2 M€ en 2019 (20,2 % de la base de remboursement)**
à **40,0 M€ en 2024 (7,7 %)**, puis à **2,6 M€ en 2025 (0,5 %)**.

Deux phases se distinguent. De 2019 à 2024, la baisse vient surtout du volume : la part
du princeps passe de 89 % à 43 % alors que l'écart de prix ne se réduit que de −22 % à
−16 %. En 2025, le potentiel chute de 93 % en un an alors que la part du princeps ne
recule que de 43 % à 31 % : l'effondrement vient presque entièrement de la
convergence des prix, c'est-à-dire de la baisse administrée du prix du princeps.

### Conclusion

Substituer le princeps restant garde un intérêt financier (environ 2,6 M€ en 2025),
mais très faible : 0,5 % de la base de remboursement. L'indicateur est en recul
constant depuis 2019, ce qui indique que l'essentiel du gain accessible a déjà été
capté. Deux réserves : (1) ce gain est passé par deux canaux, la substitution elle-même
(jusqu'en 2024) et la baisse imposée du prix du princeps (surtout en 2025) ; (2) il
s'agit d'un potentiel restant à l'écart de prix de l'année, les économies réellement
réalisées chaque année n'ont pas été calculées.

## Limites

- **Doses et conditionnements non harmonisés.** Le prix est calculé par boîte, toutes
  présentations confondues (40 mg, 80 mg, stylo, seringue, nombre d'unités par boîte).
  Les variations du prix moyen mélangent donc les baisses tarifaires et l'évolution du
  mix de présentations : une hausse de la part des fortes doses tire le prix moyen par
  boîte vers le haut et peut masquer une partie des baisses de prix. Un prix par
  équivalent de 40 mg aurait été préférable.
- **Pas d'inférence causale.** L'analyse est descriptive. Pour attribuer les évolutions
  à l'arrivée des biosimilaires, il faudrait un groupe de comparaison : un médicament
  concurrent comparable, sans entrée de biosimilaire sur la période, afin de neutraliser
  les autres facteurs non pris en compte ici (décisions de prix, évolution des
  pratiques, indications...). Une approche en différence de différences est une piste.
- **Prix facial, pas prix net.** La base de remboursement est le prix public. Les
  remises accordées par les laboratoires (notamment aux pharmacies) ne sont pas
  observées : les économies réelles pour l'Assurance Maladie et la concurrence sur les
  prix réels échappent à l'analyse.
- **Prix administré.** Les prix étant fixés par le CEPS, leur baisse reflète des
  décisions réglementaires plus qu'une concurrence par les prix.
- **Moyennes annuelles.** Les baisses de prix se font à des dates précises dans
  l'année. Les paliers sont lissés par la moyenne annuelle, et l'année 2018 est une
  année de transition (biosimilaires disponibles à partir d'octobre seulement).
- **Hypothèse avant 2018.** Sans libellés dans les fichiers 2014 à 2017, tout
  l'adalimumab est supposé être du princeps, ce qui repose sur la date de
  commercialisation des biosimilaires.
- **Identification des marques.** Le statut (princeps ou biosimilaire) est déduit du
  premier mot du libellé de la présentation. Une marque non reconnue est classée à part.
- **Périmètre ville.** Seuls les médicaments délivrés en pharmacie de ville et
  remboursés sont observés. Les achats hospitaliers, soumis à des appels d'offres, sont
  hors périmètre.
- **Données agrégées, en boîtes.** Pas d'information sur les patients (nombre de
  patients traités, durée de traitement, indication). Le volume est un nombre de boîtes,
  pas un nombre de patients.
- **Scénario statique.** Le calcul d'économie suppose les volumes inchangés et ignore
  les contraintes de la substitution (mention « non substituable », règles de
  l'ANSM sur les volumes d'injection, formulations différentes selon les biosimilaires).
  Il ne mesure pas l'effet de la substitution sur les prix eux-mêmes.
- **Pas d'incertitude statistique.** Tous les résultats sont des totaux observés,
  sans intervalle de confiance ni test.

## Reproduire

1. Installer R et le package `tidyverse`.
2. Télécharger les fichiers annuels 2014 à 2025 depuis la page Open Medic (lien
   ci-dessus), les décompresser si ce sont des archives (`.zip`) et les renommer
   `OPEN_MEDIC_AAAA.csv` (par exemple `OPEN_MEDIC_2019.csv`).
3. Ouvrir le dossier du projet comme projet RStudio et y placer ces 12 fichiers, à
   la racine, à côté du script.
4. Exécuter `script_adalimumab_open_medic.R` d'un bloc : il produit le tableau des
   indicateurs et enregistre les graphiques dans `outputs/figures/`.

## Structure du dépôt

```
README.md
script_adalimumab_open_medic.R
outputs/figures/      graphiques (PNG)
```
