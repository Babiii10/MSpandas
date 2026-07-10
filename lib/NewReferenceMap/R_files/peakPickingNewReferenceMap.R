# ##" Load some necessary files
# source_python('lib/NewReferenceMap/Python_files/modify_ParamMsdialNewReferenceMap.py')
# 
# 
# 
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Peak Pecking with MSDIAL ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# 
# findPeaks_MSDIAL<-function(input_files, output_files = getwd(),
#                            output_export_param,
#                            MS1_type = "Profile",
#                            MS2_type = "Profile",
#                            ion = "Positive",
#                            rt_begin = "0",
#                            rt_end = "100",
#                            mz_range_begin = "0",
#                            mz_range_end = "2000",
#                            mz_tolerance_centroid_MS1 = "0.01",
#                            mz_tolerance_centroid_MS2 = "0.05",
#                            maxCharge = "7",
#                            number_threads = "5", # reduction du nombre de threads 5-->2  en cas de grandes tailles d'échantillons
#                            min_Peakwidth = "5",
#                            min_PeakHeight = "1000",
#                            mass_slice_width = "0.05",
#                            Adduct_list = list("[M+H]+", "[M+Na]+", "[M+K]+")){
# 
# 
# 
# 
# 
#   message("\n--- PEAK PICKING ---\n")
# 
#   # Monitoring RAM avant MSDIAL
#   if(requireNamespace("pryr", quietly = TRUE)) {
#     ram_before <- pryr::mem_used()
#     cat(sprintf("RAM avant MSDIAL: %.2f GB\n", ram_before / 1e9))
#   }
# 
#   incProgress(1/8, detail = paste("Calling peak detection...", round(3/8*100,0),"%",collapse=""))
# 
#   MsdialParam(input_param = file.path("lib/NewReferenceMap/parameters","paramMsdial.txt"),
#               output_param = file.path(output_export_param ,"peakPicking_Parameters.txt"),
#               MS1_type = as.character(MS1_type),
#               MS2_type = as.character(MS2_type),
#               ion = as.character(ion),
#               rt_begin = as.character(rt_begin),
#               rt_end =  as.character(rt_end) ,
#               mz_range_begin = as.character(mz_range_begin),
#               mz_range_end = as.character(mz_range_end),
#               mz_tolerance_centroid_MS1 = as.character(mz_tolerance_centroid_MS1),
#               mz_tolerance_centroid_MS2 = as.character(mz_tolerance_centroid_MS2),
#               maxCharge = as.character(maxCharge),
#               number_threads = as.character(number_threads),
#               min_Peakwidth = as.character(min_Peakwidth),
#               min_PeakHeight = as.character(min_PeakHeight),
#               mass_slice_width = as.character(mass_slice_width),
#               Adduct_list = as.list(Adduct_list))
# 
#   findPeaksMsdial(input_files = input_files, output_files = output_files, output_export_param = output_export_param )
#   system2("lib/NewReferenceMap/cmd/RunMsdialPeakPicking.bat")
# 
#   # Utiliser le batching pour limiter la RAM (batch de 50 échantillons)
#   # batch_size <- 50
#   # source_python("lib/NewReferenceMap/Python_files/modify_ParamMsdialNewReferenceMap.py")
#   # findPeaksMsdial_batched(input_files = input_files,
#   #                         output_files = output_files,
#   #                         output_export_param = output_export_param,
#   #                         batch_size = batch_size)
# 
# 
#   message("--- END PEAK PICKING ---\n")
# 
# 
#   # Monitoring RAM après MSDIAL
#   if(requireNamespace("pryr", quietly = TRUE)) {
#     ram_after <- pryr::mem_used()
#     cat(sprintf("RAM après MSDIAL: %.2f GB\n", ram_after / 1e9))
#   }
# 
#   incProgress(1/8, detail = paste("End peak detection...", round(4/8*100,0),"%",collapse=""))
# 
# }
# 
# 
# 
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ######################### traitement des peakList de Msdial, Extraction des pics mono-isotopiques #######################
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# 
# 
# ProcessPeaks.msdial<-function(path.peaks.msdial,
#                               file_adduct,
#                               mass_slice_width,
#                               min_PeaksMassif
#                               ){
# 
#   ## packages necessary
# 
#   if(!(require(MsCoreUtils)))
#     stop("R Package MsCoreUtils is required, please install MsCoreUtils package !")
# 
#   if(!(require(bigstatsr)))
#     stop("R Package bigstatsr is required, please install bigstatsr package !")
#   if(!(require(bigreadr)))
#     stop("R Package bigreadr is required, please install bigreadr package !")
# 
#   if(!(require(tidyverse)))
#     stop("R Package tidyverse is required!")
#   if(!(require(dplyr)))
#     stop("R Package dplyr is required!")
#   if(!(require(stringr)))
#     stop("R Package dplyr is required!")
# 
# 
# 
# 
# 
#   # read one sample
#   peaks.msdial_read<-fread2(path.peaks.msdial,
#                             data.table = TRUE,
#                             select = c("PeakID", "Precursor m/z", "Height",
#                                        "Area", "Adduct", "Isotope", "Comment","S/N", "RT (min)",
#                                        "RT left(min)", "RT right (min)"))
# 
#   peaks.msdial<-data.frame(PeakID = peaks.msdial_read$PeakID,
#                            Precursor.mz = peaks.msdial_read$`Precursor m/z`,
#                            rt = peaks.msdial_read$`RT (min)`*60,
#                            rtmin = peaks.msdial_read$`RT left(min)`*60,
#                            rtmax = peaks.msdial_read$`RT right (min)`*60,
#                            Height = peaks.msdial_read$Height,
#                            Area = peaks.msdial_read$Area,
#                            SN =peaks.msdial_read$`S/N`,
#                            sample = sub(basename(path.peaks.msdial), pattern = ".msdial",
#                                         replacement = "", fixed = TRUE),
#                            Adduct = peaks.msdial_read$Adduct,
#                            Isotope = peaks.msdial_read$Isotope,
#                            Comment = peaks.msdial_read$Comment)
# 
# 
# 
#   cat("Extracting isotopes ... 1/7 \n")
#   #Extraction of isotopes
# 
# 
#   peaks.msdial[,"isotope"]<-str_extract(peaks.msdial$Comment,"of \\d+")
# 
# 
#   peaks.msdial[,"isotope"]<-str_replace_all(peaks.msdial[,"isotope"],"of ","")
#   peaks.msdial[,"isotope"]<-as.numeric(peaks.msdial[,"isotope"])
# 
# 
#   cat("Extracting charges ... 2/6 \n")
#   #Extraction of charge
# 
#   peaks.msdial[,"charge"]<-ifelse(is.na(str_extract(peaks.msdial$Adduct,"]\\d+"))==FALSE,
#                                   str_replace(str_extract(peaks.msdial$Adduct,"]\\d+"),"]",""),1)
#   peaks.msdial[,"charge"]<-as.numeric(peaks.msdial[,"charge"])
# 
#   #Extraction of number of isotopes within a massif and compute sum of intensity of a massif isotopic
#   cat("Extraction of number of isotopes within a massif and compute sum of intensity of a massif isotopic...3/7 \n")
#   liste_isotope <- peaks.msdial %>%
#     distinct(isotope)
# 
# 
#   table_filtered<- peaks.msdial %>%
#     dplyr::filter(PeakID %in% liste_isotope$isotope)
# 
# 
#   x <- peaks.msdial %>%
#     group_by(isotope) %>%
#     dplyr::filter(is.na(isotope)!=TRUE) %>%
#     arrange(Precursor.mz) %>%
#     mutate(nb_isotope=length(Precursor.mz),
#            somme_Area=sum(Area),
#            somme_Height=sum(Height),
#            mz_PeaksIsotopics_group = toString(Precursor.mz),
#            rt_PeaksIsotopics_group = toString(rt),
#            Height_PeaksIsotopics_group = toString(Height)) %>%
#     dplyr::distinct(isotope,.keep_all=TRUE)
# 
# 
# 
#   # Compute number of isotope and, sum Height and Area within an isotope massif
#   pb7 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
#   cat("Compute number of isotope and, sum Height and Area within an isotope massif...4/6 \n")
#   for (i in 1:nrow(table_filtered)){
#     setTxtProgressBar(pb7, i)
#     table_filtered[i,"mz_PeaksIsotopics"] <- toString(c(table_filtered[i,"Precursor.mz"],
#                                                         toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"mz_PeaksIsotopics_group"][[1]])))
#     table_filtered[i,"rt_PeaksIsotopics"] <- toString(c(table_filtered[i,"rt"],
#                                                         toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"rt_PeaksIsotopics_group"][[1]])))
#     table_filtered[i,"Height_PeaksIsotopics"] <- toString(c(table_filtered[i,"Height"],
#                                                             toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"Height_PeaksIsotopics_group"][[1]])))
# 
#     table_filtered[i,"nb_isotope"] <- x[which(x$isotope==table_filtered[i,"PeakID"] ),"nb_isotope"][[1]]+1
#     table_filtered[i,"Height"] <- table_filtered[i,"Height"]+ x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Height"][[1]]
#     table_filtered[i,"Area"] <- table_filtered[i,"Area"]+ x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Area"][[1]]
# 
# 
#   }
#   close(pb7)
# 
# 
#   ### Filter Massif
# 
#   pb_filterMassif <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
#   cat("Filter massif...4/6 \n")
#   ## Filter massif
# 
#   idxDeleteMassifTowPeaks<-c()
#   idxDeleteCharge4<-c()
#   idxDeleteCharge5<-c()
#   for(i in 1:nrow(table_filtered)){
#     setTxtProgressBar(pb_filterMassif, i)
# 
#     ## Delete massif contains only 2 (n) peaks
#     nmbPeakTest<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
#     if(nmbPeakTest < min_PeaksMassif){
#       idxDeleteMassifTowPeaks[i]<-i
#     }
# 
#     ## Delete massif 4+ contains less than 3 peaks
#     if(table_filtered[i,]$charge == 4){
#       nmbPeak<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
#       if(nmbPeak<3){
#         idxDeleteCharge4[i]<-i
#       }
#     }
# 
#     ## Delete massif 5+ contains less than 4 peaks
#     if(table_filtered[i,]$charge >= 5){
#       nmbPeak<-length(as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))))
#       if(nmbPeak<4){
#         idxDeleteCharge5[i]<-i
#       }
#     }
# 
#   }
# 
#   close(pb_filterMassif)
# 
#   idxDelete<-c(idxDeleteCharge4,idxDeleteCharge5,idxDeleteMassifTowPeaks)
#   #idxDelete<-c(idxDeleteCharge4,idxDeleteCharge5)
#   idxDelete<-idxDelete[!is.na(idxDelete)]
# 
#   table_filtered<-table_filtered[-idxDelete,]
# 
# 
#   #Compute mz without adduct
# 
#   cat("Computing M+H ... 5/6 \n")
#   adduct <-read.csv(file_adduct)
# 
#   adduct_extracted <- str_extract(table_filtered[,"Adduct"],"\\[[[:alnum:]]+\\+[[:alnum:]]+\\]")
#   adduct_number <- as.numeric(ifelse(is.na(str_extract(adduct_extracted,"[:digit:]"))==FALSE,str_extract(adduct_extracted,"[:digit:]"),1))
#   adduct_extracted <- str_replace_all(table_filtered[,"Adduct"],"[:digit:]","")
# 
# 
#   pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
#   for (i in 1:nrow(table_filtered)){
#     setTxtProgressBar(pb4, i)
# 
#     table_filtered[i,"M+H"] <- (table_filtered[i,"Precursor.mz"] - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276
#     table_filtered[i,"iso.mass"] <- toString((as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))) - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276)
# 
#   }
#   close(pb4)
# 
# 
# 
#   # sum intensity adduct to pic mono-isotopic
# 
#   somme_intensite_height <- function(Comment,Height,Area){
#     `%ni%` <- Negate(`%in%`)
#     peaks_linked_id <- str_replace_all(str_extract_all(Comment,"[:digit:]+_")[[1]],"_","")
#     intensite_table_height <- Height
#     intensite_table_area <- Area
#     #pb5 <- txtProgressBar(min=1, max = length(peaks_linked_id), style = 3)
#     for (i in peaks_linked_id){
#       # setTxtProgressBar(pb5, i)
#       if (as.numeric(i) %ni% (table_filtered %>%
#                               dplyr::select(PeakID))[,"PeakID"]){
#         intensite_table_height <- intensite_table_height + (peaks.msdial %>%
#                                                               dplyr::filter(PeakID == i) %>%
#                                                               dplyr::select(Height))
#         intensite_table_area <- intensite_table_area + (peaks.msdial %>%
#                                                           dplyr::filter(PeakID == i) %>%
#                                                           dplyr::select(Area))
#       }
# 
#     }
#     #close(pb5)
#     return(list(intensite_table_height[[1]],intensite_table_area[[1]]))
#   }
# 
#   cat("Processing...\n")
#   table_filtered <- table_filtered %>%
#     dplyr::rowwise() %>%
#     dplyr::mutate(Height=somme_intensite_height(Comment,Height,Area)[[1]],
#                   Area=somme_intensite_height(Comment,Height,Area)[[2]])
# 
# 
# 
# 
#   #as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ",")))
# 
#   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#   ##~~~~~~~~~~~~~~~~~~~~~~~~ False massifs filter ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#   iso.massCulumnDeltat<-c()
# 
#   for (i in 1:length(table_filtered$iso.mass)) {
#     iso.massCulumnDeltat[i]<-sort(diff(as.numeric(unlist(str_split(table_filtered$iso.mass[i], pattern = ",")))))[1]
#   }
# 
#   idxMassifFalse<-which(iso.massCulumnDeltat<=0.85)
# 
#   table_filtered<-table_filtered[-idxMassifFalse,]
#   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# 
# 
# 
# 
#   ## Add column Group Info
#   table_filtered<-as.data.frame(table_filtered)
#   table_filtered$iso.mass.link<-table_filtered$iso.mass
#   table_filtered$mz_PeaksIsotopics_Group<-table_filtered$mz_PeaksIsotopics
#   table_filtered$rt_PeaksIsotopics_Group<-table_filtered$rt_PeaksIsotopics
#   table_filtered$Height_PeaksIsotopics_Group<-table_filtered$Height_PeaksIsotopics
#   table_filtered<-table_filtered[order(table_filtered$`M+H`),]
#   rownames(table_filtered)<-1:nrow(table_filtered)
# 
#   table_filtered_new<-table_filtered
# 
# 
#   rColSelected<-c("M+H","rt","rtmin","rtmax","Height","Area","SN","sample",
#                   "iso.mass","iso.mass.link","mz_PeaksIsotopics_Group", "rt_PeaksIsotopics_Group","Height_PeaksIsotopics_Group","Adduct")
# 
#   table_filtered_new<-table_filtered_new[,rColSelected]
# 
# 
# 
#   table_filtered_new<-as.data.frame(table_filtered_new)
#   rownames(table_filtered_new)<-1:nrow(table_filtered_new)
# 
#   peaks<-table_filtered_new
#   peaks[,"M+H.min"]<-peaks$`M+H`-mass_slice_width/2
#   peaks[,"M+H.max"]<-peaks$`M+H`+ mass_slice_width/2
# 
#   colSelect<-c("M+H","M+H.min","M+H.max","rt","rtmin","rtmax","Area","Height","SN","sample",
#                "iso.mass","iso.mass.link","mz_PeaksIsotopics_Group","rt_PeaksIsotopics_Group","Height_PeaksIsotopics_Group","Adduct")
#   peaks<-peaks[,colSelect]
# 
#   reqColsNames<-c('M+H','M+H.min','M+H.max','CE-time','CE-time.min','CE-time.max',
#                   'integrated-intensity','intensity', 'sn', 'sample')
# 
#   colnames(peaks)[1:10]<-reqColsNames
# 
# 
#   return(peaks)
# }
# 
# 
# 
# 
# 
# 
# 
# ####### extraction des peptides
# 
# deconv_peaks_MSDIAL<-function(path_to_peakList,
#                               file_adduct,
#                               output_directory = NULL,
#                               mass_slice_width,
#                               min_PeaksMassif,
#                               workers = ceiling((detectCores())-1)){  #min(ceiling((detectCores())-1), 4)  # Max 4 workers
# 
# 
#   message("--- DECONVOLUTION ---\n")
#   incProgress(1/8, detail = paste("Grouping peaks into massifs...", round(6/8*100,0),"%",collapse=""))
# 
# 
#   if(!require(BiocParallel))
#     stop("R package \"BiocParallel\" is required !")
#   if(!require(parallel))
#     stop("R package \"parallel\" is required !")
# 
# 
#   param <- SnowParam(workers = workers, type = "SOCK")
#   time1<-system.time(Result_Msidal<-
#                         bplapply(path_to_peakList,
#                                  ProcessPeaks.msdial,
#                                  file_adduct = file_adduct,
#                                  mass_slice_width = mass_slice_width,
#                                  min_PeaksMassif = min_PeaksMassif,
#                                  BPPARAM = param))
#   time2<-system.time(peaks_MSDIAL_mono_iso<-do.call("rbind", Result_Msidal))
#   times<-time1[[3]]+time2[[3]]
# 
#   cat(paste("Time of computing mono-isotopic peaks :",times,"... !", sep = " "))
#   if(is.null(output_directory)){
#     cat("\n Finished.\n")
# 
#     colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
#     return(peaks_MSDIAL_mono_iso)
#   } else {
#     cat("\n Save result...\n")
# 
#     for (i in 1:length(Result_Msidal)) {
#       write.table(Result_Msidal[[i]],
#                   file = file.path(output_directory,
#                                    paste0(unique(Result_Msidal[[i]]$sample),".csv")),
#                   sep = ",", row.names = FALSE)
#     }
# 
#     cat("\n Finished.\n")
#     message("--- END ANNOTATION ---")
# 
#     incProgress(1/8, detail = paste("End grouping...", round(7/8*100,0),"%",collapse=""))
# 
#     colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
# 
# 
#     return(peaks_MSDIAL_mono_iso)
#   }
# }
# 
# 
# 
# 


# autre option : 

#" Load some necessary files 
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

  # Nettoyage des dossiers temporaires laissés par un run précédent interrompu.
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
  
  # Suppression R-native d'un dossier contenant des junctions/hardlinks.
  # N'utilise PAS shell()/cmd.exe → immunisé contre l'erreur 322.
  # unlink(junction, recursive=FALSE) → RemoveDirectoryW → supprime le junction point sans suivre.
  remove_batch_dir <- function(dir_path) {
    if (!dir.exists(dir_path)) return(invisible(TRUE))
    items <- list.files(dir_path, full.names = TRUE, all.files = TRUE, no.. = TRUE)
    for (item in items) {
      if (dir.exists(item)) {
        # Distinguer junction (.d) vs vrai dossier (project_*_tmpFolder avec .pll)
        if (grepl("\\.d$", item, ignore.case = TRUE)) {
          # Junction (.d) : RemoveDirectoryW supprime le reparse point, pas le contenu cible
          unlink(item, recursive = FALSE)
        } else {
          # Vrai dossier (ex: project_*_tmpFolder contenant peaklist_*.pll)
          # → suppression récursive complète
          unlink(item, recursive = TRUE)
        }
      } else {
        # Hardlink (.mzML) ou fichier quelconque : supprime l'entrée du lien
        file.remove(item)
      }
    }
    # Le dossier batch est maintenant vide → suppression simple
    unlink(dir_path, recursive = FALSE)
    invisible(!dir.exists(dir_path))
  }
  
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
  
  run_msdial_bat <- function(expected_stems = NULL, output_dir = NULL) {
    bat_file   <- normalizePath("lib/NewReferenceMap/cmd/RunMsdialPeakPicking.bat",
                                winslash = "\\", mustWork = FALSE)
    timeout_s <- {
      t <- suppressWarnings(as.integer(timeout_sec))
      if (length(t) == 1L && !is.na(t) && t > 0L) t else 14400L
    }
    poll_interval_s <- 10L
    grace_after_complete_s <- 30L
    
    if (.Platform$OS.type == "windows") {
      # Fichier sentinelle : le .bat écrira "DONE" dedans en terminant.
      # Ceci permet de détecter la fin du processus SANS spawner de subprocess.
      sentinel <- tempfile(fileext = "_msdial_done.flag")
      
      # Créer un wrapper .bat qui exécute le vrai .bat puis crée la sentinelle
      wrapper_bat <- tempfile(fileext = "_msdial_wrapper.bat")
      writeLines(c(
        "@echo off",
        paste0('call "', bat_file, '"'),
        paste0('echo DONE > "', normalizePath(sentinel, winslash = "\\", mustWork = FALSE), '"')
      ), wrapper_bat)
      
      # Lancer le wrapper en arrière-plan via shell(wait=FALSE) — un seul appel cmd.exe
      # shell() avec wait=FALSE lance le process et retourne immédiatement
      shell(paste0('"', normalizePath(wrapper_bat, winslash = "\\"), '"'),
            wait = FALSE, mustWork = FALSE)
      
      message(sprintf("--- MsdialConsoleApp lancé, timeout %ds ---", timeout_s))
      
      start_time <- proc.time()[["elapsed"]]
      completed_early <- FALSE
      
      while (TRUE) {
        elapsed <- proc.time()[["elapsed"]] - start_time
        
        # 1. Timeout absolu
        if (elapsed >= timeout_s) {
          message(sprintf("TIMEOUT: MsdialConsoleApp arrêté après %ds", round(elapsed)))
          tryCatch(
            system2("taskkill", args = c("/F", "/IM", "MsdialConsoleApp.exe"),
                    stdout = FALSE, stderr = FALSE, wait = TRUE),
            error = function(e) NULL
          )
          break
        }
        
        # 2. Le processus s'est terminé naturellement (sentinelle créée)
        if (file.exists(sentinel)) {
          message(sprintf("--- MsdialConsoleApp terminé naturellement après %.0fs ---", elapsed))
          break
        }
        
        # 3. Arrêt anticipé : tous les .msdial attendus sont présents et stables
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
  
  # -- Déterminer les échantillons restants à traiter --
  # Source de vérité 1 : CSV dans output_files (Massif-List/).
  #   Un CSV n'existe que si la déconvolution a été menée jusqu'au bout. 
  existing_csv <- list.files(output_files, pattern = "\\.csv$",
                             full.names = FALSE, ignore.case = TRUE)
  done_stems   <- tolower(sub("\\.csv$", "", existing_csv, ignore.case = TRUE))
  
  # Source de vérité 2 : cache persistant inter-session dans input_dir.
  #   Écrit par le serveur après chaque déconvolution réussie ; survive aux changements de projet.
  cache_file <- file.path(input_dir, ".msdial_processed_cache.txt")
  if (file.exists(cache_file)) {
    cached       <- tolower(trimws(readLines(cache_file, warn = FALSE)))
    cache_stems  <- sub("\\.(d|mzML)$", "", cached[nzchar(cached)], ignore.case = TRUE)
    done_stems   <- unique(c(done_stems, cache_stems))
  }
  
  input_stems <- tolower(sub("\\.(d|mzML)$", "", basename(input_items), ignore.case = TRUE))
  to_process  <- input_items[!(input_stems %in% done_stems)]
  
  batch_size <- suppressWarnings(as.integer(batch_size))
  cat("batch_size  :  ", batch_size , "\n")
  if (length(batch_size) != 1L || is.na(batch_size)) batch_size <- NA_integer_
  # batch_size <- if(is.null(batch_size)) NA else batch_size
  if (!is.na(batch_size) && batch_size > 0) {
    if (length(to_process) == 0) {
      message("--- Tous les échantillons déjà traités (cache) — peak picking ignoré ---")
      return(invisible(NULL))
    }
    
    n_batches  <- ceiling(length(to_process) / batch_size)
    batch_root <- file.path(input_dir, "_msdial_batches_tmp")
    dir.create(batch_root, recursive = TRUE, showWarnings = FALSE)
    
    # Crée des junctions (.d) ou hard links (.mzML) pointant vers les originaux.
    # Les données ne quittent JAMAIS input_dir → ZÉRO risque de perte.
    #   - junction  : supprime le lien, pas le contenu cible
    #   - hard link : supprime l'entrée, l'original conserve sa référence
    make_batch_links <- function(items, dest_dir) {
      vapply(seq_along(items), function(i) {
        item_w <- normalizePath(items[i], winslash = "\\", mustWork = FALSE)
        link_w <- normalizePath(file.path(dest_dir, basename(items[i])),
                                winslash = "\\", mustWork = FALSE)
        if (dir.exists(items[i])) {
          # .d = dossier → junction (mklink /J). Nécessite shell() mais c'est
          # exécuté AVANT MS-DIAL (système sain, pas d'erreur 322 à ce stade).
          cmd <- paste0('mklink /J "', link_w, '" "', item_w, '"')
          shell(cmd, mustWork = FALSE, intern = TRUE)
        } else {
          # .mzML = fichier → hard link R-natif (aucun subprocess)
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
          warning(sprintf("Batch %d/%d : %d lien(s) non créé(s) → ignoré(s) : %s",
                          b, n_batches, sum(!linked),
                          paste(basename(batch_items[!linked]), collapse = ", ")))
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
      
      # Nettoyage R-natif (aucun subprocess → pas d'erreur 322)
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
  
  # -------------------------------------------------------------------------
  # VÉRIFICATION FINALE : détection automatique des échantillons sans CSV
  # -------------------------------------------------------------------------
  # Après tous les batches, on relit les CSV produits + le cache pour
  # identifier les mzML qui n'ont toujours pas de CSV correspondant.
  # Si des manquants existent → on les retraite par batch de 50 jusqu'à
  # ce que tous soient traités (max 3 tentatives pour éviter boucle infinie).
  if (is.function(after_batch_fun)) {
    max_recovery_rounds <- 3L
    for (round_i in seq_len(max_recovery_rounds)) {
      # Recalculer les done_stems à partir des CSV ET du cache (état actuel)
      csv_now     <- list.files(output_files, pattern = "\\.csv$",
                                full.names = FALSE, ignore.case = TRUE)
      done_now    <- tolower(sub("\\.csv$", "", csv_now, ignore.case = TRUE))
      if (file.exists(cache_file)) {
        cached_now  <- tolower(trimws(readLines(cache_file, warn = FALSE)))
        cache_now   <- sub("\\.(d|mzML)$", "", cached_now[nzchar(cached_now)],
                           ignore.case = TRUE)
        done_now    <- unique(c(done_now, cache_now))
      }
      # Tous les mzML/d disponibles dans le dossier source
      all_inputs  <- list.files(input_dir, full.names = TRUE, recursive = FALSE)
      all_inputs  <- all_inputs[grepl("\\.d$|\\.mzML$", basename(all_inputs), ignore.case = TRUE)]
      all_stems   <- tolower(sub("\\.(d|mzML)$", "", basename(all_inputs), ignore.case = TRUE))
      missing     <- all_inputs[!(all_stems %in% done_now)]
      
      if (length(missing) == 0) {
        message(sprintf("--- Vérification finale (tour %d) : tous les échantillons ont un CSV ✓ ---",
                        round_i))
        break
      }
      
      message(sprintf(
        "--- Vérification finale (tour %d/%d) : %d échantillon(s) sans CSV → retraitement par batch ---",
        round_i, max_recovery_rounds, length(missing)))
      
      # Retraiter les manquants par batch de 50
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
          if (!all(linked_rb)) {
            warning(sprintf("Recovery batch %d : %d lien(s) non créé(s) → ignoré(s) : %s",
                            rb, sum(!linked_rb),
                            paste(basename(rb_items[!linked_rb]), collapse = ", ")))
          }
          effective_rb <- rb_items[linked_rb]
        } else {
          for (item in rb_items) file.symlink(item, file.path(rb_dir, basename(item)))
          effective_rb <- rb_items
        }
        
        if (length(effective_rb) == 0) {
          message(sprintf("--- Recovery batch %d/%d : aucun lien créé, batch ignoré ---", rb, n_rec))
          next
        }
        
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
          message(sprintf("--- Vérification finale batch %d/%d : déconvolution de %d fichier(s) ---",
                          rb, n_rec, length(new_msdial_rec)))
          after_batch_fun(new_msdial_rec)
        }
        gc()
      }
      if (dir.exists(rec_root)) remove_batch_dir(rec_root)
    }
  }
  
  message("--- END PEAK PICKING ---\n")
  
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
  
  if (nrow(peaks.msdial_read) == 0) {
    message(sprintf("Fichier .msdial sans pic détecté : %s — résultat vide retourné.",
                    basename(path.peaks.msdial)))
    empty_peaks <- data.frame(
      `M+H` = numeric(0), `M+H.min` = numeric(0), `M+H.max` = numeric(0),
      `CE-time` = numeric(0), `CE-time.min` = numeric(0), `CE-time.max` = numeric(0),
      `integrated-intensity` = numeric(0), intensity = numeric(0), sn = numeric(0),
      sample = character(0), iso.mass = character(0), iso.mass.link = character(0),
      mz_PeaksIsotopics_Group = character(0), rt_PeaksIsotopics_Group = character(0),
      Height_PeaksIsotopics_Group = character(0), Adduct = character(0),
      check.names = FALSE
    )
    return(empty_peaks)
  }
  
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
    message(sprintf("Aucun massif isotopique dans %s — résultat vide retourné.",
                    basename(path.peaks.msdial)))
    empty_peaks <- data.frame(
      `M+H` = numeric(0), `M+H.min` = numeric(0), `M+H.max` = numeric(0),
      `CE-time` = numeric(0), `CE-time.min` = numeric(0), `CE-time.max` = numeric(0),
      `integrated-intensity` = numeric(0), intensity = numeric(0), sn = numeric(0),
      sample = character(0), iso.mass = character(0), iso.mass.link = character(0),
      mz_PeaksIsotopics_Group = character(0), rt_PeaksIsotopics_Group = character(0),
      Height_PeaksIsotopics_Group = character(0), Adduct = character(0),
      check.names = FALSE
    )
    return(empty_peaks)
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
  
  pb_filterMassif <- txtProgressBar(min=0, max = nrow(table_filtered), style = 3)
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
  
  if (nrow(table_filtered) == 0) {
    message(sprintf("Tous les massifs filtrés dans %s (min_PeaksMassif) — résultat vide retourné.",
                    basename(path.peaks.msdial)))
    empty_peaks <- data.frame(
      `M+H` = numeric(0), `M+H.min` = numeric(0), `M+H.max` = numeric(0),
      `CE-time` = numeric(0), `CE-time.min` = numeric(0), `CE-time.max` = numeric(0),
      `integrated-intensity` = numeric(0), intensity = numeric(0), sn = numeric(0),
      sample = character(0), iso.mass = character(0), iso.mass.link = character(0),
      mz_PeaksIsotopics_Group = character(0), rt_PeaksIsotopics_Group = character(0),
      Height_PeaksIsotopics_Group = character(0), Adduct = character(0),
      check.names = FALSE
    )
    return(empty_peaks)
  }
  
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
  
  pb4 <- txtProgressBar(min=0, max = nrow(table_filtered), style = 3)
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
  
  
  
  # Tentative parallèle (SnowParam/SOCK) avec fallback séquentiel (SerialParam)
  # pour éviter le blocage infini de socketConnection() après épuisement des
  # ressources système (erreur 322 / DLL init failures).
  Result_Msidal <- NULL
  times <- 0
  parallel_ok <- FALSE
  
  tryCatch({
    param <- SnowParam(workers = workers, type = "SOCK", timeout = 120)
    tryCatch({
      time1 <- system.time(Result_Msidal <-
                             bplapply(path_to_peakList,
                                      ProcessPeaks.msdial,
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
    message(sprintf("--- Parallélisation SOCK échouée : %s ---", conditionMessage(e)))
    message("--- Fallback vers traitement séquentiel (SerialParam) ---")
  })
  
  if (!parallel_ok || is.null(Result_Msidal)) {
    message("--- Déconvolution séquentielle en cours... ---")
    param_serial <- SerialParam()
    time1 <- system.time(Result_Msidal <-
                           bplapply(path_to_peakList,
                                    ProcessPeaks.msdial,
                                    file_adduct = file_adduct,
                                    mass_slice_width = mass_slice_width,
                                    min_PeaksMassif = min_PeaksMassif,
                                    BPPARAM = param_serial))
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
    
    incProgress(1/8, detail = paste("End grouping...", round(7/8*100,0),"%",collapse=""))
    
    colnames(peaks_MSDIAL_mono_iso)[c(1:10)]<-c("mz","mzmin","mzmax","rt","rtmin","rtmax","into","maxo","sn","sample")
    
    
    return(peaks_MSDIAL_mono_iso)
  }
}
