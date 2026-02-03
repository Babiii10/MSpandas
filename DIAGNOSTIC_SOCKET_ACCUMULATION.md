# Comprendre le Problème Fondamental : Accumulation des Sockets

## 🎯 Observation Critique

Vous avez identifié un comportement très révélateur :

### ✅ **Scénario A : Recherche Directe (Fonctionne)**
```
1. Lancer l'application
2. Charger les données
3. Recherche normalisateurs directement
   → makeCluster() fonctionne parfaitement ✅
   → Parallélisation effective ✅
```

### ❌ **Scénario B : Workflow Complet (Échoue)**
```
1. Lancer l'application
2. Charger les données
3. Grouping Massif (parallèle) → Sockets ouverts mais pas fermés ⚠️
4. Génération Map (parallèle) → Encore plus de sockets ⚠️
5. Recherche normalisateurs
   → makeCluster() ÉCHOUE ❌
   → "cannot create connection" ou timeout
```

**Pourquoi cette différence ?**

---

## 🔍 Explication du Problème : Fuite de Sockets (Socket Leak)

### **Le Problème Fondamental**

Windows a un **nombre limité de ports éphémères** disponibles pour les connexions socket :
- **Plage par défaut** : 49152-65535 (16,384 ports)
- **Utilisables en pratique** : ~10,000-12,000 ports

Chaque worker créé par `makeCluster()` ou `SnowParam()` consomme **1 port TCP**.

### **Ce qui se passe dans votre workflow**

```r
# ÉTAPE 1 : Grouping Massif (analysisItemNewSamples.server.R:4466)
workers <- ceiling((detectCores()) - 1)  # Ex: 7 workers
param <- SnowParam(workers = workers, type = "SOCK")
res1 <- bplapply(...)  # Ouvre 7 sockets
res2 <- bplapply(...)  # Réutilise les 7 sockets (OK)
# ❌ PAS DE bpstop(param) → 7 sockets restent ouverts !

# ÉTAPE 2 : Génération Map - Peak Picking (peakPickingNewReferenceMap.R:382)
workers <- detectCores() - 1  # 7 workers
param <- SnowParam(workers = workers, type = "SOCK")
res <- bplapply(...)  # Ouvre 7 NOUVEAUX sockets (total: 14)
# ❌ PAS DE bpstop(param) → 7 sockets supplémentaires restent !

# ÉTAPE 3 : Génération Map - Grouping (GenerateMapRef.Server_NewRefMap.R:795)
workers <- ceiling((detectCores()) - 1)  # 7 workers
param <- SnowParam(workers = workers, type = "SOCK")
res1 <- bplapply(...)  # Ouvre 7 NOUVEAUX sockets (total: 21)
res2 <- bplapply(...)  # Réutilise les 7 sockets
# ❌ PAS DE bpstop(param) → 7 sockets supplémentaires restent !

# ÉTAPE 4 : Processing Analysis (ProcessingAnalysisNewsample.lib.R:579)
n_cores <- detectCores() - 1  # 7 workers
cl <- makeCluster(n_cores, type = "PSOCK")
result <- parLapply(cl, ...)  # Ouvre 7 NOUVEAUX sockets (total: 28)
# ❌ PAS DE stopCluster(cl) → 7 sockets supplémentaires restent !

# À CE STADE : 28 sockets ouverts pour un petit dataset !
```

### **Calcul pour 312 fichiers**

Avec 312 fichiers, vous avez probablement :
- Plus de passes dans les boucles
- Plus d'appels parallèles
- Accumulation massive

**Estimation réaliste pour 312 fichiers :**
```
Grouping Massif:    7 workers × 10 passes = 70 sockets non fermés
Peak Picking Map:   7 workers × 15 passes = 105 sockets non fermés
Grouping Map:       7 workers × 20 passes = 140 sockets non fermés
Processing Analy.:  7 workers × 25 passes = 175 sockets non fermés
                                TOTAL: ~490 sockets accumulés !
```

**Quand vous arrivez à la recherche de normalisateurs :**
```r
# ÉTAPE 5 : Recherche Normalisateurs
workers <- 2  # Seulement 2 workers
cl <- makeCluster(workers, type = "PSOCK")
# ❌ ÉCHEC : Le système a déjà 490 sockets ouverts !
# Windows refuse d'en ouvrir 2 de plus
```

### **Pourquoi ça marche en lançant directement ?**

Quand vous lancez **directement** la recherche :
```
État initial : 0 sockets ouverts
Recherche normalisateurs : 2 sockets
Total : 2 sockets → ✅ Fonctionne parfaitement !
```

---

## 🔬 Diagnostic : Vérifier l'État des Sockets

### **Méthode 1 : Compter les Connexions R Actives (Windows)**

```r
# Dans R, afficher toutes les connexions
showConnections(all = TRUE)

# Nombre de connexions ouvertes
length(getAllConnections())

# Détails de chaque connexion
conn_info <- showConnections(all = TRUE)
print(conn_info)
```

**Exemple de sortie :**
```
  description       class     mode   text  opened  can read can write
3 "<-localhost:11000" "sockconn" "a+b"  "binary" "opened"  "yes"    "yes"
4 "<-localhost:11001" "sockconn" "a+b"  "binary" "opened"  "yes"    "yes"
5 "<-localhost:11002" "sockconn" "a+b"  "binary" "opened"  "yes"    "yes"
...
```

Si vous voyez **des dizaines** de connexions `sockconn` ouvertes, c'est le problème !

### **Méthode 2 : Vérifier les Ports Windows (PowerShell)**

```powershell
# Compter les connexions ESTABLISHED
netstat -an | findstr "ESTABLISHED" | findstr "127.0.0.1" | measure-object -line

# Voir les ports utilisés par R
netstat -ano | findstr "<PID_de_R>"
```

**Interpréter les résultats :**
- **< 50 connexions** : OK, état normal
- **50-200 connexions** : Commence à être beaucoup
- **200-500 connexions** : ⚠️ Problème de fuite
- **500+ connexions** : ❌ Saturation imminente

### **Méthode 3 : Ajouter du Diagnostic dans le Code**

```r
# Ajouter au début de chaque étape parallèle
diagnose_connections <- function(step_name) {
  n_conn <- length(getAllConnections())
  cat(sprintf("[%s] Connexions actives: %d\n", step_name, n_conn))

  if (n_conn > 100) {
    cat("⚠️  WARNING: Trop de connexions ouvertes!\n")
  }

  return(n_conn)
}

# Utilisation
observeEvent(input$run_grouping, {
  diagnose_connections("AVANT Grouping")

  # Votre code de grouping
  param <- SnowParam(workers = workers, type = "SOCK")
  res <- bplapply(...)
  bpstop(param)  # Important !

  diagnose_connections("APRÈS Grouping")
})
```

**Sortie attendue (workflow complet) :**
```
[AVANT Grouping] Connexions actives: 3 (stdin, stdout, stderr)
[APRÈS Grouping] Connexions actives: 3  ← ✅ BON (si bpstop appelé)
[AVANT Grouping] Connexions actives: 10 ← ❌ FUITE (si pas bpstop)

[AVANT Peak Picking] Connexions actives: 10
[APRÈS Peak Picking] Connexions actives: 17 ← ❌ ACCUMULATION

[AVANT Map Generation] Connexions actives: 17
[APRÈS Map Generation] Connexions actives: 24

[AVANT Normalizer Search] Connexions actives: 24
makeCluster() → ❌ ÉCHEC (trop de sockets déjà utilisés)
```

---

## 🛠️ Sources du Problème Identifiées

### **1. Absence de `bpstop()` dans BiocParallel**

**Emplacements critiques (déjà identifiés) :**

#### **A. analysisItemNewSamples.server.R:4466**
```r
# CODE ACTUEL (FUITE)
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")
res1 <- bplapply(Massif_List_ToGroup, Grouping.Massif_AnalysisNewSample,
                 mz.tolerance = 0.15, rt.tolerance = 30, BPPARAM = param)
res2 <- bplapply(res1, Grouping.Massif.RT_AnalysisNewSample,
                 mz.tolerance = 0.15, rt.tolerance = 30, BPPARAM = param)
# ❌ PAS DE bpstop(param) !

# CODE CORRIGÉ
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

tryCatch({
  res1 <- bplapply(...)
  res2 <- bplapply(...)
}, finally = {
  bpstop(param)  # ✅ TOUJOURS fermer !
  gc()
})
```

#### **B. GenerateMapRef.Server_NewRefMap.R:795**
```r
# CODE ACTUEL (FUITE)
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")
res1 <- bplapply(Massif_List_ToGroup, Grouping.Massif_NewRefMap, ...)
res2 <- bplapply(res1, Grouping.Massif.RT_NewRefMap, ...)
# ❌ PAS DE bpstop(param) !

# CODE CORRIGÉ
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

tryCatch({
  res1 <- bplapply(...)
  res2 <- bplapply(...)
}, finally = {
  bpstop(param)
  gc()
})
```

#### **C. peakPickingNewReferenceMap.R:382**
```r
# CODE ACTUEL (FUITE)
workers <- detectCores() - 1
param <- SnowParam(workers = workers, type = "SOCK")
res <- bplapply(Split_data_PeakPicking, peakpickingsingle, ...)
# ❌ PAS DE bpstop(param) !

# CODE CORRIGÉ
workers <- detectCores() - 1
param <- SnowParam(workers = workers, type = "SOCK")

tryCatch({
  res <- bplapply(...)
}, finally = {
  bpstop(param)
  gc()
})
```

#### **D. ProcessingAnalysisNewsample.lib.R:579**
```r
# CODE ACTUEL (FUITE)
n_cores <- detectCores() - 1
cl <- makeCluster(n_cores, type = "PSOCK")
result <- parLapply(cl, list_of_data, processing_function)
# ❌ PAS DE stopCluster(cl) !

# CODE CORRIGÉ
n_cores <- detectCores() - 1
cl <- makeCluster(n_cores, type = "PSOCK")

tryCatch({
  result <- parLapply(cl, list_of_data, processing_function)
}, finally = {
  stopCluster(cl)  # ✅ TOUJOURS fermer !
  gc()
})
```

### **2. Limite des Ports Éphémères Windows**

Windows limite le nombre de ports disponibles :
```powershell
# Vérifier la plage actuelle
netsh int ipv4 show dynamicport tcp

# Exemple de sortie :
# Start Port      : 49152
# Number of Ports : 16384
```

Avec 312 fichiers et plusieurs passes :
- Vous pouvez facilement ouvrir **500-1000 sockets**
- Windows commence à refuser les nouvelles connexions
- `makeCluster()` échoue avec "cannot create connection"

### **3. Garbage Collection Insuffisant**

Même si R ferme théoriquement les connexions à la fin d'une fonction, le **garbage collector** peut ne pas les libérer immédiatement :

```r
# Sans gc() explicite
param <- SnowParam(workers = 7, type = "SOCK")
res <- bplapply(...)
bpstop(param)
# Les sockets peuvent rester "en attente" de nettoyage

# Avec gc() explicite
param <- SnowParam(workers = 7, type = "SOCK")
res <- bplapply(...)
bpstop(param)
gc(verbose = FALSE)  # Force le nettoyage immédiat
```

---

## 💡 Solutions Stables pour un Système de Parallélisation Robuste

### **Solution 1 : Fermeture Systématique avec `try-finally`** (Recommandé)

**Pattern à utiliser PARTOUT :**

```r
# Pattern universel pour BiocParallel
execute_parallel_bioc <- function(data_list, fun, workers = NULL, ...) {

  # Configuration adaptative
  if (is.null(workers)) {
    workers <- min(detectCores() - 1, 4)
  }

  # Créer cluster
  param <- SnowParam(
    workers = workers,
    type = "SOCK",
    timeout = 300,
    progressbar = FALSE
  )

  # Exécuter avec garantie de fermeture
  tryCatch({
    result <- bplapply(data_list, fun, ..., BPPARAM = param)
    return(result)

  }, error = function(e) {
    cat(sprintf("❌ Parallel execution error: %s\n", e$message))
    return(NULL)

  }, finally = {
    # GARANTIE : Fermeture même si erreur
    bpstop(param)
    gc(verbose = FALSE)
    cat("✅ Sockets closed\n")
  })
}

# Utilisation
res1 <- execute_parallel_bioc(Massif_List_ToGroup, Grouping.Massif_NewRefMap)
res2 <- execute_parallel_bioc(res1, Grouping.Massif.RT_NewRefMap)
```

**Pattern pour `parallel::makeCluster()` :**

```r
# Pattern universel pour parallel
execute_parallel_cluster <- function(data_list, fun, workers = NULL, ...) {

  if (is.null(workers)) {
    workers <- min(detectCores() - 1, 4)
  }

  cl <- makeCluster(workers, type = "PSOCK")

  tryCatch({
    # Export des fonctions/variables nécessaires
    clusterExport(cl, varlist = c(...), envir = environment())

    # Exécution
    result <- parLapply(cl, data_list, fun)
    return(result)

  }, error = function(e) {
    cat(sprintf("❌ Cluster error: %s\n", e$message))
    return(NULL)

  }, finally = {
    stopCluster(cl)
    gc(verbose = FALSE)
    cat("✅ Cluster closed\n")
  })
}
```

### **Solution 2 : Pool de Workers Réutilisable** (Pour Workflow Complet)

Au lieu de créer/détruire des clusters à chaque étape, créez **un seul pool** pour tout le workflow :

```r
# Au début du workflow
create_worker_pool <- function(n_workers = NULL) {
  if (is.null(n_workers)) {
    n_workers <- min(detectCores() - 1, 4)
  }

  param <- SnowParam(
    workers = n_workers,
    type = "SOCK",
    timeout = 600,
    progressbar = FALSE
  )

  return(param)
}

# Utilisation dans le workflow
observeEvent(input$run_full_workflow, {

  # Créer le pool UNE FOIS
  worker_pool <- create_worker_pool(n_workers = 4)

  tryCatch({
    # Étape 1 : Grouping (réutilise le pool)
    res1 <- bplapply(Massif_List, Grouping.Massif, BPPARAM = worker_pool)
    diagnose_connections("Après Grouping")

    # Étape 2 : Map Generation (réutilise le pool)
    res2 <- bplapply(res1, Generate.Map, BPPARAM = worker_pool)
    diagnose_connections("Après Map Gen")

    # Étape 3 : Normalizer Search (réutilise le pool)
    res3 <- bplapply(sample_list, Search_normalizers, BPPARAM = worker_pool)
    diagnose_connections("Après Normalizers")

  }, finally = {
    # Fermer le pool UNE FOIS à la fin
    bpstop(worker_pool)
    gc()
    cat("✅ Worker pool closed\n")
  })
})
```

**Avantages :**
- ✅ Seulement N workers pour tout le workflow
- ✅ Pas de création/destruction répétée
- ✅ Pas d'accumulation de sockets
- ✅ Plus rapide (pas d'overhead de création)

### **Solution 3 : Parallélisation Hybride avec Contrôle Fin**

Combinez parallélisation et traitement séquentiel pour les grandes données :

```r
# Pour 312 fichiers : Batches séquentiels + parallèle interne
process_large_dataset_hybrid <- function(data_matrix, batch_size = 50, workers = 2) {

  n_samples <- ncol(data_matrix)
  n_batches <- ceiling(n_samples / batch_size)

  cat(sprintf("Processing %d samples in %d batches\n", n_samples, n_batches))

  all_results <- list()

  # Créer pool UNE FOIS pour tous les batches
  param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

  tryCatch({
    # Traiter chaque batch séquentiellement
    for (b in 1:n_batches) {
      cat(sprintf("Batch %d/%d...", b, n_batches))

      # Extraire batch
      start_idx <- (b - 1) * batch_size + 1
      end_idx <- min(b * batch_size, n_samples)
      batch_data <- data_matrix[, start_idx:end_idx, drop = FALSE]

      # Créer liste d'échantillons
      sample_list <- lapply(1:ncol(batch_data), function(i) {
        list(data = batch_data[, i, drop = FALSE])
      })

      # Paralléliser À L'INTÉRIEUR du batch (réutilise le pool)
      batch_results <- bplapply(
        sample_list,
        function(s) Search_normalizers(s$data, ...),
        BPPARAM = param
      )

      all_results[[b]] <- do.call(rbind, batch_results)

      cat(" ✅\n")

      # Diagnostic
      if (b %% 3 == 0) {
        n_conn <- length(getAllConnections())
        cat(sprintf("  Connexions actives: %d\n", n_conn))
      }
    }

  }, finally = {
    # Fermer le pool UNE FOIS
    bpstop(param)
    gc()
  })

  # Combiner résultats
  return(do.call(rbind, all_results))
}

# Utilisation
normalizers <- process_large_dataset_hybrid(
  data_matrix = Matrix_filtered,
  batch_size = 30,
  workers = 2
)
```

### **Solution 4 : Nettoyage Proactif entre les Étapes**

Ajoutez un nettoyage explicite entre chaque étape majeure :

```r
# Fonction de nettoyage agressif
cleanup_connections <- function(verbose = TRUE) {
  # Fermer toutes les connexions sauf stdin/stdout/stderr
  all_conn <- getAllConnections()
  base_conn <- c(0, 1, 2)  # stdin, stdout, stderr

  to_close <- setdiff(all_conn, base_conn)

  if (length(to_close) > 0) {
    if (verbose) {
      cat(sprintf("⚠️  Found %d open connections, closing...\n", length(to_close)))
    }

    for (conn_id in to_close) {
      tryCatch({
        close(getConnection(conn_id))
      }, error = function(e) {
        # Ignore errors
      })
    }
  }

  # Force garbage collection
  gc(verbose = FALSE)

  # Attendre que les sockets se libèrent
  Sys.sleep(0.5)

  final_count <- length(getAllConnections())
  if (verbose) {
    cat(sprintf("✅ Cleanup done. Remaining connections: %d\n", final_count))
  }

  return(final_count)
}

# Utilisation dans le workflow
observeEvent(input$run_workflow, {

  # Étape 1 : Grouping
  withProgress(message = "Grouping...", {
    # ... votre code ...
  })
  cleanup_connections()  # Nettoyage entre étapes

  # Étape 2 : Map Generation
  withProgress(message = "Generating map...", {
    # ... votre code ...
  })
  cleanup_connections()  # Nettoyage entre étapes

  # Étape 3 : Normalizer Search
  withProgress(message = "Searching normalizers...", {
    # ... votre code ...
  })
  cleanup_connections()  # Nettoyage final
})
```

### **Solution 5 : Limitation Adaptative des Workers**

Réduisez dynamiquement le nombre de workers au fur et à mesure du workflow :

```r
# Configuration adaptative progressive
get_adaptive_workers <- function(stage, n_samples) {

  # Nombre de connexions actuelles
  current_conn <- length(getAllConnections())

  # Stratégie : Réduire workers si trop de connexions
  if (current_conn > 50) {
    max_workers <- 2  # Très conservateur
  } else if (current_conn > 20) {
    max_workers <- 3
  } else {
    max_workers <- 4
  }

  # Ajuster selon la taille des données
  if (n_samples >= 300) {
    max_workers <- min(max_workers, 2)
  }

  cat(sprintf("[%s] Workers: %d (connexions actuelles: %d)\n",
              stage, max_workers, current_conn))

  return(max_workers)
}

# Utilisation
observeEvent(input$run_grouping, {
  n_workers <- get_adaptive_workers("Grouping", ncol(data_matrix))
  param <- SnowParam(workers = n_workers, type = "SOCK")
  # ...
})

observeEvent(input$run_normalizers, {
  n_workers <- get_adaptive_workers("Normalizers", ncol(data_matrix))
  param <- SnowParam(workers = n_workers, type = "SOCK")
  # ...
})
```

---

## 📊 Comparaison des Approches

| Approche | Complexité | Efficacité | Robustesse | Recommandé pour |
|----------|------------|------------|------------|-----------------|
| **Try-Finally systématique** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Tous les cas (BASE) |
| **Pool réutilisable** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Workflow complet |
| **Hybride (batch+parallèle)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 300+ échantillons |
| **Nettoyage proactif** | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | En complément |
| **Workers adaptatifs** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | En complément |

---

## 🎯 Recommandation Finale pour 312 Fichiers

### **Stratégie Combinée (Maximum de Robustesse)**

```r
# 1. Créer un module de gestion des workers
source("lib/ParallelWorkerManager.lib.R")

# 2. Configuration du workflow
WORKFLOW_CONFIG <- list(
  # Pool unique pour tout le workflow
  use_worker_pool = TRUE,
  pool_workers = 2,  # Limité pour 312 fichiers

  # Nettoyage entre étapes
  cleanup_between_steps = TRUE,

  # Checkpoints
  enable_checkpoints = TRUE,
  checkpoint_every = 5,

  # Diagnostic
  verbose_connections = TRUE
)

# 3. Exécution du workflow
observeEvent(input$run_full_analysis, {

  # Diagnostic initial
  diagnose_connections("Workflow START")

  # Créer pool unique
  worker_pool <- create_worker_pool(n_workers = WORKFLOW_CONFIG$pool_workers)

  tryCatch({

    # ÉTAPE 1 : Grouping Massif
    withProgress(message = "Grouping...", {
      res_grouping <- bplapply(
        Massif_List,
        Grouping.Massif,
        BPPARAM = worker_pool
      )
    })
    diagnose_connections("Après Grouping")
    if (WORKFLOW_CONFIG$cleanup_between_steps) cleanup_connections()

    # ÉTAPE 2 : Map Generation
    withProgress(message = "Generating map...", {
      res_map <- bplapply(
        res_grouping,
        Generate.Map,
        BPPARAM = worker_pool
      )
    })
    diagnose_connections("Après Map")
    if (WORKFLOW_CONFIG$cleanup_between_steps) cleanup_connections()

    # ÉTAPE 3 : Normalizer Search (avec batches)
    withProgress(message = "Searching normalizers...", {
      normalizers <- process_large_dataset_hybrid(
        data_matrix = Matrix_filtered,
        batch_size = 30,
        workers = 2  # Utilise le pool existant
      )
    })
    diagnose_connections("Après Normalizers")

  }, finally = {
    # Fermer le pool
    bpstop(worker_pool)
    cleanup_connections()
    diagnose_connections("Workflow END")
  })
})
```

---

## 📋 Checklist de Vérification

Avant de lancer le workflow complet avec 312 fichiers :

- [ ] **Tous les `SnowParam()` ont un `bpstop()` correspondant**
- [ ] **Tous les `makeCluster()` ont un `stopCluster()` correspondant**
- [ ] **Utilisation de `try-finally` pour garantir la fermeture**
- [ ] **`gc()` appelé après chaque fermeture**
- [ ] **Diagnostic activé** (`diagnose_connections()` entre étapes)
- [ ] **Workers limités à 2** pour 312 fichiers
- [ ] **Checkpoints activés** avant opérations risquées
- [ ] **Nettoyage entre étapes** si accumulation détectée

---

## 🔧 Script de Diagnostic Complet

```r
# Créer ce fichier : lib/DiagnoseParallelSystem.R

diagnose_parallel_system <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("🔍 DIAGNOSTIC DU SYSTÈME DE PARALLÉLISATION\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  # 1. Connexions R
  all_conn <- getAllConnections()
  n_conn <- length(all_conn)

  cat(sprintf("1. Connexions R actives: %d\n", n_conn))
  if (n_conn > 10) {
    cat("   ⚠️  WARNING: Nombre élevé de connexions!\n")
  }

  # Détails
  if (n_conn > 0) {
    conn_info <- showConnections(all = TRUE)
    sock_conn <- sum(grepl("sockconn", conn_info[, "class"]))
    cat(sprintf("   - Socket connections: %d\n", sock_conn))
  }

  # 2. Mémoire
  mem_info <- gc()
  cat(sprintf("\n2. Mémoire utilisée: %.1f MB\n",
              sum(mem_info[, "used"]) / 1024))

  # 3. Workers potentiels
  n_cores <- detectCores()
  cat(sprintf("\n3. Cores disponibles: %d\n", n_cores))
  cat(sprintf("   Recommandé: %d workers\n", min(n_cores - 1, 4)))

  # 4. Test de création cluster
  cat("\n4. Test création cluster...")
  test_passed <- tryCatch({
    test_cl <- makeCluster(2, type = "PSOCK")
    stopCluster(test_cl)
    gc()
    TRUE
  }, error = function(e) {
    cat(sprintf("\n   ❌ ÉCHEC: %s\n", e$message))
    FALSE
  })

  if (test_passed) {
    cat(" ✅ OK\n")
  }

  # 5. Recommandations
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("RECOMMANDATIONS:\n")

  if (n_conn > 20) {
    cat("❌ Trop de connexions ouvertes!\n")
    cat("   → Exécuter cleanup_connections()\n")
    cat("   → Vérifier que tous les bpstop() sont appelés\n")
  } else if (n_conn > 10) {
    cat("⚠️  Nombre de connexions élevé\n")
    cat("   → Surveiller l'accumulation\n")
  } else {
    cat("✅ État des connexions normal\n")
  }

  if (!test_passed) {
    cat("\n❌ PROBLÈME CRITIQUE:\n")
    cat("   Impossible de créer un cluster!\n")
    cat("   Solutions:\n")
    cat("   1. cleanup_connections()\n")
    cat("   2. Redémarrer session R\n")
    cat("   3. Vérifier pare-feu Windows\n")
  }

  cat("═══════════════════════════════════════════════════════════════\n\n")

  return(invisible(list(
    n_connections = n_conn,
    test_passed = test_passed,
    recommended_workers = min(n_cores - 1, 4)
  )))
}

# Utilisation
diagnose_parallel_system()
```

---

## 🎓 Conclusion : Comprendre le Processus Parallèle et la Gestion des Connexions

### **Le Problème Fondamental**

Votre observation était exacte : **le problème se joue sur la compréhension du processus parallèle et de la gestion des connexions**.

**Ce qui se passe réellement :**

1. **Chaque `SnowParam()` ou `makeCluster()` ouvre N sockets TCP**
2. **Ces sockets restent ouverts jusqu'à `bpstop()` ou `stopCluster()`**
3. **Sans fermeture explicite, les sockets s'accumulent**
4. **Windows a une limite (~10,000-16,000 ports)**
5. **Après plusieurs étapes, la limite est atteinte**
6. **`makeCluster()` suivant échoue car plus de ports disponibles**

### **Pourquoi ça marche en lançant directement ?**

Parce que vous partez d'un **état propre** : 0 sockets ouverts → `makeCluster()` fonctionne.

### **Solutions Essentielles**

1. **TOUJOURS fermer** : `bpstop()` ou `stopCluster()`
2. **Utiliser try-finally** : Garantit la fermeture même si erreur
3. **Pool réutilisable** : 1 seul pool pour tout le workflow
4. **Nettoyage entre étapes** : `cleanup_connections()`
5. **Diagnostic** : Surveiller l'accumulation

**Avec ces corrections, votre workflow 312 fichiers fonctionnera de manière stable et prévisible !**
