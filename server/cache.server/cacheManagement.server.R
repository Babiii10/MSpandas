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
# ENHANCED v3.0 - CONFIGURATION HANDLERS
# ===============================================================================

#' View cache status modal
observeEvent(input$btn_view_cache_status, {

  cache_ctrl <- globalCacheController()

  if (is.null(cache_ctrl)) {
    showNotification("Cache not initialized", type = "warning")
    return()
  }

  status <- cache_ctrl$get_status()
  config <- cache_ctrl$get_config()

  showModal(modalDialog(
    title = div(
      icon("info-circle"),
      " Cache Status",
      style = "color: #495057; font-weight: 600;"
    ),
    size = "m",
    easyClose = TRUE,

    div(
      style = "padding: 15px;",

      # Project info
      h5(icon("project-diagram"), " Project Information"),
      hr(style = "margin: 10px 0;"),
      p(strong("Project: "), status$project_name),
      p(strong("Cache Version: "), status$version),
      p(strong("Current Stage: "),
        if (!is.null(status$current_stage)) status$current_stage else "Not started"),

      hr(),

      # Storage info
      h5(icon("hdd"), " Storage"),
      hr(style = "margin: 10px 0;"),
      p(strong("Total Cache Size: "),
        if (!is.na(status$total_cache_mb)) sprintf("%.2f MB", status$total_cache_mb) else "N/A"),
      p(strong("Projects in Cache: "),
        if (!is.na(status$n_projects)) status$n_projects else "N/A"),
      p(strong("Available Checkpoints: "), length(status$available_stages)),

      hr(),

      # Configuration summary
      h5(icon("cogs"), " Configuration"),
      hr(style = "margin: 10px 0;"),
      p(strong("Auto-save: "), if (status$auto_save) "Enabled" else "Disabled"),
      p(strong("Versioning: "), if (config$enable_versioning) "Enabled" else "Disabled"),
      p(strong("Compression: "), config$compression_level),
      p(strong("Max Size Limit: "), paste(config$max_total_size_gb, "GB"))
    ),

    footer = tagList(
      actionButton("btn_cache_config", "Configure",
                   class = "btn-info", icon = icon("cogs")),
      actionButton("btn_cache_health", "Health Check",
                   class = "btn-warning", icon = icon("heartbeat")),
      modalButton("Close")
    )
  ))
})


#' Open configuration modal
observeEvent(input$btn_cache_config, {

  removeModal()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  config <- cache_ctrl$get_config()

  showModal(modalDialog(
    title = div(
      icon("cogs"),
      " Cache Configuration",
      style = "color: #495057; font-weight: 600;"
    ),
    size = "m",
    easyClose = TRUE,

    div(
      style = "padding: 15px;",

      # Storage limits
      h5(icon("hdd"), " Storage Limits", style = "color: #495057;"),
      hr(style = "margin: 10px 0;"),

      fluidRow(
        column(6,
          numericInput(
            "cache_config_max_size",
            "Max total size (GB):",
            value = config$max_total_size_gb,
            min = 1,
            max = 500,
            step = 5
          )
        ),
        column(6,
          numericInput(
            "cache_config_max_projects",
            "Max projects:",
            value = config$max_projects,
            min = 1,
            max = 100,
            step = 1
          )
        )
      ),

      fluidRow(
        column(6,
          numericInput(
            "cache_config_max_versions",
            "Max versions per stage:",
            value = config$max_checkpoints_per_stage,
            min = 1,
            max = 20,
            step = 1
          )
        ),
        column(6,
          numericInput(
            "cache_config_max_age",
            "Max age (days):",
            value = config$max_age_days,
            min = 1,
            max = 365,
            step = 7
          )
        )
      ),

      hr(),

      # Features
      h5(icon("sliders"), " Features", style = "color: #495057;"),
      hr(style = "margin: 10px 0;"),

      fluidRow(
        column(6,
          checkboxInput(
            "cache_config_auto_cleanup",
            span(icon("broom"), " Auto cleanup"),
            value = config$auto_cleanup
          ),
          checkboxInput(
            "cache_config_versioning",
            span(icon("code-branch"), " Enable versioning"),
            value = config$enable_versioning
          )
        ),
        column(6,
          checkboxInput(
            "cache_config_logging",
            span(icon("file-alt"), " Enable logging"),
            value = config$enable_logging
          ),
          checkboxInput(
            "cache_config_atomic",
            span(icon("shield-alt"), " Atomic writes"),
            value = config$atomic_writes
          )
        )
      ),

      hr(),

      # Compression
      h5(icon("compress-arrows-alt"), " Compression", style = "color: #495057;"),
      hr(style = "margin: 10px 0;"),

      radioButtons(
        "cache_config_compression",
        NULL,
        choices = list(
          "Auto (recommended)" = "auto",
          "Fast (gzip)" = "gzip",
          "Balanced (bzip2)" = "bzip2",
          "Maximum (xz)" = "xz"
        ),
        selected = config$compression_level,
        inline = TRUE
      )
    ),

    footer = tagList(
      actionButton("cache_config_reset", "Reset to Defaults",
                   class = "btn-warning", icon = icon("undo")),
      modalButton("Cancel"),
      actionButton("cache_config_save", "Save Configuration",
                   class = "btn-primary", icon = icon("save"))
    )
  ))
})


#' Save configuration
observeEvent(input$cache_config_save, {

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  new_config <- list(
    max_total_size_gb = input$cache_config_max_size,
    max_projects = input$cache_config_max_projects,
    max_checkpoints_per_stage = input$cache_config_max_versions,
    max_age_days = input$cache_config_max_age,
    auto_cleanup = input$cache_config_auto_cleanup,
    enable_versioning = input$cache_config_versioning,
    enable_logging = input$cache_config_logging,
    atomic_writes = input$cache_config_atomic,
    compression_level = input$cache_config_compression
  )

  cache_ctrl$update_config(new_config)

  removeModal()

  showNotification(
    "Configuration saved successfully",
    type = "message",
    duration = 3
  )
})


#' Reset configuration to defaults
observeEvent(input$cache_config_reset, {

  # Update inputs to defaults
  updateNumericInput(session, "cache_config_max_size", value = 50)
  updateNumericInput(session, "cache_config_max_projects", value = 20)
  updateNumericInput(session, "cache_config_max_versions", value = 5)
  updateNumericInput(session, "cache_config_max_age", value = 60)
  updateCheckboxInput(session, "cache_config_auto_cleanup", value = TRUE)
  updateCheckboxInput(session, "cache_config_versioning", value = TRUE)
  updateCheckboxInput(session, "cache_config_logging", value = TRUE)
  updateCheckboxInput(session, "cache_config_atomic", value = TRUE)
  updateRadioButtons(session, "cache_config_compression", selected = "auto")

  showNotification("Reset to defaults", type = "message", duration = 2)
})


# ===============================================================================
# ENHANCED v3.0 - HEALTH CHECK HANDLERS
# ===============================================================================

#' Perform health check
observeEvent(input$btn_cache_health, {

  removeModal()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  withProgress(message = "Running health check...", value = 0.5, {
    health_result <- cache_ctrl$health_check(repair = FALSE)
  })

  # Determine overall status
  if (health_result$healthy) {
    status_color <- "#28a745"
    status_icon <- "check-circle"
    status_text <- "HEALTHY"
  } else {
    status_color <- "#dc3545"
    status_icon <- "exclamation-triangle"
    status_text <- "ISSUES DETECTED"
  }

  showModal(modalDialog(
    title = div(
      icon("heartbeat"),
      " Cache Health Check",
      style = "color: #495057; font-weight: 600;"
    ),
    size = "m",
    easyClose = TRUE,

    div(
      style = "padding: 15px;",

      # Overall status
      div(
        style = sprintf("
          text-align: center;
          padding: 20px;
          background-color: %s20;
          border-radius: 10px;
          margin-bottom: 20px;
        ", status_color),
        icon(status_icon, style = sprintf("font-size: 48px; color: %s;", status_color)),
        h3(status_text, style = sprintf("color: %s; margin: 10px 0 0 0;", status_color))
      ),

      # Summary statistics
      h5(icon("chart-bar"), " Summary", style = "color: #495057;"),
      hr(style = "margin: 10px 0;"),

      fluidRow(
        column(4,
          div(
            style = "text-align: center; padding: 10px;",
            h4(health_result$summary$total_checkpoints, style = "margin: 0; color: #007bff;"),
            span("Total", class = "text-muted")
          )
        ),
        column(4,
          div(
            style = "text-align: center; padding: 10px;",
            h4(health_result$summary$valid_checkpoints, style = "margin: 0; color: #28a745;"),
            span("Valid", class = "text-muted")
          )
        ),
        column(4,
          div(
            style = "text-align: center; padding: 10px;",
            h4(health_result$summary$corrupted_checkpoints, style = "margin: 0; color: #dc3545;"),
            span("Corrupted", class = "text-muted")
          )
        )
      ),

      # Issues list
      if (length(health_result$issues) > 0) {
        tagList(
          hr(),
          h5(icon("exclamation-circle"), " Issues", style = "color: #dc3545;"),
          hr(style = "margin: 10px 0;"),
          div(
            style = "max-height: 150px; overflow-y: auto;",
            lapply(health_result$issues, function(issue) {
              div(
                style = "padding: 5px; margin: 2px 0; background-color: #fff3cd; border-radius: 3px;",
                icon("exclamation-triangle", style = "color: #856404;"),
                span(issue, style = "margin-left: 5px;")
              )
            })
          )
        )
      }
    ),

    footer = tagList(
      if (!health_result$healthy) {
        actionButton("cache_health_repair", "Attempt Repair",
                     class = "btn-warning", icon = icon("wrench"))
      },
      modalButton("Close")
    )
  ))
})


#' Attempt repair
observeEvent(input$cache_health_repair, {

  removeModal()

  cache_ctrl <- globalCacheController()
  if (is.null(cache_ctrl)) return()

  withProgress(message = "Repairing cache...", value = 0.5, {
    health_result <- cache_ctrl$health_check(repair = TRUE)
  })

  if (length(health_result$repaired) > 0) {
    showNotification(
      sprintf("Repaired %d issue(s)", length(health_result$repaired)),
      type = "message",
      duration = 5
    )
  } else {
    showNotification(
      "No repairs needed or possible",
      type = "warning",
      duration = 3
    )
  }
})


# ===============================================================================
# ENHANCED v3.0 - CACHE STATISTICS
# ===============================================================================

#' Render cache statistics
output$cache_statistics_output <- renderUI({

  cache_ctrl <- globalCacheController()

  if (is.null(cache_ctrl)) {
    return(p("Statistics unavailable", style = "opacity: 0.7;"))
  }

  status <- cache_ctrl$get_status()

  div(
    fluidRow(
      column(4,
        div(
          style = "text-align: center;",
          h4(length(status$available_stages), style = "margin: 0;"),
          span("Checkpoints", style = "font-size: 11px; opacity: 0.8;")
        )
      ),
      column(4,
        div(
          style = "text-align: center;",
          h4(
            if (!is.na(status$total_cache_mb)) sprintf("%.0f", status$total_cache_mb) else "?",
            style = "margin: 0;"
          ),
          span("MB Used", style = "font-size: 11px; opacity: 0.8;")
        )
      ),
      column(4,
        div(
          style = "text-align: center;",
          h4(
            if (!is.na(status$n_projects)) status$n_projects else "?",
            style = "margin: 0;"
          ),
          span("Projects", style = "font-size: 11px; opacity: 0.8;")
        )
      )
    )
  )
})


# ===============================================================================
# END OF FILE
# ===============================================================================

cat("Cache Management Server v3.0 (Enhanced) loaded\n")
