# ==============================================================================
# Mini-projet RWE/HEOR : adalimumab (princeps vs biosimilaires) dans Open Medic
# ------------------------------------------------------------------------------
# Ce script contient :
#   1. une fonction qui convertit un nombre au format français en numérique
#   2. une fonction qui traite UN fichier annuel Open Medic et renvoie un
#      tableau de totaux par marque (avec le statut et l'année)
#   3. l'application à tous les fichiers du dossier, puis l'empilement
#   4. le calcul des indicateurs par année
#   5. les graphiques (enregistrés dans outputs/figures/)
#
# Avant de lancer : ouvrir le dossier du projet comme projet RStudio (ou fixer
# le dossier de travail avec setwd()), et y placer les fichiers OPEN_MEDIC_AAAA.csv.
# Les chemins du script sont relatifs à ce dossier.
#
# Particularité des fichiers :
#   - jusqu'en 2017, les fichiers n'ont que des codes (ATC5, CIP13), sans
#     libellé de médicament
#   - à partir de 2018, ils ont en plus les libellés (L_ATC5, l_cip13)
# ==============================================================================

library(tidyverse)

# Code ATC5 de l'adalimumab (identique dans toutes les années)
code_atc_adalimumab <- "L04AB04"

# Année de première commercialisation des biosimilaires de l'adalimumab
# (octobre 2018 ; à confirmer dans une source primaire et à citer dans le README)
annee_premiers_biosimilaires <- 2018


# ------------------------------------------------------------------------------
# 1. Conversion d'un nombre au format français ("47.417,58") en numérique
#    - le point est le séparateur de milliers, la virgule le séparateur décimal
#    - garde-fou : si la colonne est déjà numérique, on ne touche à rien
#      (relancer le nettoyage deux fois multiplierait les valeurs par 100)
# ------------------------------------------------------------------------------
nombre_francais_en_numerique <- function(x) {
  if (is.character(x)) {
    x <- str_remove_all(x, fixed("."))       # supprime le séparateur de milliers
    x <- str_replace_all(x, fixed(","), ".") # virgule décimale -> point décimal
    x <- as.numeric(x)
  }
  x
}


# ------------------------------------------------------------------------------
# 2. Traitement d'un fichier annuel Open Medic
#    Entrées : chemin_fichier = nom du fichier CSV ; annee = année du fichier
#    Sortie  : un tableau avec une ligne par marque
#              (marque, statut, annee, nb_boites, remboursement, base_remboursement)
# ------------------------------------------------------------------------------
traiter_fichier_open_medic <- function(chemin_fichier, annee) {

  # Import (séparateur ";" et décimale "," : format français)
  donnees_brutes <- read.csv2(chemin_fichier)

  # Contrôle : les colonnes dont on a besoin existent dans ce fichier
  colonnes_attendues <- c("ATC5", "CIP13", "BOITES", "REM", "BSE")
  stopifnot(all(colonnes_attendues %in% names(donnees_brutes)))

  # Périmètre : uniquement l'adalimumab, repéré par son code ATC5
  adalimumab <- donnees_brutes |>
    filter(ATC5 == code_atc_adalimumab)

  # Contrôle : le filtre ne doit pas être vide
  stopifnot(nrow(adalimumab) > 0)

  # Montants : conversion des nombres au format français en numérique
  adalimumab <- adalimumab |>
    mutate(
      REM = nombre_francais_en_numerique(REM),
      BSE = nombre_francais_en_numerique(BSE)
    )

  # Marque
  if ("l_cip13" %in% names(adalimumab)) {
    # Fichier avec libellés : marque = premier mot du libellé
    # (ex. "HYRIMOZ 40 MG" -> "HYRIMOZ")
    adalimumab <- adalimumab |>
      mutate(marque = word(l_cip13, 1))
  } else {
    # Fichier sans libellés (années anciennes) : valable seulement avant l'arrivée
    # des biosimilaires. Tout l'adalimumab est alors le princeps (HUMIRA).
    # Hypothèse à documenter dans le README.
    if (annee >= annee_premiers_biosimilaires) {
      stop("Fichier ", chemin_fichier, " sans libellé de médicament : ",
           "impossible d'identifier les marques à partir de ",
           annee_premiers_biosimilaires, ".")
    }
    adalimumab <- adalimumab |>
      mutate(marque = "HUMIRA")
  }

  # Totaux par marque, puis statut et année
  # Hypothèse : HUMIRA est le princeps, les marques non identifiées ("INCONNU")
  # sont mises à part, toutes les autres marques sont des biosimilaires
  # (à vérifier avec la liste de référence de l'ANSM pour chaque année étudiée)
  totaux_par_marque <- adalimumab |>
    group_by(marque) |>
    summarise(
      nb_boites          = sum(BOITES),
      remboursement      = sum(REM),
      base_remboursement = sum(BSE)
    ) |>
    mutate(
      statut = if_else(marque == "HUMIRA", "Princeps",
                       if_else(marque == "INCONNU", "Non classé", "Biosimilaire")),
      annee  = annee
    ) |>
    arrange(desc(nb_boites))

  # Dernière expression = valeur renvoyée par la fonction
  totaux_par_marque
}


# ------------------------------------------------------------------------------
# 3. Application à tous les fichiers Open Medic du dossier de travail
#    - list.files() liste les noms de fichiers du type OPEN_MEDIC_AAAA.csv
#      (le motif exclut par exemple les .zip ; ignore.case accepte .CSV)
#    - l'année est le 3e morceau du nom, en coupant sur "_" et "."
#    - la boucle applique la fonction à chaque fichier, puis do.call(rbind, ...)
#      empile les tableaux obtenus
# ------------------------------------------------------------------------------
fichiers <- list.files(pattern = "^OPEN_MEDIC_[0-9]{4}\\.csv$", ignore.case = TRUE)
annees   <- as.numeric(word(fichiers, 3, sep = "[_.]"))

resultats_annees <- vector("list", length(fichiers))
for (i in seq_along(fichiers)) {
  resultats_annees[[i]] <- traiter_fichier_open_medic(fichiers[i], annees[i])
}

totaux_toutes_annees <- do.call(rbind, resultats_annees)
dim(totaux_toutes_annees)


# ------------------------------------------------------------------------------
# 4. Indicateurs par année (à lancer sur le tableau empilé de toutes les années)
#    - group_by(annee) : une ligne de résultat par année
#    - x[condition] à l'intérieur de sum() : total pour un statut donné
#    - une année sans biosimilaire (avant 2018) donne 0 boîte biosimilaire, donc
#      un prix biosimilaire et un écart égaux à NaN : c'est normal
# ------------------------------------------------------------------------------
indicateurs_par_annee <- totaux_toutes_annees |>
  group_by(annee) |>
  summarise(
    boites_total       = sum(nb_boites),
    boites_princeps    = sum(nb_boites[statut == "Princeps"]),
    boites_biosim      = sum(nb_boites[statut == "Biosimilaire"]),
    base_total         = sum(base_remboursement),
    base_princeps      = sum(base_remboursement[statut == "Princeps"]),
    base_biosim        = sum(base_remboursement[statut == "Biosimilaire"])
  ) |>
  mutate(
    # prix moyen pondéré par boîte (base de remboursement / boîtes)
    prix_princeps      = base_princeps / boites_princeps,
    prix_biosim        = base_biosim / boites_biosim,
    # écart relatif : négatif = biosimilaires moins chers que le princeps
    ecart_prix_pct     = (prix_biosim - prix_princeps) / prix_princeps * 100,
    # part du princeps dans les boîtes remboursées
    part_princeps_pct  = boites_princeps / boites_total * 100,
    # économie si tout le volume restant du princeps passait en biosimilaire :
    # Q x (s_scen - s_obs) = boîtes de princeps, fois l'écart de prix par boîte
    economie_substitution_totale = boites_princeps * (prix_princeps - prix_biosim),
    economie_pct_base  = economie_substitution_totale / base_total * 100
  )

# Affichage arrondi (on arrondit à l'affichage, jamais avant le calcul)
indicateurs_par_annee |>
  select(annee, prix_princeps, prix_biosim, ecart_prix_pct,
         part_princeps_pct, economie_substitution_totale, economie_pct_base) |>
  mutate(across(-annee, ~ round(.x, 2)))


# ------------------------------------------------------------------------------
# 5. Graphiques
#    - chaque graphique est rangé dans un objet, puis enregistré avec ggsave()
#    - la base de remboursement par boîte est un proxy du prix public : les
#      dosages et conditionnements ne sont pas harmonisés (limite du projet)
#    - la ligne pointillée marque l'arrivée des biosimilaires (octobre 2018)
# ------------------------------------------------------------------------------
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

source_donnees <- "Source : Assurance Maladie, Open Medic (ville, remboursé). Dosages et conditionnements non harmonisés."

# Graphique 1 : base de remboursement par boîte, princeps et biosimilaires
graphique_prix <- ggplot(indicateurs_par_annee, aes(x = annee)) +
  geom_line(aes(y = prix_princeps, color = "Princeps (HUMIRA)")) +
  geom_line(aes(y = prix_biosim, color = "Biosimilaires")) +
  geom_vline(xintercept = annee_premiers_biosimilaires, linetype = "dashed") +
  labs(
    title   = "Adalimumab : base de remboursement par boîte, 2014-2025",
    x       = "Année",
    y       = "Base de remboursement par boîte (€)",
    color   = "",
    caption = source_donnees
  ) +
  theme_minimal()

ggsave("outputs/figures/prix_princeps_biosimilaires.png",
       plot = graphique_prix, width = 8, height = 5, dpi = 300)

# Graphique 2 : part du princeps dans les boîtes remboursées
graphique_part <- ggplot(indicateurs_par_annee, aes(x = annee, y = part_princeps_pct)) +
  geom_line() +
  geom_point() +
  geom_vline(xintercept = annee_premiers_biosimilaires, linetype = "dashed") +
  labs(
    title   = "Adalimumab : part du princeps dans les boîtes remboursées, 2014-2025",
    x       = "Année",
    y       = "Part des boîtes (%)",
    caption = source_donnees
  ) +
  theme_minimal()

ggsave("outputs/figures/part_princeps.png",
       plot = graphique_part, width = 8, height = 5, dpi = 300)
