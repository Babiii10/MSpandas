##" Load some necessary files 
source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')



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
                           shinyProgressData=NULL){
  
  
  
  
  
  # shiny progressBar
  if (!is.null(shinyProgressData)) {
    if (!require(shinyWidgets)) {
      warning("R package shinyWidgets not present... Disabling progress ",
              "bar...",immediate.=TRUE)
      shinyProgressData <- NULL
    }
  }
  
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
  
  findPeaksMsdial(input_files = input_files, output_files = output_files, output_export_param = output_export_param )
  # Fix: Use normalizePath and shell for Windows 11 compatibility
  bat_file <- normalizePath("lib/AnalysisNewSample/cmd/RunMsdialPeakPicking.bat", winslash = "\\", mustWork = FALSE)
  if (.Platform$OS.type == "windows") {
    system2("cmd.exe", args = c("/c", shQuote(bat_file)), stdout = TRUE, stderr = TRUE, wait = TRUE)
  } else {
    system2(bat_file)
  }


  message("--- EDN PEAK PICKING ---\n")
  
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
  # OPTIMIZED: Using vectorized operations with parallel backend
  cat("Compute number of isotope and, sum Height and Area within an isotope massif...4/6 \n")

  # Prepare the computation using parallel processing for large datasets
  if (nrow(table_filtered) > 50) {
    # Use parallel processing for larger datasets
    if (!require(parallel)) {
      cat("Package 'parallel' not available, using sequential processing\n")
      use_parallel <- FALSE
    } else {
      use_parallel <- TRUE
      n_cores <- max(1, detectCores() - 1)
      cat(paste("Using", n_cores, "cores for isotope computation...\n"))
    }

    if (use_parallel) {
      # Create cluster
      cl <- makeCluster(n_cores)
      clusterExport(cl, c("x", "table_filtered"), envir = environment())
      clusterEvalQ(cl, library(dplyr))
      clusterEvalQ(cl, library(stringr))

      # Process in parallel
      pb7 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
      results <- parLapply(cl, 1:nrow(table_filtered), function(i) {
        mz_iso <- toString(c(table_filtered[i,"Precursor.mz"],
                            toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"mz_PeaksIsotopics_group"][[1]])))
        rt_iso <- toString(c(table_filtered[i,"rt"],
                            toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"rt_PeaksIsotopics_group"][[1]])))
        height_iso <- toString(c(table_filtered[i,"Height"],
                                toString(x[which(x$isotope==table_filtered[i,"PeakID"]),"Height_PeaksIsotopics_group"][[1]])))
        nb_iso <- x[which(x$isotope==table_filtered[i,"PeakID"]),"nb_isotope"][[1]]+1
        height_sum <- table_filtered[i,"Height"] + x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Height"][[1]]
        area_sum <- table_filtered[i,"Area"] + x[which(x$isotope==table_filtered[i,"PeakID"]),"somme_Area"][[1]]

        list(mz_iso = mz_iso, rt_iso = rt_iso, height_iso = height_iso,
             nb_iso = nb_iso, height_sum = height_sum, area_sum = area_sum)
      })
      close(pb7)
      stopCluster(cl)

      # Apply results back to table_filtered
      for (i in 1:nrow(table_filtered)) {
        table_filtered[i,"mz_PeaksIsotopics"] <- results[[i]]$mz_iso
        table_filtered[i,"rt_PeaksIsotopics"] <- results[[i]]$rt_iso
        table_filtered[i,"Height_PeaksIsotopics"] <- results[[i]]$height_iso
        table_filtered[i,"nb_isotope"] <- results[[i]]$nb_iso
        table_filtered[i,"Height"] <- results[[i]]$height_sum
        table_filtered[i,"Area"] <- results[[i]]$area_sum
      }
    } else {
      # Fallback to sequential
      pb7 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
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
    }
  } else {
    # For small datasets, use sequential processing
    pb7 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
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
  }
  
  
  ### Filter Massif - OPTIMIZED with vectorized operations

  cat("Filter massif...4/6 (vectorized)\n")
  ## Filter massif using vectorized operations

  # Vectorized computation of peak counts
  peak_counts <- sapply(table_filtered[,"mz_PeaksIsotopics"], function(x) {
    length(as.numeric(unlist(str_split(x, pattern = ","))))
  })

  # Vectorized filtering logic
  idxDeleteMassifTowPeaks <- which(peak_counts < min_PeaksMassif)

  idxDeleteCharge4 <- which(table_filtered$charge == 4 & peak_counts < 3)

  idxDeleteCharge5 <- which(table_filtered$charge >= 5 & peak_counts < 4)
  
  idxDelete<-c(idxDeleteCharge4,idxDeleteCharge5,idxDeleteMassifTowPeaks)
  idxDelete<-idxDelete[!is.na(idxDelete)]
  
  table_filtered<-table_filtered[-idxDelete,]
  
  
  #Compute mz without adduct - OPTIMIZED with parallel processing

  cat("Computing M+H ... 5/6 \n")
  adduct <-read.csv(file_adduct)

  adduct_extracted <- str_extract(table_filtered[,"Adduct"],"\\[[[:alnum:]]+\\+[[:alnum:]]+\\]")
  adduct_number <- as.numeric(ifelse(is.na(str_extract(adduct_extracted,"[:digit:]"))==FALSE,str_extract(adduct_extracted,"[:digit:]"),1))
  adduct_extracted <- str_replace_all(table_filtered[,"Adduct"],"[:digit:]","")

  # Use parallel processing for large datasets
  if (nrow(table_filtered) > 100) {
    if (!require(parallel)) {
      cat("Package 'parallel' not available, using sequential processing\n")
      use_parallel_mh <- FALSE
    } else {
      use_parallel_mh <- TRUE
      n_cores <- max(1, detectCores() - 1)
      cat(paste("Using", n_cores, "cores for M+H computation...\n"))
    }

    if (use_parallel_mh) {
      # Create cluster
      cl <- makeCluster(n_cores)
      clusterExport(cl, c("adduct", "table_filtered", "adduct_extracted", "adduct_number"), envir = environment())
      clusterEvalQ(cl, library(stringr))

      # Process in parallel
      pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
      results <- parLapply(cl, 1:nrow(table_filtered), function(i) {
        massdiff_val <- adduct[which(adduct$name == adduct_extracted[i]), "massdiff"]
        charge_val <- table_filtered[i, "charge"]
        precursor_mz <- table_filtered[i, "Precursor.mz"]
        adduct_num <- adduct_number[i]

        mh_val <- (precursor_mz - massdiff_val / charge_val * adduct_num) * charge_val + 1.007276

        mz_peaks <- as.numeric(unlist(str_split(table_filtered[i, "mz_PeaksIsotopics"], pattern = ",")))
        iso_mass_val <- toString((mz_peaks - massdiff_val / charge_val * adduct_num) * charge_val + 1.007276)

        list(mh = mh_val, iso_mass = iso_mass_val)
      })
      close(pb4)
      stopCluster(cl)

      # Apply results
      for (i in 1:nrow(table_filtered)) {
        table_filtered[i, "M+H"] <- results[[i]]$mh
        table_filtered[i, "iso.mass"] <- results[[i]]$iso_mass
      }
    } else {
      # Fallback to sequential
      pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
      for (i in 1:nrow(table_filtered)){
        setTxtProgressBar(pb4, i)
        table_filtered[i,"M+H"] <- (table_filtered[i,"Precursor.mz"] - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276
        table_filtered[i,"iso.mass"] <- toString((as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))) - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276)
      }
      close(pb4)
    }
  } else {
    # For small datasets, use sequential
    pb4 <- txtProgressBar(min=1, max = nrow(table_filtered), style = 3)
    for (i in 1:nrow(table_filtered)){
      setTxtProgressBar(pb4, i)
      table_filtered[i,"M+H"] <- (table_filtered[i,"Precursor.mz"] - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276
      table_filtered[i,"iso.mass"] <- toString((as.numeric(unlist(str_split(table_filtered[i,"mz_PeaksIsotopics"], pattern = ","))) - adduct[which(adduct$name==adduct_extracted[i]),"massdiff"]/table_filtered[i,"charge"]*adduct_number[i])*table_filtered[i,]$charge+1.007276)
    }
    close(pb4)
  }
  
  
  
  # sum intensity adduct to pic mono-isotopic
  
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
  
  cat("Processing...\n")
  table_filtered <- table_filtered %>% 
    dplyr::rowwise() %>% 
    dplyr::mutate(Height=somme_intensite_height(Comment,Height,Area)[[1]],
                  Area=somme_intensite_height(Comment,Height,Area)[[2]])
  
  
  
  
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
  
  
  param <- SnowParam(workers = workers, type = "SOCK")
  time1<-system.time(Result_Msidal<-
                       bplapply(path_to_peakList,
                                ProcessPeaks.msdial.NewSample,
                                file_adduct = file_adduct,
                                mass_slice_width = mass_slice_width,
                                min_PeaksMassif = min_PeaksMassif,
                                BPPARAM = param))
  time2<-system.time(peaks_MSDIAL_mono_iso<-do.call("rbind", Result_Msidal))
  times<-time1[[3]]+time2[[3]]
  
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
