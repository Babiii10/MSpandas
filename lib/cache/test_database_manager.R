# ═══════════════════════════════════════════════════════════════════════════
# test_database_manager.R - Test Suite for DatabaseManager.lib.R
# ═══════════════════════════════════════════════════════════════════════════
#
# Tests SQLite database functionality for the cache system
#
# Usage:
#   source("lib/cache/test_database_manager.R")
#   run_database_tests()
#
# ═══════════════════════════════════════════════════════════════════════════

# Load required libraries
source("lib/cache/DatabaseManager.lib.R")
library(testthat)

# ═══════════════════════════════════════════════════════════════════════════
# Test Configuration
# ═══════════════════════════════════════════════════════════════════════════

TEST_DB_PATH <- "test_cache_temp/test.sqlite"
TEST_PROJECT_NAME <- "TestProject"
TEST_DATA_DIR <- "/test/data/path"


# ═══════════════════════════════════════════════════════════════════════════
# Helper: Clean Test Environment
# ═══════════════════════════════════════════════════════════════════════════

clean_test_db <- function() {
  if (file.exists(TEST_DB_PATH)) {
    unlink(TEST_DB_PATH)
  }
  if (dir.exists("test_cache_temp")) {
    unlink("test_cache_temp", recursive = TRUE)
  }
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 1: Database Initialization
# ═══════════════════════════════════════════════════════════════════════════

test_database_initialization <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 1: Database Initialization\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()

  test_that("init_database creates database file", {
    db_path <- init_database(TEST_DB_PATH)

    expect_true(file.exists(TEST_DB_PATH))
    expect_equal(db_path, TEST_DB_PATH)
  })

  test_that("database has correct tables", {
    init_database(TEST_DB_PATH)

    con <- dbConnect(RSQLite::SQLite(), TEST_DB_PATH)
    tables <- dbListTables(con)
    dbDisconnect(con)

    expect_true("projects" %in% tables)
    expect_true("checkpoints" %in% tables)
    expect_true("processing_logs" %in% tables)
    expect_equal(length(tables), 3)
  })

  test_that("projects table has correct schema", {
    init_database(TEST_DB_PATH)

    con <- dbConnect(RSQLite::SQLite(), TEST_DB_PATH)
    schema <- dbGetQuery(con, "PRAGMA table_info(projects)")
    dbDisconnect(con)

    column_names <- schema$name
    expect_true("project_id" %in% column_names)
    expect_true("project_name" %in% column_names)
    expect_true("data_directory" %in% column_names)
    expect_true("status" %in% column_names)
    expect_true("processing_stage" %in% column_names)
  })

  test_that("checkpoints table has correct schema", {
    init_database(TEST_DB_PATH)

    con <- dbConnect(RSQLite::SQLite(), TEST_DB_PATH)
    schema <- dbGetQuery(con, "PRAGMA table_info(checkpoints)")
    dbDisconnect(con)

    column_names <- schema$name
    expect_true("checkpoint_id" %in% column_names)
    expect_true("project_id" %in% column_names)
    expect_true("step_id" %in% column_names)
    expect_true("checkpoint_file_path" %in% column_names)
    expect_true("is_valid" %in% column_names)
  })

  clean_test_db()
  cat("✅ All database initialization tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 2: Project Registration
# ═══════════════════════════════════════════════════════════════════════════

test_project_registration <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 2: Project Registration\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("register_project creates new project", {
    project_id <- register_project(
      project_name = TEST_PROJECT_NAME,
      data_directory = TEST_DATA_DIR,
      total_files = 100,
      cache_directory = "cache_projects/test",
      cache_id = "test_20260123_123456",
      db_path = TEST_DB_PATH
    )

    expect_true(!is.null(project_id))
    expect_true(is.numeric(project_id))
    expect_true(project_id > 0)
  })

  test_that("project appears in database", {
    register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                    "cache_projects/test", NULL, TEST_DB_PATH)

    project <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)

    expect_equal(nrow(project), 1)
    expect_equal(project$project_name, TEST_PROJECT_NAME)
    expect_equal(project$data_directory, TEST_DATA_DIR)
    expect_equal(project$total_files, 100)
    expect_equal(project$status, "initialized")
  })

  test_that("duplicate project updates instead of creates", {
    # First registration
    id1 <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                           "cache1", NULL, TEST_DB_PATH)

    # Second registration with same name
    id2 <- register_project(TEST_PROJECT_NAME, "/new/path", 200,
                           "cache2", NULL, TEST_DB_PATH)

    # Should be same ID
    expect_equal(id1, id2)

    # Data should be updated
    project <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    expect_equal(project$data_directory, "/new/path")
    expect_equal(project$total_files, 200)
  })

  test_that("multiple projects can coexist", {
    register_project("Project1", "/path1", 100, "cache1", NULL, TEST_DB_PATH)
    register_project("Project2", "/path2", 200, "cache2", NULL, TEST_DB_PATH)
    register_project("Project3", "/path3", 300, "cache3", NULL, TEST_DB_PATH)

    projects <- get_all_projects(TEST_DB_PATH)

    expect_equal(nrow(projects), 3)
    expect_true("Project1" %in% projects$project_name)
    expect_true("Project2" %in% projects$project_name)
    expect_true("Project3" %in% projects$project_name)
  })

  clean_test_db()
  cat("✅ All project registration tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 3: Checkpoint Registration
# ═══════════════════════════════════════════════════════════════════════════

test_checkpoint_registration <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 3: Checkpoint Registration\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("register_checkpoint creates checkpoint entry", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    checkpoint_id <- register_checkpoint(
      project_id = project_id,
      step_id = "step_01_test",
      step_name = "Test Step",
      checkpoint_file_path = "/path/to/checkpoint.rds",
      file_size_mb = 5.2,
      checksum_md5 = "abc123",
      variables_stored = c("var1", "var2", "var3"),
      next_step = "Next Step",
      execution_time_seconds = 45.3,
      db_path = TEST_DB_PATH
    )

    expect_true(!is.null(checkpoint_id))
    expect_true(is.numeric(checkpoint_id))
  })

  test_that("checkpoint appears in database", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    register_checkpoint(
      project_id, "step_01", "Step 1", "/path.rds",
      5.0, "abc", c("v1", "v2"), "Step 2", NULL, TEST_DB_PATH
    )

    checkpoints <- list_all_checkpoints(project_id, FALSE, TEST_DB_PATH)

    expect_equal(nrow(checkpoints), 1)
    expect_equal(checkpoints$step_id, "step_01")
    expect_equal(checkpoints$step_name, "Step 1")
    expect_equal(checkpoints$is_valid, 1)
  })

  test_that("multiple checkpoints for same project", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    for (i in 1:5) {
      register_checkpoint(
        project_id, paste0("step_", sprintf("%02d", i)),
        paste("Step", i), paste0("/path", i, ".rds"),
        i * 1.5, "checksum", c("var"), "Next", NULL, TEST_DB_PATH
      )
    }

    checkpoints <- list_all_checkpoints(project_id, FALSE, TEST_DB_PATH)

    expect_equal(nrow(checkpoints), 5)
  })

  test_that("get_last_checkpoint returns most recent", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    # Add 3 checkpoints with delays
    for (i in 1:3) {
      register_checkpoint(
        project_id, paste0("step_", i), paste("Step", i),
        paste0("/path", i, ".rds"), 1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH
      )
      Sys.sleep(0.1)
    }

    last_cp <- get_last_checkpoint(project_id, TEST_DB_PATH)

    expect_equal(last_cp$step_id, "step_3")
    expect_equal(last_cp$step_name, "Step 3")
  })

  test_that("variables_stored is stored as JSON", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    vars <- c("peaks", "isotopes", "groups")
    register_checkpoint(
      project_id, "step_01", "Step", "/path.rds",
      1.0, "abc", vars, "Next", NULL, TEST_DB_PATH
    )

    con <- dbConnect(RSQLite::SQLite(), TEST_DB_PATH)
    stored <- dbGetQuery(con, "SELECT variables_stored FROM checkpoints WHERE step_id = 'step_01'")
    dbDisconnect(con)

    stored_vars <- jsonlite::fromJSON(stored$variables_stored[1])
    expect_equal(stored_vars, vars)
  })

  clean_test_db()
  cat("✅ All checkpoint registration tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 4: Project Status Updates
# ═══════════════════════════════════════════════════════════════════════════

test_status_updates <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 4: Project Status Updates\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("update_project_status changes status", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    update_project_status(project_id, "running", NULL, TEST_DB_PATH)

    project <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    expect_equal(project$status, "running")
  })

  test_that("update_project_status changes stage", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    update_project_status(project_id, NULL, "peak_picking", TEST_DB_PATH)

    project <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    expect_equal(project$processing_stage, "peak_picking")
  })

  test_that("update_project_status changes both", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    update_project_status(project_id, "completed", "export", TEST_DB_PATH)

    project <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    expect_equal(project$status, "completed")
    expect_equal(project$processing_stage, "export")
  })

  test_that("last_modified is updated", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    project_before <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    Sys.sleep(1)

    update_project_status(project_id, "running", NULL, TEST_DB_PATH)

    project_after <- get_project_info(TEST_PROJECT_NAME, TEST_DB_PATH)
    expect_true(project_after$last_modified > project_before$last_modified)
  })

  clean_test_db()
  cat("✅ All status update tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 5: Processing Logs
# ═══════════════════════════════════════════════════════════════════════════

test_processing_logs <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 5: Processing Logs\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("log_processing_event creates log entry", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    log_id <- log_processing_event(
      project_id = project_id,
      step_name = "peak_picking",
      log_level = "INFO",
      message = "Peak picking completed",
      execution_time_seconds = 123.45,
      db_path = TEST_DB_PATH
    )

    expect_true(!is.null(log_id))
    expect_true(is.numeric(log_id))
  })

  test_that("logs can be retrieved", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    log_processing_event(project_id, "step1", "INFO", "Message 1", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step2", "WARNING", "Message 2", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step3", "ERROR", "Message 3", NULL, NULL, TEST_DB_PATH)

    logs <- get_processing_logs(project_id, NULL, NULL, 100, TEST_DB_PATH)

    expect_equal(nrow(logs), 3)
  })

  test_that("logs can be filtered by level", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    log_processing_event(project_id, "step1", "INFO", "Message", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step2", "ERROR", "Error", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step3", "INFO", "Message", NULL, NULL, TEST_DB_PATH)

    error_logs <- get_processing_logs(project_id, "ERROR", NULL, 100, TEST_DB_PATH)

    expect_equal(nrow(error_logs), 1)
    expect_equal(error_logs$log_level, "ERROR")
  })

  test_that("logs can be filtered by step", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    log_processing_event(project_id, "peak_picking", "INFO", "Message", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "grouping", "INFO", "Message", NULL, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "peak_picking", "INFO", "Message", NULL, NULL, TEST_DB_PATH)

    step_logs <- get_processing_logs(project_id, NULL, "peak_picking", 100, TEST_DB_PATH)

    expect_equal(nrow(step_logs), 2)
    expect_true(all(step_logs$step_name == "peak_picking"))
  })

  clean_test_db()
  cat("✅ All processing log tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 6: Crash Detection
# ═══════════════════════════════════════════════════════════════════════════

test_crash_detection <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 6: Crash Detection\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("detect_crash_from_db identifies running project as crashed", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    # Add checkpoint
    register_checkpoint(project_id, "step_01", "Step 1", "/path.rds",
                       1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)

    # Mark as running (simulates crash)
    update_project_status(project_id, "running", "step_01", TEST_DB_PATH)

    crash_info <- detect_crash_from_db(TEST_PROJECT_NAME, TEST_DB_PATH)

    expect_true(crash_info$crashed)
    expect_true(crash_info$can_resume)
    expect_equal(crash_info$status, "running")
  })

  test_that("detect_crash_from_db finds last checkpoint", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    # Add multiple checkpoints
    for (i in 1:3) {
      register_checkpoint(project_id, paste0("step_", i), paste("Step", i),
                         "/path.rds", 1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)
      Sys.sleep(0.1)
    }

    update_project_status(project_id, "running", "step_03", TEST_DB_PATH)

    crash_info <- detect_crash_from_db(TEST_PROJECT_NAME, TEST_DB_PATH)

    expect_equal(crash_info$last_checkpoint$step_id, "step_3")
  })

  test_that("detect_crash_from_db returns FALSE for completed project", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    update_project_status(project_id, "completed", "export", TEST_DB_PATH)

    crash_info <- detect_crash_from_db(TEST_PROJECT_NAME, TEST_DB_PATH)

    expect_false(crash_info$crashed)
  })

  test_that("detect_crash_from_db handles non-existent project", {
    crash_info <- detect_crash_from_db("NonExistentProject", TEST_DB_PATH)

    expect_false(crash_info$crashed)
    expect_false(crash_info$can_resume)
    expect_false(crash_info$project_exists)
  })

  clean_test_db()
  cat("✅ All crash detection tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 7: Checkpoint Management
# ═══════════════════════════════════════════════════════════════════════════

test_checkpoint_management <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 7: Checkpoint Management\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("invalidate_checkpoint marks checkpoint as invalid", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    checkpoint_id <- register_checkpoint(project_id, "step_01", "Step 1", "/path.rds",
                                        1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)

    invalidate_checkpoint(checkpoint_id, TEST_DB_PATH)

    con <- dbConnect(RSQLite::SQLite(), TEST_DB_PATH)
    result <- dbGetQuery(con, "SELECT is_valid FROM checkpoints WHERE checkpoint_id = ?",
                        params = list(checkpoint_id))
    dbDisconnect(con)

    expect_equal(result$is_valid, 0)
  })

  test_that("list_all_checkpoints excludes invalid by default", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    cp1 <- register_checkpoint(project_id, "step_01", "Step 1", "/p1.rds",
                               1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)
    cp2 <- register_checkpoint(project_id, "step_02", "Step 2", "/p2.rds",
                               1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)

    invalidate_checkpoint(cp1, TEST_DB_PATH)

    checkpoints <- list_all_checkpoints(project_id, FALSE, TEST_DB_PATH)
    expect_equal(nrow(checkpoints), 1)
    expect_equal(checkpoints$step_id, "step_02")
  })

  test_that("list_all_checkpoints includes invalid when requested", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    cp1 <- register_checkpoint(project_id, "step_01", "Step 1", "/p1.rds",
                               1.0, "abc", c("v"), "Next", NULL, TEST_DB_PATH)

    invalidate_checkpoint(cp1, TEST_DB_PATH)

    checkpoints <- list_all_checkpoints(project_id, TRUE, TEST_DB_PATH)
    expect_equal(nrow(checkpoints), 1)
    expect_equal(checkpoints$is_valid, 0)
  })

  clean_test_db()
  cat("✅ All checkpoint management tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# TEST SUITE 8: Project Statistics
# ═══════════════════════════════════════════════════════════════════════════

test_project_statistics <- function() {
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 8: Project Statistics\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  clean_test_db()
  init_database(TEST_DB_PATH)

  test_that("get_project_statistics returns complete info", {
    project_id <- register_project(TEST_PROJECT_NAME, TEST_DATA_DIR, 100,
                                   "cache", NULL, TEST_DB_PATH)

    # Add checkpoints
    for (i in 1:3) {
      register_checkpoint(project_id, paste0("step_", i), paste("Step", i),
                         "/path.rds", i * 2.5, "abc", c("v"), "Next", NULL, TEST_DB_PATH)
    }

    # Add logs
    log_processing_event(project_id, "step1", "INFO", "Message", 10.0, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step2", "WARNING", "Warning", 20.0, NULL, TEST_DB_PATH)
    log_processing_event(project_id, "step3", "ERROR", "Error", NULL, NULL, TEST_DB_PATH)

    stats <- get_project_statistics(project_id, TEST_DB_PATH)

    expect_true(!is.null(stats))
    expect_true(!is.null(stats$project))
    expect_equal(stats$checkpoints$total_checkpoints, 3)
    expect_equal(stats$logs$total_logs, 3)
    expect_equal(stats$logs$error_count, 1)
    expect_equal(stats$logs$warning_count, 1)
  })

  clean_test_db()
  cat("✅ All project statistics tests passed!\n\n")
}


# ═══════════════════════════════════════════════════════════════════════════
# Main Test Runner
# ═══════════════════════════════════════════════════════════════════════════

run_database_tests <- function() {
  cat("\n")
  cat("╔═══════════════════════════════════════════════════════════════╗\n")
  cat("║      DATABASE MANAGER TEST SUITE                              ║\n")
  cat("╚═══════════════════════════════════════════════════════════════╝\n")

  start_time <- Sys.time()

  tryCatch({
    test_database_initialization()
    test_project_registration()
    test_checkpoint_registration()
    test_status_updates()
    test_processing_logs()
    test_crash_detection()
    test_checkpoint_management()
    test_project_statistics()

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat("═══════════════════════════════════════════════════════════════\n")
    cat("🎉 ALL DATABASE TESTS PASSED!\n")
    cat(sprintf("⏱️  Total time: %.2f seconds\n", elapsed))
    cat("═══════════════════════════════════════════════════════════════\n\n")

  }, error = function(e) {
    cat("\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("❌ DATABASE TEST SUITE FAILED\n")
    cat("═══════════════════════════════════════════════════════════════\n")
    cat("Error:", e$message, "\n\n")

  }, finally = {
    clean_test_db()
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# Quick Test Function
# ═══════════════════════════════════════════════════════════════════════════

quick_database_test <- function() {
  cat("Running quick database validation test...\n\n")

  clean_test_db()

  # Basic workflow
  init_database(TEST_DB_PATH)
  project_id <- register_project("QuickTest", "/data", 100, "cache", NULL, TEST_DB_PATH)
  register_checkpoint(project_id, "test_step", "Test", "/path.rds",
                     1.0, "abc", c("var"), "Next", NULL, TEST_DB_PATH)
  update_project_status(project_id, "running", "test_step", TEST_DB_PATH)

  crash_info <- detect_crash_from_db("QuickTest", TEST_DB_PATH)

  if (crash_info$crashed && crash_info$can_resume) {
    cat("✅ Quick database test PASSED!\n")
  } else {
    cat("❌ Quick database test FAILED!\n")
  }

  clean_test_db()
}


# ═══════════════════════════════════════════════════════════════════════════
# Auto-run message
# ═══════════════════════════════════════════════════════════════════════════

if (!interactive()) {
  cat("Database test script loaded. Run run_database_tests() to execute all tests.\n")
  cat("Or run quick_database_test() for fast validation.\n\n")
}

# ═══════════════════════════════════════════════════════════════════════════
# End of test_database_manager.R
# ═══════════════════════════════════════════════════════════════════════════
