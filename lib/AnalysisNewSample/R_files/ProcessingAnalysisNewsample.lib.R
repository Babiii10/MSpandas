##" Load some necessary files 
source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')
library(data.table)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Peak Pecking with MSDIAL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

findPeaks_MSDIAL<-function(input_files, output_files = getwd(),
                           output_export_param,
                           MS1_type = "Profile",
                           MS2_type = "Profile",
                           ion = "Positive", 
                           rt_begin = "0", 
                           rt_end = "100", 
                           mz_range_begin = "0", 
                           mz_range_end = "2000", 
                           mz_tolerance_centroid_MS1 = "0.01",
                           mz_tolerance_centroid_MS2 = "0.05",
                           maxCharge = "7", 
                           number_threads = "5", 
                           min_Peakwidth = "5", 
                           min_PeakHeight = "1000", 
                           mass_slice_width = "0.05", 
                           Adduct_list = list("[M+H]+", "[M+Na]+", "[M+K]+"),
                           batch_size = NULL,
                           after_batch_fun = NULL,
                           timeout_sec = NULL,
                           shinyProgressData=NULL){
  
  
  
  
  
  message("\n--- PEAK PICKING ---\n")
  
  incProgress(1/8, detail = paste("Calling peak detection...", collapse=""))
  
  ########################################################################
  updateShinyProgressBar(
    shinyProgressData=list(
      session=session,
      progressId="preprocessProgressBar",
      progressTotal=8,
      textId="analysis_pre"
    ),
    pbValue=3,
    headerMsg="Calling peak picking...",
    footerMsg="peak picking in progress..."
  )
  ########################################################################
  
  
  # Nettoyage des dossiers temporaires laissés par un run précédent interrompu.
  # À faire avant toute logique batch pour éviter l'état incohérent du .bat.
  {
    stale_batch <- file.path(normalizePath(input_files, winslash = "/", mustWork = FALSE),
                             "_msdial_batches_tmp")
    stale_rec   <- file.path(normalizePath(input_files, winslash = "/", mustWork = FALSE),
                             "_msdial_recovery_tmp")
    cleanup_stale <- function(dir_path) {
      if (!dir.exists(dir_path)) return(invisible(NULL))
      items <- list.files(dir_path, full.names = TRUE, all.files = TRUE, no.. = TRUE)
      for (item in items) {
        if (dir.exists(item)) {
          if (grepl("\\.d$", item, ignore.case = TRUE)) unlink(item, recursive = FALSE)
          else unlink(item, recursive = TRUE)
        } else {
          file.remove(item)
        }
      }
      unlink(dir_path, recursive = FALSE)
      if (!dir.exists(dir_path))
        message(sprintf("--- Dossier temp précédent nettoyé : %s ---", basename(dir_path)))
    }
    cleanup_stale(stale_batch)
    cleanup_stale(stale_rec)
  }

  MsdialParam(input_param = req(RvarsPeakDetectionNewSample$paramMsdial_ref_path),
              output_param = file.path(output_export_param ,"peakPicking_Parameters.txt"),
              MS1_type = as.character(MS1_type), 
              MS2_type = as.character(MS2_type), 
              ion = as.character(ion), 
              rt_begin = as.character(rt_begin), 
              rt_end =  as.character(rt_end) , 
              mz_range_begin = as.character(mz_range_begin), 
              mz_range_end = as.character(mz_range_end), 
              mz_tolerance_centroid_MS1 = as.character(mz_tolerance_centroid_MS1), 
              mz_tolerance_centroid_MS2 = as.character(mz_tolerance_centroid_MS2), 
              maxCharge = as.character(maxCharge), 
              number_threads = as.character(number_threads), 
              min_Peakwidth = as.character(min_Peakwidth), 
              min_PeakHeight = as.character(min_PeakHeight), 
              mass_slice_width = as.character(mass_slice_width), 
              Adduct_list = as.list(Adduct_list))
  
  # Suppression R-native d'un dossier contenant des junctions/hardlinks.
  # N'utilise PAS shell()/cmd.exe → immunisé contre l'erreur 322.
  remove_batch_dir <- function(dir_path) {
    if (!dir.exists(dir_path)) return(invisible(TRUE))
    items <- list.files(dir_path, full.names = TRUE, all.files = TRUE, no.. = TRUE)
    for (item in items) {
      if (dir.exists(item)) {
        if (grepl("\\.d$", item, ignore.case = TRUE)) {
          unlink(item, recursive = FALSE)
        } else {
          unlink(item, recursive = TRUE)
        }
      } else {
        file.remove(item)
      }
    }
    unlink(dir_path, recursive = FALSE)
    invisible(!dir.exists(dir_path))
  }
  
  run_msdial_bat <- function(expected_stems = NULL, output_dir = NULL) {
    bat_file   <- normalizePath("lib/AnalysisNewSample/cmd/RunMsdialPeakPicking.bat",
                                winslash = "\\", mustWork = FALSE)
    timeout_s <- {
      t <- suppressWarnings(as.integer(timeout_sec))
      if (length(t) == 1L && !is.na(t) && t > 0L) t else 14400L
    }
    poll_interval_s <- 10L
    grace_after_complete_s <- 30L
    
    if (.Platform$OS.type == "windows") {
      sentinel <- tempfile(fileext = "_msdial_done.flag")
      wrapper_bat <- tempfile(fileext = "_msdial_wrapper.bat")
      writeLines(c(
        "@echo off",
        paste0('call "', bat_file, '"'),
        paste0('echo DONE > "', normalizePath(sentinel, winslash = "\\", mustWork = FALSE), '"')
      ), wrapper_bat)
      
      shell(paste0('"', normalizePath(wrapper_bat, winslash = "\\"), '"'),
            wait = FALSE, mustWork = FALSE)
      
      message(sprintf("--- MsdialConsoleApp lancé, timeout %ds ---", timeout_s))
      
      start_time <- proc.time()[["elapsed"]]
      completed_early <- FALSE
      
      while (TRUE) {
        elapsed <- proc.time()[["elapsed"]] - start_time
        
        if (elapsed >= timeout_s) {
          message(sprintf("TIMEOUT: MsdialConsoleApp arrêté après %ds", round(elapsed)))
          tryCatch(
            system2("taskkill", args = c("/F", "/IM", "MsdialConsoleApp.exe"),
                    stdout = FALSE, stderr = FALSE, wait = TRUE),
            error = function(e) NULL
          )
          break
        }
        
        if (file.exists(sentinel)) {
          message(sprintf("--- MsdialConsoleApp terminé naturellement après %.0fs ---", elapsed))
          break
        }
        
        if (!is.null(expected_stems) && !is.null(output_dir) && length(expected_stems) > 0) {
          existing_msdial <- tolower(sub("\\.msdial$", "",
                                         list.files(output_dir, pattern = "\\.msdial$",
                                                    full.names = FALSE, ignore.case = TRUE),
                                         ignore.case = TRUE))
          existing_msdial <- existing_msdial[!grepl("^alignresult-", existing_msdial)]
          if (all(tolower(expected_stems) %in% existing_msdial)) {
            msdial_paths <- list.files(output_dir, pattern = "\\.msdial$",
                                       full.names = TRUE, ignore.case = TRUE)
            msdial_paths <- msdial_paths[!grepl("AlignResult-", basename(msdial_paths), ignore.case = TRUE)]
            sizes1 <- file.size(msdial_paths)
            Sys.sleep(grace_after_complete_s)
            sizes2 <- file.size(msdial_paths)
            if (identical(sizes1, sizes2)) {
              message(sprintf(
                "--- Tous les %d .msdial détectés et stables → kill anticipé (gain ~%.0fs) ---",
                length(expected_stems), timeout_s - elapsed))
              tryCatch(
                system2("taskkill", args = c("/F", "/IM", "MsdialConsoleApp.exe"),
                        stdout = FALSE, stderr = FALSE, wait = TRUE),
                error = function(e) NULL
              )
              completed_early <- TRUE
              break
            }
          }
        }
        Sys.sleep(poll_interval_s)
      }
      
      suppressWarnings(file.remove(sentinel, wrapper_bat))
      if (completed_early) message("--- Kill anticipé : RAM libérée, fichiers intacts ---")
      return(invisible(NULL))
    }
    # Linux/Mac fallback
    system2(bat_file)
  }
  
  input_dir <- normalizePath(input_files, winslash = "/", mustWork = FALSE)
  input_items <- list.files(input_dir, full.names = TRUE, recursive = FALSE)
  input_items <- input_items[dir.exists(input_items) | file.exists(input_items)]
  input_items <- input_items[grepl("\\.d$|\\.mzML$", basename(input_items), ignore.case = TRUE)]
  
  # Déterminer les échantillons restants à traiter
  existing_csv <- list.files(output_files, pattern = "\\.csv$",
                             full.names = FALSE, ignore.case = TRUE)
  done_stems   <- tolower(sub("\\.csv$", "", existing_csv, ignore.case = TRUE))
  
  cache_file <- file.path(input_dir, ".msdial_processed_cache.txt")
  if (file.exists(cache_file)) {
    cached       <- tolower(trimws(readLines(cache_file, warn = FALSE)))
    cache_stems  <- sub("\\.(d|mzML)$", "", cached[nzchar(cached)], ignore.case = TRUE)
    done_stems   <- unique(c(done_stems, cache_stems))
  }
  
  input_stems <- tolower(sub("\\.(d|mzML)$", "", basename(input_items), ignore.case = TRUE))
  to_process  <- input_items[!(input_stems %in% done_stems)]
  
  batch_size <- suppressWarnings(as.integer(batch_size))
  if (!is.na(batch_size) && batch_size > 0) {
    if (length(to_process) == 0) {
      message("--- Tous les échantillons déjà traités (cache) — peak picking ignoré ---")
      return(invisible(NULL))
    }
    
    n_batches  <- ceiling(length(to_process) / batch_size)
    batch_root <- file.path(input_dir, "_msdial_batches_tmp")
    dir.create(batch_root, recursive = TRUE, showWarnings = FALSE)
    
    make_batch_links <- function(items, dest_dir) {
      vapply(seq_along(items), function(i) {
        item_w <- normalizePath(items[i], winslash = "\\", mustWork = FALSE)
        link_w <- normalizePath(file.path(dest_dir, basename(items[i])),
                                winslash = "\\", mustWork = FALSE)
        if (dir.exists(items[i])) {
          cmd <- paste0('mklink /J "', link_w, '" "', item_w, '"')
          shell(cmd, mustWork = FALSE, intern = TRUE)
        } else {
          file.link(items[i], file.path(dest_dir, basename(items[i])))
        }
        file.exists(link_w) || dir.exists(link_w)
      }, logical(1))
    }
    
    for (b in seq_len(n_batches)) {
      idx_start <- (b - 1) * batch_size + 1
      idx_end   <- min(b * batch_size, length(to_process))
      batch_items <- to_process[idx_start:idx_end]
      
      batch_input_dir <- file.path(batch_root, sprintf("batch_%03d", b))
      if (dir.exists(batch_input_dir)) remove_batch_dir(batch_input_dir)
      dir.create(batch_input_dir, recursive = TRUE, showWarnings = FALSE)
      
      if (.Platform$OS.type == "windows") {
        message(sprintf("--- Batch %d/%d : création de %d lien(s) (junction / hardlink) ---",
                        b, n_batches, length(batch_items)))
        linked <- make_batch_links(batch_items, batch_input_dir)
        if (!all(linked)) {
          warning(sprintf("Batch %d/%d : %d lien(s) non créé(s)",
                          b, n_batches, sum(!linked)))
        }
        effective_items <- batch_items[linked]
      } else {
        for (item in batch_items) file.symlink(item, file.path(batch_input_dir, basename(item)))
        effective_items <- batch_items
      }
      
      if (length(effective_items) == 0) {
        message(sprintf("--- Batch %d/%d : aucun lien créé, batch ignoré ---", b, n_batches))
        next
      }
      
      findPeaksMsdial(input_files = normalizePath(batch_input_dir, winslash = "/", mustWork = FALSE),
                      output_files = output_files,
                      output_export_param = output_export_param)
      
      batch_expected_stems <- tolower(sub("\\.(d|mzML)$", "", basename(effective_items), ignore.case = TRUE))
      
      msdial_before <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
      msdial_before <- msdial_before[!grepl("AlignResult-", basename(msdial_before), ignore.case = TRUE)]
      run_msdial_bat(expected_stems = batch_expected_stems, output_dir = output_files)
      msdial_after  <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
      msdial_after  <- msdial_after[!grepl("AlignResult-", basename(msdial_after), ignore.case = TRUE)]
      new_msdial    <- setdiff(msdial_after, msdial_before)
      
      Sys.sleep(2)
      remove_batch_dir(batch_input_dir)
      
      if (is.function(after_batch_fun) && length(new_msdial) > 0) {
        message(sprintf("--- Batch %d/%d : déconvolution de %d fichier(s) .msdial ---",
                        b, n_batches, length(new_msdial)))
        after_batch_fun(new_msdial)
      }
      
      message(sprintf("--- Batch %d/%d terminé ---", b, n_batches))
      gc()
    }
    
    if (dir.exists(batch_root)) remove_batch_dir(batch_root)
    
  } else {
    if (length(to_process) == 0) {
      message("--- Tous les échantillons déjà traités (cache) — peak picking ignoré ---")
      return(invisible(NULL))
    }
    findPeaksMsdial(input_files = input_files, output_files = output_files, output_export_param = output_export_param )
    all_expected_stems <- tolower(sub("\\.(d|mzML)$", "", basename(to_process), ignore.case = TRUE))
    run_msdial_bat(expected_stems = all_expected_stems, output_dir = output_files)
  }
  
  # Vérification finale : détection automatique des échantillons sans CSV
  if (is.function(after_batch_fun)) {
    max_recovery_rounds <- 3L
    for (round_i in seq_len(max_recovery_rounds)) {
      csv_now     <- list.files(output_files, pattern = "\\.csv$",
                                full.names = FALSE, ignore.case = TRUE)
      done_now    <- tolower(sub("\\.csv$", "", csv_now, ignore.case = TRUE))
      if (file.exists(cache_file)) {
        cached_now  <- tolower(trimws(readLines(cache_file, warn = FALSE)))
        cache_now   <- sub("\\.(d|mzML)$", "", cached_now[nzchar(cached_now)],
                           ignore.case = TRUE)
        done_now    <- unique(c(done_now, cache_now))
      }
      all_inputs  <- list.files(input_dir, full.names = TRUE, recursive = FALSE)
      all_inputs  <- all_inputs[grepl("\\.d$|\\.mzML$", basename(all_inputs), ignore.case = TRUE)]
      all_stems   <- tolower(sub("\\.(d|mzML)$", "", basename(all_inputs), ignore.case = TRUE))
      missing     <- all_inputs[!(all_stems %in% done_now)]
      
      if (length(missing) == 0) {
        message(sprintf("--- Vérification finale (tour %d) : tous les échantillons OK ---",
                        round_i))
        break
      }
      
      message(sprintf(
        "--- Vérification finale (tour %d/%d) : %d échantillon(s) sans CSV → retraitement ---",
        round_i, max_recovery_rounds, length(missing)))
      
      recovery_batch_size <- if (!is.na(batch_size) && batch_size > 0) batch_size else 50L
      n_rec <- ceiling(length(missing) / recovery_batch_size)
      rec_root <- file.path(input_dir, "_msdial_recovery_tmp")
      dir.create(rec_root, recursive = TRUE, showWarnings = FALSE)
      
      for (rb in seq_len(n_rec)) {
        rb_start <- (rb - 1L) * recovery_batch_size + 1L
        rb_end   <- min(rb * recovery_batch_size, length(missing))
        rb_items <- missing[rb_start:rb_end]
        
        rb_dir <- file.path(rec_root, sprintf("recovery_%03d", rb))
        dir.create(rb_dir, recursive = TRUE, showWarnings = FALSE)
        
        if (.Platform$OS.type == "windows") {
          linked_rb <- make_batch_links(rb_items, rb_dir)
          effective_rb <- rb_items[linked_rb]
        } else {
          for (item in rb_items) file.symlink(item, file.path(rb_dir, basename(item)))
          effective_rb <- rb_items
        }
        
        if (length(effective_rb) == 0) next
        
        findPeaksMsdial(input_files = normalizePath(rb_dir, winslash = "/", mustWork = FALSE),
                        output_files = output_files,
                        output_export_param = output_export_param)
        
        rb_stems  <- tolower(sub("\\.(d|mzML)$", "", basename(effective_rb), ignore.case = TRUE))
        rb_before <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
        rb_before <- rb_before[!grepl("AlignResult-", basename(rb_before), ignore.case = TRUE)]
        run_msdial_bat(expected_stems = rb_stems, output_dir = output_files)
        rb_after  <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
        rb_after  <- rb_after[!grepl("AlignResult-", basename(rb_after), ignore.case = TRUE)]
        new_msdial_rec <- setdiff(rb_after, rb_before)
        
        Sys.sleep(2)
        remove_batch_dir(rb_dir)
        
        if (length(new_msdial_rec) > 0) {
          after_batch_fun(new_msdial_rec)
        }
        gc()
      }
      if (dir.exists(rec_root)) remove_batch_dir(rec_root)
    }
  }
  
  message("--- END PEAK PICKING ---\n")
  
  incProgress(1/8, detail = paste("End peak detection...", collapse=""))
  
  ########################################################################
  updateShinyProgressBar(
    shinyProgressData=list(
      session=session,
      progressId="preprocessProgressBar",
      progressTotal=8,
      textId="analysis_pre"
    ),
    pbValue=4,
    headerMsg="Calling peak picking...",
    footerMsg="End peak detection..."
  )
  ########################################################################
  
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#





#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##################################### traitement des peakList de Msdial ###########################################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


ProcessPeaks.msdial.NewSample<-function(path.peaks.msdial,
                              file_adduct,
                              mass_slice_width,
                              min_PeaksMassif,
                              shinyProgressData = NULL){
  
  ## packages necessary
  
  if(!(require(MsCoreUtils))) 
    stop("R Package MsCoreUtils is required, please install MsCoreUtils package !")
  
  if(!(require(bigstatsr))) 
    stop("R Package bigstatsr is required, please install bigstatsr package !")
  if(!(require(bigreadr))) 
    stop("R Package bigreadr is required, please install bigreadr package !")
  
  if(!(require(tidyverse))) 
    stop("R Package tidyverse is required!")
  if(!(require(dplyr))) 
    stop("R Package dplyr is required!")
  if(!(require(stringr))) 
    stop("R Package dplyr is required!")
  
  
  
  
  
  
  # read one sample
  peaks.msdial_read<-fread2(path.peaks.msdial,
                            data.table = TRUE, 
                            select = c("PeakID", "Precursor m/z", "Height",
                                       "Area", "Adduct", "Isotope", "Comment","S/N", "RT (min)",
                                       "RT left(min)", "RT right (min)"))
  
  peaks.msdial<-data.frame(PeakID = peaks.msdial_read$PeakID,
                           Precursor.mz = peaks.msdial_read$`Precursor m/z`, 
                           rt = peaks.msdial_read$`RT (min)`*60,
                           rtmin = peaks.msdial_read$`RT left(min)`*60,
                           rtmax = peaks.msdial_read$`RT right (min)`*60,
                           Height = peaks.msdial_read$Height, 
                           Area = peaks.msdial_read$Area,
                           SN =peaks.msdial_read$`S/N`,
                           sample = sub(basename(path.peaks.msdial), pattern = ".msdial",
                                        replacement = "", fixed = TRUE),
                           Adduct = peaks.msdial_read$Adduct, 
                           Isotope = peaks.msdial_read$Isotope, 
                           Comment = peaks.msdial_read$Comment)
  
  
  cat("Extracting isotopes ... 1/7 \n")
  #Extraction of isotopes 
  
  
  peaks.msdial[,"isotope"]<-str_extract(peaks.msdial$Comment,"of \\d+")
  
  
  peaks.msdial[,"isotope"]<-str_replace_all(peaks.msdial[,"isotope"],"of ","")
  peaks.msdial[,"isotope"]<-as.numeric(peaks.msdial[,"isotope"])
  
  
  cat("Extracting charges ... 2/6 \n")
  #Extraction of charge
  
  peaks.msdial[,"charge"]<-ifelse(is.na(str_extract(peaks.msdial$Adduct,"]\\d+"))==FALSE,
                                  str_replace(str_extract(peaks.msdial$Adduct,"]\\d+"),"]",""),1)
  peaks.msdial[,"charge"]<-as.numeric(peaks.msdial[,"charge"])
  
  #Extraction of number of isotopes within a massif and compute sum of intensity of a massif isotopic
  cat("Extraction of number of isotopes within a massif and compute sum of intensity of a massif isotopic...3/7 \n")
  liste_isotope <- peaks.msdial %>% 
    distinct(isotope)
  
  
  table_filtered<- peaks.msdial %>%
    dplyr::filter(PeakID %in% liste_isotope$isotope)
  
  if (nrow(table_filtered) == 0) {
    warning(sprintf("Aucun pic mono-isotopique dans : %s", path.peaks.msdial))
    return(data.frame())
  }
  
  x <- peaks.msdial %>%
    group_by(isotope) %>%
    dplyr::filter(is.na(isotope)!=TRUE) %>% 
    arrange(Precursor.mz) %>%
    mutate(nb_isotope=length(Precursor.mz),
           somme_Area=sum(Area),
           somme_Height=sum(Height),
           mz_PeaksIsotopics_group = toString(Precursor.mz),
           rt_PeaksIsotopics_group = toString(rt),
           Height_PeaksIsotopics_group = toString(Height)) %>%  
    dplyr::distinct(isotope,.keep_all=TRUE) 
  
  
  
  # Compute number of isotope and, sum Height and Area within an isotope massif
  pb7 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
  cat("Compute number of isotope and, sum Height and Area within an isotope massif...4/6 \n")
  for (i in 1:nrow(table_filtered)){
    setTxtProgressBar(pb7, i)
    table_filtered[i,"mz_PeaksIsotopics"] <- toString(c(table_filtered[i,"Precursor.mz"],
                                                        toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"mz_PeaksIsotopics_group"][[1]])))
    table_filtered[i,"rt_PeaksIsotopics"] <- toString(c(table_filtered[i,"rt"],
                                                        toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"rt_PeaksIsotopics_group"][[1]])))
    table_filtered[i,"Height_PeaksIsotopics"] <- toString(c(table_filtered[i,"Height"],
                                                            toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"Height_PeaksIsotopics_group"][[1]])))
    
    table_filtered[i,"nb_isotope"] <- x[which(x$isotope==table_filtered[i,"PeakID"] ),"nb_isotope"][[1]]+1
    table_filtered[i,"Height"] <- table_filtered[i,"Height"]+ x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Height"][[1]]
    table_filtered[i,"Area"] <- table_filtered[i,"Area"]+ x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Area"][[1]]
    
    
  }
  close(pb7)
  
  
  ### Filter Massif
  
  pb_filterMassif <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
  cat("Filter massif...4/6 \n")
  ## Filter massif
  idxDeleteMassifTowPeaks<-c()
  idxDeleteCharge4<-c()
  idxDeleteCharge5<-c()
  for(i in 1:nrow(table_filtered)){
    setTxtProgressBar(pb_filterMassif, i)
    
    ## Delete massif contains only 2 (n) peaks
    nmbPeakTest<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
    if(nmbPeakTest < min_PeaksMassif){
      idxDeleteMassifTowPeaks[i]<-i
    }
    
    ## Delete massif 4+ contains less than 3 peaks
    if(table_filtered[i,]$charge == 4){
      nmbPeak<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
      if(nmbPeak<3){
        idxDeleteCharge4[i]<-i
      }
    }
    
    ## Delete massif 5+ contains less than 4 peaks
    if(table_filtered[i,]$charge >= 5){
      nmbPeak<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
      if(nmbPeak<4){
        idxDeleteCharge5[i]<-i
      }
    }
    
  }
  
  close(pb_filterMassif)
  
  idxDelete<-c(idxDeleteCharge4,idxDeleteCharge5,idxDeleteMassifTowPeaks)
  idxDelete<-idxDelete[!is.na(idxDelete)]
  
  if (length(idxDelete) > 0) {
    table_filtered<-table_filtered[-idxDelete,]
  }
  if (nrow(table_filtered) == 0) {
    warning(sprintf("Aucun pic restant après filtre massif dans : %s", path.peaks.msdial))
    return(data.frame())
  }
  
  
  #Compute mz without adduct
  
  cat("Computing M+H ... 5/6 \n")
  adduct <-read.csv(file_adduct)
  
  adduct_extracted <- str_extract(table_filtered[,"Adduct"],"\\[[[:alnum:]]+\\+[[:alnum:]]+\\]")
  adduct_number <- as.numeric(ifelse(is.na(str_extract(adduct_extracted,"[:digit:]"))==FALSE,str_extract(adduct_extracted,"[:digit:]"),1))
  adduct_extracted <- str_replace_all(table_filtered[,"Adduct"],"[:digit:]","")
  
  
  pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
  for (i in 1:nrow(table_filtered)){
    setTxtProgressBar(pb4, i)
    
    table_filtered[i,"M+H"] <- (table_filtered[i,"Precursor.mz"] - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276
    table_filtered[i,"iso.mass"] <- toString((as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))) - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276)
    
  }
  close(pb4)
  
  
  
  # sum intensity adduct to pic mono-isotopic
  write.csv(table_filtered, "table_filtered.csv")
  print(getwd())
  print(head(table_filtered, 5 ))
  
  somme_intensite_height <- function(Comment,Height,Area){
    `%ni%` <- Negate(`%in%`)
    peaks_linked_id <- str_replace_all(str_extract_all(Comment,"[:digit:]+_")[[1]],"_","")
    intensite_table_height <- Height
    intensite_table_area <- Area
    #pb5 <- txtProgressBar(min=1, max = length(peaks_linked_id), style = 3)
    for (i in peaks_linked_id){
      # setTxtProgressBar(pb5, i)
      if (as.numeric(i) %ni% (table_filtered %>% 
                              dplyr::select(PeakID))[,"PeakID"]){
        intensite_table_height <- intensite_table_height + (peaks.msdial %>% 
                                                              dplyr::filter(PeakID == i) %>% 
                                                              dplyr::select(Height))
        intensite_table_area <- intensite_table_area + (peaks.msdial %>% 
                                                          dplyr::filter(PeakID == i) %>% 
                                                          dplyr::select(Area))
      }
      
    }
    #close(pb5)
    return(list(intensite_table_height[[1]],intensite_table_area[[1]]))
  }
  cat("somme_intensite_height(Comment,Height,Area)[[1]] \n")
  print(somme_intensite_height(table_filtered$Comment,table_filtered$Height,table_filtered$Area)[[1]])

  cat("somme_intensite_height(Comment,Height,Area)[[2]]\n")
  print(somme_intensite_height(table_filtered$Comment,table_filtered$Height,table_filtered$Area)[[2]])
  
  cat("Processing...\n")
  table_filtered <- table_filtered %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(Height=somme_intensite_height(Comment,Height,Area)[[1]],
                  Area=somme_intensite_height(Comment,Height,Area)[[2]])
  
  
  # for (row_i in seq_len(nrow(table_filtered))) {
  #   res <- somme_intensite_height(table_filtered$Comment[row_i],
  #                                 table_filtered$Height[row_i],
  #                                 table_filtered$Area[row_i])
  #   table_filtered$Height[row_i] <- res[[1]]
  #   table_filtered$Area[row_i]   <- res[[2]]
  # }
  # 
  
  
  #as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ",")))
  
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ##~~~~~~~~~~~~~~~~~~~~~~~~ False massifs filter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  iso.massCulumnDeltat<-c()
  
  for (i in 1:length(table_filtered$iso.mass)) {
    iso.massCulumnDeltat[i]<-sort(diff(as.numeric(unlist(str_split(table_filtered$iso.mass[i], pattern = ",")))))[1]
  }
  
  idxMassifFalse<-which(iso.massCulumnDeltat<=0.85)
  
  table_filtered<-table_filtered[-idxMassifFalse,]
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  
  
  ## Add column Group Info
  table_filtered<-as.data.frame(table_filtered)
  table_filtered$iso.mass.link<-table_filtered$iso.mass
  table_filtered$mz_PeaksIsotopics_Group<-table_filtered$mz_PeaksIsotopics
  table_filtered$rt_PeaksIsotopics_Group<-table_filtered$rt_PeaksIsotopics
  table_filtered$Height_PeaksIsotopics_Group<-table_filtered$Height_PeaksIsotopics
  table_filtered<-table_filtered[order(table_filtered$`M+H`),]
  rownames(table_filtered)<-1:nrow(table_filtered)
  
  table_filtered_new<-table_filtered
  
  # ## Grouping massif in sample
  # ## first Grouping
  # table_filtered_new<-Grouping.Massif_NewRefMap(X = table_filtered,
  #                                               mz.tolerance = 0.15,
  #                                               rt.tolerance = 30)
  # 
  # 
  # # Second Grouping
  # table_filtered_new<-Grouping.Massif_NewRefMap_Second(X = table_filtered_new,
  #                                                      mz.tolerance = 0.09,
  #                                                      rt.tolerance = 180)
  
  
  rColSelected<-c("M+H","rt","rtmin","rtmax","Height","Area","SN","sample",
                  "iso.mass","iso.mass.link","mz_PeaksIsotopics_Group", "rt_PeaksIsotopics_Group","Height_PeaksIsotopics_Group","Adduct")
  
  table_filtered_new<-table_filtered_new[,rColSelected]
  
  
  
  table_filtered_new<-as.data.frame(table_filtered_new)
  rownames(table_filtered_new)<-1:nrow(table_filtered_new)
  
  peaks<-table_filtered_new
  peaks[,"M+H.min"]<-peaks$`M+H`-mass_slice_width/2
  peaks[,"M+H.max"]<-peaks$`M+H`+ mass_slice_width/2
  
  colSelect<-c("M+H","M+H.min","M+H.max","rt","rtmin","rtmax","Area","Height","SN","sample",
               "iso.mass","iso.mass.link","mz_PeaksIsotopics_Group","rt_PeaksIsotopics_Group","Height_PeaksIsotopics_Group","Adduct")
  peaks<-peaks[,colSelect]
  
  reqColsNames<-c('M+H','M+H.min','M+H.max','CE-time','CE-time.min','CE-time.max',
                  'integrated-intensity','intensity', 'sn', 'sample')
  
  colnames(peaks)[1:10]<-reqColsNames
  
  
  return(peaks)
  
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
######################### traitement des peakList de Msdial, Extraction des massifs isotopics #######################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

deconv_peaks_MSDIAL<-function(path_to_peakList, 
                              file_adduct,
                              output_directory = NULL, 
                              mass_slice_width,
                              min_PeaksMassif,
                              workers = ceiling((detectCores())-1),
                              bpparam = NULL,
                              shinyProgressData=NULL){
  
  if (!is.null(shinyProgressData)) {
    if (!require(shinyWidgets)) {
      warning("R package shinyWidgets not present... Disabling progress ",
              "bar...",immediate.=TRUE)
      shinyProgressData <- NULL
    }
  }
  
  message("--- DECONVOLUTION ---\n")
  incProgress(1/8, detail = paste("Grouping peaks into massifs...",collapse=""))
  
  ########################################################################
  updateShinyProgressBar(
    shinyProgressData=list(
      session=session,
      progressId="preprocessProgressBar",
      progressTotal=8,
      textId="analysis_pre"
    ),
    pbValue=6,
    headerMsg="Peak deconvolution...",
    footerMsg="Grouping peaks into massifs..."
  )
  ########################################################################
  
  
  if(!require(BiocParallel))
    stop("R package \"BiocParallel\" is required !")
  if(!require(parallel))
    stop("R package \"parallel\" is required !")
  
  
  cat("path_to_peakList : \n")
  print(path_to_peakList)
  
  cat("lemme show the file_adduct : --> adduct.csv")
  print(file_adduct)
  
  # Si un cluster externe est fourni (bpparam != NULL), l'utiliser directement.
  # Son cycle de vie (création / arrêt) est géré par l'appelant — aucun socket
  # n'est créé ou détruit ici, ce qui évite l'accumulation TIME_WAIT entre batches.
  # Sinon, créer un cluster local avec un port libre garanti par l'OS (serverSocket(0)).
  find_free_port <- function() {
    tryCatch({
      con <- serverSocket(port = 0)
      port <- as.integer(sub(".*:(\\d+)$", "\\1", summary(con)$description))
      close(con)
      port
    }, error = function(e) NULL)
  }

  Result_Msidal <- NULL
  times <- 0

  if (!is.null(bpparam)) {
    # ── Cluster externe : utiliser tel quel, ne pas bpstop ──────────────────
    message("--- Déconvolution parallèle (cluster externe) ---")
    tryCatch({
      time1 <- system.time(Result_Msidal <-
                             bplapply(path_to_peakList,
                                      ProcessPeaks.msdial.NewSample,
                                      file_adduct = file_adduct,
                                      mass_slice_width = mass_slice_width,
                                      min_PeaksMassif = min_PeaksMassif,
                                      BPPARAM = bpparam))
    }, error = function(e) {
      message(sprintf("--- Parallélisation échouée (cluster externe) : %s ---",
                      conditionMessage(e)))
      message("--- Fallback vers SerialParam ---")
    })
  } else {
    # ── Cluster local : port libre + create/stop ici ─────────────────────────
    parallel_ok <- FALSE
    free_port <- find_free_port()
    if (!is.null(free_port)) {
      message(sprintf("--- Port libre trouvé : %d → création SnowParam ---", free_port))
      tryCatch({
        param <- SnowParam(workers = workers, type = "SOCK", timeout = 120,
                           port = free_port)
        tryCatch({
          time1 <- system.time(Result_Msidal <-
                                 bplapply(path_to_peakList,
                                          ProcessPeaks.msdial.NewSample,
                                          file_adduct = file_adduct,
                                          mass_slice_width = mass_slice_width,
                                          min_PeaksMassif = min_PeaksMassif,
                                          BPPARAM = param))
          parallel_ok <- TRUE
        }, finally = {
          tryCatch(bpstop(param), error = function(e) NULL)
          gc()
        })
      }, error = function(e) {
        message(sprintf("--- Parallélisation SOCK échouée (port %d) : %s ---",
                        free_port, conditionMessage(e)))
        message("--- Fallback vers traitement séquentiel (SerialParam) ---")
      })
    } else {
      message("--- Aucun port libre trouvé → SerialParam directement ---")
    }
  }

  if (is.null(Result_Msidal)) {
    message("--- Déconvolution séquentielle en cours... ---")
    time1 <- system.time(Result_Msidal <-
                           bplapply(path_to_peakList,
                                    ProcessPeaks.msdial.NewSample,
                                    file_adduct = file_adduct,
                                    mass_slice_width = mass_slice_width,
                                    min_PeaksMassif = min_PeaksMassif,
                                    BPPARAM = SerialParam()))
  }
  
  # Filtrer les résultats vides
  Result_Msidal <- Result_Msidal[vapply(Result_Msidal, function(x) nrow(x) > 0, logical(1))]
  time2 <- system.time(peaks_MSDIAL_mono_iso <- do.call("rbind", Result_Msidal))
  times <- time1[[3]] + time2[[3]]
  
  cat(paste("Time of computing mono-isotopic peaks :",times,"... !", sep = " "))
  if(is.null(output_directory)){ 
    cat("\n Finished.\n")
    
    colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
    return(peaks_MSDIAL_mono_iso)
  } else {
    cat("\n Save result...\n")
    
    for (i in seq_along(Result_Msidal)) {
      smp <- unique(Result_Msidal[[i]]$sample)
      if (!length(smp) || !nzchar(smp)) {
        smp <- sub("\\.msdial$", "", basename(path_to_peakList[[i]]), ignore.case = TRUE)
      }
      write.table(Result_Msidal[[i]], 
                  file = file.path(output_directory, paste0(smp, ".csv")), 
                  sep = ",", row.names = FALSE)
    }
    
    
    cat("\n Finished.\n")
    message("--- END ANNOTATION ---")
    
    incProgress(1/8, detail = paste("End grouping...",collapse=""))
    ########################################################################
    updateShinyProgressBar(
      shinyProgressData=list(
        session=session,
        progressId="preprocessProgressBar",
        progressTotal=8,
        textId="analysis_pre"
      ),
      pbValue=7,
      headerMsg="Peak deconvolution...",
      footerMsg="End grouping..."
    )
    ########################################################################
    
    colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
    
    
    return(peaks_MSDIAL_mono_iso)
  }
}
