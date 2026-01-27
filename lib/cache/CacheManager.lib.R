# ═══════════════════════════════════════════════════════════════════════
# Cache Manager - MSpandas Persistent Cache System
# ═══════════════════════════════════════════════════════════════════════
#
# Description: Gère la sauvegarde et le chargement des checkpoints
#              pour permettre la reprise après crash
#
# Author: MSpandas Team
# Version: 1.0.0
# Date: 2026-01-23
#
# ═══════════════════════════════════════════════════════════════════════

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(digest)) install.packages("digest")

library(jsonlite)
library(digest)


#' Initialize Cache System
#'
#' Crée la structure de cache pour un projet
#'
#' @param project_name Nom du projet
#' @param data_dir Répertoire des données brutes
#' @param base_cache_dir Répertoire de base pour tous les caches
#' @return Liste avec info cache (project_id, cache_dir, metadata_file)
#' @export
#'
#' @examples
#' cache <- init_cache_system(
#'   project_name = "MyProject_312samples",
#'   data_dir = "C:/data/312_samples"
#' )
init_cache_system <- function(project_name,
                              data_dir,
                              base_cache_dir = "cache_projects") {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🔧 Initializing Cache System\n")
  cat("═══════════════════════════════════════════════════════\n")

  # Créer nom de projet unique avec timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  project_id <- paste0(gsub("[^A-Za-z0-9_]", "_", project_name), "_", timestamp)

  # Structure de répertoires
  project_dir <- file.path(base_cache_dir, project_id)
  cache_dir <- file.path(project_dir, "cache")
  data_link_dir <- file.path(project_dir, "data")

  # Créer répertoires
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(data_link_dir, recursive = TRUE, showWarnings = FALSE)

  # Calculer hash du répertoire de données pour validation
  data_hash <- tryCatch({
    digest::digest(normalizePath(data_dir, mustWork = FALSE), algo = "md5")
  }, error = function(e) {
    "unknown"
  })

  # Initialiser metadata.json
  metadata <- list(
    project_info = list(
      name = project_name,
      project_id = project_id,
      created_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      last_updated = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      user = Sys.info()["user"],
      platform = .Platform$OS.type,
      r_version = paste(R.version$major, R.version$minor, sep = "."),
      mspandas_version = "2.0.0"
    ),
    data_info = list(
      data_directory = normalizePath(data_dir, mustWork = FALSE),
      data_hash = data_hash,
      n_samples = NA_integer_
    ),
    workflow_state = list(
      current_step = "initialized",
      completed_steps = list(),
      next_step = "peak_picking",
      can_resume = FALSE,
      crash_detected = FALSE,
      last_crash_timestamp = NA
    ),
    checkpoints = list(),
    parameters = list()
  )

  # Sauvegarder metadata
  metadata_file <- file.path(cache_dir, "metadata.json")
  write_json(metadata, metadata_file, pretty = TRUE, auto_unbox = TRUE)

  cat(sprintf("✅ Cache system initialized\n"))
  cat(sprintf("   Project ID: %s\n", project_id))
  cat(sprintf("   Cache directory: %s\n", cache_dir))
  cat(sprintf("   Metadata file: %s\n", metadata_file))
  cat("═══════════════════════════════════════════════════════\n\n")

  return(list(
    project_id = project_id,
    project_dir = project_dir,
    cache_dir = cache_dir,
    metadata_file = metadata_file,
    data_dir = data_dir
  ))
}


#' Save Checkpoint
#'
#' Sauvegarde un checkpoint avec les variables spécifiées
#'
#' @param checkpoint_id ID unique du checkpoint (ex: "peak_picking")
#' @param cache_info Info retournée par init_cache_system()
#' @param variables Liste nommée de variables R à sauvegarder
#' @param step_name Nom lisible de l'étape
#' @param next_step ID de l'étape suivante
#' @param step_number Numéro d'étape (auto-incrémenté si NULL)
#' @return TRUE si succès, FALSE sinon
#' @export
#'
#' @examples
#' save_checkpoint(
#'   checkpoint_id = "normalizers_ready",
#'   cache_info = cache,
#'   variables = list(
#'     Matrix_Abundance = my_matrix,
#'     Features_candidates = candidates
#'   ),
#'   step_name = "Ready for Search",
#'   next_step = "search_normalizers"
#' )
save_checkpoint <- function(checkpoint_id,
                           cache_info,
                           variables,
                           step_name,
                           next_step,
                           step_number = NULL) {

  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("💾 Saving checkpoint: %s\n", checkpoint_id))
  cat("═══════════════════════════════════════════════════════\n")

  # Vérifier cache_info
  if (!file.exists(cache_info$metadata_file)) {
    cat("❌ Error: Cache metadata not found. Initialize cache first.\n")
    return(FALSE)
  }

  # Lire metadata actuel
  metadata <- read_json(cache_info$metadata_file)

  # Déterminer numéro d'étape
  if (is.null(step_number)) {
    step_number <- length(metadata$checkpoints) + 1
  }

  # Fichier checkpoint
  checkpoint_file <- file.path(
    cache_info$cache_dir,
    sprintf("checkpoint_%03d_%s.rds", step_number, checkpoint_id)
  )

  # Préparer données checkpoint
  checkpoint_data <- list(
    metadata = list(
      checkpoint_id = checkpoint_id,
      step_number = step_number,
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      step_name = step_name,
      next_step = next_step,
      r_version = R.version.string,
      platform = .Platform$OS.type
    ),
    variables = variables,
    validation = list(
      checksum = NA,  # Calculé après sauvegarde
      n_variables = length(variables),
      variable_names = names(variables),
      variable_classes = sapply(variables, function(x) class(x)[1]),
      variable_sizes_mb = sapply(variables, function(x) {
        round(object.size(x) / 1024 / 1024, 2)
      })
    )
  )

  # Sauvegarder RDS (compression xz pour grandes matrices)
  tryCatch({

    cat(sprintf("   Writing checkpoint file...\n"))

    # Sauvegarder avec compression
    saveRDS(checkpoint_data,
            file = checkpoint_file,
            compress = "xz",
            version = 3)

    # Calculer checksum du fichier
    checksum <- digest::digest(file = checkpoint_file, algo = "md5")
    file_size_mb <- round(file.size(checkpoint_file) / 1024 / 1024, 2)

    cat(sprintf("   Checkpoint file: %s (%.1f MB)\n",
                basename(checkpoint_file), file_size_mb))

    # Mettre à jour metadata.json
    metadata$workflow_state$current_step <- checkpoint_id
    metadata$workflow_state$completed_steps <- c(
      unlist(metadata$workflow_state$completed_steps),
      checkpoint_id
    )
    metadata$workflow_state$next_step <- next_step
    metadata$workflow_state$can_resume <- TRUE
    metadata$project_info$last_updated <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")

    metadata$checkpoints[[checkpoint_id]] <- list(
      file = basename(checkpoint_file),
      step_number = step_number,
      timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
      size_mb = file_size_mb,
      checksum = checksum,
      variables = names(variables),
      variable_classes = sapply(variables, function(x) class(x)[1]),
      status = "valid"
    )

    write_json(metadata, cache_info$metadata_file,
               pretty = TRUE, auto_unbox = TRUE)

    cat("✅ Checkpoint saved successfully!\n")
    cat(sprintf("   Variables saved: %s\n",
                paste(names(variables), collapse = ", ")))
    cat("═══════════════════════════════════════════════════════\n\n")

    return(TRUE)

  }, error = function(e) {
    cat(sprintf("❌ Error saving checkpoint: %s\n", e$message))
    cat("═══════════════════════════════════════════════════════\n\n")
    return(FALSE)
  })
}


#' Load Checkpoint
#'
#' Charge un checkpoint et retourne les variables sauvegardées
#'
#' @param checkpoint_id ID du checkpoint à charger
#' @param cache_info Info du cache
#' @param validate_checksum Vérifier l'intégrité par checksum
#' @return Liste des variables restaurées
#' @export
#'
#' @examples
#' restored <- load_checkpoint("normalizers_ready", cache)
#' Matrix_Abundance <- restored$Matrix_Abundance
load_checkpoint <- function(checkpoint_id,
                           cache_info,
                           validate_checksum = TRUE) {

  cat("═══════════════════════════════════════════════════════\n")
  cat(sprintf("📂 Loading checkpoint: %s\n", checkpoint_id))
  cat("═══════════════════════════════════════════════════════\n")

  # Lire metadata
  if (!file.exists(cache_info$metadata_file)) {
    stop("Cache metadata not found")
  }

  metadata <- read_json(cache_info$metadata_file)

  if (!checkpoint_id %in% names(metadata$checkpoints)) {
    stop(sprintf("Checkpoint '%s' not found in metadata", checkpoint_id))
  }

  checkpoint_info <- metadata$checkpoints[[checkpoint_id]]
  checkpoint_file <- file.path(cache_info$cache_dir, checkpoint_info$file)

  if (!file.exists(checkpoint_file)) {
    stop(sprintf("Checkpoint file not found: %s", checkpoint_file))
  }

  cat(sprintf("   Checkpoint file: %s (%.1f MB)\n",
              checkpoint_info$file, checkpoint_info$size_mb))

  # Vérifier checksum si demandé
  if (validate_checksum) {
    cat("   Validating integrity...\n")
    current_checksum <- digest::digest(file = checkpoint_file, algo = "md5")
    if (current_checksum != checkpoint_info$checksum) {
      warning("⚠️  Checksum mismatch! File may be corrupted.")
      cat("   Expected: ", checkpoint_info$checksum, "\n")
      cat("   Current:  ", current_checksum, "\n")
    } else {
      cat("   ✅ Checksum valid\n")
    }
  }

  # Charger checkpoint
  tryCatch({

    checkpoint_data <- readRDS(checkpoint_file)

    cat("✅ Checkpoint loaded successfully!\n")
    cat(sprintf("   Timestamp: %s\n", checkpoint_data$metadata$timestamp))
    cat(sprintf("   Variables: %s\n",
                paste(names(checkpoint_data$variables), collapse = ", ")))
    cat("═══════════════════════════════════════════════════════\n\n")

    return(checkpoint_data$variables)

  }, error = function(e) {
    stop(sprintf("Error loading checkpoint: %s", e$message))
  })
}


#' Check if Resume Possible
#'
#' Vérifie si on peut reprendre depuis un cache existant
#'
#' @param cache_info Info du cache
#' @return Liste avec can_resume, reason, last_checkpoint, next_step
#' @export
can_resume_from_cache <- function(cache_info) {

  if (!file.exists(cache_info$metadata_file)) {
    return(list(
      can_resume = FALSE,
      reason = "No metadata found",
      last_checkpoint = NULL,
      next_step = NULL
    ))
  }

  metadata <- read_json(cache_info$metadata_file)

  if (!metadata$workflow_state$can_resume) {
    return(list(
      can_resume = FALSE,
      reason = "Workflow not in resumable state",
      last_checkpoint = metadata$workflow_state$current_step,
      next_step = NULL
    ))
  }

  # Vérifier intégrité des checkpoints
  for (ckpt_id in names(metadata$checkpoints)) {
    ckpt_info <- metadata$checkpoints[[ckpt_id]]
    ckpt_file <- file.path(cache_info$cache_dir, ckpt_info$file)

    if (!file.exists(ckpt_file)) {
      return(list(
        can_resume = FALSE,
        reason = sprintf("Missing checkpoint file: %s", ckpt_info$file),
        last_checkpoint = NULL,
        next_step = NULL
      ))
    }

    # Vérifier checksum (quick check)
    if (ckpt_info$status != "valid") {
      return(list(
        can_resume = FALSE,
        reason = sprintf("Invalid checkpoint: %s", ckpt_id),
        last_checkpoint = NULL,
        next_step = NULL
      ))
    }
  }

  return(list(
    can_resume = TRUE,
    reason = "Valid cache found",
    last_checkpoint = metadata$workflow_state$current_step,
    next_step = metadata$workflow_state$next_step,
    completed_steps = unlist(metadata$workflow_state$completed_steps),
    n_checkpoints = length(metadata$checkpoints)
  ))
}


#' List Available Checkpoints
#'
#' Liste tous les checkpoints disponibles dans un cache
#'
#' @param cache_info Info du cache
#' @return Dataframe avec info des checkpoints
#' @export
list_checkpoints <- function(cache_info) {

  if (!file.exists(cache_info$metadata_file)) {
    cat("No cache metadata found\n")
    return(NULL)
  }

  metadata <- read_json(cache_info$metadata_file)

  if (length(metadata$checkpoints) == 0) {
    cat("No checkpoints found in cache\n")
    return(NULL)
  }

  # Créer dataframe
  checkpoints_df <- do.call(rbind, lapply(names(metadata$checkpoints), function(ckpt_id) {
    ckpt <- metadata$checkpoints[[ckpt_id]]
    data.frame(
      checkpoint_id = ckpt_id,
      step_number = ckpt$step_number,
      file = ckpt$file,
      timestamp = ckpt$timestamp,
      size_mb = ckpt$size_mb,
      n_variables = length(ckpt$variables),
      status = ckpt$status,
      stringsAsFactors = FALSE
    )
  }))

  # Trier par step_number
  checkpoints_df <- checkpoints_df[order(checkpoints_df$step_number), ]

  return(checkpoints_df)
}


#' Clean Old Caches
#'
#' Nettoie les anciens caches pour libérer de l'espace disque
#'
#' @param base_cache_dir Répertoire de base des caches
#' @param keep_recent_n Garder les N projets les plus récents
#' @param dry_run Si TRUE, affiche ce qui serait supprimé sans supprimer
#' @return Nombre de caches supprimés
#' @export
clean_old_caches <- function(base_cache_dir = "cache_projects",
                             keep_recent_n = 5,
                             dry_run = FALSE) {

  cat("═══════════════════════════════════════════════════════\n")
  cat("🗑️  Cleaning old caches\n")
  cat("═══════════════════════════════════════════════════════\n")

  if (!dir.exists(base_cache_dir)) {
    cat("No cache directory found\n")
    return(0)
  }

  # Lister tous les projets
  projects <- list.dirs(base_cache_dir, full.names = TRUE, recursive = FALSE)

  if (length(projects) == 0) {
    cat("No cached projects found\n")
    return(0)
  }

  if (length(projects) <= keep_recent_n) {
    cat(sprintf("Only %d project(s), nothing to clean (keeping %d)\n",
                length(projects), keep_recent_n))
    return(0)
  }

  # Trier par date de modification
  projects_info <- data.frame(
    path = projects,
    mtime = file.info(projects)$mtime,
    stringsAsFactors = FALSE
  )
  projects_info <- projects_info[order(projects_info$mtime, decreasing = TRUE), ]

  # Projets à supprimer
  to_delete <- projects_info$path[(keep_recent_n + 1):nrow(projects_info)]

  cat(sprintf("Found %d project(s) to clean (keeping %d most recent)\n",
              length(to_delete), keep_recent_n))

  if (dry_run) {
    cat("\n[DRY RUN] Would delete:\n")
    for (proj_dir in to_delete) {
      size_mb <- sum(file.size(list.files(proj_dir, recursive = TRUE,
                                          full.names = TRUE))) / 1024 / 1024
      cat(sprintf("  - %s (%.1f MB)\n", basename(proj_dir), size_mb))
    }
    cat("\nRun with dry_run=FALSE to actually delete\n")
    return(0)
  }

  deleted <- 0
  for (proj_dir in to_delete) {
    size_mb <- sum(file.size(list.files(proj_dir, recursive = TRUE,
                                        full.names = TRUE))) / 1024 / 1024
    unlink(proj_dir, recursive = TRUE)
    cat(sprintf("✅ Deleted: %s (%.1f MB freed)\n",
                basename(proj_dir), size_mb))
    deleted <- deleted + 1
  }

  cat("═══════════════════════════════════════════════════════\n\n")

  return(deleted)
}


#' Get Cache Info
#'
#' Obtient des informations sur un cache existant
#'
#' @param cache_info Info du cache
#' @return Liste avec statistiques du cache
#' @export
get_cache_info <- function(cache_info) {

  if (!file.exists(cache_info$metadata_file)) {
    return(list(error = "Cache not found"))
  }

  metadata <- read_json(cache_info$metadata_file)

  # Taille totale du cache
  cache_files <- list.files(cache_info$cache_dir, full.names = TRUE,
                           recursive = TRUE)
  total_size_mb <- sum(file.size(cache_files)) / 1024 / 1024

  info <- list(
    project_id = metadata$project_info$project_id,
    project_name = metadata$project_info$name,
    created_at = metadata$project_info$created_at,
    last_updated = metadata$project_info$last_updated,
    data_directory = metadata$data_info$data_directory,
    current_step = metadata$workflow_state$current_step,
    next_step = metadata$workflow_state$next_step,
    can_resume = metadata$workflow_state$can_resume,
    n_checkpoints = length(metadata$checkpoints),
    total_size_mb = round(total_size_mb, 2),
    cache_directory = cache_info$cache_dir
  )

  return(info)
}


# Message de chargement
cat("✅ CacheManager.lib.R loaded successfully\n")
cat("   Functions available:\n")
cat("   - init_cache_system()\n")
cat("   - save_checkpoint()\n")
cat("   - load_checkpoint()\n")
cat("   - can_resume_from_cache()\n")
cat("   - list_checkpoints()\n")
cat("   - clean_old_caches()\n")
cat("   - get_cache_info()\n\n")
