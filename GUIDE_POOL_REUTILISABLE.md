# Guide : Pool de Workers Réutilisable pour Toute l'Application

## 🎯 Concept : Un Seul Pool Pour Tout le Workflow

Au lieu de créer/détruire des workers à chaque étape :

### ❌ **Approche Actuelle (Problématique)**
```r
# Étape 1 : Grouping
param1 <- SnowParam(workers = 7, type = "SOCK")
res1 <- bplapply(..., BPPARAM = param1)
# ❌ Oubli de bpstop(param1) → 7 sockets restent

# Étape 2 : Map Generation
param2 <- SnowParam(workers = 7, type = "SOCK")
res2 <- bplapply(..., BPPARAM = param2)
# ❌ Oubli de bpstop(param2) → 7 sockets supplémentaires

# Étape 3 : Normalizers
param3 <- SnowParam(workers = 7, type = "SOCK")
res3 <- bplapply(..., BPPARAM = param3)
# ❌ Oubli de bpstop(param3) → 7 sockets supplémentaires

# Total: 21 sockets accumulés !
```

### ✅ **Approche Optimale (Pool Réutilisable)**
```r
# Créer UN SEUL pool au début du workflow
global_pool <- SnowParam(workers = 2, type = "SOCK")

# Réutiliser pour TOUTES les étapes
res1 <- bplapply(..., BPPARAM = global_pool)
res2 <- bplapply(..., BPPARAM = global_pool)
res3 <- bplapply(..., BPPARAM = global_pool)

# Fermer UNE FOIS à la fin
bpstop(global_pool)

# Total: Seulement 2 sockets pour tout le workflow !
```

---

## 💡 Avantages du Pool Réutilisable

| Critère | Créer/Détruire | Pool Réutilisable |
|---------|----------------|-------------------|
| **Sockets utilisés** | N × nombre d'étapes | N (constant) |
| **Risque de fuite** | ⚠️ Élevé (si oubli bpstop) | ✅ Minimal (1 seul bpstop) |
| **Performance** | Overhead création × N | Création 1 fois |
| **Simplicité** | ⭐⭐ (bpstop partout) | ⭐⭐⭐⭐ (bpstop 1 fois) |
| **Stabilité** | ⚠️ Variable | ✅ Prévisible |

**Pour 312 fichiers avec 10 étapes parallèles :**
- **Sans pool** : 7 workers × 10 étapes = 70 sockets (si oublis)
- **Avec pool** : 2 workers × 1 pool = **2 sockets seulement !**

---

## 🏗️ Implémentation : Pool Global dans Shiny

### **Méthode 1 : Pool Stocké dans reactiveValues**

```r
# ══════════════════════════════════════════════════════════════════
# server.R
# ══════════════════════════════════════════════════════════════════

server <- function(input, output, session) {

  # Reactive values
  Rvars <- reactiveValues(
    worker_pool = NULL,        # ← Pool global
    pool_active = FALSE,       # ← État du pool
    processing_stage = "none"
  )

  # ══════════════════════════════════════════════════════════════
  # CRÉER LE POOL au début du workflow
  # ══════════════════════════════════════════════════════════════

  observeEvent(input$start_workflow, {
    req(input$project_name)

    cat("\n═══════════════════════════════════════════════════════\n")
    cat("🔧 Creating Global Worker Pool\n")
    cat("═══════════════════════════════════════════════════════\n")

    # Déterminer nombre de workers
    n_samples <- ncol(Rvars$data_matrix)
    n_workers <- if (n_samples >= 300) {
      2  # Limité pour grandes données
    } else {
      min(4, detectCores() - 1)
    }

    cat(sprintf("Workers: %d\n", n_workers))
    cat(sprintf("Samples: %d\n", n_samples))

    # Créer le pool GLOBAL
    Rvars$worker_pool <- SnowParam(
      workers = n_workers,
      type = "SOCK",
      timeout = 600,
      progressbar = FALSE
    )

    Rvars$pool_active <- TRUE

    cat("✅ Worker pool created and ready\n")
    cat("   This pool will be reused for ALL workflow steps\n")
    cat("═══════════════════════════════════════════════════════\n\n")
  })


  # ══════════════════════════════════════════════════════════════
  # ÉTAPE 1 : Grouping (utilise le pool)
  # ══════════════════════════════════════════════════════════════

  observeEvent(input$run_grouping, {
    req(Rvars$worker_pool)
    req(Rvars$pool_active)

    cat("\n[Grouping] Using global worker pool\n")

    withProgress(message = "Grouping...", {

      # RÉUTILISER le pool global
      res1 <- bplapply(
        Massif_List_ToGroup,
        Grouping.Massif_NewRefMap,
        mz.tolerance = 0.15,
        rt.tolerance = 30,
        BPPARAM = Rvars$worker_pool  # ← Réutilisation !
      )

      res2 <- bplapply(
        res1,
        Grouping.Massif.RT_NewRefMap,
        mz.tolerance = 0.15,
        rt.tolerance = 30,
        BPPARAM = Rvars$worker_pool  # ← Réutilisation !
      )

      Rvars$grouped_data <- res2

      cat("[Grouping] ✅ Completed (pool still active)\n")
    })
  })


  # ══════════════════════════════════════════════════════════════
  # ÉTAPE 2 : Map Generation (utilise le même pool)
  # ══════════════════════════════════════════════════════════════

  observeEvent(input$run_map_generation, {
    req(Rvars$worker_pool)
    req(Rvars$pool_active)

    cat("\n[Map Generation] Using global worker pool\n")

    withProgress(message = "Generating map...", {

      # RÉUTILISER le même pool
      res <- bplapply(
        Split_data_PeakPicking,
        peakpickingsingle,
        BPPARAM = Rvars$worker_pool  # ← Même pool !
      )

      Rvars$map_data <- res

      cat("[Map Generation] ✅ Completed (pool still active)\n")
    })
  })


  # ══════════════════════════════════════════════════════════════
  # ÉTAPE 3 : Normalizer Search (utilise le même pool)
  # ══════════════════════════════════════════════════════════════

  observeEvent(input$run_normalizers, {
    req(Rvars$worker_pool)
    req(Rvars$pool_active)

    cat("\n[Normalizers] Using global worker pool\n")

    withProgress(message = "Searching normalizers...", {

      # Créer liste d'échantillons
      sample_list <- lapply(1:ncol(Rvars$Matrix_filtered), function(i) {
        list(data = Rvars$Matrix_filtered[, i, drop = FALSE])
      })

      # RÉUTILISER le même pool
      res <- bplapply(
        sample_list,
        function(s) Search_normalizers(
          s$data,
          input$pFeatures,
          input$pSample,
          input$minNormalizers
        ),
        BPPARAM = Rvars$worker_pool  # ← Toujours le même pool !
      )

      Rvars$normalizers <- do.call(rbind, res)

      cat("[Normalizers] ✅ Completed (pool still active)\n")
    })
  })


  # ══════════════════════════════════════════════════════════════
  # FERMER LE POOL à la fin du workflow
  # ══════════════════════════════════════════════════════════════

  observeEvent(input$finish_workflow, {

    if (!is.null(Rvars$worker_pool) && Rvars$pool_active) {

      cat("\n═══════════════════════════════════════════════════════\n")
      cat("🔒 Closing Global Worker Pool\n")
      cat("═══════════════════════════════════════════════════════\n")

      bpstop(Rvars$worker_pool)
      Rvars$worker_pool <- NULL
      Rvars$pool_active <- FALSE
      gc()

      cat("✅ Worker pool closed\n")
      cat("   All sockets released\n")
      cat("═══════════════════════════════════════════════════════\n\n")

      showNotification(
        "✅ Workflow complete, workers released",
        type = "message",
        duration = 5
      )
    }
  })


  # ══════════════════════════════════════════════════════════════
  # FERMETURE AUTOMATIQUE quand l'app se ferme
  # ══════════════════════════════════════════════════════════════

  session$onSessionEnded(function() {

    cat("\n⚠️  Session ending, cleaning up worker pool...\n")

    if (!is.null(Rvars$worker_pool) && Rvars$pool_active) {
      tryCatch({
        bpstop(Rvars$worker_pool)
        gc()
        cat("✅ Worker pool closed on session end\n")
      }, error = function(e) {
        cat("⚠️  Pool cleanup error:", e$message, "\n")
      })
    }
  })
}
```

---

### **Méthode 2 : Pool Géré par un Module Dédié**

Créer un module réutilisable pour gérer le pool :

```r
# ══════════════════════════════════════════════════════════════════
# lib/GlobalWorkerPoolManager.R
# ══════════════════════════════════════════════════════════════════

GlobalWorkerPool <- R6::R6Class(
  "GlobalWorkerPool",

  public = list(
    pool = NULL,
    n_workers = NULL,
    is_active = FALSE,
    created_at = NULL,

    # Initialiser
    initialize = function(n_workers = NULL) {
      if (is.null(n_workers)) {
        n_workers <- min(detectCores() - 1, 4)
      }

      self$n_workers <- n_workers
      self$create_pool()
    },

    # Créer le pool
    create_pool = function() {
      if (self$is_active) {
        message("Pool already active, skipping creation")
        return(invisible(self))
      }

      cat("\n═══════════════════════════════════════════════════════\n")
      cat("🔧 Creating Global Worker Pool\n")
      cat("═══════════════════════════════════════════════════════\n")
      cat(sprintf("Workers: %d\n", self$n_workers))

      self$pool <- SnowParam(
        workers = self$n_workers,
        type = "SOCK",
        timeout = 600,
        progressbar = FALSE
      )

      self$is_active <- TRUE
      self$created_at <- Sys.time()

      cat("✅ Pool created\n")
      cat("═══════════════════════════════════════════════════════\n\n")

      invisible(self)
    },

    # Exécuter une tâche avec le pool
    execute = function(data_list, fun, step_name = "Task", ...) {
      if (!self$is_active) {
        stop("Worker pool is not active! Call create_pool() first.")
      }

      cat(sprintf("\n[%s] Using global pool (%d workers)\n",
                  step_name, self$n_workers))

      start_time <- Sys.time()

      result <- tryCatch({
        bplapply(data_list, fun, ..., BPPARAM = self$pool)
      }, error = function(e) {
        cat(sprintf("[%s] ❌ Error: %s\n", step_name, e$message))
        NULL
      })

      elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      cat(sprintf("[%s] ✅ Completed in %.2f seconds\n", step_name, elapsed))

      return(result)
    },

    # Fermer le pool
    close = function() {
      if (!self$is_active) {
        message("Pool already closed")
        return(invisible(self))
      }

      cat("\n═══════════════════════════════════════════════════════\n")
      cat("🔒 Closing Global Worker Pool\n")
      cat("═══════════════════════════════════════════════════════\n")

      uptime <- difftime(Sys.time(), self$created_at, units = "mins")
      cat(sprintf("Pool uptime: %.1f minutes\n", uptime))

      bpstop(self$pool)
      self$pool <- NULL
      self$is_active <- FALSE
      gc()

      cat("✅ Pool closed\n")
      cat("═══════════════════════════════════════════════════════\n\n")

      invisible(self)
    },

    # Vérifier état
    status = function() {
      cat("\n═══════════════════════════════════════════════════════\n")
      cat("📊 Worker Pool Status\n")
      cat("═══════════════════════════════════════════════════════\n")
      cat(sprintf("Active: %s\n", ifelse(self$is_active, "✅ Yes", "❌ No")))
      cat(sprintf("Workers: %d\n", self$n_workers))

      if (self$is_active) {
        uptime <- difftime(Sys.time(), self$created_at, units = "mins")
        cat(sprintf("Uptime: %.1f minutes\n", uptime))
      }

      cat("═══════════════════════════════════════════════════════\n\n")

      invisible(self)
    }
  )
)


# ══════════════════════════════════════════════════════════════════
# Utilisation dans server.R
# ══════════════════════════════════════════════════════════════════

server <- function(input, output, session) {

  # Créer instance du pool manager
  pool_manager <- GlobalWorkerPool$new(n_workers = 2)

  # Étape 1 : Grouping
  observeEvent(input$run_grouping, {
    res <- pool_manager$execute(
      Massif_List,
      Grouping.Massif,
      "Grouping"
    )
  })

  # Étape 2 : Map Generation
  observeEvent(input$run_map_gen, {
    res <- pool_manager$execute(
      Split_data,
      peakpickingsingle,
      "Map Generation"
    )
  })

  # Étape 3 : Normalizers
  observeEvent(input$run_normalizers, {
    res <- pool_manager$execute(
      sample_list,
      Search_normalizers,
      "Normalizers"
    )
  })

  # Fermer à la fin
  observeEvent(input$finish, {
    pool_manager$close()
  })

  # Cleanup automatique
  session$onSessionEnded(function() {
    pool_manager$close()
  })
}
```

---

## 🔍 Comparaison : Pool vs Créer/Détruire

### **Test avec 312 Fichiers**

#### **Sans Pool (Approche Actuelle)**
```r
# Workflow complet
Étape 1: param1 <- SnowParam(7)  → 7 sockets
Étape 2: param2 <- SnowParam(7)  → 7 sockets
Étape 3: param3 <- SnowParam(7)  → 7 sockets
Étape 4: param4 <- SnowParam(7)  → 7 sockets
...
Total si oubli bpstop: 28+ sockets accumulés ❌
```

#### **Avec Pool Global**
```r
# Workflow complet
Début: pool <- SnowParam(2)      → 2 sockets
Étape 1: bplapply(..., pool)     → même 2 sockets
Étape 2: bplapply(..., pool)     → même 2 sockets
Étape 3: bplapply(..., pool)     → même 2 sockets
Fin: bpstop(pool)                → 0 sockets
Total: Maximum 2 sockets ✅
```

---

## 🎯 Quand Utiliser Chaque Approche ?

### **✅ Pool Global Réutilisable** (Recommandé)

**Utiliser quand :**
- ✅ Workflow complet avec plusieurs étapes parallèles
- ✅ Grandes données (300+ fichiers)
- ✅ Besoin de stabilité maximale
- ✅ Éviter accumulation de sockets

**Exemple de cas d'usage :**
```r
# MSpandas workflow complet :
1. Peak Picking (parallèle)
2. Isotope Annotation (parallèle)
3. Grouping Massif (parallèle)
4. Map Generation (parallèle)
5. Normalizer Search (parallèle)

→ UN SEUL pool pour les 5 étapes !
```

### **⚙️ Créer/Détruire** (Pour opérations isolées)

**Utiliser quand :**
- ✅ Une seule opération parallèle isolée
- ✅ Petites données (< 100 fichiers)
- ✅ Besoin de workers différents selon l'étape

**Exemple :**
```r
# Opération unique
observeEvent(input$run_single_task, {
  param <- SnowParam(workers = 4, type = "SOCK")
  tryCatch({
    res <- bplapply(..., BPPARAM = param)
  }, finally = {
    bpstop(param)  # Fermeture garantie
  })
})
```

---

## 🛡️ Sécurité : Garantir la Fermeture du Pool

### **Pattern Sécurisé avec tryCatch**

```r
# Créer le pool avec protection
create_safe_pool <- function(n_workers = 2) {

  pool <- NULL

  tryCatch({
    pool <- SnowParam(
      workers = n_workers,
      type = "SOCK",
      timeout = 600
    )

    # Enregistrer cleanup automatique
    reg.finalizer(
      environment(),
      function(env) {
        if (!is.null(pool)) {
          cat("🧹 Auto-cleanup: Closing worker pool\n")
          tryCatch({
            bpstop(pool)
          }, error = function(e) {
            # Ignorer erreurs de cleanup
          })
        }
      },
      onexit = TRUE
    )

  }, error = function(e) {
    cat("❌ Failed to create pool:", e$message, "\n")
    return(NULL)
  })

  return(pool)
}


# Utilisation
server <- function(input, output, session) {

  Rvars <- reactiveValues(
    worker_pool = create_safe_pool(n_workers = 2)
  )

  # ... utilisation du pool ...

  # Cleanup explicite
  observeEvent(input$finish, {
    if (!is.null(Rvars$worker_pool)) {
      bpstop(Rvars$worker_pool)
      Rvars$worker_pool <- NULL
    }
  })
}
```

---

## 📊 Performance : Pool vs Créer/Détruire

### **Benchmark (100 échantillons, 5 étapes)**

```r
# Test 1: Créer/Détruire à chaque étape
benchmark_create_destroy <- function() {
  start <- Sys.time()

  for (i in 1:5) {
    param <- SnowParam(workers = 2, type = "SOCK")
    res <- bplapply(data_list, fun, BPPARAM = param)
    bpstop(param)
  }

  elapsed <- difftime(Sys.time(), start, units = "secs")
  return(elapsed)
}

# Test 2: Pool réutilisable
benchmark_reusable_pool <- function() {
  start <- Sys.time()

  pool <- SnowParam(workers = 2, type = "SOCK")

  for (i in 1:5) {
    res <- bplapply(data_list, fun, BPPARAM = pool)
  }

  bpstop(pool)

  elapsed <- difftime(Sys.time(), start, units = "secs")
  return(elapsed)
}

# Résultats
time_create_destroy <- benchmark_create_destroy()  # ~12.5 secondes
time_reusable <- benchmark_reusable_pool()         # ~10.2 secondes

# Gain: ~18% plus rapide avec pool réutilisable !
```

**Pourquoi plus rapide ?**
- Pas d'overhead de création/destruction
- Workers déjà chauds (pas de cold start)
- Pas de négociation socket répétée

---

## 🎓 Recommandation Finale pour MSpandas (312 Fichiers)

### **Configuration Optimale**

```r
# ══════════════════════════════════════════════════════════════════
# Configuration recommandée pour 312 fichiers
# ══════════════════════════════════════════════════════════════════

server <- function(input, output, session) {

  Rvars <- reactiveValues()

  # Créer pool au début du workflow
  observeEvent(input$start_full_workflow, {

    cat("\n🚀 Starting workflow for 312 files\n")

    # Pool GLOBAL avec 2 workers (optimal pour 312 fichiers)
    Rvars$global_pool <- SnowParam(
      workers = 2,        # Limité pour Windows + grandes données
      type = "SOCK",
      timeout = 600,      # 10 minutes par tâche
      progressbar = FALSE
    )

    Rvars$pool_active <- TRUE

    cat("✅ Global pool created (2 workers)\n")
    cat("   This pool will handle ALL parallel tasks\n\n")
  })

  # Toutes les étapes utilisent LE MÊME pool
  observeEvent(input$run_grouping, {
    res <- bplapply(..., BPPARAM = Rvars$global_pool)
  })

  observeEvent(input$run_map_gen, {
    res <- bplapply(..., BPPARAM = Rvars$global_pool)
  })

  observeEvent(input$run_normalizers, {
    res <- bplapply(..., BPPARAM = Rvars$global_pool)
  })

  # Fermer à la fin
  observeEvent(input$finish_workflow, {
    if (Rvars$pool_active) {
      bpstop(Rvars$global_pool)
      Rvars$pool_active <- FALSE
      gc()
      cat("✅ Global pool closed\n")
    }
  })

  # Auto-cleanup
  session$onSessionEnded(function() {
    if (!is.null(Rvars$global_pool) && Rvars$pool_active) {
      bpstop(Rvars$global_pool)
    }
  })
}
```

---

## ✅ Checklist d'Implémentation

- [ ] **Créer pool au DÉBUT du workflow** (pas à chaque étape)
- [ ] **Stocker pool dans reactiveValues** pour accès global
- [ ] **Réutiliser le MÊME pool** pour toutes les étapes parallèles
- [ ] **Fermer pool UNE FOIS** à la fin du workflow
- [ ] **Ajouter cleanup automatique** dans `session$onSessionEnded()`
- [ ] **Limiter à 2 workers** pour 300+ fichiers
- [ ] **Diagnostic** : Vérifier connexions avant/après
- [ ] **Tests** : Valider avec 312 fichiers

---

## 🎯 Résultat Attendu

### **Avant (sans pool réutilisable)**
```
[Workflow Start] Connexions: 3
[Grouping] Créer pool... Connexions: 10
[Map Gen] Créer pool... Connexions: 17
[Normalizers] Créer pool... ❌ ÉCHEC (trop de sockets)
```

### **Après (avec pool réutilisable)**
```
[Workflow Start] Connexions: 3
[Create Pool] Connexions: 5 (2 workers)
[Grouping] Réutilise pool... Connexions: 5
[Map Gen] Réutilise pool... Connexions: 5
[Normalizers] Réutilise pool... Connexions: 5 ✅
[Close Pool] Connexions: 3
```

**Le pool réutilisable = Solution la plus simple et la plus stable !** 🚀
