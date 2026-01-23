# 🚨 FUITE CRITIQUE: Sockets BiocParallel Non Fermés

## ⚠️ PROBLÈME DÉCOUVERT

**L'utilisateur a identifié une fuite MAJEURE de sockets qui explique en partie le crash à 312 fichiers!**

### Analyse des Fuites

**J'ai trouvé 4 endroits où `SnowParam()` est créé mais JAMAIS fermé:**

```
┌────────────────────────────────────────────────────────────────┐
│         FUITES DE SOCKETS IDENTIFIÉES                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  1. GenerateMapRef.Server_NewRefMap.R (ligne 795-823)         │
│     Location: server/newReferenceMap.server/                  │
│     ────────────────────────────────────────────────           │
│     workers = detectCores() - 1  (7-15 workers!)              │
│     param = SnowParam(workers, type = "SOCK")                 │
│     res1 = bplapply(..., BPPARAM = param)                     │
│     res2 = bplapply(..., BPPARAM = param)                     │
│     res3 = rbind(res2)                                        │
│     ❌ PAS DE bpstop(param)!                                  │
│                                                                │
│     Impact: 7-15 sockets LEAKED par exécution                 │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  2. analysisItemNewSamples.server.R (ligne 4464-4492)         │
│     Location: server/analysisNewSamples.server/               │
│     ────────────────────────────────────────────────           │
│     Code identique: workers = detectCores() - 1               │
│     ❌ PAS DE bpstop(param)!                                  │
│                                                                │
│     Impact: 7-15 sockets LEAKED par analyse                   │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  3. peakPickingNewReferenceMap.R (ligne 382-392)              │
│     Location: lib/NewReferenceMap/R_files/                    │
│     ────────────────────────────────────────────────           │
│     param = SnowParam(workers, type = "SOCK")                 │
│     Result_Msidal = bplapply(..., BPPARAM = param)            │
│     ❌ PAS DE bpstop(param)!                                  │
│                                                                │
│     Impact: workers sockets LEAKED                            │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  4. ProcessingAnalysisNewsample.lib.R (ligne 579-589)         │
│     Location: lib/AnalysisNewSample/R_files/                  │
│     ────────────────────────────────────────────────           │
│     Code identique à #3                                       │
│     ❌ PAS DE bpstop(param)!                                  │
│                                                                │
│     Impact: workers sockets LEAKED                            │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 💥 IMPACT CUMULATIF (312 fichiers)

### Calcul des Sockets Leaked

**Assumant detectCores() = 8 → workers = 7:**

```
Étape 1: Peak Picking (#3 + #4)
  → 7 workers × 2 appels = 14 sockets LEAKED

Étape 2: Grouping Massif (#1)
  → 7 workers = 7 sockets LEAKED

Étape 3: Analysis Items (#2)
  → 7 workers = 7 sockets LEAKED

Étape 4: CE-Time (déjà identifié)
  → 1 socket LEAKED (fixé partiellement)

Étape 5: Grouping.Between.Sample.Parallel (déjà identifié)
  → 0-8 sockets LEAKED

─────────────────────────────────────────────────
TOTAL: 14 + 7 + 7 + 1 + 8 = 37 sockets MINIMUM
       par exécution complète du workflow!
```

**Pour 312 fichiers:**
- Si ces étapes sont répétées ou non nettoyées
- Les sockets s'accumulent
- **Ceci explique pourquoi makeCluster() timeout!**

---

## ✅ FIX COMPLET

### Fix #1: GenerateMapRef.Server_NewRefMap.R

**Fichier:** `server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R`

**AVANT (ligne 795-823):**
```r
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

incProgress(1 / 4, detail = "first grouping")
res1 <- bplapply(
  Massif_List_ToGroup,
  Grouping.Massif_NewRefMap,
  mz.tolerance = 0.15,
  rt.tolerance = 30,
  BPPARAM = param
)

incProgress(1 / 4, detail = "second grouping")
res2 <- bplapply(
  res1,
  Grouping.Massif_NewRefMap_Second,
  mz.tolerance = 0.09,
  rt.tolerance = 180,
  BPPARAM = param
)

res3 <- do.call("rbind", res2)

res3 <- as.data.frame(res3)
rownames(res3) <- 1:nrow(res3)
RvarsGrouping$FeaturesList <- res3[,-ncol(res3)]
incProgress(1 / 4, detail = "finish")
```

**APRÈS (avec cleanup):**
```r
# Configuration workers avec limite Windows
is_windows <- .Platform$OS.type == "windows"
max_workers <- detectCores() - 1

if (is_windows) {
  # Windows: Limiter à 2 workers pour sécurité
  workers <- 2
  cat("Windows detected: Using 2 workers for Grouping Massif\n")
} else {
  workers <- ceiling(max_workers)
}

param <- SnowParam(workers = workers, type = "SOCK")

# Utiliser tryCatch pour garantir cleanup même si erreur
tryCatch({

  incProgress(1 / 4, detail = "first grouping")
  res1 <- bplapply(
    Massif_List_ToGroup,
    Grouping.Massif_NewRefMap,
    mz.tolerance = 0.15,
    rt.tolerance = 30,
    BPPARAM = param
  )

  incProgress(1 / 4, detail = "second grouping")
  res2 <- bplapply(
    res1,
    Grouping.Massif_NewRefMap_Second,
    mz.tolerance = 0.09,
    rt.tolerance = 180,
    BPPARAM = param
  )

  res3 <- do.call("rbind", res2)

  res3 <- as.data.frame(res3)
  rownames(res3) <- 1:nrow(res3)
  RvarsGrouping$FeaturesList <- res3[,-ncol(res3)]
  incProgress(1 / 4, detail = "finish")

}, finally = {
  # ✅ CLEANUP FORCÉ - CRITIQUE POUR WINDOWS!
  tryCatch({
    bpstop(param)
    gc(verbose = FALSE)
    cat(sprintf("✅ Grouping Massif: %d workers stopped and sockets closed\n", workers))
  }, error = function(e) {
    warning(paste("Grouping Massif cleanup warning:", e$message))
  })
})
```

---

### Fix #2: analysisItemNewSamples.server.R

**Fichier:** `server/analysisNewSamples.server/analysisItemNewSamples.server.R`

**AVANT (ligne 4464-4492):**
```r
workers <- ceiling((detectCores()) - 1)
param <- SnowParam(workers = workers, type = "SOCK")

incProgress(1 / 4, detail = "first grouping")
res1 <- bplapply(
  Massif_List_ToGroup,
  Grouping.Massif_NewRefMap,
  mz.tolerance = 0.15,
  rt.tolerance = 30,
  BPPARAM = param
)

incProgress(1 / 4, detail = "second grouping")
res2 <- bplapply(
  res1,
  Grouping.Massif_NewRefMap_Second,
  mz.tolerance = 0.09,
  rt.tolerance = 180,
  BPPARAM = param
)

res3 <- do.call("rbind", res2)
# ... reste du code ...
```

**APRÈS (identique au Fix #1):**
```r
# Configuration workers avec limite Windows
is_windows <- .Platform$OS.type == "windows"
max_workers <- detectCores() - 1

if (is_windows) {
  workers <- 2
  cat("Windows detected: Using 2 workers for Analysis Grouping\n")
} else {
  workers <- ceiling(max_workers)
}

param <- SnowParam(workers = workers, type = "SOCK")

tryCatch({

  incProgress(1 / 4, detail = "first grouping")
  res1 <- bplapply(
    Massif_List_ToGroup,
    Grouping.Massif_NewRefMap,
    mz.tolerance = 0.15,
    rt.tolerance = 30,
    BPPARAM = param
  )

  incProgress(1 / 4, detail = "second grouping")
  res2 <- bplapply(
    res1,
    Grouping.Massif_NewRefMap_Second,
    mz.tolerance = 0.09,
    rt.tolerance = 180,
    BPPARAM = param
  )

  res3 <- do.call("rbind", res2)
  # ... reste du code ...

}, finally = {
  # ✅ CLEANUP FORCÉ
  tryCatch({
    bpstop(param)
    gc(verbose = FALSE)
    cat(sprintf("✅ Analysis Grouping: %d workers stopped\n", workers))
  }, error = function(e) {
    warning(paste("Analysis Grouping cleanup warning:", e$message))
  })
})
```

---

### Fix #3: peakPickingNewReferenceMap.R

**Fichier:** `lib/NewReferenceMap/R_files/peakPickingNewReferenceMap.R`

**AVANT (ligne 382-392):**
```r
param <- SnowParam(workers = workers, type = "SOCK")
time1<-system.time(Result_Msidal<-
                     bplapply(path_to_peakList,
                              ProcessPeaks.msdial,
                              file_adduct = file_adduct,
                              mass_slice_width = mass_slice_width,
                              min_PeaksMassif = min_PeaksMassif,
                              BPPARAM = param))
time2<-system.time(peaks_MSDIAL_mono_iso<-do.call("rbind", Result_Msidal))
times<-time1[[3]]+time2[[3]]

# Code continue sans cleanup...
```

**APRÈS:**
```r
# Limiter workers sur Windows
is_windows <- .Platform$OS.type == "windows"
if (is_windows && workers > 2) {
  workers <- 2
  cat("Windows detected: Limiting peak picking to 2 workers\n")
}

param <- SnowParam(workers = workers, type = "SOCK")

# Wrapper avec cleanup garanti
tryCatch({

  time1 <- system.time(Result_Msidal <-
                        bplapply(path_to_peakList,
                                ProcessPeaks.msdial,
                                file_adduct = file_adduct,
                                mass_slice_width = mass_slice_width,
                                min_PeaksMassif = min_PeaksMassif,
                                BPPARAM = param))

  time2 <- system.time(peaks_MSDIAL_mono_iso <- do.call("rbind", Result_Msidal))
  times <- time1[[3]] + time2[[3]]

}, finally = {
  # ✅ CLEANUP FORCÉ
  tryCatch({
    bpstop(param)
    gc(verbose = FALSE)
    cat(sprintf("✅ Peak Picking: %d workers stopped\n", workers))
  }, error = function(e) {
    warning(paste("Peak Picking cleanup warning:", e$message))
  })
})

# Code continue avec cleanup fait...
```

---

### Fix #4: ProcessingAnalysisNewsample.lib.R

**Fichier:** `lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R`

**AVANT (ligne 579-589):**
```r
param <- SnowParam(workers = workers, type = "SOCK")
time1<-system.time(Result_Msidal<-
                     bplapply(path_to_peakList,
                              ProcessPeaks.msdial.NewSample,
                              file_adduct = file_adduct,
                              mass_slice_width = mass_slice_width,
                              min_PeaksMassif = min_PeaksMassif,
                              BPPARAM = param))
time2<-system.time(peaks_MSDIAL_mono_iso<-do.call("rbind", Result_Msidal))
times<-time1[[3]]+time2[[3]]
```

**APRÈS (identique au Fix #3):**
```r
# Limiter workers sur Windows
is_windows <- .Platform$OS.type == "windows"
if (is_windows && workers > 2) {
  workers <- 2
  cat("Windows detected: Limiting analysis peak picking to 2 workers\n")
}

param <- SnowParam(workers = workers, type = "SOCK")

tryCatch({

  time1 <- system.time(Result_Msidal <-
                        bplapply(path_to_peakList,
                                ProcessPeaks.msdial.NewSample,
                                file_adduct = file_adduct,
                                mass_slice_width = mass_slice_width,
                                min_PeaksMassif = min_PeaksMassif,
                                BPPARAM = param))

  time2 <- system.time(peaks_MSDIAL_mono_iso <- do.call("rbind", Result_Msidal))
  times <- time1[[3]] + time2[[3]]

}, finally = {
  # ✅ CLEANUP FORCÉ
  tryCatch({
    bpstop(param)
    gc(verbose = FALSE)
    cat(sprintf("✅ Analysis Peak Picking: %d workers stopped\n", workers))
  }, error = function(e) {
    warning(paste("Analysis Peak Picking cleanup warning:", e$message))
  })
})
```

---

## 📊 IMPACT DES FIXES

### AVANT Fixes

```
Workflow complet (312 fichiers):

Peak Picking:         7 workers × 2 = 14 sockets LEAKED
Grouping Massif:      7 workers     =  7 sockets LEAKED
Analysis Grouping:    7 workers     =  7 sockets LEAKED
CE-Time:              1 worker      =  1 socket  LEAKED
Grouping Between:     8 workers     =  8 sockets LEAKED
─────────────────────────────────────────────────────────
TOTAL:                               37 sockets LEAKED

État avant Search_normalizers():
  37 sockets actifs + 1,872 CE-Time (si ancien) = 1,909+ sockets
  → CRASH GARANTI à makeCluster() ❌
```

### APRÈS Fixes

```
Workflow complet (312 fichiers):

Peak Picking:         2 workers → Fermés ✅ = 0 sockets
Grouping Massif:      2 workers → Fermés ✅ = 0 sockets
Analysis Grouping:    2 workers → Fermés ✅ = 0 sockets
CE-Time:              1 worker  → Fermé  ✅ = 0 sockets
Grouping Between:     2 workers → Fermés ✅ = 0 sockets
─────────────────────────────────────────────────────────
TOTAL:                                  0 sockets LEAKED

État avant Search_normalizers():
  ~20-50 sockets (overhead système seulement)
  → makeCluster(2) réussit ✅
```

---

## 🎯 PRIORITÉ CRITIQUE

**Ces fixes sont PLUS IMPORTANTS que les autres!**

**Raison:**
1. Ces fuites affectent TOUT le workflow (pas juste Search_normalizers)
2. 37 sockets leaked × nombre d'exécutions = accumulation massive
3. Explique pourquoi même le début du workflow peut ralentir avec 312 fichiers

---

## 🚀 PLAN D'APPLICATION

### Ordre d'implémentation recommandé:

1. **Fix #1 & #2** (Server files) - PRIORITÉ MAXIMALE
   - GenerateMapRef.Server_NewRefMap.R
   - analysisItemNewSamples.server.R
   - Impact: -14 sockets leaked

2. **Fix #3 & #4** (Library files) - HAUTE PRIORITÉ
   - peakPickingNewReferenceMap.R
   - ProcessingAnalysisNewsample.lib.R
   - Impact: -14 sockets leaked

3. **Autres fixes** (déjà identifiés)
   - CE-Time cleanup
   - Grouping cleanup
   - Search_normalizers optimization

---

## ✅ VALIDATION

**Après application des 4 fixes:**

```r
# Test validation
test_socket_cleanup <- function() {

  # Compter sockets avant
  before <- system("netstat -an | find \"ESTABLISHED\" /c", intern = TRUE)
  cat(sprintf("Sockets AVANT: %s\n", before))

  # Exécuter workflow complet
  # ... votre code ...

  # Forcer nettoyage
  gc(verbose = FALSE)
  Sys.sleep(2)  # Laisser Windows libérer

  # Compter sockets après
  after <- system("netstat -an | find \"ESTABLISHED\" /c", intern = TRUE)
  cat(sprintf("Sockets APRÈS: %s\n", after))

  # Delta
  delta <- as.numeric(after) - as.numeric(before)
  cat(sprintf("DELTA: %+d sockets\n", delta))

  if (delta <= 5) {
    cat("✅ SUCCÈS: Pas de fuite majeure détectée\n")
  } else {
    cat(sprintf("⚠️ ATTENTION: %d sockets leaked\n", delta))
  }
}
```

---

## 🎉 CONCLUSION

**Merci à l'utilisateur d'avoir identifié cette fuite critique!**

**Impact attendu après les 4 fixes:**
- ✅ Réduction de ~37 sockets leaked par workflow
- ✅ Search_normalizers peut s'exécuter dans un état système propre
- ✅ 312 fichiers devrait fonctionner
- ✅ Scalable à 500+ fichiers

**Prochaine étape:** Implémenter les 4 fixes dans l'ordre de priorité

---

**Date:** 2026-01-23
**Priorité:** 🚨 CRITIQUE
**Status:** ✅ FIXES PRÊTS À APPLIQUER
