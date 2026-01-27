# ═══════════════════════════════════════════════════════════════════════════
# test_cache_system.R - Comprehensive Test Suite for Cache System
# ═══════════════════════════════════════════════════════════════════════════
#
# Tests all components of the cache system:
# - CacheManager.lib.R functions
# - RecoveryManager.lib.R functions
# - Integration scenarios
# - Error handling
#
# Usage:
#   source("lib/cache/test_cache_system.R")
#   run_all_tests()
#
# ═══════════════════════════════════════════════════════════════════════════

# Load required libraries
source("lib/cache/CacheManager.lib.R")
source("lib/cache/RecoveryManager.lib.R")

library(testthat)

# ═══════════════════════════════════════════════════════════════════════════
# Test Configuration
# ═══════════════════════════════════════════════════════════════════════════

TEST_BASE_DIR <- "test_cache_temp"
TEST_PROJECT <- "TestProject"
TEST_DATA_DIR <- "/test/data/path"


# ═══════════════════════════════════════════════════════════════════════════
# Helper: Create Test Data
# ═══════════════════════════════════════════════════════════════════════════

create_test_data <- function() {
  list(
    test_matrix = matrix(rnorm(100), nrow = 10, ncol = 10),
    test_df = data.frame(
      id = 1:10,
      value = rnorm(10),
      label = letters[1:10]
    ),
    test_list = list(
      a = 1:5,
      b = letters[1:5],
      c = list(x = 1, y = 2)
    ),
    test_vector = rnorm(50),
    test_string = "Test string value"
  )
}


# ═══════════════════════════════════════════════════════════════════════════
# Helper: Clean Test Environment
# ═══════════════════════════════════════════════════════════════════════════

clean_test_env <- function() {
  if (dir.exists(TEST_BASE_DIR)) {
    unlink(TEST_BASE_DIR, recursive = TRUE)
  }
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 1: CacheManager Basic Functions
# ═══════════════════════════════════════════════════════════════════════════

test_cache_manager_basic <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 1: CacheManager Basic Functions\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("init_cache_system creates proper structure", {
    cache_info <- init_cache_system(
      project_name = TEST_PROJECT,
      data_dir = TEST_DATA_DIR,
      base_cache_dir = TEST_BASE_DIR
    )

    expect_true(!is.null(cache_info))
    expect_equal(cache_info$project_name, TEST_PROJECT)
    expect_equal(cache_info$data_dir, TEST_DATA_DIR)
    expect_true(dir.exists(cache_info$cache_dir))
    expect_true(file.exists(cache_info$metadata_file))

    # Check cache_id format (should be YYYYMMDD_HHMMSS)
    expect_match(cache_info$cache_id, "^\\d{8}_\\d{6}$")
  })

  test_that("metadata.json has correct structure", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    metadata <- jsonlite::fromJSON(cache_info$metadata_file)

    expect_equal(metadata$project_name, TEST_PROJECT)
    expect_equal(metadata$data_dir, TEST_DATA_DIR)
    expect_equal(metadata$cache_id, cache_info$cache_id)
    expect_true("created_time" %in% names(metadata))
    expect_true("checkpoints" %in% names(metadata))
    expect_equal(length(metadata$checkpoints), 0)
  })

  clean_test_env()
  cat("✅ All CacheManager basic tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 2: Checkpoint Save/Load
# ═══════════════════════════════════════════════════════════════════════════

test_checkpoint_save_load <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 2: Checkpoint Save/Load\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("save_checkpoint creates checkpoint file", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    test_data <- create_test_data()

    result <- save_checkpoint(
      checkpoint_id = "step_01_test",
      cache_info = cache_info,
      variables = test_data,
      step_name = "Test Step 1",
      next_step = "Test Step 2"
    )

    expect_true(result)

    checkpoint_file <- file.path(cache_info$cache_dir, "step_01_test.rds")
    expect_true(file.exists(checkpoint_file))

    # Check metadata updated
    metadata <- jsonlite::fromJSON(cache_info$metadata_file)
    expect_equal(length(metadata$checkpoints), 1)
    expect_equal(metadata$checkpoints[[1]]$checkpoint_id, "step_01_test")
  })

  test_that("load_checkpoint restores variables correctly", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    original_data <- create_test_data()

    save_checkpoint("step_01_test", cache_info, original_data,
                   "Test Step", "Next Step")

    loaded_data <- load_checkpoint("step_01_test", cache_info,
                                   validate_checksum = TRUE)

    expect_true(!is.null(loaded_data))
    expect_equal(names(loaded_data), names(original_data))
    expect_equal(loaded_data$test_string, original_data$test_string)
    expect_equal(loaded_data$test_vector, original_data$test_vector)
    expect_equal(loaded_data$test_matrix, original_data$test_matrix)
  })

  test_that("load_checkpoint with invalid ID returns NULL", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    loaded_data <- load_checkpoint("nonexistent_checkpoint", cache_info)

    expect_null(loaded_data)
  })

  test_that("checksum validation works", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    test_data <- create_test_data()

    save_checkpoint("step_01_test", cache_info, test_data, "Test", "Next")

    # Corrupt the checkpoint file
    checkpoint_file <- file.path(cache_info$cache_dir, "step_01_test.rds")
    file_conn <- file(checkpoint_file, "ab")
    writeBin(as.raw(0xFF), file_conn)
    close(file_conn)

    # Should fail with validation
    loaded_data <- load_checkpoint("step_01_test", cache_info,
                                   validate_checksum = TRUE)
    expect_null(loaded_data)

    # Should work without validation
    expect_warning(
      loaded_data <- load_checkpoint("step_01_test", cache_info,
                                    validate_checksum = FALSE)
    )
  })

  clean_test_env()
  cat("✅ All checkpoint save/load tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 3: Multiple Checkpoints
# ═══════════════════════════════════════════════════════════════════════════

test_multiple_checkpoints <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 3: Multiple Checkpoints\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("can save multiple checkpoints", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    for (i in 1:5) {
      data <- list(step_number = i, data = rnorm(10))
      result <- save_checkpoint(
        checkpoint_id = paste0("step_", sprintf("%02d", i)),
        cache_info = cache_info,
        variables = data,
        step_name = paste("Step", i),
        next_step = paste("Step", i + 1)
      )
      expect_true(result)
    }

    checkpoints <- list_checkpoints(cache_info)
    expect_equal(nrow(checkpoints), 5)
  })

  test_that("list_checkpoints returns correct info", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    # Save 3 checkpoints
    for (i in 1:3) {
      save_checkpoint(
        paste0("step_", i),
        cache_info,
        list(data = rnorm(10)),
        paste("Step", i),
        paste("Step", i + 1)
      )
    }

    checkpoints <- list_checkpoints(cache_info)

    expect_equal(nrow(checkpoints), 3)
    expect_true(all(c("checkpoint_id", "step_name", "saved_time",
                     "size_mb", "checksum") %in% colnames(checkpoints)))
    expect_true(all(checkpoints$size_mb > 0))
  })

  test_that("can_resume_from_cache detects valid cache", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    # Initially should be FALSE (no checkpoints)
    expect_false(can_resume_from_cache(cache_info))

    # Save a checkpoint
    save_checkpoint("step_01", cache_info, list(data = 1:10),
                   "Step 1", "Step 2")

    # Now should be TRUE
    expect_true(can_resume_from_cache(cache_info))
  })

  clean_test_env()
  cat("✅ All multiple checkpoint tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 4: RecoveryManager Functions
# ═══════════════════════════════════════════════════════════════════════════

test_recovery_manager <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 4: RecoveryManager Functions\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("detect_crash_and_recover detects crash", {
    # Create cache with checkpoint
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    save_checkpoint("step_01", cache_info, list(data = 1:10),
                   "Step 1", "Step 2")

    # Mark as crashed
    mark_crash_detected(cache_info, "Test crash")

    # Detect crash
    recovery_info <- detect_crash_and_recover(cache_info, verbose = FALSE)

    expect_true(recovery_info$should_prompt)
    expect_true(recovery_info$can_resume)
    expect_equal(recovery_info$last_checkpoint, "step_01")
  })

  test_that("restore_application_state restores to environment", {
    # Setup
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    original_data <- list(
      var1 = 100,
      var2 = "test",
      var3 = data.frame(x = 1:5, y = 6:10)
    )
    save_checkpoint("step_01", cache_info, original_data, "Step 1", "Step 2")

    # Create new environment
    test_env <- new.env()

    # Restore
    result <- restore_application_state(
      cache_info = cache_info,
      target_step = "step_01",
      restore_to_env = test_env,
      progress_callback = NULL
    )

    expect_true(result)
    expect_equal(test_env$var1, 100)
    expect_equal(test_env$var2, "test")
    expect_equal(test_env$var3, original_data$var3)
  })

  test_that("validate_checkpoint_integrity detects corruption", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    save_checkpoint("step_01", cache_info, list(data = 1:10),
                   "Step 1", "Step 2")

    # Should pass initially
    expect_true(validate_checkpoint_integrity("step_01", cache_info))

    # Corrupt file
    checkpoint_file <- file.path(cache_info$cache_dir, "step_01.rds")
    file_conn <- file(checkpoint_file, "ab")
    writeBin(as.raw(c(0xFF, 0xFF)), file_conn)
    close(file_conn)

    # Should fail now
    expect_false(validate_checkpoint_integrity("step_01", cache_info))
  })

  test_that("auto_repair_cache finds last valid checkpoint", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    # Save 3 checkpoints
    save_checkpoint("step_01", cache_info, list(data = 1:10), "Step 1", "Step 2")
    save_checkpoint("step_02", cache_info, list(data = 1:20), "Step 2", "Step 3")
    save_checkpoint("step_03", cache_info, list(data = 1:30), "Step 3", "Step 4")

    # Corrupt step_03
    checkpoint_file <- file.path(cache_info$cache_dir, "step_03.rds")
    file_conn <- file(checkpoint_file, "ab")
    writeBin(as.raw(0xFF), file_conn)
    close(file_conn)

    # Repair should find step_02 as last valid
    repair_info <- auto_repair_cache(cache_info)

    expect_true(repair_info$repaired)
    expect_equal(repair_info$last_valid_checkpoint, "step_02")
    expect_equal(repair_info$corrupted_checkpoints, "step_03")
  })

  clean_test_env()
  cat("✅ All RecoveryManager tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 5: Integration Tests (Full Workflow)
# ═══════════════════════════════════════════════════════════════════════════

test_full_workflow <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 5: Full Workflow Integration\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("complete save-crash-restore workflow", {
    # Step 1: Initialize cache
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
    expect_true(!is.null(cache_info))

    # Step 2: Simulate workflow steps
    step1_data <- list(peaks = matrix(rnorm(100), 10, 10))
    save_checkpoint("step_01_peaks", cache_info, step1_data,
                   "Peak Picking", "Isotope Annotation")

    step2_data <- list(isotopes = data.frame(id = 1:10, mass = rnorm(10)))
    save_checkpoint("step_02_isotopes", cache_info, step2_data,
                   "Isotope Annotation", "Grouping")

    step3_data <- list(groups = list(g1 = 1:5, g2 = 6:10))
    save_checkpoint("step_03_grouping", cache_info, step3_data,
                   "Grouping", "Normalization")

    # Step 3: Simulate crash
    mark_crash_detected(cache_info, "Simulated crash at normalization")

    # Step 4: Detect crash
    recovery_info <- detect_crash_and_recover(cache_info, verbose = FALSE)
    expect_true(recovery_info$should_prompt)
    expect_true(recovery_info$can_resume)
    expect_equal(recovery_info$last_checkpoint, "step_03_grouping")

    # Step 5: Restore
    restored_env <- new.env()
    result <- restore_application_state(
      cache_info,
      "step_03_grouping",
      restored_env,
      NULL
    )

    expect_true(result)
    expect_true("groups" %in% ls(restored_env))
    expect_equal(restored_env$groups, step3_data$groups)

    # Step 6: Verify cache info
    info <- get_cache_info(cache_info)
    expect_equal(info$total_checkpoints, 3)
    expect_true(info$total_size_mb > 0)
  })

  clean_test_env()
  cat("✅ All integration tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 6: Error Handling
# ═══════════════════════════════════════════════════════════════════════════

test_error_handling <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 6: Error Handling\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("handles invalid inputs gracefully", {
    # Invalid project name
    expect_error(
      init_cache_system("", TEST_DATA_DIR, TEST_BASE_DIR)
    )

    # Invalid data dir
    expect_error(
      init_cache_system(TEST_PROJECT, "", TEST_BASE_DIR)
    )
  })

  test_that("handles missing cache gracefully", {
    cache_info <- list(
      cache_dir = "nonexistent_dir",
      metadata_file = "nonexistent_file.json"
    )

    expect_false(can_resume_from_cache(cache_info))
    expect_null(load_checkpoint("step_01", cache_info))
  })

  test_that("handles corrupted metadata gracefully", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    # Corrupt metadata
    writeLines("{invalid json", cache_info$metadata_file)

    expect_warning(
      result <- can_resume_from_cache(cache_info)
    )
  })

  clean_test_env()
  cat("✅ All error handling tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 7: Cache Cleanup
# ═══════════════════════════════════════════════════════════════════════════

test_cache_cleanup <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 7: Cache Cleanup\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("clean_old_caches removes old caches", {
    # Create 10 caches
    for (i in 1:10) {
      cache_info <- init_cache_system(
        paste0(TEST_PROJECT, "_", i),
        TEST_DATA_DIR,
        TEST_BASE_DIR
      )
      save_checkpoint("step_01", cache_info, list(data = i), "Step", "Next")
      Sys.sleep(0.1)  # Ensure different timestamps
    }

    # Clean keeping only 5 most recent
    clean_old_caches(TEST_BASE_DIR, keep_recent_n = 5, dry_run = FALSE)

    # Count remaining caches
    remaining_dirs <- list.dirs(TEST_BASE_DIR, full.names = FALSE, recursive = FALSE)
    project_dirs <- remaining_dirs[grepl(paste0("^", TEST_PROJECT), remaining_dirs)]

    expect_true(length(project_dirs) <= 5)
  })

  test_that("dry_run doesn't delete caches", {
    # Create 3 caches
    for (i in 1:3) {
      init_cache_system(paste0(TEST_PROJECT, "_", i), TEST_DATA_DIR, TEST_BASE_DIR)
    }

    count_before <- length(list.dirs(TEST_BASE_DIR, recursive = FALSE))

    # Dry run
    clean_old_caches(TEST_BASE_DIR, keep_recent_n = 1, dry_run = TRUE)

    count_after <- length(list.dirs(TEST_BASE_DIR, recursive = FALSE))

    expect_equal(count_before, count_after)
  })

  clean_test_env()
  cat("✅ All cleanup tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 8: Performance Tests
# ═══════════════════════════════════════════════════════════════════════════

test_performance <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 8: Performance Tests\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_env()

  test_that("handles large data efficiently", {
    cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)

    # Create large dataset (10MB)
    large_data <- list(
      matrix1 = matrix(rnorm(100000), 1000, 100),
      matrix2 = matrix(rnorm(100000), 1000, 100),
      df = data.frame(
        id = 1:10000,
        value1 = rnorm(10000),
        value2 = rnorm(10000)
      )
    )

    # Time save
    save_time <- system.time({
      result <- save_checkpoint(
        "large_checkpoint",
        cache_info,
        large_data,
        "Large Data Test",
        "Next"
      )
    })

    expect_true(result)
    cat(sprintf("  Save time for ~10MB: %.2f seconds\n", save_time[["elapsed"]]))

    # Time load
    load_time <- system.time({
      loaded <- load_checkpoint("large_checkpoint", cache_info)
    })

    expect_true(!is.null(loaded))
    cat(sprintf("  Load time for ~10MB: %.2f seconds\n", load_time[["elapsed"]]))

    # Both should be under 5 seconds
    expect_true(save_time[["elapsed"]] < 5)
    expect_true(load_time[["elapsed"]] < 5)
  })

  clean_test_env()
  cat("✅ All performance tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# Main Test Runner
# ═══════════════════════════════════════════════════════════════════════════

run_all_tests <- function() {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║      CACHE SYSTEM COMPREHENSIVE TEST SUITE                    ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n")

  start_time <- Sys.time()

  # Run all test suites
  tryCatch({
    test_cache_manager_basic()
    test_checkpoint_save_load()
    test_multiple_checkpoints()
    test_recovery_manager()
    test_full_workflow()
    test_error_handling()
    test_cache_cleanup()
    test_performance()

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat("═══════════════════════════════════════════════════════════════\n")
    cat("🎉 ALL TESTS PASSED!\n")
    cat(sprintf("⏱️  Total time: %.2f seconds\n", elapsed))
    cat("═══════════════════════════════════════════════════════════════\n\n")

  }, error = function(e) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("❌ TEST SUITE FAILED\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("Error:", e$message, "\n\n")

  }, finally = {
    # Always clean up
    clean_test_env()
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# Quick Test Function (for development)
# ═══════════════════════════════════════════════════════════════════════════

quick_test <- function() {
  cat("Running quick validation test...\n\n")

  clean_test_env()

  # Basic workflow
  cache_info <- init_cache_system(TEST_PROJECT, TEST_DATA_DIR, TEST_BASE_DIR)
  test_data <- list(value = 42, name = "test")
  save_checkpoint("test_checkpoint", cache_info, test_data, "Test", "Next")
  loaded <- load_checkpoint("test_checkpoint", cache_info)

  if (!is.null(loaded) && loaded$value == 42) {
    cat("✅ Quick test PASSED!\n")
  } else {
    cat("❌ Quick test FAILED!\n")
  }

  clean_test_env()
}


# ═══════════════════════════════════════════════════════════════════════════
# Auto-run if sourced directly
# ═══════════════════════════════════════════════════════════════════════════

if (!interactive()) {
  cat("Test script loaded. Run run_all_tests() to execute all tests.\n")
  cat("Or run quick_test() for a fast validation.\n\n")
}

# ═══════════════════════════════════════════════════════════════════════════
# End of test_cache_system.R
# ═══════════════════════════════════════════════════════════════════════════
