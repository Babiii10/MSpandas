# ══════════════════════════════════════════════════════════════════════════════
# Parallel version of calculate_Variability (joblib-like approach)
# ══════════════════════════════════════════════════════════════════════════════
#
# Original function: calculate_Variability
# Problem: Sequential for-loop over samples (for i in 1:ncol(X))
# Solution: Parallelize with future (like joblib.Parallel in Python)
#
# Each sample is normalized independently → perfect for parallelization
#
# ══════════════════════════════════════════════════════════════════════════════

library(future)
library(future.apply)

# ──────────────────────────────────────────────────────────────────────────────
# Helper function: Normalize a single sample
# ──────────────────────────────────────────────────────────────────────────────

normalize_single_sample <- function(sample_idx, X, ref, iset.ref, min.iset,
                                   cutrat, method, span, log.scaled) {

  # Extract sample data
  sample_data <- X[, sample_idx]

  # Filter normalizers based on cutrat
  if (!is.null(cutrat)) {
    iset <- iset.ref[which(abs(X[iset.ref, sample_idx] - ref[iset.ref]) <= cutrat)]
  } else {
    iset <- iset.ref
  }

  # Get non-NA indices
  idx_No_NA <- names(sample_data[!is.na(sample_data)])
  iset_No_NA <- names(X[iset, sample_idx][!is.na(X[iset, sample_idx])])

  # Initialize result
  result <- list(
    Xn_column = rep(NA, nrow(X)),
    normalized = FALSE,
    iset_used = iset_No_NA,
    adj_r_squared = 0
  )
  names(result$Xn_column) <- rownames(X)

  # Check if we have enough normalizers
  if (length(iset_No_NA) < min.iset) {
    # Not enough normalizers: no normalization
    result$Xn_column[idx_No_NA] <- sample_data[idx_No_NA]
    return(result)
  }

  # Enough normalizers: proceed with normalization
  a <- X[iset_No_NA, sample_idx]
  m <- ref[iset_No_NA]

  # ═══════════════════════════════════════════════════════════
  # Apply normalization method
  # ═══════════════════════════════════════════════════════════

  if (method == "lm") {
    # Linear model
    model_lm <- lm(m ~ a)
    pred <- model_lm$coefficients[1] + model_lm$coefficients[2] * sample_data[idx_No_NA]

    result$Xn_column[idx_No_NA] <- pred
    result$normalized <- TRUE
    result$adj_r_squared <- summary(model_lm)$adj.r.squared

  } else if (method == "loess") {
    # LOESS model
    model_loess <- loess(m ~ a, data.frame(a = a, m = m),
                        span = span, degree = 1, family = "symmetric")
    pred <- predict(model_loess, newdata = sample_data[idx_No_NA])

    result$Xn_column[idx_No_NA] <- pred
    result$normalized <- TRUE

  } else if (method == "kreg") {
    # Kernel regression
    if (!requireNamespace("np", quietly = TRUE)) {
      stop("Package 'np' required for method='kreg'. Install with: install.packages('np')")
    }

    data_model <- data.frame(a = a, m = m)
    model.np <- np::npreg(m ~ a,
                         bws = 15,
                         bwtype = "fixed",
                         regtype = "ll",
                         ckertype = "gaussian",
                         gradients = TRUE,
                         data = data_model)

    pred <- predict(model.np, newdata = data.frame(a = sample_data[idx_No_NA]))

    result$Xn_column[idx_No_NA] <- pred
    result$normalized <- TRUE
  }

  return(result)
}


# ──────────────────────────────────────────────────────────────────────────────
# Main parallel function
# ──────────────────────────────────────────────────────────────────────────────

#' Calculate Variability with Parallel Backend (joblib-like)
#'
#' @description
#' Parallel version of calculate_Variability using future backend.
#' Each sample is normalized independently in parallel.
#'
#' Equivalent to Python's:
#' joblib.Parallel(n_jobs=workers, backend='loky')(
#'   delayed(normalize_sample)(i) for i in range(n_samples)
#' )
#'
#' @param X Matrix to normalize (features × samples)
#' @param ref Reference intensity vector (optional, computed if missing)
#' @param iset.ref Indices of normalizers in reference
#' @param min.iset Minimum number of normalizers required
#' @param span LOESS span parameter (default: 0.75)
#' @param extrap Extrapolation flag (not used in parallel version)
#' @param cutrat Cutoff ratio for normalizer filtering (default: 2)
#' @param method Normalization method: "lm", "loess", or "kreg"
#' @param plot.model If TRUE, creates diagnostic plots (DISABLED in parallel mode)
#' @param out.scale Output scale: "log2" or "natural"
#' @param workers Number of parallel workers (NULL = auto-detect)
#' @param backend "auto", "multicore", "multisession", or "sequential"
#' @param verbose Print progress information
#'
#' @return List with:
#'   - Xn: Normalized matrix
#'   - w.metric: Variability metric (MAD)
#'   - w.metric.before: Variability before normalization
#'   - nidxSampleNormalized: Number of samples normalized
#'   - nbr_pep_normalizers: Median number of normalizers used
#'   - execution_time_sec: Execution time
#'   - backend_used: Parallel backend used
#'
#' @examples
#' result <- calculate_Variability_parallel(
#'   X = expression_matrix,
#'   ref = reference_intensities,
#'   iset.ref = normalizer_indices,
#'   min.iset = 10,
#'   method = "lm",
#'   workers = 2
#' )
#'
#' @export
calculate_Variability_parallel <- function(X,
                                          ref,
                                          iset.ref,
                                          min.iset,
                                          span = 0.75,
                                          extrap = TRUE,
                                          cutrat = 2,
                                          method = c("lm", "loess", "kreg"),
                                          plot.model = FALSE,
                                          out.scale = c("log2", "natural"),
                                          workers = NULL,
                                          backend = c("auto", "multicore", "multisession", "sequential"),
                                          verbose = TRUE) {

  # ═══════════════════════════════════════════════════════════
  # 1. Input validation and preprocessing
  # ═══════════════════════════════════════════════════════════

  if (is.vector(X)) {
    X <- as.matrix(X)
  }

  method <- tolower(method[1])
  out.scale <- tolower(out.scale[1])
  backend <- match.arg(backend)

  start_time <- Sys.time()

  # Log transformation if needed
  if (max(X, na.rm = TRUE) > 107) {
    log.scaled <- FALSE
    X <- log2(X)
    if (verbose) cat("Applied log2 transformation\n")
  } else {
    log.scaled <- TRUE
  }

  # Compute reference if missing
  if (missing(ref)) {
    ref <- apply(X, 1, function(x) median(x, na.rm = TRUE))
    if (verbose) cat("Computed reference intensities\n")
  }

  if (max(ref, na.rm = TRUE) > 107) {
    ref <- log2(ref)
  }

  # ═══════════════════════════════════════════════════════════
  # 2. Handle plot.model
  # ═══════════════════════════════════════════════════════════

  if (plot.model && ncol(X) > 1) {
    warning(paste(
      "plot.model=TRUE is not supported in parallel mode.",
      "Setting plot.model=FALSE for parallel execution.",
      "Use sequential backend to enable plotting."
    ))
    plot.model <- FALSE
  }

  # ═══════════════════════════════════════════════════════════
  # 3. Configure parallel backend
  # ═══════════════════════════════════════════════════════════

  n_samples <- ncol(X)
  matrix_size_mb <- as.numeric(object.size(X)) / 1024^2

  if (verbose) {
    cat("═══════════════════════════════════════════════════════════\n")
    cat("Calculate Variability (Parallel - joblib-like)\n")
    cat("═══════════════════════════════════════════════════════════\n")
    cat(sprintf("Matrix: %d features × %d samples (%.1f MB)\n",
               nrow(X), n_samples, matrix_size_mb))
    cat(sprintf("Method: %s\n", method))
    cat(sprintf("Min normalizers: %d\n", min.iset))
    cat("───────────────────────────────────────────────────────────\n")
  }

  # Auto-configure workers
  if (is.null(workers)) {
    if (n_samples >= 300 || matrix_size_mb > 100) {
      workers <- 2
    } else if (n_samples >= 150) {
      workers <- 3
    } else {
      workers <- min(4, availableCores() - 1)
    }

    if (verbose) {
      cat(sprintf("Auto-configured workers: %d\n", workers))
    }
  }

  # Configure backend
  old_plan <- plan()
  on.exit(plan(old_plan), add = TRUE)

  if (backend == "auto") {
    if (.Platform$OS.type == "unix") {
      plan(multicore, workers = workers)
      backend_name <- "multicore (fork-based, no sockets)"
    } else {
      plan(multisession, workers = workers)
      backend_name <- "multisession (Windows compatible)"
    }
  } else if (backend == "multicore") {
    if (.Platform$OS.type != "unix") {
      warning("multicore not supported on Windows, using multisession")
      plan(multisession, workers = workers)
      backend_name <- "multisession (fallback)"
    } else {
      plan(multicore, workers = workers)
      backend_name <- "multicore"
    }
  } else if (backend == "multisession") {
    plan(multisession, workers = workers)
    backend_name <- "multisession"
  } else {
    plan(sequential)
    backend_name <- "sequential (no parallelization)"
    workers <- 1
  }

  if (verbose) {
    cat(sprintf("Backend: %s with %d workers\n", backend_name, workers))
    cat("───────────────────────────────────────────────────────────\n")
  }

  # ═══════════════════════════════════════════════════════════
  # 4. PARALLEL EXECUTION (joblib-like)
  # ═══════════════════════════════════════════════════════════

  if (verbose) cat("Normalizing samples in parallel...\n")

  parallel_start <- Sys.time()

  # Parallel normalization of all samples
  # Equivalent to: joblib.Parallel(n_jobs=workers)(delayed(normalize)(i) for i in samples)
  sample_results <- future_lapply(1:n_samples, function(i) {
    normalize_single_sample(
      sample_idx = i,
      X = X,
      ref = ref,
      iset.ref = iset.ref,
      min.iset = min.iset,
      cutrat = cutrat,
      method = method,
      span = span,
      log.scaled = log.scaled
    )
  }, future.seed = TRUE)

  parallel_elapsed <- as.numeric(difftime(Sys.time(), parallel_start, units = "secs"))

  if (verbose) {
    cat(sprintf("✓ Parallel normalization: %.2fs\n", parallel_elapsed))
    cat(sprintf("  Throughput: %.1f samples/second\n", n_samples / parallel_elapsed))
  }

  # ═══════════════════════════════════════════════════════════
  # 5. Aggregate results
  # ═══════════════════════════════════════════════════════════

  if (verbose) cat("Aggregating results...\n")

  # Initialize normalized matrix
  Xn <- matrix(NA, nrow(X), ncol(X))
  rownames(Xn) <- rownames(X)
  colnames(Xn) <- colnames(X)

  # Collect results
  iset.i <- list()
  adj.r.squared <- numeric(n_samples)
  idxSampleNormalized <- NULL

  for (i in 1:n_samples) {
    result <- sample_results[[i]]

    # Fill normalized matrix
    Xn[, i] <- result$Xn_column

    # Track normalized samples
    if (result$normalized) {
      idxSampleNormalized <- c(idxSampleNormalized, i)
    }

    # Store normalizer info
    iset.i[[i]] <- result$iset_used

    # Store adj.r.squared (for lm method)
    if (method == "lm") {
      adj.r.squared[i] <- result$adj_r_squared
    }
  }

  # ═══════════════════════════════════════════════════════════
  # 6. Compute variability metrics
  # ═══════════════════════════════════════════════════════════

  if (method == "lm") {
    names(adj.r.squared) <- colnames(Xn)
    attr(Xn, "adj.r.squared") <- adj.r.squared
  }

  # Compute MAD (median absolute deviation) as variability metric
  if (!is.null(idxSampleNormalized) && length(idxSampleNormalized) > 0) {
    if (length(idxSampleNormalized) > 1) {
      w.metric <- mad(apply(Xn[, idxSampleNormalized, drop = FALSE], 2,
                           median, na.rm = TRUE), na.rm = TRUE)
      w.metric.before <- mad(apply(X[, idxSampleNormalized, drop = FALSE], 2,
                                   median, na.rm = TRUE), na.rm = TRUE)
    } else {
      # Only 1 sample normalized
      w.metric <- 0
      w.metric.before <- 0
    }
  } else {
    w.metric <- NA
    w.metric.before <- NA
  }

  # Store attributes
  attr(Xn, "nbr_pep_normalizers") <- lapply(iset.i, length)
  attr(Xn, "idX_normalizers") <- iset.i

  total_elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # ═══════════════════════════════════════════════════════════
  # 7. Return results
  # ═══════════════════════════════════════════════════════════

  result <- list(
    Xn = Xn,
    w.metric = w.metric,
    w.metric.before = w.metric.before,
    nidxSampleNormalized = length(idxSampleNormalized),
    nbr_pep_normalizers = median(unlist(attr(Xn, "nbr_pep_normalizers"))),
    execution_time_sec = total_elapsed,
    parallel_time_sec = parallel_elapsed,
    backend_used = backend_name,
    workers_used = workers,
    samples_normalized = idxSampleNormalized
  )

  if (verbose) {
    cat("═══════════════════════════════════════════════════════════\n")
    cat("✓ Normalization completed!\n")
    cat(sprintf("  Samples normalized: %d/%d (%.1f%%)\n",
               result$nidxSampleNormalized, n_samples,
               result$nidxSampleNormalized / n_samples * 100))
    cat(sprintf("  Median normalizers/sample: %.0f\n", result$nbr_pep_normalizers))
    cat(sprintf("  Variability before: %.4f\n", w.metric.before))
    cat(sprintf("  Variability after: %.4f\n", w.metric))
    if (!is.na(w.metric) && !is.na(w.metric.before) && w.metric.before > 0) {
      cat(sprintf("  Improvement: %.1f%%\n",
                 (1 - w.metric / w.metric.before) * 100))
    }
    cat(sprintf("  Total time: %.2fs\n", total_elapsed))
    cat(sprintf("  Parallel efficiency: %.1f%%\n",
               (parallel_elapsed / total_elapsed) * 100))
    cat(sprintf("  Backend: %s\n", backend_name))
    cat("═══════════════════════════════════════════════════════════\n")
  }

  return(result)
}


# ──────────────────────────────────────────────────────────────────────────────
# Wrapper for backward compatibility
# ──────────────────────────────────────────────────────────────────────────────

#' Calculate Variability (automatically chooses parallel or sequential)
#'
#' @description
#' Smart wrapper that automatically chooses parallel or sequential execution
#' based on data size and plot.model parameter.
#'
#' @inheritParams calculate_Variability_parallel
#'
#' @export
calculate_Variability_smart <- function(X,
                                       ref,
                                       iset.ref,
                                       min.iset,
                                       span = 0.75,
                                       extrap = TRUE,
                                       cutrat = 2,
                                       method = c("lm", "loess", "kreg"),
                                       plot.model = FALSE,
                                       out.scale = c("log2", "natural"),
                                       workers = NULL,
                                       verbose = TRUE) {

  n_samples <- ncol(as.matrix(X))

  # Decide: parallel or sequential
  if (plot.model) {
    # Plotting requires sequential
    if (verbose) cat("Using sequential mode (plot.model=TRUE)\n")
    backend <- "sequential"
  } else if (n_samples < 10) {
    # Too few samples for parallel overhead
    if (verbose) cat("Using sequential mode (few samples)\n")
    backend <- "sequential"
  } else {
    # Use parallel
    if (verbose) cat("Using parallel mode\n")
    backend <- "auto"
  }

  result <- calculate_Variability_parallel(
    X = X,
    ref = ref,
    iset.ref = iset.ref,
    min.iset = min.iset,
    span = span,
    extrap = extrap,
    cutrat = cutrat,
    method = method,
    plot.model = plot.model,
    out.scale = out.scale,
    workers = workers,
    backend = backend,
    verbose = verbose
  )

  return(result)
}


# ──────────────────────────────────────────────────────────────────────────────
# Benchmark function
# ──────────────────────────────────────────────────────────────────────────────

#' Benchmark sequential vs parallel normalization
#'
#' @param X Test matrix
#' @param ref Reference vector
#' @param iset.ref Normalizer indices
#' @param min.iset Minimum normalizers
#' @param method Normalization method
#' @param workers Number of workers for parallel
#'
#' @export
benchmark_normalization <- function(X, ref, iset.ref, min.iset,
                                   method = "lm", workers = 2) {

  cat("═══════════════════════════════════════════════════════════\n")
  cat("Benchmark: Sequential vs Parallel Normalization\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat(sprintf("Matrix: %d × %d\n", nrow(X), ncol(X)))
  cat(sprintf("Method: %s\n", method))
  cat("───────────────────────────────────────────────────────────\n")

  # Sequential
  cat("Testing SEQUENTIAL...\n")
  time_seq_start <- Sys.time()
  result_seq <- calculate_Variability_parallel(
    X = X, ref = ref, iset.ref = iset.ref, min.iset = min.iset,
    method = method, backend = "sequential", verbose = FALSE
  )
  time_seq <- as.numeric(difftime(Sys.time(), time_seq_start, units = "secs"))

  # Parallel
  cat("Testing PARALLEL...\n")
  time_par_start <- Sys.time()
  result_par <- calculate_Variability_parallel(
    X = X, ref = ref, iset.ref = iset.ref, min.iset = min.iset,
    method = method, backend = "auto", workers = workers, verbose = FALSE
  )
  time_par <- as.numeric(difftime(Sys.time(), time_par_start, units = "secs"))

  # Results
  cat("═══════════════════════════════════════════════════════════\n")
  cat("Results:\n")
  cat("═══════════════════════════════════════════════════════════\n")
  cat(sprintf("Sequential time:  %.2fs\n", time_seq))
  cat(sprintf("Parallel time:    %.2fs (with %d workers)\n", time_par, workers))
  cat(sprintf("Speedup:          %.2fx\n", time_seq / time_par))
  cat(sprintf("Time saved:       %.2fs (%.1f%% faster)\n",
             time_seq - time_par, (1 - time_par / time_seq) * 100))
  cat("───────────────────────────────────────────────────────────\n")
  cat(sprintf("Samples normalized: %d/%d\n",
             result_par$nidxSampleNormalized, ncol(X)))
  cat(sprintf("Variability: %.4f → %.4f\n",
             result_par$w.metric.before, result_par$w.metric))
  cat("═══════════════════════════════════════════════════════════\n")

  return(invisible(list(
    time_sequential = time_seq,
    time_parallel = time_par,
    speedup = time_seq / time_par,
    result_sequential = result_seq,
    result_parallel = result_par
  )))
}
