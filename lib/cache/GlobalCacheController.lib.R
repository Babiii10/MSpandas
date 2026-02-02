# ===============================================================================
# GlobalCacheController.lib.R - Unified Cache Controller for MSpandas Pipeline
# ===============================================================================
#
# Description: Provides a centralized controller for managing caches across all
#              pipeline stages of the New Reference Map workflow.
#
# Pipeline Stages Covered:
#   1. Peak Detection       - After MSDIAL peak picking
#   2. Temporal Correction  - After XCMS alignment + Kernel Density
#   3. Grouping             - After feature grouping between samples
#   4. Reference Map        - After reference map generation
#   5. Normalizer Search    - After internal standard identification
#
# Author: MSpandas Team
# Version: 2.0.0
# Date: 2026-02-01
#
# ===============================================================================

# Load dependencies
library(shiny)

# Source cache libraries if not already loaded
if (!exists("init_cache_system")) {
  source("lib/cache/CacheManager.lib.R")
}
if (!exists("detect_crash_and_recover")) {
  source("lib/cache/RecoveryManager.lib.R")
}
if (!exists("show_recovery_modal")) {
  source("lib/cache/ShinyIntegration.lib.R")
}

# ===============================================================================
# PIPELINE STAGE DEFINITIONS
# ===============================================================================

#' Define the complete pipeline stages with their checkpoint IDs
#' This mapping ensures consistency across the application
PIPELINE_STAGES <- list(
  peak_detection = list(
    id = "step_01_peak_detection",
    name = "Peak Detection",
    description = "MSDIAL peak picking complete",
    next_step = "temporal_correction"
  ),
  temporal_correction = list(
    id = "step_02_temporal_correction",
    name = "Temporal Correction",
    description = "XCMS alignment and Kernel Density correction complete",
    next_step = "grouping"
  ),
  grouping = list(
    id = "step_03_grouping",
    name = "Feature Grouping",
    description = "Feature grouping between samples complete",
    next_step = "reference_map"
  ),
  reference_map = list(
    id = "step_04_reference_map",
    name = "Reference Map Generation",
    description = "Reference map generated and validated",
    next_step = "normalizer_search"
  ),
  normalizer_search = list(
    id = "step_05_normalizer_search",
    name = "Normalizer Search",
    description = "Internal standards identified",
    next_step = "complete"
  )
)

# ===============================================================================
# GlobalCacheController - Main Controller Class
# ===============================================================================

#' Create a Global Cache Controller for a project
#'
#' @param project_name Name of the project (used for cache identification)
#' @param data_dir Directory containing raw data files
#' @param base_cache_dir Base directory for all cache storage (default: "cache_projects")
#'
#' @return A list with controller functions and state
#' @export
#'
#' @examples
#' cache_ctrl <- create_global_cache_controller(
#'   project_name = "MyProject_312samples",
#'   data_dir = "/path/to/raw/data"
#' )
create_global_cache_controller <- function(project_name,
                                           data_dir,
                                           base_cache_dir = "cache_projects") {

  # Initialize internal state
  state <- new.env(parent = emptyenv())
  state$initialized <- FALSE
  state$cache_info <- NULL
  state$current_stage <- NULL
  state$completed_stages <- character(0)
  state$auto_save <- TRUE
  state$project_name <- project_name

  # =========================================================================
  # initialize - Initialize the cache system for the project
  # =========================================================================
  initialize <- function(n_samples = NULL, verbose = TRUE) {

    if (verbose) {
      cat("\n")
      cat("================================================================\n")
      cat("   Global Cache Controller - Initialization\n")
      cat("================================================================\n")
      cat(sprintf("   Project: %s\n", project_name))
      cat(sprintf("   Data dir: %s\n", data_dir))
    }

    # Initialize cache system
    state$cache_info <- init_cache_system(
      project_name = project_name,
      data_dir = data_dir,
      base_cache_dir = base_cache_dir
    )

    # Update sample count if provided
    if (!is.null(n_samples) && !is.null(state$cache_info$db_project_id)) {
      tryCatch({
        con <- DBI::dbConnect(RSQLite::SQLite(), state$cache_info$db_path)
        DBI::dbExecute(con,
          "UPDATE projects SET total_files = ? WHERE project_id = ?",
          params = list(n_samples, state$cache_info$db_project_id)
        )
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
  # check_recovery - Check if recovery is possible from existing cache
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
  # save_stage - Save a pipeline stage checkpoint
  # =========================================================================
  save_stage <- function(stage_key, reactive_vars, progress = NULL, verbose = TRUE) {

    if (!state$initialized) {
      warning("Cache controller not initialized. Call initialize() first.")
      return(FALSE)
    }

    if (!stage_key %in% names(PIPELINE_STAGES)) {
      stop(sprintf("Unknown stage key: %s", stage_key))
    }

    stage_def <- PIPELINE_STAGES[[stage_key]]

    # Extract variables based on stage
    variables <- extract_stage_variables(stage_key, reactive_vars)

    if (is.null(variables) || length(variables) == 0) {
      warning(sprintf("No variables to save for stage: %s", stage_key))
      return(FALSE)
    }

    if (verbose) {
      cat(sprintf("\n   Saving checkpoint: %s...\n", stage_def$name))
    }

    # Update progress if provided
    if (!is.null(progress)) {
      progress$set(message = sprintf("Saving: %s", stage_def$name), value = 0.3)
    }

    # Save checkpoint
    result <- save_checkpoint(
      checkpoint_id = stage_def$id,
      cache_info = state$cache_info,
      variables = variables,
      step_name = stage_def$name,
      next_step = stage_def$next_step
    )

    if (result) {
      state$current_stage <- stage_key
      state$completed_stages <- unique(c(state$completed_stages, stage_key))

      if (!is.null(progress)) {
        progress$set(message = "Checkpoint saved!", value = 1)
      }

      if (verbose) {
        cat(sprintf("   Checkpoint saved successfully!\n"))
      }
    }

    return(result)
  }

  # =========================================================================
  # restore_stage - Restore a pipeline stage from checkpoint
  # =========================================================================
  restore_stage <- function(stage_key, reactive_vars, progress = NULL, verbose = TRUE) {

    if (!state$initialized && !is.null(state$cache_info)) {
      # Allow restore even if not fully initialized
    } else if (!state$initialized) {
      warning("Cache controller not initialized.")
      return(FALSE)
    }

    if (!stage_key %in% names(PIPELINE_STAGES)) {
      stop(sprintf("Unknown stage key: %s", stage_key))
    }

    stage_def <- PIPELINE_STAGES[[stage_key]]

    if (verbose) {
      cat(sprintf("\n   Restoring checkpoint: %s...\n", stage_def$name))
    }

    if (!is.null(progress)) {
      progress$set(message = sprintf("Restoring: %s", stage_def$name), value = 0.2)
    }

    tryCatch({
      # Load checkpoint
      variables <- load_checkpoint(
        checkpoint_id = stage_def$id,
        cache_info = state$cache_info,
        validate_checksum = TRUE
      )

      if (!is.null(progress)) {
        progress$set(message = "Restoring variables...", value = 0.5)
      }

      # Restore variables to reactive values
      restore_stage_variables(stage_key, variables, reactive_vars)

      state$current_stage <- stage_key
      state$completed_stages <- unique(c(state$completed_stages, stage_key))

      if (!is.null(progress)) {
        progress$set(message = "Restore complete!", value = 1)
      }

      if (verbose) {
        cat(sprintf("   Restore successful!\n"))
      }

      return(TRUE)

    }, error = function(e) {
      warning(sprintf("Failed to restore stage %s: %s", stage_key, e$message))
      return(FALSE)
    })
  }

  # =========================================================================
  # restore_all_stages - Restore all available stages up to target
  # =========================================================================
  restore_all_stages <- function(target_stage, reactive_vars, progress = NULL, verbose = TRUE) {

    stage_order <- names(PIPELINE_STAGES)
    target_idx <- which(stage_order == target_stage)

    if (length(target_idx) == 0) {
      warning(sprintf("Unknown target stage: %s", target_stage))
      return(FALSE)
    }

    # Get available checkpoints
    available <- list_available_stages()

    if (verbose) {
      cat("\n")
      cat("================================================================\n")
      cat("   Restoring pipeline state\n")
      cat("================================================================\n")
      cat(sprintf("   Target stage: %s\n", target_stage))
      cat(sprintf("   Available stages: %s\n", paste(available, collapse = ", ")))
    }

    # Restore stages in order up to target
    restored_count <- 0
    for (i in 1:target_idx) {
      stage_key <- stage_order[i]

      if (stage_key %in% available) {
        if (!is.null(progress)) {
          progress$set(
            message = sprintf("Restoring %s...", PIPELINE_STAGES[[stage_key]]$name),
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
  # list_available_stages - Get list of stages with saved checkpoints
  # =========================================================================
  list_available_stages <- function() {

    if (is.null(state$cache_info) || !file.exists(state$cache_info$metadata_file)) {
      return(character(0))
    }

    metadata <- jsonlite::read_json(state$cache_info$metadata_file)
    saved_checkpoints <- names(metadata$checkpoints)

    # Map checkpoint IDs back to stage keys
    available_stages <- character(0)
    for (stage_key in names(PIPELINE_STAGES)) {
      if (PIPELINE_STAGES[[stage_key]]$id %in% saved_checkpoints) {
        available_stages <- c(available_stages, stage_key)
      }
    }

    return(available_stages)
  }

  # =========================================================================
  # get_status - Get current cache status
  # =========================================================================
  get_status <- function() {

    if (!state$initialized) {
      return(list(
        initialized = FALSE,
        project_name = project_name,
        current_stage = NULL,
        completed_stages = character(0),
        can_resume = FALSE
      ))
    }

    available <- list_available_stages()

    return(list(
      initialized = TRUE,
      project_name = project_name,
      project_id = state$cache_info$project_id,
      cache_dir = state$cache_info$cache_dir,
      current_stage = state$current_stage,
      completed_stages = state$completed_stages,
      available_stages = available,
      can_resume = length(available) > 0,
      auto_save = state$auto_save
    ))
  }

  # =========================================================================
  # set_auto_save - Enable/disable automatic checkpoint saving
  # =========================================================================
  set_auto_save <- function(enabled) {
    state$auto_save <- enabled
  }

  # =========================================================================
  # get_cache_info - Get underlying cache info structure
  # =========================================================================
  get_cache_info <- function() {
    return(state$cache_info)
  }

  # =========================================================================
  # mark_complete - Mark project as completed
  # =========================================================================
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
        warning("Could not mark project as complete: ", e$message)
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
    set_auto_save = set_auto_save,
    get_cache_info = get_cache_info,
    mark_complete = mark_complete,
    STAGES = PIPELINE_STAGES
  ))
}


# ===============================================================================
# HELPER FUNCTIONS - Variable Extraction and Restoration
# ===============================================================================

#' Extract variables for a specific pipeline stage
#'
#' @param stage_key Pipeline stage key
#' @param reactive_vars List of reactive variable environments
#'
#' @return Named list of variables to save
extract_stage_variables <- function(stage_key, reactive_vars) {

  vars <- list()

  # Get reactive environments
  Rvars_PeakDetection <- reactive_vars$PeakDetection
  Rvars_CorrectionTime <- reactive_vars$CorrectionTime
  Rvars_Grouping <- reactive_vars$Grouping
  Rvars_InternalStandard <- reactive_vars$InternalStandard

  switch(stage_key,

    # =======================================================================
    # Stage 1: Peak Detection
    # =======================================================================
    "peak_detection" = {
      if (!is.null(Rvars_PeakDetection)) {
        vars$directory_rawData <- isolate(Rvars_PeakDetection$directory_rawData)
        vars$peaks_MSDIAL_mono_iso <- isolate(Rvars_PeakDetection$peaks_MSDIAL_mono_iso_NewRefMap)
        vars$sample_name <- isolate(Rvars_PeakDetection$sample_name_NewRefMap)
        vars$Project_Name <- isolate(Rvars_PeakDetection$Project_NameNewRefMap)
      }
    },

    # =======================================================================
    # Stage 2: Temporal Correction (XCMS + Kernel Density)
    # =======================================================================
    "temporal_correction" = {
      # Include peak detection data
      if (!is.null(Rvars_PeakDetection)) {
        vars$directory_rawData <- isolate(Rvars_PeakDetection$directory_rawData)
        vars$peaks_MSDIAL_mono_iso <- isolate(Rvars_PeakDetection$peaks_MSDIAL_mono_iso_NewRefMap)
        vars$sample_name <- isolate(Rvars_PeakDetection$sample_name_NewRefMap)
        vars$Project_Name <- isolate(Rvars_PeakDetection$Project_NameNewRefMap)
      }

      if (!is.null(Rvars_CorrectionTime)) {
        # Sample cutting
        vars$samplesCuttingTable <- isolate(Rvars_CorrectionTime$samplesCuttingTable)

        # Reference sample
        vars$ref_Choose_sampleName <- isolate(Rvars_CorrectionTime$ref_Choose_sampleName)
        vars$ref_Choose_samplePeaks <- isolate(Rvars_CorrectionTime$ref_Choose_samplePeaks)
        vars$Ref_Mdian_sampleName <- isolate(Rvars_CorrectionTime$Ref_Mdian_sampleName)
        vars$Ref_Mdian_samplePeaks <- isolate(Rvars_CorrectionTime$Ref_Mdian_samplePeaks)
        vars$ref_sample_sampleName <- isolate(Rvars_CorrectionTime$ref_sample_sampleName)
        vars$ref_sample_samplePeaks <- isolate(Rvars_CorrectionTime$ref_sample_samplePeaks)

        # XCMS data
        vars$rawData_mzML_path <- isolate(Rvars_CorrectionTime$rawData_mzML_path)
        vars$pheno_Data_mzML <- isolate(Rvars_CorrectionTime$pheno_Data_mzML)
        vars$Filenames <- isolate(Rvars_CorrectionTime$Filenames)
        vars$Class <- isolate(Rvars_CorrectionTime$Class)
        vars$dataObiwarp_Aligned <- isolate(Rvars_CorrectionTime$dataObiwarp_Aligned)
        vars$peakListBefore <- isolate(Rvars_CorrectionTime$peakListBefore)
        vars$peakListAligned <- isolate(Rvars_CorrectionTime$peakListAligned)

        # Kernel Density
        vars$peakListAligned_KernelDensity <- isolate(Rvars_CorrectionTime$peakListAligned_KernelDensity)
        vars$modelKernelDensity <- isolate(Rvars_CorrectionTime$modelKernelDensity)
      }
    },

    # =======================================================================
    # Stage 3: Feature Grouping
    # =======================================================================
    "grouping" = {
      # Include previous stages data
      vars <- extract_stage_variables("temporal_correction", reactive_vars)

      if (!is.null(Rvars_Grouping)) {
        vars$FeaturesList <- isolate(Rvars_Grouping$FeaturesList)
        vars$FeaturesListGroupingBetweenSamples <- isolate(Rvars_Grouping$FeaturesListGroupingBetweenSamples)
      }
    },

    # =======================================================================
    # Stage 4: Reference Map Generation
    # =======================================================================
    "reference_map" = {
      # Include previous stages data
      vars <- extract_stage_variables("grouping", reactive_vars)

      if (!is.null(Rvars_Grouping)) {
        vars$RefereanceMap <- isolate(Rvars_Grouping$RefereanceMap)
        vars$MatrixAbundance <- isolate(Rvars_Grouping$MatrixAbundance)
        vars$RefereanceMap_selected <- isolate(Rvars_Grouping$RefereanceMap_selected)
        vars$MatrixAbundance_selected <- isolate(Rvars_Grouping$MatrixAbundance_selected)
      }
    },

    # =======================================================================
    # Stage 5: Normalizer Search
    # =======================================================================
    "normalizer_search" = {
      # Include previous stages data
      vars <- extract_stage_variables("reference_map", reactive_vars)

      if (!is.null(Rvars_InternalStandard)) {
        vars$OjectNormalizers <- isolate(Rvars_InternalStandard$OjectNormalizers)
        vars$names_normalizers <- isolate(Rvars_InternalStandard$names_normalizers)
        vars$map_ref_ToSave <- isolate(Rvars_InternalStandard$map_ref_ToSave)
        vars$MatrixAbundance_Before <- isolate(Rvars_InternalStandard$MatrixAbundance_Before)
        vars$MatrixAbundance_After <- isolate(Rvars_InternalStandard$MatrixAbundance_After)
        vars$normalizers_ref <- isolate(Rvars_InternalStandard$normalizers_ref)
        vars$peaksList_run_ref <- isolate(Rvars_InternalStandard$peaksList_run_ref)
        vars$rt_ref <- isolate(Rvars_InternalStandard$rt_ref)
      }
    }
  )

  # Remove NULL entries
  vars <- vars[!sapply(vars, is.null)]

  return(vars)
}


#' Restore variables to reactive values for a specific stage
#'
#' @param stage_key Pipeline stage key
#' @param variables Named list of variables to restore
#' @param reactive_vars List of reactive variable environments
restore_stage_variables <- function(stage_key, variables, reactive_vars) {

  # Get reactive environments
  Rvars_PeakDetection <- reactive_vars$PeakDetection
  Rvars_CorrectionTime <- reactive_vars$CorrectionTime
  Rvars_Grouping <- reactive_vars$Grouping
  Rvars_InternalStandard <- reactive_vars$InternalStandard

  # Restore Peak Detection variables
  if (!is.null(Rvars_PeakDetection)) {
    if ("directory_rawData" %in% names(variables)) {
      Rvars_PeakDetection$directory_rawData <- variables$directory_rawData
    }
    if ("peaks_MSDIAL_mono_iso" %in% names(variables)) {
      Rvars_PeakDetection$peaks_MSDIAL_mono_iso_NewRefMap <- variables$peaks_MSDIAL_mono_iso
    }
    if ("sample_name" %in% names(variables)) {
      Rvars_PeakDetection$sample_name_NewRefMap <- variables$sample_name
    }
    if ("Project_Name" %in% names(variables)) {
      Rvars_PeakDetection$Project_NameNewRefMap <- variables$Project_Name
    }
  }

  # Restore Correction Time variables
  if (!is.null(Rvars_CorrectionTime)) {
    if ("samplesCuttingTable" %in% names(variables)) {
      Rvars_CorrectionTime$samplesCuttingTable <- variables$samplesCuttingTable
    }
    if ("ref_Choose_sampleName" %in% names(variables)) {
      Rvars_CorrectionTime$ref_Choose_sampleName <- variables$ref_Choose_sampleName
    }
    if ("ref_Choose_samplePeaks" %in% names(variables)) {
      Rvars_CorrectionTime$ref_Choose_samplePeaks <- variables$ref_Choose_samplePeaks
    }
    if ("Ref_Mdian_sampleName" %in% names(variables)) {
      Rvars_CorrectionTime$Ref_Mdian_sampleName <- variables$Ref_Mdian_sampleName
    }
    if ("Ref_Mdian_samplePeaks" %in% names(variables)) {
      Rvars_CorrectionTime$Ref_Mdian_samplePeaks <- variables$Ref_Mdian_samplePeaks
    }
    if ("ref_sample_sampleName" %in% names(variables)) {
      Rvars_CorrectionTime$ref_sample_sampleName <- variables$ref_sample_sampleName
    }
    if ("ref_sample_samplePeaks" %in% names(variables)) {
      Rvars_CorrectionTime$ref_sample_samplePeaks <- variables$ref_sample_samplePeaks
    }
    if ("rawData_mzML_path" %in% names(variables)) {
      Rvars_CorrectionTime$rawData_mzML_path <- variables$rawData_mzML_path
    }
    if ("pheno_Data_mzML" %in% names(variables)) {
      Rvars_CorrectionTime$pheno_Data_mzML <- variables$pheno_Data_mzML
    }
    if ("Filenames" %in% names(variables)) {
      Rvars_CorrectionTime$Filenames <- variables$Filenames
    }
    if ("Class" %in% names(variables)) {
      Rvars_CorrectionTime$Class <- variables$Class
    }
    if ("dataObiwarp_Aligned" %in% names(variables)) {
      Rvars_CorrectionTime$dataObiwarp_Aligned <- variables$dataObiwarp_Aligned
    }
    if ("peakListBefore" %in% names(variables)) {
      Rvars_CorrectionTime$peakListBefore <- variables$peakListBefore
    }
    if ("peakListAligned" %in% names(variables)) {
      Rvars_CorrectionTime$peakListAligned <- variables$peakListAligned
    }
    if ("peakListAligned_KernelDensity" %in% names(variables)) {
      Rvars_CorrectionTime$peakListAligned_KernelDensity <- variables$peakListAligned_KernelDensity
    }
    if ("modelKernelDensity" %in% names(variables)) {
      Rvars_CorrectionTime$modelKernelDensity <- variables$modelKernelDensity
    }
  }

  # Restore Grouping variables
  if (!is.null(Rvars_Grouping)) {
    if ("FeaturesList" %in% names(variables)) {
      Rvars_Grouping$FeaturesList <- variables$FeaturesList
    }
    if ("FeaturesListGroupingBetweenSamples" %in% names(variables)) {
      Rvars_Grouping$FeaturesListGroupingBetweenSamples <- variables$FeaturesListGroupingBetweenSamples
    }
    if ("RefereanceMap" %in% names(variables)) {
      Rvars_Grouping$RefereanceMap <- variables$RefereanceMap
    }
    if ("MatrixAbundance" %in% names(variables)) {
      Rvars_Grouping$MatrixAbundance <- variables$MatrixAbundance
    }
    if ("RefereanceMap_selected" %in% names(variables)) {
      Rvars_Grouping$RefereanceMap_selected <- variables$RefereanceMap_selected
    }
    if ("MatrixAbundance_selected" %in% names(variables)) {
      Rvars_Grouping$MatrixAbundance_selected <- variables$MatrixAbundance_selected
    }
  }

  # Restore Internal Standard variables
  if (!is.null(Rvars_InternalStandard)) {
    if ("OjectNormalizers" %in% names(variables)) {
      Rvars_InternalStandard$OjectNormalizers <- variables$OjectNormalizers
    }
    if ("names_normalizers" %in% names(variables)) {
      Rvars_InternalStandard$names_normalizers <- variables$names_normalizers
    }
    if ("map_ref_ToSave" %in% names(variables)) {
      Rvars_InternalStandard$map_ref_ToSave <- variables$map_ref_ToSave
    }
    if ("MatrixAbundance_Before" %in% names(variables)) {
      Rvars_InternalStandard$MatrixAbundance_Before <- variables$MatrixAbundance_Before
    }
    if ("MatrixAbundance_After" %in% names(variables)) {
      Rvars_InternalStandard$MatrixAbundance_After <- variables$MatrixAbundance_After
    }
    if ("normalizers_ref" %in% names(variables)) {
      Rvars_InternalStandard$normalizers_ref <- variables$normalizers_ref
    }
    if ("peaksList_run_ref" %in% names(variables)) {
      Rvars_InternalStandard$peaksList_run_ref <- variables$peaksList_run_ref
    }
    if ("rt_ref" %in% names(variables)) {
      Rvars_InternalStandard$rt_ref <- variables$rt_ref
    }
  }

  return(invisible(TRUE))
}


# ===============================================================================
# SHINY UI COMPONENTS
# ===============================================================================

#' Create cache status panel UI component
#'
#' @param ns Namespace function for Shiny modules
#' @return Shiny UI element
cache_status_panel_ui <- function(ns = NULL) {

  if (is.null(ns)) {
    ns <- function(x) x
  }

  tagList(
    div(
      id = ns("cache_status_panel"),
      class = "well well-sm",
      style = "background-color: #f8f9fa; border: 1px solid #dee2e6; padding: 15px;",

      h4(
        icon("database"),
        "Cache Status",
        style = "margin-top: 0; color: #495057;"
      ),

      hr(style = "margin: 10px 0;"),

      # Status display
      uiOutput(ns("cache_status_display")),

      hr(style = "margin: 10px 0;"),

      # Action buttons
      fluidRow(
        column(6,
          actionButton(
            ns("btn_save_cache"),
            label = "Save Checkpoint",
            icon = icon("save"),
            class = "btn-primary btn-block",
            style = "margin-bottom: 5px;"
          )
        ),
        column(6,
          actionButton(
            ns("btn_restore_cache"),
            label = "Restore from Cache",
            icon = icon("undo"),
            class = "btn-success btn-block",
            style = "margin-bottom: 5px;"
          )
        )
      ),

      # Advanced options (collapsible)
      tags$details(
        style = "margin-top: 10px;",
        tags$summary(
          style = "cursor: pointer; color: #6c757d;",
          "Advanced Options"
        ),
        div(
          style = "padding-top: 10px;",
          checkboxInput(
            ns("auto_save_enabled"),
            "Enable automatic checkpoints",
            value = TRUE
          ),
          actionButton(
            ns("btn_clean_cache"),
            "Clean Old Caches",
            icon = icon("trash"),
            class = "btn-warning btn-sm"
          )
        )
      )
    )
  )
}


#' Server logic for cache status panel
#'
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
#' @param cache_controller Global cache controller object
#' @param reactive_vars List of reactive variable environments
cache_status_panel_server <- function(input, output, session,
                                      cache_controller, reactive_vars) {

  ns <- session$ns

  # Render cache status
  output$cache_status_display <- renderUI({

    status <- cache_controller$get_status()

    if (!status$initialized) {
      return(div(
        class = "text-muted",
        icon("info-circle"),
        " Cache not initialized. Start a new project to enable caching."
      ))
    }

    # Build stage badges
    stage_badges <- lapply(names(PIPELINE_STAGES), function(stage_key) {
      stage <- PIPELINE_STAGES[[stage_key]]

      if (stage_key %in% status$available_stages) {
        badge_class <- "badge-success"
        badge_icon <- icon("check")
      } else {
        badge_class <- "badge-secondary"
        badge_icon <- icon("circle")
      }

      span(
        class = paste("badge", badge_class),
        style = "margin-right: 5px; margin-bottom: 5px;",
        badge_icon,
        gsub("step_\\d+_", "", stage$id)
      )
    })

    div(
      p(
        strong("Project: "),
        status$project_name
      ),
      p(
        strong("Current stage: "),
        if (!is.null(status$current_stage)) {
          PIPELINE_STAGES[[status$current_stage]]$name
        } else {
          "Not started"
        }
      ),
      p(
        strong("Saved checkpoints: ")
      ),
      div(stage_badges)
    )
  })

  # Handle save button
  observeEvent(input$btn_save_cache, {

    status <- cache_controller$get_status()

    if (!status$initialized) {
      showNotification("Cache not initialized", type = "warning")
      return()
    }

    # Determine current stage to save
    current_stage <- status$current_stage
    if (is.null(current_stage) || current_stage == "initialized") {
      current_stage <- "peak_detection"
    }

    # Show modal to select stage
    showModal(modalDialog(
      title = "Save Checkpoint",
      selectInput(
        session$ns("save_stage_select"),
        "Select stage to save:",
        choices = setNames(
          names(PIPELINE_STAGES),
          sapply(PIPELINE_STAGES, function(x) x$name)
        ),
        selected = current_stage
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(session$ns("confirm_save"), "Save", class = "btn-primary")
      )
    ))
  })

  # Confirm save
  observeEvent(input$confirm_save, {

    stage_to_save <- input$save_stage_select
    removeModal()

    withProgress(message = "Saving checkpoint...", {
      result <- cache_controller$save_stage(
        stage_key = stage_to_save,
        reactive_vars = reactive_vars
      )

      if (result) {
        showNotification(
          paste("Checkpoint saved:", PIPELINE_STAGES[[stage_to_save]]$name),
          type = "message",
          duration = 5
        )
      } else {
        showNotification("Failed to save checkpoint", type = "error")
      }
    })
  })

  # Handle restore button
  observeEvent(input$btn_restore_cache, {

    status <- cache_controller$get_status()

    if (!status$can_resume) {
      showNotification("No checkpoints available to restore", type = "warning")
      return()
    }

    # Show modal with available stages
    available_choices <- setNames(
      status$available_stages,
      sapply(status$available_stages, function(x) PIPELINE_STAGES[[x]]$name)
    )

    showModal(modalDialog(
      title = "Restore from Checkpoint",
      selectInput(
        session$ns("restore_stage_select"),
        "Select stage to restore:",
        choices = available_choices,
        selected = tail(status$available_stages, 1)
      ),
      p(class = "text-warning",
        icon("exclamation-triangle"),
        " This will overwrite current data in memory."
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(session$ns("confirm_restore"), "Restore", class = "btn-success")
      )
    ))
  })

  # Confirm restore
  observeEvent(input$confirm_restore, {

    stage_to_restore <- input$restore_stage_select
    removeModal()

    withProgress(message = "Restoring checkpoint...", {
      result <- cache_controller$restore_all_stages(
        target_stage = stage_to_restore,
        reactive_vars = reactive_vars
      )

      if (result) {
        showNotification(
          paste("Restored to:", PIPELINE_STAGES[[stage_to_restore]]$name),
          type = "message",
          duration = 5
        )
      } else {
        showNotification("Failed to restore checkpoint", type = "error")
      }
    })
  })

  # Handle auto-save toggle
  observeEvent(input$auto_save_enabled, {
    cache_controller$set_auto_save(input$auto_save_enabled)
  })

  # Handle clean cache
  observeEvent(input$btn_clean_cache, {

    showModal(modalDialog(
      title = "Clean Old Caches",
      p("This will remove old cache directories to free up disk space."),
      numericInput(
        session$ns("keep_recent_n"),
        "Keep most recent:",
        value = 5,
        min = 1,
        max = 20
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(session$ns("confirm_clean"), "Clean", class = "btn-warning")
      )
    ))
  })

  # Confirm clean
  observeEvent(input$confirm_clean, {

    removeModal()

    deleted <- clean_old_caches(
      base_cache_dir = "cache_projects",
      keep_recent_n = input$keep_recent_n,
      dry_run = FALSE
    )

    showNotification(
      paste("Cleaned", deleted, "old cache(s)"),
      type = "message",
      duration = 5
    )
  })
}


# ===============================================================================
# END OF FILE
# ===============================================================================

cat("Global Cache Controller loaded successfully\n")
cat("Functions available:\n")
cat("  - create_global_cache_controller()\n")
cat("  - cache_status_panel_ui()\n")
cat("  - cache_status_panel_server()\n")
cat("  - PIPELINE_STAGES\n\n")
