# ===============================================================================
# cacheManagement.ui.R - Cache Management UI Components
# ===============================================================================
#
# Description: UI components for cache management panel in MSpandas
#
# Features:
#   - Cache status display with stage indicators
#   - Save/Restore checkpoint buttons
#   - Auto-save toggle
#   - Project cache information
#
# Author: MSpandas Team
# Version: 2.0.0
# Date: 2026-02-01
#
# ===============================================================================

#' Create the main cache management sidebar panel
#' This panel can be included in the UI sidebar
cache_management_sidebar_ui <- function() {
  
  div(
    id = "cache_sidebar_panel",
    
    # Header
    div(
      style = "
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 12px 15px;
        border-radius: 8px 8px 0 0;
        margin: -15px -15px 15px -15px;
      ",
      h5(
        icon("database"),
        "Cache Manager",
        style = "margin: 0; font-weight: 600;"
      )
    ),
    
    # Status panel (rendered dynamically)
    uiOutput("cache_status_panel_output"),
    
    hr(style = "margin: 15px 0;"),
    
    # Auto-save toggle
    div(
      style = "padding: 10px; background-color: #f8f9fa; border-radius: 5px;",
      checkboxInput(
        "cache_auto_save_toggle",
        label = shiny::span(
          icon("bolt"),
          " Enable Auto-save Checkpoints"
        ),
        value = TRUE
      ),
      p(
        class = "text-muted small",
        style = "margin-bottom: 0;",
        "Automatically saves progress after each pipeline stage."
      )
    )
  )
}


#' Create a floating cache control button
#' This is a persistent button that appears on all pages
cache_floating_button_ui <- function() {
  
  div(
    id = "cache_floating_controls",
    style = "
      position: fixed;
      bottom: 20px;
      right: 20px;
      z-index: 1000;
    ",
    
    # Dropdown button group
    div(
      class = "btn-group dropup",
      
      # Main button
      tags$button(
        type = "button",
        class = "btn btn-info dropdown-toggle",
        `data-toggle` = "dropdown",
        `aria-haspopup` = "true",
        `aria-expanded` = "false",
        style = "
          border-radius: 50px;
          padding: 12px 20px;
          box-shadow: 0 4px 15px rgba(0,0,0,0.2);
          font-weight: 600;
        ",
        icon("save"),
        " Cache"
      ),
      
      # Dropdown menu
      tags$ul(
        class = "dropdown-menu dropdown-menu-right",
        style = "
          border-radius: 10px;
          box-shadow: 0 5px 25px rgba(0,0,0,0.15);
          padding: 10px;
          min-width: 200px;
        ",
        
        tags$li(
          actionLink(
            "btn_save_checkpoint_global",
            label = shiny::span(icon("save"), " Save Checkpoint"),
            style = "
              display: block;
              padding: 8px 15px;
              color: #333;
              border-radius: 5px;
            "
          )
        ),
        tags$li(
          actionLink(
            "btn_restore_checkpoint_global",
            label = shiny::span(icon("undo"), " Restore from Cache"),
            style = "
              display: block;
              padding: 8px 15px;
              color: #333;
              border-radius: 5px;
            "
          )
        ),
        tags$li(class = "divider", role = "separator"),
        tags$li(
          actionLink(
            "btn_view_cache_status",
            label = shiny::span(icon("info-circle"), " View Cache Status"),
            style = "
              display: block;
              padding: 8px 15px;
              color: #666;
              border-radius: 5px;
            "
          )
        )
      )
    )
  )
}


#' Create a cache status modal
#' Shows detailed information about current cache state
cache_status_modal_ui <- function() {
  
  # This is dynamically created by the server
  # Placeholder for reference
  NULL
}


#' Create inline cache controls for embedding in pages
#' A compact version of cache controls
cache_inline_controls_ui <- function() {
  
  div(
    class = "btn-group",
    style = "margin: 5px 0;",
    
    actionButton(
      "btn_quick_save",
      label = shiny::span(icon("save"), " Quick Save"),
      class = "btn-primary btn-sm"
    ),
    
    actionButton(
      "btn_quick_restore",
      label = shiny::span(icon("undo"), " Restore"),
      class = "btn-success btn-sm"
    )
  )
}


#' Cache progress indicator
#' Shows pipeline progress with cached stages highlighted
cache_progress_indicator_ui <- function() {
  
  div(
    id = "cache_progress_indicator",
    style = "
      padding: 15px;
      background: linear-gradient(to right, #f8f9fa, #ffffff);
      border-radius: 8px;
      border: 1px solid #e9ecef;
      margin: 10px 0;
    ",
    
    h6(
      icon("tasks"),
      " Pipeline Progress",
      style = "color: #495057; margin-bottom: 15px;"
    ),
    
    # Progress steps (will be updated dynamically)
    div(
      id = "cache_progress_steps",
      style = "display: flex; justify-content: space-between; align-items: center;",
      
      # Step 1: Peak Detection
      cache_step_indicator(1, "Peak Detection", "flask"),
      
      # Connector
      cache_step_connector(),
      
      # Step 2: Temporal Correction
      cache_step_indicator(2, "Time Correction", "clock"),
      
      # Connector
      cache_step_connector(),
      
      # Step 3: Grouping
      cache_step_indicator(3, "Grouping", "object-group"),
      
      # Connector
      cache_step_connector(),
      
      # Step 4: Reference Map
      cache_step_indicator(4, "Reference Map", "map"),
      
      # Connector
      cache_step_connector(),
      
      # Step 5: Normalizers
      cache_step_indicator(5, "Normalizers", "balance-scale")
    )
  )
}


#' Create a single step indicator
#' @param step_num Step number (1-5)
#' @param label Step label
#' @param icon_name FontAwesome icon name
cache_step_indicator <- function(step_num, label, icon_name) {
  
  div(
    class = "cache-step",
    id = paste0("cache_step_", step_num),
    style = "text-align: center; flex: 0 0 auto;",
    
    # Circle with icon
    div(
      class = "step-circle",
      style = "
        width: 40px;
        height: 40px;
        border-radius: 50%;
        background-color: #e9ecef;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto 5px auto;
        transition: all 0.3s ease;
      ",
      icon(icon_name, style = "color: #adb5bd;")
    ),
    
    # Label
    shiny::span(
      class = "step-label",
      style = "font-size: 10px; color: #6c757d;",
      label
    )
  )
}


#' Create a connector line between steps
cache_step_connector <- function() {
  
  div(
    class = "step-connector",
    style = "
      flex: 1;
      height: 2px;
      background-color: #dee2e6;
      margin: 0 5px;
      margin-bottom: 20px;
    "
  )
}


#' CSS styles for cache UI components
cache_ui_styles <- function() {
  
  tags$style(HTML("
    /* Cache step active state */
    .cache-step.active .step-circle {
      background-color: #28a745 !important;
      box-shadow: 0 0 0 3px rgba(40, 167, 69, 0.2);
    }

    .cache-step.active .step-circle .fa {
      color: white !important;
    }

    .cache-step.active .step-label {
      color: #28a745 !important;
      font-weight: 600;
    }

    /* Cache step cached (saved) state */
    .cache-step.cached .step-circle {
      background-color: #17a2b8 !important;
    }

    .cache-step.cached .step-circle .fa {
      color: white !important;
    }

    .cache-step.cached .step-label {
      color: #17a2b8 !important;
    }

    /* Connector active state */
    .step-connector.active {
      background-color: #28a745 !important;
    }

    /* Floating button hover effects */
    #cache_floating_controls .btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(0,0,0,0.25) !important;
    }

    /* Dropdown menu items hover */
    #cache_floating_controls .dropdown-menu li a:hover {
      background-color: #f8f9fa;
    }

    /* Cache status panel animations */
    #cache_status_panel_output {
      transition: all 0.3s ease;
    }

    /* Auto-save toggle styling */
    #cache_auto_save_toggle + label {
      font-weight: 500;
    }

    /* Recovery modal styling */
    .modal-content {
      border-radius: 12px;
      overflow: hidden;
    }

    .modal-header {
      border-bottom: none;
    }

    .modal-footer {
      border-top: none;
      padding: 15px 20px 20px;
    }

    /* Badge styles for checkpoints */
    .label-success {
      background-color: #28a745;
    }

    .label-default {
      background-color: #adb5bd;
    }

    /* Notification styling for cache operations */
    .shiny-notification {
      border-radius: 8px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    }
  "))
}


# ===============================================================================
# Enhanced v3.0 UI Components
# ===============================================================================

#' Cache configuration modal UI
#' Shows configuration options for the cache system
cache_config_modal_ui <- function() {
  
  modalDialog(
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
                 value = 50,
                 min = 1,
                 max = 500,
                 step = 5
               )
        ),
        column(6,
               numericInput(
                 "cache_config_max_projects",
                 "Max projects:",
                 value = 20,
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
                 value = 5,
                 min = 1,
                 max = 20,
                 step = 1
               )
        ),
        column(6,
               numericInput(
                 "cache_config_max_age",
                 "Max age (days):",
                 value = 60,
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
                 shiny::span(icon("broom"), " Auto cleanup"),
                 value = TRUE
               ),
               checkboxInput(
                 "cache_config_versioning",
                 shiny::span(icon("code-branch"), " Enable versioning"),
                 value = TRUE
               )
        ),
        column(6,
               checkboxInput(
                 "cache_config_logging",
                 shiny::span(icon("file-alt"), " Enable logging"),
                 value = TRUE
               ),
               checkboxInput(
                 "cache_config_atomic",
                 shiny::span(icon("shield-alt"), " Atomic writes"),
                 value = TRUE
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
        selected = "auto",
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
  )
}


#' Cache health check modal UI
cache_health_modal_ui <- function(health_result) {
  
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
  
  modalDialog(
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
                 shiny::span("Total", class = "text-muted")
               )
        ),
        column(4,
               div(
                 style = "text-align: center; padding: 10px;",
                 h4(health_result$summary$valid_checkpoints, style = "margin: 0; color: #28a745;"),
                 shiny::span("Valid", class = "text-muted")
               )
        ),
        column(4,
               div(
                 style = "text-align: center; padding: 10px;",
                 h4(health_result$summary$corrupted_checkpoints, style = "margin: 0; color: #dc3545;"),
                 shiny::span("Corrupted", class = "text-muted")
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
                shiny::span(issue, style = "margin-left: 5px;")
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
  )
}


#' Cache statistics panel
cache_statistics_ui <- function() {
  
  div(
    id = "cache_statistics_panel",
    style = "
      padding: 15px;
      background: linear-gradient(to right, #667eea, #764ba2);
      border-radius: 10px;
      color: white;
      margin: 10px 0;
    ",
    
    h5(
      icon("chart-pie"),
      " Cache Statistics",
      style = "margin-top: 0; font-weight: 600;"
    ),
    
    hr(style = "border-color: rgba(255,255,255,0.2); margin: 10px 0;"),
    
    # Dynamic content
    uiOutput("cache_statistics_output")
  )
}


# ===============================================================================
# EXPORT UI COMPONENTS
# ===============================================================================

# Return a list of UI functions for use in main ui.R
list(
  sidebar = cache_management_sidebar_ui,
  floating_button = cache_floating_button_ui,
  inline_controls = cache_inline_controls_ui,
  progress_indicator = cache_progress_indicator_ui,
  styles = cache_ui_styles,
  # Enhanced v3.0
  config_modal = cache_config_modal_ui,
  health_modal = cache_health_modal_ui,
  statistics = cache_statistics_ui
)
