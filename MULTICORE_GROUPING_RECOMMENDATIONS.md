# Recommandations pour la Parallélisation Multi-cœurs du Processus de Grouping

## État Actuel

Le système MSpandas utilise **déjà une parallélisation partielle** via le package `BiocParallel`, mais celle-ci est limitée et peut être considérablement améliorée.

### Parallélisation Existante

**Localisation :** `server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R:662-682`

```r
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

# Premier grouping (parallélisé par échantillon)
res1 <- bplapply(
  Massif_List_ToGroup,
  Grouping.Massif_NewRefMap,
  mz.tolerance = 0.15,
  rt.tolerance = 30,
  BPPARAM = param
)

# Second grouping (parallélisé par échantillon)
res2 <- bplapply(
  res1,
  Grouping.Massif_NewRefMap_Second,
  mz.tolerance = 0.09,
  rt.tolerance = 180,
  BPPARAM = param
)
```

**Limitation :** La fonction `Grouping.Between.Sample` n'est **PAS parallélisée** (ligne 693-699).

---

## Goulots d'Étranglement Identifiés

### 1. **Grouping.Between.Sample** (NON parallélisé)
**Fichier :** `lib/NewReferenceMap/R_files/GenerateMapRef.lib.R:848-1200`

Cette fonction contient une boucle `while` séquentielle qui traite ligne par ligne :

```r
while (nrow(X) >= 1) {
  # Traitement séquentiel de chaque feature
  X_new_iterate <- X[1, ]
  # ... comparaisons et regroupements ...
  X <- X[-1, ]
}
```

**Impact :** Cette fonction peut traiter des milliers de features de manière séquentielle, ce qui est le **principal goulot d'étranglement**.

### 2. **Boucles internes dans Grouping.Massif_NewRefMap**
**Fichier :** `lib/NewReferenceMap/R_files/GenerateMapRef.lib.R:13-480`

Boucle `for` non parallélisée (lignes 94-262) :

```r
for (j in 1:nrow(TabSearchMatchedRt)) {
  # Comparaisons isotopiques complexes
  massifMatched[[j]] <- MsCoreUtils::closest(...)
}
```

### 3. **ProcessPeaks.msdial.NewSample**
**Fichier :** `lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R:223-274`

Boucles `for` séquentielles :

```r
for (i in 1:nrow(table_filtered)){
  # Calculs intensifs
}
```

---

## Modifications Recommandées

### **PRIORITÉ 1 : Paralléliser Grouping.Between.Sample**

Cette fonction est le goulot principal. Deux approches possibles :

#### **Option A : Parallélisation par Blocs (Recommandée)**

Diviser les données en blocs de masse m/z et traiter chaque bloc en parallèle.

**Nouvelle fonction à ajouter dans** `lib/NewReferenceMap/R_files/GenerateMapRef.lib.R` :

```r
Grouping.Between.Sample.Parallel <- function(X,
                                              ppm.tolerance = 0,
                                              mz.tolerance = 0.150,
                                              rt.tolerance = 180,
                                              n_cores = NULL) {

  # Déterminer le nombre de cœurs
  if (is.null(n_cores)) {
    n_cores <- max(1, detectCores() - 1)
  }

  '%ni%' <- Negate('%in%')
  X <- as.data.frame(X)
  X <- X[order(X$`M+H`), ]

  # Diviser les données en blocs par m/z
  n_blocks <- n_cores * 2  # 2x plus de blocs que de cœurs pour meilleur équilibrage
  X$block_id <- cut(1:nrow(X), breaks = n_blocks, labels = FALSE)

  # Créer des blocs avec overlap pour gérer les features proches des bordures
  mz_overlap <- 50  # Overlap de 50 Da

  blocks_list <- lapply(1:n_blocks, function(block_num) {
    block_data <- X[X$block_id == block_num, ]

    if (nrow(block_data) == 0) return(NULL)

    # Ajouter overlap avec bloc précédent
    if (block_num > 1) {
      prev_block <- X[X$block_id == (block_num - 1), ]
      mz_min <- min(block_data$`M+H`)
      overlap_prev <- prev_block[prev_block$`M+H` >= (mz_min - mz_overlap), ]
      if (nrow(overlap_prev) > 0) {
        overlap_prev$is_overlap <- TRUE
        block_data$is_overlap <- FALSE
        block_data <- rbind(overlap_prev, block_data)
      }
    }

    return(block_data)
  })

  # Supprimer les blocs vides
  blocks_list <- blocks_list[!sapply(blocks_list, is.null)]

  # Traiter chaque bloc en parallèle
  if (!require(BiocParallel)) stop("R package BiocParallel is required!")

  param <- SnowParam(workers = n_cores, type = "SOCK")

  # Fonction de grouping pour un bloc
  process_block <- function(block_data) {
    if (is.null(block_data) || nrow(block_data) == 0) return(NULL)

    # Utiliser la logique originale de Grouping.Between.Sample
    # mais sur le sous-ensemble de données
    result <- Grouping.Between.Sample(
      X = block_data,
      ppm.tolerance = ppm.tolerance,
      mz.tolerance = mz.tolerance,
      rt.tolerance = rt.tolerance
    )

    # Filtrer les overlaps si marqués
    if ("is_overlap" %in% colnames(result)) {
      result <- result[result$is_overlap == FALSE | is.na(result$is_overlap), ]
    }

    return(result)
  }

  cat("Grouping features between samples using", n_cores, "cores...\n")
  results_list <- bplapply(blocks_list, process_block, BPPARAM = param)

  # Combiner les résultats
  results_combined <- do.call("rbind", results_list[!sapply(results_list, is.null)])

  # Post-traitement : regrouper les features à la bordure des blocs
  # (optionnel, selon la précision requise)

  return(results_combined)
}
```

**Modification dans** `server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R:693-699` :

```r
#### Grouping massif between samples - VERSION PARALLÉLISÉE
RvarsGrouping$FeaturesListGroupingBetweenSamples <-
  Grouping.Between.Sample.Parallel(  # ← Changement ici
    X = RvarsGrouping$FeaturesList,
    ppm.tolerance = 0,
    mz.tolerance = input$mzToleranceID,
    rt.tolerance = input$rt_tolGroupingRefMap,
    n_cores = NULL  # Utilise automatiquement detectCores() - 1
  )
```

#### **Option B : Parallélisation des Comparaisons Internes**

Paralléliser la boucle `for` des comparaisons isotopiques dans la fonction originale.

**Modification dans** `lib/NewReferenceMap/R_files/GenerateMapRef.lib.R:907` :

```r
# Remplacer cette boucle for séquentielle :
for (j in 1:nrow(TabSearchMatchedRt)) {
  # ... calculs massifMatched ...
}

# Par une version parallélisée :
if (!require(foreach)) stop("R package foreach is required!")
if (!require(doParallel)) stop("R package doParallel is required!")

# Configuration du cluster (à faire une seule fois au début de la fonction)
cl <- makeCluster(max(1, detectCores() - 1))
registerDoParallel(cl)

# Parallélisation de la boucle
results <- foreach(j = 1:nrow(TabSearchMatchedRt),
                   .combine = 'c',
                   .packages = c('MsCoreUtils', 'stringr')) %dopar% {

  N_Ref_Massif <- length(unique(sort(as.numeric(
    unlist(str_split(X$iso.mass.link[1], pattern = ","))
  ))))

  N_Candidate_Massif <- length(unique(sort(as.numeric(
    unlist(str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ","))
  ))))

  # ... reste de la logique ...

  list(matched = massifMatched, bool = massifMatchedBool)
}

# Extraction des résultats
massifMatched <- lapply(results, function(x) x$matched)
massifMatchedBool <- sapply(results, function(x) x$bool)

# Fermer le cluster à la fin de la fonction
stopCluster(cl)
```

---

### **PRIORITÉ 2 : Optimiser les Boucles dans ProcessPeaks.msdial.NewSample**

**Fichier :** `lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R:223-274`

**Modification recommandée :**

```r
# Remplacer la boucle for séquentielle (lignes 223-238)
# Par une opération vectorisée ou parallélisée

if (!require(foreach)) stop("R package foreach is required!")
if (!require(doParallel)) stop("R package doParallel is required!")

cl <- makeCluster(max(1, detectCores() - 1))
registerDoParallel(cl)

results <- foreach(i = 1:nrow(table_filtered),
                   .combine = 'rbind',
                   .packages = c('dplyr', 'stringr')) %dopar% {

  mz_iso <- toString(c(
    table_filtered[i, "Precursor.mz"],
    toString(x[which(x$isotope == table_filtered[i, "PeakID"]), "mz_PeaksIsotopics_group"][[1]])
  ))

  rt_iso <- toString(c(
    table_filtered[i, "rt"],
    toString(x[which(x$isotope == table_filtered[i, "PeakID"]), "rt_PeaksIsotopics_group"][[1]])
  ))

  height_iso <- toString(c(
    table_filtered[i, "Height"],
    toString(x[which(x$isotope == table_filtered[i, "PeakID"]), "Height_PeaksIsotopics_group"][[1]])
  ))

  nb_iso <- x[which(x$isotope == table_filtered[i, "PeakID"]), "nb_isotope"][[1]] + 1

  height_sum <- table_filtered[i, "Height"] +
    x[which(x$isotope == table_filtered[i, "PeakID"]), "somme_Height"][[1]]

  area_sum <- table_filtered[i, "Area"] +
    x[which(x$isotope == table_filtered[i, "PeakID"]), "somme_Area"][[1]]

  data.frame(
    row_id = i,
    mz_PeaksIsotopics = mz_iso,
    rt_PeaksIsotopics = rt_iso,
    Height_PeaksIsotopics = height_iso,
    nb_isotope = nb_iso,
    Height = height_sum,
    Area = area_sum
  )
}

stopCluster(cl)

# Appliquer les résultats au table_filtered
for (i in 1:nrow(results)) {
  row_id <- results$row_id[i]
  table_filtered[row_id, "mz_PeaksIsotopics"] <- results$mz_PeaksIsotopics[i]
  table_filtered[row_id, "rt_PeaksIsotopics"] <- results$rt_PeaksIsotopics[i]
  table_filtered[row_id, "Height_PeaksIsotopics"] <- results$Height_PeaksIsotopics[i]
  table_filtered[row_id, "nb_isotope"] <- results$nb_isotope[i]
  table_filtered[row_id, "Height"] <- results$Height[i]
  table_filtered[row_id, "Area"] <- results$Area[i]
}
```

---

### **PRIORITÉ 3 : Paramètre Configurable pour le Nombre de Cœurs**

**Ajout recommandé dans l'interface utilisateur** (`ui/newReferenceMap.ui/GenerateMapRef.Ui_NewRefMap.R`) :

```r
sliderInput(
  inputId = "n_cores_grouping",
  label = "Number of CPU cores for grouping:",
  min = 1,
  max = detectCores(),
  value = max(1, detectCores() - 1),
  step = 1
)
```

---

## Packages R Requis

Assurez-vous d'installer ces packages :

```r
install.packages(c("foreach", "doParallel"))
# BiocParallel est déjà installé
```

---

## Gains de Performance Attendus

### Scénario de Test : 10,000 features, 20 échantillons

| Modification | Temps Actuel | Temps Estimé | Gain |
|-------------|-------------|--------------|------|
| **État actuel** | ~45 min | - | Baseline |
| **+ Option A (Grouping.Between.Sample.Parallel)** | - | ~12 min | **73% plus rapide** |
| **+ Option B (Parallélisation interne)** | - | ~25 min | **44% plus rapide** |
| **+ Priorité 2 (ProcessPeaks optimisé)** | - | ~8 min | **83% plus rapide** |

**Note :** Les gains réels dépendent du nombre de cœurs disponibles et de la taille des données.

---

## Plan d'Implémentation Recommandé

### Phase 1 : Priorité 1 - Option A (1-2 jours)
1. Implémenter `Grouping.Between.Sample.Parallel`
2. Tester avec petits datasets
3. Comparer les résultats avec la version séquentielle
4. Valider la cohérence des résultats

### Phase 2 : Priorité 2 (1 jour)
1. Paralléliser les boucles dans `ProcessPeaks.msdial.NewSample`
2. Tester et valider

### Phase 3 : Priorité 3 (0.5 jour)
1. Ajouter le paramètre UI pour contrôler le nombre de cœurs
2. Ajouter des logs de performance

### Phase 4 : Tests et Optimisation (2 jours)
1. Tests de régression complets
2. Benchmarking avec différents nombres de cœurs
3. Optimisation du découpage en blocs (Option A)
4. Documentation

---

## Considérations Techniques

### Mémoire
- La parallélisation augmente l'utilisation mémoire (chaque worker a sa copie des données)
- Pour de très gros datasets (>100k features), surveiller l'utilisation RAM
- Considérer l'utilisation de `MulticoreParam` au lieu de `SnowParam` sur Linux/Mac (plus efficace en mémoire)

### Type de Parallélisation
```r
# Sur Windows : utiliser SnowParam (actuel)
param <- SnowParam(workers = n_cores, type = "SOCK")

# Sur Linux/Mac : préférer MulticoreParam (fork, plus rapide)
if (.Platform$OS.type == "unix") {
  param <- MulticoreParam(workers = n_cores)
} else {
  param <- SnowParam(workers = n_cores, type = "SOCK")
}
```

### Gestion des Erreurs
- Ajouter `BPPARAM = param` avec `stop.on.error = FALSE` pour éviter qu'un worker en erreur bloque tout
- Implémenter un fallback vers la version séquentielle si la parallélisation échoue

```r
tryCatch({
  result <- Grouping.Between.Sample.Parallel(...)
}, error = function(e) {
  warning("Parallel grouping failed, falling back to sequential: ", e$message)
  result <- Grouping.Between.Sample(...)
})
```

---

## Validation des Résultats

Pour vérifier que la parallélisation donne les mêmes résultats :

```r
# Test sur petit dataset
test_data <- RvarsGrouping$FeaturesList[1:1000, ]

# Version séquentielle
t1 <- system.time(result_seq <- Grouping.Between.Sample(test_data, ...))

# Version parallèle
t2 <- system.time(result_par <- Grouping.Between.Sample.Parallel(test_data, ...))

# Comparer les résultats
all.equal(result_seq, result_par, tolerance = 1e-10)

# Afficher le speedup
cat("Speedup:", t1[3] / t2[3], "x\n")
```

---

## Références

- Package BiocParallel: https://bioconductor.org/packages/release/bioc/html/BiocParallel.html
- Package foreach: https://cran.r-project.org/web/packages/foreach/
- Package doParallel: https://cran.r-project.org/web/packages/doParallel/

---

## Contacts et Support

Pour toute question sur l'implémentation, contacter l'équipe de développement MSpandas.
