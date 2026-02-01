# ===============================================================================
# cacheManagement.server.R - Cache Management Server Logic
# ===============================================================================
#
# Description: Server-side logic for global cache management in MSpandas
#
# Features:
#   - Initialize cache controller when project starts
#   - Automatic recovery detection at startup
#   - Manual save/restore checkpoints
#   - Automatic checkpoints after each pipeline stage
#   - Cache status display
#
# Author: MSpandas Team
# Version: 2.0.0
# Date: 2026-02-01
#
# ===============================================================================

# Get reference to reactive variables from parent scope
RvarsPeakDetection <- allReactiveVarsNewRefMap$PeakDetection
RvarsCorrectionTime <- allReactiveVarsNewRefMap$CorrectionTime
RvarsGrouping <- allReactiveVarsNewRefMap$Grouping
RvarsInternalStandard <- allReactiveVarsNewRefMap$InternalStandard

# ===============================================================================
# CACHE INITIALIZATION - When project name is set
# ===============================================================================

#' Initialize cache when a new project is started
observeEvent(RvarsPeakDetection$Project_NameNewRefMap, {

  project_name <- RvarsPeakDetection$Project_NameNewRefMap

  if (!is.null(project_name) && nchar(trimws(project_name)) > 0) {

    # Check if already initialized with this project
    if (cacheState$initialized && cacheState$project_name == project_name) {
      return()
    }

    # Get data directory
    data_dir <- RvarsPeakDetection$directory_rawData
    if (is.null(data_dir)) {
      data_dir <- getwd()
    }

    # Create cache controller
    tryCatch({
      cache_ctrl <- create_global_cache_controller(
        project_name = project_name,
        data_dir = data_dir,
        base_cache_dir = "cache_projects"
      )

      # Initialize the controller
      cache_ctrl$initialize(verbose = TRUE)

      # Store controller
      globalCacheController(cache_ctrl)
      cacheState$initialized <- TRUE
      cacheState$project_name <- project_name

      # Check for recovery
      recovery_info <- cache_ctrl$check_recovery(verbose = TRUE)

      if (recovery_info$can_resume && recovery_info$mode == "resume") {
        cacheState$can_resume <- TRUE
        cacheState$recovery_pending <- TRUE

        # Show recovery modal
        showModal(modalDialog(
          title = div(
            icon("sync", class = "fa-spin"),
            " Previous Session Detected",
            style = "color: #28a745;"
          ),
          div(
            style = "padding: 15px;",
            h4("Would you like to resume from the last checkpoint?"),
            hr(),
            p(strong("Project: "), project_name),
            p(strong("Last checkpoint: "),
              if (!is.null(recovery_info$checkpoint_name)) recovery_info$checkpoint_name else "Unknown"),
            p(strong("Saved at: "),
              if (!is.null(recovery_info$saved_time)) recovery_info$saved_time else "Unknown"),
            p(strong("Number of checkpoints: "), recovery_info$n_checkpoints),
            hr(),
            p(class = "text-info",
              icon("info-circle"),
              " Resuming will restore all pipeline data from the last saved state."
            )
          ),
          footer = tagList(
            actionButton("cache_restart_fresh", "Start Fresh",
                         class = "btn-warning",
                         icon = icon("redo")),
            actionButton("cache_resume_session", "Resume Session",
                         class = "btn-success",
                         icon = icon("play"))
          ),
          easyClose = FALSE
        ))
      }

      showNotification(
        paste("Cache system initialized for:", project_name),
        type = "message",
        duration = 3
      )

    }, error = function(e) {
      showNotification(
        paste("Cache initialization warning:", e$message),
        type = "warning",
        duration = 5
      )
    })
  }
})


# ===============================================================================
# RECOVERY HANDLERS
# ===============================================================================

#' Handle resume session button
observeEvent(input$cache_resume_session, {

  removeModal()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  # Get available stages
  available <- cache_ctrl$list_available_stages()

  if (length(available) == 0) {
    showNotification("No checkpoints available", type = "warning")
    return()
  }

  # Get the latest stage
  target_stage <- tail(available, 1)

  withProgress(message = "Restoring session...", value = 0, {

    # Create reactive vars list for restoration
    reactive_vars <- list(
      PeakDetection = RvarsPeakDetection,
      CorrectionTime = RvarsCorrectionTime,
      Grouping = RvarsGrouping,
      InternalStandard = RvarsInternalStandard
    )

    # Restore all stages up to target
    result <- cache_ctrl$restore_all_stages(
      target_stage = target_stage,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )

    if (result) {
      cacheState$recovery_pending <- FALSE

      showNotification(
        paste("Session restored successfully to:",
              cache_ctrl$STAGES[[target_stage]]$name),
        type = "message",
        duration = 5
      )

      # Navigate to appropriate page based on restored stage
      navigate_to_stage(session, target_stage)

    } else {
      showNotification(
        "Failed to restore session. Starting fresh.",
        type = "error",
        duration = 5
      )
    }
  })
})


#' Handle restart fresh button
observeEvent(input$cache_restart_fresh, {

  removeModal()
  cacheState$recovery_pending <- FALSE

  showNotification(
    "Starting fresh workflow",
    type = "message",
    duration = 3
  )
})


# ===============================================================================
# MANUAL CACHE CONTROLS
# ===============================================================================

#' Handle manual save checkpoint button
observeEvent(input$btn_save_checkpoint_global, {

  cache_ctrl <- globalCacheController()

  if (is.null(cache_ctrl)) {
    showNotification("Cache not initialized. Set a project name first.", type = "warning")
    return()
  }

  # Show stage selection modal
  showModal(modalDialog(
    title = div(icon("save"), " Save Checkpoint"),
    div(
      style = "padding: 10px;",
      selectInput(
        "cache_save_stage_select",
        "Select pipeline stage to save:",
        choices = setNames(
          names(cache_ctrl$STAGES),
          sapply(cache_ctrl$STAGES, function(x) x$name)
        )
      ),
      p(class = "text-muted",
        icon("info-circle"),
        " This will save all data up to and including the selected stage."
      )
    ),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("cache_confirm_save", "Save Checkpoint",
                   class = "btn-primary", icon = icon("save"))
    )
  ))
})


#' Confirm manual save
observeEvent(input$cache_confirm_save, {

  removeModal()

  cache_ctrl <- globalCacheController()
  stage_key <- input$cache_save_stage_select

  if (is.null(cache_ctrl) || is.null(stage_key)) return()

  withProgress(message = "Saving checkpoint...", value = 0, {

    reactive_vars <- list(
      PeakDetection = RvarsPeakDetection,
      CorrectionTime = RvarsCorrectionTime,
      Grouping = RvarsGrouping,
      InternalStandard = RvarsInternalStandard
    )

    result <- cache_ctrl$save_stage(
      stage_key = stage_key,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )

    if (result) {
      showNotification(
        paste("Checkpoint saved:", cache_ctrl$STAGES[[stage_key]]$name),
        type = "message",
        duration = 5
      )
    } else {
      showNotification(
        "Failed to save checkpoint. Check that required data is available.",
        type = "error",
        duration = 5
      )
    }
  })
})


#' Handle manual restore button
observeEvent(input$btn_restore_checkpoint_global, {

  cache_ctrl <- globalCacheController()

  if (is.null(cache_ctrl)) {
    showNotification("Cache not initialized", type = "warning")
    return()
  }

  available <- cache_ctrl$list_available_stages()

  if (length(available) == 0) {
    showNotification("No checkpoints available to restore", type = "warning")
    return()
  }

  # Show restore selection modal
  showModal(modalDialog(
    title = div(icon("undo"), " Restore from Checkpoint"),
    div(
      style = "padding: 10px;",
      selectInput(
        "cache_restore_stage_select",
        "Select checkpoint to restore:",
        choices = setNames(
          available,
          sapply(available, function(x) cache_ctrl$STAGES[[x]]$name)
        ),
        selected = tail(available, 1)
      ),
      p(class = "text-warning",
        icon("exclamation-triangle"),
        " Warning: This will overwrite current data in memory!"
      )
    ),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("cache_confirm_restore", "Restore",
                   class = "btn-success", icon = icon("undo"))
    )
  ))
})


#' Confirm manual restore
observeEvent(input$cache_confirm_restore, {

  removeModal()

  cache_ctrl <- globalCacheController()
  stage_key <- input$cache_restore_stage_select

  if (is.null(cache_ctrl) || is.null(stage_key)) return()

  withProgress(message = "Restoring checkpoint...", value = 0, {

    reactive_vars <- list(
      PeakDetection = RvarsPeakDetection,
      CorrectionTime = RvarsCorrectionTime,
      Grouping = RvarsGrouping,
      InternalStandard = RvarsInternalStandard
    )

    result <- cache_ctrl$restore_all_stages(
      target_stage = stage_key,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )

    if (result) {
      showNotification(
        paste("Restored to:", cache_ctrl$STAGES[[stage_key]]$name),
        type = "message",
        duration = 5
      )

      # Navigate to appropriate page
      navigate_to_stage(session, stage_key)

    } else {
      showNotification("Failed to restore checkpoint", type = "error", duration = 5)
    }
  })
})


# ===============================================================================
# CACHE STATUS DISPLAY
# ===============================================================================

#' Render cache status panel
output$cache_status_panel_output <- renderUI({

  cache_ctrl <- globalCacheController()

  if (is.null(cache_ctrl) || !cacheState$initialized) {
    return(div(
      class = "alert alert-info",
      style = "margin: 10px;",
      icon("info-circle"),
      " Cache not initialized. Enter a project name to enable caching."
    ))
  }

  status <- cache_ctrl$get_status()
  available <- status$available_stages

  # Build stage indicators
  stage_badges <- lapply(names(cache_ctrl$STAGES), function(stage_key) {
    stage <- cache_ctrl$STAGES[[stage_key]]

    if (stage_key %in% available) {
      badge_class <- "label-success"
      badge_icon <- icon("check-circle")
    } else {
      badge_class <- "label-default"
      badge_icon <- icon("circle-o")
    }

    span(
      class = paste("label", badge_class),
      style = "margin: 2px; padding: 5px 8px; font-size: 11px;",
      badge_icon,
      stage$name
    )
  })

  div(
    class = "well well-sm",
    style = "margin: 10px; padding: 15px; background-color: #f5f5f5;",

    h5(
      icon("database"),
      " Cache Status",
      style = "margin-top: 0; color: #333;"
    ),
    hr(style = "margin: 10px 0;"),

    p(strong("Project: "), status$project_name),
    p(strong("Checkpoints: "), length(available), " saved"),

    div(
      style = "margin: 10px 0;",
      stage_badges
    ),

    hr(style = "margin: 10px 0;"),

    div(
      style = "text-align: center;",
      actionButton(
        "btn_save_checkpoint_global",
        "Save",
        icon = icon("save"),
        class = "btn-primary btn-sm",
        style = "margin: 2px;"
      ),
      actionButton(
        "btn_restore_checkpoint_global",
        "Restore",
        icon = icon("undo"),
        class = "btn-success btn-sm",
        style = "margin: 2px;"
      )
    )
  )
})


# ===============================================================================
# AUTOMATIC CHECKPOINTS - Triggered after pipeline stage completion
# ===============================================================================

#' Auto-save after Temporal Correction (XCMS + Kernel Density)
observeEvent(RvarsCorrectionTime$peakListAligned_KernelDensity, {

  if (!cacheState$auto_save_enabled) return()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  # Only save if we have valid data
  if (is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) return()

  # Delay to ensure all data is ready
  invalidateLater(2000, session)

  isolate({
    tryCatch({
      reactive_vars <- list(
        PeakDetection = RvarsPeakDetection,
        CorrectionTime = RvarsCorrectionTime,
        Grouping = RvarsGrouping,
        InternalStandard = RvarsInternalStandard
      )

      result <- cache_ctrl$save_stage(
        stage_key = "temporal_correction",
        reactive_vars = reactive_vars,
        verbose = FALSE
      )

      if (result) {
        showNotification(
          "Auto-saved: Temporal Correction checkpoint",
          type = "message",
          duration = 3
        )
      }
    }, error = function(e) {
      # Silent fail for auto-save
    })
  })
}, ignoreInit = TRUE)


#' Auto-save after Grouping
observeEvent(RvarsGrouping$FeaturesListGroupingBetweenSamples, {

  if (!cacheState$auto_save_enabled) return()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  if (is.null(RvarsGrouping$FeaturesListGroupingBetweenSamples)) return()

  invalidateLater(2000, session)

  isolate({
    tryCatch({
      reactive_vars <- list(
        PeakDetection = RvarsPeakDetection,
        CorrectionTime = RvarsCorrectionTime,
        Grouping = RvarsGrouping,
        InternalStandard = RvarsInternalStandard
      )

      result <- cache_ctrl$save_stage(
        stage_key = "grouping",
        reactive_vars = reactive_vars,
        verbose = FALSE
      )

      if (result) {
        showNotification(
          "Auto-saved: Grouping checkpoint",
          type = "message",
          duration = 3
        )
      }
    }, error = function(e) {
      # Silent fail
    })
  })
}, ignoreInit = TRUE)


#' Auto-save after Reference Map Generation
observeEvent(RvarsGrouping$RefereanceMap_selected, {

  if (!cacheState$auto_save_enabled) return()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  if (is.null(RvarsGrouping$RefereanceMap_selected)) return()

  invalidateLater(2000, session)

  isolate({
    tryCatch({
      reactive_vars <- list(
        PeakDetection = RvarsPeakDetection,
        CorrectionTime = RvarsCorrectionTime,
        Grouping = RvarsGrouping,
        InternalStandard = RvarsInternalStandard
      )

      result <- cache_ctrl$save_stage(
        stage_key = "reference_map",
        reactive_vars = reactive_vars,
        verbose = FALSE
      )

      if (result) {
        showNotification(
          "Auto-saved: Reference Map checkpoint",
          type = "message",
          duration = 3
        )
      }
    }, error = function(e) {
      # Silent fail
    })
  })
}, ignoreInit = TRUE)


#' Auto-save after Normalizer Search
observeEvent(RvarsInternalStandard$normalizers_ref, {

  if (!cacheState$auto_save_enabled) return()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  if (is.null(RvarsInternalStandard$normalizers_ref)) return()

  invalidateLater(2000, session)

  isolate({
    tryCatch({
      reactive_vars <- list(
        PeakDetection = RvarsPeakDetection,
        CorrectionTime = RvarsCorrectionTime,
        Grouping = RvarsGrouping,
        InternalStandard = RvarsInternalStandard
      )

      result <- cache_ctrl$save_stage(
        stage_key = "normalizer_search",
        reactive_vars = reactive_vars,
        verbose = FALSE
      )

      if (result) {
        showNotification(
          "Auto-saved: Normalizer Search checkpoint",
          type = "message",
          duration = 3
        )
      }
    }, error = function(e) {
      # Silent fail
    })
  })
}, ignoreInit = TRUE)


# ===============================================================================
# HELPER FUNCTIONS
# ===============================================================================

#' Navigate to appropriate UI page based on restored stage
navigate_to_stage <- function(session, stage_key) {

  switch(stage_key,

    "peak_detection" = {
      updateNavbarPage(session, "analysisNavbar", selected = "Peak detection")
    },

    "temporal_correction" = {
      updateNavbarPage(session, "analysisNavbar", selected = "CE-time correction")
      updateRadioButtons(session, "CorrectionTimeStep", selected = "4")
    },

    "grouping" = {
      updateNavbarPage(session, "analysisNavbar", selected = "Generate the reference map")
      updateRadioButtons(session, "GenerateRefMapStep", selected = "1")
    },

    "reference_map" = {
      updateNavbarPage(session, "analysisNavbar", selected = "Generate the reference map")
      updateRadioButtons(session, "GenerateRefMapStep", selected = "2")
    },

    "normalizer_search" = {
      updateNavbarPage(session, "analysisNavbar", selected = "Identification internal standards")
      updateRadioButtons(session, "InternalStandardsStep", selected = "2")
    }
  )
}


# ===============================================================================
# AUTO-SAVE TOGGLE
# ===============================================================================

#' Toggle auto-save functionality
observeEvent(input$cache_auto_save_toggle, {
  cacheState$auto_save_enabled <- input$cache_auto_save_toggle
  showNotification(
    paste("Auto-save:", if(input$cache_auto_save_toggle) "enabled" else "disabled"),
    type = "message",
    duration = 2
  )
})


# ===============================================================================
# END OF FILE
# ===============================================================================

cat("Cache Management Server loaded\n")
