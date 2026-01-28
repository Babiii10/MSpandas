# ═══════════════════════════════════════════════════════════════════════════
# ShinyIntegration.lib.R - Shiny Integration Helpers for Cache System
# ═══════════════════════════════════════════════════════════════════════════
#
# Provides easy-to-use Shiny integration functions for the cache system
#
# Dependencies: shiny, CacheManager.lib.R, RecoveryManager.lib.R
#
# Functions:
# - show_recovery_modal() - Display modal asking user to resume or restart
# - save_checkpoint_with_progress() - Save checkpoint with Shiny progress bar
# - restore_to_reactive() - Restore checkpoint variables to reactiveValues
# - create_checkpoint_button() - Create UI button for manual checkpoints
# - cache_progress_callback() - Progress callback for Shiny
# - init_cache_in_shiny() - Initialize cache system in Shiny app
# - auto_recovery_check() - Automatic crash detection at app startup
#
# ═══════════════════════════════════════════════════════════════════════════

library(shiny)

# ═══════════════════════════════════════════════════════════════════════════
# show_recovery_modal - Display Recovery Modal Dialog
# ═══════════════════════════════════════════════════════════════════════════
#' Display modal dialog asking user to resume from cache or restart
#'
#' @param session Shiny session object
#' @param recovery_info List returned by detect_crash_and_recover()
#' @param on_resume Function to call if user chooses to resume
#' @param on_restart Function to call if user chooses to restart
#'
#' @return NULL (displays modal)
#'
#' @examples
#' show_recovery_modal(session, recovery_info,
#'   on_resume = function() { ... },
#'   on_restart = function() { ... }
#' )
show_recovery_modal <- function(session, recovery_info, on_resume, on_restart) {

  # Extract info
  can_resume <- recovery_info$can_resume
  last_checkpoint <- recovery_info$last_checkpoint
  checkpoint_name <- recovery_info$checkpoint_name
  saved_time <- recovery_info$saved_time

  if (!can_resume) {
    # Cannot resume - just show information modal
    showModal(modalDialog(
      title = "⚠️ Cache Recovery Not Available",
      HTML(paste0(
        "<p>A previous session was detected, but no valid checkpoint was found.</p>",
        "<p>The workflow will start from the beginning.</p>"
      )),
      footer = modalButton("OK"),
      easyClose = FALSE
    ))
    return(invisible(NULL))
  }

  # Build recovery modal
  showModal(modalDialog(
    title = "🔄 Resume Previous Session?",
    HTML(paste0(
      "<div style='padding: 10px;'>",
      "<h4>Previous session detected!</h4>",
      "<p><strong>Last checkpoint:</strong> ", checkpoint_name, "</p>",
      "<p><strong>Saved at:</strong> ", saved_time, "</p>",
      "<p><strong>Checkpoint ID:</strong> ", last_checkpoint, "</p>",
      "<hr>",
      "<p><b>Resume:</b> Continue from the last checkpoint (~ 1 minute)</p>",
      "<p><b>Restart:</b> Start fresh from the beginning</p>",
      "</div>"
    )),
    footer = tagList(
      actionButton("cache_resume_btn", "✅ Resume",
                   class = "btn-success",
                   style = "margin-right: 10px;"),
      actionButton("cache_restart_btn", "🔄 Restart",
                   class = "btn-warning")
    ),
    easyClose = FALSE
  ))

  # Handle Resume button
  observeEvent(session$input$cache_resume_btn, {
    removeModal()
    if (!is.null(on_resume)) {
      on_resume()
    }
  }, once = TRUE)

  # Handle Restart button
  observeEvent(session$input$cache_restart_btn, {
    removeModal()
    if (!is.null(on_restart)) {
      on_restart()
    }
  }, once = TRUE)

  invisible(NULL)
}


# ═══════════════════════════════════════════════════════════════════════════
# save_checkpoint_with_progress - Save Checkpoint with Progress Bar
# ═══════════════════════════════════════════════════════════════════════════
#' Save a checkpoint with Shiny progress notification
#'
#' @param checkpoint_id Checkpoint identifier (e.g., "step_01_peak_picking")
#' @param cache_info Cache info list from init_cache_system()
#' @param variables Named list of variables to save
#' @param step_name Human-readable step name for display
#' @param next_step Description of next step
#' @param progress Shiny progress object (optional, will create if NULL)
#'
#' @return TRUE if successful, FALSE otherwise
#'
#' @examples
#' save_checkpoint_with_progress(
#'   "step_01_peak_picking",
#'   cache_info,
#'   list(peaks = peaks_data, params = params),
#'   "Peak Picking Complete",
#'   "Isotope Annotation"
#' )
save_checkpoint_with_progress <- function(checkpoint_id, cache_info, variables,
                                          step_name, next_step,
                                          progress = NULL) {

  # Create progress if not provided
  close_progress <- FALSE
  if (is.null(progress)) {
    progress <- Progress$new()
    close_progress <- TRUE
    progress$set(message = "Saving checkpoint...", value = 0)
  }

  tryCatch({
    # Update progress
    progress$set(message = paste0("💾 Saving: ", step_name), value = 0.3)

    # Save checkpoint
    result <- save_checkpoint(
      checkpoint_id = checkpoint_id,
      cache_info = cache_info,
      variables = variables,
      step_name = step_name,
      next_step = next_step
    )

    # Update progress
    progress$set(message = "✅ Checkpoint saved!", value = 1)

    # Show notification
    showNotification(
      paste0("✅ Checkpoint saved: ", step_name),
      type = "message",
      duration = 3
    )

    return(result)

  }, error = function(e) {
    showNotification(
      paste0("❌ Failed to save checkpoint: ", e$message),
      type = "error",
      duration = 10
    )
    return(FALSE)

  }, finally = {
    if (close_progress) {
      progress$close()
    }
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# restore_to_reactive - Restore Checkpoint to ReactiveValues
# ═══════════════════════════════════════════════════════════════════════════
#' Restore checkpoint variables into Shiny reactiveValues
#'
#' @param cache_info Cache info list
#' @param checkpoint_id Checkpoint ID to restore
#' @param reactive_values reactiveValues object to restore into
#' @param progress Shiny progress object (optional)
#'
#' @return TRUE if successful, FALSE otherwise
#'
#' @examples
#' restore_to_reactive(cache_info, "step_01_peak_picking", Rvars)
restore_to_reactive <- function(cache_info, checkpoint_id, reactive_values,
                                progress = NULL) {

  # Create progress if not provided
  close_progress <- FALSE
  if (is.null(progress)) {
    progress <- Progress$new()
    close_progress <- TRUE
    progress$set(message = "Restoring checkpoint...", value = 0)
  }

  tryCatch({
    # Progress callback for detailed updates
    prog_callback <- function(msg, value) {
      progress$set(message = msg, value = value)
    }

    # Restore using RecoveryManager
    result <- restore_to_shiny_reactive(
      cache_info = cache_info,
      target_step = checkpoint_id,
      reactive_list = reactive_values,
      progress_callback = prog_callback
    )

    # Show notification
    if (result) {
      showNotification(
        "✅ Checkpoint restored successfully!",
        type = "message",
        duration = 5
      )
    } else {
      showNotification(
        "⚠️ Checkpoint restoration failed",
        type = "warning",
        duration = 10
      )
    }

    return(result)

  }, error = function(e) {
    showNotification(
      paste0("❌ Restoration error: ", e$message),
      type = "error",
      duration = 10
    )
    return(FALSE)

  }, finally = {
    if (close_progress) {
      progress$close()
    }
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# create_checkpoint_button - Create Manual Checkpoint Button UI
# ═══════════════════════════════════════════════════════════════════════════
#' Create a manual checkpoint save button for Shiny UI
#'
#' @param button_id Button input ID
#' @param label Button label text
#' @param icon Icon name (default: "save")
#'
#' @return Shiny UI element
#'
#' @examples
#' create_checkpoint_button("manual_checkpoint", "Save Progress")
create_checkpoint_button <- function(button_id,
                                     label = "💾 Save Checkpoint",
                                     icon = icon("save")) {

  actionButton(
    inputId = button_id,
    label = label,
    icon = icon,
    class = "btn-info",
    style = "margin: 5px;"
  )
}


# ═══════════════════════════════════════════════════════════════════════════
# cache_progress_callback - Progress Callback Generator for Shiny
# ═══════════════════════════════════════════════════════════════════════════
#' Generate a progress callback function for Shiny Progress objects
#'
#' @param progress Shiny Progress object
#'
#' @return Function(message, value) for progress updates
#'
#' @examples
#' progress <- Progress$new()
#' callback <- cache_progress_callback(progress)
#' callback("Loading data...", 0.5)
cache_progress_callback <- function(progress) {
  function(message, value) {
    if (!is.null(progress)) {
      progress$set(message = message, value = value)
    }
  }
}


# ═══════════════════════════════════════════════════════════════════════════
# init_cache_in_shiny - Initialize Cache System in Shiny App
# ═══════════════════════════════════════════════════════════════════════════
#' Initialize cache system at Shiny app startup
#'
#' @param project_name Project name
#' @param data_dir Data directory path
#' @param base_cache_dir Base cache directory (default: "cache_projects")
#' @param reactive_values Optional reactiveValues object to store cache_info
#' @param storage_key Key name in reactive_values (default: "cache_info")
#'
#' @return Cache info list
#'
#' @examples
#' cache_info <- init_cache_in_shiny("MyProject", "/data/raw",
#'                                   reactive_values = Rvars)
init_cache_in_shiny <- function(project_name, data_dir,
                                base_cache_dir = "cache_projects",
                                reactive_values = NULL,
                                storage_key = "cache_info") {

  tryCatch({
    # Initialize cache
    cache_info <- init_cache_system(
      project_name = project_name,
      data_dir = data_dir,
      base_cache_dir = base_cache_dir
    )

    # Store in reactive values if provided
    if (!is.null(reactive_values)) {
      reactive_values[[storage_key]] <- cache_info
    }

    # Show notification
    showNotification(
      paste0("✅ Cache system initialized: ", project_name),
      type = "message",
      duration = 3
    )

    return(cache_info)

  }, error = function(e) {
    showNotification(
      paste0("⚠️ Cache initialization warning: ", e$message),
      type = "warning",
      duration = 5
    )
    return(NULL)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# auto_recovery_check - Automatic Crash Detection at Startup
# ═══════════════════════════════════════════════════════════════════════════
#' Automatically check for crash and show recovery modal if needed
#'
#' Should be called once at app initialization after cache is initialized
#'
#' @param session Shiny session object
#' @param cache_info Cache info list
#' @param on_resume Function to call if user chooses to resume
#' @param on_restart Function to call if user chooses to restart
#' @param auto_show Show modal automatically (default: TRUE)
#'
#' @return Recovery info list from detect_crash_and_recover()
#'
#' @examples
#' auto_recovery_check(session, cache_info,
#'   on_resume = function() { restore_from_cache() },
#'   on_restart = function() { clean_cache() }
#' )
auto_recovery_check <- function(session, cache_info, on_resume, on_restart,
                               auto_show = TRUE) {

  tryCatch({
    # Detect crash
    recovery_info <- detect_crash_and_recover(cache_info, verbose = FALSE)

    # Show modal if crash detected and auto_show enabled
    if (recovery_info$should_prompt && auto_show) {
      show_recovery_modal(session, recovery_info, on_resume, on_restart)
    }

    return(recovery_info)

  }, error = function(e) {
    showNotification(
      paste0("⚠️ Recovery check warning: ", e$message),
      type = "warning",
      duration = 5
    )
    return(list(
      should_prompt = FALSE,
      can_resume = FALSE,
      error = e$message
    ))
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# Helper: Show Cache Information Panel
# ═══════════════════════════════════════════════════════════════════════════
#' Display cache information in Shiny app
#'
#' @param cache_info Cache info list
#'
#' @return HTML string for display
show_cache_info_panel <- function(cache_info) {

  if (is.null(cache_info)) {
    return(HTML("<p>Cache not initialized</p>"))
  }

  tryCatch({
    info <- get_cache_info(cache_info)
    checkpoints <- list_checkpoints(cache_info)

    html_content <- paste0(
      "<div style='padding: 10px; border: 1px solid #ddd; border-radius: 5px;'>",
      "<h4>📦 Cache Information</h4>",
      "<p><strong>Project:</strong> ", info$project_name, "</p>",
      "<p><strong>Cache ID:</strong> ", info$cache_id, "</p>",
      "<p><strong>Created:</strong> ", info$created_time, "</p>",
      "<p><strong>Total checkpoints:</strong> ", nrow(checkpoints), "</p>",
      "<p><strong>Total size:</strong> ", sprintf("%.2f MB", info$total_size_mb), "</p>",
      "<hr>",
      "<h5>Available Checkpoints:</h5>",
      "<ul>"
    )

    if (nrow(checkpoints) > 0) {
      for (i in 1:nrow(checkpoints)) {
        cp <- checkpoints[i, ]
        html_content <- paste0(html_content,
          "<li><strong>", cp$step_name, "</strong><br>",
          "ID: ", cp$checkpoint_id, " | ",
          "Size: ", sprintf("%.2f MB", cp$size_mb), " | ",
          "Time: ", cp$saved_time,
          "</li>"
        )
      }
    } else {
      html_content <- paste0(html_content, "<li>No checkpoints yet</li>")
    }

    html_content <- paste0(html_content, "</ul></div>")

    return(HTML(html_content))

  }, error = function(e) {
    return(HTML(paste0("<p>Error displaying cache info: ", e$message, "</p>")))
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# Helper: Create Cache Management UI Module
# ═══════════════════════════════════════════════════════════════════════════
#' Create a complete cache management UI panel
#'
#' @param id Namespace ID for module
#'
#' @return Shiny UI element
cache_management_ui <- function(id) {
  ns <- NS(id)

  tagList(
    wellPanel(
      h3("🗄️ Cache Management"),

      fluidRow(
        column(6,
          actionButton(ns("save_checkpoint"),
                      "💾 Save Checkpoint Now",
                      class = "btn-info btn-block")
        ),
        column(6,
          actionButton(ns("clean_cache"),
                      "🗑️ Clean Old Caches",
                      class = "btn-warning btn-block")
        )
      ),

      hr(),

      htmlOutput(ns("cache_info_display")),

      hr(),

      fluidRow(
        column(6,
          actionButton(ns("refresh_info"),
                      "🔄 Refresh Info",
                      class = "btn-default btn-sm")
        ),
        column(6,
          downloadButton(ns("export_metadata"),
                        "📥 Export Metadata",
                        class = "btn-default btn-sm")
        )
      )
    )
  )
}


# ═══════════════════════════════════════════════════════════════════════════
# End of ShinyIntegration.lib.R
# ═══════════════════════════════════════════════════════════════════════════

cat("✅ ShinyIntegration.lib.R loaded successfully\n")
