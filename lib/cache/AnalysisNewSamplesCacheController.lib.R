# ===============================================================================
# AnalysisNewSamplesCacheController.lib.R
# Unified Cache Controller for the Analysis New Samples Pipeline
# ===============================================================================
#
# Description: Provides a centralized controller for managing caches across all
#              pipeline stages of the Analysis New Samples workflow.
#              Mirrors the architecture of GlobalCacheController.lib.R
#
# Pipeline Stages Covered:
#   1. Peak Detection       - After MSDIAL peak picking + deconvolution
#   2. Temporal Correction  - After Kernel Density correction
#   3. Feature Grouping     - After feature grouping within samples
#   4. Match Reference      - After matching against reference map
#   5. Normalization        - After intensity normalization
#
# ===============================================================================

library(shiny)

# Source cache libraries (reuse existing infrastructure)
if (!exists("init_cache_system") ||
    !is.function(init_cache_system) ||
    !"reuse_existing" %in% names(formals(init_cache_system))) {
  source("lib/cache/CacheManager.lib.R")
}
if (!exists("detect_crash_and_recover")) {
  source("lib/cache/RecoveryManager.lib.R")
}
if (!exists("show_recovery_modal")) {
  source("lib/cache/ShinyIntegration.lib.R")
}
if (!exists("save_checkpoint_enhanced")) {
  source("lib/cache/EnhancedCacheManager.lib.R")
}

# ===============================================================================
# PIPELINE STAGE DEFINITIONS - Analysis New Samples
# ===============================================================================

ANS_PIPELINE_STAGES <- list(
  ans_peak_detection = list(
    id = "ans_step_01_peak_detection",
    name = "Peak Detection (New Samples)",
    description = "MSDIAL peak picking and deconvolution complete",
    next_step = "ans_temporal_correction"
  ),
  ans_temporal_correction = list(
    id = "ans_step_02_temporal_correction",
    name = "Temporal Correction (New Samples)",
    description = "Kernel Density correction complete",
    next_step = "ans_grouping"
  ),
  ans_grouping = list(
    id = "ans_step_03_grouping",
    name = "Feature Grouping (New Samples)",
    description = "Feature grouping within samples complete",
    next_step = "ans_match_reference"
  ),
  ans_match_reference = list(
    id = "ans_step_04_match_reference",
    name = "Match Reference Map",
    description = "Matching against reference map complete",
    next_step = "ans_normalization"
  ),
  ans_normalization = list(
    id = "ans_step_05_normalization",
    name = "Normalization (New Samples)",
    description = "Intensity normalization complete",
    next_step = "complete"
  )
)

# ===============================================================================
# create_ans_cache_controller - Main Controller for Analysis New Samples
# ===============================================================================

create_ans_cache_controller <- function(project_name,
                                        data_dir,
                                        base_cache_dir = "cache_projects_ans",
                                        config = NULL) {

  state <- new.env(parent = emptyenv())
  state$initialized <- FALSE
  state$cache_info <- NULL
  state$current_stage <- NULL
  state$completed_stages <- character(0)
  state$project_name <- project_name

  state$config <- if (!is.null(config)) {
    modifyList(CACHE_CONFIG_DEFAULTS, config)
  } else {
    CACHE_CONFIG_DEFAULTS
  }

  state$logger <- NULL

  # =========================================================================
  # initialize
  # =========================================================================
  initialize <- function(n_samples = NULL, verbose = TRUE, reuse_existing = TRUE) {

    if (verbose) {
      cat("\n")
      cat("================================================================\n")
      cat("   ANS Cache Controller v3.0 - Analysis New Samples\n")
      cat("================================================================\n")
      cat(sprintf("   Project: %s\n", project_name))
      cat(sprintf("   Data dir: %s\n", data_dir))
    }

    state$cache_info <- init_cache_system(
      project_name = project_name,
      data_dir = data_dir,
      base_cache_dir = base_cache_dir,
      reuse_existing = reuse_existing
    )

    if (state$config$enable_logging) {
      log_file <- file.path(state$cache_info$project_dir, "cache_ans.log")
      state$logger <- create_cache_logger(
        log_file = log_file,
        db_path = state$cache_info$db_path
      )
      state$logger$info("INIT", "ANS Cache controller initialized",
                        project_id = state$cache_info$project_id)
    }

    if (state$config$auto_cleanup) {
      tryCatch({
        cleanup_result <- auto_cleanup_cache(
          base_cache_dir = base_cache_dir,
          config = state$config,
          dry_run = FALSE
        )
        if (length(cleanup_result$deleted_projects) > 0 && verbose) {
          cat(sprintf("   Auto-cleanup: removed %d old project(s)\n",
                      length(cleanup_result$deleted_projects)))
        }
      }, error = function(e) {
        if (verbose) cat("   Auto-cleanup skipped:", e$message, "\n")
      })
    }

    if (!is.null(n_samples) && !is.null(state$cache_info$db_project_id)) {
      tryCatch({
        con <- DBI::dbConnect(RSQLite::SQLite(), state$cache_info$db_path)
        DBI::dbExecute(con,
                       "UPDATE projects SET total_files = ? WHERE project_id = ?",
                       params = list(n_samples, state$cache_info$db_project_id))
        DBI::dbDisconnect(con)
      }, error = function(e) {
        warning("Could not update sample count: ", e$message)
      })
    }

    state$initialized <- TRUE
    state$current_stage <- "initialized"

    if (verbose) {
      cat("   Status: INITIALIZED\n")
      cat("================================================================\n\n")
    }

    return(invisible(state$cache_info))
  }

  # =========================================================================
  # check_recovery
  # =========================================================================
  check_recovery <- function(verbose = TRUE) {
    recovery_info <- detect_crash_and_recover(
      cache_info = state$cache_info,
      project_name = project_name,
      verbose = verbose
    )
    return(recovery_info)
  }

  # =========================================================================
  # save_stage - Hierarchical save (cumulative: saves all data up to stage)
  # =========================================================================
  save_stage <- function(stage_key, reactive_vars, progress = NULL, verbose = TRUE) {

    if (!state$initialized) {
      warning("ANS Cache controller not initialized. Call initialize() first.")
      return(FALSE)
    }

    if (!stage_key %in% names(ANS_PIPELINE_STAGES)) {
      stop(sprintf("Unknown ANS stage key: %s", stage_key))
    }

    stage_def <- ANS_PIPELINE_STAGES[[stage_key]]
    variables <- extract_ans_stage_variables(stage_key, reactive_vars)

    if (is.null(variables) || length(variables) == 0) {
      warning(sprintf("No variables to save for ANS stage: %s", stage_key))
      return(FALSE)
    }

    if (verbose) {
      cat(sprintf("\n   [ANS] Saving checkpoint: %s...\n", stage_def$name))
    }

    if (!is.null(progress)) {
      progress$set(message = sprintf("Saving: %s", stage_def$name), value = 0.3)
    }

    save_result <- save_checkpoint_enhanced(
      checkpoint_id = stage_def$id,
      cache_info = state$cache_info,
      variables = variables,
      step_name = stage_def$name,
      next_step = stage_def$next_step,
      config = state$config,
      logger = state$logger
    )

    if (save_result$success) {
      state$current_stage <- stage_key
      state$completed_stages <- unique(c(state$completed_stages, stage_key))

      if (!is.null(progress)) {
        progress$set(message = "Checkpoint saved!", value = 1)
      }

      if (verbose) {
        cat(sprintf("   [ANS] Checkpoint saved successfully!\n"))
        cat(sprintf("   Version: %d | Size: %.2f MB | Compression: %s\n",
                    save_result$version,
                    save_result$size_bytes / (1024^2),
                    save_result$compression))
      }

      return(TRUE)
    } else {
      if (verbose) {
        cat(sprintf("   [ANS] Failed to save checkpoint: %s\n", save_result$error))
      }
      return(FALSE)
    }
  }

  # =========================================================================
  # restore_stage - Restore a single stage
  # =========================================================================
  restore_stage <- function(stage_key, reactive_vars, progress = NULL,
                            version = NULL, verbose = TRUE) {

    if (!state$initialized && !is.null(state$cache_info)) {
      # Allow restore even if not fully initialized
    } else if (!state$initialized) {
      warning("ANS Cache controller not initialized.")
      return(FALSE)
    }

    if (!stage_key %in% names(ANS_PIPELINE_STAGES)) {
      stop(sprintf("Unknown ANS stage key: %s", stage_key))
    }

    stage_def <- ANS_PIPELINE_STAGES[[stage_key]]

    if (verbose) {
      cat(sprintf("\n   [ANS] Restoring checkpoint: %s...\n", stage_def$name))
    }

    if (!is.null(progress)) {
      progress$set(message = sprintf("Restoring: %s", stage_def$name), value = 0.2)
    }

    load_result <- load_checkpoint_enhanced(
      checkpoint_id = stage_def$id,
      cache_info = state$cache_info,
      version = version,
      validate_checksum = TRUE,
      logger = state$logger
    )

    if (!load_result$success) {
      warning(sprintf("Failed to restore ANS stage %s: %s", stage_key, load_result$error))
      return(FALSE)
    }

    if (!is.null(progress)) {
      progress$set(message = "Restoring variables...", value = 0.5)
    }

    restore_ans_stage_variables(stage_key, load_result$data, reactive_vars)

    state$current_stage <- stage_key
    state$completed_stages <- unique(c(state$completed_stages, stage_key))

    if (!is.null(progress)) {
      progress$set(message = "Restore complete!", value = 1)
    }

    if (verbose) {
      cat(sprintf("   [ANS] Restore successful!\n"))
      if (load_result$migrated) {
        cat(sprintf("   Note: Data migrated from schema v%s\n", load_result$original_version))
      }
    }

    return(TRUE)
  }

  # =========================================================================
  # restore_all_stages - Hierarchical restore up to target stage
  # =========================================================================
  restore_all_stages <- function(target_stage, reactive_vars, progress = NULL, verbose = TRUE) {

    stage_order <- names(ANS_PIPELINE_STAGES)
    target_idx <- which(stage_order == target_stage)

    if (length(target_idx) == 0) {
      warning(sprintf("Unknown target ANS stage: %s", target_stage))
      return(FALSE)
    }

    available <- list_available_stages()

    if (verbose) {
      cat("\n")
      cat("================================================================\n")
      cat("   [ANS] Restoring pipeline state\n")
      cat("================================================================\n")
      cat(sprintf("   Target stage: %s\n", target_stage))
      cat(sprintf("   Available stages: %s\n", paste(available, collapse = ", ")))
    }

    restored_count <- 0
    for (i in 1:target_idx) {
      stage_key <- stage_order[i]

      if (stage_key %in% available) {
        if (!is.null(progress)) {
          progress$set(
            message = sprintf("Restoring %s...", ANS_PIPELINE_STAGES[[stage_key]]$name),
            value = i / target_idx * 0.8
          )
        }

        result <- restore_stage(stage_key, reactive_vars, verbose = verbose)
        if (result) {
          restored_count <- restored_count + 1
        }
      }
    }

    if (!is.null(progress)) {
      progress$set(message = "Restoration complete!", value = 1)
    }

    if (verbose) {
      cat(sprintf("   Restored %d stage(s)\n", restored_count))
      cat("================================================================\n\n")
    }

    return(restored_count > 0)
  }

  # =========================================================================
  # list_available_stages
  # =========================================================================
  list_available_stages <- function() {

    if (is.null(state$cache_info) || !file.exists(state$cache_info$metadata_file)) {
      return(character(0))
    }

    metadata <- jsonlite::read_json(state$cache_info$metadata_file)
    saved_checkpoints <- names(metadata$checkpoints)

    available_stages <- character(0)
    for (stage_key in names(ANS_PIPELINE_STAGES)) {
      if (ANS_PIPELINE_STAGES[[stage_key]]$id %in% saved_checkpoints) {
        available_stages <- c(available_stages, stage_key)
      }
    }

    return(available_stages)
  }

  # =========================================================================
  # get_status
  # =========================================================================
  get_status <- function() {

    if (!state$initialized) {
      return(list(
        initialized = FALSE,
        project_name = project_name,
        current_stage = NULL,
        completed_stages = character(0),
        can_resume = FALSE,
        version = "3.0.0"
      ))
    }

    available <- list_available_stages()

    cache_size <- tryCatch({
      calculate_cache_size(dirname(state$cache_info$project_dir))
    }, error = function(e) {
      list(total_mb = NA, n_projects = NA)
    })

    return(list(
      initialized = TRUE,
      project_name = project_name,
      project_id = state$cache_info$project_id,
      cache_dir = state$cache_info$cache_dir,
      current_stage = state$current_stage,
      completed_stages = state$completed_stages,
      available_stages = available,
      can_resume = length(available) > 0,
      version = "3.0.0",
      config = state$config,
      total_cache_mb = cache_size$total_mb,
      n_projects = cache_size$n_projects
    ))
  }

  # =========================================================================
  # Utility accessors
  # =========================================================================
  get_cache_info <- function() {
    return(state$cache_info)
  }

  get_config <- function() {
    return(state$config)
  }

  update_config <- function(new_config) {
    state$config <- modifyList(state$config, new_config)
    if (!is.null(state$logger)) {
      state$logger$info("CONFIG_UPDATE", "ANS Configuration updated",
                        project_id = state$cache_info$project_id,
                        details = new_config)
    }
  }

  health_check <- function(repair = FALSE) {
    if (!state$initialized) {
      return(list(healthy = FALSE, issues = list("ANS Cache not initialized")))
    }
    result <- check_cache_health(state$cache_info, repair = repair)
    return(result)
  }

  mark_complete <- function() {
    if (!is.null(state$cache_info$db_project_id)) {
      tryCatch({
        update_project_status(
          project_id = state$cache_info$db_project_id,
          status = "completed",
          processing_stage = "complete",
          db_path = state$cache_info$db_path
        )
      }, error = function(e) {
        warning("Could not mark ANS project as complete: ", e$message)
      })
    }
  }

  # Return controller object
  return(list(
    initialize = initialize,
    check_recovery = check_recovery,
    save_stage = save_stage,
    restore_stage = restore_stage,
    restore_all_stages = restore_all_stages,
    list_available_stages = list_available_stages,
    get_status = get_status,
    get_cache_info = get_cache_info,
    get_config = get_config,
    update_config = update_config,
    health_check = health_check,
    mark_complete = mark_complete,
    STAGES = ANS_PIPELINE_STAGES,
    VERSION = "3.0.0"
  ))
}


# ===============================================================================
# HELPER FUNCTIONS - Variable Extraction and Restoration
# ===============================================================================

#' Extract variables for a specific Analysis New Samples pipeline stage
#' Hierarchical: each stage includes all variables from previous stages
extract_ans_stage_variables <- function(stage_key, reactive_vars) {

  vars <- list()

  RvarsPeakDetection <- reactive_vars$PeakDetection
  RvarsMatch <- reactive_vars$Match
  RvarsNormalize <- reactive_vars$Normalize

  switch(stage_key,

    # =======================================================================
    # Stage 1: Peak Detection + Deconvolution
    # =======================================================================
    "ans_peak_detection" = {
      if (!is.null(RvarsPeakDetection)) {
        vars$Project_Name <- isolate(RvarsPeakDetection$Project_Name)
        vars$peaks_MSDIAL_mono_iso_newSample <- isolate(RvarsPeakDetection$peaks_MSDIAL_mono_iso_newSample)
        vars$peaks_mono_iso_Cutt_newSample <- isolate(RvarsPeakDetection$peaks_mono_iso_Cutt_newSample)
        vars$map_ref <- isolate(RvarsPeakDetection$map_ref)
        vars$normalizers_ref <- isolate(RvarsPeakDetection$normalizers_ref)
        vars$defaultParam <- isolate(RvarsPeakDetection$defaultParam)
        vars$run_ref_path <- isolate(RvarsPeakDetection$run_ref_path)
        vars$map_ref_path <- isolate(RvarsPeakDetection$map_ref_path)
        vars$peaksList_run_ref_path <- isolate(RvarsPeakDetection$peaksList_run_ref_path)
        vars$normalizers_ref_path <- isolate(RvarsPeakDetection$normalizers_ref_path)
        vars$rt_min_max_run_ref_path <- isolate(RvarsPeakDetection$rt_min_max_run_ref_path)
        vars$paramMsdial_ref_path <- isolate(RvarsPeakDetection$paramMsdial_ref_path)
        vars$defaultParam_ref_path <- isolate(RvarsPeakDetection$defaultParam_ref_path)
      }
    },

    # =======================================================================
    # Stage 2: Temporal Correction (Kernel Density)
    # =======================================================================
    "ans_temporal_correction" = {
      vars <- extract_ans_stage_variables("ans_peak_detection", reactive_vars)

      if (!is.null(RvarsPeakDetection)) {
        vars$samplesCuttingTable_newSample <- isolate(RvarsPeakDetection$samplesCuttingTable_newSample)
        vars$peaks_mono_iso_newSample_list <- isolate(RvarsPeakDetection$peaks_mono_iso_newSample_list)
        vars$modelKernelDensity <- isolate(RvarsPeakDetection$modelKernelDensity)
        vars$peaks_newSample_list_KernelDensityCorrection <- isolate(RvarsPeakDetection$peaks_newSample_list_KernelDensityCorrection)
        vars$Data_Plot.newSample <- isolate(RvarsPeakDetection$Data_Plot.newSample)
        vars$Data_Plot.newSample_to_filter <- isolate(RvarsPeakDetection$Data_Plot.newSample_to_filter)
        vars$Data_Plot.after_KernelDensity <- isolate(RvarsPeakDetection$Data_Plot.after_KernelDensity)
        vars$kernelDensity_params_log <- isolate(RvarsPeakDetection$kernelDensity_params_log)
      }
    },

    # =======================================================================
    # Stage 3: Feature Grouping
    # =======================================================================
    "ans_grouping" = {
      vars <- extract_ans_stage_variables("ans_temporal_correction", reactive_vars)

      if (!is.null(RvarsPeakDetection)) {
        vars$FeaturesList_newSample <- isolate(RvarsPeakDetection$FeaturesList_newSample)
        vars$sample_name_newSample <- isolate(RvarsPeakDetection$sample_name_newSample)
      }
    },

    # =======================================================================
    # Stage 4: Match Reference Map
    # =======================================================================
    "ans_match_reference" = {
      vars <- extract_ans_stage_variables("ans_grouping", reactive_vars)

      if (!is.null(RvarsMatch)) {
        vars$res_match_ref <- isolate(RvarsMatch$res_match_ref)
        vars$res_MatrixNewSample <- isolate(RvarsMatch$res_MatrixNewSample)
        vars$matchedTable_newSample <- isolate(RvarsMatch$matchedTable_newSample)
      }
    },

    # =======================================================================
    # Stage 5: Normalization
    # =======================================================================
    "ans_normalization" = {
      vars <- extract_ans_stage_variables("ans_match_reference", reactive_vars)

      if (!is.null(RvarsNormalize)) {
        vars$matrix_abondance <- isolate(RvarsNormalize$matrix_abondance)
        vars$iset.normalizer.selected <- isolate(RvarsNormalize$iset.normalizer.selected)
        vars$matrix_abondance_Normalize <- isolate(RvarsNormalize$matrix_abondance_Normalize)
        vars$res_MatrixNewSample_normalized_toSave <- isolate(RvarsNormalize$res_MatrixNewSample_normalized_toSave)
        vars$res_MatrixNewSample_normalized_toPlot <- isolate(RvarsNormalize$res_MatrixNewSample_normalized_toPlot)
      }
    }
  )

  # Remove NULL entries
  vars <- vars[!sapply(vars, is.null)]

  return(vars)
}


#' Restore variables to reactive values for a specific Analysis New Samples stage
restore_ans_stage_variables <- function(stage_key, variables, reactive_vars) {

  RvarsPeakDetection <- reactive_vars$PeakDetection
  RvarsMatch <- reactive_vars$Match
  RvarsNormalize <- reactive_vars$Normalize

  # Restore Peak Detection variables
  if (!is.null(RvarsPeakDetection)) {
    restore_fields <- c(
      "Project_Name", "peaks_MSDIAL_mono_iso_newSample",
      "peaks_mono_iso_Cutt_newSample", "map_ref", "normalizers_ref",
      "defaultParam", "run_ref_path", "map_ref_path",
      "peaksList_run_ref_path", "normalizers_ref_path",
      "rt_min_max_run_ref_path", "paramMsdial_ref_path",
      "defaultParam_ref_path",
      "samplesCuttingTable_newSample", "peaks_mono_iso_newSample_list",
      "modelKernelDensity", "peaks_newSample_list_KernelDensityCorrection",
      "Data_Plot.newSample", "Data_Plot.newSample_to_filter",
      "Data_Plot.after_KernelDensity", "kernelDensity_params_log",
      "FeaturesList_newSample", "sample_name_newSample"
    )
    for (field in restore_fields) {
      if (field %in% names(variables)) {
        RvarsPeakDetection[[field]] <- variables[[field]]
      }
    }
  }

  # Restore Match variables
  if (!is.null(RvarsMatch)) {
    match_fields <- c("res_match_ref", "res_MatrixNewSample", "matchedTable_newSample")
    for (field in match_fields) {
      if (field %in% names(variables)) {
        RvarsMatch[[field]] <- variables[[field]]
      }
    }
  }

  # Restore Normalize variables
  if (!is.null(RvarsNormalize)) {
    norm_fields <- c(
      "matrix_abondance", "iset.normalizer.selected",
      "matrix_abondance_Normalize",
      "res_MatrixNewSample_normalized_toSave",
      "res_MatrixNewSample_normalized_toPlot"
    )
    for (field in norm_fields) {
      if (field %in% names(variables)) {
        RvarsNormalize[[field]] <- variables[[field]]
      }
    }
  }
}


cat("AnalysisNewSamplesCacheController.lib.R loaded successfully\n")
