# Configure Traitement parallel
# Only register if not already done (prevents socket connection leak)
# This file is sourced multiple times (in renderPlot), causing cluster duplication
if (!exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
  # Use register() without bpstart() to avoid immediate cluster creation
  # Cluster will be created on-demand by bplapply() when needed
  register(SnowParam(workers = 1, type = "SOCK"), default = FALSE)
  assign(".biocparallel_registered_ce_time", TRUE, envir = .GlobalEnv)
}


## Define functions utils

"%ni%"<-Negate("%in%")

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
                               batch_size    = NULL,
                               timeout_sec   = 7200L) {

  n_files    <- length(MSnbase::fileNames(xdata))
  batch_size <- suppressWarnings(as.integer(batch_size))

  # ── Direct (non-batched) path ──────────────────────────────────────────────
  if (is.na(batch_size) || batch_size <= 0L || n_files <= batch_size) {
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
  # With subset = all files and a fixed centerSample, obiwarp aligns every
  # sample independently against the center (no chained warp).  Running each
  # batch of 50 in its own callr subprocess caps memory per process and fully
  # releases it between batches — mathematically equivalent to a single run.
  if (!requireNamespace("callr", quietly = TRUE))
    stop("Package 'callr' is required for batched obiwarp (install.packages('callr')).")

  center_idx <- as.integer(centerSample)
  non_center <- setdiff(seq_len(n_files), center_idx)
  batches    <- split(non_center, ceiling(seq_along(non_center) / batch_size))
  n_batches  <- length(batches)

  message(sprintf(
    "--- Obiwarp batché : %d fichier(s), %d lot(s) de %d (centre = fichier %d) ---",
    n_files, n_batches, batch_size, center_idx))

  # Keep the original chromPeaks snapshot; we will only patch rt/rtmin/rtmax
  # for each batch in-place — this preserves the row ordering that the server
  # relies on for the cbind with peaks_mono_iso_toUSe[, 11:ncol].
  result_cp <- xcms::chromPeaks(xdata)

  for (b in seq_len(n_batches)) {
    batch_file_idx  <- c(center_idx, batches[[b]])
    center_in_batch <- 1L
    subset_in_batch <- seq_along(batch_file_idx)

    message(sprintf("--- Obiwarp lot %d/%d : %d fichier(s) ---",
                    b, n_batches, length(batch_file_idx)))

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

    # cp_adjusted has batch-relative sample indices (1 = center, 2..k = batch files).
    # Remap to full-dataset indices so we can match rows in result_cp.
    global_sample <- batch_file_idx[cp_adjusted[, "sample"]]

    # Update only the files that belong to this batch:
    # center is updated in batch 1 only; non-center files update in their own batch.
    files_to_update <- if (b == 1L) batch_file_idx else batches[[b]]

    for (f in files_to_update) {
      batch_rows  <- which(global_sample           == f)
      result_rows <- which(result_cp[, "sample"]   == f)
      if (length(batch_rows) == length(result_rows) && length(result_rows) > 0L) {
        result_cp[result_rows, c("rt", "rtmin", "rtmax")] <-
          cp_adjusted[batch_rows, c("rt", "rtmin", "rtmax")]
      } else if (length(batch_rows) != length(result_rows)) {
        warning(sprintf(
          "Obiwarp lot %d/%d : pics discordants pour fichier %d (%d vs %d) — ignoré",
          b, n_batches, f, length(batch_rows), length(result_rows)))
      }
    }

    rm(xdata_batch, cp_adjusted)
    gc()
    message(sprintf("--- Obiwarp lot %d/%d terminé ---", b, n_batches))
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
                     ) {
  
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
