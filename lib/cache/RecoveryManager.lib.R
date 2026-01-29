# ═══════════════════════════════════════════════════════════════════════
# Recovery Manager - MSpandas Crash Recovery System
# ═══════════════════════════════════════════════════════════════════════
#
# Description: Gère la détection de crash et la restauration automatique
#              de l'état de l'application depuis les checkpoints
#
# Author: MSpandas Team
# Version: 1.0.0
# Date: 2026-01-23
#
# ═══════════════════════════════════════════════════════════════════════

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
library(jsonlite)

# Source CacheManager if not already loaded
if (!exists("init_cache_system")) {
  source("lib/cache/CacheManager.lib.R")
}

# Load DatabaseManager for SQLite integration
DB_INTEGRATION_ENABLED <- file.exists("lib/cache/DatabaseManager.lib.R")
if (DB_INTEGRATION_ENABLED && !exists("detect_crash_from_db")) {
  source("lib/cache/DatabaseManager.lib.R")
}


#' Detect Crash and Recovery Mode
#'
#' Détecte si une session précédente existe et si on peut reprendre
#'
#' @param cache_info Info du cache (peut être NULL pour détection depuis projet name)
#' @param project_name Project name (si cache_info est NULL)
#' @param verbose Afficher messages détaillés
#' @return Liste avec mode ("fresh" ou "resume") et informations
#' @export
detect_crash_and_recover <- function(cache_info = NULL, project_name = NULL, verbose = TRUE) {

  if (verbose) {
    cat("═══════════════════════════════════════════════════════\n")
    cat("🔍 Checking for previous session\n")
    cat("═══════════════════════════════════════════════════════\n")
  }

  # Try SQLite database detection first (more reliable)
  if (DB_INTEGRATION_ENABLED && !is.null(project_name)) {
    tryCatch({
      db_crash_info <- detect_crash_from_db(
        project_name = project_name,
        db_path = "cache_projects/mspandas.sqlite"
      )

      if (db_crash_info$project_exists && db_crash_info$crashed && db_crash_info$can_resume) {
        last_cp <- db_crash_info$last_checkpoint

        if (verbose) {
          cat("🎯 Crash detected in database!\n")
          cat(sprintf("   Project: %s (ID: %d)\n", project_name, db_crash_info$project_id))
          cat(sprintf("   Status: %s\n", db_crash_info$status))
          cat(sprintf("   Last checkpoint: %s\n", last_cp$step_name))
          cat(sprintf("   Next step: %s\n", last_cp$next_step))
          cat(sprintf("   Total checkpoints: %d\n", db_crash_info$checkpoint_count))
          cat("═══════════════════════════════════════════════════════\n\n")
        }

        return(list(
          mode = "resume",
          should_prompt = TRUE,
          can_resume = TRUE,
          crashed = TRUE,
          last_checkpoint = last_cp$step_id,
          checkpoint_name = last_cp$step_name,
          next_step = last_cp$next_step,
          saved_time = last_cp$created_at,
          n_checkpoints = db_crash_info$checkpoint_count,
          checkpoint_file_path = last_cp$checkpoint_file_path,
          project_id = db_crash_info$project_id,
          db_detection = TRUE
        ))
      }

      if (verbose && db_crash_info$project_exists) {
        cat(sprintf("ℹ️  Project exists in database (status: %s)\n", db_crash_info$status))
      }
    }, error = function(e) {
      if (verbose) {
        cat(sprintf("⚠️  Database detection failed: %s\n", e$message))
        cat("   Falling back to JSON metadata detection\n")
      }
    })
  }

  # Fall back to JSON metadata detection
  if (!is.null(cache_info)) {
    resume_info <- can_resume_from_cache(cache_info)

    if (!resume_info$can_resume) {
      if (verbose) {
        cat(sprintf("ℹ️  Starting fresh workflow\n"))
        cat(sprintf("   Reason: %s\n", resume_info$reason))
        cat("═══════════════════════════════════════════════════════\n\n")
      }

      return(list(
        mode = "fresh",
        should_prompt = FALSE,
        can_resume = FALSE,
        reason = resume_info$reason,
        db_detection = FALSE
      ))
    }

    if (verbose) {
      cat("🎯 Previous session detected in JSON metadata!\n")
      cat(sprintf("   Last completed: %s\n", resume_info$last_checkpoint))
      cat(sprintf("   Next step: %s\n", resume_info$next_step))
      cat(sprintf("   Total checkpoints: %d\n", resume_info$n_checkpoints))
      cat("═══════════════════════════════════════════════════════\n\n")
    }

    return(list(
      mode = "resume",
      should_prompt = TRUE,
      can_resume = TRUE,
      last_checkpoint = resume_info$last_checkpoint,
      next_step = resume_info$next_step,
      completed_steps = resume_info$completed_steps,
      n_checkpoints = resume_info$n_checkpoints,
      db_detection = FALSE
    ))
  }

  # No detection possible
  if (verbose) {
    cat("ℹ️  No previous session detected\n")
    cat("═══════════════════════════════════════════════════════\n\n")
  }

  return(list(
    mode = "fresh",
    should_prompt = FALSE,
    can_resume = FALSE,
    reason = "No cache_info or project_name provided"
  ))
}


#' Restore Application State from Cache
#'
#' Restaure l'état de l'application depuis un checkpoint
#'
#' @param cache_info Info du cache
#' @param target_step Étape cible à restaurer (par défaut: dernière disponible)
#' @param restore_to_env Environnement où restaurer les variables (défaut: parent)
#' @param progress_callback Fonction callback pour afficher la progression
#' @return Liste des variables restaurées
#' @export
#'
#' @examples
#' restored <- restore_application_state(
#'   cache_info = cache,
#'   target_step = "normalizers_ready"
#' )
restore_application_state <- function(cache_info,
                                     target_step = NULL,
                                     restore_to_env = parent.frame(),
                                     progress_callback = NULL) {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔄 Restoring application state\n")
  cat("═══════════════════════════════════════════════════════\n")

  # Lire metadata
  metadata <- read_json(cache_info$metadata_file)

  # Si target_step non spécifié, utiliser current_step
  if (is.null(target_step)) {
    target_step <- metadata$workflow_state$current_step
  }

  cat(sprintf("Target step: %s\n", target_step))

  # Vérifier que target_step existe
  if (!target_step %in% names(metadata$checkpoints)) {
    stop(sprintf("Checkpoint '%s' not found", target_step))
  }

  # Charger le checkpoint cible
  cat(sprintf("\nLoading checkpoint: %s\n", target_step))

  if (!is.null(progress_callback)) {
    progress_callback(0.1, detail = sprintf("Loading %s", target_step))
  }

  variables <- load_checkpoint(target_step, cache_info, validate_checksum = TRUE)

  if (!is.null(progress_callback)) {
    progress_callback(0.5, detail = "Checkpoint loaded")
  }

  # Restaurer les variables dans l'environnement cible
  cat("\nRestoring variables to environment...\n")

  n_restored <- 0
  for (var_name in names(variables)) {
    tryCatch({
      assign(var_name, variables[[var_name]], envir = restore_to_env)
      cat(sprintf("  ✅ %s (%s)\n", var_name, class(variables[[var_name]])[1]))
      n_restored <- n_restored + 1
    }, error = function(e) {
      cat(sprintf("  ⚠️  %s (error: %s)\n", var_name, e$message))
    })
  }

  if (!is.null(progress_callback)) {
    progress_callback(1, detail = "Complete")
  }

  cat(sprintf("\n✅ Application state restored (%d/%d variables)\n",
              n_restored, length(variables)))
  cat("═══════════════════════════════════════════════════════\n\n")

  return(variables)
}


#' Restore to Shiny Reactive Values
#'
#' Restaure les variables dans des reactiveValues Shiny
#'
#' @param cache_info Info du cache
#' @param target_step Étape cible
#' @param reactive_list Liste nommée de reactiveValues Shiny
#' @param progress_callback Fonction callback pour progression
#' @return Liste des variables restaurées
#' @export
#'
#' @examples
#' # Dans un contexte Shiny
#' restore_to_shiny_reactive(
#'   cache_info = cache,
#'   target_step = "normalizers_ready",
#'   reactive_list = list(
#'     RvarsGrouping = allReactiveVarsNewRefMap$Grouping,
#'     RvarsInternal = allReactiveVarsNewRefMap$InternalStandard
#'   )
#' )
restore_to_shiny_reactive <- function(cache_info,
                                     target_step,
                                     reactive_list,
                                     progress_callback = NULL) {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔄 Restoring to Shiny reactive values\n")
  cat("═══════════════════════════════════════════════════════\n")

  # Charger checkpoint
  if (!is.null(progress_callback)) {
    progress_callback(0.2, detail = "Loading checkpoint")
  }

  variables <- load_checkpoint(target_step, cache_info)

  if (!is.null(progress_callback)) {
    progress_callback(0.5, detail = "Checkpoint loaded")
  }

  # Restaurer dans reactiveValues
  cat("\nRestoring to reactive values...\n")

  n_restored <- 0

  for (var_name in names(variables)) {
    # Déterminer dans quel reactiveValues restaurer
    # Format attendu: "RvarsName$variable"
    if (grepl("\\$", var_name)) {
      parts <- strsplit(var_name, "\\$", fixed = TRUE)[[1]]
      reactive_name <- parts[1]
      sub_var_name <- parts[2]

      if (reactive_name %in% names(reactive_list)) {
        tryCatch({
          reactive_list[[reactive_name]][[sub_var_name]] <- variables[[var_name]]
          cat(sprintf("  ✅ %s$%s\n", reactive_name, sub_var_name))
          n_restored <- n_restored + 1
        }, error = function(e) {
          cat(sprintf("  ⚠️  %s (error: %s)\n", var_name, e$message))
        })
      } else {
        cat(sprintf("  ⚠️  ReactiveValues '%s' not found, skipping\n", reactive_name))
      }
    } else {
      # Variable simple - essayer de restaurer dans le premier reactive
      if (length(reactive_list) > 0) {
        first_reactive <- reactive_list[[1]]
        tryCatch({
          first_reactive[[var_name]] <- variables[[var_name]]
          cat(sprintf("  ✅ %s (in first reactive)\n", var_name))
          n_restored <- n_restored + 1
        }, error = function(e) {
          cat(sprintf("  ⚠️  %s (error: %s)\n", var_name, e$message))
        })
      }
    }
  }

  if (!is.null(progress_callback)) {
    progress_callback(1, detail = "Complete")
  }

  cat(sprintf("\n✅ Restored %d/%d variables\n", n_restored, length(variables)))
  cat("═══════════════════════════════════════════════════════\n\n")

  return(variables)
}


#' Mark Checkpoint as Crash Point
#'
#' Marque dans les métadonnées qu'un crash a été détecté
#'
#' @param cache_info Info du cache
#' @param error_message Message d'erreur optionnel
#' @export
mark_crash_detected <- function(cache_info, error_message = NULL) {

  if (!file.exists(cache_info$metadata_file)) {
    warning("Cache metadata not found, cannot mark crash")
    return(FALSE)
  }

  metadata <- read_json(cache_info$metadata_file)

  metadata$workflow_state$crash_detected <- TRUE
  metadata$workflow_state$last_crash_timestamp <- format(Sys.time(),
                                                         "%Y-%m-%dT%H:%M:%SZ")

  if (!is.null(error_message)) {
    metadata$workflow_state$last_crash_message <- error_message
  }

  write_json(metadata, cache_info$metadata_file,
             pretty = TRUE, auto_unbox = TRUE)

  cat(sprintf("⚠️  Crash marked in cache metadata\n"))

  return(TRUE)
}


#' Clear Crash Flag
#'
#' Efface le flag de crash après reprise réussie
#'
#' @param cache_info Info du cache
#' @export
clear_crash_flag <- function(cache_info) {

  if (!file.exists(cache_info$metadata_file)) {
    return(FALSE)
  }

  metadata <- read_json(cache_info$metadata_file)

  metadata$workflow_state$crash_detected <- FALSE

  write_json(metadata, cache_info$metadata_file,
             pretty = TRUE, auto_unbox = TRUE)

  return(TRUE)
}


#' Validate Checkpoint Integrity
#'
#' Valide l'intégrité d'un checkpoint
#'
#' @param checkpoint_id ID du checkpoint
#' @param cache_info Info du cache
#' @return Liste avec valid (TRUE/FALSE) et reason
#' @export
validate_checkpoint_integrity <- function(checkpoint_id, cache_info) {

  metadata <- read_json(cache_info$metadata_file)

  if (!checkpoint_id %in% names(metadata$checkpoints)) {
    return(list(valid = FALSE, reason = "Checkpoint not in metadata"))
  }

  ckpt_info <- metadata$checkpoints[[checkpoint_id]]
  ckpt_file <- file.path(cache_info$cache_dir, ckpt_info$file)

  # Vérifier existence
  if (!file.exists(ckpt_file)) {
    return(list(valid = FALSE, reason = "File not found"))
  }

  # Vérifier checksum
  current_checksum <- digest::digest(file = ckpt_file, algo = "md5")

  if (current_checksum != ckpt_info$checksum) {
    return(list(
      valid = FALSE,
      reason = "Checksum mismatch",
      expected = ckpt_info$checksum,
      current = current_checksum
    ))
  }

  # Essayer de charger
  tryCatch({
    data <- readRDS(ckpt_file)

    # Vérifier structure
    required_fields <- c("metadata", "variables", "validation")
    missing <- setdiff(required_fields, names(data))

    if (length(missing) > 0) {
      return(list(
        valid = FALSE,
        reason = paste("Missing fields:", paste(missing, collapse = ", "))
      ))
    }

    return(list(valid = TRUE, reason = "OK"))

  }, error = function(e) {
    return(list(
      valid = FALSE,
      reason = paste("Load error:", e$message)
    ))
  })
}


#' Auto-Repair Corrupted Cache
#'
#' Tente de réparer un cache corrompu en trouvant le dernier checkpoint valide
#'
#' @param cache_info Info du cache
#' @return Liste avec success, repaired_to_step
#' @export
auto_repair_cache <- function(cache_info) {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔧 Auto-repairing cache\n")
  cat("═══════════════════════════════════════════════════════\n")

  metadata <- read_json(cache_info$metadata_file)

  cat("Checking cache integrity...\n\n")

  corrupted <- c()
  valid <- c()

  for (ckpt_id in names(metadata$checkpoints)) {
    cat(sprintf("Checking %s... ", ckpt_id))

    validation <- validate_checkpoint_integrity(ckpt_id, cache_info)

    if (!validation$valid) {
      cat(sprintf("❌ CORRUPTED (%s)\n", validation$reason))
      corrupted <- c(corrupted, ckpt_id)

      # Marquer comme invalide
      metadata$checkpoints[[ckpt_id]]$status <- "invalid"
    } else {
      cat("✅ OK\n")
      valid <- c(valid, ckpt_id)
    }
  }

  cat("\n")

  if (length(corrupted) > 0) {
    cat(sprintf("Found %d corrupted checkpoint(s)\n", length(corrupted)))

    # Trouver le dernier checkpoint valide
    if (length(valid) > 0) {
      # Trier par step_number
      valid_info <- lapply(valid, function(id) {
        list(id = id, step_number = metadata$checkpoints[[id]]$step_number)
      })
      valid_info <- valid_info[order(sapply(valid_info, function(x) x$step_number),
                                    decreasing = TRUE)]

      last_valid <- valid_info[[1]]$id

      metadata$workflow_state$current_step <- last_valid
      metadata$workflow_state$next_step <- metadata$checkpoints[[last_valid]]$next_step
      metadata$workflow_state$can_resume <- TRUE

      cat(sprintf("✅ Can resume from: %s\n", last_valid))

      # Sauvegarder metadata mis à jour
      write_json(metadata, cache_info$metadata_file,
                 pretty = TRUE, auto_unbox = TRUE)

      cat("═══════════════════════════════════════════════════════\n\n")

      return(list(
        success = TRUE,
        repaired = TRUE,
        repaired_to_step = last_valid,
        corrupted_steps = corrupted
      ))

    } else {
      metadata$workflow_state$can_resume <- FALSE

      cat("❌ No valid checkpoints found, must start fresh\n")

      write_json(metadata, cache_info$metadata_file,
                 pretty = TRUE, auto_unbox = TRUE)

      cat("═══════════════════════════════════════════════════════\n\n")

      return(list(
        success = FALSE,
        repaired = FALSE,
        reason = "No valid checkpoints"
      ))
    }

  } else {
    cat("✅ All checkpoints valid, no repair needed\n")
    cat("═══════════════════════════════════════════════════════\n\n")

    return(list(
      success = TRUE,
      repaired = FALSE,
      reason = "No corruption detected"
    ))
  }
}


#' Find Available Caches for Project
#'
#' Trouve tous les caches existants pour un projet
#'
#' @param project_name Nom du projet
#' @param base_cache_dir Répertoire de base des caches
#' @return Dataframe avec info des caches trouvés
#' @export
find_available_caches <- function(project_name,
                                 base_cache_dir = "cache_projects") {

  if (!dir.exists(base_cache_dir)) {
    cat("No cache directory found\n")
    return(NULL)
  }

  # Lister tous les répertoires
  all_dirs <- list.dirs(base_cache_dir, full.names = TRUE, recursive = FALSE)

  # Filtrer par nom de projet (début du nom de répertoire)
  project_pattern <- gsub("[^A-Za-z0-9_]", "_", project_name)
  matching_dirs <- all_dirs[grepl(paste0("^", project_pattern), basename(all_dirs))]

  if (length(matching_dirs) == 0) {
    cat(sprintf("No caches found for project: %s\n", project_name))
    return(NULL)
  }

  # Extraire info de chaque cache
  caches_info <- lapply(matching_dirs, function(dir) {
    metadata_file <- file.path(dir, "cache", "metadata.json")

    if (!file.exists(metadata_file)) {
      return(NULL)
    }

    metadata <- tryCatch({
      read_json(metadata_file)
    }, error = function(e) {
      return(NULL)
    })

    if (is.null(metadata)) {
      return(NULL)
    }

    # Taille totale
    cache_dir <- file.path(dir, "cache")
    if (dir.exists(cache_dir)) {
      cache_files <- list.files(cache_dir, full.names = TRUE, recursive = TRUE)
      total_size_mb <- sum(file.size(cache_files)) / 1024 / 1024
    } else {
      total_size_mb <- 0
    }

    data.frame(
      project_id = metadata$project_info$project_id,
      created_at = metadata$project_info$created_at,
      last_updated = metadata$project_info$last_updated,
      current_step = metadata$workflow_state$current_step,
      can_resume = metadata$workflow_state$can_resume,
      n_checkpoints = length(metadata$checkpoints),
      size_mb = round(total_size_mb, 2),
      cache_dir = dir,
      stringsAsFactors = FALSE
    )
  })

  # Combiner et filtrer NULL
  caches_info <- caches_info[!sapply(caches_info, is.null)]

  if (length(caches_info) == 0) {
    return(NULL)
  }

  result <- do.call(rbind, caches_info)

  # Trier par date (plus récent en premier)
  result <- result[order(result$last_updated, decreasing = TRUE), ]

  return(result)
}


# Message de chargement
cat("✅ RecoveryManager.lib.R loaded successfully\n")
cat("   Functions available:\n")
cat("   - detect_crash_and_recover()\n")
cat("   - restore_application_state()\n")
cat("   - restore_to_shiny_reactive()\n")
cat("   - mark_crash_detected()\n")
cat("   - clear_crash_flag()\n")
cat("   - validate_checkpoint_integrity()\n")
cat("   - auto_repair_cache()\n")
cat("   - find_available_caches()\n\n")
