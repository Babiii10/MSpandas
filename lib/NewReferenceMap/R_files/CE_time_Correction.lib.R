library(BiocParallel)


# Only register if not already done (prevents socket connection leak)
# This file is sourced multiple times (in renderPlot), causing cluster duplication
# if (!exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
# #   # Use register() without bpstart() to avoid immediate cluster creation
# #   # Cluster will be created on-demand by bplapply() when needed
#    register(SnowParam(workers = 1, type = "SOCK"), default = FALSE)
#    assign(".biocparallel_registered_ce_time", TRUE, envir = .GlobalEnv)
# }
# Use a serial backend in the main process. The heavy obiwarp work runs in
# isolated callr sub-processes (see alignement_Obiwrap), so no SOCK cluster is
# needed here — this also avoids leaking sockets when this file is re-sourced.
BiocParallel::register(BiocParallel::SerialParam())
# Define functions utils




"%ni%"<-Negate("%in%")

#~~~~~~~~~~~~~~~~ Correction time ~~~~~~~~~~~~~~~~~~~~~~~~~~#
# alignement_Obiwrap<-function(xdata, 
#                              binSize = 1,
#                              distFun = "cor_opt",
#                              subset = integer(),
#                              subsetAdjust = c("average", "previous"),
#                              centerSample = integer(),
#                              localAlignment = FALSE,
#                              response = 1L,
#                              factorDiag = 2,
#                              factorGap = 1,
#                              initPenalty = 0,
#                              msLevel = 1L
# ){
#   
#   
#   parObiwrap<- ObiwarpParam(binSize = binSize,
#                             centerSample = centerSample,
#                             response = response,
#                             distFun = distFun,
#                             gapInit = numeric(),
#                             gapExtend = numeric(),
#                             factorDiag = factorDiag,
#                             factorGap = factorGap,
#                             localAlignment = localAlignment,
#                             initPenalty = initPenalty,
#                             subset = subset,
#                             subsetAdjust = subsetAdjust
#   )
# 
#  data_align<-adjustRtime(xdata, param = parObiwrap, msLevel = msLevel)
#   # Force SerialParam to avoid SOCK port exhaustion on Windows
#   # with large sample counts (>1000). XCMS adjustRtime uses bplapply
#   # internally; without this, SnowParam workers consume all ephemeral
#   # TCP ports and crash with "cannot open the connection".
#   # old_param <- bpparam()
#   # register(SerialParam(), default = TRUE)
#   # on.exit(register(old_param, default = TRUE), add = TRUE)
# 
#   # data_align <- adjustRtime(xdata, param = parObiwrap, msLevel = msLevel)
# 
#   return(data_align)
# }


# Worker obiwarp pour UN lot (centre + chunk), exécuté dans un sous-process callr
# propre. DÉFINI AU NIVEAU TOP-LEVEL À DESSEIN : callr::r() sérialise la fonction
# AVEC son environnement englobant. Si le worker est défini à l'intérieur de
# alignement_Obiwrap(), cet environnement contient le xdata complet (tous les
# fichiers) et result_cp, qui sont alors re-sérialisés sur disque puis rechargés
# À CHAQUE appel callr — la RSS du process parent grimpe lot après lot jusqu'à ce
# que l'OS ne puisse plus démarrer de sous-process ("could not start R ...").
# Au niveau top-level, l'environnement est le global env (sérialisé par
# référence), donc seuls les `args` (le sous-objet du lot) sont transmis.
.obiwarp_batch_worker <- function(xdata_batch, binSize, distFun,
                                  subset_in_batch, subsetAdjust, center_in_batch,
                                  localAlignment, response, factorDiag, factorGap,
                                  initPenalty, msLevel) {
  library(xcms)
  # Force a serial backend so adjustRtime() does not spawn SOCK clusters.
  BiocParallel::register(BiocParallel::SerialParam())
  param <- xcms::ObiwarpParam(
    binSize = binSize, centerSample = center_in_batch, distFun = distFun,
    gapInit = numeric(), gapExtend = numeric(), subset = subset_in_batch,
    subsetAdjust = subsetAdjust, localAlignment = localAlignment,
    response = response, factorDiag = factorDiag, factorGap = factorGap,
    initPenalty = initPenalty)
  xcms::chromPeaks(
    xcms::adjustRtime(xdata_batch, param = param, msLevel = msLevel))
}


#~~~~~~~~~~~~~~~~ Correction time ~~~~~~~~~~~~~~~~~~~~~~~~~~#
alignement_Obiwrap <- function(xdata,
                               binSize       = 1,
                               distFun       = "cor_opt",
                               subset        = integer(),
                               subsetAdjust  = c("average", "previous"),
                               centerSample  = integer(),
                               localAlignment = FALSE,
                               response      = 1L,
                               factorDiag    = 2,
                               factorGap     = 1,
                               initPenalty   = 0,
                               msLevel       = 1L,
                               batch_size    = 25L,
                               timeout_sec   = 7200L) {

  n_files    <- length(MSnbase::fileNames(xdata))
  batch_size <- suppressWarnings(as.integer(batch_size))

  # Batching is only mathematically equivalent when every sample is aligned
  # against the center (subset = all). For a partial subset, subsetAdjust
  # interpolates the non-subset samples from their neighbours across the *whole*
  # set, which per-batch alignment cannot reproduce — so we fall back to a
  # single direct adjustRtime() run in that case.
  subset_all <- length(subset) == 0L || length(unique(subset)) >= n_files
  use_batch  <- !is.na(batch_size) && batch_size > 0L &&
                n_files > batch_size && subset_all

  # ── Direct (non-batched) path ──────────────────────────────────────────────
  if (!use_batch) {
    if (!subset_all && !is.na(batch_size) && batch_size > 0L && n_files > batch_size)
      message("Obiwarp : subset partiel detecte — batching desactive, ",
              "execution directe (peut etre lourde sur de nombreux fichiers).")
    parObiwrap <- ObiwarpParam(binSize        = binSize,
                               centerSample   = centerSample,
                               response       = response,
                               distFun        = distFun,
                               gapInit        = numeric(),
                               gapExtend      = numeric(),
                               factorDiag     = factorDiag,
                               factorGap      = factorGap,
                               localAlignment = localAlignment,
                               initPenalty    = initPenalty,
                               subset         = subset,
                               subsetAdjust   = subsetAdjust)
    return(adjustRtime(xdata, param = parObiwrap, msLevel = msLevel))
  }

  # ── Batched path via callr sub-processes ────────────────────────────────────
  # obiwarp aligns every sample independently against the (fixed) center, so the
  # files can be processed in independent batches. Each batch runs in its own
  # callr subprocess that caps and fully releases memory between batches —
  # mathematically equivalent to a single adjustRtime() run.
  #
  # obiwarp's profile-matrix memory grows with the number of files in a batch.
  # If a subprocess runs out of memory ("could not start R / killed"), the batch
  # is split in two and retried recursively, down to a single file (center + 1
  # always fits). The center is aligned against itself (identity warp) so its
  # peaks never change and are never patched.
  if (!requireNamespace("callr", quietly = TRUE))
    stop("Package 'callr' is required for batched obiwarp (install.packages('callr')).")

  center_idx <- as.integer(centerSample)
  non_center <- setdiff(seq_len(n_files), center_idx)

  message(sprintf(
    "--- Obiwarp batché : %d fichier(s), lots de %d max (centre = fichier %d) ---",
    n_files, batch_size, center_idx))

  # Snapshot of the original peaks; only rt/rtmin/rtmax of non-center files get
  # patched, preserving the row ordering the server relies on downstream.
  result_cp <- xcms::chromPeaks(xdata)

  # Run obiwarp for (center + chunk) in an isolated subprocess. Returns the
  # adjusted chromPeaks matrix (sample column remapped to global file indices),
  # or the error condition (tagged) if the subprocess failed.
  run_obiwarp_chunk <- function(chunk) {
    batch_file_idx  <- c(center_idx, chunk)
    xdata_batch     <- xcms::filterFile(xdata, file = batch_file_idx)
    # filterFile() sorts files by original index; recover the true global index
    # of each batch position from the file names.
    batch_global    <- match(MSnbase::fileNames(xdata_batch),
                             MSnbase::fileNames(xdata))
    center_in_batch <- which(batch_global == center_idx)
    subset_in_batch <- seq_along(batch_global)

    # filterFile subsets the OnDisk XCMSnExp to the batch files and re-numbers
    # the sample column in chromPeaks to 1..n_batch_files.
    xdata_batch <- xcms::filterFile(xdata, file = batch_file_idx)

    # Write the batch object to a temp RDS file and pass only the path string
    # to callr.  Passing xdata_batch directly as a callr arg causes a crash
    # because S4/data.table objects can embed C-level external pointers
    # (UserDefinedDatabase) that are valid only in the parent process; the
    # subprocess receives a deserialised copy with invalid addresses → R fails
    # to start with "R_ExternalPtrAddr: argument of type VECSXP is not an
    # external pointer".  Reading from disk in the subprocess avoids this.
    tmp_rds <- tempfile(fileext = "_obiwarp_batch.rds")
    saveRDS(xdata_batch, file = tmp_rds, compress = FALSE)  # no compression for speed

    cp_adjusted <- tryCatch(
      callr::r(
        function(rds_path, binSize, distFun, subset_in_batch, subsetAdjust,
                 center_in_batch, localAlignment, response, factorDiag, factorGap,
                 initPenalty, msLevel) {
          library(xcms)
          library(MSnbase)
          xdata_batch <- readRDS(rds_path)
          param <- xcms::ObiwarpParam(
            binSize        = binSize,
            centerSample   = center_in_batch,
            distFun        = distFun,
            gapInit        = numeric(),
            gapExtend      = numeric(),
            subset         = subset_in_batch,
            subsetAdjust   = subsetAdjust,
            localAlignment = localAlignment,
            response       = response,
            factorDiag     = factorDiag,
            factorGap      = factorGap,
            initPenalty    = initPenalty
          )
          aligned <- xcms::adjustRtime(xdata_batch, param = param, msLevel = msLevel)
          xcms::chromPeaks(aligned)
        },
        args = list(
          rds_path        = tmp_rds,
          binSize         = binSize,
          distFun         = distFun,
          subset_in_batch = subset_in_batch,
          subsetAdjust    = subsetAdjust,
          center_in_batch = center_in_batch,
          localAlignment  = localAlignment,
          response        = response,
          factorDiag      = factorDiag,
          factorGap       = factorGap,
          initPenalty     = initPenalty,
          msLevel         = msLevel
        ),
        timeout      = as.double(timeout_sec),
        user_profile = FALSE   # never load .Rprofile in the subprocess
      ),
      error = function(e) {
        warning(sprintf(
          "Obiwarp lot %d/%d : sous-process échoué (%s) — pics non corrigés pour ce lot",
          b, n_batches, conditionMessage(e)))
        xcms::chromPeaks(xdata_batch)   # fallback: unadjusted peaks for this batch
      },
      finally = {
        unlink(tmp_rds)   # always remove temp file, even on error
      }
    )
    rm(xdata_batch)
    gc()

    if (inherits(cp, "error")) return(cp)
    cp[, "sample"] <- batch_global[cp[, "sample"]]   # batch -> global indices
    cp
  }

  # Patch result_cp (enclosing env) with adjusted rt/rtmin/rtmax for the files.
  patch_files <- function(cp, files) {
    for (f in files) {
      batch_rows  <- which(cp[, "sample"]        == f)
      result_rows <- which(result_cp[, "sample"] == f)
      if (length(batch_rows) == length(result_rows) && length(result_rows) > 0L) {
        result_cp[result_rows, c("rt", "rtmin", "rtmax")] <<-
          cp[batch_rows, c("rt", "rtmin", "rtmax")]
      } else if (length(batch_rows) != length(result_rows)) {
        warning(sprintf(
          "Obiwarp : pics discordants pour fichier %d (%d vs %d) — ignoré",
          f, length(batch_rows), length(result_rows)))
      }
    }
  }

  # Process a chunk; on subprocess failure, split in two and retry down to 1.
  process_chunk <- function(chunk) {
    if (!length(chunk)) return(invisible())
    message(sprintf("--- Obiwarp : %d fichier(s) [%d..%d] ---",
                    length(chunk), chunk[1L], chunk[length(chunk)]))
    cp <- run_obiwarp_chunk(chunk)
    if (inherits(cp, "error")) {
      if (length(chunk) > 1L) {
        mid <- ceiling(length(chunk) / 2L)
        message(sprintf("  -> echec (%s) — decoupe en %d + %d et reessai",
                        conditionMessage(cp), mid, length(chunk) - mid))
        gc()
        process_chunk(chunk[seq_len(mid)])
        process_chunk(chunk[(mid + 1L):length(chunk)])
      } else {
        warning(sprintf("Obiwarp : fichier %d non corrige (echec persistant : %s)",
                        chunk, conditionMessage(cp)))
      }
      return(invisible())
    }
    patch_files(cp, chunk)
    rm(cp); gc()
  }

  batches <- split(non_center, ceiling(seq_along(non_center) / batch_size))
  for (b in seq_along(batches)) {
    message(sprintf("=== Lot %d/%d ===", b, length(batches)))
    process_chunk(batches[[b]])
  }

  xcms::chromPeaks(xdata) <- result_cp
  xdata
}



###~~~~~~~~~~~~~~~~~~~~~~ Match mz or M+H ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
matchMz <- function(x,
                    table,
                    nomatch = NA_integer_,
                    ppm_tolereance = 50,
                    mzcol = "mz",
                    rtcol = "rt",
                    session
                     ){
  
  if(!require(MsCoreUtils))
    stop("R package \"MsCoreUtils\" is not found, please install R package \"MsCoreUtils\" ")
  
  
  if (!is.numeric(nomatch) || length(nomatch) != 1L){
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("'nomatch' has to be a 'numeric' of length one."),
      type = "warning"
    )
  }
  
  if (length(dim(x)) != 2 || length(dim(table)) != 2){
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("'x' and 'table' have to be two data frames"),
      type = "warning"
    )
  }
  if (!all(c(mzcol, rtcol) %in% colnames(x)) ||
      !all(c(mzcol, rtcol) %in% colnames(table))){

    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("Required columns : '", 
                   mzcol,"', '",
                   rtcol,
                   "' not found at the same time in reference file and file to align."),
      type = "warning"
    )
    
    return(NULL)
  } else{
    
    if(nrow(x)<2) {
      
      sendSweetAlert(
        session = session,
        title = "Warning !",
        text = paste("'x' must have two or more rows!."),
        type = "warning"
      )
    } else {
      
      table<- table[order(table[,mzcol]), ]
      x<- x[order(x[,mzcol]), ]
      
      table$IDSample<-createID(ref = "IDMatch", number = nrow(table))
      
      rownames(table)<-createID(ref = "IDMatch", number = nrow(table))
      
      
      
      mz1 <- x[, mzcol]
      rt1 <- x[, rtcol]
      mz2 <- table[, mzcol]
      rt2 <- table[, rtcol]
      
      names(mz2)<-createID(ref = "IDMatch", number = length(mz2))
      
      
      idxl <- vector("list", length = nrow(x))
      
      
      withProgress(message = 'In progress..', value = 0, {
        
        pb_match <- txtProgressBar(min=1, max = length(seq_along(idxl)), style = 3)
        cat("matching rt1~rt2 and mz1~mz2 ...!\n")
        
        
        for (i in seq_along(idxl)) {
          
          setTxtProgressBar(pb_match, i)
          
          incProgress(1/length(seq_along(idxl)), detail = "")
          
          matches <- which(abs(mz2-mz1[i])<=MsCoreUtils::ppm(mz1[i], ppm_tolereance))

          if (length(matches)) {
            
            matche <- matches[abs(mz2[matches]-mz1[i])==min(abs(mz2[matches]-mz1[i]))][1]
            idxl[[i]] <- names(mz2)[matche]
            mz2<-mz2[-which(names(mz2) %in% names(mz2)[matche])] 
            
          } else idxl[[i]] <- nomatch
        }
        close(pb_match)
        
      })
      
      cat("OK...!\n")
      
      colnames_x<-colnames(x)
      colnames_table<-colnames(table)
      colnames(x)<-paste0(colnames_x,".1")
      colnames(table)[-ncol(table)]<-paste0(colnames_table[-ncol(table)],".2")

      MatchTable = cbind(x[seq_along(x[,paste0(mzcol,".1")]),],
                         table[unlist(idxl),])
      

      rownames(MatchTable)<-1:nrow(MatchTable)
      
      percentageMatch = round((nrow(MatchTable)-sum(is.na(MatchTable[,paste0(mzcol,".2")])))*100/nrow(MatchTable), digits = 2)
      numberMatch = (nrow(MatchTable)-sum(is.na(MatchTable[,paste0(mzcol,".2")])))
      
    
      return(ResMatch = list(idxl = idxl,
                             percentageMatch = percentageMatch,
                             numberMatch = numberMatch,
                             MatchTable = MatchTable))
        
    }
    
  }
  
  
}


#  cleanup : forcer la fermeture des connexion socket
cleanup_ce_time_cluster <- function() {
  if (exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
    tryCatch({
      # Arrêter tous les workers BiocParallel
      bpstop(bpparam())
      rm(".biocparallel_registered_ce_time", envir = .GlobalEnv)
      gc(verbose = FALSE)
      
      cat("CE-Time cluster cleaned up successfully\n")
    }, error = function(e) {
      warning(paste("CE-Time cleanup warning:", e$message))
    })
  }
}
