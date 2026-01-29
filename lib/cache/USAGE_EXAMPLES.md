# Usage Examples - Cache System Integration

This document provides practical examples for integrating the cache system into the MSpandas Shiny application.

---

## Table of Contents

1. [Basic Setup](#1-basic-setup)
2. [Server.R Integration](#2-serverr-integration)
3. [Workflow Checkpoint Integration](#3-workflow-checkpoint-integration)
4. [Recovery Scenarios](#4-recovery-scenarios)
5. [Manual Checkpoints](#5-manual-checkpoints)
6. [Advanced Usage](#6-advanced-usage)

---

## 1. Basic Setup

### Load Required Libraries

```r
# In your server.R or global.R
source("lib/cache/CacheManager.lib.R")
source("lib/cache/RecoveryManager.lib.R")
source("lib/cache/ShinyIntegration.lib.R")
```

### Initialize Cache at App Startup

```r
# In server.R, at the beginning of server function
server <- function(input, output, session) {

  # Initialize reactive values
  Rvars <- reactiveValues()

  # Initialize cache system when project is loaded
  observeEvent(input$project_name, {
    req(input$project_name)
    req(input$data_directory)

    # Initialize cache
    cache_info <- init_cache_in_shiny(
      project_name = input$project_name,
      data_dir = input$data_directory,
      base_cache_dir = "cache_projects",
      reactive_values = Rvars,
      storage_key = "cache_info"
    )

    # Automatic crash detection
    if (!is.null(cache_info)) {
      auto_recovery_check(
        session = session,
        cache_info = cache_info,
        on_resume = function() {
          # User chose to resume
          recovery_info <- detect_crash_and_recover(cache_info)

          # Restore from last checkpoint
          restore_to_reactive(
            cache_info = cache_info,
            checkpoint_id = recovery_info$last_checkpoint,
            reactive_values = Rvars
          )

          # Update UI to show resumed state
          showNotification(
            paste0("✅ Resumed from: ", recovery_info$checkpoint_name),
            type = "message",
            duration = 5
          )
        },
        on_restart = function() {
          # User chose to restart - clean cache
          showNotification(
            "Starting fresh workflow",
            type = "message",
            duration = 3
          )
        }
      )
    }
  })

  # ... rest of your server code
}
```

---

## 2. Server.R Integration

### Complete Server Integration Example

```r
server <- function(input, output, session) {

  # Reactive values
  Rvars <- reactiveValues(
    cache_info = NULL,
    peaks = NULL,
    isotopes = NULL,
    groups = NULL,
    normalized = NULL
  )

  # ═══════════════════════════════════════════════════════════════
  # STEP 1: Project Initialization with Cache
  # ═══════════════════════════════════════════════════════════════

  observeEvent(input$start_analysis, {
    req(input$project_name)
    req(input$data_directory)

    # Initialize cache
    Rvars$cache_info <- init_cache_system(
      project_name = input$project_name,
      data_dir = input$data_directory,
      base_cache_dir = "cache_projects"
    )

    # Check for crash recovery
    recovery_info <- detect_crash_and_recover(Rvars$cache_info, verbose = TRUE)

    if (recovery_info$should_prompt) {
      # Show modal
      show_recovery_modal(
        session = session,
        recovery_info = recovery_info,
        on_resume = function() {
          # Restore from last checkpoint
          restore_to_reactive(
            cache_info = Rvars$cache_info,
            checkpoint_id = recovery_info$last_checkpoint,
            reactive_values = Rvars
          )
        },
        on_restart = function() {
          # Start fresh
          showNotification("Starting new analysis", type = "message")
        }
      )
    }
  })

  # ═══════════════════════════════════════════════════════════════
  # STEP 2: Peak Picking with Checkpoint
  # ═══════════════════════════════════════════════════════════════

  observeEvent(input$run_peak_picking, {
    req(Rvars$cache_info)

    withProgress(message = "Peak Picking...", value = 0, {

      # Your existing peak picking code
      incProgress(0.3, detail = "Processing files...")

      # Simulate peak picking
      Rvars$peaks <- process_peak_picking(
        files = input$data_files,
        params = list(...)
      )

      incProgress(0.3, detail = "Finalizing...")

      # 💾 SAVE CHECKPOINT
      save_checkpoint_with_progress(
        checkpoint_id = "step_01_peak_picking",
        cache_info = Rvars$cache_info,
        variables = list(
          peaks = Rvars$peaks,
          file_list = input$data_files,
          params = list(...)
        ),
        step_name = "Peak Picking Complete",
        next_step = "Isotope Annotation"
      )

      incProgress(0.4, detail = "Checkpoint saved!")
    })
  })

  # ═══════════════════════════════════════════════════════════════
  # STEP 3: Isotope Annotation with Checkpoint
  # ═══════════════════════════════════════════════════════════════

  observeEvent(input$run_isotope_annotation, {
    req(Rvars$peaks)
    req(Rvars$cache_info)

    withProgress(message = "Isotope Annotation...", value = 0, {

      incProgress(0.3, detail = "Analyzing isotopes...")

      # Your existing isotope annotation code
      Rvars$isotopes <- annotate_isotopes(
        peaks = Rvars$peaks,
        params = list(...)
      )

      incProgress(0.3, detail = "Processing results...")

      # 💾 SAVE CHECKPOINT
      save_checkpoint_with_progress(
        checkpoint_id = "step_02_isotope_annotation",
        cache_info = Rvars$cache_info,
        variables = list(
          peaks = Rvars$peaks,
          isotopes = Rvars$isotopes,
          isotope_params = list(...)
        ),
        step_name = "Isotope Annotation Complete",
        next_step = "Grouping Massif"
      )

      incProgress(0.4, detail = "Checkpoint saved!")
    })
  })

  # ═══════════════════════════════════════════════════════════════
  # STEP 4: Grouping with Checkpoint
  # ═══════════════════════════════════════════════════════════════

  observeEvent(input$run_grouping, {
    req(Rvars$isotopes)
    req(Rvars$cache_info)

    withProgress(message = "Grouping Massif...", value = 0, {

      incProgress(0.2, detail = "First grouping...")

      # Your existing grouping code
      res1 <- bplapply(...) # First grouping

      incProgress(0.3, detail = "Second grouping...")

      res2 <- bplapply(...) # Second grouping

      incProgress(0.2, detail = "Finalizing groups...")

      Rvars$groups <- process_grouping_results(res1, res2)

      # 💾 SAVE CHECKPOINT
      save_checkpoint_with_progress(
        checkpoint_id = "step_03_grouping",
        cache_info = Rvars$cache_info,
        variables = list(
          peaks = Rvars$peaks,
          isotopes = Rvars$isotopes,
          groups = Rvars$groups,
          grouping_params = list(...)
        ),
        step_name = "Grouping Complete",
        next_step = "Internal Standard Search"
      )

      incProgress(0.3, detail = "Checkpoint saved!")
    })
  })

  # ═══════════════════════════════════════════════════════════════
  # STEP 5: Normalization with Checkpoint (CRITICAL!)
  # ═══════════════════════════════════════════════════════════════

  observeEvent(input$run_normalization, {
    req(Rvars$groups)
    req(Rvars$cache_info)

    withProgress(message = "Searching Internal Standards...", value = 0, {

      incProgress(0.2, detail = "Searching...")

      # Your existing normalization code
      # THIS IS WHERE CRASHES OFTEN OCCUR WITH 312 FILES!
      Rvars$normalized <- search_internal_standards(
        groups = Rvars$groups,
        params = list(...)
      )

      incProgress(0.3, detail = "Normalizing...")

      # Apply normalization
      Rvars$final_results <- apply_normalization(
        groups = Rvars$groups,
        internal_standards = Rvars$normalized
      )

      # 💾 SAVE CHECKPOINT - Most critical one!
      save_checkpoint_with_progress(
        checkpoint_id = "step_04_normalization",
        cache_info = Rvars$cache_info,
        variables = list(
          peaks = Rvars$peaks,
          isotopes = Rvars$isotopes,
          groups = Rvars$groups,
          normalized = Rvars$normalized,
          final_results = Rvars$final_results
        ),
        step_name = "Normalization Complete",
        next_step = "Export Results"
      )

      incProgress(0.5, detail = "Analysis complete!")
    })
  })
}
```

---

## 3. Workflow Checkpoint Integration

### Recommended Checkpoint Locations

Based on the MSpandas workflow, place checkpoints at these critical points:

```r
# Checkpoint 1: After Peak Picking
# Why: First major computational step, generates large dataset
checkpoint_id = "step_01_peak_picking"
variables = list(peaks, file_list, peak_params)

# Checkpoint 2: After Isotope Annotation
# Why: Complex analysis, builds on peak data
checkpoint_id = "step_02_isotope_annotation"
variables = list(peaks, isotopes, isotope_params)

# Checkpoint 3: After Grouping Massif
# Why: Resource-intensive parallel processing, critical intermediate result
checkpoint_id = "step_03_grouping"
variables = list(peaks, isotopes, groups, grouping_params)

# Checkpoint 4: After Internal Standard Search
# Why: THIS IS WHERE 312 FILES CRASH! Most critical checkpoint
checkpoint_id = "step_04_normalization"
variables = list(peaks, isotopes, groups, normalized, final_results)

# Checkpoint 5: Final Results
# Why: Complete analysis, ready for export
checkpoint_id = "step_05_final"
variables = list(all_results, metadata, export_ready_data)
```

---

## 4. Recovery Scenarios

### Scenario A: App Crashes During Normalization (312 Files)

**What happens:**
1. User processes 312 files
2. App crashes at internal standard search (socket exhaustion)
3. User restarts app

**Recovery flow:**

```r
# App startup
server <- function(input, output, session) {

  Rvars <- reactiveValues()

  # Load project
  observeEvent(input$load_project, {

    # Initialize cache
    cache_info <- init_cache_system(
      project_name = input$project_name,
      data_dir = input$data_directory
    )

    # Detect crash
    recovery_info <- detect_crash_and_recover(cache_info)

    # recovery_info contains:
    # $should_prompt = TRUE
    # $can_resume = TRUE
    # $last_checkpoint = "step_03_grouping"
    # $checkpoint_name = "Grouping Complete"
    # $next_step = "Internal Standard Search"

    # Show modal
    show_recovery_modal(
      session,
      recovery_info,
      on_resume = function() {
        # Restore from step_03_grouping
        restore_to_reactive(
          cache_info = cache_info,
          checkpoint_id = "step_03_grouping",
          reactive_values = Rvars
        )

        # Now Rvars contains:
        # - Rvars$peaks (restored)
        # - Rvars$isotopes (restored)
        # - Rvars$groups (restored)

        # User can click "Run Normalization" to continue
        # Processing resumes in ~1 minute instead of 45+ minutes!
      },
      on_restart = function() {
        # Start from beginning
      }
    )
  })
}
```

**Result:** Resume in ~1 minute vs 45+ minute full rerun!

---

### Scenario B: Partial Recovery After Corruption

**What happens:**
1. Checkpoint file gets corrupted
2. Auto-repair finds last valid checkpoint

```r
observeEvent(input$load_project, {

  cache_info <- init_cache_system(...)

  # Attempt recovery
  recovery_info <- detect_crash_and_recover(cache_info)

  if (recovery_info$can_resume) {
    # Try to restore
    result <- restore_to_reactive(
      cache_info,
      recovery_info$last_checkpoint,
      Rvars
    )

    if (!result) {
      # Restoration failed - try auto-repair
      repair_info <- auto_repair_cache(cache_info)

      if (repair_info$repaired) {
        showNotification(
          paste0(
            "⚠️ Corrupted checkpoint detected and repaired!\n",
            "Last valid: ", repair_info$last_valid_checkpoint
          ),
          type = "warning",
          duration = 10
        )

        # Try restore from repaired checkpoint
        restore_to_reactive(
          cache_info,
          repair_info$last_valid_checkpoint,
          Rvars
        )
      }
    }
  }
})
```

---

## 5. Manual Checkpoints

### Add Manual Checkpoint Button to UI

```r
# In ui.R
fluidRow(
  column(12,
    wellPanel(
      h4("Workflow Progress"),
      create_checkpoint_button(
        button_id = "manual_checkpoint",
        label = "💾 Save Progress Now"
      ),
      hr(),
      htmlOutput("cache_status")
    )
  )
)
```

### Handle Manual Checkpoint in Server

```r
# In server.R
observeEvent(input$manual_checkpoint, {
  req(Rvars$cache_info)

  # Determine current step based on what data exists
  current_step <- if (!is.null(Rvars$final_results)) {
    list(id = "manual_final", name = "Manual Save - Final Results")
  } else if (!is.null(Rvars$normalized)) {
    list(id = "manual_normalized", name = "Manual Save - After Normalization")
  } else if (!is.null(Rvars$groups)) {
    list(id = "manual_groups", name = "Manual Save - After Grouping")
  } else if (!is.null(Rvars$isotopes)) {
    list(id = "manual_isotopes", name = "Manual Save - After Isotopes")
  } else if (!is.null(Rvars$peaks)) {
    list(id = "manual_peaks", name = "Manual Save - After Peaks")
  } else {
    NULL
  }

  if (!is.null(current_step)) {
    # Collect all available data
    variables <- list()
    if (!is.null(Rvars$peaks)) variables$peaks <- Rvars$peaks
    if (!is.null(Rvars$isotopes)) variables$isotopes <- Rvars$isotopes
    if (!is.null(Rvars$groups)) variables$groups <- Rvars$groups
    if (!is.null(Rvars$normalized)) variables$normalized <- Rvars$normalized
    if (!is.null(Rvars$final_results)) variables$final_results <- Rvars$final_results

    # Save checkpoint
    save_checkpoint_with_progress(
      checkpoint_id = current_step$id,
      cache_info = Rvars$cache_info,
      variables = variables,
      step_name = current_step$name,
      next_step = "User-initiated save"
    )
  } else {
    showNotification(
      "No data to save yet. Run analysis first.",
      type = "warning",
      duration = 3
    )
  }
})

# Display cache status
output$cache_status <- renderUI({
  req(Rvars$cache_info)
  show_cache_info_panel(Rvars$cache_info)
})
```

---

## 6. Advanced Usage

### A. Conditional Checkpoints (Large Datasets Only)

Save checkpoints only for large datasets (300+ files) where crashes are more likely:

```r
observeEvent(input$run_peak_picking, {

  n_files <- length(input$data_files)

  # Your peak picking code
  Rvars$peaks <- process_peak_picking(...)

  # Save checkpoint only for large datasets
  if (n_files >= 300 && !is.null(Rvars$cache_info)) {
    save_checkpoint_with_progress(
      checkpoint_id = "step_01_peak_picking",
      cache_info = Rvars$cache_info,
      variables = list(peaks = Rvars$peaks),
      step_name = "Peak Picking Complete (Large Dataset)",
      next_step = "Isotope Annotation"
    )
  }
})
```

---

### B. Progress Callbacks with Detailed Updates

```r
observeEvent(input$restore_checkpoint, {
  req(Rvars$cache_info)

  progress <- Progress$new(session)
  progress$set(message = "Restoring checkpoint...", value = 0)

  # Create detailed progress callback
  prog_callback <- function(msg, value) {
    progress$set(message = msg, value = value)
  }

  # Restore with detailed progress
  restore_application_state(
    cache_info = Rvars$cache_info,
    target_step = input$selected_checkpoint,
    restore_to_env = environment(),  # Restore to current environment
    progress_callback = prog_callback
  )

  progress$close()
})
```

---

### C. Cache Management Panel

```r
# In ui.R
tabPanel("Cache Management",
  cache_management_ui("cache_module")
)

# In server.R
observeEvent(input$`cache_module-clean_cache`, {
  req(Rvars$cache_info)

  # Show confirmation dialog
  showModal(modalDialog(
    title = "⚠️ Clean Old Caches?",
    "This will remove old cache directories, keeping only the 5 most recent.",
    footer = tagList(
      modalButton("Cancel"),
      actionButton("confirm_clean", "Clean", class = "btn-warning")
    )
  ))
})

observeEvent(input$confirm_clean, {
  removeModal()

  # Clean old caches
  result <- clean_old_caches(
    base_cache_dir = "cache_projects",
    keep_recent_n = 5,
    dry_run = FALSE
  )

  showNotification(
    "✅ Old caches cleaned successfully",
    type = "message",
    duration = 3
  )
})
```

---

### D. Export Checkpoint Metadata

```r
output$`cache_module-export_metadata` <- downloadHandler(
  filename = function() {
    paste0("cache_metadata_", Sys.Date(), ".json")
  },
  content = function(file) {
    req(Rvars$cache_info)

    # Read metadata
    metadata <- jsonlite::fromJSON(Rvars$cache_info$metadata_file)

    # Write to file
    jsonlite::write_json(
      metadata,
      file,
      pretty = TRUE,
      auto_unbox = TRUE
    )
  }
)
```

---

### E. Validate Integrity Before Critical Operations

```r
observeEvent(input$run_export, {
  req(Rvars$cache_info)

  # Validate checkpoint integrity before export
  if (!is.null(Rvars$cache_info)) {
    checkpoints <- list_checkpoints(Rvars$cache_info)

    if (nrow(checkpoints) > 0) {
      last_cp <- checkpoints$checkpoint_id[nrow(checkpoints)]

      is_valid <- validate_checkpoint_integrity(last_cp, Rvars$cache_info)

      if (!is_valid) {
        showModal(modalDialog(
          title = "⚠️ Checkpoint Integrity Warning",
          "The last checkpoint may be corrupted. Recommend saving a new checkpoint before export.",
          footer = tagList(
            actionButton("save_new_cp", "Save New Checkpoint"),
            actionButton("proceed_anyway", "Proceed Anyway"),
            modalButton("Cancel")
          )
        ))
        return()
      }
    }
  }

  # Proceed with export
  export_results(Rvars$final_results)
})
```

---

## 7. SQLite Database Integration

### Overview

The cache system now includes **SQLite database integration** for robust metadata tracking. This provides:

- **Crash detection** based on project status in database
- **Complete audit trail** of all processing events
- **Fast queries** for project history and statistics
- **Reliable persistence** even if JSON metadata gets corrupted

### Architecture

```
cache_projects/
├── mspandas.sqlite          ← SQLite database (metadata, logs, tracking)
└── Project1_20260123/
    └── cache/
        ├── metadata.json    ← Backup JSON metadata
        ├── step_01.rds      ← RDS checkpoint (large data)
        ├── step_02.rds
        └── step_03.rds
```

**Division of responsibilities:**
- **SQLite**: Project tracking, checkpoint registry, logs, status
- **RDS files**: Actual checkpoint data (matrices, lists, etc.)
- **JSON**: Backup metadata (human-readable)

---

### A. Automatic Integration

The SQLite integration is **automatic** if `DatabaseManager.lib.R` exists. No code changes needed!

When you use the existing cache functions, SQLite is automatically updated:

```r
# 1. Initialize cache (automatically registers in SQLite)
cache_info <- init_cache_system(
  project_name = "MyProject",
  data_dir = "/data/raw"
)

# cache_info now contains:
# - $db_project_id: Project ID in SQLite database
# - $db_path: Path to SQLite database file

# 2. Save checkpoint (automatically registers in SQLite)
save_checkpoint(
  checkpoint_id = "step_01_peaks",
  cache_info = cache_info,
  variables = list(peaks = peaks_data),
  step_name = "Peak Picking Complete",
  next_step = "Isotope Annotation"
)

# Behind the scenes, this:
# - Saves RDS file with checkpoint data
# - Registers checkpoint in SQLite database
# - Updates project status to "running"
# - Logs the event with timestamp
```

---

### B. Database-Driven Crash Detection

Use SQLite for more reliable crash detection:

```r
observeEvent(input$load_project, {
  req(input$project_name)

  # Method 1: SQLite-based crash detection (recommended)
  crash_info <- detect_crash_and_recover(
    project_name = input$project_name,  # Detection by name
    verbose = TRUE
  )

  # crash_info contains:
  # $crashed = TRUE/FALSE (was project status "running"?)
  # $can_resume = TRUE/FALSE (valid checkpoints exist?)
  # $last_checkpoint = "step_03_grouping"
  # $checkpoint_name = "Grouping Complete"
  # $checkpoint_file_path = "/path/to/checkpoint.rds"
  # $project_id = 5 (database ID)
  # $db_detection = TRUE (detection method used)

  if (crash_info$crashed && crash_info$can_resume) {
    show_recovery_modal(
      session = session,
      recovery_info = crash_info,
      on_resume = function() {
        # Load checkpoint directly from file path
        restored_data <- readRDS(crash_info$checkpoint_file_path)

        # Restore to Rvars
        for (var_name in names(restored_data$variables)) {
          Rvars[[var_name]] <- restored_data$variables[[var_name]]
        }

        showNotification(
          paste0("✅ Resumed from: ", crash_info$checkpoint_name),
          type = "message"
        )
      },
      on_restart = function() {
        # Update database status
        if (!is.null(crash_info$project_id)) {
          update_project_status(
            project_id = crash_info$project_id,
            status = "initialized",
            processing_stage = "none"
          )
        }
      }
    )
  }
})
```

---

### C. Viewing Project History

Query the database for project statistics and history:

```r
# Get comprehensive project statistics
observeEvent(input$show_project_stats, {
  req(Rvars$cache_info)
  req(Rvars$cache_info$db_project_id)

  stats <- get_project_statistics(
    project_id = Rvars$cache_info$db_project_id
  )

  # stats contains:
  # $project: Project info (name, status, dates)
  # $checkpoints: Checkpoint stats (count, total size, last time)
  # $logs: Log stats (total, errors, warnings, execution time)
  # $recent_logs: Last 10 log entries

  # Display in UI
  output$project_stats <- renderUI({
    HTML(paste0(
      "<h4>Project: ", stats$project$project_name, "</h4>",
      "<p><strong>Status:</strong> ", stats$project$status, "</p>",
      "<p><strong>Stage:</strong> ", stats$project$processing_stage, "</p>",
      "<p><strong>Checkpoints:</strong> ", stats$checkpoints$total_checkpoints,
      " (", sprintf("%.1f MB", stats$checkpoints$total_size_mb), ")</p>",
      "<p><strong>Total logs:</strong> ", stats$logs$total_logs,
      " (", stats$logs$error_count, " errors, ",
      stats$logs$warning_count, " warnings)</p>",
      "<p><strong>Total execution time:</strong> ",
      sprintf("%.1f seconds", stats$logs$total_execution_time), "</p>"
    ))
  })
})
```

---

### D. Viewing Processing Logs

Access detailed processing logs from the database:

```r
# Get all logs for project
logs <- get_processing_logs(
  project_id = Rvars$cache_info$db_project_id,
  limit = 100
)

# Filter by log level
error_logs <- get_processing_logs(
  project_id = Rvars$cache_info$db_project_id,
  log_level = "ERROR",
  limit = 50
)

# Filter by step
peak_picking_logs <- get_processing_logs(
  project_id = Rvars$cache_info$db_project_id,
  step_name = "peak_picking",
  limit = 50
)

# Display in Shiny table
output$logs_table <- renderDT({
  datatable(
    logs,
    options = list(
      pageLength = 25,
      order = list(list(1, 'desc'))  # Sort by timestamp descending
    )
  )
})
```

---

### E. Manual Logging

Add custom log entries during processing:

```r
observeEvent(input$run_peak_picking, {
  req(Rvars$cache_info)

  start_time <- Sys.time()

  tryCatch({
    # Your peak picking code
    Rvars$peaks <- process_peak_picking(...)

    # Log success
    execution_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    log_processing_event(
      project_id = Rvars$cache_info$db_project_id,
      step_name = "peak_picking",
      log_level = "INFO",
      message = paste0("Peak picking completed successfully. ",
                      nrow(Rvars$peaks), " peaks detected."),
      execution_time_seconds = execution_time
    )

  }, error = function(e) {
    # Log error
    log_processing_event(
      project_id = Rvars$cache_info$db_project_id,
      step_name = "peak_picking",
      log_level = "ERROR",
      message = paste0("Peak picking failed: ", e$message),
      error_details = toString(e)
    )

    showNotification(
      paste0("❌ Peak picking failed: ", e$message),
      type = "error",
      duration = 10
    )
  })
})
```

---

### F. Listing All Projects

View all projects in the database:

```r
# Get all projects
all_projects <- get_all_projects()

# Display in table
output$projects_table <- renderDT({
  datatable(
    all_projects[, c("project_name", "status", "processing_stage",
                     "total_files", "last_modified")],
    options = list(pageLength = 10)
  )
})

# Load a specific project
observeEvent(input$load_selected_project, {
  req(input$projects_table_rows_selected)

  selected_row <- input$projects_table_rows_selected
  project_name <- all_projects$project_name[selected_row]

  # Check for crash
  crash_info <- detect_crash_from_db(project_name)

  if (crash_info$crashed) {
    show_recovery_modal(session, crash_info, ...)
  } else {
    # Load project normally
    load_project(project_name)
  }
})
```

---

### G. Cleaning Up Database

Remove old or completed projects:

```r
# Delete a specific project from database
observeEvent(input$delete_project, {
  req(input$confirm_delete)
  req(Rvars$cache_info$db_project_id)

  result <- delete_project(
    project_id = Rvars$cache_info$db_project_id,
    delete_files = TRUE  # Also delete checkpoint files
  )

  if (result) {
    showNotification(
      "✅ Project deleted successfully",
      type = "message"
    )
  }
})

# Invalidate a corrupted checkpoint
invalidate_checkpoint(
  checkpoint_id = 123,  # Database checkpoint ID
  db_path = "cache_projects/mspandas.sqlite"
)

# Clean up invalid checkpoints (remove files)
cleanup_invalid_checkpoints(
  project_id = Rvars$cache_info$db_project_id
)
```

---

### H. Database Queries (Advanced)

Direct SQL queries for custom reporting:

```r
library(RSQLite)
library(DBI)

# Open connection
con <- dbConnect(RSQLite::SQLite(), "cache_projects/mspandas.sqlite")

# Example: Find all crashed projects
crashed_projects <- dbGetQuery(con, "
  SELECT project_name, processing_stage, last_modified
  FROM projects
  WHERE status = 'running'
  ORDER BY last_modified DESC
")

# Example: Find projects with errors
projects_with_errors <- dbGetQuery(con, "
  SELECT DISTINCT p.project_name, COUNT(l.log_id) as error_count
  FROM projects p
  JOIN processing_logs l ON p.project_id = l.project_id
  WHERE l.log_level = 'ERROR'
  GROUP BY p.project_id
  HAVING error_count > 0
  ORDER BY error_count DESC
")

# Example: Average execution time per step
avg_execution_times <- dbGetQuery(con, "
  SELECT step_name,
         COUNT(*) as count,
         AVG(execution_time_seconds) as avg_time,
         MIN(execution_time_seconds) as min_time,
         MAX(execution_time_seconds) as max_time
  FROM processing_logs
  WHERE execution_time_seconds IS NOT NULL
  GROUP BY step_name
  ORDER BY avg_time DESC
")

# Close connection
dbDisconnect(con)
```

---

### I. Complete Example with SQLite

Here's a complete workflow with full SQLite integration:

```r
server <- function(input, output, session) {

  Rvars <- reactiveValues()

  # ═══════════════════════════════════════════════════════════
  # Initialize SQLite database at app startup
  # ═══════════════════════════════════════════════════════════

  # This runs once when app starts
  db_path <- init_database("cache_projects/mspandas.sqlite")


  # ═══════════════════════════════════════════════════════════
  # Load project with SQLite-based crash detection
  # ═══════════════════════════════════════════════════════════

  observeEvent(input$load_project, {
    req(input$project_name)

    # SQLite-based crash detection
    crash_info <- detect_crash_and_recover(
      project_name = input$project_name,
      verbose = TRUE
    )

    if (crash_info$crashed && crash_info$can_resume) {
      # Show recovery modal
      show_recovery_modal(
        session = session,
        recovery_info = crash_info,
        on_resume = function() {
          # Initialize cache with existing project_id
          Rvars$cache_info <- list(
            db_project_id = crash_info$project_id,
            cache_dir = dirname(crash_info$checkpoint_file_path),
            db_path = db_path
          )

          # Load checkpoint
          checkpoint_data <- readRDS(crash_info$checkpoint_file_path)
          for (var in names(checkpoint_data$variables)) {
            Rvars[[var]] <- checkpoint_data$variables[[var]]
          }

          # Update status
          update_project_status(
            project_id = crash_info$project_id,
            status = "running",
            processing_stage = crash_info$last_checkpoint
          )

          showNotification("✅ Session restored!", type = "message")
        },
        on_restart = function() {
          start_new_session()
        }
      )
    } else {
      start_new_session()
    }
  })


  # ═══════════════════════════════════════════════════════════
  # Start new session
  # ═══════════════════════════════════════════════════════════

  start_new_session <- function() {
    # Initialize cache (auto-registers in SQLite)
    Rvars$cache_info <- init_cache_system(
      project_name = input$project_name,
      data_dir = input$data_directory
    )

    showNotification("✅ New session started", type = "message")
  }


  # ═══════════════════════════════════════════════════════════
  # Processing with automatic SQLite logging
  # ═══════════════════════════════════════════════════════════

  observeEvent(input$run_peak_picking, {
    req(Rvars$cache_info)

    start_time <- Sys.time()

    withProgress(message = "Peak Picking...", {

      tryCatch({
        # Process
        Rvars$peaks <- process_peak_picking(...)

        # Save checkpoint (auto-registers in SQLite)
        save_checkpoint_with_progress(
          checkpoint_id = "step_01_peak_picking",
          cache_info = Rvars$cache_info,
          variables = list(peaks = Rvars$peaks),
          step_name = "Peak Picking Complete",
          next_step = "Isotope Annotation"
        )

        # Checkpoint save automatically:
        # - Registers in SQLite
        # - Updates project status to "running"
        # - Logs the event

      }, error = function(e) {
        # Errors are automatically logged if save_checkpoint is called
        showNotification(paste0("Error: ", e$message), type = "error")
      })
    })
  })


  # ═══════════════════════════════════════════════════════════
  # Mark workflow as completed
  # ═══════════════════════════════════════════════════════════

  observeEvent(input$export_results, {
    req(Rvars$cache_info)

    # Mark as completed
    update_project_status(
      project_id = Rvars$cache_info$db_project_id,
      status = "completed",
      processing_stage = "export"
    )

    log_processing_event(
      project_id = Rvars$cache_info$db_project_id,
      step_name = "export",
      log_level = "INFO",
      message = "Workflow completed successfully"
    )

    showNotification("✅ Analysis complete!", type = "message")
  })
}
```

---

### J. Benefits of SQLite Integration

| Feature | Without SQLite | With SQLite |
|---------|----------------|-------------|
| **Crash detection** | Check JSON file | Query database status |
| **Project history** | Parse all JSON files | Single SQL query |
| **Logs** | Print to console (lost) | Persistent in database |
| **Search** | Manual file scanning | Fast SQL queries |
| **Corruption recovery** | JSON must be valid | Database transaction-safe |
| **Audit trail** | Limited | Complete with timestamps |
| **Statistics** | Recalculate each time | Aggregated queries |
| **Multi-user** | File locks | Database transactions |

---

### K. Testing SQLite Integration

Run the test suite to validate SQLite functionality:

```r
source("lib/cache/test_database_manager.R")

# Run all tests
run_database_tests()

# Or quick validation
quick_database_test()
```

Tests cover:
- Database initialization
- Project registration
- Checkpoint registration
- Status updates
- Processing logs
- Crash detection
- Checkpoint management
- Project statistics

---

## Summary

### Key Integration Points

1. **Initialization**: Call `init_cache_in_shiny()` when project loads
2. **Auto-Recovery**: Use `auto_recovery_check()` at app startup
3. **Checkpoints**: Add `save_checkpoint_with_progress()` after each major step
4. **Recovery**: Use `restore_to_reactive()` to restore checkpoint variables

### Critical Checkpoints for 312 Files

Focus on these 3 checkpoints for maximum impact:
1. ✅ **After Grouping Massif** - Before the crash-prone normalization
2. ✅ **After Peak Picking** - Saves 20+ minutes of processing
3. ✅ **After Normalization** - Complete analysis preserved

### Best Practices

- ✅ Always save checkpoint after resource-intensive operations
- ✅ Include all necessary variables in checkpoint (don't skip dependencies)
- ✅ Show clear notifications when checkpoints are saved
- ✅ Test recovery flow with large datasets (312+ files)
- ✅ Clean old caches periodically (keep 5 most recent)

---

**Ready to use!** Copy these examples into your MSpandas application and adjust variable names/function calls to match your existing code.
