
##" Initialize reactive values
RvarsPeakDetection<-allReactiveVarsNewRefMap$PeakDetection

## Get directory for raw data



observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$directory_rawData_NewRefMap
    },
  handlerExpr = {
    if (input$directory_rawData_NewRefMap > 0) {
      
      # condition prevents handler execution on initial app launch
      # launch the directory selection dialog with initial path read from the widget
      RvarsPeakDetection$directory_rawData = choose.dir(default = readDirectoryInput(session, 'directory_rawData_NewRefMap'))
      RvarsPeakDetection$directory_rawData = str_replace_all(req(RvarsPeakDetection$directory_rawData),
                                                   pattern =  "\\\\", replacement  = "/")
      # update the widget value
      updateDirectoryInput(session, 'directory_rawData_NewRefMap', value = req(RvarsPeakDetection$directory_rawData))
    } 
    
    
  })



# Populate the "resume" dropdown dynamically.
# Lists all subdirectories of directory_rawData whose name starts with
# "<projectName>_", sorted most-recent first (timestamp suffix → reverse alpha).
output$ui_existingProjects_NewRefMap <- renderUI({
  req(input$resumeMode_NewRefMap == "resume")
  raw_dir   <- req(RvarsPeakDetection$directory_rawData)
  base_name <- trimws(input$projectName_NewRefMap)
  req(nzchar(base_name))

  all_dirs <- list.dirs(raw_dir, recursive = FALSE, full.names = FALSE)
  matching <- sort(
    all_dirs[startsWith(all_dirs, paste0(base_name, "_"))],
    decreasing = TRUE   # most recent timestamp first
  )

  if (length(matching) == 0) {
    return(tagList(
      tags$p(
        style = "color:#a94442; font-style:italic;",
        paste0('No existing project found for "', base_name, '".')
      )
    ))
  }

  selectInput(
    inputId  = "selectedProject_NewRefMap",
    label    = "Select project to resume:",
    choices  = matching,
    selected = matching[1],
    width    = "100%"
  )
})


observe({
  toggleState(id = "MS2_type_NewRefMap",
              condition = input$dataType_NewRefMap == "MS2")
  RvarsPeakDetection$paramMsdial_ref_path<-file.path("lib/NewReferenceMap/parameters","paramMsdial.txt")

})


#Reset all parameters peak detection to default when switch to Default
observe({
  if(length(input$peakDetectionParameters_NewRefMap)!=0){
    
    if(input$peakDetectionParameters_NewRefMap=="defaults") {
      
      updateNumericInput(session = session,
                         inputId = "mz_tolerance_centroid_MS1_NewRefMap",
                         value = 0.01)
      updateNumericInput(session = session,
                         inputId = "mz_tolerance_centroid_MS2_NewRefMap",
                         value = 0.025)
      updateNumericInput(session = session,
                         inputId = "mass_slice_width_NewRefMap",
                         value = 0.05)
      updateSelectInput(session = session,
                        inputId = "Adduct_list_NewRefMap",
                        selected=list("[M+H]+",
                                      "[M+Na]+",
                                      "[M+K]+"))
      updateNumericInput(session = session,
                         inputId = "maxCharge_NewRefMap",
                         value = 8)
      updateNumericInput(session = session,
                         inputId = "min_Peakwidth_NewRefMap",
                         value = 4)
      updateNumericInput(session = session,
                         inputId = "min_PeakHeight_NewRefMap",
                         value = 1000)
      updateNumericInput(session = session,
                         inputId = "minPeaksMassif_NewRefMap",
                         value = 2)
    }
    
  }
})

observe({
  
  if(length(input$IdDataType_NewRefMap)!=0){
    
    if(input$IdDataType_NewRefMap=="defaults") {
      
      
      updateSelectInput(session = session,
                        inputId = "MS1_type_NewRefMap",
                        selected="Profile")
      
      updateSelectInput(session = session,
                        inputId = "MS2_type_NewRefMap",
                        selected="Profile")
      
      updateRadioButtons(session = session,
                         inputId="dataType_NewRefMap",
                         selected = "MS1")
      
    }
    
  }
})

##~~~~~~~~ Size of point for the plot~~~~~~~~~~~~#
observe({
  
  if(length(input$ViewSizePoints_NewRefMap)!=0){
    
    if(input$ViewSizePoints_NewRefMap=="defaults") {
      updateSliderInput(session = session,
                        inputId = "sizePoints_NewRefMap",
                        value = 0.5)
  }
  
  
  }
})



## Calling peak picking

observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$runPeakPicking_NewRefMap
  }
  ,
  handlerExpr = {

    ### Disable some buttons when processes started
    shinyjs::disable(selector = '.navbar-nav a[data-value="Analysis new samples"')
    shinyjs::disable(selector = '.navbar-nav a[data-value="New reference map"')
    shinyjs::disable(selector = '.navbar-nav a[data-value="Database"')
    shinyjs::disable(selector = '.navbar-nav a[data-value="Statistical analysis"')
    shinyjs::disable(selector = '.navbar-nav a[data-value="Help"')
    
    disable("id_PanelImportRawData")
    disable("id_PanelDataCollection")
    disable("id_PanelParametersNewRefMap")
    
    disable("runPeakPicking_NewRefMap")
    disable("resetAll_NewRefMap")
    disable("PeakDetectionView")
    
    
    ####~~~~~~~~~~~~~~~~~~~~~~~~~~ Start process (peak detection with api MSDIAL and Grouping massif to features) ~~~~~~~~~~~~~~~~#
    ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    tryCatch(
      expr = {
        
        if(is.na(RvarsPeakDetection$directory_rawData)|| 
           (RvarsPeakDetection$directory_rawData == "")|| 
           (RvarsPeakDetection$directory_rawData == getwd())|| 
           (RvarsPeakDetection$directory_rawData == "Choose working directory") ||
           is.null(RvarsPeakDetection$directory_rawData)){
          
          message("No file .msdial...!")
          
          ### Enable button and div when processes finished
          shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
          shinyjs::hide("Id_resetAll_NewRefMap_PeakDetectionView")
          
          enable("id_PanelImportRawData")
          enable("id_PanelDataCollection")
          enable("id_PanelParametersNewRefMap")
          
          enable("runPeakPicking_NewRefMap")
          enable("resetAll_NewRefMap")
          enable("PeakDetectionView")
          
          sendSweetAlert(
            session = session,
            title = "Warning !",
            text = "There is no input MS file to be imported !",
            type = "warning"
          )
          
        } else {
          
          
          withProgress(message = 'Processing...', value = 0, {
            
            incProgress(1/8, detail = paste("starting preprocessing... ", round(1/8*100,0),"%",collapse=""))
            
            source("lib/NewReferenceMap/R_files/peakPickingNewReferenceMap.R", local = TRUE)
            source_python("lib/NewReferenceMap/Python_files/msconverter_command_line.py")
            
            
            
            ### Directory Project
            if (isTRUE(input$resumeMode_NewRefMap == "resume") &&
                !is.null(input$selectedProject_NewRefMap)        &&
                nzchar(input$selectedProject_NewRefMap)) {
              # Reprendre un projet existant : réutiliser son dossier.
              # Le cache .msdial_processed_cache.txt et la vérification des .mzML
              # garantissent que seuls les échantillons non encore traités sont retraités.
              RvarsPeakDetection$Project_NameNewRefMap <- input$selectedProject_NewRefMap
              message(sprintf("--- Reprise du projet existant : %s ---",
                              input$selectedProject_NewRefMap))
            } else {
              RvarsPeakDetection$Project_NameNewRefMap <-
                paste(req(input$projectName_NewRefMap),
                      sub(sub(sub(Sys.time(), pattern = "CEST",
                                  replacement = "",
                                  fixed = TRUE), pattern = ":",
                              replacement = "-",
                              fixed = TRUE), pattern = ":",
                          replacement = "-",
                          fixed = TRUE),
                      sep = "_")
              message(sprintf("--- Nouveau projet : %s ---",
                              RvarsPeakDetection$Project_NameNewRefMap))
            }
            
            
            ## project directory
            if(!dir.exists(file.path(req(RvarsPeakDetection$directory_rawData), req(RvarsPeakDetection$Project_NameNewRefMap)))) {
              dir.create(file.path(req(RvarsPeakDetection$directory_rawData), req(RvarsPeakDetection$Project_NameNewRefMap)))
            }
            
            ## Directory for peak list
            directoryOutput_NewRefMap<-file.path(req(RvarsPeakDetection$directory_rawData), req(RvarsPeakDetection$Project_NameNewRefMap),"Massif-List")
            if(!dir.exists(directoryOutput_NewRefMap)) {
              dir.create(directoryOutput_NewRefMap)
            }
            
            ## Directory for raw data mzML files
            RvarsPeakDetection$directory_rawDataOutput_mzML_files_NewRefMap<-file.path(req(RvarsPeakDetection$directory_rawData), req(RvarsPeakDetection$Project_NameNewRefMap), "mzML files")
            if(!dir.exists(RvarsPeakDetection$directory_rawDataOutput_mzML_files_NewRefMap)) {
              dir.create(RvarsPeakDetection$directory_rawDataOutput_mzML_files_NewRefMap)
            }
            
            
            ## Conversion des raw data en .mzML pour l'alignement des runs
            message(" \n --- Convert raw data to .mzML ---\n")
            
            
            incProgress(1/8, detail = paste("Convert raw data to .mzML...",round(2/8*100,0),"%",collapse=""))
            raw_d_runs <- list.files(req(RvarsPeakDetection$directory_rawData),
                                     pattern = "\\.d$",
                                     full.names = TRUE,
                                     ignore.case = TRUE)
            expected_mzml <- file.path(req(RvarsPeakDetection$directory_rawDataOutput_mzML_files_NewRefMap),
                                       sub("\\.d$", ".mzML", basename(raw_d_runs), ignore.case = TRUE))
            mzml_already_done <- length(raw_d_runs) > 0 && length(expected_mzml) == length(raw_d_runs) && all(file.exists(expected_mzml))

            if (!mzml_already_done) {
              system.time(convert_to_mzML(RvarsPeakDetection$directory_rawData,
                                          RvarsPeakDetection$directory_rawDataOutput_mzML_files_NewRefMap))
              system.time(system2("lib/NewReferenceMap/cmd/convert_raw_data_to_mzML_centroid.bat"))
            }
            
            message("--- End converting raw data to .mzML ---\n")
            
            
            
            ###~~~~~~~~~~~~~~~~~~~~ Peak detection~~~~~~~~~~~~~~~~~~~~~###
            
            n_input_runs <- length(list.files(req(RvarsPeakDetection$directory_rawData),
                                              pattern = "\\.d$|\\.mzML$",
                                              full.names = TRUE,
                                              ignore.case = TRUE))
            batch_size_msdial <- if (n_input_runs > 100) 50 else NULL
            timeout_sec_msdial <- if (!is.null(batch_size_msdial)) 7200 else NULL

            processed_msdial_files <- character(0)
            after_batch_fun <- function(new_msdial_files) {
              new_msdial_files <- setdiff(new_msdial_files, processed_msdial_files)
              if (length(new_msdial_files) == 0) return(invisible(NULL))
              processed_msdial_files <<- c(processed_msdial_files, new_msdial_files)

              deconv_peaks_MSDIAL(path_to_peakList = req(new_msdial_files),
                                  output_directory = directoryOutput_NewRefMap,
                                  file_adduct = "data/Adduit.csv",
                                  mass_slice_width = req(input$mass_slice_width_NewRefMap),
                                  min_PeaksMassif = req(input$minPeaksMassif_NewRefMap))
              removeFiles(path_to_files = directoryOutput_NewRefMap, ext = '.msdial')
              gc()
            }

            system.time(findPeaks_MSDIAL(input_files = req(RvarsPeakDetection$directory_rawData),
                                         output_files = req(directoryOutput_NewRefMap),
                                         #output_export_param = file.path(directoryInput$directory, rValues$Project_Name),
                                         output_export_param = "lib/NewReferenceMap/parameters",
                                         MS1_type = req(input$MS1_type_NewRefMap),
                                         MS2_type = req(input$MS2_type_NewRefMap),
                                         rt_begin = req(input$rt_begin_NewRefMap),
                                         rt_end = req(input$rt_end_NewRefMap),
                                         mz_range_begin = req(input$mz_range_begin_NewRefMap),
                                         mz_range_end = req(input$mz_range_end_NewRefMap),
                                         mz_tolerance_centroid_MS1 = req(input$mz_tolerance_centroid_MS1_NewRefMap),
                                         mz_tolerance_centroid_MS2 = req(input$mz_tolerance_centroid_MS2_NewRefMap),
                                         maxCharge = req(input$maxCharge_NewRefMap),
                                         min_Peakwidth = req(input$min_Peakwidth_NewRefMap),
                                         min_PeakHeight = req(input$min_PeakHeight_NewRefMap),
                                         mass_slice_width = req(input$mass_slice_width_NewRefMap),
                                         Adduct_list = req(input$Adduct_list_NewRefMap),
                                         batch_size = batch_size_msdial,
                                         after_batch_fun = after_batch_fun,
                                         timeout_sec = timeout_sec_msdial
            ))
            
            
            ## Remove some files 
            incProgress(1/8, detail = paste("Deleting unnecessary files..", round(5/8*100,0),"%",collapse=""))
            
            removeFiles(path_to_files = req(RvarsPeakDetection$directory_rawData),
                        ext = '.dcl')
            removeFiles(path_to_files = req(RvarsPeakDetection$directory_rawData),
                        ext = '.pai2')
            removeFiles(path_to_files = req(RvarsPeakDetection$directory_rawData),
                        ext = '.aef')
            
            ###~~~~~~~~~~~~~~~~~~~~ Grouping massif into features ~~~~~~~~~~~~~~~~~~~~~###
            
            
            path_file_msdial_NewRefMap<-file.path(directoryOutput_NewRefMap, dir(directoryOutput_NewRefMap))
            path_file_msdial_NewRefMap<-path_file_msdial_NewRefMap[grepl("\\.msdial$", path_file_msdial_NewRefMap, ignore.case = TRUE)]

            if(length(path_file_msdial_NewRefMap)>=1) {
              if(length(path_file_msdial_NewRefMap)>1) {
                file.remove(list.files(directoryOutput_NewRefMap,pattern = "AlignResult-", full.names = TRUE))
              }

              RvarsPeakDetection$peaks_MSDIAL_mono_iso_NewRefMap<- deconv_peaks_MSDIAL(path_to_peakList = req(path_file_msdial_NewRefMap),
                                                                                       output_directory = directoryOutput_NewRefMap,
                                                                                       file_adduct = "data/Adduit.csv",
                                                                                       mass_slice_width = req(input$mass_slice_width_NewRefMap),
                                                                                       min_PeaksMassif = req(input$minPeaksMassif_NewRefMap)
              )

              removeFiles(path_to_files = directoryOutput_NewRefMap,
                          ext = '.msdial')
            }
            
            
            
            message(" \n --- Preprocess complete ! ---\n")
            incProgress(1/8, detail = paste("Peaks detection and deconvolution complete !", round(8/8*100,0),"%",collapse=""))
            
            #### End Processing
            sendSweetAlert(
              session = session,
              title = "Preprocess complete !",
              text = HTML(paste('<h3> Parameters used : </h3>

                <h4>Reference map : Refrence plasma dialyse</h4>

                <h4>Mass accuracy(centroid parameter) : </h4>
                <ol style = "list-style-type: none;">
                <li>MS1 tolerance (Da) : ',req(as.character(input$mz_tolerance_centroid_MS1_NewRefMap)),'</li>
                <li>MS2 tolerance (Da) : ',req(as.character(input$mz_tolerance_centroid_MS2_NewRefMap)),'</li>
                </ol>

                <h4>Peak detection parameters : </h4>
                <ol style = "list-style-type: none;">
                <li>Mass slice width (Da) : ',req(as.character(input$mass_slice_width_NewRefMap)),' </li>
                <li>Minimum peak height (amplitude) : ',req(as.character(input$min_PeakHeight_NewRefMap)),' </li>
                <li>Minimum peak widt (scan) : ',req(as.character(input$min_Peakwidth_NewRefMap)),' </li>
                <li>Maximum charged number : ',req(as.character(input$maxCharge_NewRefMap)),'</li>
                </ol>

                <br/>
                <h3>Click OK to continue !</h3>')),
              type = "success",
              #width = "70%",
              closeOnClickOutside = FALSE,
              html = TRUE
            )
            
          })
          
          updateRadioButtons(session = session,
                             inputId = "NewRefrenceMapStep",
                             selected = "2")
          
          ### Enable button and div when processes finished
          shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
          shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
          shinyjs::show("Id_resetAll_NewRefMap_PeakDetectionView")
          
          enable("id_PanelImportRawData")
          enable("id_PanelDataCollection")
          enable("id_PanelParametersNewRefMap")
          
          enable("runPeakPicking_NewRefMap")
          enable("resetAll_NewRefMap")
          enable("PeakDetectionView")
          
          
        }
        

      },

      error = function(e) {
        message("Error")
        print(e)
        message("No file .msdial...!")

        ### Enable button and div when processes finished
        shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
        shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
        shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
        shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
        shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
        shinyjs::hide("Id_resetAll_NewRefMap_PeakDetectionView")

        enable("id_PanelImportRawData")
        enable("id_PanelDataCollection")
        enable("id_PanelParametersNewRefMap")

        enable("runPeakPicking_NewRefMap")
        enable("resetAll_NewRefMap")
        enable("PeakDetectionView")

        sendSweetAlert(
          session = session,
          title = "Warning !",
          text = "There is no input MS file to be imported !",
          type = "warning"
        )
      })
    
    
    
    
    
  
    

    
    
    
    
    
    ####~~~~~~~~~~~~~~~~~~~~~~~~~~ End process (peak detection with api MSDIAL) ~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

    
    }
  
  )




##~~~~~~~~~~~~~~~~~~~~~~ Go to peak detection viewer~~~~~~~~~~~~~~~~~~~~###
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$PeakDetectionView
  }
  ,
  handlerExpr = {
    updateRadioButtons(session = session,
                       inputId = "NewRefrenceMapStep",
                       selected = "2")
    
  })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  Reset all inputs ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(
  ignoreNULL = TRUE,
  
  eventExpr = {
    input$resetAll_NewRefMap
    
  },
  
  handlerExpr = {
    
    ask_confirmation(
      inputId = "resetAll_NewRefMap_confirmation",
      title = NULL,
      text = tags$b(
        #icon("info"),
        "Do you really want to reset all ?",
        style = "color: #FA5858;"
      ),
      btn_labels = c("Cancel", "Confirm"),
      btn_colors = c("#00BFFF", "#FE2E2E"),
      html = TRUE
    )
    
  })





# Disable some navbar element
# observe({
#   
#   shinyjs::disable(selector = '.navbar-nav a[data-value="Identification internal standards"')
#   
# })


### Get features list for all samples
peaks_mono_iso_NewRefMap<-reactive({
  if(!is.null(RvarsPeakDetection$peaks_MSDIAL_mono_iso_NewRefMap)) {
    peaks_mono_iso<-RvarsPeakDetection$peaks_MSDIAL_mono_iso_NewRefMap
    colnames(peaks_mono_iso)[c(1,8)]<-c("mz","intensity")
    peaks_mono_iso$intensity<-log2(peaks_mono_iso$intensity)
    peaks_mono_iso
    
  }
})


observe({
  
  if(!is.null(peaks_mono_iso_NewRefMap())){
    
    RvarsPeakDetection$sample_name_NewRefMap<-unique(peaks_mono_iso_NewRefMap()$sample)
    
    updatePickerInput(session = session,
                      inputId = "levelSample_NewRefMap",
                      choices = req(RvarsPeakDetection$sample_name_NewRefMap),
                      selected = req(RvarsPeakDetection$sample_name_NewRefMap[1]))
    
    updatePickerInput(session = session,
                      inputId = "IncludeSample_NewRefMap",
                      choices = RvarsPeakDetection$sample_name_NewRefMap,
                      selected = RvarsPeakDetection$sample_name_NewRefMap)
    
    
  }
})


peaks_mono_iso_NewRefMap_toPlot<-reactive({
  
  if(!is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    values_plot<-peaks_mono_iso_NewRefMap()[peaks_mono_iso_NewRefMap()$sample %in% req(input$levelSample_NewRefMap),]
    colnames(values_plot)[c(1,4)]<-c("M.H","CE.time")
    
    j<-1
    for (names in unique(values_plot$sample)) {
      values_plot[values_plot$sample==names, "sample"]<-j
      j<-j+1
    }
    
    values_plot
    
  }
  
})

#######~~~~~~~~~~~~~~~~~ Conversion time min or second ~~~~~~~~~~~~~~~~~~~##



observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$levelSample_NewRefMap
  },
  handlerExpr = {
    RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-req(peaks_mono_iso_NewRefMap_toPlot())
    #Because les data viennent initialement en second
    RvarsPeakDetection$Second <- TRUE
    if(input$UnitTime_NewRefMap=="Minute"){
      print(paste("Convert to min",input$UnitTime_NewRefMap=="Minute" & RvarsPeakDetection$Second == TRUE))
      if(input$UnitTime_NewRefMap=="Minute" & RvarsPeakDetection$Second == TRUE){
        if(!is.null(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)){
          RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time<-
            req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time)/60
          RvarsPeakDetection$Second<-FALSE
        }
      }
    }
    
  })



observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$massif_list_NewRefMap
  },
  handlerExpr = {
    # #Because initially in second
    
    updateRadioGroupButtons(
      session = session,
      inputId = "UnitTime_NewRefMap",
      selected = "Second")
    RvarsPeakDetection$Second <- TRUE
    ## reset coord_cartesian
    rangesZoomPeakMonoIso$x <- NULL
    rangesZoomPeakMonoIso$y <- NULL
    
  })


observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$UnitTime_NewRefMap
  },
  handlerExpr = {
    
    RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-req(peaks_mono_iso_NewRefMap_toPlot())
    print(paste("Convert to min",input$UnitTime_NewRefMap=="Minute" & RvarsPeakDetection$Second == TRUE))
    if(input$UnitTime_NewRefMap=="Minute" & RvarsPeakDetection$Second == TRUE){
      if(!is.null(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)){
        RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time<-
          req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time)/60
        RvarsPeakDetection$Second<-FALSE
      }
    }
    
    print(paste("Covert to Second",input$UnitTime_NewRefMap=="Second" & RvarsPeakDetection$Second == FALSE))
    if(input$UnitTime_NewRefMap=="Second" & RvarsPeakDetection$Second == FALSE){
      if(!is.null(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)){
        RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time<-
          req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$CE.time)*60
        RvarsPeakDetection$Second<-TRUE
      }
    }
    
    if(input$UnitTime_NewRefMap=="Second" & RvarsPeakDetection$Second == TRUE){
      RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-req(peaks_mono_iso_NewRefMap_toPlot())
    }
    
    
  })

## Number of peaks detected for each sample
number_of_features_NewRefMap<-reactive({
  if(length(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    table(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample)
    
  }
})

legend_sample_NewRefMap<-reactive({
  if(length(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    legend_values<-data.frame(xd = 1:length(input$levelSample_NewRefMap),
                              yd = 1:length(input$levelSample_NewRefMap),
                              Samples = paste("\n",1:length(input$levelSample_NewRefMap),": ",input$levelSample_NewRefMap,"\n", sep = ""))
    legend_values
  }
  
})


rangesZoomPeakMonoIso<- reactiveValues(x = NULL, y = NULL)

# When a double-click happens, check if there's a brush on the plot.
# If so, zoom to the brush bounds; if not, reset the zoom.
observeEvent({input$peakMonoIsoPlot_dblclick},{
  brush <- input$peakMonoIsoPlot_brush
  if (!is.null(brush)) {
    rangesZoomPeakMonoIso$x <- c(brush$xmin, brush$xmax)
    rangesZoomPeakMonoIso$y <- c(brush$ymin, brush$ymax)
    
  } else {
    ## reset coord_cartesian
    rangesZoomPeakMonoIso$x <- NULL
    rangesZoomPeakMonoIso$y <- NULL
  }
})


output$PeaksMonoIsoPlotSamplesSelected<-renderPlot({
  
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))>1 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    myPlot_NewRefMap<-req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime) %>%
      
      ggplot() +
      aes(x = CE.time, y = M.H, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints) +
      geom_point(size = req(input$sizePoints_NewRefMap)) +
      scale_color_viridis_c(option = "inferno", direction = -1) +
      theme_gray() +
      facet_grid(vars(sample), vars())  +
      coord_cartesian(xlim = rangesZoomPeakMonoIso$x, ylim = rangesZoomPeakMonoIso$y, expand = TRUE)+
      ylab("Mass (M+H) (Da)") +
      xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
      
      #ggtitle(paste("Nubmer of features :", number_of_features()))+
      
      scale_x_continuous(n.breaks = 14)+
      #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
      
      
      #facet_grid(vars(sample), vars())+
      #option_graphe.2 +
      theme_ben() +
      labs(colour ="log2 Intensity")+
      theme(plot.title = element_text(size = rel(1),
                                      face = "bold",
                                      color = "blue",
                                      margin = margin(0,0,5,0), hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            panel.border = element_rect(fill = "transparent", # Needed to add the border
                                        color = "blue",
                                        linewidth = 0.5,
                                        linetype = "dashed"),
            plot.background = element_rect(fill = "aliceblue"))
    
    
    
    
  }
  
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))==1 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    myPlot_NewRefMap<-req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime) %>%
      
      ggplot() +
      aes(x = CE.time, y = M.H, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
      geom_point(size = input$sizePoints_NewRefMap) +
      scale_color_viridis_c(option = "inferno", direction = -1) +
      ylab("Mass (M+H) (Da)") +
      xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
      coord_cartesian(xlim = rangesZoomPeakMonoIso$x, ylim = rangesZoomPeakMonoIso$y, expand = TRUE)+
      #ggtitle(paste(" :", number_of_features()))+
      scale_x_continuous(n.breaks = 14)+
      #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
      
      
      #facet_grid(vars(sample), vars())+
      #option_graphe.3
      theme_ben() +
      labs(colour ="log2 Intensity")+
      theme(plot.title = element_text(size = rel(1),
                                      face = "bold",
                                      color = "blue",
                                      margin = margin(0,0,5,0), hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            plot.background = element_rect(fill = "aliceblue"))
  }
  
  Values_myPlot_NewRefMap<-reactive({
    myPlot_NewRefMap
  })
  
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    shinyjs::show("PeaksMonoIsoPlot_id")
    Values_myPlot_NewRefMap()
    
  }
  
  
})

### Position mouse
output$PeaksMonoIsoPlot_info <- renderText({
  paste0("Mouse position : CE-time = ", round(req(input$peakMonoIsoPlot_click$x),0)," (",input$UnitTime_NewRefMap,"), ",
         " M+H = ", round(req(input$peakMonoIsoPlot_click$y),4)," (Da)")
})


#### info-bulle
output$PeaksMonoIsoPlot_hover_info <- renderUI({
  hover <- req(input$PeaksMonoIsoPlot_hover)
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))>1 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    myPlot_data_NewRefMap<-req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)
  }
  
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))==1 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    myPlot_data_NewRefMap<-req(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime)
  }
  
  Values_myPlot_data_NewRefMap<-reactive({
    myPlot_data_NewRefMap
  })
  
  if(length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    
    point <-suppressWarnings(nearPoints(req(Values_myPlot_data_NewRefMap()), hover, threshold = 5, maxpoints = 1, addDist = TRUE))
    if (nrow(point) == 0) return(NULL)
    
    # calculate point position INSIDE the image as percent of total dimensions
    # from left (horizontal) and from top (vertical)
    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    # calculate distance from left and bottom side of the picture in pixels
    left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
    top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
    
    # create style property fot tooltip
    # background color is set so tooltip is a bit transparent
    # z-index is set so we are sure are tooltip will be on top
    style <- paste0("position:absolute; z-index:100; background-color: #760001; color:white;",
                    "left:", left_px + 2, "px; top:", top_px + 2, "px;")
    
    # actual tooltip created as wellPanel
    div(
      class = "well well-sm",
      style = style,
      p(HTML(paste0(
        "<span class='bullText'> M+H: </span>", round(point$M.H,4), "<br/>",
        "<span class='bullText'> CE-time: </span>", round(point$CE.time,2), "<br/>",
        
        "<span class='bullText'> log2 Intensity: </span>", round(point$intensity,2), "<br/>",
        "<span class='bullText'> Intensity: </span>", round(2^(point$intensity),0), "<br/>"
      )))
    )
    
  }
  
  
})



output$NumberOfFeatures_NewRefMap<-renderPlot({
  if(length(number_of_features_NewRefMap())>0 & length(unique(RvarsPeakDetection$peaks_mono_iso_NewRefMap_toPlot_ConvertTime$sample))>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$levelSample_NewRefMap)){
    NbPeak_for_each_sample_adj<-data.frame(number_of_features_NewRefMap())
    colnames(NbPeak_for_each_sample_adj)[1]<-"Sample"
    ggplot(NbPeak_for_each_sample_adj) +
      aes(
        x = Sample,
        #colour = sample,
        weight = Freq
      ) +
      geom_bar(width = 0.4,fill = "#4682B4") +
      geom_text(aes(label = paste0(round(..count..,2))),
                stat = "count", vjust = 0, hjust = 0.5, size = 5,fontface = 4)+
      scale_color_hue(direction = 1) +
      #coord_flip() +
      ylab("Number of massif")+
      xlab("samples")+
      ggtitle(paste("Number of Feature for each sample"))+
      coord_cartesian(ylim = c(0,max(NbPeak_for_each_sample_adj$Freq)+1000))+
      theme_ben()+
      #theme(axis.text.x = element_text(angle = 90, size = rel(1), face = "bold"))
      theme(axis.text.x = element_text(size = rel(1.2), face = "bold"),
            axis.title.y = element_text(size = rel(0.85), face = "bold.italic"),
            plot.title = element_text(size = rel(0.9), face = "bold", color = "#760001", margin = margin(0,0,5,0), hjust = 0.5))
    
  }
  
})


output$legend_samppleOutput_NewRefMap<-renderText({legend_sample_NewRefMap()$Samples})



### Return to peak detection
observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$returnAnalysis_NewRefMap
  }
  ,
  handlerExpr = {
    updateRadioButtons(session = session,
                       inputId = "NewRefrenceMapStep",
                       selected = "1")
    
    shinyjs::show(id = "Id_resetAll_NewRefMap_PeakDetectionView")
  })

## Go to Alignement and grouping peaks mono-iso
observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$AlignementGrouping
  }
  ,
  handlerExpr = {
    updateNavbarPage(
      session = session,
      inputId = "analysisNavbar",
      selected = "CE-time correction"
    )
    
    updateRadioButtons(session = session, 
                       inputId = "CorrectionTimeStep", 
                       selected = "1")
    
  })



#### Files to save
peaks_mono_iso_toSave_NewRefMap<-reactive({
  if(!is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$IncludeSample_NewRefMap)){
    values<-peaks_mono_iso_NewRefMap()[peaks_mono_iso_NewRefMap()$sample %in% input$IncludeSample_NewRefMap,]
    colnames(values)[8] <- "maxo"
    values$maxo<-2^(values$maxo)
    
    reqColsSaved<-c('M+H','M+H.min','M+H.max','CE-time','CE-time.min','CE-time.max',
                    'integrated-intensity','intensity', 'sn', 'sample')
    
    reqColsUsed<-c('mz','mzmin','mzmax','rt','rtmin','rtmax',
                   'into','maxo', 'sn', 'sample')
    
    idx_reqColsSaved<-which(colnames(values) %in% reqColsUsed)
    colnames(values)[idx_reqColsSaved]<-reqColsSaved
    
    values<-split(values, f = values$sample)
    values
  }
  
})

peaks_mono_iso_toUsed_NewRefMap<-reactive({
  if(!is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$IncludeSample_NewRefMap)){
    values<-peaks_mono_iso_NewRefMap()[peaks_mono_iso_NewRefMap()$sample %in% input$IncludeSample_NewRefMap,]
    colnames(values)[8] <- "maxo"
    values$maxo<-2^(values$maxo)
    values<-split(values, f = values$sample)
    values
  }
  
})



### The volume to use and save file

observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$SaveAnalysis_NewRefMap
  }
  ,
  handlerExpr = {
    shinyFileSave(input,
                  id = "SaveAnalysis_NewRefMap",
                  roots = volumes,
                  session = session)
    
    path_Save_Files_origine<-parseSavePath(volumes, input$SaveAnalysis_NewRefMap)$datapath
    
    if(length(path_Save_Files_origine)>0){
      path_Save_Files<-strsplit(path_Save_Files_origine, split = "/")[[1]]
      directory_Save_Files<-paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
      
      if(length(peaks_mono_iso_toSave_NewRefMap())>0 & !is.null(peaks_mono_iso_NewRefMap()) & !is.null(input$IncludeSample_NewRefMap)){
        if(length(peaks_mono_iso_toSave_NewRefMap())==1){
          write.table(peaks_mono_iso_toSave_NewRefMap()[[1]], #file = path_Save_Files_origine,
                      file = paste0(c(directory_Save_Files,
                                      paste(names(peaks_mono_iso_toSave_NewRefMap())[1],
                                            path_Save_Files[length(path_Save_Files)],
                                            collapse = "", sep = "-")), collapse = "/"),
                      sep = ",", row.names = FALSE)
          print("Save ok")
        } else{
          
          withProgress(message = 'Saving files...', value = 0, {
            for(i in 1:length(peaks_mono_iso_toSave_NewRefMap())){
              
              incProgress(1/length(peaks_mono_iso_toSave_NewRefMap()), detail = "")
              print(paste0(c(directory_Save_Files,
                             paste(#as.character(i),
                               names(peaks_mono_iso_toSave_NewRefMap())[i],
                               path_Save_Files[length(path_Save_Files)],
                               collapse = "", sep = "-")), collapse = "/"))
              write.table(peaks_mono_iso_toSave_NewRefMap()[[i]], file = paste0(c(directory_Save_Files,
                                                                                  paste(#as.character(i),
                                                                                    names(peaks_mono_iso_toSave_NewRefMap())[i],
                                                                                    path_Save_Files[length(path_Save_Files)],
                                                                                    collapse = "", sep = "-")), collapse = "/"),
                          sep = ",", row.names = FALSE)
              print("Save ok")
            }
            
          })
          
        }
        
        
      }
    }
    
    
  })
