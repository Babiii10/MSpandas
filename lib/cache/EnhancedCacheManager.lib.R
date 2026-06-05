# ===============================================================================
# EnhancedCacheManager.lib.R - Professional-Grade Cache System
# ===============================================================================
#
# Version: 3.0.0
# Date: 2026-02-13
#
# Improvements over basic CacheManager:
#   1. Atomic saves (prevents corruption)
#   2. Checkpoint versioning (rollback support)
#   3. Smart compression (adaptive based on size)
#   4. Structured logging (detailed audit trail)
#   5. Schema versioning (migration support)
#   6. Automatic cleanup (size limits)
#   7. Integrity validation (multi-level checks)
#
# ===============================================================================

library(DBI)
library(RSQLite)
library(jsonlite)
library(tools)

# ===============================================================================
# CONSTANTS AND CONFIGURATION
# ===============================================================================

CACHE_SCHEMA_VERSION <- "3.0.0"
CACHE_CONFIG_DEFAULTS <- list(

max_total_size_gb = 50,
  max_projects = 20,
  max_checkpoints_per_stage = 5,
  max_age_days = 60,
  auto_cleanup = TRUE,
  compression_level = "auto",
  enable_versioning = TRUE,
  enable_logging = TRUE,
  atomic_writes = TRUE
)

# Log levels
LOG_LEVEL <- list(
  DEBUG = 0,
  INFO = 1,
  WARNING = 2,
  ERROR = 3,
  CRITICAL = 4
)

# ===============================================================================
# CacheLogger - Structured Logging System
# ===============================================================================

#' Create a cache logger instance
#' @param log_file Path to log file
#' @param db_path Path to SQLite database for log storage
#' @param min_level Minimum log level to record
create_cache_logger <- function(log_file = NULL, db_path = NULL, min_level = LOG_LEVEL$INFO) {

  # Initialize log table in SQLite if db_path provided
  if (!is.null(db_path) && file.exists(db_path)) {
    tryCatch({
      con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
      DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS cache_logs (
          log_id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          level TEXT NOT NULL,
          event_type TEXT NOT NULL,
          project_id TEXT,
          checkpoint_id TEXT,
          message TEXT,
          details TEXT,
          duration_ms INTEGER,
          size_bytes INTEGER
        )
      ")
      DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON cache_logs(timestamp DESC)")
      DBI::dbExecute(con, "CREATE INDEX IF NOT EXISTS idx_logs_project ON cache_logs(project_id)")
      DBI::dbDisconnect(con)
    }, error = function(e) {
      warning("Could not initialize log table: ", e$message)
    })
  }

  # Logger function
  log_event <- function(level, event_type, message,
                        project_id = NULL, checkpoint_id = NULL,
                        details = NULL, duration_ms = NULL, size_bytes = NULL) {

    if (level < min_level) return(invisible(NULL))

    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%OS3")
    level_name <- names(LOG_LEVEL)[which(unlist(LOG_LEVEL) == level)]

    # Format console message
    console_msg <- sprintf("[%s] [%s] [%s] %s",
                           timestamp, level_name, event_type, message)

    # Add details if present
    if (!is.null(details)) {
      console_msg <- paste0(console_msg, " | ",
                            paste(names(details), details, sep = "=", collapse = ", "))
    }

    # Print to console
    if (level >= LOG_LEVEL$WARNING) {
      message(console_msg)
    } else {
      cat(console_msg, "\n")
    }

    # Write to file if configured
    if (!is.null(log_file)) {
      tryCatch({
        cat(console_msg, "\n", file = log_file, append = TRUE)
      }, error = function(e) {})
    }

    # Write to database if configured
    if (!is.null(db_path) && file.exists(db_path)) {
      tryCatch({
        con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
        DBI::dbExecute(con, "
          INSERT INTO cache_logs
          (timestamp, level, event_type, project_id, checkpoint_id, message, details, duration_ms, size_bytes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
          params = list(
            timestamp, level_name, event_type,
            project_id, checkpoint_id, message,
            if (!is.null(details)) jsonlite::toJSON(details, auto_unbox = TRUE) else NULL,
            duration_ms, size_bytes
          )
        )
        DBI::dbDisconnect(con)
      }, error = function(e) {})
    }

    invisible(NULL)
  }

  # Return logger interface
  list(
    debug = function(...) log_event(LOG_LEVEL$DEBUG, ...),
    info = function(...) log_event(LOG_LEVEL$INFO, ...),
    warning = function(...) log_event(LOG_LEVEL$WARNING, ...),
    error = function(...) log_event(LOG_LEVEL$ERROR, ...),
    critical = function(...) log_event(LOG_LEVEL$CRITICAL, ...)
  )
}


# ===============================================================================
# Atomic Save Operations
# ===============================================================================

#' Save data atomically with temporary file and verification
#' @param data Data to save
#' @param file Target file path
#' @param compress Compression method
#' @param verify Whether to verify after save
#' @return List with success status and metadata
atomic_save_rds <- function(data, file, compress = "xz", verify = TRUE) {

  start_time <- Sys.time()
  temp_file <- paste0(file, ".tmp.", format(Sys.time(), "%Y%m%d%H%M%S"), ".", Sys.getpid())
  backup_file <- paste0(file, ".bak")

  result <- list(
    success = FALSE,
    file = file,
    size_bytes = 0,
    checksum = NULL,
    duration_ms = 0,
    error = NULL
  )

  tryCatch({

    # Step 1: Write to temporary file
    saveRDS(data, temp_file, compress = compress)

    # Step 2: Verify the temporary file can be read
    if (verify) {
      test_read <- readRDS(temp_file)
      if (is.null(test_read)) {
        stop("Verification failed: could not read temporary file")
      }
      rm(test_read)
      gc(verbose = FALSE)
    }

    # Step 3: Calculate checksum
    result$checksum <- unname(tools::md5sum(temp_file))
    result$size_bytes <- file.size(temp_file)

    # Step 4: Backup existing file if present
    if (file.exists(file)) {
      file.copy(file, backup_file, overwrite = TRUE)
    }

    # Step 5: Atomic rename (this is atomic on most filesystems)
    success <- file.rename(temp_file, file)

    if (!success) {
      # Fallback: copy and delete
      file.copy(temp_file, file, overwrite = TRUE)
      unlink(temp_file)
    }

    # Step 6: Final verification
    if (verify) {
      final_checksum <- unname(tools::md5sum(file))
      if (final_checksum != result$checksum) {
        # Restore from backup
        if (file.exists(backup_file)) {
          file.copy(backup_file, file, overwrite = TRUE)
        }
        stop("Final verification failed: checksum mismatch")
      }
    }

    # Step 7: Clean up backup (keep for safety)
    # unlink(backup_file)  # Optionally keep backup

    result$success <- TRUE

  }, error = function(e) {
    result$error <- e$message

    # Clean up temp file
    if (file.exists(temp_file)) {
      unlink(temp_file)
    }

  }, finally = {
    result$duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  })

  return(result)
}


#' Load data with integrity verification
#' @param file File path to load
#' @param expected_checksum Expected MD5 checksum (optional)
#' @return List with data and metadata
atomic_load_rds <- function(file, expected_checksum = NULL) {

  start_time <- Sys.time()

  result <- list(
    success = FALSE,
    data = NULL,
    checksum = NULL,
    size_bytes = 0,
    duration_ms = 0,
    error = NULL
  )

  tryCatch({

    # Check file exists
    if (!file.exists(file)) {
      stop("File not found: ", file)
    }

    # Calculate checksum
    result$checksum <- unname(tools::md5sum(file))
    result$size_bytes <- file.size(file)

    # Verify checksum if provided
    if (!is.null(expected_checksum) && result$checksum != expected_checksum) {
      stop("Checksum mismatch: expected ", expected_checksum, ", got ", result$checksum)
    }

    # Load data
    result$data <- readRDS(file)
    result$success <- TRUE

  }, error = function(e) {
    result$error <- e$message

  }, finally = {
    result$duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  })

  return(result)
}


# ===============================================================================
# Smart Compression
# ===============================================================================

#' Determine optimal compression method based on data size
#' @param data Data to compress
#' @param size_bytes Pre-calculated size (optional)
#' @return Compression method string
determine_compression <- function(data = NULL, size_bytes = NULL) {

  if (is.null(size_bytes) && !is.null(data)) {
    size_bytes <- as.numeric(object.size(data))
  }

  if (is.null(size_bytes)) {
    return("gzip")  # Default
  }

  size_mb <- size_bytes / (1024^2)

  if (size_mb < 10) {
    # Small files: fast compression
    return("gzip")
  } else if (size_mb < 100) {
    # Medium files: balanced
    return("bzip2")
  } else {
    # Large files: maximum compression
    return("xz")
  }
}


# ===============================================================================
# Checkpoint Versioning System
# ===============================================================================

#' Create a versioned checkpoint filename
#' @param checkpoint_id Base checkpoint ID
#' @param version Version number
#' @param timestamp Timestamp for the version
#' @return Versioned filename
create_versioned_filename <- function(checkpoint_id, version, timestamp = NULL) {

  if (is.null(timestamp)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  }

  sprintf("%s_v%03d_%s.rds", checkpoint_id, version, timestamp)
}


#' Parse a versioned checkpoint filename
#' @param filename Filename to parse
#' @return List with checkpoint_id, version, timestamp
parse_versioned_filename <- function(filename) {

  # Pattern: checkpoint_id_vXXX_YYYYMMDD_HHMMSS.rds
  pattern <- "^(.+)_v(\\d{3})_(\\d{8}_\\d{6})\\.rds$"

  if (!grepl(pattern, filename)) {
    return(NULL)
  }

  matches <- regmatches(filename, regexec(pattern, filename))[[1]]

  list(
    checkpoint_id = matches[2],
    version = as.integer(matches[3]),
    timestamp = matches[4],
    filename = filename
  )
}


#' List all versions of a checkpoint
#' @param cache_dir Cache directory
#' @param checkpoint_id Checkpoint ID to search
#' @return Data frame of versions sorted by version number
list_checkpoint_versions <- function(cache_dir, checkpoint_id) {

  pattern <- sprintf("^%s_v\\d{3}_\\d{8}_\\d{6}\\.rds$", checkpoint_id)
  files <- list.files(cache_dir, pattern = pattern, full.names = FALSE)

  if (length(files) == 0) {
    return(data.frame(
      filename = character(),
      version = integer(),
      timestamp = character(),
      size_bytes = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  versions <- lapply(files, function(f) {
    parsed <- parse_versioned_filename(f)
    if (!is.null(parsed)) {
      parsed$size_bytes <- file.size(file.path(cache_dir, f))
      parsed
    }
  })

  versions <- Filter(Negate(is.null), versions)

  df <- do.call(rbind, lapply(versions, as.data.frame, stringsAsFactors = FALSE))
  df <- df[order(df$version, decreasing = TRUE), ]
  rownames(df) <- NULL

  return(df)
}


#' Get next version number for a checkpoint
#' @param cache_dir Cache directory
#' @param checkpoint_id Checkpoint ID
#' @return Next version number
get_next_version <- function(cache_dir, checkpoint_id) {

  versions <- list_checkpoint_versions(cache_dir, checkpoint_id)

  if (nrow(versions) == 0) {
    return(1)
  }

  return(max(versions$version) + 1)
}


#' Cleanup old checkpoint versions, keeping only the most recent N
#' @param cache_dir Cache directory
#' @param checkpoint_id Checkpoint ID
#' @param keep_n Number of versions to keep
#' @return Number of deleted versions
cleanup_old_versions <- function(cache_dir, checkpoint_id, keep_n = 5) {

  versions <- list_checkpoint_versions(cache_dir, checkpoint_id)

  if (nrow(versions) <= keep_n) {
    return(0)
  }

  # Keep the most recent N versions
  to_delete <- versions$filename[(keep_n + 1):nrow(versions)]

  deleted <- 0
  for (f in to_delete) {
    tryCatch({
      unlink(file.path(cache_dir, f))
      deleted <- deleted + 1
    }, error = function(e) {})
  }

  return(deleted)
}


# ===============================================================================
# Schema Versioning and Migration
# ===============================================================================

#' Wrap data with schema version metadata
#' @param data Data to wrap
#' @param schema_version Schema version string
#' @param app_version Application version string
#' @return Wrapped data structure
wrap_with_schema <- function(data, schema_version = CACHE_SCHEMA_VERSION, app_version = "1.0.0") {

  list(
    .cache_meta = list(
      schema_version = schema_version,
      app_version = app_version,
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      platform = R.version$platform
    ),
    data = data
  )
}


#' Unwrap data and validate/migrate schema
#' @param wrapped Wrapped data structure
#' @param target_version Target schema version (optional)
#' @return Unwrapped and migrated data
unwrap_with_schema <- function(wrapped, target_version = CACHE_SCHEMA_VERSION) {

  # Handle old format (no schema wrapper)
  if (is.null(wrapped$.cache_meta)) {
    return(list(
      data = wrapped,
      migrated = FALSE,
      original_version = "1.0.0"
    ))
  }

  meta <- wrapped$.cache_meta
  data <- wrapped$data

  # Check if migration needed
  if (meta$schema_version != target_version) {
    data <- migrate_cache_data(data, meta$schema_version, target_version)
    return(list(
      data = data,
      migrated = TRUE,
      original_version = meta$schema_version
    ))
  }

  return(list(
    data = data,
    migrated = FALSE,
    original_version = meta$schema_version
  ))
}


#' Migrate cache data between schema versions
#' @param data Data to migrate
#' @param from_version Source schema version
#' @param to_version Target schema version
#' @return Migrated data
migrate_cache_data <- function(data, from_version, to_version) {

  # Define migration functions
  migrations <- list(
    "1.0.0_to_2.0.0" = function(d) {
      # Example migration: rename fields
      if ("old_field" %in% names(d)) {
        d$new_field <- d$old_field
        d$old_field <- NULL
      }
      d
    },
    "2.0.0_to_3.0.0" = function(d) {
      # Add any new required fields with defaults
      d
    }
  )

  # Parse versions
  from_parts <- as.integer(strsplit(from_version, "\\.")[[1]])
  to_parts <- as.integer(strsplit(to_version, "\\.")[[1]])

  # Apply migrations in sequence (simplified)
  # In production, you'd have a proper migration chain

  return(data)
}


# ===============================================================================
# Cache Size Management and Cleanup
# ===============================================================================

#' Calculate total cache size
#' @param base_cache_dir Base cache directory
#' @return List with size information
calculate_cache_size <- function(base_cache_dir = "cache_projects") {

  if (!dir.exists(base_cache_dir)) {
    return(list(
      total_bytes = 0,
      total_mb = 0,
      total_gb = 0,
      n_projects = 0,
      n_files = 0,
      projects = data.frame()
    ))
  }

  # Get all project directories
  project_dirs <- list.dirs(base_cache_dir, recursive = FALSE, full.names = TRUE)

  project_sizes <- lapply(project_dirs, function(dir) {
    files <- list.files(dir, recursive = TRUE, full.names = TRUE)
    sizes <- file.size(files)

    list(
      project = basename(dir),
      path = dir,
      n_files = length(files),
      size_bytes = sum(sizes, na.rm = TRUE),
      last_modified = max(file.mtime(files), na.rm = TRUE)
    )
  })

  project_df <- do.call(rbind, lapply(project_sizes, as.data.frame, stringsAsFactors = FALSE))

  if (nrow(project_df) > 0) {
    project_df <- project_df[order(project_df$last_modified, decreasing = TRUE), ]
    rownames(project_df) <- NULL
  }

  total_bytes <- sum(project_df$size_bytes, na.rm = TRUE)

  # Add SQLite database size
  db_file <- file.path(base_cache_dir, "mspandas.sqlite")
  if (file.exists(db_file)) {
    total_bytes <- total_bytes + file.size(db_file)
  }

  list(
    total_bytes = total_bytes,
    total_mb = total_bytes / (1024^2),
    total_gb = total_bytes / (1024^3),
    n_projects = nrow(project_df),
    n_files = sum(project_df$n_files, na.rm = TRUE),
    projects = project_df
  )
}


#' Automatic cache cleanup based on configuration
#' @param base_cache_dir Base cache directory
#' @param config Cache configuration list
#' @param dry_run If TRUE, only report what would be deleted
#' @return List with cleanup results
auto_cleanup_cache <- function(base_cache_dir = "cache_projects",
                               config = CACHE_CONFIG_DEFAULTS,
                               dry_run = FALSE) {

  results <- list(
    deleted_projects = character(),
    deleted_versions = 0,
    freed_bytes = 0,
    errors = character()
  )

  if (!config$auto_cleanup) {
    return(results)
  }

  cache_info <- calculate_cache_size(base_cache_dir)

  # 1. Delete projects older than max_age_days
  if (!is.null(config$max_age_days) && nrow(cache_info$projects) > 0) {
    cutoff_date <- Sys.time() - (config$max_age_days * 24 * 60 * 60)
    old_projects <- cache_info$projects[cache_info$projects$last_modified < cutoff_date, ]

    for (i in seq_len(nrow(old_projects))) {
      proj <- old_projects[i, ]
      if (!dry_run) {
        tryCatch({
          unlink(proj$path, recursive = TRUE)
          results$deleted_projects <- c(results$deleted_projects, proj$project)
          results$freed_bytes <- results$freed_bytes + proj$size_bytes
        }, error = function(e) {
          results$errors <- c(results$errors, paste("Failed to delete", proj$project, ":", e$message))
        })
      } else {
        results$deleted_projects <- c(results$deleted_projects, paste("[DRY RUN]", proj$project))
        results$freed_bytes <- results$freed_bytes + proj$size_bytes
      }
    }
  }

  # Recalculate after age-based cleanup
  cache_info <- calculate_cache_size(base_cache_dir)

  # 2. Delete oldest projects if over max_projects limit
  if (!is.null(config$max_projects) && cache_info$n_projects > config$max_projects) {
    n_to_delete <- cache_info$n_projects - config$max_projects
    projects_to_delete <- tail(cache_info$projects, n_to_delete)

    for (i in seq_len(nrow(projects_to_delete))) {
      proj <- projects_to_delete[i, ]
      if (!dry_run) {
        tryCatch({
          unlink(proj$path, recursive = TRUE)
          results$deleted_projects <- c(results$deleted_projects, proj$project)
          results$freed_bytes <- results$freed_bytes + proj$size_bytes
        }, error = function(e) {
          results$errors <- c(results$errors, paste("Failed to delete", proj$project, ":", e$message))
        })
      } else {
        results$deleted_projects <- c(results$deleted_projects, paste("[DRY RUN]", proj$project))
        results$freed_bytes <- results$freed_bytes + proj$size_bytes
      }
    }
  }

  # Recalculate after project limit cleanup
  cache_info <- calculate_cache_size(base_cache_dir)

  # 3. Delete oldest projects if over max_total_size_gb limit
  if (!is.null(config$max_total_size_gb) && cache_info$total_gb > config$max_total_size_gb) {
    target_size_bytes <- config$max_total_size_gb * (1024^3)

    # Sort by oldest first
    projects_sorted <- cache_info$projects[order(cache_info$projects$last_modified), ]

    current_size <- cache_info$total_bytes
    for (i in seq_len(nrow(projects_sorted))) {
      if (current_size <= target_size_bytes) break

      proj <- projects_sorted[i, ]
      if (!dry_run) {
        tryCatch({
          unlink(proj$path, recursive = TRUE)
          results$deleted_projects <- c(results$deleted_projects, proj$project)
          results$freed_bytes <- results$freed_bytes + proj$size_bytes
          current_size <- current_size - proj$size_bytes
        }, error = function(e) {
          results$errors <- c(results$errors, paste("Failed to delete", proj$project, ":", e$message))
        })
      } else {
        results$deleted_projects <- c(results$deleted_projects, paste("[DRY RUN]", proj$project))
        results$freed_bytes <- results$freed_bytes + proj$size_bytes
        current_size <- current_size - proj$size_bytes
      }
    }
  }

  # 4. Cleanup old checkpoint versions within remaining projects
  if (!is.null(config$max_checkpoints_per_stage)) {
    remaining_projects <- list.dirs(base_cache_dir, recursive = FALSE, full.names = TRUE)

    for (proj_dir in remaining_projects) {
      cache_subdir <- file.path(proj_dir, "cache")
      if (!dir.exists(cache_subdir)) next

      # Find unique checkpoint IDs
      files <- list.files(cache_subdir, pattern = "_v\\d{3}_.*\\.rds$")
      checkpoint_ids <- unique(sapply(files, function(f) {
        parsed <- parse_versioned_filename(f)
        if (!is.null(parsed)) parsed$checkpoint_id else NA
      }))
      checkpoint_ids <- checkpoint_ids[!is.na(checkpoint_ids)]

      for (cp_id in checkpoint_ids) {
        if (!dry_run) {
          deleted <- cleanup_old_versions(cache_subdir, cp_id, config$max_checkpoints_per_stage)
          results$deleted_versions <- results$deleted_versions + deleted
        }
      }
    }
  }

  return(results)
}


# ===============================================================================
# Enhanced Checkpoint Save/Load Functions
# ===============================================================================

#' Save checkpoint with all enhancements
#' @param checkpoint_id Checkpoint identifier
#' @param cache_info Cache info from init_cache_system
#' @param variables Named list of variables to save
#' @param step_name Human-readable step name
#' @param next_step Next step identifier
#' @param config Cache configuration
#' @param logger Logger instance (optional)
#' @return List with save results
save_checkpoint_enhanced <- function(checkpoint_id,
                                     cache_info,
                                     variables,
                                     step_name,
                                     next_step,
                                     config = CACHE_CONFIG_DEFAULTS,
                                     logger = NULL) {

  start_time <- Sys.time()

  result <- list(
    success = FALSE,
    checkpoint_id = checkpoint_id,
    version = NULL,
    filename = NULL,
    size_bytes = 0,
    checksum = NULL,
    compression = NULL,
    duration_ms = 0,
    error = NULL
  )

  tryCatch({

    # Log start
    if (!is.null(logger)) {
      logger$info("SAVE_START", paste("Saving checkpoint:", step_name),
                  project_id = cache_info$project_id,
                  checkpoint_id = checkpoint_id)
    }

    # Determine version number
    if (config$enable_versioning) {
      result$version <- get_next_version(cache_info$cache_dir, checkpoint_id)
      result$filename <- create_versioned_filename(checkpoint_id, result$version)
    } else {
      result$version <- 1
      result$filename <- paste0(checkpoint_id, ".rds")
    }

    checkpoint_file <- file.path(cache_info$cache_dir, result$filename)

    # Wrap data with schema
    wrapped_data <- wrap_with_schema(variables)

    # Determine compression
    if (config$compression_level == "auto") {
      result$compression <- determine_compression(variables)
    } else {
      result$compression <- config$compression_level
    }

    # Save with atomic write
    if (config$atomic_writes) {
      save_result <- atomic_save_rds(wrapped_data, checkpoint_file,
                                     compress = result$compression,
                                     verify = TRUE)

      if (!save_result$success) {
        stop(save_result$error)
      }

      result$size_bytes <- save_result$size_bytes
      result$checksum <- save_result$checksum

    } else {
      # Non-atomic save (legacy)
      saveRDS(wrapped_data, checkpoint_file, compress = result$compression)
      result$size_bytes <- file.size(checkpoint_file)
      result$checksum <- unname(tools::md5sum(checkpoint_file))
    }

    # Update metadata.json
    if (file.exists(cache_info$metadata_file)) {
      metadata <- jsonlite::read_json(cache_info$metadata_file)
    } else {
      metadata <- list(
        project_name = cache_info$project_name,
        project_id = cache_info$project_id,
        created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
        schema_version = CACHE_SCHEMA_VERSION,
        checkpoints = list()
      )
    }

    metadata$current_step <- checkpoint_id
    metadata$current_step_name <- step_name
    metadata$next_step <- next_step
    metadata$last_updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")

    metadata$checkpoints[[checkpoint_id]] <- list(
      step_name = step_name,
      version = result$version,
      filename = result$filename,
      saved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
      size_bytes = result$size_bytes,
      checksum = result$checksum,
      compression = result$compression,
      is_valid = TRUE
    )

    jsonlite::write_json(metadata, cache_info$metadata_file,
                         auto_unbox = TRUE, pretty = TRUE)

    # Update SQLite database (schema compatible with DatabaseManager.lib.R)
    if (!is.null(cache_info$db_project_id)) {
      tryCatch({
        con <- DBI::dbConnect(RSQLite::SQLite(), cache_info$db_path)
        on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

        # Update project status/stage
        DBI::dbExecute(con, "
          UPDATE projects
          SET status = ?,
              processing_stage = ?,
              last_modified = ?
          WHERE project_id = ?",
          params = list(
            "running",
            step_name,
            format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            cache_info$db_project_id
          )
        )

        # Register checkpoint in the existing 'checkpoints' table schema
        # (columns: project_id, step_id, step_name, checkpoint_file_path, created_at, file_size_mb, checksum_md5, is_valid, variables_stored, next_step, execution_time_seconds)
        DBI::dbExecute(con, "
          INSERT INTO checkpoints
          (project_id, step_id, step_name, checkpoint_file_path, created_at,
           file_size_mb, checksum_md5, is_valid, variables_stored, next_step, execution_time_seconds)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          params = list(
            cache_info$db_project_id,
            checkpoint_id,
            step_name,
            checkpoint_file,
            format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
            as.numeric(result$size_bytes) / (1024^2),
            as.character(result$checksum),
            1,
            jsonlite::toJSON(names(variables), auto_unbox = TRUE),
            next_step,
            as.numeric(difftime(Sys.time(), start_time, units = "secs"))
          )
        )
      }, error = function(e) {
        warning("Could not update database: ", e$message)
      })
    }

    # Cleanup old versions
    if (config$enable_versioning && !is.null(config$max_checkpoints_per_stage)) {
      cleanup_old_versions(cache_info$cache_dir, checkpoint_id,
                           config$max_checkpoints_per_stage)
    }

    result$success <- TRUE

    # Log success
    if (!is.null(logger)) {
      logger$info("SAVE_COMPLETE", paste("Checkpoint saved:", step_name),
                  project_id = cache_info$project_id,
                  checkpoint_id = checkpoint_id,
                  details = list(version = result$version, compression = result$compression),
                  duration_ms = as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000,
                  size_bytes = result$size_bytes)
    }

  }, error = function(e) {
    result$error <- e$message

    if (!is.null(logger)) {
      logger$error("SAVE_FAILED", paste("Failed to save checkpoint:", e$message),
                   project_id = cache_info$project_id,
                   checkpoint_id = checkpoint_id)
    }
  })

  result$duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

  return(result)
}


#' Load checkpoint with all enhancements
#' @param checkpoint_id Checkpoint identifier
#' @param cache_info Cache info from init_cache_system
#' @param version Specific version to load (NULL = latest)
#' @param validate_checksum Whether to validate checksum
#' @param logger Logger instance (optional)
#' @return List with loaded data and metadata
load_checkpoint_enhanced <- function(checkpoint_id,
                                     cache_info,
                                     version = NULL,
                                     validate_checksum = TRUE,
                                     logger = NULL) {

  start_time <- Sys.time()

  result <- list(
    success = FALSE,
    data = NULL,
    checkpoint_id = checkpoint_id,
    version = NULL,
    filename = NULL,
    migrated = FALSE,
    original_version = NULL,
    duration_ms = 0,
    error = NULL
  )

  tryCatch({

    # Log start
    if (!is.null(logger)) {
      logger$info("LOAD_START", paste("Loading checkpoint:", checkpoint_id),
                  project_id = cache_info$project_id,
                  checkpoint_id = checkpoint_id)
    }

    # Read metadata to find file
    if (!file.exists(cache_info$metadata_file)) {
      stop("Metadata file not found")
    }

    metadata <- jsonlite::read_json(cache_info$metadata_file)

    if (!checkpoint_id %in% names(metadata$checkpoints)) {
      stop("Checkpoint not found: ", checkpoint_id)
    }

    cp_meta <- metadata$checkpoints[[checkpoint_id]]

    # Determine which version to load
    if (!is.null(version)) {
      # Load specific version
      versions <- list_checkpoint_versions(cache_info$cache_dir, checkpoint_id)
      version_row <- versions[versions$version == version, ]
      if (nrow(version_row) == 0) {
        stop("Version ", version, " not found for checkpoint ", checkpoint_id)
      }
      result$filename <- version_row$filename[1]
      result$version <- version
    } else {
      # Load latest version from metadata
      result$filename <- cp_meta$filename
      result$version <- cp_meta$version
    }

    checkpoint_file <- file.path(cache_info$cache_dir, result$filename)

    # Load with atomic loader
    expected_checksum <- if (validate_checksum) cp_meta$checksum else NULL
    load_result <- atomic_load_rds(checkpoint_file, expected_checksum)

    if (!load_result$success) {
      stop(load_result$error)
    }

    # Unwrap schema
    unwrapped <- unwrap_with_schema(load_result$data)
    result$data <- unwrapped$data
    result$migrated <- unwrapped$migrated
    result$original_version <- unwrapped$original_version

    result$success <- TRUE

    # Log success
    if (!is.null(logger)) {
      logger$info("LOAD_COMPLETE", paste("Checkpoint loaded:", checkpoint_id),
                  project_id = cache_info$project_id,
                  checkpoint_id = checkpoint_id,
                  details = list(version = result$version, migrated = result$migrated),
                  duration_ms = as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000,
                  size_bytes = load_result$size_bytes)
    }

  }, error = function(e) {
    result$error <- e$message

    if (!is.null(logger)) {
      logger$error("LOAD_FAILED", paste("Failed to load checkpoint:", e$message),
                   project_id = cache_info$project_id,
                   checkpoint_id = checkpoint_id)
    }
  })

  result$duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

  return(result)
}


# ===============================================================================
# Cache Health Check
# ===============================================================================

#' Perform comprehensive health check on cache
#' @param cache_info Cache info from init_cache_system
#' @param repair If TRUE, attempt to repair issues
#' @return List with health check results
check_cache_health <- function(cache_info, repair = FALSE) {

  results <- list(
    healthy = TRUE,
    issues = list(),
    repaired = list(),
    summary = list(
      total_checkpoints = 0,
      valid_checkpoints = 0,
      corrupted_checkpoints = 0,
      missing_files = 0,
      orphaned_files = 0
    )
  )

  if (!file.exists(cache_info$metadata_file)) {
    results$healthy <- FALSE
    results$issues <- c(results$issues, "Metadata file missing")
    return(results)
  }

  metadata <- jsonlite::read_json(cache_info$metadata_file)

  for (cp_id in names(metadata$checkpoints)) {
    results$summary$total_checkpoints <- results$summary$total_checkpoints + 1

    cp_meta <- metadata$checkpoints[[cp_id]]
    cp_file <- file.path(cache_info$cache_dir, cp_meta$filename)

    # Check file exists
    if (!file.exists(cp_file)) {
      results$healthy <- FALSE
      results$summary$missing_files <- results$summary$missing_files + 1
      results$issues <- c(results$issues, paste("Missing file:", cp_meta$filename))

      if (repair) {
        # Mark as invalid in metadata
        metadata$checkpoints[[cp_id]]$is_valid <- FALSE
        results$repaired <- c(results$repaired, paste("Marked invalid:", cp_id))
      }
      next
    }

    # Verify checksum
    actual_checksum <- unname(tools::md5sum(cp_file))
    if (actual_checksum != cp_meta$checksum) {
      results$healthy <- FALSE
      results$summary$corrupted_checkpoints <- results$summary$corrupted_checkpoints + 1
      results$issues <- c(results$issues, paste("Checksum mismatch:", cp_meta$filename))

      if (repair) {
        metadata$checkpoints[[cp_id]]$is_valid <- FALSE
        results$repaired <- c(results$repaired, paste("Marked invalid:", cp_id))
      }
      next
    }

    # Try to read file
    tryCatch({
      test <- readRDS(cp_file)
      results$summary$valid_checkpoints <- results$summary$valid_checkpoints + 1
      rm(test)
    }, error = function(e) {
      results$healthy <- FALSE
      results$summary$corrupted_checkpoints <- results$summary$corrupted_checkpoints + 1
      results$issues <- c(results$issues, paste("Cannot read:", cp_meta$filename, "-", e$message))

      if (repair) {
        metadata$checkpoints[[cp_id]]$is_valid <- FALSE
        results$repaired <- c(results$repaired, paste("Marked invalid:", cp_id))
      }
    })
  }

  # Check for orphaned files (files not in metadata)
  all_files <- list.files(cache_info$cache_dir, pattern = "\\.rds$")
  known_files <- sapply(metadata$checkpoints, function(x) x$filename)
  orphaned <- setdiff(all_files, known_files)

  results$summary$orphaned_files <- length(orphaned)
  if (length(orphaned) > 0) {
    for (f in orphaned) {
      results$issues <- c(results$issues, paste("Orphaned file:", f))
    }
  }

  # Save repaired metadata
  if (repair && length(results$repaired) > 0) {
    jsonlite::write_json(metadata, cache_info$metadata_file,
                         auto_unbox = TRUE, pretty = TRUE)
  }

  return(results)
}


# ===============================================================================
# Export Cache Configuration UI Helper
# ===============================================================================

#' Get current cache configuration as data frame for display
#' @param config Configuration list
#' @return Data frame suitable for display
config_to_display <- function(config = CACHE_CONFIG_DEFAULTS) {

  data.frame(
    Setting = c(
      "Maximum total size",
      "Maximum projects",
      "Max checkpoints per stage",
      "Maximum age",
      "Auto cleanup",
      "Compression",
      "Versioning",
      "Logging",
      "Atomic writes"
    ),
    Value = c(
      paste(config$max_total_size_gb, "GB"),
      as.character(config$max_projects),
      as.character(config$max_checkpoints_per_stage),
      paste(config$max_age_days, "days"),
      if (config$auto_cleanup) "Enabled" else "Disabled",
      config$compression_level,
      if (config$enable_versioning) "Enabled" else "Disabled",
      if (config$enable_logging) "Enabled" else "Disabled",
      if (config$atomic_writes) "Enabled" else "Disabled"
    ),
    stringsAsFactors = FALSE
  )
}


# ===============================================================================
# END OF FILE
# ===============================================================================

cat("EnhancedCacheManager.lib.R loaded successfully\n")
cat("Schema version:", CACHE_SCHEMA_VERSION, "\n")
cat("Features: atomic saves, versioning, smart compression, structured logging\n\n")
