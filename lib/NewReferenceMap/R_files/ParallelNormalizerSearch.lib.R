# ═══════════════════════════════════════════════════════════════════════════
# ParallelNormalizerSearch.lib.R - Recherche Parallèle de Normalisateurs
# ═══════════════════════════════════════════════════════════════════════════
#
# Fonctions pour paralléliser efficacement la recherche de normalisateurs
# même avec des données immenses (312+ échantillons)
#
# Author: MSpandas Team
# Date: 2026-01-30
#
# ═══════════════════════════════════════════════════════════════════════════

library(BiocParallel)


#' Search Normalizers in Parallel by Sample
#'
#' Recherche des normalisateurs en parallèle en divisant par échantillon
#'
#' @param input_Matrix Matrice d'entrée (features × samples)
#' @param pFeatures Paramètre pFeatures
#' @param pSample Paramètre pSample
#' @param minNormalizersParam Paramètre minNormalizers
#' @param max_workers Nombre maximum de workers (auto si NULL)
#' @param batch_mode Utiliser le mode batch pour grandes données
#' @param verbose Afficher progression détaillée
#'
#' @return Résultats de la recherche de normalisateurs
#' @export
search_normalizers_parallel <- function(input_Matrix,
                                       pFeatures,
                                       pSample,
                                       minNormalizersParam,
                                       max_workers = NULL,
                                       batch_mode = TRUE,
                                       verbose = TRUE) {

  # Configuration adaptative
  n_samples <- ncol(input_Matrix)
  matrix_size_mb <- as.numeric(object.size(input_Matrix)) / 1024^2

  if (verbose) {
    cat("═══════════════════════════════════════════════════════\n")
    cat("🔍 Parallel Normalizer Search\n")
    cat("═══════════════════════════════════════════════════════\n")
    cat(sprintf("  Samples: %d\n", n_samples))
    cat(sprintf("  Matrix size: %.1f MB\n", matrix_size_mb))
  }

  # Déterminer workers
  if (is.null(max_workers)) {
    workers <- if (n_samples >= 300 || matrix_size_mb > 50) {
      2  # Limité pour grandes données
    } else if (n_samples >= 150) {
      3
    } else {
      min(4, parallel::detectCores() - 1)
    }
  } else {
    workers <- max_workers
  }

  if (verbose) {
    cat(sprintf("  Workers: %d\n", workers))
  }

  # Choisir mode : batch ou direct
  if (batch_mode && n_samples >= 100) {
    # Mode batch pour grandes données
    result <- search_normalizers_by_batch(
      input_Matrix = input_Matrix,
      pFeatures = pFeatures,
      pSample = pSample,
      minNormalizersParam = minNormalizersParam,
      workers = workers,
      verbose = verbose
    )
  } else {
    # Mode direct par échantillon
    result <- search_normalizers_by_sample(
      input_Matrix = input_Matrix,
      pFeatures = pFeatures,
      pSample = pSample,
      minNormalizersParam = minNormalizersParam,
      workers = workers,
      verbose = verbose
    )
  }

  if (verbose) {
    cat("✅ Normalizer search completed\n")
    cat("═══════════════════════════════════════════════════════\n\n")
  }

  return(result)
}


#' Search Normalizers by Sample (Mode Direct)
#'
#' Parallélisation directe sur tous les échantillons
#' Recommandé pour < 100 échantillons
#'
#' @keywords internal
search_normalizers_by_sample <- function(input_Matrix, pFeatures, pSample,
                                        minNormalizersParam, workers, verbose) {

  n_samples <- ncol(input_Matrix)

  if (verbose) {
    cat(sprintf("  Mode: Direct (all %d samples)\n", n_samples))
  }

  # Créer liste d'échantillons
  sample_list <- lapply(1:n_samples, function(i) {
    list(
      sample_data = input_Matrix[, i, drop = FALSE],
      sample_name = colnames(input_Matrix)[i],
      sample_idx = i
    )
  })

  # Fonction de traitement
  process_one_sample <- function(sample_job, pF, pS, minN) {
    # Appel à la fonction de recherche originale
    result <- Search_normalizers(
      Matrix = sample_job$sample_data,
      pFeatures = pF,
      pSample = pS,
      minNormalizersParam = minN
    )
    return(result)
  }

  # Créer cluster
  param <- SnowParam(
    workers = workers,
    type = "SOCK",
    timeout = 300,
    progressbar = verbose
  )

  # Traitement parallèle
  tryCatch({
    results <- bplapply(
      sample_list,
      process_one_sample,
      pF = pFeatures,
      pS = pSample,
      minN = minNormalizersParam,
      BPPARAM = param
    )

  }, finally = {
    bpstop(param)
    gc(verbose = FALSE)
  })

  # Combiner résultats
  if (length(results) > 0) {
    final_result <- do.call(rbind, results)
    return(final_result)
  } else {
    return(NULL)
  }
}


#' Search Normalizers by Batch
#'
#' Parallélisation par batch avec traitement séquentiel des batches
#' Recommandé pour 100+ échantillons
#'
#' @keywords internal
search_normalizers_by_batch <- function(input_Matrix, pFeatures, pSample,
                                       minNormalizersParam, workers, verbose) {

  n_samples <- ncol(input_Matrix)

  # Taille de batch adaptative
  batch_size <- if (n_samples >= 300) {
    30  # Petits batches pour grandes données
  } else if (n_samples >= 200) {
    40
  } else {
    50
  }

  n_batches <- ceiling(n_samples / batch_size)

  if (verbose) {
    cat(sprintf("  Mode: Batch (%d batches of ~%d samples)\n",
                n_batches, batch_size))
    cat("  Processing batches sequentially...\n")
  }

  all_results <- list()

  # Traiter chaque batch séquentiellement
  for (b in 1:n_batches) {
    # Extraire batch
    start_idx <- (b - 1) * batch_size + 1
    end_idx <- min(b * batch_size, n_samples)
    batch_matrix <- input_Matrix[, start_idx:end_idx, drop = FALSE]
    batch_samples <- end_idx - start_idx + 1

    if (verbose) {
      cat(sprintf("    Batch %d/%d (%d samples)...",
                  b, n_batches, batch_samples))
    }

    # Créer liste d'échantillons pour ce batch
    sample_list <- lapply(1:batch_samples, function(i) {
      list(
        sample_data = batch_matrix[, i, drop = FALSE],
        sample_name = colnames(batch_matrix)[i]
      )
    })

    # Fonction de traitement
    process_sample <- function(s, pF, pS, minN) {
      Search_normalizers(
        Matrix = s$sample_data,
        pFeatures = pF,
        pSample = pS,
        minNormalizersParam = minN
      )
    }

    # Créer cluster pour ce batch
    param <- SnowParam(
      workers = workers,
      type = "SOCK",
      timeout = 300,
      progressbar = FALSE  # Désactivé pour mode batch
    )

    # Traitement parallèle du batch
    tryCatch({
      batch_results <- bplapply(
        sample_list,
        process_sample,
        pF = pFeatures,
        pS = pSample,
        minN = minNormalizersParam,
        BPPARAM = param
      )

      # Combiner résultats du batch
      if (length(batch_results) > 0) {
        all_results[[b]] <- do.call(rbind, batch_results)
      }

      if (verbose) {
        cat(" ✅\n")
      }

    }, error = function(e) {
      if (verbose) {
        cat(sprintf(" ❌ Error: %s\n", e$message))
      }
      all_results[[b]] <- NULL

    }, finally = {
      bpstop(param)
      gc(verbose = FALSE)
    })
  }

  # Combiner tous les résultats
  valid_results <- all_results[!sapply(all_results, is.null)]

  if (length(valid_results) > 0) {
    final_result <- do.call(rbind, valid_results)
    return(final_result)
  } else {
    return(NULL)
  }
}


#' Search Normalizers with Checkpointing
#'
#' Recherche de normalisateurs avec checkpoints intermédiaires
#' pour reprise en cas de crash
#'
#' @param input_Matrix Matrice d'entrée
#' @param pFeatures Paramètre pFeatures
#' @param pSample Paramètre pSample
#' @param minNormalizersParam Paramètre minNormalizers
#' @param cache_info Info du système de cache (optionnel)
#' @param checkpoint_every Sauvegarder checkpoint tous les N batches
#' @param max_workers Nombre maximum de workers
#'
#' @return Résultats de la recherche
#' @export
search_normalizers_with_checkpoints <- function(input_Matrix,
                                               pFeatures,
                                               pSample,
                                               minNormalizersParam,
                                               cache_info = NULL,
                                               checkpoint_every = 5,
                                               max_workers = NULL) {

  n_samples <- ncol(input_Matrix)

  # Configuration
  if (is.null(max_workers)) {
    workers <- if (n_samples >= 300) 2 else min(4, detectCores() - 1)
  } else {
    workers <- max_workers
  }

  batch_size <- if (n_samples >= 300) 30 else 50
  n_batches <- ceiling(n_samples / batch_size)

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔍 Normalizer Search with Checkpointing\n")
  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("  Samples: %d\n", n_samples))
  cat(sprintf("  Batches: %d (size: %d)\n", n_batches, batch_size))
  cat(sprintf("  Workers: %d\n", workers))
  cat(sprintf("  Checkpoints: every %d batches\n", checkpoint_every))

  # Checkpoint initial (si cache disponible)
  if (!is.null(cache_info)) {
    tryCatch({
      save_checkpoint(
        checkpoint_id = "normalizer_search_start",
        cache_info = cache_info,
        variables = list(
          input_Matrix = input_Matrix,
          params = list(
            pFeatures = pFeatures,
            pSample = pSample,
            minNormalizers = minNormalizersParam
          )
        ),
        step_name = "Normalizer Search Started",
        next_step = "Processing batches"
      )
    }, error = function(e) {
      warning("Failed to save initial checkpoint: ", e$message)
    })
  }

  all_results <- list()

  # Traiter par batch
  for (b in 1:n_batches) {
    cat(sprintf("  Batch %d/%d...", b, n_batches))

    # Extraire batch
    start_idx <- (b - 1) * batch_size + 1
    end_idx <- min(b * batch_size, n_samples)
    batch_matrix <- input_Matrix[, start_idx:end_idx, drop = FALSE]

    # Liste d'échantillons
    sample_list <- lapply(1:ncol(batch_matrix), function(i) {
      list(data = batch_matrix[, i, drop = FALSE])
    })

    # Parallélisation
    param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

    tryCatch({
      batch_results <- bplapply(
        sample_list,
        function(s) Search_normalizers(s$data, pFeatures, pSample, minNormalizersParam),
        BPPARAM = param
      )

      all_results[[b]] <- do.call(rbind, batch_results)
      cat(" ✅\n")

    }, error = function(e) {
      cat(sprintf(" ❌ Error: %s\n", e$message))
      all_results[[b]] <- NULL

    }, finally = {
      bpstop(param)
      gc(verbose = FALSE)
    })

    # Checkpoint intermédiaire
    if ((b %% checkpoint_every == 0 || b == n_batches) && !is.null(cache_info)) {
      tryCatch({
        temp_result <- do.call(rbind, all_results[!sapply(all_results, is.null)])

        save_checkpoint(
          checkpoint_id = sprintf("normalizer_batch_%03d", b),
          cache_info = cache_info,
          variables = list(
            partial_results = temp_result,
            batches_completed = b,
            batches_total = n_batches
          ),
          step_name = sprintf("Normalizer Search Progress (%d/%d)", b, n_batches),
          next_step = if(b == n_batches) "Normalization" else "Continue batch processing"
        )

        cat(sprintf("    💾 Checkpoint saved (batch %d)\n", b))

      }, error = function(e) {
        warning("Failed to save checkpoint: ", e$message)
      })
    }
  }

  # Combiner résultats finaux
  valid_results <- all_results[!sapply(all_results, is.null)]

  if (length(valid_results) > 0) {
    final_result <- do.call(rbind, valid_results)

    # Checkpoint final
    if (!is.null(cache_info)) {
      tryCatch({
        save_checkpoint(
          checkpoint_id = "normalizer_search_complete",
          cache_info = cache_info,
          variables = list(normalizers = final_result),
          step_name = "Normalizer Search Complete",
          next_step = "Normalization"
        )
      }, error = function(e) {
        warning("Failed to save final checkpoint: ", e$message)
      })
    }

    cat("✅ Normalizer search completed successfully\n")
    cat(sprintf("   Results: %d rows\n", nrow(final_result)))
    cat("═══════════════════════════════════════════════════════\n\n")

    return(final_result)

  } else {
    cat("❌ All batches failed\n")
    cat("═══════════════════════════════════════════════════════\n\n")
    return(NULL)
  }
}


# ═══════════════════════════════════════════════════════════════════════════
# Fonction utilitaire : Diagnostic de parallélisation
# ═══════════════════════════════════════════════════════════════════════════

#' Test Parallel Configuration
#'
#' Teste la configuration parallèle et vérifie que ça fonctionne
#'
#' @param n_tasks Nombre de tâches de test
#' @param workers Nombre de workers
#' @export
test_parallel_config <- function(n_tasks = 10, workers = 2) {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🧪 Testing Parallel Configuration\n")
  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("  Tasks: %d\n", n_tasks))
  cat(sprintf("  Workers: %d\n", workers))

  # Créer tâches de test
  tasks <- 1:n_tasks

  # Fonction de test qui retourne le PID du worker
  test_fun <- function(task_id) {
    worker_pid <- Sys.getpid()
    Sys.sleep(0.5)  # Simuler travail
    return(list(
      task_id = task_id,
      worker_pid = worker_pid,
      timestamp = Sys.time()
    ))
  }

  # Créer cluster
  param <- SnowParam(workers = workers, type = "SOCK", timeout = 60)

  # Exécuter
  cat("\n  Running parallel tasks...\n")
  start_time <- Sys.time()

  results <- bplapply(tasks, test_fun, BPPARAM = param)

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  bpstop(param)

  # Analyser résultats
  pids <- unique(sapply(results, function(r) r$worker_pid))
  n_unique_workers <- length(pids)

  cat("\n  Results:\n")
  cat(sprintf("    Elapsed time: %.2f seconds\n", elapsed))
  cat(sprintf("    Unique worker PIDs: %d\n", n_unique_workers))

  if (n_unique_workers > 1) {
    cat("    ✅ PARALLEL execution detected!\n")
    cat(sprintf("    Workers used: %s\n", paste(pids, collapse = ", ")))
  } else {
    cat("    ❌ SEQUENTIAL execution (only 1 worker PID)\n")
    cat("    This indicates parallelization is NOT working!\n")
  }

  # Calcul efficacité
  expected_time_sequential <- n_tasks * 0.5
  speedup <- expected_time_sequential / elapsed
  efficiency <- (speedup / workers) * 100

  cat(sprintf("    Speedup: %.2fx\n", speedup))
  cat(sprintf("    Efficiency: %.1f%%\n", efficiency))

  cat("═══════════════════════════════════════════════════════\n\n")

  return(invisible(list(
    parallel = n_unique_workers > 1,
    n_workers_used = n_unique_workers,
    elapsed = elapsed,
    speedup = speedup,
    efficiency = efficiency
  )))
}


cat("✅ ParallelNormalizerSearch.lib.R loaded successfully\n")
cat("   Functions available:\n")
cat("   - search_normalizers_parallel()\n")
cat("   - search_normalizers_with_checkpoints()\n")
cat("   - test_parallel_config()\n\n")
