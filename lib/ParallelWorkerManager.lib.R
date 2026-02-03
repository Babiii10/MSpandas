# ═══════════════════════════════════════════════════════════════════════════
# ParallelWorkerManager.lib.R - Gestionnaire Robuste de Workers Parallèles
# ═══════════════════════════════════════════════════════════════════════════
#
# Gestion centralisée et robuste des workers parallèles pour éviter
# l'accumulation de sockets et garantir un système stable
#
# Author: MSpandas Team
# Date: 2026-01-30
#
# ═══════════════════════════════════════════════════════════════════════════

library(BiocParallel)
library(parallel)

# ═══════════════════════════════════════════════════════════════════════════
# diagnose_connections - Diagnostic des Connexions Actives
# ═══════════════════════════════════════════════════════════════════════════
#' Affiche le nombre de connexions R actives
#'
#' @param step_name Nom de l'étape pour identification
#' @param warn_threshold Seuil d'avertissement (défaut: 20)
#' @param error_threshold Seuil d'erreur (défaut: 50)
#'
#' @return Nombre de connexions actives
#' @export
diagnose_connections <- function(step_name = "Check",
                                warn_threshold = 20,
                                error_threshold = 50) {

  all_conn <- getAllConnections()
  n_conn <- length(all_conn)

  # Compter les socket connections spécifiquement
  conn_info <- showConnections(all = TRUE)
  if (nrow(conn_info) > 0) {
    sock_conn <- sum(grepl("sockconn", conn_info[, "class"]))
  } else {
    sock_conn <- 0
  }

  # Affichage
  status <- if (n_conn >= error_threshold) {
    "❌"
  } else if (n_conn >= warn_threshold) {
    "⚠️ "
  } else {
    "✅"
  }

  cat(sprintf("[%s] %s Connexions: %d (sockets: %d)\n",
              step_name, status, n_conn, sock_conn))

  if (n_conn >= error_threshold) {
    cat("   ❌ CRITIQUE: Trop de connexions ouvertes!\n")
    cat("   → Appeler cleanup_connections() immédiatement\n")
  } else if (n_conn >= warn_threshold) {
    cat("   ⚠️  Attention: Accumulation détectée\n")
  }

  return(invisible(n_conn))
}


# ═══════════════════════════════════════════════════════════════════════════
# cleanup_connections - Nettoyage Agressif des Connexions
# ═══════════════════════════════════════════════════════════════════════════
#' Ferme toutes les connexions non essentielles et force le garbage collection
#'
#' @param verbose Afficher les détails (défaut: TRUE)
#' @param wait_time Temps d'attente après nettoyage en secondes (défaut: 0.5)
#'
#' @return Nombre de connexions restantes
#' @export
cleanup_connections <- function(verbose = TRUE, wait_time = 0.5) {

  if (verbose) {
    cat("\n🧹 Nettoyage des connexions...\n")
  }

  # Connexions avant nettoyage
  before_count <- length(getAllConnections())

  if (verbose && before_count > 3) {
    cat(sprintf("   Connexions avant: %d\n", before_count))
  }

  # Fermer toutes les connexions sauf stdin(0), stdout(1), stderr(2)
  all_conn <- getAllConnections()
  base_conn <- c(0, 1, 2)
  to_close <- setdiff(all_conn, base_conn)

  closed_count <- 0
  if (length(to_close) > 0) {
    for (conn_id in to_close) {
      tryCatch({
        conn <- getConnection(conn_id)
        close(conn)
        closed_count <- closed_count + 1
      }, error = function(e) {
        # Ignorer les erreurs (connexion déjà fermée, etc.)
      })
    }
  }

  # Force garbage collection (2 passes pour être sûr)
  gc(verbose = FALSE)
  gc(verbose = FALSE)

  # Attendre que le système libère les ressources
  if (wait_time > 0) {
    Sys.sleep(wait_time)
  }

  # Connexions après nettoyage
  after_count <- length(getAllConnections())

  if (verbose) {
    if (closed_count > 0) {
      cat(sprintf("   ✅ Fermé %d connexion(s)\n", closed_count))
    }
    cat(sprintf("   Connexions après: %d\n", after_count))
  }

  return(invisible(after_count))
}


# ═══════════════════════════════════════════════════════════════════════════
# get_safe_workers - Déterminer le Nombre Sûr de Workers
# ═══════════════════════════════════════════════════════════════════════════
#' Calcule le nombre optimal de workers en fonction de l'état du système
#'
#' @param n_samples Nombre d'échantillons à traiter
#' @param stage Nom de l'étape (pour stratégie adaptative)
#' @param max_workers Maximum de workers autorisés (NULL = auto)
#'
#' @return Nombre de workers recommandé
#' @export
get_safe_workers <- function(n_samples = NULL, stage = "default", max_workers = NULL) {

  # Nombre de connexions actuelles
  current_conn <- length(getAllConnections())

  # Déterminer max_workers si non spécifié
  if (is.null(max_workers)) {
    # Stratégie : Réduire si trop de connexions
    if (current_conn > 50) {
      max_workers <- 2  # Très conservateur
    } else if (current_conn > 30) {
      max_workers <- 3
    } else if (current_conn > 15) {
      max_workers <- 4
    } else {
      max_workers <- min(detectCores() - 1, 6)
    }
  }

  # Ajuster selon la taille des données
  if (!is.null(n_samples)) {
    if (n_samples >= 300) {
      max_workers <- min(max_workers, 2)  # Limité pour très grandes données
    } else if (n_samples >= 200) {
      max_workers <- min(max_workers, 3)
    } else if (n_samples >= 100) {
      max_workers <- min(max_workers, 4)
    }
  }

  # Garantir minimum 1 worker
  final_workers <- max(1, max_workers)

  cat(sprintf("[%s] Workers: %d (connexions: %d, échantillons: %s)\n",
              stage, final_workers, current_conn,
              if(is.null(n_samples)) "?" else as.character(n_samples)))

  return(final_workers)
}


# ═══════════════════════════════════════════════════════════════════════════
# execute_parallel_safe - Exécution Parallèle Sécurisée (BiocParallel)
# ═══════════════════════════════════════════════════════════════════════════
#' Exécute bplapply avec garantie de fermeture des sockets
#'
#' @param data_list Liste de données à traiter
#' @param fun Fonction à appliquer
#' @param workers Nombre de workers (NULL = auto)
#' @param timeout Timeout en secondes (défaut: 300)
#' @param step_name Nom de l'étape (pour diagnostic)
#' @param ... Arguments supplémentaires pour fun
#'
#' @return Résultats de bplapply ou NULL si erreur
#' @export
execute_parallel_safe <- function(data_list, fun, workers = NULL,
                                  timeout = 300, step_name = "Parallel",
                                  ...) {

  diagnose_connections(paste0("AVANT ", step_name))

  # Déterminer workers
  if (is.null(workers)) {
    workers <- get_safe_workers(
      n_samples = length(data_list),
      stage = step_name
    )
  }

  # Créer cluster
  param <- SnowParam(
    workers = workers,
    type = "SOCK",
    timeout = timeout,
    progressbar = FALSE
  )

  # Exécution avec garantie de fermeture
  result <- NULL

  tryCatch({
    result <- bplapply(data_list, fun, ..., BPPARAM = param)
    cat(sprintf("[%s] ✅ Completed\n", step_name))

  }, error = function(e) {
    cat(sprintf("[%s] ❌ Error: %s\n", step_name, e$message))
    result <- NULL

  }, finally = {
    # GARANTIE : Fermeture même si erreur
    bpstop(param)
    gc(verbose = FALSE)
    diagnose_connections(paste0("APRÈS ", step_name))
  })

  return(result)
}


# ═══════════════════════════════════════════════════════════════════════════
# execute_cluster_safe - Exécution Parallèle Sécurisée (parallel)
# ═══════════════════════════════════════════════════════════════════════════
#' Exécute parLapply avec garantie de fermeture du cluster
#'
#' @param data_list Liste de données à traiter
#' @param fun Fonction à appliquer
#' @param workers Nombre de workers (NULL = auto)
#' @param export_vars Variables à exporter vers workers
#' @param step_name Nom de l'étape (pour diagnostic)
#' @param ... Arguments supplémentaires pour fun
#'
#' @return Résultats de parLapply ou NULL si erreur
#' @export
execute_cluster_safe <- function(data_list, fun, workers = NULL,
                                export_vars = NULL, step_name = "Cluster",
                                ...) {

  diagnose_connections(paste0("AVANT ", step_name))

  # Déterminer workers
  if (is.null(workers)) {
    workers <- get_safe_workers(
      n_samples = length(data_list),
      stage = step_name
    )
  }

  # Créer cluster
  cl <- makeCluster(workers, type = "PSOCK")

  result <- NULL

  tryCatch({
    # Exporter variables si spécifiées
    if (!is.null(export_vars)) {
      clusterExport(cl, varlist = export_vars, envir = parent.frame())
    }

    # Exécution
    result <- parLapply(cl, data_list, fun, ...)
    cat(sprintf("[%s] ✅ Completed\n", step_name))

  }, error = function(e) {
    cat(sprintf("[%s] ❌ Error: %s\n", step_name, e$message))
    result <- NULL

  }, finally = {
    # GARANTIE : Fermeture même si erreur
    stopCluster(cl)
    gc(verbose = FALSE)
    diagnose_connections(paste0("APRÈS ", step_name))
  })

  return(result)
}


# ═══════════════════════════════════════════════════════════════════════════
# WorkerPool - Classe pour Pool de Workers Réutilisable
# ═══════════════════════════════════════════════════════════════════════════
#' Crée un pool de workers réutilisable pour un workflow complet
#'
#' @param n_workers Nombre de workers (NULL = auto)
#' @param timeout Timeout en secondes
#'
#' @return Liste avec pool et méthodes
#' @export
WorkerPool <- function(n_workers = NULL, timeout = 600) {

  if (is.null(n_workers)) {
    n_workers <- get_safe_workers()
  }

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔧 Creating Worker Pool\n")
  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("Workers: %d\n", n_workers))
  cat(sprintf("Timeout: %d seconds\n", timeout))

  # Créer le pool
  param <- SnowParam(
    workers = n_workers,
    type = "SOCK",
    timeout = timeout,
    progressbar = FALSE
  )

  cat("✅ Worker pool created\n")
  cat("═══════════════════════════════════════════════════════\n\n")

  diagnose_connections("Pool Created")

  # Retourner objet avec méthodes
  pool <- list(
    param = param,
    n_workers = n_workers,
    is_active = TRUE,

    # Méthode : Exécuter une tâche
    execute = function(data_list, fun, step_name = "Task", ...) {
      if (!pool$is_active) {
        stop("Worker pool is closed!")
      }

      diagnose_connections(paste0("AVANT ", step_name))

      result <- tryCatch({
        bplapply(data_list, fun, ..., BPPARAM = pool$param)
      }, error = function(e) {
        cat(sprintf("[%s] ❌ Error: %s\n", step_name, e$message))
        NULL
      })

      diagnose_connections(paste0("APRÈS ", step_name))

      return(result)
    },

    # Méthode : Fermer le pool
    close = function() {
      if (pool$is_active) {
        cat("\n🔒 Closing worker pool...\n")
        bpstop(pool$param)
        pool$is_active <- FALSE
        gc(verbose = FALSE)
        cat("✅ Worker pool closed\n\n")
        diagnose_connections("Pool Closed")
      } else {
        cat("⚠️  Worker pool already closed\n")
      }
    },

    # Méthode : Vérifier si actif
    is_alive = function() {
      return(pool$is_active)
    }
  )

  class(pool) <- "WorkerPool"

  return(pool)
}


# ═══════════════════════════════════════════════════════════════════════════
# diagnose_parallel_system - Diagnostic Complet du Système
# ═══════════════════════════════════════════════════════════════════════════
#' Effectue un diagnostic complet du système de parallélisation
#'
#' @return Liste avec résultats du diagnostic
#' @export
diagnose_parallel_system <- function() {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║      DIAGNOSTIC DU SYSTÈME DE PARALLÉLISATION                ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

  # 1. Connexions R
  all_conn <- getAllConnections()
  n_conn <- length(all_conn)

  cat(sprintf("1. Connexions R actives: %d\n", n_conn))

  if (n_conn > 50) {
    cat("   ❌ CRITIQUE: Trop de connexions!\n")
  } else if (n_conn > 20) {
    cat("   ⚠️  Attention: Nombre élevé\n")
  } else {
    cat("   ✅ Normal\n")
  }

  # Détails des socket connections
  if (n_conn > 0) {
    conn_info <- showConnections(all = TRUE)
    if (nrow(conn_info) > 0) {
      sock_conn <- sum(grepl("sockconn", conn_info[, "class"]))
      cat(sprintf("   - Socket connections: %d\n", sock_conn))

      if (sock_conn > 0) {
        cat("   - Détails:\n")
        sock_rows <- conn_info[grepl("sockconn", conn_info[, "class"]), ]
        for (i in 1:min(5, nrow(sock_rows))) {
          cat(sprintf("     [%s] %s\n",
                      rownames(sock_rows)[i],
                      sock_rows[i, "description"]))
        }
        if (nrow(sock_rows) > 5) {
          cat(sprintf("     ... et %d autres\n", nrow(sock_rows) - 5))
        }
      }
    }
  }

  # 2. Mémoire
  cat("\n2. Mémoire:\n")
  mem_info <- gc()
  total_mb <- sum(mem_info[, "used"]) / 1024
  cat(sprintf("   Utilisée: %.1f MB\n", total_mb))

  if (total_mb > 2000) {
    cat("   ⚠️  Utilisation mémoire élevée\n")
  } else {
    cat("   ✅ Normal\n")
  }

  # 3. Cores disponibles
  cat("\n3. Processeurs:\n")
  n_cores <- detectCores()
  cat(sprintf("   Cores disponibles: %d\n", n_cores))

  recommended <- get_safe_workers(stage = "Diagnostic")
  cat(sprintf("   Workers recommandés: %d\n", recommended))

  # 4. Test de création cluster
  cat("\n4. Test création cluster:\n")
  test_passed <- FALSE
  test_error <- NULL

  test_passed <- tryCatch({
    cat("   Tentative de création (2 workers)...")
    test_cl <- makeCluster(2, type = "PSOCK")
    Sys.sleep(0.5)
    stopCluster(test_cl)
    gc(verbose = FALSE)
    cat(" ✅ OK\n")
    TRUE
  }, error = function(e) {
    cat(sprintf(" ❌ ÉCHEC\n")
    cat(sprintf("   Erreur: %s\n", e$message))
    test_error <<- e$message
    FALSE
  })

  # 5. Résumé et recommandations
  cat("\n═══════════════════════════════════════════════════════════════\n")
  cat("RÉSUMÉ:\n")

  if (!test_passed) {
    cat("\n❌ SYSTÈME NON FONCTIONNEL\n")
    cat("   Impossible de créer un cluster parallèle!\n\n")
    cat("SOLUTIONS:\n")
    cat("   1. cleanup_connections()  # Nettoyer les connexions\n")
    cat("   2. Redémarrer session R\n")
    cat("   3. Vérifier pare-feu/antivirus Windows\n")
    cat("   4. Augmenter limite ports éphémères Windows\n")

  } else if (n_conn > 50) {
    cat("\n⚠️  ACCUMULATION CRITIQUE DÉTECTÉE\n")
    cat("   Le système fonctionne mais trop de connexions ouvertes\n\n")
    cat("ACTIONS RECOMMANDÉES:\n")
    cat("   1. cleanup_connections()  # Immédiatement\n")
    cat("   2. Vérifier que tous les bpstop() sont appelés\n")
    cat("   3. Ajouter try-finally partout\n")

  } else if (n_conn > 20) {
    cat("\n⚠️  SURVEILLANCE RECOMMANDÉE\n")
    cat("   Nombre de connexions élevé mais gérable\n\n")
    cat("RECOMMANDATIONS:\n")
    cat("   1. Surveiller l'évolution\n")
    cat("   2. Cleanup entre étapes importantes\n")

  } else {
    cat("\n✅ SYSTÈME EN BON ÉTAT\n")
    cat("   Prêt pour traitement parallèle\n\n")
    cat("BONNES PRATIQUES:\n")
    cat("   1. Toujours utiliser try-finally\n")
    cat("   2. Limiter workers à 2-4 pour grandes données\n")
    cat("   3. Cleanup entre étapes si workflow long\n")
  }

  cat("═══════════════════════════════════════════════════════════════\n\n")

  # Retour
  return(invisible(list(
    n_connections = n_conn,
    n_socket_connections = if(n_conn > 0) sock_conn else 0,
    memory_mb = total_mb,
    n_cores = n_cores,
    recommended_workers = recommended,
    test_passed = test_passed,
    test_error = test_error,
    status = if(!test_passed) "CRITICAL" else if(n_conn > 50) "WARNING_HIGH" else if(n_conn > 20) "WARNING_MEDIUM" else "OK"
  )))
}


# ═══════════════════════════════════════════════════════════════════════════
# Message de chargement
# ═══════════════════════════════════════════════════════════════════════════

cat("✅ ParallelWorkerManager.lib.R loaded successfully\n")
cat("   Functions available:\n")
cat("   - diagnose_connections(step_name)\n")
cat("   - cleanup_connections(verbose)\n")
cat("   - get_safe_workers(n_samples, stage)\n")
cat("   - execute_parallel_safe(data_list, fun, ...)\n")
cat("   - execute_cluster_safe(data_list, fun, ...)\n")
cat("   - WorkerPool(n_workers)  # Pool réutilisable\n")
cat("   - diagnose_parallel_system()  # Diagnostic complet\n\n")

cat("Recommendation: Run diagnose_parallel_system() to check system state\n\n")
