# Guide : Parallélisation de la Recherche de Normalisateurs

## Problème Constaté

Votre code s'exécute en **séquentiel** au lieu de **parallèle** :

```r
RvarsInternalStandard$OjectNormalizers <- bplapply(
  input_Matrix,
  Fun = Search_normalizers,
  pFeatures = input$pFeatures,
  pSample = input$pSample,
  minNormalizersParam = input$minNormalizers,
  BPPARAM = SnowParam(workers = workers, type = "SOCK")
)
```

---

## Pourquoi ça ne marche pas en parallèle ?

### ❌ **Problème 1 : Structure incorrecte**

```r
bplapply(input_Matrix, Fun = Search_normalizers, ...)
          ^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^^^^
          Argument 1   Argument incorrect!
```

**Erreurs :**
1. `Fun = Search_normalizers` → **Incorrect !** La syntaxe correcte est juste `Search_normalizers` (sans `Fun =`)
2. `input_Matrix` est probablement une **matrice unique**, pas une liste

**Ce qui se passe réellement :**
- `bplapply()` itère sur les **colonnes** de la matrice (comportement par défaut pour une matrice)
- Si la matrice a 1 colonne → 1 seule tâche → **séquentiel**
- Si la matrice a N colonnes → N tâches, mais `Search_normalizers()` ne s'attend probablement pas à recevoir une colonne à la fois

---

### ❌ **Problème 2 : Une seule tâche = Pas de parallélisation**

```r
# Grouping (fonctionne bien en parallèle)
bplapply(
  Massif_List_ToGroup,    # Liste de 50 massifs
  Grouping.Massif_NewRefMap,
  ...
)
# → 50 tâches indépendantes → Parallélisation effective !

# Recherche normalisateurs (séquentiel)
bplapply(
  input_Matrix,           # 1 seule matrice
  Search_normalizers,
  ...
)
# → 1 seule tâche → Rien à paralléliser !
```

**Principe clé :** `bplapply()` ne peut paralléliser que s'il y a **plusieurs tâches indépendantes** dans une liste.

---

## ✅ Solutions : Comment Paralléliser Correctement

### **Solution 1 : Paralléliser par Échantillon** (Recommandé)

Si `Search_normalizers()` peut traiter **chaque échantillon indépendamment**, divisez la matrice par échantillon :

```r
# Transformer la matrice en liste d'échantillons
n_samples <- ncol(input_Matrix)

# Créer une liste de jobs (chaque job = 1 échantillon)
sample_list <- lapply(1:n_samples, function(i) {
  list(
    sample_data = input_Matrix[, i, drop = FALSE],  # 1 colonne
    sample_name = colnames(input_Matrix)[i]
  )
})

# Créer le cluster avec gestion propre
workers <- if (n_samples >= 300) 2 else min(4, parallel::detectCores() - 1)
param <- SnowParam(workers = workers, type = "SOCK")

# Fonction wrapper pour chaque échantillon
process_one_sample <- function(sample_job, pFeatures, pSample, minNorm) {
  Search_normalizers(
    Matrix = sample_job$sample_data,
    pFeatures = pFeatures,
    pSample = pSample,
    minNormalizersParam = minNorm
  )
}

# PARALLÉLISATION : chaque worker traite plusieurs échantillons
results <- bplapply(
  sample_list,
  process_one_sample,
  pFeatures = input$pFeatures,
  pSample = input$pSample,
  minNorm = input$minNormalizers,
  BPPARAM = param
)

# IMPORTANT : Fermer les connexions !
bpstop(param)

# Combiner les résultats
RvarsInternalStandard$OjectNormalizers <- do.call(rbind, results)
```

**Avantages :**
- ✅ Vraie parallélisation (N échantillons sur W workers)
- ✅ Distribution équitable de la charge
- ✅ Gestion mémoire meilleure (chaque worker traite moins de données)

---

### **Solution 2 : Paralléliser par Batch d'Échantillons** (Pour grandes données)

Si vous avez **312 échantillons** et des données **immenses**, divisez en **batches** pour réduire la charge mémoire :

```r
# Configuration adaptative
n_samples <- ncol(input_Matrix)
batch_size <- if (n_samples >= 300) 50 else 100  # Batches plus petits pour grandes données
workers <- if (n_samples >= 300) 2 else min(4, detectCores() - 1)

# Créer les batches
n_batches <- ceiling(n_samples / batch_size)
batch_list <- lapply(1:n_batches, function(b) {
  start_idx <- (b - 1) * batch_size + 1
  end_idx <- min(b * batch_size, n_samples)
  list(
    batch_matrix = input_Matrix[, start_idx:end_idx, drop = FALSE],
    batch_id = b
  )
})

cat(sprintf("Processing %d samples in %d batches with %d workers\n",
            n_samples, n_batches, workers))

# Fonction de traitement par batch
process_batch <- function(batch_job, pFeatures, pSample, minNorm) {
  cat(sprintf("  Processing batch %d...\n", batch_job$batch_id))

  result <- Search_normalizers(
    Matrix = batch_job$batch_matrix,
    pFeatures = pFeatures,
    pSample = pSample,
    minNormalizersParam = minNorm
  )

  # Libérer la mémoire après chaque batch
  gc(verbose = FALSE)

  return(result)
}

# Créer le cluster
param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

# Traitement parallèle par batch
results <- bplapply(
  batch_list,
  process_batch,
  pFeatures = input$pFeatures,
  pSample = input$pSample,
  minNorm = input$minNormalizers,
  BPPARAM = param
)

# Fermer proprement
bpstop(param)
gc()

# Combiner les résultats
RvarsInternalStandard$OjectNormalizers <- do.call(rbind, results)
```

**Configuration Batch recommandée :**

| N échantillons | Batch size | Workers | Raison |
|----------------|------------|---------|--------|
| < 100 | 100 (tout d'un coup) | 4-6 | Données petites, parallélisation maximale |
| 100-200 | 50 | 3-4 | Compromis mémoire/vitesse |
| 200-300 | 30-40 | 2-3 | Économie mémoire |
| **300+** | **25-30** | **2** | **Grandes données, éviter saturation** |

---

### **Solution 3 : Paralléliser à l'Intérieur de Search_normalizers()**

Si `Search_normalizers()` contient une boucle interne (par exemple sur les features), parallélisez **à l'intérieur** :

```r
# Modifier Search_normalizers() directement

Search_normalizers <- function(Matrix, pFeatures, pSample, minNormalizersParam) {

  # ... code existant ...

  # Si vous avez une boucle comme celle-ci :
  # for (feature in candidate_features) {
  #   result <- analyze_feature(feature, Matrix)
  # }

  # REMPLACER PAR :
  workers <- min(2, detectCores() - 1)  # Limité à 2 pour grandes données
  param <- SnowParam(workers = workers, type = "SOCK")

  results <- bplapply(
    candidate_features,
    analyze_feature,
    Matrix = Matrix,
    BPPARAM = param
  )

  bpstop(param)  # IMPORTANT : Fermer les sockets !

  # ... reste du code ...
}
```

**⚠️ Attention :** Cette approche ouvre des sockets **à l'intérieur** de la fonction. Si vous appelez `Search_normalizers()` depuis un autre contexte parallèle, vous aurez des **sockets imbriqués** → risque de saturation !

---

## 🔧 Gestion de la Mémoire et des Sockets (312 Fichiers)

### **Problème : Données Immenses dans le Grouping**

Avec 312 fichiers, vous avez probablement :
- Matrice d'abondance : **10,000 features × 312 samples** = ~25 MB (en mémoire)
- Chaque worker duplique les données → **25 MB × 4 workers = 100 MB**
- Données temporaires pendant le calcul → **×2-3** = **200-300 MB par worker**

### **Solution 1 : Limiter les Workers** ✅

```r
# Configuration adaptative basée sur la taille des données
n_samples <- ncol(input_Matrix)
matrix_size_mb <- object.size(input_Matrix) / 1024^2

workers <- if (n_samples >= 300 || matrix_size_mb > 50) {
  2  # Seulement 2 workers pour grandes données
} else if (n_samples >= 150) {
  3  # 3 workers pour données moyennes
} else {
  min(4, detectCores() - 1)  # Maximum 4 workers pour petites données
}

cat(sprintf("Data size: %.1f MB, Using %d workers\n", matrix_size_mb, workers))
```

---

### **Solution 2 : Nettoyer les Sockets Systématiquement** ✅

```r
# TOUJOURS utiliser ce pattern :

param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

tryCatch({
  # Votre code parallèle
  results <- bplapply(data_list, fun, BPPARAM = param)

}, error = function(e) {
  cat("Erreur parallèle:", e$message, "\n")

}, finally = {
  # Fermeture GARANTIE même en cas d'erreur
  bpstop(param)
  gc(verbose = FALSE)
  cat("Sockets fermés\n")
})
```

---

### **Solution 3 : Checkpoint Avant Opération Risquée** ✅

```r
observeEvent(input$run_normalizer_search, {
  req(Rvars$cache_info)
  req(Rvars$Matrix_filtered)

  # SAUVEGARDER AVANT l'opération risquée
  save_checkpoint_with_progress(
    checkpoint_id = "step_03_before_normalizer",
    cache_info = Rvars$cache_info,
    variables = list(
      Matrix_filtered = Rvars$Matrix_filtered,
      groups = Rvars$groups,
      isotopes = Rvars$isotopes
    ),
    step_name = "Ready for Normalizer Search",
    next_step = "Normalizer Search"
  )

  # ENSUITE faire la recherche parallèle
  tryCatch({
    # Déterminer workers
    n_samples <- ncol(Rvars$Matrix_filtered)
    workers <- if (n_samples >= 300) 2 else min(4, detectCores() - 1)

    # Créer batches
    batch_size <- if (n_samples >= 300) 30 else 50
    batches <- create_batches(Rvars$Matrix_filtered, batch_size)

    # Paralléliser
    param <- SnowParam(workers = workers, type = "SOCK", timeout = 600)

    results <- bplapply(
      batches,
      process_batch_normalizers,
      pFeatures = input$pFeatures,
      pSample = input$pSample,
      minNorm = input$minNormalizers,
      BPPARAM = param
    )

    bpstop(param)
    gc()

    # Combiner
    Rvars$normalizers <- combine_results(results)

    # Sauvegarder après succès
    save_checkpoint_with_progress(
      checkpoint_id = "step_04_normalizers_found",
      cache_info = Rvars$cache_info,
      variables = list(
        Matrix_filtered = Rvars$Matrix_filtered,
        groups = Rvars$groups,
        normalizers = Rvars$normalizers
      ),
      step_name = "Normalizers Found",
      next_step = "Normalization"
    )

  }, error = function(e) {
    showNotification(
      paste0("❌ Normalizer search failed: ", e$message),
      type = "error",
      duration = 10
    )

    # En cas d'erreur, le checkpoint "before_normalizer" existe
    # → L'utilisateur peut reprendre depuis là !
  })
})
```

---

### **Solution 4 : Traitement Hybride** ✅

Pour **très grandes données** (>500 échantillons), combinez séquentiel + parallèle :

```r
# Stratégie hybride : batches séquentiels, contenu parallèle

n_samples <- ncol(input_Matrix)
batch_size <- 50
n_batches <- ceiling(n_samples / batch_size)

all_results <- list()

withProgress(message = "Searching normalizers...", value = 0, {

  for (b in 1:n_batches) {
    incProgress(1/n_batches, detail = sprintf("Batch %d/%d", b, n_batches))

    # Extraire le batch
    start_idx <- (b - 1) * batch_size + 1
    end_idx <- min(b * batch_size, n_samples)
    batch_matrix <- input_Matrix[, start_idx:end_idx, drop = FALSE]

    # Traiter CE batch en parallèle (par échantillon)
    sample_list <- lapply(1:ncol(batch_matrix), function(i) {
      list(data = batch_matrix[, i, drop = FALSE])
    })

    # Paralléliser à l'intérieur du batch
    param <- SnowParam(workers = 2, type = "SOCK", timeout = 300)

    batch_results <- bplapply(
      sample_list,
      function(s) Search_normalizers(s$data, pFeatures, pSample, minNorm),
      BPPARAM = param
    )

    bpstop(param)
    gc()

    all_results[[b]] <- do.call(rbind, batch_results)

    # Checkpoint intermédiaire tous les 3 batches
    if (b %% 3 == 0) {
      temp_result <- do.call(rbind, all_results)
      save_checkpoint(
        checkpoint_id = sprintf("normalizer_batch_%d", b),
        cache_info = Rvars$cache_info,
        variables = list(partial_results = temp_result),
        step_name = sprintf("Normalizer Search - Batch %d/%d", b, n_batches),
        next_step = "Continue search"
      )
    }
  }

  # Résultat final
  RvarsInternalStandard$OjectNormalizers <- do.call(rbind, all_results)
})
```

**Avantages :**
- ✅ Mémoire contrôlée (1 batch à la fois)
- ✅ Parallélisation à l'intérieur des batches
- ✅ Checkpoints intermédiaires (reprise possible)
- ✅ Barre de progression visible

---

## 📊 Comparaison des Solutions

| Solution | Vitesse | Mémoire | Complexité | Recommandé pour |
|----------|---------|---------|------------|-----------------|
| **Par échantillon** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | < 200 échantillons |
| **Par batch** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | 200-400 échantillons |
| **Hybride (batch séquentiel + parallèle interne)** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **>300 échantillons (votre cas)** |
| **Interne à Search_normalizers()** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | Si la fonction a des boucles internes |

---

## 🎯 Recommandation Finale pour 312 Fichiers

### **Approche Recommandée : Hybride avec Checkpoints**

```r
observeEvent(input$run_normalizer_search, {
  req(Rvars$Matrix_filtered)

  # Configuration
  n_samples <- ncol(Rvars$Matrix_filtered)
  batch_size <- 30  # 30 échantillons par batch
  n_batches <- ceiling(n_samples / batch_size)
  workers <- 2      # 2 workers seulement pour Windows + grande donnée

  cat(sprintf("\n=== Normalizer Search ===\n"))
  cat(sprintf("Samples: %d\n", n_samples))
  cat(sprintf("Batches: %d (size: %d)\n", n_batches, batch_size))
  cat(sprintf("Workers per batch: %d\n", workers))

  # Checkpoint AVANT
  save_checkpoint_with_progress(
    checkpoint_id = "step_03_before_normalizer",
    cache_info = Rvars$cache_info,
    variables = list(
      Matrix_filtered = Rvars$Matrix_filtered,
      groups = Rvars$groups
    ),
    step_name = "Ready for Normalizer Search",
    next_step = "Normalizer Search"
  )

  # Traitement par batch séquentiel
  all_results <- list()

  withProgress(message = "Searching normalizers...", value = 0, {

    for (b in 1:n_batches) {
      incProgress(1/n_batches, detail = sprintf("Batch %d/%d", b, n_batches))

      # Extraire batch
      start_idx <- (b - 1) * batch_size + 1
      end_idx <- min(b * batch_size, n_samples)
      batch_matrix <- Rvars$Matrix_filtered[, start_idx:end_idx, drop = FALSE]

      # Liste d'échantillons pour ce batch
      sample_list <- lapply(1:ncol(batch_matrix), function(i) {
        list(
          data = batch_matrix[, i, drop = FALSE],
          name = colnames(batch_matrix)[i]
        )
      })

      # Parallélisation INTRA-batch
      param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

      tryCatch({
        batch_results <- bplapply(
          sample_list,
          function(s, pFeat, pSamp, minN) {
            Search_normalizers(
              Matrix = s$data,
              pFeatures = pFeat,
              pSample = pSamp,
              minNormalizersParam = minN
            )
          },
          pFeat = input$pFeatures,
          pSamp = input$pSample,
          minN = input$minNormalizers,
          BPPARAM = param
        )

      }, finally = {
        bpstop(param)  # TOUJOURS fermer
        gc(verbose = FALSE)
      })

      all_results[[b]] <- do.call(rbind, batch_results)

      # Checkpoint intermédiaire tous les 5 batches
      if (b %% 5 == 0 || b == n_batches) {
        temp_result <- do.call(rbind, all_results)
        save_checkpoint(
          checkpoint_id = sprintf("normalizer_progress_batch%d", b),
          cache_info = Rvars$cache_info,
          variables = list(
            partial_normalizers = temp_result,
            batches_completed = b
          ),
          step_name = sprintf("Normalizer Search Progress (%d/%d)", b, n_batches),
          next_step = if(b == n_batches) "Normalization" else "Continue search"
        )
      }
    }

    # Résultat final
    RvarsInternalStandard$OjectNormalizers <- do.call(rbind, all_results)

    # Checkpoint final
    save_checkpoint_with_progress(
      checkpoint_id = "step_04_normalizers_complete",
      cache_info = Rvars$cache_info,
      variables = list(
        Matrix_filtered = Rvars$Matrix_filtered,
        groups = Rvars$groups,
        normalizers = RvarsInternalStandard$OjectNormalizers
      ),
      step_name = "Normalizers Found",
      next_step = "Normalization"
    )

    showNotification(
      sprintf("✅ Found normalizers in %d batches", n_batches),
      type = "message"
    )
  })
})
```

---

## ✅ Checklist Finale

Pour que la parallélisation fonctionne avec vos données immenses :

- [ ] **Diviser en tâches indépendantes** (échantillons ou batches)
- [ ] **Limiter workers à 2** pour 300+ fichiers sur Windows
- [ ] **Utiliser `bpstop()` TOUJOURS** dans un bloc `finally`
- [ ] **Ajouter timeout** (300-600 secondes)
- [ ] **Checkpoints avant/après** les opérations risquées
- [ ] **Libérer mémoire** avec `gc()` après chaque batch
- [ ] **Barre de progression** pour visibilité utilisateur
- [ ] **Gestion d'erreur** avec messages clairs

---

## 🔍 Diagnostic Rapide

Pour vérifier si votre parallélisation fonctionne :

```r
# Ajouter des logs dans votre fonction
process_sample <- function(sample_data, ...) {
  worker_id <- Sys.getpid()  # ID du processus
  cat(sprintf("[Worker %d] Processing sample...\n", worker_id))

  result <- Search_normalizers(sample_data, ...)

  return(result)
}

# Si vous voyez plusieurs Worker IDs différents → PARALLÈLE ✅
# Si vous voyez toujours le même Worker ID → SÉQUENTIEL ❌
```

---

**Résumé : Votre code était séquentiel parce qu'il n'y avait qu'**une seule tâche** (la matrice entière). Pour paralléliser, il faut diviser en **plusieurs tâches indépendantes** (échantillons ou batches) et utiliser la syntaxe correcte de `bplapply()`.**
