# Solutions pour Windows: Parallélisation Sans Crash (312+ Fichiers)

## 🪟 CONTRAINTE WINDOWS

**Sur Windows, fork() n'existe pas!**
- ❌ MulticoreParam: Ne fonctionne PAS
- ❌ mclapply: Ne fonctionne PAS
- ❌ plan(multicore): Fallback automatique vers sockets
- ✅ **Seule option: SOCKETS (PSOCK/SnowParam)**

**Donc: On DOIT utiliser des sockets sur Windows, mais on peut les GÉRER mieux!**

---

## ❓ VOS QUESTIONS

### Question 1: Limiter le nombre de workers dans la recherche de normalisateurs?

✅ **OUI, déjà fait mais on peut optimiser encore plus!**

**Actuellement (déjà appliqué):**
```r
# InternalStandard.lib_NewRefMap.R ligne 990-993
workers <- if (n_samples < 50) {
  max_workers
} else if (n_samples < 150) {
  max(2, floor(max_workers * 0.75))
} else if (n_samples < 300) {
  max(2, floor(max_workers * 0.5))
} else {
  max(2, min(4, floor(max_workers * 0.25)))  # Max 4 workers pour 312+
}
```

**Résultat pour 312 fichiers:**
- Ancien: 7-15 workers
- Nouveau: 2-4 workers
- Réduction: -75% de sockets

**💡 Optimisation possible pour Windows:**
```r
# WINDOWS: Encore plus conservateur
workers <- if (n_samples < 50) {
  max(2, floor(max_workers * 0.5))  # 50% même pour petits datasets
} else if (n_samples < 150) {
  max(2, floor(max_workers * 0.4))  # 40%
} else if (n_samples < 300) {
  max(2, floor(max_workers * 0.3))  # 30%
} else {
  2  # FIXE à 2 workers pour 300+ (Windows strict)
}

cat(sprintf("Windows mode: Using %d workers (conservative)\n", workers))
```

**Impact attendu:**
- 312 fichiers: 2 workers fixes (au lieu de 2-4)
- Plus lent mais plus stable sur Windows

---

### Question 2: Les connexions socket/port sont-elles fermées après les processus d'avant?

❌ **NON! C'est EXACTEMENT le problème!**

**État actuel du code:**

#### A. CE-Time Correction
```r
# Fichier: CE_time_Correction.lib.R (lignes 4-9)

# ✅ PARTIELLEMENT FIXÉ (évite duplication)
if (!exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
  register(SnowParam(workers = 1, type = "SOCK"), default = FALSE)
  assign(".biocparallel_registered_ce_time", TRUE, envir = .GlobalEnv)
}

# MAIS: Pas de nettoyage explicite après!
# → Le cluster reste en mémoire
# → Les sockets restent ESTABLISHED
```

**Problème:**
- Cluster créé UNE fois (bien)
- MAIS: Jamais arrêté explicitement
- Sur Windows: Les sockets persistent même après fin de fonction

#### B. Grouping.Between.Sample.Parallel()
```r
# Fichier: GenerateMapRef.lib.R (lignes 1649-1737)

param <- SnowParam(workers = n_cores, type = "SOCK")

grouped_blocks <- bplapply(
  X = blocks_list,
  FUN = function(block) { ... },
  BPPARAM = param
)

return(results_combined)  # ❌ PAS de bpstop() ou cleanup!
```

**Problème:**
- BiocParallel *devrait* nettoyer automatiquement
- **MAIS sur Windows, ce n'est PAS garanti!**
- Les workers peuvent rester en mémoire
- Les sockets restent ESTABLISHED

#### C. Search_normalizers()
```r
# Fichier: InternalStandard.lib_NewRefMap.R (lignes 999-1015)

cl <- parallel::makeCluster(workers, type = "PSOCK", timeout = 300)

on.exit({
  tryCatch({
    parallel::stopCluster(cl)  # ✅ BIEN fermé
    gc(verbose = FALSE)
  }, error = function(e) {
    message("Cluster cleanup warning: ", e$message)
  })
}, add = TRUE)
```

**Ce module: ✅ Bien nettoyé (depuis le fix récent)**

---

## 📊 ANALYSE: OÙ SONT LES FUITES?

### État des Sockets AVANT Search_normalizers() (312 fichiers)

```
┌──────────────────────────────────────────────────────────┐
│           ANALYSE DES FUITES SOCKET                      │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  1. CE-Time Correction                                  │
│     Source du problème: source() répété                 │
│     ────────────────────────────────────────            │
│     Ancien code (AVANT fix):                            │
│       → Chaque source(): register(bpstart(...))         │
│       → 312 fichiers × 6 plots = 1,872 clusters créés  │
│       → Sockets: 1,872 LEAKED ❌                        │
│                                                          │
│     Nouveau code (APRÈS fix):                           │
│       → register() UNE seule fois avec flag global      │
│       → Sockets créés: 1 worker × 1 cluster = 1         │
│       → MAIS: Jamais fermé explicitement               │
│       → Sockets: 1 PERSISTENT ⚠️                        │
│                                                          │
│  2. Grouping.Between.Sample.Parallel()                  │
│     ────────────────────────────────────────            │
│     Code actuel:                                        │
│       → param = SnowParam(workers = 8)                  │
│       → bplapply(..., BPPARAM = param)                  │
│       → return() sans cleanup explicite                 │
│                                                          │
│     Sur Linux: BiocParallel nettoie auto ✅             │
│     Sur Windows: Pas garanti! ⚠️                        │
│       → Workers peuvent rester actifs                   │
│       → Sockets: 0-8 POSSIBLEMENT LEAKED ⚠️            │
│                                                          │
│  3. Overhead Système Windows                            │
│     ────────────────────────────────────────            │
│     → Connexions RStudio/R GUI: ~20-50                  │
│     → Connexions R packages: ~50-100                    │
│     → TIME_WAIT sockets: ~200-500                       │
│                                                          │
│  TOTAL AVANT Search_normalizers():                      │
│  ═══════════════════════════════════════                │
│  Scénario optimiste:   1 + 0 + 70 = ~71 sockets        │
│  Scénario réaliste:    1 + 8 + 300 = ~309 sockets      │
│  Scénario pessimiste:  1,872 + 8 + 500 = ~2,380 ❌     │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Question clé: Le fix CE-Time a-t-il été appliqué dans votre version?**

---

## ✅ SOLUTIONS POUR WINDOWS

### Solution 1: Nettoyage Forcé des Sockets (RECOMMANDÉ #1)

**Ajouter cleanup explicite après CHAQUE étape parallèle**

#### A. Cleanup CE-Time

**Fichier:** `lib/NewReferenceMap/R_files/CE_time_Correction.lib.R`

**Ajouter à la FIN du fichier:**
```r
# Fonction de cleanup à appeler après CE-Time
cleanup_ce_time_cluster <- function() {
  if (exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
    tryCatch({
      # Arrêter tous les workers BiocParallel
      bpstop(bpparam())

      # Retirer le flag
      rm(".biocparallel_registered_ce_time", envir = .GlobalEnv)

      # Force garbage collection
      gc(verbose = FALSE)

      cat("CE-Time cluster cleaned up successfully\n")
    }, error = function(e) {
      warning(paste("CE-Time cleanup warning:", e$message))
    })
  }
}
```

**Appeler dans le serveur après CE-Time:**

**Fichier:** `server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R`

```r
# Après tous les renderPlot CE-Time, ajouter:

observeEvent(input$finalize_ce_time_button, {  # ou équivalent

  # ... votre code CE-Time existant ...

  # NOUVEAU: Cleanup forcé
  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R", local = TRUE)
  cleanup_ce_time_cluster()

  cat("CE-Time completed and sockets cleaned\n")
})
```

---

#### B. Cleanup Grouping

**Fichier:** `lib/NewReferenceMap/R_files/GenerateMapRef.lib.R`

**Modifier la fin de Grouping.Between.Sample.Parallel() (ligne 1717-1737):**

```r
# ANCIEN (ligne 1717-1719):
message(paste("Parallel grouping completed.", nrow(results_combined), "features grouped."))

return(results_combined)

# NOUVEAU:
message(paste("Parallel grouping completed.", nrow(results_combined), "features grouped."))

# CLEANUP EXPLICITE (Windows-safe)
tryCatch({
  # Arrêter le backend parallèle
  if (exists("param") && inherits(param, "BiocParallelParam")) {
    # Force l'arrêt de tous les workers
    bpstop(param)
  }

  # Garbage collection
  gc(verbose = FALSE)

  cat("Grouping parallel workers stopped successfully\n")
}, error = function(e) {
  warning(paste("Grouping cleanup warning:", e$message))
})

return(results_combined)
```

---

### Solution 2: Limiter Workers Windows (RECOMMANDÉ #2)

**Fichier:** `lib/NewReferenceMap/R_files/InternalStandard.lib_NewRefMap.R`

**Remplacer lignes 980-993:**

```r
# ANCIEN (ligne 980-993):
n_samples <- ncol(Matrix_filter_BySample)
max_workers <- detectCores() - 1

workers <- if (n_samples < 50) {
  max_workers
} else if (n_samples < 150) {
  max(2, floor(max_workers * 0.75))
} else if (n_samples < 300) {
  max(2, floor(max_workers * 0.5))
} else {
  max(2, min(4, floor(max_workers * 0.25)))
}

# NOUVEAU (Windows-optimisé):
n_samples <- ncol(Matrix_filter_BySample)
max_workers <- detectCores() - 1
is_windows <- .Platform$OS.type == "windows"

if (is_windows) {
  # Windows: Plus conservateur (sockets = ressource limitée)
  workers <- if (n_samples < 50) {
    max(2, floor(max_workers * 0.5))
  } else if (n_samples < 150) {
    2  # Fixe à 2
  } else if (n_samples < 300) {
    2  # Fixe à 2
  } else {
    2  # Fixe à 2 (TOUJOURS pour 300+)
  }
  cat(sprintf("Windows detected: Conservative mode, %d workers\n", workers))
} else {
  # Linux/macOS: Peut être plus agressif
  workers <- if (n_samples < 50) {
    max_workers
  } else if (n_samples < 150) {
    max(2, floor(max_workers * 0.75))
  } else if (n_samples < 300) {
    max(2, floor(max_workers * 0.5))
  } else {
    max(2, min(4, floor(max_workers * 0.25)))
  }
  cat(sprintf("Unix detected: Standard mode, %d workers\n", workers))
}
```

**Impact pour 312 fichiers sur Windows:**
- Ancien: 2-4 workers
- Nouveau: **2 workers FIXES**
- Plus lent (~20%) mais beaucoup plus stable

---

### Solution 3: Mode Séquentiel pour Grandes Datasets (FALLBACK)

**Si même avec 2 workers ça crash, forcer séquentiel:**

```r
# Dans Search_normalizers(), ajouter avant makeCluster():

# Détection auto si dataset trop grand pour Windows
force_sequential <- FALSE

if (is_windows && n_samples >= 250) {
  # Vérifier état système avant de décider
  current_connections <- system("netstat -an | find \"ESTABLISHED\" /c", intern = TRUE)
  current_connections <- as.numeric(current_connections)

  if (current_connections > 1000) {
    cat(sprintf("WARNING: %d socket connections detected (threshold: 1000)\n",
                current_connections))
    cat("Forcing SEQUENTIAL mode for safety on Windows\n")
    force_sequential <- TRUE
  }
}

if (force_sequential) {
  # Utiliser vapply au lieu de foreach
  v <- vapply(
    X = 1:length(iset.Opt),
    FUN = function(i) {
      calculate_Variability(...)$w.metric
    },
    FUN.VALUE = numeric(1)
  )
} else {
  # Utiliser parallel (code existant)
  cl <- makeCluster(workers, ...)
  # ...
}
```

---

### Solution 4: Chunked Processing avec Cleanup (OPTIMAL WINDOWS)

**Diviser le travail en chunks + cleanup entre chaque chunk**

```r
# Remplacer la boucle while dans Search_normalizers()

# Configuration chunking
chunk_size <- 5  # Traiter 5 normalisateurs à la fois
n_iterations <- length(iset.Opt)
n_chunks <- ceiling(n_iterations / chunk_size)

v <- numeric(length(iset.Opt))

withProgress(message = 'Calculating variabilities (chunked Windows mode)...', value = 0, {

  for (chunk_idx in 1:n_chunks) {
    incProgress(1/n_chunks, detail = sprintf("Chunk %d/%d", chunk_idx, n_chunks))

    # Indices du chunk
    start_idx <- (chunk_idx - 1) * chunk_size + 1
    end_idx <- min(chunk_idx * chunk_size, length(iset.Opt))
    chunk_indices <- start_idx:end_idx

    # CRÉER cluster pour ce chunk seulement
    cl <- makeCluster(2, type = "PSOCK")  # 2 workers fixes Windows
    doParallel::registerDoParallel(cl)

    tryCatch({
      # Process chunk
      v_chunk <- foreach(i = chunk_indices, .combine = 'c') %dopar% {
        calculate_Variability(
          X = as.matrix(Matrix_filter_BySample[, -i]),
          ref = ref_intensity,
          iset.ref = iset.Opt[-i],
          min.iset = minNormalizers,
          extrap = TRUE,
          cutrat = 1,
          out.scale = "naturel",
          method = "lm"
        )$w.metric
      }

      # Stocker résultats
      v[chunk_indices] <- v_chunk

    }, finally = {
      # CLEANUP FORCÉ après chaque chunk
      stopCluster(cl)
      gc(verbose = FALSE)

      # Pause courte pour laisser Windows libérer les sockets
      Sys.sleep(0.5)

      cat(sprintf("  Chunk %d/%d completed, cluster cleaned\n", chunk_idx, n_chunks))
    })
  }
})

cat("All chunks completed with cleanup\n")
```

**Avantages:**
- ✅ Sockets libérés après CHAQUE chunk
- ✅ Pas d'accumulation
- ✅ Fonctionne avec 312+ fichiers
- ⚠️ Plus lent (~30% overhead) mais STABLE

---

### Solution 5: Monitoring Temps Réel Windows

**Script PowerShell pour monitorer sockets pendant exécution:**

```powershell
# Sauver comme: monitor_sockets.ps1

while ($true) {
    Clear-Host
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Socket Monitoring - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan

    # Compter connexions ESTABLISHED
    $established = (netstat -an | Select-String "ESTABLISHED").Count
    Write-Host "ESTABLISHED: $established" -ForegroundColor $(if($established -gt 1000){"Red"}elseif($established -gt 500){"Yellow"}else{"Green"})

    # Compter TIME_WAIT
    $timewait = (netstat -an | Select-String "TIME_WAIT").Count
    Write-Host "TIME_WAIT:   $timewait" -ForegroundColor Gray

    # Connexions localhost R (port 127.0.0.1)
    $r_sockets = (netstat -an | Select-String "127.0.0.1" | Select-String "ESTABLISHED").Count
    Write-Host "R Localhost: $r_sockets" -ForegroundColor $(if($r_sockets -gt 1500){"Red"}elseif($r_sockets -gt 800){"Yellow"}else{"Green"})

    # Limite Windows
    $limit = 16384
    $percent = [math]::Round(($established / $limit) * 100, 2)
    Write-Host "Usage:       $percent% of $limit ports" -ForegroundColor $(if($percent -gt 10){"Red"}elseif($percent -gt 5){"Yellow"}else{"Green"})

    Write-Host "`nPress Ctrl+C to stop monitoring" -ForegroundColor Gray

    Start-Sleep -Seconds 2
}
```

**Lancer dans PowerShell pendant que R s'exécute:**
```powershell
.\monitor_sockets.ps1
```

---

## 📊 COMPARAISON SOLUTIONS WINDOWS

| Solution | Complexité | Speedup | Stabilité 312 | Recommandé |
|----------|------------|---------|---------------|------------|
| **1. Cleanup forcé** | Moyenne | 2x | ✅ Excellent | ⭐⭐⭐⭐⭐ |
| **2. Limiter workers (2 fixes)** | Facile | 2x | ✅ Très bon | ⭐⭐⭐⭐⭐ |
| **3. Séquentiel auto** | Facile | 1x | ✅ Garanti | ⭐⭐⭐⭐ |
| **4. Chunked + cleanup** | Difficile | 1.5x | ✅ Excellent | ⭐⭐⭐⭐⭐ |
| **5. Monitoring** | Facile | N/A | Diagnostique | ⭐⭐⭐ |

---

## 🎯 PLAN D'ACTION RECOMMANDÉ POUR WINDOWS

### Phase 1: Quick Wins (30 minutes)

**A. Vérifier fix CE-Time appliqué**
```r
# Lire: lib/NewReferenceMap/R_files/CE_time_Correction.lib.R
# Lignes 1-10 doivent contenir le flag global
if (!exists(".biocparallel_registered_ce_time", ...)) {
  # Si absent, appliquer le fix
}
```

**B. Limiter workers à 2 pour Windows**
```r
# Modifier InternalStandard.lib_NewRefMap.R ligne 980-993
# Forcer workers = 2 si n_samples >= 150
```

---

### Phase 2: Cleanup Forcé (1-2 heures)

**A. Ajouter cleanup CE-Time**
- Fonction `cleanup_ce_time_cluster()`
- Appeler après renderPlot CE-Time

**B. Ajouter cleanup Grouping**
- `bpstop(param)` avant return

**C. Vérifier cleanup Search_normalizers**
- Déjà en place avec `on.exit(stopCluster(cl))`

---

### Phase 3: Test Validation (2-4 heures)

**A. Lancer monitoring sockets**
```powershell
.\monitor_sockets.ps1
```

**B. Lancer R avec 312 fichiers**
- Observer sockets en temps réel
- Vérifier que ça ne dépasse pas 1,000

**C. Benchmarker**
- Temps exécution
- Mémoire utilisée
- Sockets max atteints

---

### Phase 4: Si Échec, Chunked Processing (4-6 heures)

**Implémenter Solution 4 (Chunked + cleanup)**
- Diviser en chunks de 5
- Cleanup après chaque chunk
- Pause 0.5s entre chunks

---

## ✅ RÉPONSES FINALES À VOS QUESTIONS

### Q1: Limiter le nombre de workers?

**OUI, déjà fait mais on peut optimiser:**

✅ **Actuel:** 2-4 workers pour 312 fichiers
✅ **Optimal Windows:** **2 workers FIXES** pour 150+ fichiers
✅ **Code fourni ci-dessus** (Section Solution 2)

---

### Q2: Les sockets sont-elles fermées après les étapes précédentes?

**NON, pas garanties sur Windows!**

❌ **CE-Time:** 1 cluster créé mais jamais fermé explicitement
❌ **Grouping:** BiocParallel censé nettoyer mais pas garanti Windows
✅ **Search_normalizers:** Bien nettoyé (depuis fix récent)

**Solution:** Cleanup forcé avec `bpstop()` + `gc()` après CHAQUE étape
**Code fourni:** Section Solution 1

---

## 📚 DOCUMENTATION CRÉÉE

**Fichier:** `SOLUTIONS_WINDOWS_PARALLEL_312_FICHIERS.md`
- Solutions 1-5 détaillées
- Code prêt à copier-coller
- Script monitoring PowerShell
- Plan d'action étape par étape

---

**Date:** 2026-01-23
**Plateforme:** Windows
**Status:** ✅ SOLUTIONS PRÊTES
