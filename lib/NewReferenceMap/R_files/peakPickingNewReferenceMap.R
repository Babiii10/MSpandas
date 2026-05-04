##" Load some necessary files 
source_python('lib/NewReferenceMap/Python_files/modify_ParamMsdialNewReferenceMap.py')
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
                           timeout_sec = NULL){
  
  
 

  
  message("\n--- PEAK PICKING ---\n")
  
  incProgress(1/8, detail = paste("Calling peak detection...", round(3/8*100,0),"%",collapse=""))
  
  MsdialParam(input_param = file.path("lib/NewReferenceMap/parameters","paramMsdial.txt"),
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

  run_msdial_bat <- function() {
    bat_file <- normalizePath("lib/NewReferenceMap/cmd/RunMsdialPeakPicking.bat", winslash = "\\", mustWork = FALSE)
    timeout_sec_i <- suppressWarnings(as.integer(timeout_sec))
    if (.Platform$OS.type == "windows" && length(timeout_sec_i) == 1 && !is.na(timeout_sec_i) && timeout_sec_i > 0) {
      ps_cmd <- paste0(
        "$bat=", shQuote(bat_file), "; ",
        "$p=Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', $bat) -PassThru; ",
        "Wait-Process -Id $p.Id -Timeout ", timeout_sec_i, " -ErrorAction SilentlyContinue; ",
        "if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force; exit 124 } ",
        "exit $p.ExitCode"
      )
      out <- system2("powershell.exe", args = c("-NoProfile", "-Command", ps_cmd), stdout = TRUE, stderr = TRUE, wait = TRUE)
      return(out)
    }
    if (.Platform$OS.type == "windows") {
      return(system2("cmd.exe", args = c("/c", shQuote(bat_file)), stdout = TRUE, stderr = TRUE, wait = TRUE))
    }
    system2(bat_file)
  }

  input_dir <- normalizePath(input_files, winslash = "/", mustWork = FALSE)
  input_items <- list.files(input_dir, full.names = TRUE, recursive = FALSE)
  input_items <- input_items[dir.exists(input_items) | file.exists(input_items)]
  input_items <- input_items[grepl("\\.d$|\\.mzML$", basename(input_items), ignore.case = TRUE)]

  # Cache persistant dans le répertoire des données brutes.
  # Résiste aux changements de session : le nom du projet (avec sa date) change à chaque session,
  # mais le répertoire des données brutes (input_dir) reste stable.
  cache_file    <- file.path(input_dir, ".msdial_processed_cache.txt")
  existing_base <- character(0)
  if (file.exists(cache_file)) {
    cached <- trimws(readLines(cache_file, warn = FALSE))
    existing_base <- tolower(cached[nzchar(cached)])
  }
  # Compléter avec les .msdial déjà présents dans le dossier de sortie (reprise intra-session)
  existing_msdial <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
  existing_base   <- unique(c(existing_base,
                               tolower(sub("\\.msdial$", "", basename(existing_msdial), ignore.case = TRUE))))
  to_process <- input_items[!(tolower(basename(input_items)) %in% existing_base)]

  batch_size <- suppressWarnings(as.integer(batch_size))
  if (!is.na(batch_size) && batch_size > 0) {
    if (length(to_process) == 0) {
      message("--- Tous les échantillons déjà traités (cache) — peak picking ignoré ---")
      return(invisible(NULL))
    }

    n_batches      <- ceiling(length(to_process) / batch_size)
    # batch_root dans input_dir : même volume que les .d/.mzML → file.rename() instantané
    batch_root     <- file.path(input_dir, "_msdial_batches_tmp")
    all_new_msdial <- character(0)
    dir.create(batch_root, recursive = TRUE, showWarnings = FALSE)

    for (b in seq_len(n_batches)) {
      idx_start <- (b - 1) * batch_size + 1
      idx_end   <- min(b * batch_size, length(to_process))
      batch_items <- to_process[idx_start:idx_end]

      batch_input_dir <- file.path(batch_root, sprintf("batch_%03d", b))
      # Suppression propre du dossier sans suivre de jonctions éventuelles
      if (dir.exists(batch_input_dir)) {
        if (.Platform$OS.type == "windows") {
          shell(paste0('rd /s /q "', normalizePath(batch_input_dir, winslash = "\\"), '"'), mustWork = FALSE)
        } else {
          unlink(batch_input_dir, recursive = TRUE, force = TRUE)
        }
      }
      dir.create(batch_input_dir, recursive = TRUE, showWarnings = FALSE)

      # Déplacer les fichiers/dossiers dans le répertoire de batch.
      # file.rename() sur le même volume = simple renommage de métadonnées, sans copie ni jonction.
      message(sprintf("--- Batch %d/%d : déplacement de %d élément(s) ---",
                      b, n_batches, length(batch_items)))
      moved <- file.rename(batch_items, file.path(batch_input_dir, basename(batch_items)))
      if (!all(moved)) {
        # Restaurer les fichiers déjà déplacés avant d'arrêter
        ok_idx <- which(moved)
        if (length(ok_idx)) {
          file.rename(file.path(batch_input_dir, basename(batch_items[ok_idx])), batch_items[ok_idx])
        }
        stop(sprintf("Batch %d/%d : échec du déplacement de certains fichiers vers %s",
                     b, n_batches, batch_input_dir))
      }

      findPeaksMsdial(input_files = normalizePath(batch_input_dir, winslash = "/", mustWork = FALSE),
                      output_files = output_files,
                      output_export_param = output_export_param)

      msdial_before <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
      run_msdial_bat()
      msdial_after  <- list.files(output_files, pattern = "\\.msdial$", full.names = TRUE, ignore.case = TRUE)
      new_msdial    <- setdiff(msdial_after, msdial_before)
      if (is.function(after_batch_fun) && length(new_msdial) > 0) {
        all_new_msdial <- c(all_new_msdial, new_msdial)
      }

      # Remettre les fichiers sources à leur emplacement d'origine
      file.rename(file.path(batch_input_dir, basename(batch_items)), batch_items)
      # Supprimer le dossier temporaire (ne contient plus que .dcl/.pai2/.aef)
      if (.Platform$OS.type == "windows") {
        shell(paste0('rd /s /q "', normalizePath(batch_input_dir, winslash = "\\"), '"'), mustWork = FALSE)
      } else {
        unlink(batch_input_dir, recursive = TRUE, force = TRUE)
      }

      # Mettre à jour le cache persistant avec les échantillons traités dans ce batch
      cat(paste(basename(batch_items), collapse = "\n"), "\n", file = cache_file, append = TRUE)

      message(sprintf("--- Batch %d/%d terminé ---", b, n_batches))
      gc()
    }

    # Supprimer le dossier racine temporaire (vide après le dernier batch)
    if (dir.exists(batch_root)) unlink(batch_root, recursive = TRUE, force = TRUE)

    # Déconvolution unique après que TOUS les batches MS-DIAL sont terminés.
    # Évite le blocage inter-batch : les batches s'enchaînent sans interruption.
    if (is.function(after_batch_fun) && length(all_new_msdial) > 0) {
      message(sprintf("--- Tous les batches terminés — déconvolution de %d fichier(s) .msdial ---",
                      length(all_new_msdial)))
      after_batch_fun(all_new_msdial)
    }

  } else {
    if (length(to_process) == 0) {
      message("--- Tous les échantillons déjà traités (cache) — peak picking ignoré ---")
      return(invisible(NULL))
    }
    findPeaksMsdial(input_files = input_files, output_files = output_files, output_export_param = output_export_param )
    run_msdial_bat()
  }


  message("--- EDN PEAK PICKING ---\n")
  
  incProgress(1/8, detail = paste("End peak detection...", round(4/8*100,0),"%",collapse=""))

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
######################### traitement des peakList de Msdial, Extraction des pics mono-isotopiques #######################
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


ProcessPeaks.msdial<-function(path.peaks.msdial,
                              file_adduct,
                              mass_slice_width,
                              min_PeaksMassif
                              ){
  
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
  if(!(require(data.table)))
    stop("R Package data.table is required!")
  
  
  
 
  
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
  
  
  
  cat("Compute number of isotope and, sum Height and Area within an isotope massif...4/6 \n")
  x_key <- as.data.frame(x)
  idx_x <- match(table_filtered$PeakID, x_key$isotope)
  mz_group <- x_key$mz_PeaksIsotopics_group[idx_x]
  rt_group <- x_key$rt_PeaksIsotopics_group[idx_x]
  height_group <- x_key$Height_PeaksIsotopics_group[idx_x]
  nb_iso <- x_key$nb_isotope[idx_x]
  somme_h <- x_key$somme_Height[idx_x]
  somme_a <- x_key$somme_Area[idx_x]
  
  mz_group[is.na(mz_group)] <- ""
  rt_group[is.na(rt_group)] <- ""
  height_group[is.na(height_group)] <- ""
  nb_iso[is.na(nb_iso)] <- 0
  somme_h[is.na(somme_h)] <- 0
  somme_a[is.na(somme_a)] <- 0
  
  table_filtered[,"mz_PeaksIsotopics"] <- ifelse(
    nzchar(mz_group),
    paste0(table_filtered$Precursor.mz, ",", mz_group),
    as.character(table_filtered$Precursor.mz)
  )
  table_filtered[,"rt_PeaksIsotopics"] <- ifelse(
    nzchar(rt_group),
    paste0(table_filtered$rt, ",", rt_group),
    as.character(table_filtered$rt)
  )
  table_filtered[,"Height_PeaksIsotopics"] <- ifelse(
    nzchar(height_group),
    paste0(table_filtered$Height, ",", height_group),
    as.character(table_filtered$Height)
  )
  
  table_filtered[,"nb_isotope"] <- nb_iso + 1
  table_filtered[,"Height"] <- table_filtered$Height + somme_h
  table_filtered[,"Area"] <- table_filtered$Area + somme_a
  
  
  ### Filter Massif
  
  pb_filterMassif <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
  cat("Filter massif...4/6 \n")
  ## Filter massif
  
  count_commas <- lengths(regmatches(table_filtered$mz_PeaksIsotopics, gregexpr(",", table_filtered$mz_PeaksIsotopics, fixed = TRUE)))
  nmbPeakTest <- count_commas + 1L
  
  idxDeleteMassifTowPeaks <- which(nmbPeakTest < min_PeaksMassif)
  idxDeleteCharge4 <- which(table_filtered$charge == 4 & nmbPeakTest < 3)
  idxDeleteCharge5 <- which(table_filtered$charge >= 5 & nmbPeakTest < 4)
  
  close(pb_filterMassif)
  
  idxDelete <- unique(c(idxDeleteCharge4, idxDeleteCharge5, idxDeleteMassifTowPeaks))
  
  table_filtered<-table_filtered[-idxDelete,]
  
  
  #Compute mz without adduct
  
  cat("Computing M+H ... 5/6 \n")
  adduct <-read.csv(file_adduct)
  
  adduct_extracted <- str_extract(table_filtered[,"Adduct"],"\\[[[:alnum:]]+\\+[[:alnum:]]+\\]")
  adduct_number <- as.numeric(ifelse(is.na(str_extract(adduct_extracted,"[:digit:]"))==FALSE,str_extract(adduct_extracted,"[:digit:]"),1))
  adduct_extracted <- str_replace_all(table_filtered[,"Adduct"],"[:digit:]","")
  
  idx_adduct <- match(adduct_extracted, adduct$name)
  massdiff <- adduct$massdiff[idx_adduct]
  massdiff[is.na(massdiff)] <- 0
  
  table_filtered[,"M+H"] <- (table_filtered$Precursor.mz - (massdiff / table_filtered$charge) * adduct_number) * table_filtered$charge + 1.007276
  
  pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
  iso.mass_vec <- vapply(seq_len(nrow(table_filtered)), function(i) {
    setTxtProgressBar(pb4, i)
    mzs <- suppressWarnings(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
    mzs <- mzs[!is.na(mzs)]
    if (!length(mzs)) return("")
    toString((mzs - (massdiff[i] / table_filtered$charge[i]) * adduct_number[i]) * table_filtered$charge[i] + 1.007276)
  }, character(1))
  close(pb4)
  table_filtered[,"iso.mass"] <- iso.mass_vec
  
  
  
  # sum intensity adduct to pic mono-isotopic
  
  peaksHeightById <- setNames(peaks.msdial$Height, as.character(peaks.msdial$PeakID))
  peaksAreaById <- setNames(peaks.msdial$Area, as.character(peaks.msdial$PeakID))
  peakIdInTable <- as.character(table_filtered$PeakID)
  
  cat("Processing...\n")
  linked_ids_list <- str_extract_all(table_filtered$Comment, "[:digit:]+_")
  linked_ids_list <- lapply(linked_ids_list, function(x) str_replace_all(x, "_", ""))
  
  sums <- lapply(seq_along(linked_ids_list), function(i) {
    ids <- linked_ids_list[[i]]
    if (!length(ids)) return(c(0, 0))
    ids <- ids[!(ids %in% peakIdInTable)]
    if (!length(ids)) return(c(0, 0))
    h <- sum(peaksHeightById[ids], na.rm = TRUE)
    a <- sum(peaksAreaById[ids], na.rm = TRUE)
    c(h, a)
  })
  sums_mat <- do.call(rbind, sums)
  if (!is.null(sums_mat) && nrow(sums_mat) == nrow(table_filtered)) {
    table_filtered$Height <- table_filtered$Height + sums_mat[, 1]
    table_filtered$Area <- table_filtered$Area + sums_mat[, 2]
  }
  
  
  
  
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







####### extraction des peptides

deconv_peaks_MSDIAL<-function(path_to_peakList, 
                              file_adduct,
                              output_directory = NULL, 
                              mass_slice_width,
                              min_PeaksMassif,
                              workers = ceiling((detectCores())-1)){
  
  
  message("--- DECONVOLUTION ---\n")
  incProgress(1/8, detail = paste("Grouping peaks into massifs...", round(6/8*100,0),"%",collapse=""))

  
  if(!require(BiocParallel))
    stop("R package \"BiocParallel\" is required !")
  if(!require(parallel))
    stop("R package \"parallel\" is required !")
  
  
  
  param <- SnowParam(workers = workers, type = "SOCK")
  tryCatch({
  time1<-system.time(Result_Msidal<-
                        bplapply(path_to_peakList,
                                 ProcessPeaks.msdial,
                                 file_adduct = file_adduct,
                                 mass_slice_width = mass_slice_width,
                                 min_PeaksMassif = min_PeaksMassif,
                                 BPPARAM = param))
  time2<-system.time(peaks_MSDIAL_mono_iso<-do.call("rbind", Result_Msidal))
  times<-time1[[3]]+time2[[3]]
  }, finally = {
    # Always cleanup worker pool to prevent socket accumulation
    bpstop(param)
    gc()
  })
  
  cat(paste("Time of computing mono-isotopic peaks :",times,"... !", sep = " "))
  if(is.null(output_directory)){ 
    cat("\n Finished.\n")
    
    colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
    return(peaks_MSDIAL_mono_iso)
  } else {
    cat("\n Save result...\n")
    
    for (i in 1:length(Result_Msidal)) {
      write.table(Result_Msidal[[i]], 
                  file = file.path(output_directory,
                                   paste0(unique(Result_Msidal[[i]]$sample),".csv")), 
                  sep = ",", row.names = FALSE)
    }
    
    cat("\n Finished.\n")
    message("--- END ANNOTATION ---")
    
    incProgress(1/8, detail = paste("End grouping...", round(7/8*100,0),"%",collapse=""))
    
    colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")

    
    return(peaks_MSDIAL_mono_iso)
  }
}


