# ===============================================================================
# cacheManagementAnalysisNewSamples.server.R
# Cache Management Server Logic for Analysis New Samples Pipeline
# ===============================================================================
#
# Description: Server-side logic for cache management in the Analysis New Samples
#              workflow. Mirrors the architecture of cacheManagement.server.R
#              with project-name-based initialization and hierarchical
#              manual save/restore (no auto-save).
#
# Requires: globalCacheControllerANS, cacheStateANS,
#           RvarsPeakDetectionNewSample, RvarsMatchNewsample, RvarsNormalizeNewsample
# ===============================================================================


# ===============================================================================
# CACHE INITIALIZATION - Triggered by project name
# ===============================================================================

#' Initialize ANS cache when project name input changes (early initialization)
#' This triggers as soon as user types a project name
projectName_ANS_debounced <- shiny::debounce(
  reactive(input$projectName),
  millis = 1200
)

observeEvent(projectName_ANS_debounced(), {
  
  project_name <- projectName_ANS_debounced()
  
  cat("\n[ANS CACHE DEBUG] input$projectName changed:", project_name, "\n")
  
  if (!is.null(project_name) && nchar(trimws(project_name)) > 0) {
    
    # Check if already initialized with this project
    if (cacheStateANS$initialized && cacheStateANS$project_name == project_name) {
      cat("[ANS CACHE DEBUG] Already initialized for this project\n")
      return()
    }
    
    # Get data directory if available
    data_dir <- if (exists("directoryInput") && !is.null(directoryInput$directory)) {
      directoryInput$directory
    } else {
      getwd()
    }
    
    cat("[ANS CACHE DEBUG] Creating ANS cache controller...\n")
    cat("[ANS CACHE DEBUG] Project:", project_name, "\n")
    cat("[ANS CACHE DEBUG] Data dir:", data_dir, "\n")
    
    # Create cache controller
    tryCatch({
      ans_ctrl <- create_ans_cache_controller(
        project_name = project_name,
        data_dir = data_dir,
        base_cache_dir = "cache_projects_ans"
      )
      
      # Initialize the controller
      ans_ctrl$initialize(verbose = TRUE, reuse_existing = TRUE)
      
      # Store controller
      globalCacheControllerANS(ans_ctrl)
      cacheStateANS$initialized <- TRUE
      cacheStateANS$project_name <- project_name
      
      cat("[ANS CACHE DEBUG] ANS Cache initialized successfully!\n")
      
      # Check for recovery
      recovery_info <- ans_ctrl$check_recovery(verbose = TRUE)
      
      if (isTRUE(recovery_info$can_resume) && isTRUE(recovery_info$mode == "resume")) {
        cacheStateANS$can_resume <- TRUE
        cacheStateANS$recovery_pending <- TRUE
        
        # Show recovery modal
        showModal(modalDialog(
          title = div(
            icon("sync", class = "fa-spin"),
            " Previous Analysis Session Detected",
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
            hr(),
            p(class = "text-info",
              icon("info-circle"),
              " Resuming will restore all analysis pipeline data from the last saved state."
            )
          ),
          footer = tagList(
            actionButton("ans_cache_restart_fresh", "Start Fresh",
                         class = "btn-warning",
                         icon = icon("redo")),
            actionButton("ans_cache_resume_session", "Resume Session",
                         class = "btn-success",
                         icon = icon("play"))
          ),
          easyClose = FALSE
        ))
      }
      
      showNotification(
        paste("Analysis cache initialized for:", project_name),
        type = "message",
        duration = 3
      )
      
    }, error = function(e) {
      cat("[ANS CACHE DEBUG] ERROR:", e$message, "\n")
      showNotification(
        paste("Analysis cache initialization warning:", e$message),
        type = "warning",
        duration = 5
      )
    })
  }
}, ignoreInit = TRUE)


#' Also initialize cache when the reactive variable is set (backup trigger)
observeEvent(RvarsPeakDetectionNewSample$Project_Name, {
  
  project_name <- RvarsPeakDetectionNewSample$Project_Name
  
  cat("\n[ANS CACHE DEBUG] RvarsPeakDetectionNewSample$Project_Name changed:", project_name, "\n")
  
  if (!is.null(project_name) && nchar(trimws(project_name)) > 0) {
    
    # Check if already initialized
    if (cacheStateANS$initialized) {
      cat("[ANS CACHE DEBUG] ANS Cache already initialized\n")
      return()
    }
    
    # Get data directory
    data_dir <- if (exists("directoryInput") && !is.null(directoryInput$directory)) {
      directoryInput$directory
    } else {
      getwd()
    }
    
    # Create cache controller
    tryCatch({
      ans_ctrl <- create_ans_cache_controller(
        project_name = project_name,
        data_dir = data_dir,
        base_cache_dir = "cache_projects_ans"
      )
      
      # Initialize the controller
      ans_ctrl$initialize(verbose = TRUE, reuse_existing = TRUE)
      
      # Store controller
      globalCacheControllerANS(ans_ctrl)
      cacheStateANS$initialized <- TRUE
      cacheStateANS$project_name <- project_name
      
      showNotification(
        paste("Analysis cache ready:", project_name),
        type = "message",
        duration = 3
      )
      
    }, error = function(e) {
      cat("[ANS CACHE DEBUG] ERROR:", e$message, "\n")
      showNotification(
        paste("Analysis cache initialization warning:", e$message),
        type = "warning",
        duration = 5
      )
    })
  }
}, ignoreInit = TRUE)


# ===============================================================================
# RECOVERY HANDLERS
# ===============================================================================

#' Handle resume session button for ANS
observeEvent(input$ans_cache_resume_session, {
  
  removeModal()
  
  ans_ctrl <- globalCacheControllerANS()
  if (is.null(ans_ctrl)) return()
  
  # Get available stages
  available <- ans_ctrl$list_available_stages()
  
  if (length(available) == 0) {
    showNotification("No analysis checkpoints available", type = "warning")
    return()
  }
  
  # Get the latest stage
  target_stage <- tail(available, 1)
  
  withProgress(message = "Restoring analysis session...", value = 0, {
    
    reactive_vars <- list(
      PeakDetection = RvarsPeakDetectionNewSample,
      Match = RvarsMatchNewsample,
      Normalize = RvarsNormalizeNewsample
    )
    
    # Restore all stages up to target
    result <- ans_ctrl$restore_all_stages(
      target_stage = target_stage,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )
    
    if (result) {
      cacheStateANS$recovery_pending <- FALSE
      
      showNotification(
        paste("Analysis session restored to:",
              ans_ctrl$STAGES[[target_stage]]$name),
        type = "message",
        duration = 5
      )
      
      # Navigate to appropriate page based on restored stage
      navigate_to_ans_stage(session, target_stage)
      
    } else {
      showNotification(
        "Failed to restore analysis session. Starting fresh.",
        type = "error",
        duration = 5
      )
    }
  })
})


#' Handle restart fresh button for ANS
observeEvent(input$ans_cache_restart_fresh, {
  
  removeModal()
  cacheStateANS$recovery_pending <- FALSE
  cacheStateANS$initialized <- FALSE
  cacheStateANS$can_resume <- FALSE
  
  # Force creation of a new cache folder
  tryCatch({
    project_name <- cacheStateANS$project_name
    if (is.null(project_name) || nchar(trimws(project_name)) == 0) {
      project_name <- input$projectName
    }
    if (is.null(project_name) || nchar(trimws(project_name)) == 0) {
      return()
    }
    
    data_dir <- if (exists("directoryInput") && !is.null(directoryInput$directory)) {
      directoryInput$directory
    } else {
      getwd()
    }
    
    ans_ctrl <- create_ans_cache_controller(
      project_name = project_name,
      data_dir = data_dir,
      base_cache_dir = "cache_projects_ans"
    )
    
    ans_ctrl$initialize(verbose = TRUE, reuse_existing = FALSE)
    
    globalCacheControllerANS(ans_ctrl)
    cacheStateANS$initialized <- TRUE
    cacheStateANS$project_name <- project_name
  }, error = function(e) {
    cat("[ANS CACHE DEBUG] ERROR (restart fresh):", e$message, "\n")
  })
  
  showNotification(
    "Starting fresh analysis workflow",
    type = "message",
    duration = 3
  )
})


# ===============================================================================
# MANUAL CACHE CONTROLS - Hierarchical Save
# ===============================================================================

#' Handle manual save checkpoint button
observeEvent(input$btn_save_checkpoint_ans, {
  
  ans_ctrl <- globalCacheControllerANS()
  
  if (is.null(ans_ctrl)) {
    showNotification("Analysis cache not initialized. Set a project name first.", type = "warning")
    return()
  }
  
  # Show stage selection modal
  showModal(modalDialog(
    title = div(icon("save"), " Save Analysis Checkpoint"),
    div(
      style = "padding: 10px;",
      selectInput(
        "ans_cache_save_stage_select",
        "Select pipeline stage to save:",
        choices = setNames(
          names(ans_ctrl$STAGES),
          sapply(ans_ctrl$STAGES, function(x) x$name)
        )
      ),
      p(class = "text-muted",
        icon("info-circle"),
        " This will save all data up to and including the selected stage."
      )
    ),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("ans_cache_confirm_save", "Save Checkpoint",
                   class = "btn-primary", icon = icon("save"))
    )
  ))
})


#' Confirm manual save
observeEvent(input$ans_cache_confirm_save, {
  
  removeModal()
  
  ans_ctrl <- globalCacheControllerANS()
  stage_key <- input$ans_cache_save_stage_select
  
  if (is.null(ans_ctrl) || is.null(stage_key)) return()
  
  withProgress(message = "Saving analysis checkpoint...", value = 0, {
    
    reactive_vars <- list(
      PeakDetection = RvarsPeakDetectionNewSample,
      Match = RvarsMatchNewsample,
      Normalize = RvarsNormalizeNewsample
    )
    
    result <- ans_ctrl$save_stage(
      stage_key = stage_key,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )
    
    if (result) {
      showNotification(
        paste("Checkpoint saved:", ans_ctrl$STAGES[[stage_key]]$name),
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


# ===============================================================================
# MANUAL CACHE CONTROLS - Hierarchical Restore
# ===============================================================================

#' Handle manual restore button
observeEvent(input$btn_restore_checkpoint_ans, {
  
  ans_ctrl <- globalCacheControllerANS()
  
  if (is.null(ans_ctrl)) {
    showNotification("Analysis cache not initialized", type = "warning")
    return()
  }
  
  available <- ans_ctrl$list_available_stages()
  
  if (length(available) == 0) {
    showNotification("No analysis checkpoints available to restore", type = "warning")
    return()
  }
  
  # Show restore selection modal with hierarchical choices
  showModal(modalDialog(
    title = div(icon("undo"), " Restore Analysis Checkpoint"),
    div(
      style = "padding: 10px;",
      selectInput(
        "ans_cache_restore_stage_select",
        "Select checkpoint to restore:",
        choices = setNames(
          available,
          sapply(available, function(x) ans_ctrl$STAGES[[x]]$name)
        ),
        selected = tail(available, 1)
      ),
      p(class = "text-warning",
        icon("exclamation-triangle"),
        " Warning: This will overwrite current analysis data in memory!"
      )
    ),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("ans_cache_confirm_restore", "Restore",
                   class = "btn-success", icon = icon("undo"))
    )
  ))
})


#' Confirm manual restore
observeEvent(input$ans_cache_confirm_restore, {
  
  removeModal()
  
  ans_ctrl <- globalCacheControllerANS()
  stage_key <- input$ans_cache_restore_stage_select
  
  if (is.null(ans_ctrl) || is.null(stage_key)) return()
  
  withProgress(message = "Restoring analysis checkpoint...", value = 0, {
    
    reactive_vars <- list(
      PeakDetection = RvarsPeakDetectionNewSample,
      Match = RvarsMatchNewsample,
      Normalize = RvarsNormalizeNewsample
    )
    
    result <- ans_ctrl$restore_all_stages(
      target_stage = stage_key,
      reactive_vars = reactive_vars,
      verbose = TRUE
    )
    
    if (result) {
      showNotification(
        paste("Restored to:", ans_ctrl$STAGES[[stage_key]]$name),
        type = "message",
        duration = 5
      )
      
      # Navigate to appropriate page
      navigate_to_ans_stage(session, stage_key)
      
    } else {
      showNotification("Failed to restore analysis checkpoint", type = "error", duration = 5)
    }
  })
})


# ===============================================================================
# CACHE STATUS DISPLAY
# ===============================================================================

#' Render ANS cache status panel
output$ans_cache_status_panel_output <- renderUI({
  
  ans_ctrl <- globalCacheControllerANS()
  
  if (is.null(ans_ctrl) || !cacheStateANS$initialized) {
    return(div(
      class = "alert alert-info",
      style = "margin: 10px;",
      icon("info-circle"),
      " Analysis cache not initialized. Enter a project name to enable caching."
    ))
  }
  
  status <- ans_ctrl$get_status()
  available <- status$available_stages
  
  # Build stage indicators
  stage_badges <- lapply(names(ans_ctrl$STAGES), function(stage_key) {
    stage <- ans_ctrl$STAGES[[stage_key]]
    
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
      " Analysis Cache Status",
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
        "btn_save_checkpoint_ans",
        "Save",
        icon = icon("save"),
        class = "btn-primary btn-sm",
        style = "margin: 2px;"
      ),
      actionButton(
        "btn_restore_checkpoint_ans",
        "Restore",
        icon = icon("undo"),
        class = "btn-success btn-sm",
        style = "margin: 2px;"
      )
    )
  )
})


# ===============================================================================
# HELPER FUNCTIONS
# ===============================================================================

#' Navigate to appropriate UI page based on restored ANS stage
navigate_to_ans_stage <- function(session, stage_key) {
  
  switch(stage_key,
         
         "ans_peak_detection" = {
           updateNavbarPage(session, "analysisNavbar",
                            selected = "Peak detection and grouping")
           updateRadioButtons(session, "IdAnalysisStep", selected = "2")
         },
         
         "ans_temporal_correction" = {
           updateNavbarPage(session, "analysisNavbar",
                            selected = "Peak detection and grouping")
           updateRadioButtons(session, "IdAnalysisStep", selected = "3")
         },
         
         "ans_grouping" = {
           updateNavbarPage(session, "analysisNavbar",
                            selected = "Peak detection and grouping")
           updateRadioButtons(session, "IdAnalysisStep", selected = "4")
         },
         
         "ans_match_reference" = {
           updateNavbarPage(session, "analysisNavbar",
                            selected = "Match reference map")
         },
         
         "ans_normalization" = {
           updateNavbarPage(session, "analysisNavbar",
                            selected = "Samples normalization")
         }
  )
}


cat("ANS Cache Management Server loaded\n")
