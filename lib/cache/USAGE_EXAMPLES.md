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
