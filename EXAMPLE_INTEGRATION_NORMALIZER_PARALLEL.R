# ═══════════════════════════════════════════════════════════════════════════
# Exemple d'Intégration : Recherche Parallèle de Normalisateurs dans Shiny
# ═══════════════════════════════════════════════════════════════════════════
#
# Ce fichier montre comment intégrer la recherche parallèle de normalisateurs
# dans l'application Shiny MSpandas
#
# ═══════════════════════════════════════════════════════════════════════════

# Charger la bibliothèque de parallélisation
source("lib/NewReferenceMap/R_files/ParallelNormalizerSearch.lib.R")

# Charger le système de cache (optionnel mais recommandé)
source("lib/cache/CacheManager.lib.R")
source("lib/cache/ShinyIntegration.lib.R")


# ═══════════════════════════════════════════════════════════════════════════
# MÉTHODE 1 : Simple (sans checkpoint)
# ═══════════════════════════════════════════════════════════════════════════

observeEvent(input$run_normalizer_search_simple, {
  req(RvarsInternalStandard$Matrix_filter_BySample)

  withProgress(message = "Searching normalizers...", value = 0, {

    # Appel simple avec détection automatique du mode
    RvarsInternalStandard$OjectNormalizers <- search_normalizers_parallel(
      input_Matrix = RvarsInternalStandard$Matrix_filter_BySample,
      pFeatures = input$pFeatures,
      pSample = input$pSample,
      minNormalizersParam = input$minNormalizers,
      max_workers = NULL,  # Détection automatique
      batch_mode = TRUE,   # Active mode batch pour grandes données
      verbose = TRUE
    )

    if (!is.null(RvarsInternalStandard$OjectNormalizers)) {
      showNotification(
        sprintf("✅ Found %d normalizers",
                nrow(RvarsInternalStandard$OjectNormalizers)),
        type = "message",
        duration = 5
      )
    } else {
      showNotification(
        "⚠️ No normalizers found",
        type = "warning",
        duration = 5
      )
    }
  })
})


# ═══════════════════════════════════════════════════════════════════════════
# MÉTHODE 2 : Avec Checkpoints (Recommandé pour 312 fichiers)
# ═══════════════════════════════════════════════════════════════════════════

observeEvent(input$run_normalizer_search_with_cache, {
  req(RvarsInternalStandard$Matrix_filter_BySample)
  req(Rvars$cache_info)  # Cache doit être initialisé

  # Checkpoint AVANT la recherche (état juste avant)
  save_checkpoint_with_progress(
    checkpoint_id = "step_03_before_normalizer_search",
    cache_info = Rvars$cache_info,
    variables = list(
      Matrix_filtered = RvarsInternalStandard$Matrix_filter_BySample,
      groups = RvarsGrouping$GroupedMassifList,
      isotopes = RvarsGrouping$IsotopeAnnotation
    ),
    step_name = "Ready for Normalizer Search",
    next_step = "Normalizer Search"
  )

  # Recherche avec checkpoints intermédiaires
  withProgress(message = "Searching normalizers with checkpoints...", value = 0, {

    RvarsInternalStandard$OjectNormalizers <- search_normalizers_with_checkpoints(
      input_Matrix = RvarsInternalStandard$Matrix_filter_BySample,
      pFeatures = input$pFeatures,
      pSample = input$pSample,
      minNormalizersParam = input$minNormalizers,
      cache_info = Rvars$cache_info,
      checkpoint_every = 5,  # Checkpoint tous les 5 batches
      max_workers = NULL     # Détection automatique
    )

    if (!is.null(RvarsInternalStandard$OjectNormalizers)) {
      # Checkpoint final (après succès)
      save_checkpoint_with_progress(
        checkpoint_id = "step_04_normalizers_found",
        cache_info = Rvars$cache_info,
        variables = list(
          Matrix_filtered = RvarsInternalStandard$Matrix_filter_BySample,
          groups = RvarsGrouping$GroupedMassifList,
          normalizers = RvarsInternalStandard$OjectNormalizers
        ),
        step_name = "Normalizers Found",
        next_step = "Normalization"
      )

      showNotification(
        sprintf("✅ Found %d normalizers (checkpointed)",
                nrow(RvarsInternalStandard$OjectNormalizers)),
        type = "message",
        duration = 5
      )
    } else {
      showNotification(
        "⚠️ No normalizers found",
        type = "warning",
        duration = 5
      )
    }
  })
})


# ═══════════════════════════════════════════════════════════════════════════
# MÉTHODE 3 : Configuration Avancée (Contrôle Total)
# ═══════════════════════════════════════════════════════════════════════════

observeEvent(input$run_normalizer_search_advanced, {
  req(RvarsInternalStandard$Matrix_filter_BySample)

  # Configuration manuelle
  n_samples <- ncol(RvarsInternalStandard$Matrix_filter_BySample)
  matrix_size_mb <- as.numeric(object.size(RvarsInternalStandard$Matrix_filter_BySample)) / 1024^2

  # Déterminer stratégie
  if (n_samples >= 300 || matrix_size_mb > 100) {
    # Stratégie conservatrice pour grandes données
    workers <- 2
    batch_size <- 25
    checkpoint_every <- 3
    strategy <- "Conservative (large dataset)"

  } else if (n_samples >= 150) {
    # Stratégie intermédiaire
    workers <- 3
    batch_size <- 40
    checkpoint_every <- 5
    strategy <- "Balanced (medium dataset)"

  } else {
    # Stratégie agressive pour petites données
    workers <- min(4, detectCores() - 1)
    batch_size <- 50
    checkpoint_every <- 10
    strategy <- "Aggressive (small dataset)"
  }

  # Afficher configuration
  showModal(modalDialog(
    title = "🔍 Normalizer Search Configuration",
    HTML(paste0(
      "<p><strong>Samples:</strong> ", n_samples, "</p>",
      "<p><strong>Matrix size:</strong> ", sprintf("%.1f MB", matrix_size_mb), "</p>",
      "<p><strong>Strategy:</strong> ", strategy, "</p>",
      "<p><strong>Workers:</strong> ", workers, "</p>",
      "<p><strong>Batch size:</strong> ", batch_size, "</p>",
      "<p><strong>Checkpoint frequency:</strong> Every ", checkpoint_every, " batches</p>",
      "<hr>",
      "<p>Estimated time: ",
      sprintf("%.1f minutes", (n_samples / batch_size / workers) * 0.5),
      "</p>"
    )),
    footer = tagList(
      actionButton("confirm_search", "▶️ Start Search", class = "btn-primary"),
      modalButton("Cancel")
    ),
    easyClose = FALSE
  ))
})

# Exécution après confirmation
observeEvent(input$confirm_search, {
  removeModal()

  req(RvarsInternalStandard$Matrix_filter_BySample)

  n_samples <- ncol(RvarsInternalStandard$Matrix_filter_BySample)
  workers <- if (n_samples >= 300) 2 else if (n_samples >= 150) 3 else 4
  batch_size <- if (n_samples >= 300) 25 else if (n_samples >= 150) 40 else 50
  n_batches <- ceiling(n_samples / batch_size)

  withProgress(message = "Processing batches...", value = 0, {

    all_results <- list()

    for (b in 1:n_batches) {
      incProgress(1/n_batches, detail = sprintf("Batch %d/%d", b, n_batches))

      # Extraire batch
      start_idx <- (b - 1) * batch_size + 1
      end_idx <- min(b * batch_size, n_samples)
      batch_matrix <- RvarsInternalStandard$Matrix_filter_BySample[, start_idx:end_idx, drop = FALSE]

      # Créer liste d'échantillons
      sample_list <- lapply(1:ncol(batch_matrix), function(i) {
        list(data = batch_matrix[, i, drop = FALSE])
      })

      # Parallélisation
      param <- SnowParam(workers = workers, type = "SOCK", timeout = 300)

      tryCatch({
        batch_results <- bplapply(
          sample_list,
          function(s) Search_normalizers(
            s$data,
            input$pFeatures,
            input$pSample,
            input$minNormalizers
          ),
          BPPARAM = param
        )

        all_results[[b]] <- do.call(rbind, batch_results)

      }, error = function(e) {
        showNotification(
          sprintf("⚠️ Batch %d failed: %s", b, e$message),
          type = "warning"
        )
        all_results[[b]] <- NULL

      }, finally = {
        bpstop(param)
        gc(verbose = FALSE)
      })

      # Checkpoint intermédiaire
      if (b %% 3 == 0 && !is.null(Rvars$cache_info)) {
        temp_result <- do.call(rbind, all_results[!sapply(all_results, is.null)])
        save_checkpoint(
          sprintf("normalizer_batch_%03d", b),
          Rvars$cache_info,
          list(partial_normalizers = temp_result),
          sprintf("Normalizer Progress (%d/%d)", b, n_batches),
          "Continue"
        )
      }
    }

    # Combiner résultats
    valid_results <- all_results[!sapply(all_results, is.null)]
    if (length(valid_results) > 0) {
      RvarsInternalStandard$OjectNormalizers <- do.call(rbind, valid_results)

      showNotification(
        sprintf("✅ Search complete: %d normalizers found in %d batches",
                nrow(RvarsInternalStandard$OjectNormalizers), n_batches),
        type = "message",
        duration = 10
      )
    } else {
      showNotification(
        "❌ All batches failed",
        type = "error",
        duration = 10
      )
    }
  })
})


# ═══════════════════════════════════════════════════════════════════════════
# MÉTHODE 4 : Test de Configuration (Diagnostic)
# ═══════════════════════════════════════════════════════════════════════════

observeEvent(input$test_parallel_config, {

  showModal(modalDialog(
    title = "🧪 Testing Parallel Configuration",
    HTML("<p>Running diagnostic test to verify parallel execution...</p>"),
    footer = NULL,
    easyClose = FALSE
  ))

  # Exécuter test
  test_result <- test_parallel_config(n_tasks = 10, workers = 2)

  removeModal()

  # Afficher résultats
  if (test_result$parallel) {
    showModal(modalDialog(
      title = "✅ Parallel Execution Working!",
      HTML(paste0(
        "<p><strong>Status:</strong> PARALLEL execution detected</p>",
        "<p><strong>Workers used:</strong> ", test_result$n_workers_used, "</p>",
        "<p><strong>Elapsed time:</strong> ", sprintf("%.2f seconds", test_result$elapsed), "</p>",
        "<p><strong>Speedup:</strong> ", sprintf("%.2fx", test_result$speedup), "</p>",
        "<p><strong>Efficiency:</strong> ", sprintf("%.1f%%", test_result$efficiency), "</p>",
        "<hr>",
        "<p style='color: green;'>✅ Your parallel configuration is working correctly!</p>"
      )),
      footer = modalButton("OK"),
      easyClose = TRUE
    ))
  } else {
    showModal(modalDialog(
      title = "❌ Parallel Execution Not Working",
      HTML(paste0(
        "<p><strong>Status:</strong> SEQUENTIAL execution detected</p>",
        "<p><strong>Workers used:</strong> ", test_result$n_workers_used, " (should be > 1)</p>",
        "<p><strong>Elapsed time:</strong> ", sprintf("%.2f seconds", test_result$elapsed), "</p>",
        "<hr>",
        "<p style='color: red;'>❌ Parallelization is not functioning!</p>",
        "<p><strong>Possible causes:</strong></p>",
        "<ul>",
        "<li>BiocParallel not installed correctly</li>",
        "<li>Workers not starting (firewall/antivirus?)</li>",
        "<li>PSOCK sockets blocked</li>",
        "</ul>",
        "<p><strong>Solution:</strong> Check BiocParallel installation and try restarting R session.</p>"
      )),
      footer = modalButton("OK"),
      easyClose = TRUE
    ))
  }
})


# ═══════════════════════════════════════════════════════════════════════════
# Comparaison de Performance (Séquentiel vs Parallèle)
# ═══════════════════════════════════════════════════════════════════════════

observeEvent(input$benchmark_parallel, {
  req(RvarsInternalStandard$Matrix_filter_BySample)

  # Créer échantillon réduit pour benchmark rapide
  n_samples_full <- ncol(RvarsInternalStandard$Matrix_filter_BySample)
  n_samples_test <- min(20, n_samples_full)  # Max 20 échantillons pour test

  test_matrix <- RvarsInternalStandard$Matrix_filter_BySample[, 1:n_samples_test, drop = FALSE]

  showModal(modalDialog(
    title = "⏱️ Performance Benchmark",
    HTML(paste0(
      "<p>Comparing sequential vs parallel execution...</p>",
      "<p><strong>Test size:</strong> ", n_samples_test, " samples</p>",
      "<p>This will take ~1-2 minutes...</p>"
    )),
    footer = NULL,
    easyClose = FALSE
  ))

  # Test séquentiel
  time_seq <- system.time({
    result_seq <- search_normalizers_by_sample(
      test_matrix,
      input$pFeatures,
      input$pSample,
      input$minNormalizers,
      workers = 1,
      verbose = FALSE
    )
  })

  # Test parallèle
  time_par <- system.time({
    result_par <- search_normalizers_by_sample(
      test_matrix,
      input$pFeatures,
      input$pSample,
      input$minNormalizers,
      workers = 2,
      verbose = FALSE
    )
  })

  removeModal()

  # Calculer amélioration
  speedup <- time_seq[["elapsed"]] / time_par[["elapsed"]]
  time_saved_pct <- (1 - 1/speedup) * 100

  # Extrapoler pour dataset complet
  estimated_seq_full <- (time_seq[["elapsed"]] / n_samples_test) * n_samples_full / 60
  estimated_par_full <- (time_par[["elapsed"]] / n_samples_test) * n_samples_full / 60
  time_saved_full <- estimated_seq_full - estimated_par_full

  # Afficher résultats
  showModal(modalDialog(
    title = "📊 Benchmark Results",
    HTML(paste0(
      "<h4>Test Results (", n_samples_test, " samples)</h4>",
      "<table class='table'>",
      "<tr><td><strong>Sequential:</strong></td><td>", sprintf("%.2f seconds", time_seq[["elapsed"]]), "</td></tr>",
      "<tr><td><strong>Parallel (2 workers):</strong></td><td>", sprintf("%.2f seconds", time_par[["elapsed"]]), "</td></tr>",
      "<tr><td><strong>Speedup:</strong></td><td style='color: green;'><strong>", sprintf("%.2fx", speedup), "</strong></td></tr>",
      "<tr><td><strong>Time saved:</strong></td><td style='color: green;'><strong>", sprintf("%.1f%%", time_saved_pct), "</strong></td></tr>",
      "</table>",
      "<hr>",
      "<h4>Extrapolation for Full Dataset (", n_samples_full, " samples)</h4>",
      "<table class='table'>",
      "<tr><td><strong>Sequential:</strong></td><td>", sprintf("%.1f minutes", estimated_seq_full), "</td></tr>",
      "<tr><td><strong>Parallel:</strong></td><td>", sprintf("%.1f minutes", estimated_par_full), "</td></tr>",
      "<tr><td><strong>Time saved:</strong></td><td style='color: green; font-size: 1.2em;'><strong>", sprintf("%.1f minutes", time_saved_full), "</strong></td></tr>",
      "</table>",
      "<hr>",
      "<p style='color: ",
      if(speedup > 1.5) "green" else "orange",
      ";'><strong>",
      if(speedup > 1.5) {
        "✅ Parallel execution is effective!"
      } else {
        "⚠️ Parallel speedup is lower than expected. Check workers configuration."
      },
      "</strong></p>"
    )),
    footer = modalButton("OK"),
    easyClose = TRUE
  ))
})


# ═══════════════════════════════════════════════════════════════════════════
# Note : Intégration dans l'interface UI
# ═══════════════════════════════════════════════════════════════════════════

# Ajouter ces boutons à votre UI :

# Dans ui.R ou dans la section InternalStandard :
# wellPanel(
#   h4("Normalizer Search"),
#
#   # Méthode simple
#   actionButton("run_normalizer_search_simple",
#                "🚀 Search Normalizers (Auto)",
#                class = "btn-primary btn-block"),
#
#   # Méthode avec cache
#   actionButton("run_normalizer_search_with_cache",
#                "💾 Search with Checkpoints",
#                class = "btn-success btn-block"),
#
#   # Méthode avancée
#   actionButton("run_normalizer_search_advanced",
#                "⚙️ Advanced Configuration",
#                class = "btn-info btn-block"),
#
#   hr(),
#
#   # Diagnostic
#   actionButton("test_parallel_config",
#                "🧪 Test Parallel Config",
#                class = "btn-default btn-sm"),
#
#   actionButton("benchmark_parallel",
#                "⏱️ Benchmark Performance",
#                class = "btn-default btn-sm")
# )
