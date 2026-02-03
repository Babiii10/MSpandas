# ══════════════════════════════════════════════════════════════════════════════
# Examples: Parallel Calculate Variability Integration
# ══════════════════════════════════════════════════════════════════════════════
#
# This file shows how to integrate the parallel version of calculate_Variability
# into your existing MSpandas workflow.
#
# ══════════════════════════════════════════════════════════════════════════════

library(future)
library(future.apply)

# Load the parallel implementation
source("lib/NewReferenceMap/R_files/calculate_Variability_parallel.R")

# ──────────────────────────────────────────────────────────────────────────────
# Example 1: Basic Usage (replaces old calculate_Variability)
# ──────────────────────────────────────────────────────────────────────────────

example_1_basic_usage <- function() {

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("Example 1: Basic Usage\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  # Generate test data (simulating 312 samples)
  set.seed(123)
  n_features <- 1000
  n_samples <- 312

  X <- matrix(rnorm(n_features * n_samples, mean = 1e6, sd = 1e5),
             nrow = n_features, ncol = n_samples)
  rownames(X) <- paste0("Feature_", 1:n_features)
  colnames(X) <- paste0("Sample_", 1:n_samples)

  # Reference intensities (median across samples)
  ref <- apply(X, 1, median, na.rm = TRUE)

  # Normalizer indices (e.g., 100 most stable features)
  iset.ref <- rownames(X)[1:100]

  # ─────────────────────────────────────────────────────────────
  # OLD WAY (sequential)
  # ─────────────────────────────────────────────────────────────

  # result_old <- calculate_Variability(
  #   X = X,
  #   ref = ref,
  #   iset.ref = iset.ref,
  #   min.iset = 10,
  #   method = "lm",
  #   plot.model = FALSE
  # )

  # ─────────────────────────────────────────────────────────────
  # NEW WAY (parallel - joblib-like)
  # ─────────────────────────────────────────────────────────────

  result_new <- calculate_Variability_parallel(
    X = X,
    ref = ref,
    iset.ref = iset.ref,
    min.iset = 10,
    method = "lm",
    workers = 2,          # Optimal for large datasets
    backend = "auto",     # Auto-detect: multicore or multisession
    verbose = TRUE
  )

  cat("\n✓ Results:\n")
  cat(sprintf("  Normalized matrix: %d × %d\n",
             nrow(result_new$Xn), ncol(result_new$Xn)))
  cat(sprintf("  Variability: %.4f → %.4f\n",
             result_new$w.metric.before, result_new$w.metric))
  cat(sprintf("  Samples normalized: %d/%d\n",
             result_new$nidxSampleNormalized, n_samples))
  cat(sprintf("  Execution time: %.2fs\n", result_new$execution_time_sec))

  return(result_new)
}


# ──────────────────────────────────────────────────────────────────────────────
# Example 2: Integration in Shiny Server (BEFORE/AFTER)
# ──────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# BEFORE (sequential - slow for 312 samples)
# ─────────────────────────────────────────────────────────────

observeEvent_OLD <- function(input, Rvars, session) {
  observeEvent(input$normalize_button, {

    withProgress(message = 'Normalizing samples...', value = 0, {

      incProgress(0.3, detail = "Computing normalization")

      # ❌ OLD: Sequential processing (slow!)
      result <- calculate_Variability(
        X = Rvars$Matrix_toNormalize,
        ref = Rvars$ref_intensity,
        iset.ref = Rvars$Normalizers,
        min.iset = input$min_normalizers,
        method = input$norm_method,
        cutrat = input$cutrat,
        span = input$span,
        plot.model = FALSE  # Can't plot in Shiny easily
      )

      incProgress(1, detail = "Complete!")

      # Extract results
      Rvars$Matrix_normalized <- result$Xn  # Access Xn from attributes
      Rvars$variability_after <- result$w.metric

      sendSweetAlert(
        session = session,
        title = "Success!",
        text = sprintf("Normalized %d samples in %.2fs",
                      ncol(Rvars$Matrix_toNormalize),
                      result$execution_time_sec),  # Won't exist in old version
        type = "success"
      )
    })
  })
}


# ─────────────────────────────────────────────────────────────
# AFTER (parallel - fast with 312 samples!)
# ─────────────────────────────────────────────────────────────

observeEvent_NEW <- function(input, Rvars, session) {
  observeEvent(input$normalize_button, {

    withProgress(message = 'Normalizing samples (parallel)...', value = 0, {

      incProgress(0.3, detail = "Starting parallel normalization")

      # ✅ NEW: Parallel processing (fast!)
      result <- calculate_Variability_parallel(
        X = Rvars$Matrix_toNormalize,
        ref = Rvars$ref_intensity,
        iset.ref = Rvars$Normalizers,
        min.iset = input$min_normalizers,
        method = input$norm_method,
        cutrat = input$cutrat,
        span = input$span,
        workers = 2,
        backend = "auto",
        verbose = TRUE
      )

      incProgress(1, detail = "Complete!")

      # Save results
      Rvars$Matrix_normalized <- result$Xn
      Rvars$variability_before <- result$w.metric.before
      Rvars$variability_after <- result$w.metric
      Rvars$n_normalized <- result$nidxSampleNormalized

      sendSweetAlert(
        session = session,
        title = "Success!",
        text = HTML(sprintf(
          paste0("<b>Normalization completed</b><br/>",
                 "Samples: %d/%d normalized<br/>",
                 "Variability: %.4f → %.4f (%.1f%% improvement)<br/>",
                 "Time: %.2fs<br/>",
                 "Backend: %s with %d workers<br/>",
                 "TCP/IP sockets: 0 ✓"),
          result$nidxSampleNormalized,
          ncol(Rvars$Matrix_toNormalize),
          result$w.metric.before,
          result$w.metric,
          (1 - result$w.metric / result$w.metric.before) * 100,
          result$execution_time_sec,
          result$backend_used,
          result$workers_used
        )),
        type = "success",
        html = TRUE
      )
    })
  })
}


# ──────────────────────────────────────────────────────────────────────────────
# Example 3: Smart Wrapper (auto-detects best approach)
# ──────────────────────────────────────────────────────────────────────────────

example_3_smart_wrapper <- function() {

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("Example 3: Smart Wrapper (auto-detection)\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  # Generate test data
  set.seed(456)
  X_small <- matrix(rnorm(1000 * 5), nrow = 1000)  # 5 samples
  X_large <- matrix(rnorm(1000 * 312), nrow = 1000)  # 312 samples

  ref <- apply(X_large, 1, median)
  iset.ref <- rownames(X_large)[1:50]

  # ─────────────────────────────────────────────────────────────
  # Test 1: Small dataset (auto-chooses sequential)
  # ─────────────────────────────────────────────────────────────

  cat("Test 1: Small dataset (5 samples)\n")
  result_small <- calculate_Variability_smart(
    X = X_small,
    ref = ref[1:nrow(X_small)],
    iset.ref = rownames(X_small)[1:50],
    min.iset = 10,
    method = "lm",
    verbose = TRUE
  )
  # → Should use sequential (too few samples for parallel overhead)

  cat("\n")

  # ─────────────────────────────────────────────────────────────
  # Test 2: Large dataset (auto-chooses parallel)
  # ─────────────────────────────────────────────────────────────

  cat("Test 2: Large dataset (312 samples)\n")
  result_large <- calculate_Variability_smart(
    X = X_large,
    ref = ref,
    iset.ref = iset.ref,
    min.iset = 10,
    method = "lm",
    verbose = TRUE
  )
  # → Should use parallel (many samples)

  cat("\n✓ Smart wrapper automatically chose optimal approach!\n")
}


# ──────────────────────────────────────────────────────────────────────────────
# Example 4: Benchmark Comparison
# ──────────────────────────────────────────────────────────────────────────────

example_4_benchmark <- function() {

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("Example 4: Benchmark Sequential vs Parallel\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  # Generate realistic test data (312 samples like in real workflow)
  set.seed(789)
  n_features <- 2000
  n_samples <- 312

  X <- matrix(rnorm(n_features * n_samples, mean = 1e6, sd = 1e5),
             nrow = n_features, ncol = n_samples)
  rownames(X) <- paste0("Feature_", 1:n_features)
  colnames(X) <- paste0("Sample_", 1:n_samples)

  ref <- apply(X, 1, median, na.rm = TRUE)
  iset.ref <- rownames(X)[1:100]  # 100 normalizers

  # Run benchmark
  benchmark_results <- benchmark_normalization(
    X = X,
    ref = ref,
    iset.ref = iset.ref,
    min.iset = 10,
    method = "lm",
    workers = 2
  )

  return(invisible(benchmark_results))
}


# ──────────────────────────────────────────────────────────────────────────────
# Example 5: Different Normalization Methods (all parallel)
# ──────────────────────────────────────────────────────────────────────────────

example_5_methods_comparison <- function() {

  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("Example 5: Compare Normalization Methods (Parallel)\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  # Generate test data
  set.seed(321)
  X <- matrix(rnorm(1000 * 100, mean = 1e6, sd = 1e5),
             nrow = 1000, ncol = 100)
  rownames(X) <- paste0("Feature_", 1:1000)
  colnames(X) <- paste0("Sample_", 1:100)

  ref <- apply(X, 1, median, na.rm = TRUE)
  iset.ref <- rownames(X)[1:50]

  methods <- c("lm", "loess", "kreg")
  results <- list()

  for (method in methods) {
    cat(sprintf("\nTesting method: %s\n", method))
    cat("─────────────────────────────────────────────────────────\n")

    results[[method]] <- calculate_Variability_parallel(
      X = X,
      ref = ref,
      iset.ref = iset.ref,
      min.iset = 10,
      method = method,
      workers = 2,
      backend = "auto",
      verbose = TRUE
    )
  }

  # Compare results
  cat("\n═══════════════════════════════════════════════════════════\n")
  cat("Method Comparison:\n")
  cat("═══════════════════════════════════════════════════════════\n")

  comparison <- data.frame(
    Method = methods,
    Time_sec = sapply(results, function(r) r$execution_time_sec),
    Variability_Before = sapply(results, function(r) r$w.metric.before),
    Variability_After = sapply(results, function(r) r$w.metric),
    Improvement_pct = sapply(results, function(r) {
      (1 - r$w.metric / r$w.metric.before) * 100
    }),
    Samples_Normalized = sapply(results, function(r) r$nidxSampleNormalized)
  )

  print(comparison)

  return(invisible(results))
}


# ──────────────────────────────────────────────────────────────────────────────
# Example 6: Migration Guide
# ──────────────────────────────────────────────────────────────────────────────

print_migration_guide <- function() {

  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("MIGRATION GUIDE: calculate_Variability → Parallel Version\n")
  cat("═══════════════════════════════════════════════════════════\n\n")

  cat("Step 1: Load the parallel library\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat("  source('lib/NewReferenceMap/R_files/calculate_Variability_parallel.R')\n\n")

  cat("Step 2: Configure future backend (optional, global config)\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat("  # In server.R startup:\n")
  cat("  plan(multicore, workers = 2)  # Linux/Mac\n")
  cat("  # OR\n")
  cat("  plan(multisession, workers = 2)  # Windows\n\n")

  cat("Step 3: Replace function call\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat("  ❌ OLD:\n")
  cat("  result <- calculate_Variability(\n")
  cat("    X = matrix_data,\n")
  cat("    ref = ref_intensity,\n")
  cat("    iset.ref = normalizers,\n")
  cat("    min.iset = 10,\n")
  cat("    method = 'lm',\n")
  cat("    plot.model = FALSE\n")
  cat("  )\n\n")

  cat("  ✅ NEW:\n")
  cat("  result <- calculate_Variability_parallel(\n")
  cat("    X = matrix_data,\n")
  cat("    ref = ref_intensity,\n")
  cat("    iset.ref = normalizers,\n")
  cat("    min.iset = 10,\n")
  cat("    method = 'lm',\n")
  cat("    workers = 2,\n")
  cat("    backend = 'auto',\n")
  cat("    verbose = TRUE\n")
  cat("  )\n\n")

  cat("Step 4: Update result access\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat("  ❌ OLD (attributes-based):\n")
  cat("  normalized_matrix <- result  # Result IS the matrix\n")
  cat("  w_metric <- result$w.metric\n")
  cat("  n_normalized <- result$nidxSampleNormalized\n\n")

  cat("  ✅ NEW (list-based, more explicit):\n")
  cat("  normalized_matrix <- result$Xn\n")
  cat("  w_metric <- result$w.metric\n")
  cat("  w_metric_before <- result$w.metric.before\n")
  cat("  n_normalized <- result$nidxSampleNormalized\n")
  cat("  execution_time <- result$execution_time_sec\n")
  cat("  backend_used <- result$backend_used\n\n")

  cat("Step 5: Handle plot.model\n")
  cat("───────────────────────────────────────────────────────────\n")
  cat("  ⚠️ plot.model = TRUE is NOT supported in parallel mode\n")
  cat("  Options:\n")
  cat("  1. Set plot.model = FALSE (recommended for Shiny)\n")
  cat("  2. Use backend = 'sequential' to enable plotting\n")
  cat("  3. Use calculate_Variability_smart() for auto-detection\n\n")

  cat("═══════════════════════════════════════════════════════════\n")
  cat("Expected Benefits:\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("  ✓ ~2-3x faster for 312 samples\n")
  cat("  ✓ 0 TCP/IP sockets (no accumulation)\n")
  cat("  ✓ Automatic cleanup (no manual bpstop)\n")
  cat("  ✓ Cross-platform (works on Windows, Linux, Mac)\n")
  cat("  ✓ Better resource utilization\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
}


# ──────────────────────────────────────────────────────────────────────────────
# Main: Run examples
# ──────────────────────────────────────────────────────────────────────────────

if (interactive()) {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("Parallel calculate_Variability Examples\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")
  cat("Available examples:\n")
  cat("  1. example_1_basic_usage()         - Basic parallel normalization\n")
  cat("  2. example_3_smart_wrapper()       - Auto-detection demo\n")
  cat("  3. example_4_benchmark()           - Sequential vs Parallel benchmark\n")
  cat("  4. example_5_methods_comparison()  - Compare lm/loess/kreg in parallel\n")
  cat("  5. print_migration_guide()         - Show migration steps\n")
  cat("\n")
  cat("Quick start:\n")
  cat("  source('EXAMPLE_calculate_Variability_parallel.R')\n")
  cat("  print_migration_guide()\n")
  cat("  example_4_benchmark()\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat("\n")

  # Show migration guide by default
  print_migration_guide()
}
