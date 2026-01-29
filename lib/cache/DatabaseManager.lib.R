# ═══════════════════════════════════════════════════════════════════════════
# DatabaseManager.lib.R - SQLite Database Manager for Cache System
# ═══════════════════════════════════════════════════════════════════════════
#
# Manages SQLite database for cache metadata, project tracking, and logs
#
# Dependencies: RSQLite, DBI
#
# Tables:
# - projects: Project metadata and status
# - checkpoints: Checkpoint registry with file paths
# - processing_logs: Execution logs and timing
#
# Functions:
# - init_database() - Initialize database structure
# - register_project() - Register/update project in database
# - register_checkpoint() - Register checkpoint with metadata
# - get_project_info() - Get project information
# - get_last_checkpoint() - Get last valid checkpoint
# - list_all_checkpoints() - List all project checkpoints
# - update_project_status() - Update project status and stage
# - log_processing_event() - Add processing log entry
# - detect_crash_from_db() - Detect crash from database status
# - get_project_statistics() - Get project statistics
# - invalidate_checkpoint() - Mark checkpoint as invalid
# - cleanup_invalid_checkpoints() - Remove invalid checkpoint files
# - get_processing_logs() - Get filtered processing logs
#
# ═══════════════════════════════════════════════════════════════════════════

library(RSQLite)
library(DBI)

# Default database path
DEFAULT_DB_PATH <- "cache_projects/mspandas.sqlite"


# ═══════════════════════════════════════════════════════════════════════════
# init_database - Initialize Database Structure
# ═══════════════════════════════════════════════════════════════════════════
#' Initialize SQLite database with required tables and indexes
#'
#' @param db_path Path to SQLite database file
#'
#' @return Database path
#'
#' @examples
#' init_database()
#' init_database("custom_path/database.sqlite")
init_database <- function(db_path = DEFAULT_DB_PATH) {

  # Create directory if needed
  dir.create(dirname(db_path), recursive = TRUE, showWarnings = FALSE)

  con <- dbConnect(RSQLite::SQLite(), db_path)

  # Enable foreign keys
  dbExecute(con, "PRAGMA foreign_keys = ON")

  # ─────────────────────────────────────────────────────────────────────────
  # Table: projects
  # ─────────────────────────────────────────────────────────────────────────
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS projects (
      project_id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_name TEXT NOT NULL UNIQUE,
      data_directory TEXT NOT NULL,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL,
      status TEXT DEFAULT 'initialized',
      total_files INTEGER DEFAULT 0,
      processing_stage TEXT DEFAULT 'none',
      cache_directory TEXT,
      cache_id TEXT
    )
  ")

  # ─────────────────────────────────────────────────────────────────────────
  # Table: checkpoints
  # ─────────────────────────────────────────────────────────────────────────
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS checkpoints (
      checkpoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL,
      step_id TEXT NOT NULL,
      step_name TEXT NOT NULL,
      checkpoint_file_path TEXT NOT NULL,
      created_at TEXT NOT NULL,
      file_size_mb REAL,
      checksum_md5 TEXT,
      is_valid INTEGER DEFAULT 1,
      variables_stored TEXT,
      next_step TEXT,
      execution_time_seconds REAL,
      FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE
    )
  ")

  # ─────────────────────────────────────────────────────────────────────────
  # Table: processing_logs
  # ─────────────────────────────────────────────────────────────────────────
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS processing_logs (
      log_id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL,
      timestamp TEXT NOT NULL,
      step_name TEXT NOT NULL,
      log_level TEXT NOT NULL,
      message TEXT,
      execution_time_seconds REAL,
      error_details TEXT,
      FOREIGN KEY (project_id) REFERENCES projects(project_id) ON DELETE CASCADE
    )
  ")

  # ─────────────────────────────────────────────────────────────────────────
  # Indexes for performance
  # ─────────────────────────────────────────────────────────────────────────
  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_checkpoints_project
    ON checkpoints(project_id, created_at DESC)
  ")

  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_checkpoints_valid
    ON checkpoints(project_id, is_valid)
  ")

  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_logs_project
    ON processing_logs(project_id, timestamp DESC)
  ")

  dbExecute(con, "
    CREATE INDEX IF NOT EXISTS idx_logs_level
    ON processing_logs(log_level)
  ")

  dbDisconnect(con)

  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  SQLite Database Initialized\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("  Path:", db_path, "\n")
  cat("  Tables: projects, checkpoints, processing_logs\n")
  cat("═══════════════════════════════════════════════════════════════\n\n")

  return(db_path)
}


# ═══════════════════════════════════════════════════════════════════════════
# register_project - Register or Update Project in Database
# ═══════════════════════════════════════════════════════════════════════════
#' Register a new project or update existing project in database
#'
#' @param project_name Project name (must be unique)
#' @param data_directory Data directory path
#' @param total_files Total number of files
#' @param cache_directory Cache directory path
#' @param cache_id Cache ID from cache_info
#' @param db_path Database path
#'
#' @return project_id
#'
#' @examples
#' project_id <- register_project("MyProject", "/data/raw", 312, "cache_projects/...")
register_project <- function(project_name, data_directory, total_files,
                            cache_directory, cache_id = NULL,
                            db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Check if project exists
    existing <- dbGetQuery(con, "
      SELECT project_id FROM projects WHERE project_name = ?
    ", params = list(project_name))

    if (nrow(existing) > 0) {
      # Update existing project
      dbExecute(con, "
        UPDATE projects
        SET data_directory = ?,
            last_modified = ?,
            total_files = ?,
            cache_directory = ?,
            cache_id = ?,
            status = 'initialized',
            processing_stage = 'none'
        WHERE project_name = ?
      ", params = list(
        data_directory,
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        total_files,
        cache_directory,
        cache_id,
        project_name
      ))

      project_id <- existing$project_id[1]

      cat("✅ Project updated in database:", project_name, "(ID:", project_id, ")\n")

    } else {
      # Insert new project
      dbExecute(con, "
        INSERT INTO projects
        (project_name, data_directory, created_at, last_modified,
         total_files, cache_directory, cache_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      ", params = list(
        project_name,
        data_directory,
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        total_files,
        cache_directory,
        cache_id
      ))

      project_id <- dbGetQuery(con, "SELECT last_insert_rowid() AS id")$id

      cat("✅ Project registered in database:", project_name, "(ID:", project_id, ")\n")
    }

    dbDisconnect(con)
    return(project_id)

  }, error = function(e) {
    dbDisconnect(con)
    stop("Failed to register project: ", e$message)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# register_checkpoint - Register Checkpoint in Database
# ═══════════════════════════════════════════════════════════════════════════
#' Register a checkpoint in the database with metadata
#'
#' @param project_id Project ID from database
#' @param step_id Step identifier (e.g., "step_01_peak_picking")
#' @param step_name Human-readable step name
#' @param checkpoint_file_path Full path to checkpoint RDS file
#' @param file_size_mb File size in megabytes
#' @param checksum_md5 MD5 checksum of file
#' @param variables_stored Vector of variable names stored
#' @param next_step Description of next step
#' @param execution_time_seconds Execution time for this step
#' @param db_path Database path
#'
#' @return checkpoint_id
register_checkpoint <- function(project_id, step_id, step_name,
                               checkpoint_file_path, file_size_mb,
                               checksum_md5, variables_stored, next_step,
                               execution_time_seconds = NULL,
                               db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Convert variables list to JSON
    variables_json <- jsonlite::toJSON(variables_stored, auto_unbox = TRUE)

    # Insert checkpoint
    dbExecute(con, "
      INSERT INTO checkpoints
      (project_id, step_id, step_name, checkpoint_file_path, created_at,
       file_size_mb, checksum_md5, variables_stored, next_step, execution_time_seconds)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ", params = list(
      project_id,
      step_id,
      step_name,
      checkpoint_file_path,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      file_size_mb,
      checksum_md5,
      as.character(variables_json),
      next_step,
      execution_time_seconds
    ))

    checkpoint_id <- dbGetQuery(con, "SELECT last_insert_rowid() AS id")$id

    dbDisconnect(con)

    cat("💾 Checkpoint registered in database:", step_id, "(ID:", checkpoint_id, ")\n")

    return(checkpoint_id)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to register checkpoint: ", e$message)
    return(NULL)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# get_project_info - Get Project Information
# ═══════════════════════════════════════════════════════════════════════════
#' Get project information from database
#'
#' @param project_name Project name
#' @param db_path Database path
#'
#' @return Data frame with project info or NULL if not found
get_project_info <- function(project_name, db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  project <- dbGetQuery(con, "
    SELECT * FROM projects WHERE project_name = ?
  ", params = list(project_name))

  dbDisconnect(con)

  if (nrow(project) == 0) {
    return(NULL)
  }

  return(project)
}


# ═══════════════════════════════════════════════════════════════════════════
# get_last_checkpoint - Get Last Valid Checkpoint
# ═══════════════════════════════════════════════════════════════════════════
#' Get the last valid checkpoint for a project
#'
#' @param project_id Project ID
#' @param db_path Database path
#'
#' @return Data frame with checkpoint info or NULL if none found
get_last_checkpoint <- function(project_id, db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  checkpoint <- dbGetQuery(con, "
    SELECT * FROM checkpoints
    WHERE project_id = ? AND is_valid = 1
    ORDER BY created_at DESC
    LIMIT 1
  ", params = list(project_id))

  dbDisconnect(con)

  if (nrow(checkpoint) == 0) {
    return(NULL)
  }

  return(checkpoint)
}


# ═══════════════════════════════════════════════════════════════════════════
# list_all_checkpoints - List All Checkpoints for Project
# ═══════════════════════════════════════════════════════════════════════════
#' List all checkpoints for a project
#'
#' @param project_id Project ID
#' @param include_invalid Include invalid checkpoints (default: FALSE)
#' @param db_path Database path
#'
#' @return Data frame with checkpoints
list_all_checkpoints <- function(project_id, include_invalid = FALSE,
                                 db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  if (include_invalid) {
    checkpoints <- dbGetQuery(con, "
      SELECT * FROM checkpoints
      WHERE project_id = ?
      ORDER BY created_at DESC
    ", params = list(project_id))
  } else {
    checkpoints <- dbGetQuery(con, "
      SELECT * FROM checkpoints
      WHERE project_id = ? AND is_valid = 1
      ORDER BY created_at DESC
    ", params = list(project_id))
  }

  dbDisconnect(con)

  return(checkpoints)
}


# ═══════════════════════════════════════════════════════════════════════════
# update_project_status - Update Project Status and Stage
# ═══════════════════════════════════════════════════════════════════════════
#' Update project status and processing stage
#'
#' @param project_id Project ID
#' @param status Status (initialized, running, completed, crashed, failed)
#' @param processing_stage Current processing stage
#' @param db_path Database path
#'
#' @return TRUE if successful
update_project_status <- function(project_id, status = NULL,
                                  processing_stage = NULL,
                                  db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Build dynamic UPDATE query
    updates <- c()
    params <- list()

    if (!is.null(status)) {
      updates <- c(updates, "status = ?")
      params <- c(params, list(status))
    }

    if (!is.null(processing_stage)) {
      updates <- c(updates, "processing_stage = ?")
      params <- c(params, list(processing_stage))
    }

    updates <- c(updates, "last_modified = ?")
    params <- c(params, list(format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

    # Add project_id at the end (for WHERE clause)
    params <- c(params, list(project_id))

    query <- paste0("
      UPDATE projects
      SET ", paste(updates, collapse = ", "), "
      WHERE project_id = ?
    ")

    dbExecute(con, query, params = params)

    dbDisconnect(con)

    return(TRUE)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to update project status: ", e$message)
    return(FALSE)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# log_processing_event - Add Processing Log Entry
# ═══════════════════════════════════════════════════════════════════════════
#' Log a processing event to database
#'
#' @param project_id Project ID
#' @param step_name Step name
#' @param log_level Log level (INFO, WARNING, ERROR)
#' @param message Log message
#' @param execution_time_seconds Execution time in seconds
#' @param error_details Error details if applicable
#' @param db_path Database path
#'
#' @return log_id or NULL if failed
log_processing_event <- function(project_id, step_name, log_level,
                                 message, execution_time_seconds = NULL,
                                 error_details = NULL,
                                 db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    dbExecute(con, "
      INSERT INTO processing_logs
      (project_id, timestamp, step_name, log_level, message,
       execution_time_seconds, error_details)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    ", params = list(
      project_id,
      format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      step_name,
      log_level,
      message,
      execution_time_seconds,
      error_details
    ))

    log_id <- dbGetQuery(con, "SELECT last_insert_rowid() AS id")$id

    dbDisconnect(con)

    return(log_id)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to log event: ", e$message)
    return(NULL)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# detect_crash_from_db - Detect Crash from Database Status
# ═══════════════════════════════════════════════════════════════════════════
#' Detect if project crashed by checking database status
#'
#' @param project_name Project name
#' @param db_path Database path
#'
#' @return List with crash detection info
detect_crash_from_db <- function(project_name, db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Get project info
    project <- dbGetQuery(con, "
      SELECT * FROM projects WHERE project_name = ?
    ", params = list(project_name))

    if (nrow(project) == 0) {
      dbDisconnect(con)
      return(list(
        crashed = FALSE,
        can_resume = FALSE,
        project_exists = FALSE
      ))
    }

    # Check if status indicates crash (status="running" means previous session didn't finish)
    crashed <- project$status == "running"

    # Get last checkpoint
    checkpoint <- dbGetQuery(con, "
      SELECT * FROM checkpoints
      WHERE project_id = ? AND is_valid = 1
      ORDER BY created_at DESC
      LIMIT 1
    ", params = list(project$project_id))

    # Get checkpoint count
    checkpoint_count <- dbGetQuery(con, "
      SELECT COUNT(*) as count FROM checkpoints
      WHERE project_id = ? AND is_valid = 1
    ", params = list(project$project_id))$count

    dbDisconnect(con)

    return(list(
      crashed = crashed,
      can_resume = nrow(checkpoint) > 0,
      project_exists = TRUE,
      project_id = project$project_id,
      project_name = project$project_name,
      status = project$status,
      processing_stage = project$processing_stage,
      last_checkpoint = if(nrow(checkpoint) > 0) checkpoint else NULL,
      checkpoint_count = checkpoint_count,
      total_files = project$total_files,
      cache_directory = project$cache_directory
    ))

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to detect crash: ", e$message)
    return(list(crashed = FALSE, can_resume = FALSE, error = e$message))
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# get_project_statistics - Get Project Statistics
# ═══════════════════════════════════════════════════════════════════════════
#' Get comprehensive statistics for a project
#'
#' @param project_id Project ID
#' @param db_path Database path
#'
#' @return List with statistics
get_project_statistics <- function(project_id, db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Get project info
    project <- dbGetQuery(con, "
      SELECT * FROM projects WHERE project_id = ?
    ", params = list(project_id))

    # Get checkpoint statistics
    checkpoint_stats <- dbGetQuery(con, "
      SELECT
        COUNT(*) as total_checkpoints,
        COUNT(CASE WHEN is_valid = 1 THEN 1 END) as valid_checkpoints,
        SUM(file_size_mb) as total_size_mb,
        MAX(created_at) as last_checkpoint_time
      FROM checkpoints
      WHERE project_id = ?
    ", params = list(project_id))

    # Get log statistics
    log_stats <- dbGetQuery(con, "
      SELECT
        COUNT(*) as total_logs,
        COUNT(CASE WHEN log_level = 'ERROR' THEN 1 END) as error_count,
        COUNT(CASE WHEN log_level = 'WARNING' THEN 1 END) as warning_count,
        SUM(execution_time_seconds) as total_execution_time
      FROM processing_logs
      WHERE project_id = ?
    ", params = list(project_id))

    # Get recent logs
    recent_logs <- dbGetQuery(con, "
      SELECT * FROM processing_logs
      WHERE project_id = ?
      ORDER BY timestamp DESC
      LIMIT 10
    ", params = list(project_id))

    dbDisconnect(con)

    return(list(
      project = project,
      checkpoints = checkpoint_stats,
      logs = log_stats,
      recent_logs = recent_logs
    ))

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to get statistics: ", e$message)
    return(NULL)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# invalidate_checkpoint - Mark Checkpoint as Invalid
# ═══════════════════════════════════════════════════════════════════════════
#' Mark a checkpoint as invalid (corrupted or outdated)
#'
#' @param checkpoint_id Checkpoint ID
#' @param db_path Database path
#'
#' @return TRUE if successful
invalidate_checkpoint <- function(checkpoint_id, db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    dbExecute(con, "
      UPDATE checkpoints
      SET is_valid = 0
      WHERE checkpoint_id = ?
    ", params = list(checkpoint_id))

    dbDisconnect(con)

    cat("⚠️  Checkpoint marked as invalid:", checkpoint_id, "\n")

    return(TRUE)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to invalidate checkpoint: ", e$message)
    return(FALSE)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# cleanup_invalid_checkpoints - Remove Invalid Checkpoint Files
# ═══════════════════════════════════════════════════════════════════════════
#' Remove checkpoint files that are marked as invalid
#'
#' @param project_id Project ID (optional, NULL for all projects)
#' @param db_path Database path
#'
#' @return Number of files deleted
cleanup_invalid_checkpoints <- function(project_id = NULL,
                                       db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Get invalid checkpoints
    if (is.null(project_id)) {
      invalid_checkpoints <- dbGetQuery(con, "
        SELECT checkpoint_id, checkpoint_file_path
        FROM checkpoints
        WHERE is_valid = 0
      ")
    } else {
      invalid_checkpoints <- dbGetQuery(con, "
        SELECT checkpoint_id, checkpoint_file_path
        FROM checkpoints
        WHERE is_valid = 0 AND project_id = ?
      ", params = list(project_id))
    }

    deleted_count <- 0

    for (i in seq_len(nrow(invalid_checkpoints))) {
      file_path <- invalid_checkpoints$checkpoint_file_path[i]

      if (file.exists(file_path)) {
        unlink(file_path)
        deleted_count <- deleted_count + 1
        cat("🗑️  Deleted invalid checkpoint:", basename(file_path), "\n")
      }
    }

    # Delete from database
    if (is.null(project_id)) {
      dbExecute(con, "DELETE FROM checkpoints WHERE is_valid = 0")
    } else {
      dbExecute(con, "
        DELETE FROM checkpoints
        WHERE is_valid = 0 AND project_id = ?
      ", params = list(project_id))
    }

    dbDisconnect(con)

    cat("✅ Cleaned up", deleted_count, "invalid checkpoint(s)\n")

    return(deleted_count)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to cleanup checkpoints: ", e$message)
    return(0)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# get_processing_logs - Get Filtered Processing Logs
# ═══════════════════════════════════════════════════════════════════════════
#' Get processing logs with optional filters
#'
#' @param project_id Project ID
#' @param log_level Filter by log level (optional)
#' @param step_name Filter by step name (optional)
#' @param limit Maximum number of logs to return
#' @param db_path Database path
#'
#' @return Data frame with logs
get_processing_logs <- function(project_id, log_level = NULL,
                               step_name = NULL, limit = 100,
                               db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Build dynamic query
    query <- "SELECT * FROM processing_logs WHERE project_id = ?"
    params <- list(project_id)

    if (!is.null(log_level)) {
      query <- paste(query, "AND log_level = ?")
      params <- c(params, list(log_level))
    }

    if (!is.null(step_name)) {
      query <- paste(query, "AND step_name = ?")
      params <- c(params, list(step_name))
    }

    query <- paste(query, "ORDER BY timestamp DESC LIMIT ?")
    params <- c(params, list(limit))

    logs <- dbGetQuery(con, query, params = params)

    dbDisconnect(con)

    return(logs)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to get logs: ", e$message)
    return(data.frame())
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# get_all_projects - Get All Projects
# ═══════════════════════════════════════════════════════════════════════════
#' Get all projects from database
#'
#' @param db_path Database path
#'
#' @return Data frame with all projects
get_all_projects <- function(db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  projects <- dbGetQuery(con, "
    SELECT * FROM projects
    ORDER BY last_modified DESC
  ")

  dbDisconnect(con)

  return(projects)
}


# ═══════════════════════════════════════════════════════════════════════════
# delete_project - Delete Project and All Associated Data
# ═══════════════════════════════════════════════════════════════════════════
#' Delete project from database (CASCADE deletes checkpoints and logs)
#'
#' @param project_id Project ID
#' @param delete_files Also delete checkpoint files (default: TRUE)
#' @param db_path Database path
#'
#' @return TRUE if successful
delete_project <- function(project_id, delete_files = TRUE,
                          db_path = DEFAULT_DB_PATH) {

  con <- dbConnect(RSQLite::SQLite(), db_path)

  tryCatch({

    # Get checkpoint files before deletion
    if (delete_files) {
      checkpoints <- dbGetQuery(con, "
        SELECT checkpoint_file_path FROM checkpoints WHERE project_id = ?
      ", params = list(project_id))

      # Delete checkpoint files
      for (file_path in checkpoints$checkpoint_file_path) {
        if (file.exists(file_path)) {
          unlink(file_path)
        }
      }
    }

    # Delete project (CASCADE will delete checkpoints and logs)
    dbExecute(con, "DELETE FROM projects WHERE project_id = ?",
              params = list(project_id))

    dbDisconnect(con)

    cat("✅ Project deleted:", project_id, "\n")

    return(TRUE)

  }, error = function(e) {
    dbDisconnect(con)
    warning("Failed to delete project: ", e$message)
    return(FALSE)
  })
}


# ═══════════════════════════════════════════════════════════════════════════
# End of DatabaseManager.lib.R
# ═══════════════════════════════════════════════════════════════════════════

cat("✅ DatabaseManager.lib.R loaded successfully\n")
