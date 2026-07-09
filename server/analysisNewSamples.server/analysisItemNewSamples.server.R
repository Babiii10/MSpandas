# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~ Configure some buttons ~~~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ReturnToPeakViewer_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ReturnToPeakViewer_newSample
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "1")
               
#                shinyjs::show(id = "buttonResetViewAnalysis")
#                shinyjs::show(id = "RestartProjects")
#                shinyjs::show(id = "ViewAnalysis")
               
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button GoToPeakView_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$GoToPeakView_newSample
#              },
#              handlerExpr = {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "3")
               
               
#              })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ViewAnalysis ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ViewAnalysis
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "2")
               
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ViewAnalysis_duplicate ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ViewAnalysis_duplicate
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "2")
               
#              })
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ReturToFilterSample_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ReturToFilterSample_newSample
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "2")
               
#              })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Buton CorrectionKernelDensityNexPage_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$CorrectionKernelDensityNexPage_newSample
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "4")
               
#              })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button returnAnalysis ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$returnAnalysis
#              }
#              , {
#                updateRadioButtons(session = session,
#                                   inputId = "IdAnalysisStep",
#                                   selected = "3")
               
               
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button Finish_fitModel_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$Finish_fitModel_newSample
#              },
#              handlerExpr = {
#                ask_confirmation(
#                  inputId = "Comfirm_FinishedCEtimeCorrection",
#                  title = NULL,
#                  text = tags$b(
#                    #icon("info"),
#                    paste0(
#                      "Are you sure you’re finished correcting CE-time ?"
#                    ),
#                    style = "color: #FA5858;"
#                  ),
#                  btn_labels = c("Cancel", "OK"),
#                  btn_colors = c("#00BFFF", "#FE2E2E"),
#                  html = TRUE
#                )
               
               
#              })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button Comfirm_FinishedCEtimeCorrection ~~~~~~~~~~~~~~~~~~~~~~~~#
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$Comfirm_FinishedCEtimeCorrection
#              },
#              handlerExpr = {
#                if (input$Comfirm_FinishedCEtimeCorrection == TRUE) {
#                  enable("GroupingButtonIDNewSample")
                 
#                }
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button GoMatch ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$GoMatch
#              }
#              , {
#                updateNavbarPage(session = session,
#                                 inputId = "analysisNavbar",
#                                 selected = "Match reference map")
               
#              })

# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~ choix du map de référance ~~~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$chosseRef
#              },
#              handlerExpr = {
#                print(input$chosseRef)
#                if (input$chosseRef == "") {
#                  print("No reference map")
                 
#                  updateNavbarPage(session = session,
#                                   inputId = "analysisNavbar",
#                                   selected = "Peak detection")
                 
#                  ask_confirmation(
#                    inputId = "no_ref_map",
#                    type = "warning",
#                    title = NULL,
#                    text = tags$b(
#                      icon("frown"),
#                      "No reference map available.",
#                      br(),
#                      "Please create a new reference map!",
                     
#                      style = "color: #FA5858;"
#                    ),
#                    btn_labels = c("Yep"),
#                    btn_colors = c("#FE642E"),
#                    html = TRUE
#                  )
                 
#                  disable("runPeakPicking")
#                  shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
#                } else if (file.exists(file.path(ref_map_directory, input$chosseRef, "run_ref.mzML")) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "map_ref.csv")) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "paramMsdial.txt")) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "defaultParam.txt")) &
#                           file.exists(file.path(
#                             ref_map_directory,
#                             input$chosseRef,
#                             "peaksList_run_ref.csv"
#                           )) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "rt_ref.csv")) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "normalizers_ref.csv")) &
#                           file.exists(file.path(ref_map_directory, input$chosseRef, "Parameters_Used.txt"))) {
#                  print("Tout est OK !")
                 
#                  source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')
                 
#                  RvarsPeakDetectionNewSample$run_ref_path <-
#                    file.path(ref_map_directory, input$chosseRef, "run_ref.mzML")
#                  RvarsPeakDetectionNewSample$map_ref_path <-
#                    file.path(ref_map_directory, input$chosseRef, "map_ref.csv")
#                  RvarsPeakDetectionNewSample$paramMsdial_ref_path <-
#                    file.path(ref_map_directory, input$chosseRef, "paramMsdial.txt")
#                  RvarsPeakDetectionNewSample$defaultParam_ref_path <-
#                    file.path(ref_map_directory, input$chosseRef, "defaultParam.txt")
#                  RvarsPeakDetectionNewSample$peaksList_run_ref_path <-
#                    file.path(ref_map_directory,
#                              input$chosseRef,
#                              "peaksList_run_ref.csv")
#                  RvarsPeakDetectionNewSample$rt_min_max_run_ref_path <-
#                    file.path(ref_map_directory, input$chosseRef, "rt_ref.csv")
#                  RvarsPeakDetectionNewSample$normalizers_ref_path <-
#                    file.path(ref_map_directory,
#                              input$chosseRef,
#                              "normalizers_ref.csv")
                 
#                  RvarsPeakDetectionNewSample$export_param_path <-
#                    file.path(ref_map_directory,
#                              input$chosseRef,
#                              "Parameters_Used.txt")
#                  RvarsPeakDetectionNewSample$output_export_param_path <-
#                    file.path(ref_map_directory, input$chosseRef, "outputParam.txt")
                 
#                  RvarsPeakDetectionNewSample$defaultParam <-
#                    readDefaultParam(req(RvarsPeakDetectionNewSample$defaultParam_ref_path))
                 
#                  RvarsPeakDetectionNewSample$map_ref <-
#                    read.csv(RvarsPeakDetectionNewSample$map_ref_path, sep = ",")
                 
#                  colnames(RvarsPeakDetectionNewSample$map_ref)[2:3] <-
#                    c("M+H", "CE-time")
                 
#                  RvarsPeakDetectionNewSample$normalizers_ref <-
#                    read.csv(RvarsPeakDetectionNewSample$normalizers_ref_path, sep = ",")
                 
                 
#                  enable("runPeakPicking")
#                  shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
#                } else {
#                  print("Pas bon !")
                 
#                  message("Incomplete reference map...!")
#                  disable("runPeakPicking")
#                  shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
#                  RvarsPeakDetectionNewSample$run_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$map_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$paramMsdial_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$defaultParam_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$peaksList_run_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$rt_min_max_run_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$normalizers_ref_path <-
#                    character()
#                  RvarsPeakDetectionNewSample$export_param_path <-
#                    NULL
#                  RvarsPeakDetectionNewSample$output_export_param_path <-
#                    NULL
                 
                 
#                  RvarsPeakDetectionNewSample$defaultParam = NULL
                 
#                  RvarsPeakDetectionNewSample$map_ref <-
#                    data.frame(
#                      ID = character(),
#                      mz = numeric(0),
#                      rt = numeric(0),
#                      maxo = numeric(0)
#                    )
#                  RvarsPeakDetectionNewSample$normalizers_ref <-
#                    data.frame()
                 
                 
                 
                 
#                  ask_confirmation(
#                    inputId = "error_ref_map",
#                    type = "warning",
#                    title = NULL,
#                    text = tags$b(
#                      icon("frown"),
#                      "Incomplete reference map.",
#                      br(),
#                      "Please recreate the map again !",
#                      style = "color: #FA5858;"
#                    ),
#                    btn_labels = c("Yep"),
#                    btn_colors = c("#FE642E"),
#                    html = TRUE
#                  )
#                }
               
#              })


# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Input Files ~~~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# directoryInput <- reactiveValues(directory = getwd())

# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$directory
#              },
#              handlerExpr = {
#                if (input$directory > 0) {
#                  # condition prevents handler execution on initial app launch
                 
#                  # launch the directory selection dialog with initial path read from the widget
#                  directoryInput$directory = choose.dir(default = readDirectoryInput(session, 'directory'))
#                  directoryInput$directory = str_replace_all(directoryInput$directory,
#                                                             pattern =  "\\\\",
#                                                             replacement  = "/")
                 
#                  # update the widget value
#                  updateDirectoryInput(session, 'directory', value = directoryInput$directory)
                 
                 
                 
#                }
#              })


# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~~~~ Default for some inputs ~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observe({
#   if (length(input$IdDataType) != 0) {
#     if (input$IdDataType == "defaults") {
#       shinyjs::reset("dataType")
#       updateSelectInput(session = session,
#                         inputId = "MS1_type",
#                         selected = "Profile")
#       updateSelectInput(session = session,
#                         inputId = "MS2_type",
#                         selected = "Profile")
#     }
    
#   }
  
#   if (length(input$ViewSizePoints) != 0) {
#     if (input$ViewSizePoints == "defaults") {
#       shinyjs::reset("sizePoints")
#     }
    
#   }
  
  
# })





# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~ Run peak picking MSDIAl and Deconvolution ~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$runPeakPicking
#              }
#              , {
#                ### Disable some buttons when prepossessing start
#                shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
#                shinyjs::disable(selector = '.navbar-nav a[data-value="New reference map"')
#                shinyjs::disable(selector = '.navbar-nav a[data-value="Database"')
#                shinyjs::disable(selector = '.navbar-nav a[data-value="Statistical analysis"')
#                shinyjs::disable(selector = '.navbar-nav a[data-value="Help"')
               
               
               
#                disable("runPeakPicking")
#                disable("processParameters")
#                disable("directory")
#                disable("match")
#                #disable("viewResult")
#                disable("features_list")
#                disable("normIntensity")
#                disable("runNormalizing")
#                disable("returnAnalysisViewer")
#                disable("finishAnalyze")
#                disable("returnMatchRef")
#                disable("SaveAnalysisResults")
               
#                disable(id = "chosseRef")
#                disable(id = "projectName")
#                disable(id = "IdDataType")
#                disable(id = "dataType")
#                disable(id = "MS1_type")
#                disable(id = "MS2_type")
#                hide(id = "ViewAnalysis")
#                hide(id = "RestartProjects")
               
               
               
#                # Show progress stuff
#                shinyjs::show("progressWrapper")
#                shinyjs::show("analysisProgress")
#                shinyjs::show("idpanel_analysisProgress")
#                #shinyjs::html("analysisProgress","Preprocess running !")
               
#                if (is.na(directoryInput$directory) ||
#                    (directoryInput$directory == "") ||
#                    (directoryInput$directory == getwd()) ||
#                    (req(directoryInput$directory) == "Choose working directory") ||
#                    is.null(directoryInput$directory)) {
#                  message("No file .msdial...!")
                 
#                  hide("progressWrapper")
#                  hide("analysisProgress")
#                  hide("idpanel_analysisProgress")
#                  enable("runPeakPicking")
#                  enable("updateProject")
#                  enable("confirmProject")
#                  enable("processParameters")
#                  enable("directory")
                 
#                  enable(id = "chosseRef")
#                  enable(id = "projectName")
#                  enable(id = "dataType")
#                  enable(id = "IdDataType")
#                  enable(id = "MS1_type")
#                  enable(id = "MS2_type")
                 
#                  shinyjs::html("analysisProgress", html = NULL)
                 
#                  sendSweetAlert(
#                    session = session,
#                    title = "Warning !",
#                    text = "There is no input MS file to be imported !",
#                    type = "warning"
#                  )
                 
                 
#                } else {
#                  withProgress(message = 'Processing...', value = 0, {
#                    source("lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R",
#                           local = TRUE)
#                    source_python("lib/AnalysisNewSample/Python_files/msconverter_command_line.py")
                   
#                    #incProgress(1/10, detail = paste("Grouping isotopic massifs into features...", round(6/8*100,0),"%",collapse=""))
#                    incProgress(1 / 8, detail = paste("Start preprocessing...", collapse =
#                                                        ""))
#                    ########################################################################
#                    updateShinyProgressBar(
#                      shinyProgressData = list(
#                        session = session,
#                        progressId = "preprocessProgressBar",
#                        progressTotal = 8,
#                        textId = "analysis_pre"
#                      ),
#                      pbValue = 1,
#                      headerMsg = "Start preprocessing....",
#                      footerMsg = "Start preprocessing data..."
#                    )
#                    ########################################################################
                   
#                    ### Directory Project
#                    RvarsPeakDetectionNewSample$Project_Name <-
#                      paste(input$projectName,
#                            sub(
#                              sub(
#                                sub(
#                                  Sys.time(),
#                                  pattern = "CEST",
#                                  replacement = "",
#                                  fixed = TRUE
#                                ),
#                                pattern = ":",
#                                replacement = "-",
#                                fixed = TRUE
#                              ),
#                              pattern = ":",
#                              replacement = "-",
#                              fixed = TRUE
#                            ),
#                            sep = "_")
                   
                   
#                    if (dir.exists(
#                      file.path(
#                        directoryInput$directory,
#                        RvarsPeakDetectionNewSample$Project_Name
#                      )
#                    )) {
#                      unlink(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name
#                        ),
#                        recursive = TRUE
#                      )
#                      dir.create(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name
#                        )
#                      )
#                    } else{
#                      dir.create(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name
#                        )
#                      )
#                    }
                   
#                    ## creer un dossier contenant la liste des peaks
#                    if (dir.exists(
#                      file.path(
#                        directoryInput$directory,
#                        RvarsPeakDetectionNewSample$Project_Name,
#                        "Massif-List"
#                      )
#                    )) {
#                      unlink(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name,
#                          "Massif-List"
#                        ),
#                        recursive = TRUE
#                      )
#                      dir.create(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name,
#                          "Massif-List"
#                        )
#                      )
#                      directoryOutput <-
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name,
#                          "Massif-List"
#                        )
#                    } else{
#                      dir.create(
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name,
#                          "Massif-List"
#                        )
#                      )
#                      directoryOutput <-
#                        file.path(
#                          directoryInput$directory,
#                          RvarsPeakDetectionNewSample$Project_Name,
#                          "Massif-List"
#                        )
#                    }
                   
                   
#                    ### Don't need the mzML files
#                    # ## creer un dossier contenant les fichiers mzML
#                    # if(dir.exists(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"))) {
#                    #   unlink(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"), recursive = TRUE)
#                    #   dir.create(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"))
#                    #   RvarsPeakDetectionNewSample$directoryOutput_mzML_files<-file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files")
#                    # } else{
#                    #   dir.create(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name, "mzML files"))
#                    #   RvarsPeakDetectionNewSample$directoryOutput_mzML_files<-file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name, "mzML files")
#                    # }
#                    ## Conversion des raw data en .mzML pour l'alignement des runs
#                    # message(" \n --- Convert raw data to .mzML ---\n")
#                    #
#                    # incProgress(1/10, detail = paste("Converting raw data to .mzML...",collapse=""))
#                    # ########################################################################
#                    # updateShinyProgressBar(
#                    #   shinyProgressData=list(
#                    #     session=session,
#                    #     progressId="preprocessProgressBar",
#                    #     progressTotal=10,
#                    #     textId="analysis_pre"
#                    #   ),
#                    #   pbValue=2,
#                    #   headerMsg="Converting raw data...",
#                    #   footerMsg="Converting raw data to .mzML..."
#                    # )
#                    # ########################################################################
#                    #
#                    #
#                    # system.time(convert_to_mzML(directoryInput$directory,RvarsPeakDetectionNewSample$directoryOutput_mzML_files))
#                    # system.time(system2("lib/AnalysisNewSample/cmd/convert_raw_data_to_mzML_centroid.bat"))
#                    #
#                    #
#                    #
#                    # message("--- End converting raw data to .mzML ---\n")
#                    #
#                    # incProgress(1/10, detail = paste("End converting raw data to .mzML...",collapse=""))
#                    # ########################################################################
#                    # updateShinyProgressBar(
#                    #   shinyProgressData=list(
#                    #     session=session,
#                    #     progressId="preprocessProgressBar",
#                    #     progressTotal=10,
#                    #     textId="analysis_pre"
#                    #   ),
#                    #   pbValue=3,
#                    #   headerMsg="Converting raw data...",
#                    #   footerMsg="End coverting..."
#                    # )
#                    # ########################################################################
#                    #
                   
#                    source_python('lib/AnalysisNewSample/Python_files/export.parameters.py')
                   
#                    exportMsdialParam(
#                      export_param = req(RvarsPeakDetectionNewSample$export_param_path),
#                      output_export_param =  req(RvarsPeakDetectionNewSample$output_export_param_path),
#                      MS1_type = req(input$MS1_type),
#                      MS2_type = req(input$MS2_type),
#                      ion = req(RvarsPeakDetectionNewSample$defaultParam$ion),
#                      rt_begin = req(
#                        as.character(RvarsPeakDetectionNewSample$defaultParam$rt_begin)
#                      ),
#                      rt_end = req(
#                        as.character(RvarsPeakDetectionNewSample$defaultParam$rt_end)
#                      ),
#                      mz_range_begin = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mz_range_begin
#                        )
#                      ),
#                      mz_range_end = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mz_range_end
#                        )
#                      ),
#                      mz_tolerance_centroid_MS1 = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS1
#                        )
#                      ),
#                      mz_tolerance_centroid_MS2 = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS2
#                        )
#                      ),
#                      maxCharge = req(
#                        as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
#                      ),
#                      min_Peakwidth = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
#                        )
#                      ),
#                      min_PeakHeight = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
#                        )
#                      ),
#                      mass_slice_width = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
#                        )
#                      ),
#                      min_PeaksMassif = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$min_PeaksMassif
#                        )
#                      ),
#                      Adduct_list = req(
#                        as.list(RvarsPeakDetectionNewSample$defaultParam$Adduct_list)
#                      ),
#                      bw = req(
#                        as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
#                      ),
#                      rt_tolerance = req(
#                        as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
#                      ),
#                      mass_tolerance = req(
#                        as.character(
#                          RvarsPeakDetectionNewSample$defaultParam$mass_tolerance
#                        )
#                      ),
#                      min_iset = req(as.character(input$min_iset)),
#                      cutrat = req(as.character(input$cutrat)),
#                      Ref = req(input$chosseRef)
#                    )
                   
                   
                   
#                    message("--- Start peak picking ---\n")
#                    incProgress(1 / 8, detail = paste("Start peak picking...", collapse =
#                                                        ""))
                   
#                    ########################################################################
#                    updateShinyProgressBar(
#                      shinyProgressData = list(
#                        session = session,
#                        progressId = "preprocessProgressBar",
#                        progressTotal = 8,
#                        textId = "analysis_pre"
#                      ),
#                      pbValue = 2,
#                      headerMsg = "Calling peak picking...",
#                      footerMsg = "Start peak picking..."
#                    )
#                    ########################################################################
                   
#                    #### Peak picking
#                    system.time(
#                      findPeaks_MSDIAL(
#                        input_files = req(directoryInput$directory),
#                        output_files = directoryOutput,
#                        #output_export_param = file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name),
#                        output_export_param = file.path("data/References", req(input$chosseRef)),
#                        rt_begin = req(
#                          as.character(RvarsPeakDetectionNewSample$defaultParam$rt_begin)
#                        ),
#                        rt_end = req(
#                          as.character(RvarsPeakDetectionNewSample$defaultParam$rt_end)
#                        ),
#                        mz_range_begin = req(
#                          as.character(
#                            RvarsPeakDetectionNewSample$defaultParam$mz_range_begin
#                          )
#                        ),
#                        mz_range_end = req(
#                          as.character(
#                            RvarsPeakDetectionNewSample$defaultParam$mz_range_end
#                          )
#                        ),
#                        MS1_type = req(input$MS1_type),
#                        MS2_type = req(input$MS2_type),
#                        Adduct_list = req(
#                          as.list(RvarsPeakDetectionNewSample$defaultParam$Adduct_list)
#                        ),
#                        maxCharge = req(
#                          as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
#                        ),
#                        min_Peakwidth = req(
#                          as.character(
#                            RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
#                          )
#                        ),
#                        min_PeakHeight = req(
#                          RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
#                        ),
#                        mass_slice_width = req(
#                          as.character(
#                            RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
#                          )
#                        ),
#                        shinyProgressData = list(
#                          session = session,
#                          progressId = "preprocessProgressBar",
#                          progressTotal = 8,
#                          textId = "analysis_pre"
#                        )
#                      )
#                    )
                   
                   
                   
                   
#                    ###### Suppression des fichiers inutiles après peak picking
                   
#                    message("--- Deleting unnecessary files ---\n")
                   
#                    incProgress(1 / 8,
#                                detail = paste("Deleting unnecessary files...", collapse = ""))
#                    ########################################################################
#                    updateShinyProgressBar(
#                      shinyProgressData = list(
#                        session = session,
#                        progressId = "preprocessProgressBar",
#                        progressTotal = 8,
#                        textId = "analysis_pre"
#                      ),
#                      pbValue = 5,
#                      headerMsg = " Deleting unnecessary files...",
#                      footerMsg = ""
#                    )
#                    ########################################################################
                   
                   
#                    source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')
                   
#                    removeFiles(path_to_files = directoryInput$directory,
#                                ext = '.dcl')
#                    removeFiles(path_to_files = directoryInput$directory,
#                                ext = '.pai2')
#                    removeFiles(path_to_files = directoryInput$directory,
#                                ext = '.aef')
                   
                   
                   
#                    #### Grouping isotopic massifs into peptides
                   
#                    # Vecteur contenant les chemins d'acces vers les fichiers .msdial
#                    path_file_msdial_newSample <-
#                      file.path(directoryOutput, dir(directoryOutput))
                   
#                    if (length(path_file_msdial_newSample) >= 1) {
#                      if (length(path_file_msdial_newSample) > 1) {
#                        file.remove(list.files(
#                          directoryOutput,
#                          pattern = "AlignResult-",
#                          full.names = TRUE
#                        ))
#                        path_file_msdial_newSample <-
#                          list.files(directoryOutput, full.names = TRUE)
#                      }
                     
#                      cat("lemme whow path_file_msdial_newSample : \n")
#                      print(path_file_msdial_newSample)
#                      cat(" lemme show directoryOutput : \n")
#                      print(directoryOutput)
                     
#                      RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample <-
#                        deconv_peaks_MSDIAL(
#                          path_to_peakList = req(path_file_msdial_newSample),
#                          output_directory = directoryOutput,
#                          file_adduct = "data/Adduit.csv",
#                          mass_slice_width = as.numeric(
#                            req(
#                              RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
#                            )
#                          ),
#                          min_PeaksMassif = as.numeric(
#                            req(
#                              RvarsPeakDetectionNewSample$defaultParam$min_PeaksMassif
#                            )
#                          ),
#                          shinyProgressData =
#                            list(
#                              session = session,
#                              progressId =
#                                "preprocessProgressBar",
#                              progressTotal =
#                                8,
#                              textId =
#                                "analysis_pre"
#                            )
#                        )
#                      removeFiles(path_to_files = directoryOutput,
#                                  ext = '.msdial')
                     
                     
#                      RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
#                        split(
#                          RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample,
#                          f =
#                            RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample$sample
#                        )
                     
                     
                     
                     
                     
#                      message(" \n --- Preprocess complete ! ---\n")
#                      ########################################################################
#                      updateShinyProgressBar(
#                        shinyProgressData = list(
#                          session = session,
#                          progressId = "preprocessProgressBar",
#                          progressTotal = 8,
#                          textId = "analysis_pre"
#                        ),
#                        pbValue = 8,
#                        headerMsg = " Preprocess complete !",
#                        footerMsg = ""
#                      )
#                      ########################################################################
                     
                     
                     
                     
#                      # Pipeline completed hopefully
#                      #shinyjs::html("analysisProgress","Preprocess complete !")
                     
#                      #### End Processing
#                      sendSweetAlert(
#                        session = session,
#                        title = "Preprocess complete !",
#                        text = HTML(
#                          paste(
#                            '<h3> Parameters used : </h3>

#                 <span style="font-weight:bold;">Reference map : ',
#                            req(input$chosseRef),
#                            '</span>

#                 <h4>Mass accuracy(centroid parameter) : </h4>
#                 <ol style = "list-style-type: none;">
#                 <li>MS1 tolerance (Da) : ',
#                            req(
#                              as.character(
#                                RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS1
#                              )
#                            ),
#                            '</li>
#                 <li>MS2 tolerance (Da) : ',
#                            req(
#                              as.character(
#                                RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS2
#                              )
#                            ),
#                            '</li>
#                 </ol>

#                 <h4>Peak detection parameters : </h4>
#                 <ol style = "list-style-type: none;">
#                 <li>Mass slice width (Da) : ',
#                            req(
#                              as.character(
#                                RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
#                              )
#                            ),
#                            ' </li>
#                 <li>Minimum peak height (amplitude) : ',
#                            req(
#                              as.character(
#                                RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
#                              )
#                            ),
#                            ' </li>
#                 <li>Minimum peak widt (scan) : ',
#                            req(
#                              as.character(
#                                RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
#                              )
#                            ),
#                            ' </li>
#                 <li>Maximum charged number : ',
#                            req(
#                              as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
#                            ),
#                            '</li>
#                 </ol>

#                 <h4> Grouping of chromatographic peaks within samples : </h4>
#                 <ol style = "list-style-type: none;">
#                 <li>Bandwidth (CE-time tolerance) (second) : ',
#                            req(
#                              as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
#                            ),
#                            ' </li>
#                 </ol>
#                 <br/>
#                 <h3>Click OK to continue !</h3>'
#                          )
#                        ),
#                        type = "success",
#                        width = "70%",
#                        closeOnClickOutside = FALSE,
#                        html = TRUE
#                      )
                     
                     
                     
                     
#                      #showTab("analysisNavbar","Samples normalization", select = TRUE, session = session)
                     
#                      # updateNavbarPage(
#                      #   session = session,
#                      #   inputId = "analysisNavbar",
#                      #   selected = "Match reference map"
#                      # )
                     
#                      updateRadioButtons(session = session,
#                                         inputId = "IdAnalysisStep",
#                                         selected = "2")
                     
#                      shinyjs::show("normIntensity")
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
                     
#                    } else {
#                      message("No file .msdial...!")
#                      hide("progressWrapper")
#                      hide("analysisProgress")
#                      hide("idpanel_analysisProgress")
#                      enable("runPeakPicking")
#                      enable("updateProject")
#                      enable("confirmProject")
#                      enable("processParameters")
#                      enable("directory")
                     
#                      enable(id = "chosseRef")
#                      enable(id = "projectName")
#                      enable(id = "dataType")
#                      enable(id = "IdDataType")
#                      enable(id = "MS1_type")
#                      enable(id = "MS2_type")
                     
                     
#                      shinyjs::html("analysisProgress", html = NULL)
                     
#                      sendSweetAlert(
#                        session = session,
#                        title = "Warning !",
#                        text = "There is no input MS file to be imported !",
#                        type = "alert"
#                      )
#                    }
                   
#                  })

#                }
               
               
               
#                enable("match")
#                enable("normIntensity")
#                enable("runNormalizing")
#                enable("returnAnalysisViewer")
#                enable("returnMatchRef")
#                enable("SaveAnalysisResults")
#                enable("finishAnalyze")
#                enable("features_list")
#                shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
#                shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
#                shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
#                shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
#                shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
               
#                shinyjs::show("id_PlotCutt_newSample")
               
               
               
#              })


# ########################################################################
# # Reset the timebar for later
# updateShinyProgressBar(
#   shinyProgressData = list(
#     session = session,
#     progressId = "preprocessProgressBar",
#     progressTotal = 8,
#     textId = "analysis_pre"
#   ),
#   pbValue = 1,
#   headerMsg = "",
#   footerMsg = ""
# )
# ########################################################################

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##



# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~~~ Upload massif list files  ~~~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$massif_list_newSample
#              }
#              , {
#                files <- input$massif_list_newSample
#                ext <- tools::file_ext(files$datapath)
               
               
#                if (length(ext) > 1) {
#                  if (all.equal(ext, rep("csv", length(ext))) != TRUE) {
#                    message("Please upload a csv file...!")
                   
#                    sendSweetAlert(
#                      session = session,
#                      title = "Warning !",
#                      text = "Please upload a csv file !",
#                      type = "warning"
#                    )
#                  } else {
#                    a <- lapply(input$massif_list_newSample$datapath, read.csv)
#                    tryCatch({
#                      a <- do.call("rbind", a)
#                    },
#                    error = function(e) {
#                      message("Please upload a csv file...!")
                     
#                      sendSweetAlert(
#                        session = session,
#                        title = "Warning !",
#                        text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
#                        'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
#                            'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
#                        type = "warning"
#                      )
#                    })
                   
                   
#                    if (!is.element("M.H", colnames(a)) ||
#                        !is.element("M.H.min", colnames(a)) ||
#                        !is.element("M.H.max", colnames(a)) ||
#                        !is.element("CE.time", colnames(a)) ||
#                        !is.element("CE.time.min", colnames(a)) ||
#                        !is.element("CE.time.max", colnames(a)) ||
#                        !is.element("integrated.intensity", colnames(a)) ||
#                        !is.element("intensity", colnames(a)) ||
#                        !is.element("sn", colnames(a)) ||
#                        !is.element("sample", colnames(a)) ||
#                        !is.element("iso.mass", colnames(a)) ||
#                        !is.element("iso.mass.link", colnames(a)) ||
#                        !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("Adduct", colnames(a)) ||
#                        ncol(a) < 16) {
#                      message("Please upload a csv file...!")
                     
#                      sendSweetAlert(
#                        session = session,
#                        title = "Warning !",
#                        text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
#                        'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
#                            'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
#                        type = "warning"
#                      )
#                    } else {
                     
                     
#                      ColnameData <-
#                        c(
#                          'M.H',
#                          'M.H.min',
#                          'M.H.max',
#                          'CE.time',
#                          'CE.time.min',
#                          'CE.time.max',
#                          'integrated-intensity',
#                          'intensity',
#                          'sn',
#                          'sample',
#                          'iso.mass',
#                          'iso.mass.link',
#                          'mz_PeaksIsotopics_Group',
#                          'rt_PeaksIsotopics_Group',
#                          'Height_PeaksIsotopics_Group',
#                          'Adduct'
#                        )
                     
#                      ColnamesToUse <-
#                        c(
#                          "mz",
#                          "mzmin",
#                          "mzmax",
#                          "rt",
#                          "rtmin",
#                          "rtmax",
#                          "into",
#                          "maxo",
#                          "sn",
#                          "sample",
#                          'iso.mass',
#                          'iso.mass.link',
#                          'mz_PeaksIsotopics_Group',
#                          'rt_PeaksIsotopics_Group',
#                          'Height_PeaksIsotopics_Group',
#                          'Adduct'
#                        )
                     
#                      colnames(a) <- ColnamesToUse
                     
#                      a <- a
#                      a <- split(a, f = a$sample)
#                      RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
#                        a
                     
                     
#                      updateRadioButtons(session = session,
#                                         inputId = "IdAnalysisStep",
#                                         selected = "2")
#                      enable("ViewAnalysis_duplicate")
#                      shinyjs::show("id_PlotCutt_newSample")
                     
#                      shinyjs::show("normIntensity")
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
#                      enable("match")
#                      enable("normIntensity")
#                      enable("runNormalizing")
#                      enable("returnAnalysisViewer")
#                      enable("returnMatchRef")
#                      enable("SaveAnalysisResults")
#                      enable("finishAnalyze")
#                      enable("features_list")
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
                     
                     
#                    }
                   
#                  }
#                } else {
#                  if (ext != "csv") {
#                    message("Please upload a csv file...!")
                   
#                    sendSweetAlert(
#                      session = session,
#                      title = "Warning !",
#                      text = "Please upload a csv file !",
#                      type = "warning"
#                    )
#                  } else {
#                    a <- lapply(input$massif_list_newSample$datapath, read.csv)
#                    tryCatch({
#                      a <- do.call("rbind", a)
#                    },
#                    error = function(e) {
#                      message("Please upload a csv file...!")
                     
#                      sendSweetAlert(
#                        session = session,
#                        title = "Warning !",
#                        text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
#                        'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
#                            'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
#                        type = "warning"
#                      )
#                    })
                   
                   
                   
#                    if (!is.element("M.H", colnames(a)) ||
#                        !is.element("M.H.min", colnames(a)) ||
#                        !is.element("M.H.max", colnames(a)) ||
#                        !is.element("CE.time", colnames(a)) ||
#                        !is.element("CE.time.min", colnames(a)) ||
#                        !is.element("CE.time.max", colnames(a)) ||
#                        !is.element("integrated.intensity", colnames(a)) ||
#                        !is.element("intensity", colnames(a)) ||
#                        !is.element("sn", colnames(a)) ||
#                        !is.element("sample", colnames(a)) ||
#                        !is.element("iso.mass", colnames(a)) ||
#                        !is.element("iso.mass.link", colnames(a)) ||
#                        !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
#                        !is.element("Adduct", colnames(a)) ||
#                        ncol(a) < 16) {
#                      message("Please upload a csv file...!")
#                      message("\n Probleme inconnu")
                     
#                      sendSweetAlert(
#                        session = session,
#                        title = "Warning !",
#                        text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
#                        'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
#                            'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
#                        type = "warning"
#                      )
#                    } else {
                     
#                      ColnameData <-
#                        c(
#                          'M.H',
#                          'M.H.min',
#                          'M.H.max',
#                          'CE.time',
#                          'CE.time.min',
#                          'CE.time.max',
#                          'integrated-intensity',
#                          'intensity',
#                          'sn',
#                          'sample',
#                          'iso.mass',
#                          'iso.mass.link',
#                          'mz_PeaksIsotopics_Group',
#                          'rt_PeaksIsotopics_Group',
#                          'Height_PeaksIsotopics_Group',
#                          'Adduct'
#                        )
                     
#                      ColnamesToUse <-
#                        c(
#                          "mz",
#                          "mzmin",
#                          "mzmax",
#                          "rt",
#                          "rtmin",
#                          "rtmax",
#                          "into",
#                          "maxo",
#                          "sn",
#                          "sample",
#                          'iso.mass',
#                          'iso.mass.link',
#                          'mz_PeaksIsotopics_Group',
#                          'rt_PeaksIsotopics_Group',
#                          'Height_PeaksIsotopics_Group',
#                          'Adduct'
#                        )
                     
#                      colnames(a) <- ColnamesToUse
                     
                     
#                      a <- a
#                      a <- split(a, f = a$sample)
#                      RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
#                        a
                     
#                      updateRadioButtons(session = session,
#                                         inputId = "IdAnalysisStep",
#                                         selected = "2")
                     
#                      enable("ViewAnalysis_duplicate")
#                      shinyjs::show("id_PlotCutt_newSample")
                     
#                      shinyjs::show("normIntensity")
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
#                      enable("match")
#                      enable("normIntensity")
#                      enable("runNormalizing")
#                      enable("returnAnalysisViewer")
#                      enable("returnMatchRef")
#                      enable("SaveAnalysisResults")
#                      enable("finishAnalyze")
#                      enable("features_list")
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
#                      shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
                     
                     
#                    }
#                  }
#                }
               
               
#              })


# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~ Samples filtering ~~~~~~~~~~~~~~~~~~~~~~~~~~###
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

# observe({
#   if (!is.null(names(
#     RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#   ))) {
#     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
#       data.frame(
#         row.names = names(
#           RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#         ),
#         rt_min_cut_newSample = rep(
#           NA,
#           length(
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#           )
#         ),
#         rt_max_cut_newSample = rep(
#           NA,
#           length(
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#           )
#         ),
#         Unit = rep(
#           "Second",
#           length(
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#           )
#         )
#       )
    
    
#     output$SelectSampleCut <- renderUI({
#       pickerInput(
#         inputId = "sample_selectedCutting_newSample",
#         label = "Select a sample:",
#         choices = names(
#           RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#         ),
#         options = pickerOptions(
#           size = 10,
#           showTick = TRUE,
#           style = "btn-primary"
#         ),
#         width = "fit"
#       )
#     })
    
    
#   } else{
#     output$SelectSampleCut <- renderUI({
#       pickerInput(
#         inputId = "sample_selectedCutting_newSample",
#         label = "Select a sample:",
#         choices = NULL,
#         options = pickerOptions(
#           size = 10,
#           showTick = TRUE,
#           style = "btn-primary"
#         ),
#         width = "fit"
#       )
#     })
    
#     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
#       NULL
#   }
  
  
# })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ sample cutting viewer ~~~~~~~~~~~~~~~~~~~~~~~~#
# observe({
#   if (length(input$sample_selectedCutting_newSample) != 0) {
#     sample_cutting_rv <-
#       req(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])
#     colnames(sample_cutting_rv)[c(1, 4, 8)] <-
#       c("M.H", "CE.time", "intensity")
#     sample_cutting_rv$intensity <- log2(sample_cutting_rv$intensity)
#     RvarsPeakDetectionNewSample$sample_cutting_newSample <-
#       sample_cutting_rv
    
    
#   }
  
# })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sample cutting to used ~~~~~~~~~~~~~~~~~~~~~~~~#
# ## Convert time sample select
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$sample_selectedCutting_newSample
#              },
#              handlerExpr = {
#                RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample <-
#                  req(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])
#                colnames(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)[c(1, 4, 8)] <-
#                  c("M.H", "CE.time", "intensity")
#                RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$intensity <-
#                  log2(
#                    RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$intensity
#                  )
               
               
               
#                #Because les data viennent initialement en second
#                RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
#                  TRUE
#                if (input$UnitTime_sampleCutting_newSample == "Minute") {
#                  #RvarsPeakDetectionNewSample$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-peaks_mono_iso_NewRefMap_toPlot()
#                  print(
#                    paste(
#                      "Convert to min",
#                      input$UnitTime_sampleCutting_newSample == "Minute" &
#                        RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE
#                    )
#                  )
#                  if (input$UnitTime_sampleCutting_newSample == "Minute" &
#                      RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
#                    if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
#                      RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
#                        req(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
#                        ) / 60
#                      RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
#                        FALSE
#                    }
#                  }
#                }
               
               
#                if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 3] <-
#                    input$UnitTime_sampleCutting_newSample
                 
#                }
#              })




# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$UnitTime_sampleCutting_newSample
#              },
#              handlerExpr = {
#                print(
#                  paste(
#                    "Convert to min",
#                    input$UnitTime_sampleCutting_newSample == "Minute" &
#                      RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE
#                  )
#                )
#                if (isolate(input$UnitTime_sampleCutting_newSample) == "Minute" &
#                    RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
#                  if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
#                    RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
#                      req(
#                        RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
#                      ) / 60
#                    RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
#                      FALSE
#                  }
#                }
               
#                print(
#                  paste(
#                    "Covert to Second",
#                    input$UnitTime_sampleCutting_newSample == "Second" &
#                      RvarsPeakDetectionNewSample$Second_Cutting_newSample == FALSE
#                  )
#                )
#                if (isolate(input$UnitTime_sampleCutting_newSample) == "Second" &
#                    RvarsPeakDetectionNewSample$Second_Cutting_newSample == FALSE) {
#                  if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
#                    RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
#                      req(
#                        RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
#                      ) * 60
#                    RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
#                      TRUE
#                  }
#                }
               
#                if (input$UnitTime_sampleCutting_newSample == "Second" &
#                    RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
#                  RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample <-
#                    req(RvarsPeakDetectionNewSample$sample_cutting_newSample)
#                }
               
#                if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 3] <-
#                    input$UnitTime_sampleCutting_newSample
                 
#                }
               
               
#              })


# rangesZoomSample_selectedCutting_newSample <-
#   reactiveValues(x = NULL, y = NULL)

# # When a double-click happens, check if there's a brush on the plot.
# # If so, zoom to the brush bounds; if not, reset the zoom.
# observeEvent({
#   input$sample_selectedCutting_dblclick_newSample
# }, {
#   brush <- input$sample_selectedCutting_brush_newSample
#   if (!is.null(brush)) {
#     rangesZoomSample_selectedCutting_newSample$x <-
#       c(brush$xmin, brush$xmax)
#     rangesZoomSample_selectedCutting_newSample$y <-
#       c(brush$ymin, brush$ymax)
    
#   } else {
#     ## reset coord_cartesian
#     rangesZoomSample_selectedCutting_newSample$x <- NULL
#     rangesZoomSample_selectedCutting_newSample$y <- NULL
#   }
# })

# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$sample_selectedCutting_newSample
#              },
#              handlerExpr = {
#                updateNumericInput(
#                  session = session,
#                  inputId = "rt_min_cut_newSample",
#                  value = RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                )
               
#                updateNumericInput(
#                  session = session,
#                  inputId = "rt_max_cut_newSample",
#                  value = RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                )
               
               
#              })

# observe({
#   if (!is.null(input$sample_selectedCutting_newSample)) {
#     if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
#       if (is.na(
#         RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#       ) &
#       is.na(
#         RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#       )) {
#         print("Sample selected not cutted")
#         if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
#             c(NA, NA)
          
#         }
        
        
        
#         output$sample_selectedCutting_Plot_newSample <- renderPlot({
#           if (!is.null(
#             RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#           )) {
#             shinyjs::show("UnitTime_sampleCutting_id_newSample")
#             shinyjs::show("mousepositionSampleCutting_newSample")
            
#             RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#               ggplot() +
#               aes(x = CE.time,
#                   y = M.H,
#                   colour = intensity) +
#               #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#               geom_point(size = 1) +
#               # geom_vline(xintercept = 3229, lwd = 1.5, color = "blue", linetype = "dashed")+
#               # geom_vline(xintercept = 750, lwd = 1.5, color = "blue", linetype = "dashed")+
#               scale_color_viridis_c(option = "inferno", direction = -1) +
#               ylab("Mass (M+H) (Da)") +
#               xlab(paste(
#                 "CE-time (",
#                 req(input$UnitTime_sampleCutting_newSample),
#                 ")"
#               )) +
#               coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                               ylim = rangesZoomSample_selectedCutting_newSample$y,
#                               expand = TRUE) +
#               ggtitle(paste(
#                 "Sample selected :",
#                 req(input$sample_selectedCutting_newSample),
#                 "\n"
#               )) +
              
#               scale_x_continuous(n.breaks = 14) +
#               #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
              
              
#               #facet_grid(vars(sample), vars())+
#               #option_graphe.3
#               theme_ben() +
#               labs(colour = "log2 Intensity") +
#               theme(
#                 plot.title = element_text(
#                   size = rel(0.9),
#                   face = "bold",
#                   color = "#760001",
#                   margin = margin(0, 0, 5, 0),
#                   hjust = 0.5
#                 ),
#                 plot.subtitle = element_text(hjust = 0.5)
#               )
            
#           }
          
          
          
          
#         })
        
#         ## Mouse position
#         # output$sample_selectedCutting_Plot_info <- renderText({
#         #   paste0("Mouse position : ",
#         #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#         #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#         # })
        
#         output$sample_selectedCutting_Plot_info_newSample <-
#           renderText({
#             paste0(
#               "Mouse position : ",
#               xy_str(
#                 input$sample_selectedCutting_hover_newSample,
#                 "CE-time",
#                 "M+H"
#               ),
#               "Click: ",
#               xy_str(
#                 input$sample_selectedCutting_click_newSample,
#                 "CE-time",
#                 "M+H"
#               )
#             )
#             # paste0("Mouse position : ",
#             #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#             #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#           })
        
#         ## Bulle info
        
#         #### info-bulle
#         output$sample_selectedCutting_hover_info_newSample <-
#           renderUI({
#             hover <- req(input$sample_selectedCutting_hover_newSample)
            
#             if (!is.null(
#               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#             )) {
#               point <-
#                 nearPoints(
#                   req(
#                     RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                   ),
#                   hover,
#                   threshold = 5,
#                   maxpoints = 1,
#                   addDist = TRUE
#                 )
#               if (nrow(point) == 0)
#                 return(NULL)
              
#               # calculate point position INSIDE the image as percent of total dimensions
#               # from left (horizontal) and from top (vertical)
#               left_pct <-
#                 (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#               top_pct <-
#                 (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
              
#               # calculate distance from left and bottom side of the picture in pixels
#               left_px <-
#                 hover$range$left + left_pct * (hover$range$right - hover$range$left)
#               top_px <-
#                 hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
              
#               # create style property fot tooltip
#               # background color is set so tooltip is a bit transparent
#               # z-index is set so we are sure are tooltip will be on top
#               style <-
#                 paste0(
#                   "position:absolute; z-index:100; background-color: #760001; color: white;",
#                   "left:",
#                   left_px + 2,
#                   "px; top:",
#                   top_px + 2,
#                   "px;"
#                 )
              
#               # actual tooltip created as wellPanel
#               div(class = "well well-sm",
#                   style = style,
#                   p(HTML(
#                     paste0(
#                       "<span class='bullText'> CE-time: </span>",
#                       round(point$CE.time, 2),
#                       "<br/>",
#                       "<span class='bullText'> M+H: </span>",
#                       round(point$M.H, 4),
#                       "<br/>",
#                       "<span class='bullText'> log2 Intensity: </span>",
#                       round(point$intensity, 2),
#                       "<br/>",
#                       "<span class='bullText'> Intensity: </span>",
#                       round(2 ^ (point$intensity), 0),
#                       "<br/>"
#                     )
#                   )))
#             }
            
            
            
            
            
#           })
        
        
        
#       }
#     }
#     else {
#       output$sample_selectedCutting_Plot_newSample <- renderPlot({
        
#       })
#       output$sample_selectedCutting_Plot_info_newSample <-
#         renderText({
          
#         })
#       output$sample_selectedCutting_hover_info_newSample <-
#         renderUI({
          
#         })
#       hide("UnitTime_sampleCutting_id_newSample")
#     }
#   } else {
#     output$sample_selectedCutting_Plot_newSample <- renderPlot({
      
#     })
#   }
  
  
# })


# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$cutOff_newSample
#              },
#              handlerExpr = {
#                if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
#                  if (!is.na(input$rt_min_cut_newSample) &
#                      !is.na(input$rt_max_cut_newSample)) {
#                    print("cutoff_newSample")
#                    output$sample_selectedCutting_Plot_newSample <-
#                      renderPlot({
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                          shinyjs::show("mousepositionSampleCutting_newSample")
                         
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                            ggplot() +
#                            aes(x = CE.time,
#                                y = M.H,
#                                colour = intensity) +
#                            #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                            geom_point(size = 1) +
#                            geom_vline(
#                              xintercept = isolate(input$rt_min_cut_newSample),
#                              color = "gray",
#                              linetype = "dashed"
#                            ) +
#                            geom_vline(
#                              xintercept = isolate(input$rt_max_cut_newSample),
#                              color = "gray",
#                              linetype = "dashed"
#                            ) +
#                            ggplot2::annotate(
#                              "rect",
#                              xmin = c(0, isolate(input$rt_max_cut_newSample)),
#                              xmax = c(isolate(input$rt_min_cut_newSample), Inf),
#                              ymin = -Inf ,
#                              ymax = Inf,
#                              alpha = 0.5,
#                              fill = "gray"
#                            ) +
#                            scale_color_viridis_c(option = "inferno", direction = -1) +
#                            ylab("Mass (M+H) (Da)") +
#                            xlab(paste(
#                              "CE-time (",
#                              req(input$UnitTime_sampleCutting_newSample),
#                              ")"
#                            )) +
#                            coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                            ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                            expand = TRUE) +
#                            ggtitle(paste(
#                              "Sample selected :",
#                              req(input$sample_selectedCutting_newSample),
#                              "\n"
#                            )) +
                           
#                            scale_x_continuous(n.breaks = 14) +
#                            #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
#                            #facet_grid(vars(sample), vars())+
#                            #option_graphe.3
#                            theme_ben() +
#                            labs(colour = "log2 Intensity") +
#                            theme(
#                              plot.title = element_text(
#                                size = rel(0.9),
#                                face = "bold",
#                                color = "#760001",
#                                margin = margin(0, 0, 5, 0),
#                                hjust = 0.5
#                              ),
#                              plot.subtitle = element_text(hjust = 0.5)
#                            )
                         
#                        }
                       
                       
                       
#                      })
                   
#                    ## Mouse position
#                    # output$sample_selectedCutting_Plot_info <- renderText({
#                    #   paste0("Mouse position : ",
#                    #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                    #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                    # })
                   
#                    output$sample_selectedCutting_Plot_info_newSample <-
#                      renderText({
#                        paste0(
#                          "Mouse position: ",
#                          xy_str(
#                            input$sample_selectedCutting_hover_newSample,
#                            "CE-time",
#                            "M+H"
#                          ),
#                          "Click: ",
#                          xy_str(
#                            input$sample_selectedCutting_click_newSample,
#                            "CE-time",
#                            "M+H"
#                          )
#                        )
#                        # paste0("Mouse position : ",
#                        #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                        #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                      })
                   
#                    ## Bulle info
                   
#                    #### info-bulle
#                    output$sample_selectedCutting_hover_info_newSample <-
#                      renderUI({
#                        hover <- req(input$sample_selectedCutting_hover_newSample)
                       
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          point <-
#                            nearPoints(
#                              req(
#                                RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                              ),
#                              hover,
#                              threshold = 5,
#                              maxpoints = 1,
#                              addDist = TRUE
#                            )
#                          if (nrow(point) == 0)
#                            return(NULL)
                         
#                          # calculate point position INSIDE the image as percent of total dimensions
#                          # from left (horizontal) and from top (vertical)
#                          left_pct <-
#                            (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                          top_pct <-
#                            (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
#                          # calculate distance from left and bottom side of the picture in pixels
#                          left_px <-
#                            hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                          top_px <-
#                            hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
#                          # create style property fot tooltip
#                          # background color is set so tooltip is a bit transparent
#                          # z-index is set so we are sure are tooltip will be on top
#                          style <-
#                            paste0(
#                              "position:absolute; z-index:100; background-color: #760001; color: white;",
#                              "left:",
#                              left_px + 2,
#                              "px; top:",
#                              top_px + 2,
#                              "px;"
#                            )
                         
#                          # actual tooltip created as wellPanel
#                          div(class = "well well-sm",
#                              style = style,
#                              p(HTML(
#                                paste0(
#                                  "<span class='bullText'> CE-time: </span>",
#                                  round(point$CE.time, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> M+H: </span>",
#                                  round(point$M.H, 4),
#                                  "<br/>",
#                                  "<span class='bullText'> log2 Intensity: </span>",
#                                  round(point$intensity, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> Intensity: </span>",
#                                  round(2 ^ (point$intensity), 0),
#                                  "<br/>"
#                                )
#                              )))
#                        }
                       
                       
                       
                       
                       
#                      })
                   
#                    if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
#                        c(
#                          isolate(input$rt_min_cut_newSample),
#                          isolate(input$rt_max_cut_newSample)
#                        )
#                    }
                   
                   
                   
#                  } else if (!is.na(input$rt_min_cut_newSample) &
#                             is.na(input$rt_max_cut_newSample)) {
#                    print("cutoff_newSample")
#                    output$sample_selectedCutting_Plot_newSample <-
#                      renderPlot({
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                          shinyjs::show("mousepositionSampleCutting_newSample")
                         
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                            ggplot() +
#                            aes(x = CE.time,
#                                y = M.H,
#                                colour = intensity) +
#                            #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                            geom_point(size = 1) +
#                            geom_vline(
#                              xintercept = isolate(input$rt_min_cut_newSample),
#                              color = "gray",
#                              linetype = "dashed"
#                            ) +
#                            ggplot2::annotate(
#                              "rect",
#                              xmin = 0,
#                              xmax = isolate(input$rt_min_cut_newSample),
#                              ymin = -Inf ,
#                              ymax = Inf,
#                              alpha = 0.5,
#                              fill = "gray"
#                            ) +
#                            scale_color_viridis_c(option = "inferno", direction = -1) +
#                            ylab("Mass (M+H) (Da)") +
#                            xlab(paste(
#                              "CE-time (",
#                              req(input$UnitTime_sampleCutting_newSample),
#                              ")"
#                            )) +
#                            coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                            ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                            expand = TRUE) +
#                            ggtitle(paste(
#                              "Sample selected :",
#                              req(input$sample_selectedCutting_newSample),
#                              "\n"
#                            )) +
                           
#                            scale_x_continuous(n.breaks = 14) +
#                            #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
#                            #facet_grid(vars(sample), vars())+
#                            #option_graphe.3
#                            theme_ben() +
#                            labs(colour = "log2 Intensity") +
#                            theme(
#                              plot.title = element_text(
#                                size = rel(0.9),
#                                face = "bold",
#                                color = "#760001",
#                                margin = margin(0, 0, 5, 0),
#                                hjust = 0.5
#                              ),
#                              plot.subtitle = element_text(hjust = 0.5)
#                            )
                         
#                        }
                       
                       
                       
#                      })
                   
#                    ## Mouse position
#                    # output$sample_selectedCutting_Plot_info <- renderText({
#                    #   paste0("Mouse position : ",
#                    #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                    #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                    # })
                   
#                    output$sample_selectedCutting_Plot_info_newSample <-
#                      renderText({
#                        paste0(
#                          "Mouse position: ",
#                          xy_str(
#                            input$sample_selectedCutting_hover_newSample,
#                            "CE-time",
#                            "M+H"
#                          ),
#                          "Click: ",
#                          xy_str(
#                            input$sample_selectedCutting_click_newSample,
#                            "CE-time",
#                            "M+H"
#                          )
#                        )
#                        # paste0("Mouse position : ",
#                        #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                        #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                      })
                   
#                    ## Bulle info
                   
#                    #### info-bulle
#                    output$sample_selectedCutting_hover_info_newSample <-
#                      renderUI({
#                        hover <- req(input$sample_selectedCutting_hover_newSample)
                       
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          point <-
#                            nearPoints(
#                              req(
#                                RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                              ),
#                              hover,
#                              threshold = 5,
#                              maxpoints = 1,
#                              addDist = TRUE
#                            )
#                          if (nrow(point) == 0)
#                            return(NULL)
                         
#                          # calculate point position INSIDE the image as percent of total dimensions
#                          # from left (horizontal) and from top (vertical)
#                          left_pct <-
#                            (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                          top_pct <-
#                            (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
#                          # calculate distance from left and bottom side of the picture in pixels
#                          left_px <-
#                            hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                          top_px <-
#                            hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
#                          # create style property fot tooltip
#                          # background color is set so tooltip is a bit transparent
#                          # z-index is set so we are sure are tooltip will be on top
#                          style <-
#                            paste0(
#                              "position:absolute; z-index:100; background-color: #760001; color: white;",
#                              "left:",
#                              left_px + 2,
#                              "px; top:",
#                              top_px + 2,
#                              "px;"
#                            )
                         
#                          # actual tooltip created as wellPanel
#                          div(class = "well well-sm",
#                              style = style,
#                              p(HTML(
#                                paste0(
#                                  "<span class='bullText'> CE-time: </span>",
#                                  round(point$CE.time, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> M+H: </span>",
#                                  round(point$M.H, 4),
#                                  "<br/>",
#                                  "<span class='bullText'> log2 Intensity: </span>",
#                                  round(point$intensity, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> Intensity: </span>",
#                                  round(2 ^ (point$intensity), 0),
#                                  "<br/>"
#                                )
#                              )))
#                        }
                       
                       
                       
                       
                       
#                      })
                   
#                    if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
#                        c(isolate(input$rt_min_cut_newSample), NA)
#                    }
                   
                   
#                  } else if (is.na(input$rt_min_cut_newSample) &
#                             !is.na(input$rt_max_cut_newSample)) {
#                    print("cutoff")
#                    output$sample_selectedCutting_Plot_newSample <-
#                      renderPlot({
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                          shinyjs::show("mousepositionSampleCutting_newSample")
                         
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                            ggplot() +
#                            aes(x = CE.time,
#                                y = M.H,
#                                colour = intensity) +
#                            #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                            geom_point(size = 1) +
#                            geom_vline(
#                              xintercept = isolate(input$rt_max_cut_newSample),
#                              color = "gray",
#                              linetype = "dashed"
#                            ) +
#                            ggplot2::annotate(
#                              "rect",
#                              xmin = isolate(input$rt_max_cut_newSample),
#                              xmax = Inf,
#                              ymin = -Inf ,
#                              ymax = Inf,
#                              alpha = 0.5,
#                              fill = "gray"
#                            ) +
#                            scale_color_viridis_c(option = "inferno", direction = -1) +
#                            ylab("Mass (M+H) (Da)") +
#                            xlab(paste(
#                              "CE-time (",
#                              req(input$UnitTime_sampleCutting_newSample),
#                              ")"
#                            )) +
#                            coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                            ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                            expand = TRUE) +
#                            ggtitle(paste(
#                              "Sample selected :",
#                              req(input$sample_selectedCutting_newSample),
#                              "\n"
#                            )) +
                           
#                            scale_x_continuous(n.breaks = 14) +
#                            #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
#                            #facet_grid(vars(sample), vars())+
#                            #option_graphe.3
#                            theme_ben() +
#                            labs(colour = "log2 Intensity") +
#                            theme(
#                              plot.title = element_text(
#                                size = rel(0.9),
#                                face = "bold",
#                                color = "#760001",
#                                margin = margin(0, 0, 5, 0),
#                                hjust = 0.5
#                              ),
#                              plot.subtitle = element_text(hjust = 0.5)
#                            )
                         
#                        }
                       
                       
                       
#                      })
                   
#                    ## Mouse position
#                    # output$sample_selectedCutting_Plot_info <- renderText({
#                    #   paste0("Mouse position : ",
#                    #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                    #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                    # })
                   
#                    output$sample_selectedCutting_Plot_info_newSample <-
#                      renderText({
#                        paste0(
#                          "Mouse position: ",
#                          xy_str(
#                            input$sample_selectedCutting_hover_newSample,
#                            "CE-time",
#                            "M+H"
#                          ),
#                          "Click: ",
#                          xy_str(
#                            input$sample_selectedCutting_click_newSample,
#                            "CE-time",
#                            "M+H"
#                          )
#                        )
#                        # paste0("Mouse position : ",
#                        #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                        #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                      })
                   
#                    ## Bulle info
                   
#                    #### info-bulle
#                    output$sample_selectedCutting_hover_info_newSample <-
#                      renderUI({
#                        hover <- req(input$sample_selectedCutting_hover_newSample)
                       
#                        if (!is.null(
#                          RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                        )) {
#                          point <-
#                            nearPoints(
#                              req(
#                                RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                              ),
#                              hover,
#                              threshold = 5,
#                              maxpoints = 1,
#                              addDist = TRUE
#                            )
#                          if (nrow(point) == 0)
#                            return(NULL)
                         
#                          # calculate point position INSIDE the image as percent of total dimensions
#                          # from left (horizontal) and from top (vertical)
#                          left_pct <-
#                            (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                          top_pct <-
#                            (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
#                          # calculate distance from left and bottom side of the picture in pixels
#                          left_px <-
#                            hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                          top_px <-
#                            hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
#                          # create style property fot tooltip
#                          # background color is set so tooltip is a bit transparent
#                          # z-index is set so we are sure are tooltip will be on top
#                          style <-
#                            paste0(
#                              "position:absolute; z-index:100; background-color: #760001; color: white;",
#                              "left:",
#                              left_px + 2,
#                              "px; top:",
#                              top_px + 2,
#                              "px;"
#                            )
                         
#                          # actual tooltip created as wellPanel
#                          div(class = "well well-sm",
#                              style = style,
#                              p(HTML(
#                                paste0(
#                                  "<span class='bullText'> CE-time: </span>",
#                                  round(point$CE.time, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> M+H: </span>",
#                                  round(point$M.H, 4),
#                                  "<br/>",
#                                  "<span class='bullText'> log2 Intensity: </span>",
#                                  round(point$intensity, 2),
#                                  "<br/>",
#                                  "<span class='bullText'> Intensity: </span>",
#                                  round(2 ^ (point$intensity), 0),
#                                  "<br/>"
#                                )
#                              )))
#                        }
                       
                       
                       
                       
                       
#                      })
                   
#                    if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
#                        c(NA, isolate(input$rt_max_cut_newSample))
#                    }
                   
                   
#                  } else  if (is.na(input$rt_min_cut_newSample) &
#                              is.na(input$rt_max_cut_newSample)) {
#                    if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
#                        c(NA, NA)
                     
#                    }
#                  }
                 
#                } else {
#                  output$sample_selectedCutting_Plot_newSample <- renderPlot({
                   
#                  })
#                  output$sample_selectedCutting_Plot_info_newSample <-
#                    renderText({
                     
#                    })
#                  output$sample_selectedCutting_hover_info_newSample <-
#                    renderUI({
                     
#                    })
#                  hide("UnitTime_sampleCutting_id_newSample")
#                }
               
               
               
               
#              })



# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$sample_selectedCutting_newSample
#              },
#              handlerExpr = {
#                updateNumericInput(
#                  session = session,
#                  inputId = "rt_min_cut_newSample",
#                  value = as.numeric(
#                    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                  )
#                )
               
#                updateNumericInput(
#                  session = session,
#                  inputId = "rt_max_cut_newSample",
#                  value = as.numeric(
#                    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                  )
#                )
               
               
#              })


# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$sample_selectedCutting_newSample
#              },
#              handlerExpr = {
#                if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
#                  if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#                    if (!is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                    ) &
#                    !is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                    )) {
#                      print("Selectsample")
#                      output$sample_selectedCutting_Plot_newSample <-
#                        renderPlot({
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                            shinyjs::show("mousepositionSampleCutting_newSample")
                           
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                              ggplot() +
#                              aes(x = CE.time,
#                                  y = M.H,
#                                  colour = intensity) +
#                              #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                              geom_point(size = 1) +
#                              geom_vline(
#                                xintercept = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                                ),
#                                color = "gray",
#                                linetype = "dashed"
#                              ) +
#                              geom_vline(
#                                xintercept = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                                ),
#                                color = "gray",
#                                linetype = "dashed"
#                              ) +
#                              ggplot2::annotate(
#                                "rect",
#                                xmin = c(
#                                  0,
#                                  as.numeric(
#                                    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                                  )
#                                ),
#                                xmax = c(
#                                  as.numeric(
#                                    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                                  ),
#                                  Inf
#                                ),
#                                ymin = -Inf ,
#                                ymax = Inf,
#                                alpha = 0.5,
#                                fill = "gray"
#                              ) +
#                              scale_color_viridis_c(option = "inferno", direction = -1) +
#                              ylab("Mass (M+H) (Da)") +
#                              xlab(paste(
#                                "CE-time (",
#                                req(input$UnitTime_sampleCutting_newSample),
#                                ")"
#                              )) +
#                              coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                              ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                              expand = TRUE) +
#                              ggtitle(paste(
#                                "Sample selected :",
#                                req(input$sample_selectedCutting_newSample),
#                                "\n"
#                              )) +
                             
#                              scale_x_continuous(n.breaks = 14) +
#                              #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
#                              #facet_grid(vars(sample), vars())+
#                              #option_graphe.3
#                              theme_ben() +
#                              labs(colour = "log2 Intensity") +
#                              theme(
#                                plot.title = element_text(
#                                  size = rel(0.9),
#                                  face = "bold",
#                                  color = "#760001",
#                                  margin = margin(0, 0, 5, 0),
#                                  hjust = 0.5
#                                ),
#                                plot.subtitle = element_text(hjust = 0.5)
#                              )
                           
#                          }
                         
                         
                         
#                        })
                     
#                      ## Mouse position
#                      # output$sample_selectedCutting_Plot_info <- renderText({
#                      #   paste0("Mouse position : ",
#                      #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                      #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                      # })
                     
#                      output$sample_selectedCutting_Plot_info_newSample <-
#                        renderText({
#                          paste0(
#                            "Mouse position: ",
#                            xy_str(
#                              input$sample_selectedCutting_hover_newSample,
#                              "CE-time",
#                              "M+H"
#                            ),
#                            "Click: ",
#                            xy_str(
#                              input$sample_selectedCutting_click_newSample,
#                              "CE-time",
#                              "M+H"
#                            )
#                          )
#                          # paste0("Mouse position : ",
#                          #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                          #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                        })
#                      ## Bulle info
                     
#                      #### info-bulle
#                      output$sample_selectedCutting_hover_info_newSample <-
#                        renderUI({
#                          hover <- req(input$sample_selectedCutting_hover_newSample)
                         
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            point <-
#                              nearPoints(
#                                req(
#                                  RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                                ),
#                                hover,
#                                threshold = 5,
#                                maxpoints = 1,
#                                addDist = TRUE
#                              )
#                            if (nrow(point) == 0)
#                              return(NULL)
                           
#                            # calculate point position INSIDE the image as percent of total dimensions
#                            # from left (horizontal) and from top (vertical)
#                            left_pct <-
#                              (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                            top_pct <-
#                              (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
#                            # calculate distance from left and bottom side of the picture in pixels
#                            left_px <-
#                              hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                            top_px <-
#                              hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
#                            # create style property fot tooltip
#                            # background color is set so tooltip is a bit transparent
#                            # z-index is set so we are sure are tooltip will be on top
#                            style <-
#                              paste0(
#                                "position:absolute; z-index:100; background-color: #760001; color: white;",
#                                "left:",
#                                left_px + 2,
#                                "px; top:",
#                                top_px + 2,
#                                "px;"
#                              )
                           
#                            # actual tooltip created as wellPanel
#                            div(class = "well well-sm",
#                                style = style,
#                                p(HTML(
#                                  paste0(
#                                    "<span class='bullText'> CE-time: </span>",
#                                    round(point$CE.time, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> M+H: </span>",
#                                    round(point$M.H, 4),
#                                    "<br/>",
#                                    "<span class='bullText'> log2 Intensity: </span>",
#                                    round(point$intensity, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> Intensity: </span>",
#                                    round(2 ^ (point$intensity), 0),
#                                    "<br/>"
#                                  )
#                                )))
#                          }
                         
                         
                         
                         
                         
#                        })
                     
#                      # if(!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable)) {
#                      #
#                      #   RvarsPeakDetectionNewSample$samplesCuttingTable[input$sample_selectedCutting,]<-
#                      #     c(isolate(input$rt_min_cut),isolate(input$rt_max_cut), isolate(input$UnitTime_sampleCutting))
#                      # }
                     
                     
                     
#                    } else if (!is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                    ) &
#                    is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                    )) {
#                      print("Selectsample")
#                      output$sample_selectedCutting_Plot_newSample <-
#                        renderPlot({
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                            shinyjs::show("mousepositionSampleCutting_newSample")
                           
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                              ggplot() +
#                              aes(x = CE.time,
#                                  y = M.H,
#                                  colour = intensity) +
#                              #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                              geom_point(size = 1) +
#                              geom_vline(
#                                xintercept = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                                ),
#                                color = "gray",
#                                linetype = "dashed"
#                              ) +
#                              ggplot2::annotate(
#                                "rect",
#                                xmin = 0,
#                                xmax = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                                ),
#                                ymin = -Inf ,
#                                ymax = Inf,
#                                alpha = 0.5,
#                                fill = "gray"
#                              ) +
#                              scale_color_viridis_c(option = "inferno", direction = -1) +
#                              ylab("Mass (M+H) (Da)") +
#                              xlab(paste(
#                                "CE-time (",
#                                req(input$UnitTime_sampleCutting_newSample),
#                                ")"
#                              )) +
#                              coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                              ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                              expand = TRUE) +
#                              ggtitle(paste(
#                                "Sample selected :",
#                                req(input$sample_selectedCutting_newSample),
#                                "\n"
#                              )) +
                             
#                              scale_x_continuous(n.breaks = 14) +
#                              #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
#                              #facet_grid(vars(sample), vars())+
#                              #option_graphe.3
#                              theme_ben() +
#                              labs(colour = "log2 Intensity") +
#                              theme(
#                                plot.title = element_text(
#                                  size = rel(0.9),
#                                  face = "bold",
#                                  color = "#760001",
#                                  margin = margin(0, 0, 5, 0),
#                                  hjust = 0.5
#                                ),
#                                plot.subtitle = element_text(hjust = 0.5)
#                              )
                           
#                          }
                         
                         
                         
#                        })
                     
#                      ## Mouse position
#                      # output$sample_selectedCutting_Plot_info <- renderText({
#                      #   paste0("Mouse position : ",
#                      #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                      #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                      # })
                     
#                      output$sample_selectedCutting_Plot_info_newSample <-
#                        renderText({
#                          paste0(
#                            "Mouse position: ",
#                            xy_str(
#                              input$sample_selectedCutting_hover_newSample,
#                              "CE-time",
#                              "M+H"
#                            ),
#                            "Click: ",
#                            xy_str(
#                              input$sample_selectedCutting_click_newSample,
#                              "CE-time",
#                              "M+H"
#                            )
#                          )
#                          # paste0("Mouse position : ",
#                          #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                          #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                        })
#                      ## Bulle info
                     
#                      #### info-bulle
#                      output$sample_selectedCutting_hover_info_newSample <-
#                        renderUI({
#                          hover <- req(input$sample_selectedCutting_hover_newSample)
                         
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            point <-
#                              nearPoints(
#                                req(
#                                  RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                                ),
#                                hover,
#                                threshold = 5,
#                                maxpoints = 1,
#                                addDist = TRUE
#                              )
#                            if (nrow(point) == 0)
#                              return(NULL)
                           
#                            # calculate point position INSIDE the image as percent of total dimensions
#                            # from left (horizontal) and from top (vertical)
#                            left_pct <-
#                              (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                            top_pct <-
#                              (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
#                            # calculate distance from left and bottom side of the picture in pixels
#                            left_px <-
#                              hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                            top_px <-
#                              hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
#                            # create style property fot tooltip
#                            # background color is set so tooltip is a bit transparent
#                            # z-index is set so we are sure are tooltip will be on top
#                            style <-
#                              paste0(
#                                "position:absolute; z-index:100; background-color: #760001; color: white;",
#                                "left:",
#                                left_px + 2,
#                                "px; top:",
#                                top_px + 2,
#                                "px;"
#                              )
                           
#                            # actual tooltip created as wellPanel
#                            div(class = "well well-sm",
#                                style = style,
#                                p(HTML(
#                                  paste0(
#                                    "<span class='bullText'> CE-time: </span>",
#                                    round(point$CE.time, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> M+H: </span>",
#                                    round(point$M.H, 4),
#                                    "<br/>",
#                                    "<span class='bullText'> log2 Intensity: </span>",
#                                    round(point$intensity, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> Intensity: </span>",
#                                    round(2 ^ (point$intensity), 0),
#                                    "<br/>"
#                                  )
#                                )))
#                          }
                         
                         
                         
                         
                         
#                        })
                     
#                      # if(!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable)) {
#                      #
#                      #   RvarsPeakDetectionNewSample$samplesCuttingTable[input$sample_selectedCutting,]<-
#                      #     c(isolate(input$rt_min_cut),isolate(input$rt_max_cut), isolate(input$UnitTime_sampleCutting))
#                      # }
                     
                     
                     
#                    } else if (is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
#                    ) &
#                    !is.na(
#                      RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                    )) {
#                      print("Selectsample")
#                      output$sample_selectedCutting_Plot_newSample <-
#                        renderPlot({
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            shinyjs::show("UnitTime_sampleCutting_id_newSample")
#                            shinyjs::show("mousepositionSampleCutting_newSample")
                           
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
#                              ggplot() +
#                              aes(x = CE.time,
#                                  y = M.H,
#                                  colour = intensity) +
#                              #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
#                              geom_point(size = 1) +
#                              geom_vline(
#                                xintercept = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                                ),
#                                color = "gray",
#                                linetype = "dashed"
#                              ) +
#                              ggplot2::annotate(
#                                "rect",
#                                xmin = as.numeric(
#                                  RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
#                                ),
#                                xmax = Inf,
#                                ymin = -Inf ,
#                                ymax = Inf,
#                                alpha = 0.5,
#                                fill = "gray"
#                              ) +
#                              scale_color_viridis_c(option = "inferno", direction = -1) +
#                              ylab("Mass (M+H) (Da)") +
#                              xlab(paste(
#                                "CE-time (",
#                                req(input$UnitTime_sampleCutting_newSample),
#                                ")"
#                              )) +
#                              coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
#                                              ylim = rangesZoomSample_selectedCutting_newSample$y,
#                                              expand = TRUE) +
#                              ggtitle(paste(
#                                "Sample selected :",
#                                req(input$sample_selectedCutting_newSample),
#                                "\n"
#                              )) +
                             
#                              scale_x_continuous(n.breaks = 14) +
#                              #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
#                              #facet_grid(vars(sample), vars())+
#                              #option_graphe.3
#                              theme_ben() +
#                              labs(colour = "log2 Intensity") +
#                              theme(
#                                plot.title = element_text(
#                                  size = rel(0.9),
#                                  face = "bold",
#                                  color = "#760001",
#                                  margin = margin(0, 0, 5, 0),
#                                  hjust = 0.5
#                                ),
#                                plot.subtitle = element_text(hjust = 0.5)
#                              )
                           
#                          }
                         
                         
                         
#                        })
                     
#                      ## Mouse position
#                      # output$sample_selectedCutting_Plot_info <- renderText({
#                      #   paste0("Mouse position : ",
#                      #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
#                      #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
#                      # })
                     
#                      output$sample_selectedCutting_Plot_info_newSample <-
#                        renderText({
#                          paste0(
#                            "Mouse position: ",
#                            xy_str(
#                              input$sample_selectedCutting_hover_newSample,
#                              "CE-time",
#                              "M+H"
#                            ),
#                            "Click: ",
#                            xy_str(
#                              input$sample_selectedCutting_click_newSample,
#                              "CE-time",
#                              "M+H"
#                            )
#                          )
#                          # paste0("Mouse position : ",
#                          #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
#                          #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
#                        })
#                      ## Bulle info
                     
#                      #### info-bulle
#                      output$sample_selectedCutting_hover_info_newSample <-
#                        renderUI({
#                          hover <- req(input$sample_selectedCutting_hover_newSample)
                         
#                          if (!is.null(
#                            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                          )) {
#                            point <-
#                              suppressWarnings(
#                                nearPoints(
#                                  req(
#                                    RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
#                                  )
#                                ),
#                                hover,
#                                threshold = 5,
#                                maxpoints = 1,
#                                addDist = TRUE
#                              )
#                            if (nrow(point) == 0)
#                              return(NULL)
                           
#                            # calculate point position INSIDE the image as percent of total dimensions
#                            # from left (horizontal) and from top (vertical)
#                            left_pct <-
#                              (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                            top_pct <-
#                              (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
#                            # calculate distance from left and bottom side of the picture in pixels
#                            left_px <-
#                              hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                            top_px <-
#                              hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
#                            # create style property fot tooltip
#                            # background color is set so tooltip is a bit transparent
#                            # z-index is set so we are sure are tooltip will be on top
#                            style <-
#                              paste0(
#                                "position:absolute; z-index:100; background-color: #760001; color: white;",
#                                "left:",
#                                left_px + 2,
#                                "px; top:",
#                                top_px + 2,
#                                "px;"
#                              )
                           
#                            # actual tooltip created as wellPanel
#                            div(class = "well well-sm",
#                                style = style,
#                                p(HTML(
#                                  paste0(
#                                    "<span class='bullText'> CE-time: </span>",
#                                    round(point$CE.time, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> M+H: </span>",
#                                    round(point$M.H, 4),
#                                    "<br/>",
#                                    "<span class='bullText'> log2 Intensity: </span>",
#                                    round(point$intensity, 2),
#                                    "<br/>",
#                                    "<span class='bullText'> Intensity: </span>",
#                                    round(2 ^ (point$intensity), 0),
#                                    "<br/>"
#                                  )
#                                )))
#                          }
                         
                         
                         
                         
                         
#                        })
                     
                     
                     
#                    }
                   
#                  }
#                } else {
#                  output$sample_selectedCutting_Plot_newSample <- renderPlot({
                   
#                  })
#                  output$sample_selectedCutting_Plot_info_newSample <-
#                    renderText({
                     
#                    })
#                  output$sample_selectedCutting_hover_info_newSample <-
#                    renderUI({
                     
#                    })
#                  hide("UnitTime_sampleCutting_id_newSample")
#                }
               
               
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Save samples cutting ~~~~~~~~~~~~~~~~~~~~~~~~#*
# peaks_mono_iso_sample_selectedCutting_newSample <- reactive({
#   if (!is.null(names(
#     RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#   ))) {
#     table_to_save <-
#       RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
    
#     for (i in rownames(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
#       if (RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, "Unit"] ==
#           "Second") {
#         if (!is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         !is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
#                 rt,
#               rt < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#             )
#         } else if (!is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
#                 rt
#             )
#         } else if (is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         !is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               rt < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#             )
#         } else if (is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]]
#         }
#       } else if (RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, "Unit"] ==
#                  "Minute") {
#         if (!is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         !is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
#                 rt / 60,
#               rt / 60 < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#             )
#         } else if (!is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
#                 rt / 60
#             )
#         } else if (is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         !is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
#             dplyr::filter(
#               rt / 60 < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#             )
#         } else if (is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
#         ) &
#         is.na(
#           RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
#         )) {
#           table_to_save[[i]] <-
#             RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]]
#         }
#       }
      
      
#     }
    
#     table_to_save
    
    
#   }
  
# })



# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button server for cutting new samples ~~~~~~~~~~~~~~~~~~~~~~~~#*
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$validCuttingRun_newSample
#              },
#              handlerExpr = {
#                ask_confirmation(
#                  inputId = "validCuttingRun_confirmation_newSample",
#                  title = NULL,
#                  text = tags$b(
#                    #icon("info"),
#                    paste0(
#                      "Are you sure you’re done cutting all your samples?",
#                      "\n",
#                      "Once you click OK, you may resume all if you want to go back."
#                    ),
#                    style = "color: #FA5858;"
#                  ),
#                  btn_labels = c("Cancel", "OK"),
#                  btn_colors = c("#00BFFF", "#FE2E2E"),
#                  html = TRUE
#                )
               
               
#              })

# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ResetCuttingRun_newSample
#              },
#              handlerExpr = {
#                ask_confirmation(
#                  inputId = "ResetCuttingRun_confirmation_newSample",
#                  title = NULL,
#                  text = tags$b(#icon("info"),
#                    "Do you really want to resume the cutting of all samples ?",
#                    style = "color: #FA5858;"),
#                  btn_labels = c("Cancel", "OK"),
#                  btn_colors = c("#00BFFF", "#FE2E2E"),
#                  html = TRUE
#                )
               
               
#              })



# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$validCuttingRun_confirmation_newSample
#              },
#              handlerExpr = {
#                if (input$validCuttingRun_confirmation_newSample == TRUE) {
#                  disable("RetentionTimeFiltering_id_newSample")
#                  shinyjs::show("id_ResetCuttingRun_newSample")
#                  enable("SaveCuttingSample_newSample")
#                  hide("id_validCuttingRun_newSample")
#                  enable("GoToPeakView_newSample")
#                  enable("id_SelectRefrenceSamplePanel_newSample")
                 
#                }
#              })



# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$ResetCuttingRun_confirmation_newSample
#              },
#              handlerExpr = {
#                if (input$ResetCuttingRun_confirmation_newSample == TRUE) {
#                  enable("RetentionTimeFiltering_id_newSample")
#                  hide("id_ResetCuttingRun_newSample")
#                  shinyjs::show("id_validCuttingRun_newSample")
#                  disable("SaveCuttingSample_newSample")
#                  shinyjs::reset("rt_min_cut_newSample")
#                  shinyjs::reset("rt_max_cut_newSample")
#                  disable("GoToPeakView_newSample")
#                  disable("id_SelectRefrenceSamplePanel_newSample")
                 
                 
#                  if (!is.null(names(
#                    RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#                  ))) {
#                    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
#                      data.frame(
#                        row.names = names(
#                          RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#                        ),
#                        rt_min_cut_newSample = rep(
#                          NA,
#                          length(
#                            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#                          )
#                        ),
#                        rt_max_cut_newSample = rep(
#                          NA,
#                          length(
#                            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#                          )
#                        ),
#                        Unit = rep(
#                          "Second",
#                          length(
#                            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
#                          )
#                        )
#                      )
#                  }
                 
#                  updateAwesomeRadio(session = session,
#                                     inputId = "UnitTime_sampleCutting_newSample",
#                                     selected = "Second")
#                  RvarsPeakDetectionNewSample$Second <- TRUE
#                }
#              })




# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~ Correction time to the reference map  ~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~ Correction time with kernel Density ~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

# ##~~~~~~~~~~~~ update input 'SelectSample_KernelDensity_newSample' ~~~~~~~~~#

# observe({
#   if (!is.null(peaks_mono_iso_sample_selectedCutting_newSample())) {
#     sample_name <-
#       names(peaks_mono_iso_sample_selectedCutting_newSample())
    
#     RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
#       peaks_mono_iso_sample_selectedCutting_newSample()
    
#     peaks <-
#       RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list
#     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection <-
#       peaks
    
#     updatePickerInput(session = session,
#                       inputId = "SelectSample_KernelDensity_newSample",
#                       choices = sample_name)
    
    
    
#   } else {
#     RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
#       peaks_mono_iso_sample_selectedCutting_newSample()
    
#     peaks <-
#       RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list
#     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection <-
#       peaks
    
#     updatePickerInput(
#       session = session,
#       inputId = "SelectSample_KernelDensity_newSample",
#       choices = character(0),
#       selected = character(0)
#     )
    
    
#   }
# })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~ Forced reactive Kernel density filter when choosing samples when cutting sample~~#
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                c(input$cutOff_newSample)
#              },
#              handlerExpr = {
#                if (!is.null(peaks_mono_iso_sample_selectedCutting_newSample())) {
#                  sample_name <-
#                    names(peaks_mono_iso_sample_selectedCutting_newSample())
                 
#                  RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
#                    peaks_mono_iso_sample_selectedCutting_newSample()
                 
#                  updatePickerInput(
#                    session = session,
#                    inputId = "SelectSample_KernelDensity_newSample",
#                    choices = character(0),
#                    selected = character(0)
#                  )
                 
#                  updatePickerInput(session = session,
#                                    inputId = "SelectSample_KernelDensity_newSample",
#                                    choices = sample_name)
#                }
               
#              })

# ## View data
# # observe({
# #   if(!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)){
# #     View(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)
# #   }
# # })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~ Kernel density filter when choosing samples ~~~~~~~~~#
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$SelectSample_KernelDensity_newSample
#              },
#              handlerExpr = {
#                if (!is.null(input$SelectSample_KernelDensity_newSample) &
#                    !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
#                    !is.null(RvarsPeakDetectionNewSample$map_ref)) {
#                  ##Matched samples
                 
#                  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
#                         local = TRUE)
                 
#                  ref <- RvarsPeakDetectionNewSample$map_ref[2:4]
#                  colnames(ref) <- c("mz", "rt", "maxo")
                 
#                  ref$maxo <- 2 ^ (ref$maxo)
                 
#                  table.newSample <-
#                    RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]
#                  table.newSample <-
#                    table.newSample[, c("mz", "rt", "maxo", "sample")]
                 
#                  resMatch.newSample <- matchMz(
#                    x = ref,
#                    table = table.newSample,
#                    ppm_tolereance = 1000,
#                    mzcol = "mz",
#                    rtcol = "rt" ,
#                    session = session
#                  )
                 
                 
                 
#                  RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter <-
#                    resMatch.newSample$MatchTable[!is.na(resMatch.newSample$MatchTable$rt.2),
#                                                  c("mz.1",
#                                                    "rt.1",
#                                                    "maxo.1",
#                                                    "mz.2",
#                                                    "rt.2",
#                                                    "rt.2",
#                                                    "maxo.2",
#                                                    "sample.2")]
                 
#                  ##Log2 intensity sample to align
#                  RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$maxo.2 <-
#                    log2(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$maxo.2)
                 
                 
                 
#                  ## Filter intensity
#                  observe({
#                    if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter)) {
#                      RvarsPeakDetectionNewSample$Data_Plot.newSample <-
#                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter %>%
#                        dplyr::filter(maxo.2 >= req(input$intensityFilter_newSample))
#                    }
#                  })
                 
#                  ## Median line
#                  if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
#                    median_line.newSample <-
#                      seq(min(
#                        range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2)[1],
#                        range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1)[1]
#                      ),
#                      max(
#                        range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2)[2],
#                        range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1)[2]
#                      ), by = 50)
                   
#                    median_line_data.newSample <-
#                      data.frame(x =  median_line.newSample,
#                                 y  =  median_line.newSample)
#                  }
                 
                 
#                  ####~~~~~~~~~~~~~~~~ Correction with Kernel Density ~~~~~~~~~~~~~~~~~~~~###
                 
#                  #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
#                  data_dens_filter.newSample <-
#                    reactive(if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample) &
#                                 nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample) !=
#                                 0) {
#                      dens <-
#                        kde2d(
#                          RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2,
#                          RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1,
#                          h = input$bandwidth_Filter_newSample,
#                          n = input$gridSize_newSample
#                        )
#                      nx <-
#                        nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)
#                      df <- expand.grid(x = dens$x, y = dens$y)
#                      df$density <- (as.vector(dens$z))
#                      df$density <- df$density / max(df$density)
#                      #df$group <- data$group[1]
#                      df$ndensity <-
#                        df$density / max(df$density, na.rm = TRUE)
#                      df$count <- nx * df$density
#                      df$n <- nx
#                      df$level <- 1
#                      df$piece <- 1
#                      df_filter <- df %>%
#                        dplyr::filter(density >= req(input$minDensity_newSample))
                     
#                      colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                     
#                      df_filter
#                    })
                 
                 
#                  #~~~~~~~~~~~~~~~~~~~~~~~~ Plot filter density ~~~~~~~~~~~~~~~~~~~~~~~#
#                  output$DensityFilterPlot_newSample <- renderPlot({
#                    if (length(data_dens_filter.newSample()) != 0) {
#                      if (!is.null(data_dens_filter.newSample()) &
#                          nrow(data_dens_filter.newSample()) != 0 &
#                          nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample) !=
#                          0) {
#                        p1 <- RvarsPeakDetectionNewSample$Data_Plot.newSample %>%
#                          ggplot() +
#                          aes(x = rt.2, y = rt.1) + 
#                          geom_point(aes(color = maxo.2), size = 0.8) +
#                          scale_color_viridis_c(option = "H", direction = -1) +
#                          geom_density_2d(
#                            h = input$bandwidth_Filter_newSample,
#                            n = input$gridSize_newSample
#                          ) +
#                          #scale_color_viridis_c(option = "inferno", direction = -1) +
#                          scale_x_continuous(n.breaks = 14) +
#                          scale_y_continuous(n.breaks = 14) +
                         
#                          coord_cartesian(xlim = c(min(
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
#                            )[1],
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
#                            )[1]
#                          ),
#                          max(
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
#                            )[2],
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
#                            )[2]
#                          )),
                         
#                          ylim = c(min(
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
#                            )[1],
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
#                            )[1]
#                          ),
#                          max(
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
#                            )[2],
#                            range(
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
#                            )[2]
#                          ))) +
                         
                         
#                          xlab(
#                            paste(
#                              "CE-time (",
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$sample.2,
#                              ")"
#                            )
#                          ) +
#                          ylab("CE-time (reference sample)") +
#                          #labs(colour ="log2 Intensity")+
#                          theme_ben() +
#                          labs(colour = "log2 Intensity") 
                       
#                        p2 <-
#                          ggplot(data_dens_filter.newSample(), aes(x = rt.2, y = rt.1)) +
#                          geom_point(aes(color = density), size = 0.5) +
                         
#                          scale_x_continuous(n.breaks = 14) +
#                          scale_y_continuous(n.breaks = 14) +
                         
#                          coord_cartesian(xlim = c(min(
#                            range(data_dens_filter.newSample()$rt.2)[1],
#                            range(data_dens_filter.newSample()$rt.1)[1]
#                          ),
#                          max(
#                            range(data_dens_filter.newSample()$rt.2)[2],
#                            range(data_dens_filter.newSample()$rt.1)[2]
#                          )),
                         
#                          ylim = c(min(
#                            range(data_dens_filter.newSample()$rt.2)[1],
#                            range(data_dens_filter.newSample()$rt.1)[1]
#                          ),
#                          max(
#                            range(data_dens_filter.newSample()$rt.2)[2],
#                            range(data_dens_filter.newSample()$rt.1)[2]
#                          ))) +
                         
#                          xlab(
#                            paste(
#                              "CE-time (",
#                              RvarsPeakDetectionNewSample$Data_Plot.newSample$sample.2,
#                              ")"
#                            )
#                          ) +
#                          ylab("CE-time (Reference map)") +
                         
#                          theme_ben() +
#                          theme(
#                            legend.title = element_text(
#                              size = rel(0.95),
#                              face = "bold.italic",
#                              hjust = 0.5
#                            ),
#                            legend.text = element_text(size = rel(0.85), face = "bold.italic")
#                          )
                       
#                        grid.arrange(p1, p2, nrow = 2)
                       
#                      }
                     
#                    }
                   
#                  })
                 
#                }
               
#              })


# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~ Fit model kernel density estimation ~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                c(input$fitModel_newSample,
#                  input$SelectSample_KernelDensity_newSample)
               
#              },
#              handlerExpr = {
               
#                if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
                 
#                  if(nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)!=0){
#                    #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
#                    data_dens_filter.newSample <-
#                      reactive(if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
#                        dens <-
#                          kde2d(
#                            RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2,
#                            RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1,
#                            h = input$bandwidth_Filter_newSample,
#                            n = input$gridSize_newSample
#                          )
#                        nx <-
#                          nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)
#                        df <- expand.grid(x = dens$x, y = dens$y)
#                        df$density <- (as.vector(dens$z))
#                        df$density <- df$density / max(df$density)
#                        #df$group <- data$group[1]
#                        df$ndensity <-
#                          df$density / max(df$density, na.rm = TRUE)
#                        df$count <- nx * df$density
#                        df$n <- nx
#                        df$level <- 1
#                        df$piece <- 1
#                        df_filter <- df %>%
#                          dplyr::filter(density >= req(input$minDensity_newSample))
                       
#                        colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                       
#                        df_filter
#                      })
                   
#                    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Fit model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                    if (length(data_dens_filter.newSample()) != 0) {
#                      if (!is.null(data_dens_filter.newSample())) {
#                        dataDensity <- isolate(data_dens_filter.newSample())
                       
#                        if (!is.null(dataDensity)) {
#                          withProgress(message = 'Fit model...', value = 0, {
#                            incProgress(1 / 3, detail = "")
                           
#                            #~~~~~~~~~~~~~~~~~ Kernel density estimation ~~~~~~~~~~~~~~~~~~~~~~~#
#                            RvarsPeakDetectionNewSample$modelKernelDensity <-
#                              npreg(
#                                rt.1 ~ rt.2,
#                                bws = req(input$"bandwidth_Model_newSample"),
#                                bwtype = c("fixed", "generalized_nn", "adaptive_nn")[1],
#                                regtype = "ll",
#                                ckertype = input$KernelType_newSample,
#                                #bwmethod = "cv.aic",
#                                gradients = TRUE,
#                                data = dataDensity
#                              )
                           
#                            #~~~~~~~~~~~~~~~~~ Calculate prediction rt for sample selected ~~~~~~~~~~~~~~~~~~~~~~~#
#                            if (!is.null(RvarsPeakDetectionNewSample$modelKernelDensity)) {
#                              incProgress(1 / 3, detail = "")
                             
#                              ### correction rt new sample Kernel Density
#                              RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt <-
#                                predict(
#                                  RvarsPeakDetectionNewSample$modelKernelDensity,
#                                  newdata = data.frame(rt.2 = RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]$rt)
#                                )
                             
#                              ### Delete negative correction rt
                             
#                              # RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt<-
#                              #   RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt %>% dplyr::filter(rt>0)
#                              #
                             
                             
#                              ## ~~~~~~~~~~~~~~~~~~ Plot correction rt with kernel Density ~~~~~~~~~~~~~#
                             
#                              ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Before~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                              output$PlotCorrectionKernelDensity_Before_newSample <-
#                                renderPlot({
#                                  predict_data_model.np <-
#                                    data.frame(
#                                      rt.1 = predict(
#                                        RvarsPeakDetectionNewSample$modelKernelDensity,
#                                        newdata = data.frame(rt.2 = seq(
#                                          min(
#                                            range(
#                                              RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                            )[1],
#                                            range(
#                                              RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                            )[1]
#                                          ),
#                                          max(
#                                            range(
#                                              RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                            )[2],
#                                            range(
#                                              RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                            )[2]
#                                          )
#                                        ), by = 50)
#                                      ),
#                                      rt.2 = seq(min(
#                                        range(
#                                          RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                        )[1],
#                                        range(
#                                          RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                        )[1]
#                                      ),
#                                      max(
#                                        range(
#                                          RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                        )[2],
#                                        range(
#                                          RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                        )[2]
#                                      )),
#                                      by = 50
#                                    )
                                 
#                                  median_line <-
#                                    seq(min(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[1],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[1]
#                                    ),
#                                    max(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[2],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[2]
#                                    ),
#                                    by = 50)
                                 
#                                  median_line_data <-
#                                    data.frame(x =  median_line, y  =  median_line)
                                 
#                                  ggplot(
#                                    RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter,
#                                    aes(x = rt.2, y = rt.1)
#                                  ) +
#                                    geom_point(size = 0.5) +
                                   
#                                    coord_cartesian(xlim = c(min(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[1],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[1]
#                                    ),
#                                    max(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[2],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[2]
#                                    )),
#                                    ylim = c(min(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[1],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[1]
#                                    ),
#                                    max(
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
#                                      )[2],
#                                      range(
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
#                                      )[2]
#                                    ))) +
                                   
#                                    scale_x_continuous(n.breaks = 14) +
#                                    scale_y_continuous(n.breaks = 14) +
                                   
#                                    # xlab("CE-time (sample to align)")+
#                                    # ylab("CE-time (reference sample)")+
                                   
#                                    geom_line(
#                                      data = predict_data_model.np,
#                                      aes(
#                                        x = rt.2,
#                                        y = rt.1,
#                                        color = "Model"
#                                      ),
#                                      lwd = 1,
#                                      size = 1.5
#                                    ) +
#                                    #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
#                                    # geom_abline(yintercept = 0, lwd = 1, color = "green")+
#                                    geom_line(
#                                      data = median_line_data,
#                                      aes(
#                                        x = x,
#                                        y = x,
#                                        color = "Median"
#                                      ),
#                                      lwd = 1,
#                                      size = 1.5
#                                    ) +
#                                    ggtitle("Before CE-time correction") +
                                   
#                                    labs(
#                                      x = paste(
#                                        "CE-time (",
#                                        RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$sample.2,
#                                        ")"
#                                      ),
#                                      y = "CE-time (Reference map)",
#                                      color = "Legend"
#                                    ) +
                                   
#                                    scale_color_manual(values = c(
#                                      "Model" = "red",
#                                      "Median" = "green"
#                                    )) +
                                   
                                   
#                                    theme_ben() +
#                                    theme(
#                                      plot.title = element_text(
#                                        size = rel(1),
#                                        face = "bold",
#                                        color = "#760001",
#                                        margin = margin(0, 0, 5, 0),
#                                        hjust = 0.5
#                                      ),
#                                      plot.subtitle = element_text(hjust = 0.5),
#                                      plot.background = element_rect(fill = "aliceblue"),
#                                      legend.title = element_text(
#                                        size = rel(0.95),
#                                        face = "bold.italic",
#                                        hjust = 0.5
#                                      ),
#                                      legend.text = element_text(size = rel(0.85), face = "bold.italic")
#                                    )
                                 
#                                })
                             
#                              #### info-bulle
#                              output$PlotCorrectionKernelDensity_Before_hover_info_newSample <-
#                                renderUI({
#                                  hover <-
#                                    req(input$PlotCorrectionKernelDensity_Before_hover_newSample)
                                 
#                                  if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter)) {
#                                    point <-
#                                      nearPoints(
#                                        req(
#                                          RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter
#                                        ),
#                                        hover,
#                                        threshold = 5,
#                                        maxpoints = 1,
#                                        addDist = TRUE
#                                      )
#                                    if (nrow(point) == 0)
#                                      return(NULL)
                                   
#                                    # calculate point position INSIDE the image as percent of total dimensions
#                                    # from left (horizontal) and from top (vertical)
#                                    left_pct <-
#                                      (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                                    top_pct <-
#                                      (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                                   
#                                    # calculate distance from left and bottom side of the picture in pixels
#                                    left_px <-
#                                      hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                                    top_px <-
#                                      hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                                   
#                                    # create style property fot tooltip
#                                    # background color is set so tooltip is a bit transparent
#                                    # z-index is set so we are sure are tooltip will be on top
#                                    style <-
#                                      paste0(
#                                        "position:absolute; z-index:100; background-color: #760001; color: white;",
#                                        "left:",
#                                        left_px + 2,
#                                        "px; top:",
#                                        top_px + 2,
#                                        "px;"
#                                      )
                                   
#                                    # actual tooltip created as wellPanel
#                                    div(class = "well well-sm",
#                                        style = style,
#                                        p(HTML(
#                                          paste0(
#                                            "<span class='bullText'> M+H (ref): </span>",
#                                            round(point$mz.1, 4),
#                                            "<br/>",
#                                            "<span class='bullText'> CE-time (ref): </span>",
#                                            round(point$rt.1, 2),
#                                            "<br/>",
#                                            "<span class='bullText'> Intensity (ref): </span>",
#                                            round(point$maxo.1, 0),
#                                            "<br/>",
#                                            "<br>",
#                                            "<span class='bullText'> M+H (sample): </span>",
#                                            round(point$mz.2, 4),
#                                            "<br/>",
#                                            "<span class='bullText'> CE-time (sample): </span>",
#                                            round(point$rt.2, 2),
#                                            "<br/>",
#                                            "<span class='bullText'> Intensity (sample): </span>",
#                                            round(2 ^ (point$maxo.2), 0),
#                                            "<br/>"
#                                          )
#                                        )))
#                                  }
                                 
#                                })
                             
#                              incProgress(1 / 3, detail = "")
#                              ####~~~~~~~~~~~~~~~~~~~~ Plot After ~~~~~~~~~~~~~~~~~~~~~~~~#
#                              ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                              output$PlotCorrectionKernelDensity_After_newSample <-
#                                renderPlot({
#                                  if (!is.null(input$SelectSample_KernelDensity_newSample) &
#                                      !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
#                                      !is.null(RvarsPeakDetectionNewSample$map_ref) &
#                                      !is.null(
#                                        RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
#                                      )) {
#                                    source(
#                                      "lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
#                                      local = TRUE
#                                    )
                                   
#                                    ref <-
#                                      RvarsPeakDetectionNewSample$map_ref[2:4]
#                                    colnames(ref) <-
#                                      c("mz", "rt", "maxo")
                                   
#                                    ref$maxo <- 2 ^ (ref$maxo)
                                   
#                                    table.after <-
#                                      RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]
                                   
#                                    table.after <-
#                                      table.after[, c("mz", "rt", "maxo", "sample")]
                                   
                                   
#                                    resMatch.after <- matchMz(
#                                      x = ref,
#                                      table = table.after,
#                                      ppm_tolereance = 1000,
#                                      mzcol = "mz",
#                                      rtcol = "rt" ,
#                                      session = session
#                                    )
                                   
#                                    Data_Plot.after <-
#                                      resMatch.after$MatchTable[!is.na(resMatch.after$MatchTable$rt.2),
#                                                                c(
#                                                                  "mz.1",
#                                                                  "rt.1",
#                                                                  "maxo.1",
#                                                                  "mz.2",
#                                                                  "rt.2",
#                                                                  "rt.2",
#                                                                  "maxo.2",
#                                                                  "sample.2"
#                                                                )]
                                   
#                                    RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity <-
#                                      Data_Plot.after
                                   
#                                    median_line.after <-
#                                      seq(min(
#                                        range(Data_Plot.after$rt.2)[1],
#                                        range(Data_Plot.after$rt.1)[1]
#                                      ),
#                                      max(
#                                        range(Data_Plot.after$rt.2)[2],
#                                        range(Data_Plot.after$rt.1)[2]
#                                      ),
#                                      by = 50)
                                   
#                                    median_line_data.after <-
#                                      data.frame(x =  median_line.after,
#                                                 y  =  median_line.after)
                                   
                                   
#                                    #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot after Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                    Plot.after <-
#                                      ggplot(Data_Plot.after, aes(x = rt.2, y = rt.1)) +
#                                      geom_point(size = 0.5) +
                                     
#                                      coord_cartesian(xlim = c(
#                                        min(
#                                          range(Data_Plot.after$rt.2)[1],
#                                          range(Data_Plot.after$rt.1)[1]
#                                        ),
#                                        max(
#                                          range(Data_Plot.after$rt.2)[2],
#                                          range(Data_Plot.after$rt.1)[2]
#                                        )
#                                      ),
#                                      ylim = c(
#                                        min(
#                                          range(Data_Plot.after$rt.2)[1],
#                                          range(Data_Plot.after$rt.1)[1]
#                                        ),
#                                        max(
#                                          range(Data_Plot.after$rt.2)[2],
#                                          range(Data_Plot.after$rt.1)[2]
#                                        )
#                                      )) +
                                     
                                     
                                     
#                                      scale_x_continuous(n.breaks = 14) +
#                                      scale_y_continuous(n.breaks = 14) +
                                     
#                                      # xlab("CE-time (sample to align)")+
#                                      # ylab("CE-time (reference sample)")+
                                     
#                                      # geom_line(data = predict_data_model.np, aes(x = rt2, y = rt1, color = "Model"), lwd = 1, size = 1.5) +
#                                      # #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
#                                      # # geom_abline(yintercept = 0, lwd = 1, color = "green")+
                                     
#                                      geom_line(
#                                        data = median_line_data.after,
#                                        aes(
#                                          x = x,
#                                          y = x,
#                                          color = "Median"
#                                        ),
#                                        lwd = 1,
#                                        size = 1.5
#                                      ) +
                                     
#                                      labs(
#                                        x = paste("CE-time (", Data_Plot.after$sample.2, ")"),
#                                        y = "CE-time (Reference map)",
#                                        color = "Legend"
#                                      ) +
#                                      ggtitle("Correction with Kernel Density") +
                                     
#                                      scale_color_manual(values = c("Median" = "green")) +
                                     
                                     
#                                      theme_ben() +
#                                      theme(
#                                        plot.title = element_text(
#                                          size = rel(1),
#                                          face = "bold",
#                                          color = "#760001",
#                                          margin = margin(0, 0, 5, 0),
#                                          hjust = 0.5
#                                        ),
#                                        plot.subtitle = element_text(hjust = 0.5),
#                                        plot.background = element_rect(fill = "aliceblue"),
#                                        legend.title = element_text(
#                                          size = rel(0.95),
#                                          face = "bold.italic",
#                                          hjust = 0.5
#                                        ),
#                                        legend.text = element_text(size = rel(0.85), face = "bold.italic")
#                                      )
                                   
#                                    Plot.after
#                                  }
                                 
#                                })
                             
#                              #### info-bulle
#                              output$PlotCorrectionKernelDensity_After_hover_info_newSample <-
#                                renderUI({
#                                  hover <-
#                                    req(input$PlotCorrectionKernelDensity_After_hover_newSample)
                                 
#                                  if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity)) {
#                                    point <-
#                                      nearPoints(
#                                        req(
#                                          RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity
#                                        ),
#                                        hover,
#                                        threshold = 5,
#                                        maxpoints = 1,
#                                        addDist = TRUE
#                                      )
#                                    if (nrow(point) == 0)
#                                      return(NULL)
                                   
#                                    # calculate point position INSIDE the image as percent of total dimensions
#                                    # from left (horizontal) and from top (vertical)
#                                    left_pct <-
#                                      (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#                                    top_pct <-
#                                      (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                                   
#                                    # calculate distance from left and bottom side of the picture in pixels
#                                    left_px <-
#                                      hover$range$left + left_pct * (hover$range$right - hover$range$left)
#                                    top_px <-
#                                      hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                                   
#                                    # create style property fot tooltip
#                                    # background color is set so tooltip is a bit transparent
#                                    # z-index is set so we are sure are tooltip will be on top
#                                    style <-
#                                      paste0(
#                                        "position:absolute; z-index:100; background-color: #760001; color: white;",
#                                        "left:",
#                                        left_px + 2,
#                                        "px; top:",
#                                        top_px + 2,
#                                        "px;"
#                                      )
                                   
#                                    # actual tooltip created as wellPanel
#                                    div(class = "well well-sm",
#                                        style = style,
#                                        p(HTML(
#                                          paste0(
#                                            "<span class='bullText'> M+H (ref): </span>",
#                                            round(point$mz.1, 4),
#                                            "<br/>",
#                                            "<span class='bullText'> CE-time (ref): </span>",
#                                            round(point$rt.1, 2),
#                                            "<br/>",
#                                            "<span class='bullText'> Intensity (ref): </span>",
#                                            round(point$maxo.1, 0),
#                                            "<br/>",
#                                            "<br>",
#                                            "<span class='bullText'> M+H (sample): </span>",
#                                            round(point$mz.2, 4),
#                                            "<br/>",
#                                            "<span class='bullText'> CE-time (sample): </span>",
#                                            round(point$rt.2, 2),
#                                            "<br/>",
#                                            "<span class='bullText'> Intensity (sample): </span>",
#                                            round(point$maxo.2, 0),
#                                            "<br/>"
#                                          )
#                                        )))
#                                  }
                                 
#                                })
                             
#                              #~~~~~~~~~ Plot mz (or M+H)~rt reference and mz(M+H)~rt sample (CE-time correction with xcms)~~~~~~~~~~~~~#
#                              #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                             
#                              output$CorrectimeKernelDensityViewer_2_newSample <-
#                                renderPlot({
#                                  if (!is.null(input$SelectSample_KernelDensity_newSample) &
#                                      !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
#                                      !is.null(RvarsPeakDetectionNewSample$map_ref) &
#                                      !is.null(
#                                        RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
#                                      )) {
#                                    ref <- RvarsPeakDetectionNewSample$map_ref
                                   
#                                    ref <-
#                                      RvarsPeakDetectionNewSample$map_ref[2:4]
                                   
#                                    ref$sample <- "Reference map"
#                                    colnames(ref) <-
#                                      c('mz', 'rt', 'maxo', 'sample')
                                   
#                                    ref$maxo <- 2 ^ (ref$maxo)
                                   
#                                    reqColstoPlot <-
#                                      c('M+H', 'CE-time', 'intensity', 'sample')
#                                    reqColsUsed <-
#                                      c('mz', 'rt', 'maxo', 'sample')
                                   
                                   
#                                    ##~~~~~~~~~~~~~~~~~~~~ After correction xcms ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                    table.after <-
#                                      RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]
#                                    table.after <-
#                                      table.after[, c("mz", "rt", "maxo", "sample")]
                                   
#                                    Data_after <- rbind(table.after,
#                                                        ref)
#                                    rownames(Data_after) <-
#                                      1:nrow(Data_after)
#                                    colnames(Data_after)[which(colnames(Data_after) %in% reqColsUsed)] <-
#                                      reqColstoPlot
#                                    Data_after$intensity <-
#                                      log2(Data_after$intensity)
                                   
                                   
#                                    Data_after$sample <-
#                                      factor(Data_after$sample,
#                                             levels = c(
#                                               unique(Data_after$sample)[unique(Data_after$sample) !=
#                                                                           "Reference map"],
#                                               "Reference map"
#                                             ))
                                   
#                                    Plot.After <- Data_after %>%
#                                      ggplot() +
#                                      aes(x = `CE-time`,
#                                          y = `M+H`,
#                                          colour = intensity) +
#                                      #geom_point(shape = "circle", size = input$sizePoints) +
#                                      geom_point(size = 0.5) +
#                                      scale_color_viridis_c(option = "inferno", direction = -1) +
#                                      theme_gray() +
#                                      #facet_grid(vars(sample), vars())  +
#                                      facet_wrap( ~ sample, dir = "v") +
#                                      ylab("Mass (M+H) (Da)") +
#                                      #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
#                                      xlab(paste("CE-time")) +
                                     
#                                      ggtitle("Before CE-time correction") +
                                     
#                                      scale_x_continuous(n.breaks = 14) +
#                                      scale_y_continuous(n.breaks = 5) +
                                     
#                                      theme_ben() +
#                                      labs(colour = "log2 Intensity") +
#                                      theme(
#                                        plot.title = element_text(
#                                          size = rel(1),
#                                          face = "bold",
#                                          color = "#760001",
#                                          margin = margin(0, 0, 5, 0),
#                                          hjust = 0.5
#                                        ),
#                                        plot.subtitle = element_text(hjust = 0.5),
#                                        panel.border = element_rect(
#                                          fill = "transparent",
#                                          # Needed to add the border
#                                          color = "blue",
#                                          linewidth = 0.5,
#                                          linetype = "dashed"
#                                        ),
                                       
#                                        # Les étiquettes dans le cas d'un facetting
#                                        strip.background = element_rect(
#                                          fill = "grey",
#                                          color = "grey"
#                                        ),
#                                        strip.text = element_text(
#                                          size = rel(1),
#                                          face = "bold.italic",
#                                          color = "black",
#                                          margin = margin(5, 0, 5, 0)
#                                        ),
#                                        plot.background = element_rect(fill = "aliceblue")
#                                      )
                                   
#                                    ##~~~~~~~~~~~~~~~~~~~~ After correction With Kernel Density ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                                    table.After_KernelDensity <-
#                                      RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]
#                                    table.After_KernelDensity <-
#                                      table.After_KernelDensity[, c("mz", "rt", "maxo", "sample")]
                                   
#                                    Data_After_KernelDensity <-
#                                      rbind(table.After_KernelDensity,
#                                            ref)
                                   
#                                    rownames(Data_After_KernelDensity) <-
#                                      1:nrow(Data_After_KernelDensity)
                                   
                                   
#                                    colnames(Data_After_KernelDensity)[which(colnames(Data_After_KernelDensity) %in% reqColsUsed)] <-
#                                      reqColstoPlot
#                                    Data_After_KernelDensity$intensity <-
#                                      log2(Data_After_KernelDensity$intensity)
                                   
                                   
#                                    Data_After_KernelDensity$sample <-
#                                      factor(
#                                        Data_After_KernelDensity$sample,
#                                        levels = c(
#                                          unique(Data_After_KernelDensity$sample)[unique(Data_After_KernelDensity$sample) !=
#                                                                                    "Reference map"],
#                                          "Reference map"
#                                        )
#                                      )
                                   
                                   
                                   
#                                    Plot.After_KernelDensity <-
#                                      Data_After_KernelDensity %>%
#                                      ggplot() +
#                                      aes(x = `CE-time`,
#                                          y = `M+H`,
#                                          colour = intensity) +
#                                      #geom_point(shape = "circle", size = input$sizePoints) +
#                                      geom_point(size = 0.5) +
#                                      scale_color_viridis_c(option = "inferno", direction = -1) +
#                                      theme_gray() +
#                                      #facet_grid(vars(sample), vars())  +
#                                      facet_wrap( ~ sample, dir = "v") +
#                                      #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
#                                      ylab("Mass (M+H) (Da)") +
#                                      #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
#                                      xlab(paste("CE-time")) +
                                     
#                                      ggtitle("Correction with Kernel density") +
                                     
#                                      scale_x_continuous(n.breaks = 14) +
#                                      scale_y_continuous(n.breaks = 5) +
                                     
#                                      theme_ben() +
#                                      labs(colour = "log2 Intensity") +
#                                      theme(
#                                        plot.title = element_text(
#                                          size = rel(1),
#                                          face = "bold",
#                                          color = "#760001",
#                                          margin = margin(0, 0, 5, 0),
#                                          hjust = 0.5
#                                        ),
#                                        plot.subtitle = element_text(hjust = 0.5),
#                                        panel.border = element_rect(
#                                          fill = "transparent",
#                                          # Needed to add the border
#                                          color = "blue",
#                                          linewidth = 0.5,
#                                          linetype = "dashed"
#                                        ),
                                       
#                                        # Les étiquettes dans le cas d'un facetting
#                                        strip.background = element_rect(
#                                          fill = "grey",
#                                          color = "grey"
#                                        ),
#                                        strip.text = element_text(
#                                          size = rel(1),
#                                          face = "bold.italic",
#                                          color = "black",
#                                          margin = margin(5, 0, 5, 0)
#                                        ),
#                                        plot.background = element_rect(fill = "aliceblue")
#                                      )
                                   
                                   
                                   
                                   
                                   
#                                    grid.arrange(Plot.After,
#                                                 Plot.After_KernelDensity,
#                                                 nrow = 2)
                                   
#                                  }
                                 
#                                })
                             
                             
                             
#                            }
                           
                           
#                          })
                         
#                        }
#                      }
                     
#                    }
#                  }
                 
#                }
               
               
               
#              })

# ##
# observe({
#   if (is.null(RvarsPeakDetectionNewSample$modelKernelDensity)) {
#     output$PlotCorrectionKernelDensity_Before_newSample <-
#       renderPlot({
        
#       })
#     output$PlotCorrectionKernelDensity_After_newSample <-
#       renderPlot({
        
#       })
#     output$CorrectimeKernelDensityViewer_2_newSample <- renderPlot({
      
#     })
#   }
  
#   if (is.null(input$SelectSample_KernelDensity_newSample) ||
#       is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) ||
#       is.null(RvarsPeakDetectionNewSample$map_ref)) {
#     output$DensityFilterPlot_newSample <- renderPlot({
      
#     })
#   }
# })

# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~~~~~~ Grouping massifs into features  ~~~~~~~~~~~~~~~~~~~~~###
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$GroupingButtonIDNewSample
#              }
#              ,
#              handlerExpr = {
#                if (!is.null(RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection)) {
#                  ## Load some functions:
#                  source("lib/NewReferenceMap/R_files/GenerateMapRef.lib.R",
#                         local = TRUE)
                 
#                  withProgress(message = 'Grouping massif to features...', value = 0, {
#                    ####~~~~~~~~~~~~~~~~~~~~~~ Grouping massif in samples  ~~~~~~~~~~~~~~~~~~~~#
#                    ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   
#                    incProgress(1 / 4, detail = "starting")
                   
#                    ## Change names of columns
                   
#                    Massif_List_ToGroup <-
#                      RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
                   
#                    for (i in 1:length(Massif_List_ToGroup)) {
#                      colSelect <-
#                        c(
#                          "M+H",
#                          "M+H.min",
#                          "M+H.max",
#                          "rt",
#                          "rtmin",
#                          "rtmax",
#                          "Area",
#                          "Height",
#                          "SN",
#                          "sample",
#                          "iso.mass",
#                          "iso.mass.link",
#                          "mz_PeaksIsotopics_Group",
#                          "rt_PeaksIsotopics_Group",
#                          "Height_PeaksIsotopics_Group",
#                          "Adduct"
#                        )
                     
#                      colnames(Massif_List_ToGroup[[i]])[c(1:10)] <-
#                        colSelect[c(1:10)]
#                    }
                   
                   
                   
                   
#                    workers <- ceiling((detectCores()) - 1)
#                    param <-
#                      SnowParam(workers = workers, type = "SOCK")
                   
                   
#                    incProgress(1 / 4, detail = "first grouping")
#                    res1 <- bplapply(
#                      Massif_List_ToGroup,
#                      Grouping.Massif_NewRefMap,
#                      mz.tolerance = 0.15,
#                      rt.tolerance = 30,
#                      BPPARAM = param
#                    )
                   
#                    incProgress(1 / 4, detail = "second grouping")
#                    res2 <- bplapply(
#                      res1,
#                      Grouping.Massif_NewRefMap_Second,
#                      mz.tolerance = 0.09,
#                      rt.tolerance = 180,
#                      BPPARAM = param
#                    )
                   
                   
#                    ## Change colnames
                   
#                    for (i in 1:length(res2)) {
#                      colSelect <-
#                        c(
#                          "M+H",
#                          "M+H.min",
#                          "M+H.max",
#                          "rt",
#                          "rtmin",
#                          "rtmax",
#                          "Area",
#                          "Height",
#                          "SN",
#                          "sample",
#                          "iso.mass",
#                          "iso.mass.link",
#                          "mz_PeaksIsotopics_Group",
#                          "rt_PeaksIsotopics_Group",
#                          "Height_PeaksIsotopics_Group",
#                          "Adduct"
#                        )
                     
#                      reqColsNames <-
#                        c(
#                          'M+H',
#                          'M+H.min',
#                          'M+H.max',
#                          'CE-time',
#                          'CE-time.min',
#                          'CE-time.max',
#                          'integrated-intensity',
#                          'intensity',
#                          'sn',
#                          'sample'
#                        )
                     
#                      colnames(res2[[i]])[c(1:10)] <- reqColsNames
                     
#                      res2[[i]] <- res2[[i]][, -ncol(res2[[i]])]
#                    }
                   
                   
#                    RvarsPeakDetectionNewSample$FeaturesList_newSample <-
#                      res2
#                    incProgress(1 / 4, detail = "finish")
                   
                   
#                  })
                 
                 
#                  #"~~~~~~~ Enable Generate reference map button ~~~~~~~~#
                 
#                  enable("CorrectionKernelDensityNexPage_newSample")
                 
#                  updateRadioButtons(session = session,
#                                     inputId = "IdAnalysisStep",
#                                     selected = "4")
                 
                 
#                  sendSweetAlert(
#                    session = session,
#                    title = "Preprocess complete !",
#                    text = HTML(paste(
#                      "Grouping massif into feature well done !<br>"
#                    )),
#                    type = "success",
#                    closeOnClickOutside = FALSE,
#                    html = TRUE
#                  )
                 
#                }
               
               
#              })



# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
# ###~~~~~~~~~~~~~~~ Get features list and plot of table features ~~~~~~~~~~~~~~###
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~##
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


# ###~~~~ Get features list~~~~~~~~#
# ms_features_newSample <- reactive({
#   if ((length(RvarsPeakDetectionNewSample$FeaturesList_newSample) > 0)) {
#     ms_featuresTable <-
#       do.call(rbind,
#               RvarsPeakDetectionNewSample$FeaturesList_newSample)
    
#     rownames(ms_featuresTable) <- 1:nrow(ms_featuresTable)
    
#     ms_featuresTable$intensity <- log2(ms_featuresTable$intensity)
#     ms_featuresTable
#   }
# })



# ##~~~~ Update select input (select samples to viewer or to use)~~~~~~#
# observe({
#   if (!is.null(ms_features_newSample())) {
#     RvarsPeakDetectionNewSample$sample_name_newSample <-
#       unique(ms_features_newSample()$sample)
    
#     updatePickerInput(
#       session = session,
#       inputId = "levelSample",
#       choices = RvarsPeakDetectionNewSample$sample_name_newSample,
#       selected = RvarsPeakDetectionNewSample$sample_name_newSample[1]
#     )
    
#     updatePickerInput(
#       session = session,
#       inputId = "IncludeSample",
#       choices = RvarsPeakDetectionNewSample$sample_name_newSample,
#       selected = RvarsPeakDetectionNewSample$sample_name_newSample
#     )
    
    
#   }
  
# })

# ##~~~~~~~~~~~~~~~~~ Get data features to plot ~~~~~~~~~~~~~~#
# ms_features_newSample_toPlot <- reactive({
#   if (!is.null(ms_features_newSample()) &
#       !is.null(input$levelSample)) {
#     values_plot <-
#       req(ms_features_newSample()[ms_features_newSample()$sample %in% input$levelSample, ])
    
#     j <- 1
#     for (names in unique(values_plot$sample)) {
#       values_plot[values_plot$sample == names, "sample"] <- j
#       j <- j + 1
#     }
    
#     values_plot
    
#   }
  
# })

# ###~~~~~~ CE-time Conversion ~~~~~~~~#
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$levelSample
#              },
#              handlerExpr = {
#                RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
#                  isolate(req(ms_features_newSample_toPlot()))
#                #Because les data viennent initialement en second
#                RvarsPeakDetectionNewSample$Second <- TRUE
#                if (input$UnitTime == "Minute") {
#                  print(
#                    paste(
#                      "Convert to min",
#                      input$UnitTime == "Minute" &
#                        RvarsPeakDetectionNewSample$Second == TRUE
#                    )
#                  )
#                  if (input$UnitTime == "Minute" &
#                      RvarsPeakDetectionNewSample$Second == TRUE) {
#                    if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
#                      print("Yes!")
#                      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
#                        req(
#                          RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
#                        ) / 60
#                      RvarsPeakDetectionNewSample$Second <- FALSE
#                    }
#                  }
#                }
               
               
#              })

# ## When uploaded features list
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$features_list
#              },
#              handlerExpr = {
#                ## Because data is initially in second
               
#                updateRadioGroupButtons(session = session,
#                                        inputId = "UnitTime",
#                                        selected = "Second")
#                RvarsPeakDetectionNewSample$Second == TRUE
#                ## reset coord_cartesian
#                rangesZoomAnalyisPlotSamplesSelected$x <- NULL
#                rangesZoomAnalyisPlotSamplesSelected$y <- NULL
               
               
#              })


# ##~~~~~~ CE-time conversion second or minute ~~~~~~~#
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$UnitTime
#              },
#              handlerExpr = {
#                RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
#                  req(ms_features_newSample_toPlot())
#                print(
#                  paste(
#                    "Convert to min",
#                    input$UnitTime == "Minute" &
#                      RvarsPeakDetectionNewSample$Second == TRUE
#                  )
#                )
#                if (input$UnitTime == "Minute" &
#                    RvarsPeakDetectionNewSample$Second == TRUE) {
#                  if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
#                    RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
#                      req(
#                        RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
#                      ) / 60
#                    RvarsPeakDetectionNewSample$Second <- FALSE
#                  }
#                }
               
#                print(
#                  paste(
#                    "Covert to Second",
#                    input$UnitTime == "Second" &
#                      RvarsPeakDetectionNewSample$Second == FALSE
#                  )
#                )
#                if (input$UnitTime == "Second" &
#                    RvarsPeakDetectionNewSample$Second == FALSE) {
#                  if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
#                    RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
#                      req(
#                        RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
#                      ) * 60
#                    RvarsPeakDetectionNewSample$Second <- TRUE
#                  }
#                }
               
#                if (input$UnitTime == "Second" &
#                    RvarsPeakDetectionNewSample$Second == TRUE) {
#                  RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
#                    req(ms_features_newSample_toPlot())
#                }
               
               
#              })


# ##~~~~~~ Number of features ~~~~~~#
# number_of_features <- reactive({
#   if (length(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) >
#       0 &
#       !is.null(ms_features_newSample()) &
#       !is.null(input$levelSample)) {
#     table(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
    
#   }
# })

# ##~~~~~~~~~~~~ Legend for plot ~~~~~~~~~#
# legend_sample <- reactive({
#   if (length(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) >
#       0 &
#       !is.null(ms_features_newSample()) &
#       !is.null(input$levelSample)) {
#     legend_values <- data.frame(
#       xd = 1:length(input$levelSample),
#       yd = 1:length(input$levelSample),
#       Samples = paste(
#         "\n",
#         1:length(input$levelSample),
#         ": ",
#         input$levelSample,
#         "\n",
#         sep = ""
#       )
#     )
#     legend_values
#   }
  
# })


# ##~~~~~~~Zoom: features list viewer ~~~~~~~~#
# rangesZoomAnalyisPlotSamplesSelected <-
#   reactiveValues(x = NULL, y = NULL)

# # When a double-click happens, check if there's a brush on the plot.
# # If so, zoom to the brush bounds; if not, reset the zoom.
# observeEvent({
#   input$plotAnalysisNewSample_dblclick
# }, {
#   brush <- input$plotAnalysisNewSample_brush
#   if (!is.null(brush)) {
#     rangesZoomAnalyisPlotSamplesSelected$x <- c(brush$xmin, brush$xmax)
#     rangesZoomAnalyisPlotSamplesSelected$y <-
#       c(brush$ymin, brush$ymax)
    
#   } else {
#     ## reset coord_cartesian
#     rangesZoomAnalyisPlotSamplesSelected$x <- NULL
#     rangesZoomAnalyisPlotSamplesSelected$y <- NULL
#   }
# })


# #~~~~~~~~~ Features list plot ~~~~~~~#
# output$AnalyisPlotSamplesSelected <- renderPlot({
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) > 1 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     if (TRUE) {
#       myPlot <-
#         req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) %>%
        
#         ggplot() +
#         aes(x = `CE-time`,
#             y = `M+H`,
#             colour = intensity) +
#         #geom_point(shape = "circle", size = input$sizePoints) +
#         geom_point(size = req(input$sizePoints)) +
#         scale_color_viridis_c(option = "inferno", direction = -1) +
#         theme_gray() +
#         facet_grid(vars(sample), vars())  +
#         # facet_wrap(~req(sample) , dir="v", ncol = 1)  +
#         coord_cartesian(xlim = rangesZoomAnalyisPlotSamplesSelected$x,
#                         ylim = rangesZoomAnalyisPlotSamplesSelected$y,
#                         expand = TRUE) +
#         ylab("Mass (M+H) (Da)") +
#         xlab(paste("CE-time (", input$UnitTime, ")")) +
        
#         ggtitle(paste("Features list")) +
        
#         scale_x_continuous(n.breaks = 14) +
#         #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
        
        
#         #facet_grid(vars(sample), vars())+
#         #option_graphe.2 +
#         theme_ben() +
#         labs(colour = "log2 Intensity") +
#         theme(
#           plot.title = element_text(
#             size = rel(1),
#             face = "bold",
#             color = "#760001",
#             margin = margin(0, 0, 5, 0),
#             hjust = 0.5
#           ),
#           plot.subtitle = element_text(hjust = 0.5),
#           panel.border = element_rect(
#             fill = "transparent",
#             # Needed to add the border
#             color = "blue",
#             linewidth = 0.5,
#             linetype = "dashed"
#           )
#         )
      
#     }
    
    
    
    
    
#   }
  
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) == 1 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     myPlot <-
#       req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) %>%
      
#       ggplot() +
#       aes(x = `CE-time`, y = `M+H`, colour = intensity) +
#       #geom_point(shape = "circle", size = input$sizePoints) +
#       geom_point(size = input$sizePoints) +
#       scale_color_viridis_c(option = "inferno", direction = -1) +
#       ylab("Mass (M+H) (Da)") +
#       xlab(paste("CE-time (", input$UnitTime, ")")) +
#       coord_cartesian(xlim = rangesZoomAnalyisPlotSamplesSelected$x,
#                       ylim = rangesZoomAnalyisPlotSamplesSelected$y,
#                       expand = TRUE) +
#       ggtitle(paste("Features list")) +
      
#       scale_x_continuous(n.breaks = 14) +
#       #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
      
      
#       #facet_grid(vars(sample), vars())+
#       #option_graphe.3
#       theme_ben() +
#       labs(colour = "log2 Intensity") +
#       theme(
#         plot.title = element_text(
#           size = rel(1),
#           face = "bold",
#           color = "#760001",
#           margin = margin(0, 0, 5, 0),
#           hjust = 0.5
#         ),
#         plot.subtitle = element_text(hjust = 0.5)
#       )
    
#   }
  
#   Values_myPlot <- reactive({
#     myPlot
#   })
  
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) > 0 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     shinyjs::show("PeaksMonoIsoPlotAnalysisNewSample_id")
#     Values_myPlot()
    
#   }
  
# })


# ### Position mouse
# output$PeaksMonoIsoPlotAnalysisNewSample_info <- renderText({
#   paste0(
#     "Mouse position : CE-time = ",
#     round(req(input$plotAnalysisNewSample_click$x), 0),
#     " (",
#     input$UnitTime,
#     "), ",
#     " M+H = ",
#     round(req(input$plotAnalysisNewSample_click$y), 4),
#     " (Da)"
#   )
# })


# ##~~~~~~~~~~ Info bull for plot features list ~~~~~~~~#
# output$plotAnalysisNewSamplet_hover_info <- renderUI({
#   hover <- req(input$plotAnalysisNewSamplet_hover)
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) > 1 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     myPlot_data <-
#       req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)
    
#   }
  
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) == 1 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     myPlot_data <-
#       req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)
#   }
  
#   Values_myPlot_data <- reactive({
#     myPlot_data
#   })
  
  
#   if (length(
#     unique(
#       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#     )
#   ) > 0 &
#   !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
#     point <-
#       nearPoints(
#         req(Values_myPlot_data()),
#         hover,
#         threshold = 5,
#         maxpoints = 1,
#         addDist = TRUE
#       )
#     if (nrow(point) == 0)
#       return(NULL)
    
    
#     # calculate point position INSIDE the image as percent of total dimensions
#     # from left (horizontal) and from top (vertical)
#     left_pct <-
#       (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#     top_pct <-
#       (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
#     # calculate distance from left and bottom side of the picture in pixels
#     left_px <-
#       hover$range$left + left_pct * (hover$range$right - hover$range$left)
#     top_px <-
#       hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
    
#     # create style property fot tooltip
#     # background color is set so tooltip is a bit transparent
#     # z-index is set so we are sure are tooltip will be on top
#     style <-
#       paste0(
#         "position:absolute; z-index:100; background-color: #f7f0f0; ",
#         "left:",
#         left_px + 2,
#         "px; top:",
#         top_px + 2,
#         "px;"
#       )
    
#     # actual tooltip created as wellPanel
#     div(class = "well well-sm",
#         style = style,
#         p(HTML(
#           paste0(
#             "<span class='bullText'> CE-time: </span>",
#             round(point$`CE-time`, 2),
#             "<br/>",
#             "<span class='bullText'> M+H: </span>",
#             round(point$`M+H`, 4),
#             "<br/>",
#             "<span class='bullText'> log2 Intensity: </span>",
#             round(point$intensity, 2),
#             "<br/>",
#             "<span class='bullText'> Intensity: </span>",
#             round(2 ^ (point$intensity), 0),
#             "<br/>"
#           )
#         )))
    
#   }
  
  
# })

# ##~~~~~~~~~~~ Render plot number of features ~~~~~~~~~~#
# output$NumberOfFeatures <- renderPlot({
#   if (length(number_of_features()) > 0 &
#       length(
#         unique(
#           RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
#         )
#       ) > 0 &
#       !is.null(ms_features_newSample()) &
#       !is.null(input$levelSample)) {
#     NbPeak_for_each_sample_adj <- data.frame(number_of_features())
#     colnames(NbPeak_for_each_sample_adj)[1] <- "Sample"
#     ggplot(NbPeak_for_each_sample_adj) +
#       aes(x = Sample,
#           #colour = sample,
#           weight = Freq) +
#       geom_bar(width = 0.4, fill = "#4682B4") +
#       geom_text(
#         aes(label = paste0(round(..count.., 2))),
#         stat = "count",
#         vjust = 0,
#         hjust = 0.5,
#         size = 5,
#         fontface = 4
#       ) +
#       scale_color_hue(direction = 1) +
#       #coord_flip() +
#       ylab("Number of Features") +
#       xlab("") +
#       coord_cartesian(ylim = c(0, max(NbPeak_for_each_sample_adj$Freq) +
#                                  1000)) +
#       theme_ben() +
#       #theme(axis.text.x = element_text(angle = 90, size = rel(1), face = "bold"))
#       theme(axis.text.x = element_text(size = rel(1.2), face = "bold"))
    
#   }
  
# })

# output$sampleOutput <- renderText({
#   legend_sample()$Samples
# })


# ##~~~~~~~~~~~~ Get data to save ~~~~~~~~~~#
# ms_features_newSample_toSave <- reactive({
#   if (!is.null(ms_features_newSample()) &
#       !is.null(input$IncludeSample)) {
#     values <-
#       ms_features_newSample()[ms_features_newSample()$sample %in% input$IncludeSample, ]
#     values$intensity <- 2 ^ (values$intensity)
#     split(values, f = values$sample)
    
#   }
  
# })

# ##~~~~~~~~~~~~ Get data to use ~~~~~~~~~~#

# ms_features_list_newSample_toUse <- reactive({
#   if (!is.null(ms_features_newSample()) &
#       !is.null(input$IncludeSample)) {
#     values <-
#       ms_features_newSample()[ms_features_newSample()$sample %in% input$IncludeSample, ]
#     values$intensity <- 2 ^ (values$intensity)
    
#     split(values, f = values$sample)
#   }
# })


# ##~~~~~~~~~~~~ Save features list ~~~~~~~~~~#
# observeEvent(ignoreNULL = TRUE,
#              eventExpr = {
#                input$SaveAnalysis
#              }
#              ,
#              handlerExpr = {
#                shinyFileSave(input,
#                              id = "SaveAnalysis",
#                              roots = volumes,
#                              session = session)
               
               
#                path_Save_Files_origine <-
#                  parseSavePath(volumes, input$SaveAnalysis)$datapath
               
#                if (length(path_Save_Files_origine) > 0) {
#                  path_Save_Files <-
#                    strsplit(path_Save_Files_origine, split = "/")[[1]]
#                  directory_Save_Files <-
#                    paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
#                  if (length(ms_features_newSample_toSave()) > 0 &
#                      !is.null(ms_features_newSample()) &
#                      !is.null(input$IncludeSample)) {
#                    if (length(ms_features_newSample_toSave()) == 1) {
#                      write.table(
#                        ms_features_newSample_toSave()[[1]],
#                        #file = path_Save_Files_origine,
#                        file = paste0(c(
#                          directory_Save_Files,
#                          paste(
#                            names(ms_features_newSample_toSave())[1],
#                            path_Save_Files[length(path_Save_Files)],
#                            collapse = "",
#                            sep = "-"
#                          )
#                        ), collapse = "/"),
#                        sep = ",",
#                        row.names = FALSE
#                      )
#                      print("Save ok")
#                    } else{
#                      withProgress(message = 'Saving files...', value = 0, {
#                        for (i in 1:length(ms_features_newSample_toSave())) {
#                          incProgress(1 / length(ms_features_newSample_toSave()),
#                                      detail = paste(names(
#                                        ms_features_newSample_toSave()
#                                      )[i]))
#                          print(basename(paste0(
#                            c(
#                              directory_Save_Files,
#                              paste(
#                                #as.character(i),
#                                names(ms_features_newSample_toSave())[i],
#                                path_Save_Files[length(path_Save_Files)],
#                                collapse = "",
#                                sep = "-"
#                              )
#                            ), collapse = "/"
#                          )))
#                          write.table(
#                            ms_features_newSample_toSave()[[i]],
#                            file = paste0(c(
#                              directory_Save_Files,
#                              paste(
#                                #as.character(i),
#                                names(ms_features_newSample_toSave())[i],
#                                path_Save_Files[length(path_Save_Files)],
#                                collapse = "",
#                                sep = "-"
#                              )
#                            ), collapse = "/"),
#                            sep = ",",
#                            row.names = FALSE
#                          )
#                          print("Save ok")
#                        }
                       
#                      })
                     
#                    }
                   
                   
#                  }
#                }
               
               
#              })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ Configure some buttons ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ReturnToPeakViewer_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturnToPeakViewer_newSample
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "1")
               
               shinyjs::show(id = "buttonResetViewAnalysis")
               shinyjs::show(id = "RestartProjects")
               shinyjs::show(id = "ViewAnalysis")
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button GoToPeakView_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GoToPeakView_newSample
             },
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "3")
               
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ViewAnalysis ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ViewAnalysis
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "2")
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ViewAnalysis_duplicate ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ViewAnalysis_duplicate
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "2")
               
             })
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button ReturToFilterSample_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturToFilterSample_newSample
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "2")
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Buton CorrectionKernelDensityNexPage_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$CorrectionKernelDensityNexPage_newSample
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "4")
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button returnAnalysis ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$returnAnalysis
             }
             , {
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "3")
               
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button Finish_fitModel_newSample ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$Finish_fitModel_newSample
             },
             handlerExpr = {
               ask_confirmation(
                 inputId = "Comfirm_FinishedCEtimeCorrection",
                 title = NULL,
                 text = tags$b(
                   #icon("info"),
                   paste0(
                     "Are you sure you’re finished correcting CE-time ?"
                   ),
                   style = "color: #FA5858;"
                 ),
                 btn_labels = c("Cancel", "OK"),
                 btn_colors = c("#00BFFF", "#FE2E2E"),
                 html = TRUE
               )
               
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button Comfirm_FinishedCEtimeCorrection ~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$Comfirm_FinishedCEtimeCorrection
             },
             handlerExpr = {
               if (input$Comfirm_FinishedCEtimeCorrection == TRUE) {
                 enable("GroupingButtonIDNewSample")

                 ## Export kernel density parameters to Excel
                 params_log <- isolate(RvarsPeakDetectionNewSample$kernelDensity_params_log)
                 if (!is.null(params_log) && nrow(params_log) > 0) {
                   proj_dir <- tryCatch(
                     file.path(directoryInput$directory,
                               isolate(RvarsPeakDetectionNewSample$Project_Name)),
                     error = function(e) directoryInput$directory
                   )
                   if (!dir.exists(proj_dir)) proj_dir <- directoryInput$directory
                   xlsx_path <- file.path(proj_dir,
                                          "KernelDensity_Correction_Parameters.xlsx")
                   tryCatch({
                     openxlsx::write.xlsx(params_log, file = xlsx_path, rowNames = FALSE)
                     showNotification(
                       paste("Parameters saved:", xlsx_path),
                       type = "message",
                       duration = 6
                     )
                   }, error = function(e) {
                     showNotification(
                       paste("Failed to save parameters:", e$message),
                       type = "error",
                       duration = 6
                     )
                   })
                 }
               }
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button GoMatch ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GoMatch
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Match reference map")
               
             })

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ choix du map de référance ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$chosseRef
             },
             handlerExpr = {
               print(input$chosseRef)
               if (input$chosseRef == "") {
                 print("No reference map")
                 
                 updateNavbarPage(session = session,
                                  inputId = "analysisNavbar",
                                  selected = "Peak detection")
                 
                 ask_confirmation(
                   inputId = "no_ref_map",
                   type = "warning",
                   title = NULL,
                   text = tags$b(
                     icon("frown"),
                     "No reference map available.",
                     br(),
                     "Please create a new reference map!",
                     
                     style = "color: #FA5858;"
                   ),
                   btn_labels = c("Yep"),
                   btn_colors = c("#FE642E"),
                   html = TRUE
                 )
                 
                 disable("runPeakPicking")
                 shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
               } else if (file.exists(file.path(ref_map_directory, input$chosseRef, "run_ref.mzML")) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "map_ref.csv")) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "paramMsdial.txt")) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "defaultParam.txt")) &
                          file.exists(file.path(
                            ref_map_directory,
                            input$chosseRef,
                            "peaksList_run_ref.csv"
                          )) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "rt_ref.csv")) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "normalizers_ref.csv")) &
                          file.exists(file.path(ref_map_directory, input$chosseRef, "Parameters_Used.txt"))) {
                 print("Tout est OK !")
                 
                 source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')
                 
                 RvarsPeakDetectionNewSample$run_ref_path <-
                   file.path(ref_map_directory, input$chosseRef, "run_ref.mzML")
                 RvarsPeakDetectionNewSample$map_ref_path <-
                   file.path(ref_map_directory, input$chosseRef, "map_ref.csv")
                 RvarsPeakDetectionNewSample$paramMsdial_ref_path <-
                   file.path(ref_map_directory, input$chosseRef, "paramMsdial.txt")
                 RvarsPeakDetectionNewSample$defaultParam_ref_path <-
                   file.path(ref_map_directory, input$chosseRef, "defaultParam.txt")
                 RvarsPeakDetectionNewSample$peaksList_run_ref_path <-
                   file.path(ref_map_directory,
                             input$chosseRef,
                             "peaksList_run_ref.csv")
                 RvarsPeakDetectionNewSample$rt_min_max_run_ref_path <-
                   file.path(ref_map_directory, input$chosseRef, "rt_ref.csv")
                 RvarsPeakDetectionNewSample$normalizers_ref_path <-
                   file.path(ref_map_directory,
                             input$chosseRef,
                             "normalizers_ref.csv")
                 
                 RvarsPeakDetectionNewSample$export_param_path <-
                   file.path(ref_map_directory,
                             input$chosseRef,
                             "Parameters_Used.txt")
                 RvarsPeakDetectionNewSample$output_export_param_path <-
                   file.path(ref_map_directory, input$chosseRef, "outputParam.txt")
                 
                 RvarsPeakDetectionNewSample$defaultParam <-
                   readDefaultParam(req(RvarsPeakDetectionNewSample$defaultParam_ref_path))
                 
                 RvarsPeakDetectionNewSample$map_ref <-
                   read.csv(RvarsPeakDetectionNewSample$map_ref_path, sep = ",")
                 
                 colnames(RvarsPeakDetectionNewSample$map_ref)[2:3] <-
                   c("M+H", "CE-time")
                 
                 RvarsPeakDetectionNewSample$normalizers_ref <-
                   read.csv(RvarsPeakDetectionNewSample$normalizers_ref_path, sep = ",")
                 
                 
                 enable("runPeakPicking")
                 shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
               } else {
                 print("Pas bon !")
                 
                 message("Incomplete reference map...!")
                 disable("runPeakPicking")
                 shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
                 
                 RvarsPeakDetectionNewSample$run_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$map_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$paramMsdial_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$defaultParam_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$peaksList_run_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$rt_min_max_run_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$normalizers_ref_path <-
                   character()
                 RvarsPeakDetectionNewSample$export_param_path <-
                   NULL
                 RvarsPeakDetectionNewSample$output_export_param_path <-
                   NULL
                 
                 
                 RvarsPeakDetectionNewSample$defaultParam = NULL
                 
                 RvarsPeakDetectionNewSample$map_ref <-
                   data.frame(
                     ID = character(),
                     mz = numeric(0),
                     rt = numeric(0),
                     maxo = numeric(0)
                   )
                 RvarsPeakDetectionNewSample$normalizers_ref <-
                   data.frame()
                 
                 
                 
                 
                 ask_confirmation(
                   inputId = "error_ref_map",
                   type = "warning",
                   title = NULL,
                   text = tags$b(
                     icon("frown"),
                     "Incomplete reference map.",
                     br(),
                     "Please recreate the map again !",
                     style = "color: #FA5858;"
                   ),
                   btn_labels = c("Yep"),
                   btn_colors = c("#FE642E"),
                   html = TRUE
                 )
               }
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Input Files ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
directoryInput <- reactiveValues(directory = getwd())

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$directory
             },
             handlerExpr = {
               if (input$directory > 0) {
                 # condition prevents handler execution on initial app launch
                 
                 # launch the directory selection dialog with initial path read from the widget
                 directoryInput$directory = choose.dir(default = readDirectoryInput(session, 'directory'))
                 directoryInput$directory = str_replace_all(directoryInput$directory,
                                                            pattern =  "\\\\",
                                                            replacement  = "/")
                 
                 # update the widget value
                 updateDirectoryInput(session, 'directory', value = directoryInput$directory)
                 
                 
                 
               }
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~~ Default for some inputs ~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observe({
  if (length(input$IdDataType) != 0) {
    if (input$IdDataType == "defaults") {
      shinyjs::reset("dataType")
      updateSelectInput(session = session,
                        inputId = "MS1_type",
                        selected = "Profile")
      updateSelectInput(session = session,
                        inputId = "MS2_type",
                        selected = "Profile")
    }
    
  }
  
  if (length(input$ViewSizePoints) != 0) {
    if (input$ViewSizePoints == "defaults") {
      shinyjs::reset("sizePoints")
    }
    
  }
  
  
})





###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~ Run peak picking MSDIAl and Deconvolution ~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$runPeakPicking
             }
             , {
               ### Disable some buttons when prepossessing start
               shinyjs::disable(selector = '.navbar-nav a[data-value="Match reference map"')
               shinyjs::disable(selector = '.navbar-nav a[data-value="New reference map"')
               shinyjs::disable(selector = '.navbar-nav a[data-value="Database"')
               shinyjs::disable(selector = '.navbar-nav a[data-value="Statistical analysis"')
               shinyjs::disable(selector = '.navbar-nav a[data-value="Help"')
               
               
               
               disable("runPeakPicking")
               disable("processParameters")
               disable("directory")
               disable("match")
               #disable("viewResult")
               disable("features_list")
               disable("normIntensity")
               disable("runNormalizing")
               disable("returnAnalysisViewer")
               disable("finishAnalyze")
               disable("returnMatchRef")
               disable("SaveAnalysisResults")
               
               disable(id = "chosseRef")
               disable(id = "projectName")
               disable(id = "IdDataType")
               disable(id = "dataType")
               disable(id = "MS1_type")
               disable(id = "MS2_type")
               hide(id = "ViewAnalysis")
               hide(id = "RestartProjects")
               
               
               
               # Show progress stuff
               shinyjs::show("progressWrapper")
               shinyjs::show("analysisProgress")
               shinyjs::show("idpanel_analysisProgress")
               #shinyjs::html("analysisProgress","Preprocess running !")
               
               if (is.na(directoryInput$directory) ||
                   (directoryInput$directory == "") ||
                   (directoryInput$directory == getwd()) ||
                   (req(directoryInput$directory) == "Choose working directory") ||
                   is.null(directoryInput$directory)) {
                 message("No file .msdial...!")
                 
                 hide("progressWrapper")
                 hide("analysisProgress")
                 hide("idpanel_analysisProgress")
                 enable("runPeakPicking")
                 enable("updateProject")
                 enable("confirmProject")
                 enable("processParameters")
                 enable("directory")
                 
                 enable(id = "chosseRef")
                 enable(id = "projectName")
                 enable(id = "dataType")
                 enable(id = "IdDataType")
                 enable(id = "MS1_type")
                 enable(id = "MS2_type")
                 
                 shinyjs::html("analysisProgress", html = NULL)
                 
                 sendSweetAlert(
                   session = session,
                   title = "Warning !",
                   text = "There is no input MS file to be imported !",
                   type = "warning"
                 )
                 
                 
               } else {
                 withProgress(message = 'Processing...', value = 0, {
                   source("lib/AnalysisNewSample/R_files/ProcessingAnalysisNewsample.lib.R",
                          local = TRUE)
                   source_python("lib/AnalysisNewSample/Python_files/msconverter_command_line.py")
                   
                   #incProgress(1/10, detail = paste("Grouping isotopic massifs into features...", round(6/8*100,0),"%",collapse=""))
                   incProgress(1 / 8, detail = paste("Start preprocessing...", collapse =
                                                       ""))
                   ########################################################################
                   updateShinyProgressBar(
                     shinyProgressData = list(
                       session = session,
                       progressId = "preprocessProgressBar",
                       progressTotal = 8,
                       textId = "analysis_pre"
                     ),
                     pbValue = 1,
                     headerMsg = "Start preprocessing....",
                     footerMsg = "Start preprocessing data..."
                   )
                   ########################################################################
                   
                   ### Directory Project
                   RvarsPeakDetectionNewSample$Project_Name <-
                     paste(input$projectName,
                           sub(
                             sub(
                               sub(
                                 Sys.time(),
                                 pattern = "CEST",
                                 replacement = "",
                                 fixed = TRUE
                               ),
                               pattern = ":",
                               replacement = "-",
                               fixed = TRUE
                             ),
                             pattern = ":",
                             replacement = "-",
                             fixed = TRUE
                           ),
                           sep = "_")
                   
                   
                   if (dir.exists(
                     file.path(
                       directoryInput$directory,
                       RvarsPeakDetectionNewSample$Project_Name
                     )
                   )) {
                     unlink(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name
                       ),
                       recursive = TRUE
                     )
                     dir.create(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name
                       )
                     )
                   } else{
                     dir.create(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name
                       )
                     )
                   }
                   
                   ## creer un dossier contenant la liste des peaks
                   if (dir.exists(
                     file.path(
                       directoryInput$directory,
                       RvarsPeakDetectionNewSample$Project_Name,
                       "Massif-List"
                     )
                   )) {
                     unlink(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name,
                         "Massif-List"
                       ),
                       recursive = TRUE
                     )
                     dir.create(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name,
                         "Massif-List"
                       )
                     )
                     directoryOutput <-
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name,
                         "Massif-List"
                       )
                   } else{
                     dir.create(
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name,
                         "Massif-List"
                       )
                     )
                     directoryOutput <-
                       file.path(
                         directoryInput$directory,
                         RvarsPeakDetectionNewSample$Project_Name,
                         "Massif-List"
                       )
                   }
                   
                   
                   ### Don't need the mzML files
                   # ## creer un dossier contenant les fichiers mzML
                   # if(dir.exists(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"))) {
                   #   unlink(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"), recursive = TRUE)
                   #   dir.create(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files"))
                   #   RvarsPeakDetectionNewSample$directoryOutput_mzML_files<-file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name,"mzML files")
                   # } else{
                   #   dir.create(file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name, "mzML files"))
                   #   RvarsPeakDetectionNewSample$directoryOutput_mzML_files<-file.path(directoryInput$directory, RvarsPeakDetectionNewSample$Project_Name, "mzML files")
                   # }
                   ## Conversion des raw data en .mzML pour l'alignement des runs
                   # message(" \n --- Convert raw data to .mzML ---\n")
                   #
                   # incProgress(1/10, detail = paste("Converting raw data to .mzML...",collapse=""))
                   # ########################################################################
                   # updateShinyProgressBar(
                   #   shinyProgressData=list(
                   #     session=session,
                   #     progressId="preprocessProgressBar",
                   #     progressTotal=10,
                   #     textId="analysis_pre"
                   #   ),
                   #   pbValue=2,
                   #   headerMsg="Converting raw data...",
                   #   footerMsg="Converting raw data to .mzML..."
                   # )
                   # ########################################################################
                   #
                   #
                   # system.time(convert_to_mzML(directoryInput$directory,RvarsPeakDetectionNewSample$directoryOutput_mzML_files))
                   # system.time(system2("lib/AnalysisNewSample/cmd/convert_raw_data_to_mzML_centroid.bat"))
                   #
                   #
                   #
                   # message("--- End converting raw data to .mzML ---\n")
                   #
                   # incProgress(1/10, detail = paste("End converting raw data to .mzML...",collapse=""))
                   # ########################################################################
                   # updateShinyProgressBar(
                   #   shinyProgressData=list(
                   #     session=session,
                   #     progressId="preprocessProgressBar",
                   #     progressTotal=10,
                   #     textId="analysis_pre"
                   #   ),
                   #   pbValue=3,
                   #   headerMsg="Converting raw data...",
                   #   footerMsg="End coverting..."
                   # )
                   # ########################################################################
                   #
                   
                   source_python('lib/AnalysisNewSample/Python_files/export.parameters.py')
                   
                   exportMsdialParam(
                     export_param = req(RvarsPeakDetectionNewSample$export_param_path),
                     output_export_param =  req(RvarsPeakDetectionNewSample$output_export_param_path),
                     MS1_type = req(input$MS1_type),
                     MS2_type = req(input$MS2_type),
                     ion = req(RvarsPeakDetectionNewSample$defaultParam$ion),
                     rt_begin = req(
                       as.character(RvarsPeakDetectionNewSample$defaultParam$rt_begin)
                     ),
                     rt_end = req(
                       as.character(RvarsPeakDetectionNewSample$defaultParam$rt_end)
                     ),
                     mz_range_begin = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mz_range_begin
                       )
                     ),
                     mz_range_end = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mz_range_end
                       )
                     ),
                     mz_tolerance_centroid_MS1 = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS1
                       )
                     ),
                     mz_tolerance_centroid_MS2 = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS2
                       )
                     ),
                     maxCharge = req(
                       as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
                     ),
                     min_Peakwidth = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
                       )
                     ),
                     min_PeakHeight = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
                       )
                     ),
                     mass_slice_width = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
                       )
                     ),
                     min_PeaksMassif = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$min_PeaksMassif
                       )
                     ),
                     Adduct_list = req(
                       as.list(RvarsPeakDetectionNewSample$defaultParam$Adduct_list)
                     ),
                     bw = req(
                       as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
                     ),
                     rt_tolerance = req(
                       as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
                     ),
                     mass_tolerance = req(
                       as.character(
                         RvarsPeakDetectionNewSample$defaultParam$mass_tolerance
                       )
                     ),
                     min_iset = req(as.character(input$min_iset)),
                     cutrat = req(as.character(input$cutrat)),
                     Ref = req(input$chosseRef)
                   )
                   
                   
                   
                   message("--- Start peak picking ---\n")
                   incProgress(1 / 8, detail = paste("Start peak picking...", collapse =
                                                       ""))
                   
                   ########################################################################
                   updateShinyProgressBar(
                     shinyProgressData = list(
                       session = session,
                       progressId = "preprocessProgressBar",
                       progressTotal = 8,
                       textId = "analysis_pre"
                     ),
                     pbValue = 2,
                     headerMsg = "Calling peak picking...",
                     footerMsg = "Start peak picking..."
                   )
                   ########################################################################
                   
                   #### Peak picking — batching + after_batch_fun pattern
                   n_input_runs <- length(list.files(req(directoryInput$directory),
                                                     pattern = "\\.d$|\\.mzML$",
                                                     full.names = TRUE,
                                                     ignore.case = TRUE))
                   batch_size_msdial <- if (n_input_runs > 100) 50 else NULL
                   timeout_sec_msdial <- if (!is.null(batch_size_msdial)) 7200 else NULL
                   
                   cache_path_srv <- file.path(req(directoryInput$directory),
                                               ".msdial_processed_cache.txt")
                   
                   # Créer le cluster parallèle UNE SEULE FOIS pour tous les batches.
                   # Cela évite la création/destruction répétée de sockets TCP (TIME_WAIT)
                   # qui bloquait l'application au 5e-6e batch.
                   .find_free_port_deconv <- function() {
                     tryCatch({
                       con <- serverSocket(port = 0)
                       port <- as.integer(sub(".*:(\\d+)$", "\\1", summary(con)$description))
                       close(con)
                       port
                     }, error = function(e) NULL)
                   }
                   deconv_bpparam <- NULL
                   .free_port_deconv <- .find_free_port_deconv()
                   if (!is.null(.free_port_deconv)) {
                     deconv_bpparam <- tryCatch(
                       BiocParallel::SnowParam(
                         workers = max(1L, parallel::detectCores() - 1L),
                         type = "SOCK", timeout = 120,
                         port = .free_port_deconv
                       ),
                       error = function(e) {
                         message(sprintf(
                           "--- Cluster déconvolution : création SnowParam échouée : %s → SerialParam ---",
                           conditionMessage(e)))
                         NULL
                       }
                     )
                     if (!is.null(deconv_bpparam))
                       message(sprintf(
                         "--- Cluster déconvolution créé (port %d, %d workers) ---",
                         .free_port_deconv,
                         BiocParallel::bpworkers(deconv_bpparam)))
                   } else {
                     message("--- Aucun port libre → déconvolution séquentielle ---")
                   }

                   processed_msdial_files <- character(0)
                   after_batch_fun <- function(new_msdial_files) {
                     new_msdial_files <- setdiff(new_msdial_files, processed_msdial_files)
                     if (length(new_msdial_files) == 0) return(invisible(NULL))
                     processed_msdial_files <<- c(processed_msdial_files, new_msdial_files)
                     
                     deconv_peaks_MSDIAL(path_to_peakList = req(new_msdial_files),
                                         output_directory = directoryOutput,
                                         file_adduct = "data/Adduit.csv",
                                         mass_slice_width = as.numeric(
                                           req(RvarsPeakDetectionNewSample$defaultParam$mass_slice_width)
                                         ),
                                         min_PeaksMassif = as.numeric(
                                           req(RvarsPeakDetectionNewSample$defaultParam$min_PeaksMassif)
                                         ),
                                         bpparam = deconv_bpparam,
                                         shinyProgressData =
                                           list(session = session,
                                                progressId = "preprocessProgressBar",
                                                progressTotal = 8,
                                                textId = "analysis_pre"))
                     removeFiles(path_to_files = directoryOutput, ext = '.msdial')
                     
                     # Écrire dans le cache APRÈS déconvolution réussie
                     msdial_stems   <- tolower(sub("\\.msdial$", "", basename(new_msdial_files),
                                                    ignore.case = TRUE))
                     all_inputs_srv <- list.files(req(directoryInput$directory),
                                                   pattern    = "\\.d$|\\.mzML$",
                                                   full.names = FALSE, ignore.case = TRUE)
                     input_stems_srv <- tolower(sub("\\.(d|mzML)$", "", all_inputs_srv,
                                                     ignore.case = TRUE))
                     matched_srv <- all_inputs_srv[input_stems_srv %in% msdial_stems]
                     if (length(matched_srv) > 0) {
                       existing_c <- if (file.exists(cache_path_srv)) {
                         tolower(trimws(readLines(cache_path_srv, warn = FALSE)))
                       } else character(0)
                       to_add_srv <- matched_srv[!(tolower(matched_srv) %in%
                                                      existing_c[nzchar(existing_c)])]
                       if (length(to_add_srv) > 0) {
                         cat(paste(to_add_srv, collapse = "\n"), "\n",
                             file = cache_path_srv, append = TRUE)
                         message(sprintf("--- Cache : %d échantillon(s) ajoutés ---",
                                         length(to_add_srv)))
                       }
                     }
                     gc()
                   }
                   
                   # Reprise des .msdial orphelins (MS-DIAL fini mais déconvolution crashée)
                   if (dir.exists(directoryOutput)) {
                     all_msdial <- list.files(directoryOutput,
                                              pattern    = "\\.msdial$",
                                              full.names = TRUE, ignore.case = TRUE)
                     all_msdial <- all_msdial[!grepl("AlignResult-", basename(all_msdial), ignore.case = TRUE)]
                     existing_csv_stems <- tolower(sub("\\.csv$", "",
                                                       list.files(directoryOutput, pattern = "\\.csv$",
                                                                  full.names = FALSE, ignore.case = TRUE), ignore.case = TRUE))
                     msdial_stems_chk <- tolower(sub("\\.msdial$", "", basename(all_msdial), ignore.case = TRUE))
                     pending_msdial <- all_msdial[!(msdial_stems_chk %in% existing_csv_stems)]
                     
                     if (length(pending_msdial) > 0) {
                       message(sprintf(
                         "--- Reprise : %d fichier(s) .msdial sans CSV → déconvolution ---",
                         length(pending_msdial)))
                       chunk_size_deconv <- 50L
                       n_chunks <- ceiling(length(pending_msdial) / chunk_size_deconv)
                       for (ch in seq_len(n_chunks)) {
                         ch_start <- (ch - 1L) * chunk_size_deconv + 1L
                         ch_end   <- min(ch * chunk_size_deconv, length(pending_msdial))
                         chunk_files <- pending_msdial[ch_start:ch_end]
                         after_batch_fun(chunk_files)
                       }
                     }
                   }
                   
                   system.time(
                     findPeaks_MSDIAL(
                       input_files = req(directoryInput$directory),
                       output_files = directoryOutput,
                       output_export_param = file.path("data/References", req(input$chosseRef)),
                       rt_begin = req(
                         as.character(RvarsPeakDetectionNewSample$defaultParam$rt_begin)
                       ),
                       rt_end = req(
                         as.character(RvarsPeakDetectionNewSample$defaultParam$rt_end)
                       ),
                       mz_range_begin = req(
                         as.character(
                           RvarsPeakDetectionNewSample$defaultParam$mz_range_begin
                         )
                       ),
                       mz_range_end = req(
                         as.character(
                           RvarsPeakDetectionNewSample$defaultParam$mz_range_end
                         )
                       ),
                       MS1_type = req(input$MS1_type),
                       MS2_type = req(input$MS2_type),
                       Adduct_list = req(
                         as.list(RvarsPeakDetectionNewSample$defaultParam$Adduct_list)
                       ),
                       maxCharge = req(
                         as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
                       ),
                       min_Peakwidth = req(
                         as.character(
                           RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
                         )
                       ),
                       min_PeakHeight = req(
                         RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
                       ),
                       mass_slice_width = req(
                         as.character(
                           RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
                         )
                       ),
                       batch_size = batch_size_msdial,
                       after_batch_fun = after_batch_fun,
                       timeout_sec = timeout_sec_msdial,
                       shinyProgressData = list(
                         session = session,
                         progressId = "preprocessProgressBar",
                         progressTotal = 8,
                         textId = "analysis_pre"
                       )
                     )
                   )
                   
                   
                   
                   
                   ###### Suppression des fichiers inutiles après peak picking
                   
                   message("--- Deleting unnecessary files ---\n")
                   
                   incProgress(1 / 8,
                               detail = paste("Deleting unnecessary files...", collapse = ""))
                   ########################################################################
                   updateShinyProgressBar(
                     shinyProgressData = list(
                       session = session,
                       progressId = "preprocessProgressBar",
                       progressTotal = 8,
                       textId = "analysis_pre"
                     ),
                     pbValue = 5,
                     headerMsg = " Deleting unnecessary files...",
                     footerMsg = ""
                   )
                   ########################################################################
                   
                   
                   source_python('lib/AnalysisNewSample/Python_files/modify_ParamMsdial.py')
                   
                   removeFiles(path_to_files = directoryInput$directory,
                               ext = '.dcl')
                   removeFiles(path_to_files = directoryInput$directory,
                               ext = '.pai2')
                   removeFiles(path_to_files = directoryInput$directory,
                               ext = '.aef')
                   
                   
                   
                   #### Grouping isotopic massifs into peptides
                   
                   # Supprimer les AlignResult-* (fichiers projet MS-DIAL, inutiles)
                   align_files <- list.files(directoryOutput, pattern = "^AlignResult-", full.names = TRUE)
                   if (length(align_files) > 0) file.remove(align_files)
                   
                   # Vérifier s'il reste des .msdial non traités (mode sans batching ou leftovers)
                   path_file_msdial_newSample <- list.files(directoryOutput,
                                                            pattern = "\\.msdial$",
                                                            full.names = TRUE, ignore.case = TRUE)
                   path_file_msdial_newSample <- path_file_msdial_newSample[
                     !grepl("AlignResult-", basename(path_file_msdial_newSample), ignore.case = TRUE)]
                   
                   if (length(path_file_msdial_newSample) >= 1) {
                     # .msdial restants = mode non-batché ou orphelins → déconvolution classique
                     RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample <-
                       deconv_peaks_MSDIAL(
                         path_to_peakList = req(path_file_msdial_newSample),
                         output_directory = directoryOutput,
                         file_adduct = "data/Adduit.csv",
                         mass_slice_width = as.numeric(
                           req(RvarsPeakDetectionNewSample$defaultParam$mass_slice_width)
                         ),
                         min_PeaksMassif = as.numeric(
                           req(RvarsPeakDetectionNewSample$defaultParam$min_PeaksMassif)
                         ),
                         bpparam = deconv_bpparam,
                         shinyProgressData =
                           list(session = session,
                                progressId = "preprocessProgressBar",
                                progressTotal = 8,
                                textId = "analysis_pre")
                       )
                     removeFiles(path_to_files = directoryOutput, ext = '.msdial')
                   } else {
                     # Mode batché : reconstituer le tableau depuis les CSV
                     csv_files <- list.files(directoryOutput, pattern = "\\.csv$",
                                             full.names = TRUE, ignore.case = TRUE)
                     if (length(csv_files) > 0) {
                       message(sprintf("--- Agrégation de %d CSV (produits par le traitement bout-en-bout) ---",
                                       length(csv_files)))
                       all_peaks <- lapply(csv_files, function(f) {
                         tryCatch(read.csv(f, stringsAsFactors = FALSE),
                                  error = function(e) { warning(paste("CSV illisible:", f)); NULL })
                       })
                       all_peaks <- all_peaks[!vapply(all_peaks, is.null, logical(1))]
                       if (length(all_peaks) > 0) {
                         peaks_combined <- do.call("rbind", all_peaks)
                         colnames(peaks_combined)[1:10] <- c("mz","mzmin","mzmax","rt","rtmin","rtmax",
                                                              "into","maxo","sn","sample")
                         RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample <- peaks_combined
                       }
                     }
                   }

                   # Arrêter le cluster une fois tous les batches et la déconvolution finale terminés
                   if (!is.null(deconv_bpparam)) {
                     tryCatch(BiocParallel::bpstop(deconv_bpparam), error = function(e) NULL)
                     message("--- Cluster déconvolution arrêté ---")
                     deconv_bpparam <- NULL
                   }

                   if (!is.null(RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample)) {
                     RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
                       split(
                         RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample,
                         f =
                           RvarsPeakDetectionNewSample$peaks_MSDIAL_mono_iso_newSample$sample
                       )
                     
                     
                     
                     
                     
                     message(" \n --- Preprocess complete ! ---\n")
                     ########################################################################
                     updateShinyProgressBar(
                       shinyProgressData = list(
                         session = session,
                         progressId = "preprocessProgressBar",
                         progressTotal = 8,
                         textId = "analysis_pre"
                       ),
                       pbValue = 8,
                       headerMsg = " Preprocess complete !",
                       footerMsg = ""
                     )
                     ########################################################################
                     
                     
                     
                     
                     # Pipeline completed hopefully
                     #shinyjs::html("analysisProgress","Preprocess complete !")
                     
                     #### End Processing
                     sendSweetAlert(
                       session = session,
                       title = "Preprocess complete !",
                       text = HTML(
                         paste(
                           '<h3> Parameters used : </h3>

                <span style="font-weight:bold;">Reference map : ',
                           req(input$chosseRef),
                           '</span>

                <h4>Mass accuracy(centroid parameter) : </h4>
                <ol style = "list-style-type: none;">
                <li>MS1 tolerance (Da) : ',
                           req(
                             as.character(
                               RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS1
                             )
                           ),
                           '</li>
                <li>MS2 tolerance (Da) : ',
                           req(
                             as.character(
                               RvarsPeakDetectionNewSample$defaultParam$mz_tolerance_centroid_MS2
                             )
                           ),
                           '</li>
                </ol>

                <h4>Peak detection parameters : </h4>
                <ol style = "list-style-type: none;">
                <li>Mass slice width (Da) : ',
                           req(
                             as.character(
                               RvarsPeakDetectionNewSample$defaultParam$mass_slice_width
                             )
                           ),
                           ' </li>
                <li>Minimum peak height (amplitude) : ',
                           req(
                             as.character(
                               RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight
                             )
                           ),
                           ' </li>
                <li>Minimum peak widt (scan) : ',
                           req(
                             as.character(
                               RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth
                             )
                           ),
                           ' </li>
                <li>Maximum charged number : ',
                           req(
                             as.character(RvarsPeakDetectionNewSample$defaultParam$maxCharge)
                           ),
                           '</li>
                </ol>

                <h4> Grouping of chromatographic peaks within samples : </h4>
                <ol style = "list-style-type: none;">
                <li>Bandwidth (CE-time tolerance) (second) : ',
                           req(
                             as.character(RvarsPeakDetectionNewSample$defaultParam$bw)
                           ),
                           ' </li>
                </ol>
                <br/>
                <h3>Click OK to continue !</h3>'
                         )
                       ),
                       type = "success",
                       width = "70%",
                       closeOnClickOutside = FALSE,
                       html = TRUE
                     )
                     
                     
                     
                     
                     #showTab("analysisNavbar","Samples normalization", select = TRUE, session = session)
                     
                     # updateNavbarPage(
                     #   session = session,
                     #   inputId = "analysisNavbar",
                     #   selected = "Match reference map"
                     # )
                     
                     updateRadioButtons(session = session,
                                        inputId = "IdAnalysisStep",
                                        selected = "2")
                     
                     shinyjs::show("normIntensity")
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
                     
                   } else {
                     message("No file .msdial...!")
                     hide("progressWrapper")
                     hide("analysisProgress")
                     hide("idpanel_analysisProgress")
                     enable("runPeakPicking")
                     enable("updateProject")
                     enable("confirmProject")
                     enable("processParameters")
                     enable("directory")
                     
                     enable(id = "chosseRef")
                     enable(id = "projectName")
                     enable(id = "dataType")
                     enable(id = "IdDataType")
                     enable(id = "MS1_type")
                     enable(id = "MS2_type")
                     
                     
                     shinyjs::html("analysisProgress", html = NULL)
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "There is no input MS file to be imported !",
                       type = "alert"
                     )
                   }
                   
                 })

               }
               
               
               
               enable("match")
               enable("normIntensity")
               enable("runNormalizing")
               enable("returnAnalysisViewer")
               enable("returnMatchRef")
               enable("SaveAnalysisResults")
               enable("finishAnalyze")
               enable("features_list")
               shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
               shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
               shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
               shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
               shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
               
               shinyjs::show("id_PlotCutt_newSample")
               
               
               
             })


########################################################################
# Reset the timebar for later
updateShinyProgressBar(
  shinyProgressData = list(
    session = session,
    progressId = "preprocessProgressBar",
    progressTotal = 8,
    textId = "analysis_pre"
  ),
  pbValue = 1,
  headerMsg = "",
  footerMsg = ""
)
########################################################################

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~ Upload massif list files  ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$massif_list_newSample
             }
             , {
               files <- input$massif_list_newSample
               ext <- tools::file_ext(files$datapath)
               
               
               if (length(ext) > 1) {
                 if (all.equal(ext, rep("csv", length(ext))) != TRUE) {
                   message("Please upload a csv file...!")
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning"
                   )
                 } else {
                   a <- lapply(input$massif_list_newSample$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
                       'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
                           'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
                       type = "warning"
                     )
                   })
                   
                   
                   if (!is.element("M.H", colnames(a)) ||
                       !is.element("M.H.min", colnames(a)) ||
                       !is.element("M.H.max", colnames(a)) ||
                       !is.element("CE.time", colnames(a)) ||
                       !is.element("CE.time.min", colnames(a)) ||
                       !is.element("CE.time.max", colnames(a)) ||
                       !is.element("integrated.intensity", colnames(a)) ||
                       !is.element("intensity", colnames(a)) ||
                       !is.element("sn", colnames(a)) ||
                       !is.element("sample", colnames(a)) ||
                       !is.element("iso.mass", colnames(a)) ||
                       !is.element("iso.mass.link", colnames(a)) ||
                       !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Adduct", colnames(a)) ||
                       ncol(a) < 16) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
                       'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
                           'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
                       type = "warning"
                     )
                   } else {
                     
                     
                     ColnameData <-
                       c(
                         'M.H',
                         'M.H.min',
                         'M.H.max',
                         'CE.time',
                         'CE.time.min',
                         'CE.time.max',
                         'integrated-intensity',
                         'intensity',
                         'sn',
                         'sample',
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group',
                         'Adduct'
                       )
                     
                     ColnamesToUse <-
                       c(
                         "mz",
                         "mzmin",
                         "mzmax",
                         "rt",
                         "rtmin",
                         "rtmax",
                         "into",
                         "maxo",
                         "sn",
                         "sample",
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group',
                         'Adduct'
                       )
                     
                     colnames(a) <- ColnamesToUse
                     
                     a <- a
                     a <- split(a, f = a$sample)
                     RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
                       a
                     
                     
                     updateRadioButtons(session = session,
                                        inputId = "IdAnalysisStep",
                                        selected = "2")
                     enable("ViewAnalysis_duplicate")
                     shinyjs::show("id_PlotCutt_newSample")
                     
                     shinyjs::show("normIntensity")
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
                     enable("match")
                     enable("normIntensity")
                     enable("runNormalizing")
                     enable("returnAnalysisViewer")
                     enable("returnMatchRef")
                     enable("SaveAnalysisResults")
                     enable("finishAnalyze")
                     enable("features_list")
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
                     
                     
                   }
                   
                 }
               } else {
                 if (ext != "csv") {
                   message("Please upload a csv file...!")
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning"
                   )
                 } else {
                   a <- lapply(input$massif_list_newSample$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
                       'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
                           'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
                       type = "warning"
                     )
                   })
                   
                   
                   
                   if (!is.element("M.H", colnames(a)) ||
                       !is.element("M.H.min", colnames(a)) ||
                       !is.element("M.H.max", colnames(a)) ||
                       !is.element("CE.time", colnames(a)) ||
                       !is.element("CE.time.min", colnames(a)) ||
                       !is.element("CE.time.max", colnames(a)) ||
                       !is.element("integrated.intensity", colnames(a)) ||
                       !is.element("intensity", colnames(a)) ||
                       !is.element("sn", colnames(a)) ||
                       !is.element("sample", colnames(a)) ||
                       !is.element("iso.mass", colnames(a)) ||
                       !is.element("iso.mass.link", colnames(a)) ||
                       !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Adduct", colnames(a)) ||
                       ncol(a) < 16) {
                     message("Please upload a csv file...!")
                     message("\n Probleme inconnu")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max',
                       'integrated-intensity', 'intensity','sn', 'sample', 'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
                           'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group','Adduct' not found in files.",
                       type = "warning"
                     )
                   } else {
                     
                     ColnameData <-
                       c(
                         'M.H',
                         'M.H.min',
                         'M.H.max',
                         'CE.time',
                         'CE.time.min',
                         'CE.time.max',
                         'integrated-intensity',
                         'intensity',
                         'sn',
                         'sample',
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group',
                         'Adduct'
                       )
                     
                     ColnamesToUse <-
                       c(
                         "mz",
                         "mzmin",
                         "mzmax",
                         "rt",
                         "rtmin",
                         "rtmax",
                         "into",
                         "maxo",
                         "sn",
                         "sample",
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group',
                         'Adduct'
                       )
                     
                     colnames(a) <- ColnamesToUse
                     
                     
                     a <- a
                     a <- split(a, f = a$sample)
                     RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample <-
                       a
                     
                     updateRadioButtons(session = session,
                                        inputId = "IdAnalysisStep",
                                        selected = "2")
                     
                     enable("ViewAnalysis_duplicate")
                     shinyjs::show("id_PlotCutt_newSample")
                     
                     shinyjs::show("normIntensity")
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                     
                     enable("match")
                     enable("normIntensity")
                     enable("runNormalizing")
                     enable("returnAnalysisViewer")
                     enable("returnMatchRef")
                     enable("SaveAnalysisResults")
                     enable("finishAnalyze")
                     enable("features_list")
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
                     shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
                     
                     
                   }
                 }
               }
               
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~~~~ Samples filtering ~~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

observe({
  if (!is.null(names(
    RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
  ))) {
    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
      data.frame(
        row.names = names(
          RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
        ),
        rt_min_cut_newSample = rep(
          NA,
          length(
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
          )
        ),
        rt_max_cut_newSample = rep(
          NA,
          length(
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
          )
        ),
        Unit = rep(
          "Second",
          length(
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
          )
        )
      )
    
    
    output$SelectSampleCut <- renderUI({
      pickerInput(
        inputId = "sample_selectedCutting_newSample",
        label = "Select a sample:",
        choices = names(
          RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
        ),
        options = pickerOptions(
          size = 10,
          showTick = TRUE,
          style = "btn-primary"
        ),
        width = "fit"
      )
    })
    
    
  } else{
    output$SelectSampleCut <- renderUI({
      pickerInput(
        inputId = "sample_selectedCutting_newSample",
        label = "Select a sample:",
        choices = NULL,
        options = pickerOptions(
          size = 10,
          showTick = TRUE,
          style = "btn-primary"
        ),
        width = "fit"
      )
    })
    
    RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
      NULL
  }
  
  
})


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ sample cutting viewer ~~~~~~~~~~~~~~~~~~~~~~~~#
observe({
  if (length(input$sample_selectedCutting_newSample) != 0) {
    sample_cutting_rv <-
      req(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])
    colnames(sample_cutting_rv)[c(1, 4, 8)] <-
      c("M.H", "CE.time", "intensity")
    sample_cutting_rv$intensity <- log2(sample_cutting_rv$intensity)
    RvarsPeakDetectionNewSample$sample_cutting_newSample <-
      sample_cutting_rv
    
    
  }
  
})

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Sample cutting to used ~~~~~~~~~~~~~~~~~~~~~~~~#
## Convert time sample select
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting_newSample
             },
             handlerExpr = {
               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample <-
                 req(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])
               colnames(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)[c(1, 4, 8)] <-
                 c("M.H", "CE.time", "intensity")
               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$intensity <-
                 log2(
                   RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$intensity
                 )
               
               
               
               #Because les data viennent initialement en second
               RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
                 TRUE
               if (input$UnitTime_sampleCutting_newSample == "Minute") {
                 #RvarsPeakDetectionNewSample$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-peaks_mono_iso_NewRefMap_toPlot()
                 print(
                   paste(
                     "Convert to min",
                     input$UnitTime_sampleCutting_newSample == "Minute" &
                       RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE
                   )
                 )
                 if (input$UnitTime_sampleCutting_newSample == "Minute" &
                     RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
                   if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
                     RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
                       req(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
                       ) / 60
                     RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
                       FALSE
                   }
                 }
               }
               
               
               if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 3] <-
                   input$UnitTime_sampleCutting_newSample
                 
               }
             })




observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$UnitTime_sampleCutting_newSample
             },
             handlerExpr = {
               print(
                 paste(
                   "Convert to min",
                   input$UnitTime_sampleCutting_newSample == "Minute" &
                     RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE
                 )
               )
               if (isolate(input$UnitTime_sampleCutting_newSample) == "Minute" &
                   RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
                 if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
                   RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
                     req(
                       RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
                     ) / 60
                   RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
                     FALSE
                 }
               }
               
               print(
                 paste(
                   "Covert to Second",
                   input$UnitTime_sampleCutting_newSample == "Second" &
                     RvarsPeakDetectionNewSample$Second_Cutting_newSample == FALSE
                 )
               )
               if (isolate(input$UnitTime_sampleCutting_newSample) == "Second" &
                   RvarsPeakDetectionNewSample$Second_Cutting_newSample == FALSE) {
                 if (!is.null(RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample)) {
                   RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time <-
                     req(
                       RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample$CE.time
                     ) * 60
                   RvarsPeakDetectionNewSample$Second_Cutting_newSample <-
                     TRUE
                 }
               }
               
               if (input$UnitTime_sampleCutting_newSample == "Second" &
                   RvarsPeakDetectionNewSample$Second_Cutting_newSample == TRUE) {
                 RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample <-
                   req(RvarsPeakDetectionNewSample$sample_cutting_newSample)
               }
               
               if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 3] <-
                   input$UnitTime_sampleCutting_newSample
                 
               }
               
               
             })


rangesZoomSample_selectedCutting_newSample <-
  reactiveValues(x = NULL, y = NULL)

# When a double-click happens, check if there's a brush on the plot.
# If so, zoom to the brush bounds; if not, reset the zoom.
observeEvent({
  input$sample_selectedCutting_dblclick_newSample
}, {
  brush <- input$sample_selectedCutting_brush_newSample
  if (!is.null(brush)) {
    rangesZoomSample_selectedCutting_newSample$x <-
      c(brush$xmin, brush$xmax)
    rangesZoomSample_selectedCutting_newSample$y <-
      c(brush$ymin, brush$ymax)
    
  } else {
    ## reset coord_cartesian
    rangesZoomSample_selectedCutting_newSample$x <- NULL
    rangesZoomSample_selectedCutting_newSample$y <- NULL
  }
})

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting_newSample
             },
             handlerExpr = {
               updateNumericInput(
                 session = session,
                 inputId = "rt_min_cut_newSample",
                 value = RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
               )
               
               updateNumericInput(
                 session = session,
                 inputId = "rt_max_cut_newSample",
                 value = RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
               )
               
               
             })

observe({
  if (!is.null(input$sample_selectedCutting_newSample)) {
    if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
      if (is.na(
        RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
      ) &
      is.na(
        RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
      )) {
        print("Sample selected not cutted")
        if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
            c(NA, NA)
          
        }
        
        
        
        output$sample_selectedCutting_Plot_newSample <- renderPlot({
          if (!is.null(
            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
          )) {
            shinyjs::show("UnitTime_sampleCutting_id_newSample")
            shinyjs::show("mousepositionSampleCutting_newSample")
            
            RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
              ggplot() +
              aes(x = CE.time,
                  y = M.H,
                  colour = intensity) +
              #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
              geom_point(size = 1) +
              # geom_vline(xintercept = 3229, lwd = 1.5, color = "blue", linetype = "dashed")+
              # geom_vline(xintercept = 750, lwd = 1.5, color = "blue", linetype = "dashed")+
              scale_color_viridis_c(option = "inferno", direction = -1) +
              ylab("Mass (M+H) (Da)") +
              xlab(paste(
                "CE-time (",
                req(input$UnitTime_sampleCutting_newSample),
                ")"
              )) +
              coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                              ylim = rangesZoomSample_selectedCutting_newSample$y,
                              expand = TRUE) +
              ggtitle(paste(
                "Sample selected :",
                req(input$sample_selectedCutting_newSample),
                "\n"
              )) +
              
              scale_x_continuous(n.breaks = 14) +
              #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
              
              
              #facet_grid(vars(sample), vars())+
              #option_graphe.3
              theme_ben() +
              labs(colour = "log2 Intensity") +
              theme(
                plot.title = element_text(
                  size = rel(0.9),
                  face = "bold",
                  color = "#760001",
                  margin = margin(0, 0, 5, 0),
                  hjust = 0.5
                ),
                plot.subtitle = element_text(hjust = 0.5)
              )
            
          }
          
          
          
          
        })
        
        ## Mouse position
        # output$sample_selectedCutting_Plot_info <- renderText({
        #   paste0("Mouse position : ",
        #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
        #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
        # })
        
        output$sample_selectedCutting_Plot_info_newSample <-
          renderText({
            paste0(
              "Mouse position : ",
              xy_str(
                input$sample_selectedCutting_hover_newSample,
                "CE-time",
                "M+H"
              ),
              "Click: ",
              xy_str(
                input$sample_selectedCutting_click_newSample,
                "CE-time",
                "M+H"
              )
            )
            # paste0("Mouse position : ",
            #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
            #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
          })
        
        ## Bulle info
        
        #### info-bulle
        output$sample_selectedCutting_hover_info_newSample <-
          renderUI({
            hover <- req(input$sample_selectedCutting_hover_newSample)
            
            if (!is.null(
              RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
            )) {
              point <-
                nearPoints(
                  req(
                    RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                  ),
                  hover,
                  threshold = 5,
                  maxpoints = 1,
                  addDist = TRUE
                )
              if (nrow(point) == 0)
                return(NULL)
              
              # calculate point position INSIDE the image as percent of total dimensions
              # from left (horizontal) and from top (vertical)
              left_pct <-
                (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
              top_pct <-
                (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
              
              # calculate distance from left and bottom side of the picture in pixels
              left_px <-
                hover$range$left + left_pct * (hover$range$right - hover$range$left)
              top_px <-
                hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
              
              # create style property fot tooltip
              # background color is set so tooltip is a bit transparent
              # z-index is set so we are sure are tooltip will be on top
              style <-
                paste0(
                  "position:absolute; z-index:100; background-color: #760001; color: white;",
                  "left:",
                  left_px + 2,
                  "px; top:",
                  top_px + 2,
                  "px;"
                )
              
              # actual tooltip created as wellPanel
              div(class = "well well-sm",
                  style = style,
                  p(HTML(
                    paste0(
                      "<span class='bullText'> CE-time: </span>",
                      round(point$CE.time, 2),
                      "<br/>",
                      "<span class='bullText'> M+H: </span>",
                      round(point$M.H, 4),
                      "<br/>",
                      "<span class='bullText'> log2 Intensity: </span>",
                      round(point$intensity, 2),
                      "<br/>",
                      "<span class='bullText'> Intensity: </span>",
                      round(2 ^ (point$intensity), 0),
                      "<br/>"
                    )
                  )))
            }
            
            
            
            
            
          })
        
        
        
      }
    }
    else {
      output$sample_selectedCutting_Plot_newSample <- renderPlot({
        
      })
      output$sample_selectedCutting_Plot_info_newSample <-
        renderText({
          
        })
      output$sample_selectedCutting_hover_info_newSample <-
        renderUI({
          
        })
      hide("UnitTime_sampleCutting_id_newSample")
    }
  } else {
    output$sample_selectedCutting_Plot_newSample <- renderPlot({
      
    })
  }
  
  
})


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$cutOff_newSample
             },
             handlerExpr = {
               if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
                 if (!is.na(input$rt_min_cut_newSample) &
                     !is.na(input$rt_max_cut_newSample)) {
                   print("cutoff_newSample")
                   output$sample_selectedCutting_Plot_newSample <-
                     renderPlot({
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         shinyjs::show("UnitTime_sampleCutting_id_newSample")
                         shinyjs::show("mousepositionSampleCutting_newSample")
                         
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_min_cut_newSample),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           geom_vline(
                             xintercept = isolate(input$rt_max_cut_newSample),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = c(0, isolate(input$rt_max_cut_newSample)),
                             xmax = c(isolate(input$rt_min_cut_newSample), Inf),
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste(
                             "CE-time (",
                             req(input$UnitTime_sampleCutting_newSample),
                             ")"
                           )) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                           ylim = rangesZoomSample_selectedCutting_newSample$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             req(input$sample_selectedCutting_newSample),
                             "\n"
                           )) +
                           
                           scale_x_continuous(n.breaks = 14) +
                           #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
                           #facet_grid(vars(sample), vars())+
                           #option_graphe.3
                           theme_ben() +
                           labs(colour = "log2 Intensity") +
                           theme(
                             plot.title = element_text(
                               size = rel(0.9),
                               face = "bold",
                               color = "#760001",
                               margin = margin(0, 0, 5, 0),
                               hjust = 0.5
                             ),
                             plot.subtitle = element_text(hjust = 0.5)
                           )
                         
                       }
                       
                       
                       
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info_newSample <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(
                           input$sample_selectedCutting_hover_newSample,
                           "CE-time",
                           "M+H"
                         ),
                         "Click: ",
                         xy_str(
                           input$sample_selectedCutting_click_newSample,
                           "CE-time",
                           "M+H"
                         )
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info_newSample <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover_newSample)
                       
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         point <-
                           nearPoints(
                             req(
                               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                             ),
                             hover,
                             threshold = 5,
                             maxpoints = 1,
                             addDist = TRUE
                           )
                         if (nrow(point) == 0)
                           return(NULL)
                         
                         # calculate point position INSIDE the image as percent of total dimensions
                         # from left (horizontal) and from top (vertical)
                         left_pct <-
                           (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                         top_pct <-
                           (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
                         # calculate distance from left and bottom side of the picture in pixels
                         left_px <-
                           hover$range$left + left_pct * (hover$range$right - hover$range$left)
                         top_px <-
                           hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
                         # create style property fot tooltip
                         # background color is set so tooltip is a bit transparent
                         # z-index is set so we are sure are tooltip will be on top
                         style <-
                           paste0(
                             "position:absolute; z-index:100; background-color: #760001; color: white;",
                             "left:",
                             left_px + 2,
                             "px; top:",
                             top_px + 2,
                             "px;"
                           )
                         
                         # actual tooltip created as wellPanel
                         div(class = "well well-sm",
                             style = style,
                             p(HTML(
                               paste0(
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
                                 "<br/>",
                                 "<span class='bullText'> M+H: </span>",
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> log2 Intensity: </span>",
                                 round(point$intensity, 2),
                                 "<br/>",
                                 "<span class='bullText'> Intensity: </span>",
                                 round(2 ^ (point$intensity), 0),
                                 "<br/>"
                               )
                             )))
                       }
                       
                       
                       
                       
                       
                     })
                   
                   if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
                       c(
                         isolate(input$rt_min_cut_newSample),
                         isolate(input$rt_max_cut_newSample)
                       )
                   }
                   
                   
                   
                 } else if (!is.na(input$rt_min_cut_newSample) &
                            is.na(input$rt_max_cut_newSample)) {
                   print("cutoff_newSample")
                   output$sample_selectedCutting_Plot_newSample <-
                     renderPlot({
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         shinyjs::show("UnitTime_sampleCutting_id_newSample")
                         shinyjs::show("mousepositionSampleCutting_newSample")
                         
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_min_cut_newSample),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = 0,
                             xmax = isolate(input$rt_min_cut_newSample),
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste(
                             "CE-time (",
                             req(input$UnitTime_sampleCutting_newSample),
                             ")"
                           )) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                           ylim = rangesZoomSample_selectedCutting_newSample$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             req(input$sample_selectedCutting_newSample),
                             "\n"
                           )) +
                           
                           scale_x_continuous(n.breaks = 14) +
                           #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
                           #facet_grid(vars(sample), vars())+
                           #option_graphe.3
                           theme_ben() +
                           labs(colour = "log2 Intensity") +
                           theme(
                             plot.title = element_text(
                               size = rel(0.9),
                               face = "bold",
                               color = "#760001",
                               margin = margin(0, 0, 5, 0),
                               hjust = 0.5
                             ),
                             plot.subtitle = element_text(hjust = 0.5)
                           )
                         
                       }
                       
                       
                       
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info_newSample <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(
                           input$sample_selectedCutting_hover_newSample,
                           "CE-time",
                           "M+H"
                         ),
                         "Click: ",
                         xy_str(
                           input$sample_selectedCutting_click_newSample,
                           "CE-time",
                           "M+H"
                         )
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info_newSample <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover_newSample)
                       
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         point <-
                           nearPoints(
                             req(
                               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                             ),
                             hover,
                             threshold = 5,
                             maxpoints = 1,
                             addDist = TRUE
                           )
                         if (nrow(point) == 0)
                           return(NULL)
                         
                         # calculate point position INSIDE the image as percent of total dimensions
                         # from left (horizontal) and from top (vertical)
                         left_pct <-
                           (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                         top_pct <-
                           (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
                         # calculate distance from left and bottom side of the picture in pixels
                         left_px <-
                           hover$range$left + left_pct * (hover$range$right - hover$range$left)
                         top_px <-
                           hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
                         # create style property fot tooltip
                         # background color is set so tooltip is a bit transparent
                         # z-index is set so we are sure are tooltip will be on top
                         style <-
                           paste0(
                             "position:absolute; z-index:100; background-color: #760001; color: white;",
                             "left:",
                             left_px + 2,
                             "px; top:",
                             top_px + 2,
                             "px;"
                           )
                         
                         # actual tooltip created as wellPanel
                         div(class = "well well-sm",
                             style = style,
                             p(HTML(
                               paste0(
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
                                 "<br/>",
                                 "<span class='bullText'> M+H: </span>",
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> log2 Intensity: </span>",
                                 round(point$intensity, 2),
                                 "<br/>",
                                 "<span class='bullText'> Intensity: </span>",
                                 round(2 ^ (point$intensity), 0),
                                 "<br/>"
                               )
                             )))
                       }
                       
                       
                       
                       
                       
                     })
                   
                   if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
                       c(isolate(input$rt_min_cut_newSample), NA)
                   }
                   
                   
                 } else if (is.na(input$rt_min_cut_newSample) &
                            !is.na(input$rt_max_cut_newSample)) {
                   print("cutoff")
                   output$sample_selectedCutting_Plot_newSample <-
                     renderPlot({
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         shinyjs::show("UnitTime_sampleCutting_id_newSample")
                         shinyjs::show("mousepositionSampleCutting_newSample")
                         
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_max_cut_newSample),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = isolate(input$rt_max_cut_newSample),
                             xmax = Inf,
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste(
                             "CE-time (",
                             req(input$UnitTime_sampleCutting_newSample),
                             ")"
                           )) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                           ylim = rangesZoomSample_selectedCutting_newSample$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             req(input$sample_selectedCutting_newSample),
                             "\n"
                           )) +
                           
                           scale_x_continuous(n.breaks = 14) +
                           #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                           
                           
                           #facet_grid(vars(sample), vars())+
                           #option_graphe.3
                           theme_ben() +
                           labs(colour = "log2 Intensity") +
                           theme(
                             plot.title = element_text(
                               size = rel(0.9),
                               face = "bold",
                               color = "#760001",
                               margin = margin(0, 0, 5, 0),
                               hjust = 0.5
                             ),
                             plot.subtitle = element_text(hjust = 0.5)
                           )
                         
                       }
                       
                       
                       
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info_newSample <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(
                           input$sample_selectedCutting_hover_newSample,
                           "CE-time",
                           "M+H"
                         ),
                         "Click: ",
                         xy_str(
                           input$sample_selectedCutting_click_newSample,
                           "CE-time",
                           "M+H"
                         )
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info_newSample <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover_newSample)
                       
                       if (!is.null(
                         RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                       )) {
                         point <-
                           nearPoints(
                             req(
                               RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                             ),
                             hover,
                             threshold = 5,
                             maxpoints = 1,
                             addDist = TRUE
                           )
                         if (nrow(point) == 0)
                           return(NULL)
                         
                         # calculate point position INSIDE the image as percent of total dimensions
                         # from left (horizontal) and from top (vertical)
                         left_pct <-
                           (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                         top_pct <-
                           (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                         
                         # calculate distance from left and bottom side of the picture in pixels
                         left_px <-
                           hover$range$left + left_pct * (hover$range$right - hover$range$left)
                         top_px <-
                           hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                         
                         # create style property fot tooltip
                         # background color is set so tooltip is a bit transparent
                         # z-index is set so we are sure are tooltip will be on top
                         style <-
                           paste0(
                             "position:absolute; z-index:100; background-color: #760001; color: white;",
                             "left:",
                             left_px + 2,
                             "px; top:",
                             top_px + 2,
                             "px;"
                           )
                         
                         # actual tooltip created as wellPanel
                         div(class = "well well-sm",
                             style = style,
                             p(HTML(
                               paste0(
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
                                 "<br/>",
                                 "<span class='bullText'> M+H: </span>",
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> log2 Intensity: </span>",
                                 round(point$intensity, 2),
                                 "<br/>",
                                 "<span class='bullText'> Intensity: </span>",
                                 round(2 ^ (point$intensity), 0),
                                 "<br/>"
                               )
                             )))
                       }
                       
                       
                       
                       
                       
                     })
                   
                   if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
                       c(NA, isolate(input$rt_max_cut_newSample))
                   }
                   
                   
                 } else  if (is.na(input$rt_min_cut_newSample) &
                             is.na(input$rt_max_cut_newSample)) {
                   if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), 1:2] <-
                       c(NA, NA)
                     
                   }
                 }
                 
               } else {
                 output$sample_selectedCutting_Plot_newSample <- renderPlot({
                   
                 })
                 output$sample_selectedCutting_Plot_info_newSample <-
                   renderText({
                     
                   })
                 output$sample_selectedCutting_hover_info_newSample <-
                   renderUI({
                     
                   })
                 hide("UnitTime_sampleCutting_id_newSample")
               }
               
               
               
               
             })



observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting_newSample
             },
             handlerExpr = {
               updateNumericInput(
                 session = session,
                 inputId = "rt_min_cut_newSample",
                 value = as.numeric(
                   RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                 )
               )
               
               updateNumericInput(
                 session = session,
                 inputId = "rt_max_cut_newSample",
                 value = as.numeric(
                   RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                 )
               )
               
               
             })


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting_newSample
             },
             handlerExpr = {
               if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[req(input$sample_selectedCutting_newSample)][[1]])) {
                 if (!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
                   if (!is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                   ) &
                   !is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                   )) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot_newSample <-
                       renderPlot({
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           shinyjs::show("UnitTime_sampleCutting_id_newSample")
                           shinyjs::show("mousepositionSampleCutting_newSample")
                           
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = c(
                                 0,
                                 as.numeric(
                                   RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                                 )
                               ),
                               xmax = c(
                                 as.numeric(
                                   RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                                 ),
                                 Inf
                               ),
                               ymin = -Inf ,
                               ymax = Inf,
                               alpha = 0.5,
                               fill = "gray"
                             ) +
                             scale_color_viridis_c(option = "inferno", direction = -1) +
                             ylab("Mass (M+H) (Da)") +
                             xlab(paste(
                               "CE-time (",
                               req(input$UnitTime_sampleCutting_newSample),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                             ylim = rangesZoomSample_selectedCutting_newSample$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               req(input$sample_selectedCutting_newSample),
                               "\n"
                             )) +
                             
                             scale_x_continuous(n.breaks = 14) +
                             #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
                             #facet_grid(vars(sample), vars())+
                             #option_graphe.3
                             theme_ben() +
                             labs(colour = "log2 Intensity") +
                             theme(
                               plot.title = element_text(
                                 size = rel(0.9),
                                 face = "bold",
                                 color = "#760001",
                                 margin = margin(0, 0, 5, 0),
                                 hjust = 0.5
                               ),
                               plot.subtitle = element_text(hjust = 0.5)
                             )
                           
                         }
                         
                         
                         
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info_newSample <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover_newSample,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click_newSample,
                             "CE-time",
                             "M+H"
                           )
                         )
                         # paste0("Mouse position : ",
                         #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                         #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                       })
                     ## Bulle info
                     
                     #### info-bulle
                     output$sample_selectedCutting_hover_info_newSample <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover_newSample)
                         
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           point <-
                             nearPoints(
                               req(
                                 RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                               ),
                               hover,
                               threshold = 5,
                               maxpoints = 1,
                               addDist = TRUE
                             )
                           if (nrow(point) == 0)
                             return(NULL)
                           
                           # calculate point position INSIDE the image as percent of total dimensions
                           # from left (horizontal) and from top (vertical)
                           left_pct <-
                             (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                           top_pct <-
                             (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
                           # calculate distance from left and bottom side of the picture in pixels
                           left_px <-
                             hover$range$left + left_pct * (hover$range$right - hover$range$left)
                           top_px <-
                             hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
                           # create style property fot tooltip
                           # background color is set so tooltip is a bit transparent
                           # z-index is set so we are sure are tooltip will be on top
                           style <-
                             paste0(
                               "position:absolute; z-index:100; background-color: #760001; color: white;",
                               "left:",
                               left_px + 2,
                               "px; top:",
                               top_px + 2,
                               "px;"
                             )
                           
                           # actual tooltip created as wellPanel
                           div(class = "well well-sm",
                               style = style,
                               p(HTML(
                                 paste0(
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
                                   "<br/>",
                                   "<span class='bullText'> M+H: </span>",
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> log2 Intensity: </span>",
                                   round(point$intensity, 2),
                                   "<br/>",
                                   "<span class='bullText'> Intensity: </span>",
                                   round(2 ^ (point$intensity), 0),
                                   "<br/>"
                                 )
                               )))
                         }
                         
                         
                         
                         
                         
                       })
                     
                     # if(!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable)) {
                     #
                     #   RvarsPeakDetectionNewSample$samplesCuttingTable[input$sample_selectedCutting,]<-
                     #     c(isolate(input$rt_min_cut),isolate(input$rt_max_cut), isolate(input$UnitTime_sampleCutting))
                     # }
                     
                     
                     
                   } else if (!is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                   ) &
                   is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                   )) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot_newSample <-
                       renderPlot({
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           shinyjs::show("UnitTime_sampleCutting_id_newSample")
                           shinyjs::show("mousepositionSampleCutting_newSample")
                           
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = 0,
                               xmax = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                               ),
                               ymin = -Inf ,
                               ymax = Inf,
                               alpha = 0.5,
                               fill = "gray"
                             ) +
                             scale_color_viridis_c(option = "inferno", direction = -1) +
                             ylab("Mass (M+H) (Da)") +
                             xlab(paste(
                               "CE-time (",
                               req(input$UnitTime_sampleCutting_newSample),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                             ylim = rangesZoomSample_selectedCutting_newSample$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               req(input$sample_selectedCutting_newSample),
                               "\n"
                             )) +
                             
                             scale_x_continuous(n.breaks = 14) +
                             #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
                             #facet_grid(vars(sample), vars())+
                             #option_graphe.3
                             theme_ben() +
                             labs(colour = "log2 Intensity") +
                             theme(
                               plot.title = element_text(
                                 size = rel(0.9),
                                 face = "bold",
                                 color = "#760001",
                                 margin = margin(0, 0, 5, 0),
                                 hjust = 0.5
                               ),
                               plot.subtitle = element_text(hjust = 0.5)
                             )
                           
                         }
                         
                         
                         
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info_newSample <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover_newSample,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click_newSample,
                             "CE-time",
                             "M+H"
                           )
                         )
                         # paste0("Mouse position : ",
                         #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                         #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                       })
                     ## Bulle info
                     
                     #### info-bulle
                     output$sample_selectedCutting_hover_info_newSample <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover_newSample)
                         
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           point <-
                             nearPoints(
                               req(
                                 RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                               ),
                               hover,
                               threshold = 5,
                               maxpoints = 1,
                               addDist = TRUE
                             )
                           if (nrow(point) == 0)
                             return(NULL)
                           
                           # calculate point position INSIDE the image as percent of total dimensions
                           # from left (horizontal) and from top (vertical)
                           left_pct <-
                             (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                           top_pct <-
                             (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
                           # calculate distance from left and bottom side of the picture in pixels
                           left_px <-
                             hover$range$left + left_pct * (hover$range$right - hover$range$left)
                           top_px <-
                             hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
                           # create style property fot tooltip
                           # background color is set so tooltip is a bit transparent
                           # z-index is set so we are sure are tooltip will be on top
                           style <-
                             paste0(
                               "position:absolute; z-index:100; background-color: #760001; color: white;",
                               "left:",
                               left_px + 2,
                               "px; top:",
                               top_px + 2,
                               "px;"
                             )
                           
                           # actual tooltip created as wellPanel
                           div(class = "well well-sm",
                               style = style,
                               p(HTML(
                                 paste0(
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
                                   "<br/>",
                                   "<span class='bullText'> M+H: </span>",
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> log2 Intensity: </span>",
                                   round(point$intensity, 2),
                                   "<br/>",
                                   "<span class='bullText'> Intensity: </span>",
                                   round(2 ^ (point$intensity), 0),
                                   "<br/>"
                                 )
                               )))
                         }
                         
                         
                         
                         
                         
                       })
                     
                     # if(!is.null(RvarsPeakDetectionNewSample$samplesCuttingTable)) {
                     #
                     #   RvarsPeakDetectionNewSample$samplesCuttingTable[input$sample_selectedCutting,]<-
                     #     c(isolate(input$rt_min_cut),isolate(input$rt_max_cut), isolate(input$UnitTime_sampleCutting))
                     # }
                     
                     
                     
                   } else if (is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_min_cut_newSample
                   ) &
                   !is.na(
                     RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                   )) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot_newSample <-
                       renderPlot({
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           shinyjs::show("UnitTime_sampleCutting_id_newSample")
                           shinyjs::show("mousepositionSampleCutting_newSample")
                           
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = as.numeric(
                                 RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[req(input$sample_selectedCutting_newSample), ]$rt_max_cut_newSample
                               ),
                               xmax = Inf,
                               ymin = -Inf ,
                               ymax = Inf,
                               alpha = 0.5,
                               fill = "gray"
                             ) +
                             scale_color_viridis_c(option = "inferno", direction = -1) +
                             ylab("Mass (M+H) (Da)") +
                             xlab(paste(
                               "CE-time (",
                               req(input$UnitTime_sampleCutting_newSample),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting_newSample$x,
                                             ylim = rangesZoomSample_selectedCutting_newSample$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               req(input$sample_selectedCutting_newSample),
                               "\n"
                             )) +
                             
                             scale_x_continuous(n.breaks = 14) +
                             #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
                             
                             
                             #facet_grid(vars(sample), vars())+
                             #option_graphe.3
                             theme_ben() +
                             labs(colour = "log2 Intensity") +
                             theme(
                               plot.title = element_text(
                                 size = rel(0.9),
                                 face = "bold",
                                 color = "#760001",
                                 margin = margin(0, 0, 5, 0),
                                 hjust = 0.5
                               ),
                               plot.subtitle = element_text(hjust = 0.5)
                             )
                           
                         }
                         
                         
                         
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info_newSample <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover_newSample,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click_newSample,
                             "CE-time",
                             "M+H"
                           )
                         )
                         # paste0("Mouse position : ",
                         #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                         #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                       })
                     ## Bulle info
                     
                     #### info-bulle
                     output$sample_selectedCutting_hover_info_newSample <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover_newSample)
                         
                         if (!is.null(
                           RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                         )) {
                           point <-
                             suppressWarnings(
                               nearPoints(
                                 req(
                                   RvarsPeakDetectionNewSample$sample_cutting_viewer_ConvertTime_newSample
                                 )
                               ),
                               hover,
                               threshold = 5,
                               maxpoints = 1,
                               addDist = TRUE
                             )
                           if (nrow(point) == 0)
                             return(NULL)
                           
                           # calculate point position INSIDE the image as percent of total dimensions
                           # from left (horizontal) and from top (vertical)
                           left_pct <-
                             (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                           top_pct <-
                             (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                           
                           # calculate distance from left and bottom side of the picture in pixels
                           left_px <-
                             hover$range$left + left_pct * (hover$range$right - hover$range$left)
                           top_px <-
                             hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                           
                           # create style property fot tooltip
                           # background color is set so tooltip is a bit transparent
                           # z-index is set so we are sure are tooltip will be on top
                           style <-
                             paste0(
                               "position:absolute; z-index:100; background-color: #760001; color: white;",
                               "left:",
                               left_px + 2,
                               "px; top:",
                               top_px + 2,
                               "px;"
                             )
                           
                           # actual tooltip created as wellPanel
                           div(class = "well well-sm",
                               style = style,
                               p(HTML(
                                 paste0(
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
                                   "<br/>",
                                   "<span class='bullText'> M+H: </span>",
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> log2 Intensity: </span>",
                                   round(point$intensity, 2),
                                   "<br/>",
                                   "<span class='bullText'> Intensity: </span>",
                                   round(2 ^ (point$intensity), 0),
                                   "<br/>"
                                 )
                               )))
                         }
                         
                         
                         
                         
                         
                       })
                     
                     
                     
                   }
                   
                 }
               } else {
                 output$sample_selectedCutting_Plot_newSample <- renderPlot({
                   
                 })
                 output$sample_selectedCutting_Plot_info_newSample <-
                   renderText({
                     
                   })
                 output$sample_selectedCutting_hover_info_newSample <-
                   renderUI({
                     
                   })
                 hide("UnitTime_sampleCutting_id_newSample")
               }
               
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Save samples cutting ~~~~~~~~~~~~~~~~~~~~~~~~#*
peaks_mono_iso_sample_selectedCutting_newSample <- reactive({
  if (!is.null(names(
    RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
  ))) {
    table_to_save <-
      RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
    
    for (i in rownames(RvarsPeakDetectionNewSample$samplesCuttingTable_newSample)) {
      if (RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, "Unit"] ==
          "Second") {
        if (!is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        !is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
                rt,
              rt < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
            )
        } else if (!is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
                rt
            )
        } else if (is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        !is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              rt < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
            )
        } else if (is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]]
        }
      } else if (RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, "Unit"] ==
                 "Minute") {
        if (!is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        !is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
                rt / 60,
              rt / 60 < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
            )
        } else if (!is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample <
                rt / 60
            )
        } else if (is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        !is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]] %>%
            dplyr::filter(
              rt / 60 < RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
            )
        } else if (is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_min_cut_newSample
        ) &
        is.na(
          RvarsPeakDetectionNewSample$samplesCuttingTable_newSample[i, ]$rt_max_cut_newSample
        )) {
          table_to_save[[i]] <-
            RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample[[i]]
        }
      }
      
      
    }
    
    table_to_save
    
    
  }
  
})



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button server for cutting new samples ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$validCuttingRun_newSample
             },
             handlerExpr = {
               ask_confirmation(
                 inputId = "validCuttingRun_confirmation_newSample",
                 title = NULL,
                 text = tags$b(
                   #icon("info"),
                   paste0(
                     "Are you sure you’re done cutting all your samples?",
                     "\n",
                     "Once you click OK, you may resume all if you want to go back."
                   ),
                   style = "color: #FA5858;"
                 ),
                 btn_labels = c("Cancel", "OK"),
                 btn_colors = c("#00BFFF", "#FE2E2E"),
                 html = TRUE
               )
               
               
             })

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ResetCuttingRun_newSample
             },
             handlerExpr = {
               ask_confirmation(
                 inputId = "ResetCuttingRun_confirmation_newSample",
                 title = NULL,
                 text = tags$b(#icon("info"),
                   "Do you really want to resume the cutting of all samples ?",
                   style = "color: #FA5858;"),
                 btn_labels = c("Cancel", "OK"),
                 btn_colors = c("#00BFFF", "#FE2E2E"),
                 html = TRUE
               )
               
               
             })



observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$validCuttingRun_confirmation_newSample
             },
             handlerExpr = {
               if (input$validCuttingRun_confirmation_newSample == TRUE) {
                 disable("RetentionTimeFiltering_id_newSample")
                 shinyjs::show("id_ResetCuttingRun_newSample")
                 enable("SaveCuttingSample_newSample")
                 hide("id_validCuttingRun_newSample")
                 enable("GoToPeakView_newSample")
                 enable("id_SelectRefrenceSamplePanel_newSample")
                 
               }
             })



observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ResetCuttingRun_confirmation_newSample
             },
             handlerExpr = {
               if (input$ResetCuttingRun_confirmation_newSample == TRUE) {
                 enable("RetentionTimeFiltering_id_newSample")
                 hide("id_ResetCuttingRun_newSample")
                 shinyjs::show("id_validCuttingRun_newSample")
                 disable("SaveCuttingSample_newSample")
                 shinyjs::reset("rt_min_cut_newSample")
                 shinyjs::reset("rt_max_cut_newSample")
                 disable("GoToPeakView_newSample")
                 disable("id_SelectRefrenceSamplePanel_newSample")
                 
                 
                 if (!is.null(names(
                   RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
                 ))) {
                   RvarsPeakDetectionNewSample$samplesCuttingTable_newSample <-
                     data.frame(
                       row.names = names(
                         RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
                       ),
                       rt_min_cut_newSample = rep(
                         NA,
                         length(
                           RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
                         )
                       ),
                       rt_max_cut_newSample = rep(
                         NA,
                         length(
                           RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
                         )
                       ),
                       Unit = rep(
                         "Second",
                         length(
                           RvarsPeakDetectionNewSample$peaks_mono_iso_Cutt_newSample
                         )
                       )
                     )
                 }
                 
                 updateAwesomeRadio(session = session,
                                    inputId = "UnitTime_sampleCutting_newSample",
                                    selected = "Second")
                 RvarsPeakDetectionNewSample$Second <- TRUE
               }
             })




##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~ Correction time to the reference map  ~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~ Correction time with kernel Density ~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~ update input 'SelectSample_KernelDensity_newSample' ~~~~~~~~~#

observe({
  if (!is.null(peaks_mono_iso_sample_selectedCutting_newSample())) {
    sample_name <-
      names(peaks_mono_iso_sample_selectedCutting_newSample())
    
    RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
      peaks_mono_iso_sample_selectedCutting_newSample()
    
    peaks <-
      RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list
    RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection <-
      peaks
    
    updatePickerInput(session = session,
                      inputId = "SelectSample_KernelDensity_newSample",
                      choices = sample_name)
    
    
    
  } else {
    RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
      peaks_mono_iso_sample_selectedCutting_newSample()
    
    peaks <-
      RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list
    RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection <-
      peaks
    
    updatePickerInput(
      session = session,
      inputId = "SelectSample_KernelDensity_newSample",
      choices = character(0),
      selected = character(0)
    )
    
    
  }
})


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~ Forced reactive Kernel density filter when choosing samples when cutting sample~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               c(input$cutOff_newSample)
             },
             handlerExpr = {
               if (!is.null(peaks_mono_iso_sample_selectedCutting_newSample())) {
                 sample_name <-
                   names(peaks_mono_iso_sample_selectedCutting_newSample())
                 
                 RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list <-
                   peaks_mono_iso_sample_selectedCutting_newSample()
                 
                 updatePickerInput(
                   session = session,
                   inputId = "SelectSample_KernelDensity_newSample",
                   choices = character(0),
                   selected = character(0)
                 )
                 
                 updatePickerInput(session = session,
                                   inputId = "SelectSample_KernelDensity_newSample",
                                   choices = sample_name)
               }
               
             })

## View data
# observe({
#   if(!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)){
#     View(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)
#   }
# })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~ Kernel density filter when choosing samples ~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SelectSample_KernelDensity_newSample
             },
             handlerExpr = {
               if (!is.null(input$SelectSample_KernelDensity_newSample) &
                   !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
                   !is.null(RvarsPeakDetectionNewSample$map_ref)) {
                 ##Matched samples
                 
                 source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                        local = TRUE)
                 
                 ref <- RvarsPeakDetectionNewSample$map_ref[2:4]
                 colnames(ref) <- c("mz", "rt", "maxo")
                 
                 ref$maxo <- 2 ^ (ref$maxo)
                 
                 table.newSample <-
                   RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]
                 table.newSample <-
                   table.newSample[, c("mz", "rt", "maxo", "sample")]
                 
                 resMatch.newSample <- matchMz(
                   x = ref,
                   table = table.newSample,
                   ppm_tolereance = 1000,
                   mzcol = "mz",
                   rtcol = "rt" ,
                   session = session
                 )
                 
                 
                 
                 RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter <-
                   resMatch.newSample$MatchTable[!is.na(resMatch.newSample$MatchTable$rt.2),
                                                 c("mz.1",
                                                   "rt.1",
                                                   "maxo.1",
                                                   "mz.2",
                                                   "rt.2",
                                                   "rt.2",
                                                   "maxo.2",
                                                   "sample.2")]
                 
                 ##Log2 intensity sample to align
                 RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$maxo.2 <-
                   log2(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$maxo.2)
                 
                 
                 
                 ## Filter intensity
                 observe({
                   if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter)) {
                     RvarsPeakDetectionNewSample$Data_Plot.newSample <-
                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter %>%
                       dplyr::filter(maxo.2 >= req(input$intensityFilter_newSample))
                   }
                 })
                 
                 ## Median line
                 if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
                   median_line.newSample <-
                     seq(min(
                       range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2)[1],
                       range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1)[1]
                     ),
                     max(
                       range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2)[2],
                       range(RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1)[2]
                     ), by = 50)
                   
                   median_line_data.newSample <-
                     data.frame(x =  median_line.newSample,
                                y  =  median_line.newSample)
                 }
                 
                 
                 ####~~~~~~~~~~~~~~~~ Correction with Kernel Density ~~~~~~~~~~~~~~~~~~~~###
                 
                 #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
                 data_dens_filter.newSample <-
                   reactive(if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample) &
                                nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample) !=
                                0) {
                     dens <-
                       kde2d(
                         RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2,
                         RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1,
                         h = input$bandwidth_Filter_newSample,
                         n = input$gridSize_newSample
                       )
                     nx <-
                       nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)
                     df <- expand.grid(x = dens$x, y = dens$y)
                     df$density <- (as.vector(dens$z))
                     df$density <- df$density / max(df$density)
                     #df$group <- data$group[1]
                     df$ndensity <-
                       df$density / max(df$density, na.rm = TRUE)
                     df$count <- nx * df$density
                     df$n <- nx
                     df$level <- 1
                     df$piece <- 1
                     df_filter <- df %>%
                       dplyr::filter(density >= req(input$minDensity_newSample))
                     
                     colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                     
                     df_filter
                   })
                 
                 
                 #~~~~~~~~~~~~~~~~~~~~~~~~ Plot filter density ~~~~~~~~~~~~~~~~~~~~~~~#
                 output$DensityFilterPlot_newSample <- renderPlot({
                   if (length(data_dens_filter.newSample()) != 0) {
                     if (!is.null(data_dens_filter.newSample()) &
                         nrow(data_dens_filter.newSample()) != 0 &
                         nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample) !=
                         0) {
                       p1 <- RvarsPeakDetectionNewSample$Data_Plot.newSample %>%
                         ggplot() +
                         aes(x = rt.2, y = rt.1) + 
                         geom_point(aes(color = maxo.2), size = 0.8) +
                         # scale_color_viridis_c(option = "H", direction = -1) +
                         scale_colour_continuous(
                           palette = c("#ffce4d","red","#9E0B0B", "#450A0A" )
                         )+
                         geom_density_2d(
                           h = input$bandwidth_Filter_newSample,
                           n = input$gridSize_newSample
                         ) +
                         #scale_color_viridis_c(option = "inferno", direction = -1) +
                         scale_x_continuous(n.breaks = 14) +
                         scale_y_continuous(n.breaks = 14) +
                         
                         coord_cartesian(xlim = c(min(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[1],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[1]
                         ),
                         max(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[2],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[2]
                         )),
                         
                         ylim = c(min(
                               range(
                                 RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                               )[1],
                               range(
                                 RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                               )[1]
                         ),
                         min(
                             range(
                               RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                             )[2],
                             range(
                               RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                             )[2]
                         )+100)) +
                         
                         
                         xlab(
                           paste(
                             "CE-time (",
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$sample.2,
                             ")"
                           )
                         ) +
                         ylab("CE-time (reference sample)") +
                         #labs(colour ="log2 Intensity")+
                         theme_ben() +
                         labs(colour = "log2 Intensity") 
                       
                       p2 <-
                         ggplot(data_dens_filter.newSample(), aes(x = rt.2, y = rt.1)) +
                         geom_point(aes(color = density), size = 0.5) +
                         
                         scale_x_continuous(n.breaks = 14) +
                         scale_y_continuous(n.breaks = 14) +
                         scale_color_gradientn(
                           name = "Density",
                           colours = c("#2487FF",
                                       "#4FE8FF",
                                       "#A8FFFF",
                                       "#FFE600",
                                       "#FFB300",
                                       "#FF7A00",
                                       "#FF4500",
                                       "#FF1A00"),
                           breaks = seq(round(min(data_dens_filter.newSample()$density), 2), 
                                        round(max(data_dens_filter.newSample()$density), 2), by = 0.1),
                           limits = c(0, 1)
                         )+
                         
                         # coord_cartesian(xlim = c(min(
                         #   range(data_dens_filter.newSample()$rt.2)[1],
                         #   range(data_dens_filter.newSample()$rt.1)[1]
                         # ),
                         # max(
                         #   range(data_dens_filter.newSample()$rt.2)[2],
                         #   range(data_dens_filter.newSample()$rt.1)[2]
                         # )),
                         # 
                         # ylim = c(min(
                         #   range(data_dens_filter.newSample()$rt.2)[1],
                         #   range(data_dens_filter.newSample()$rt.1)[1]
                         # ),
                         # max(
                         #   range(data_dens_filter.newSample()$rt.2)[2],
                         #   range(data_dens_filter.newSample()$rt.1)[2]
                         # ))) +
                         # 
                         coord_cartesian(xlim = c(min(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[1],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[1]
                         ),
                         max(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[2],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[2]
                         )),
                         
                         ylim = c(min(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[1],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[1]
                         ),
                         min(
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2
                           )[2],
                           range(
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1
                           )[2]
                         )+100)) +
                         xlab(
                           paste(
                             "CE-time (",
                             RvarsPeakDetectionNewSample$Data_Plot.newSample$sample.2,
                             ")"
                           )
                         ) +
                         ylab("CE-time (Reference map)") +
                         
                         theme_ben() +
                         theme(
                           legend.title = element_text(
                             size = rel(0.85),
                             face = "bold.italic",
                             hjust = 0.5
                           ),
                           legend.text = element_text(size = rel(0.70), face = "bold.italic"), 
                           legend.key.height = unit(1.2, "cm"),
                           legend.key.width = unit(0.7, "cm")
                         )
                       
                       #grid.arrange(p1, p2, nrow = 2)
                       g1 <- ggplotGrob(p1)
                       g2 <- ggplotGrob(p2)
                       maxWidth <- grid::unit.pmax(g1$widths, g2$widths)
                       g1$widths <- maxWidth
                       g2$widths <- maxWidth
                       grid.arrange(g1, g2, nrow = 2)
                       
                     }
                     
                   }
                   
                 })
                 
               }
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~ Fit model kernel density estimation ~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$fitModel_newSample
             },
             handlerExpr = {
               
               if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
                 
                 if(nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)!=0){
                   #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
                   data_dens_filter.newSample <-
                     reactive(if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample)) {
                       dens <-
                         kde2d(
                           RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.2,
                           RvarsPeakDetectionNewSample$Data_Plot.newSample$rt.1,
                           h = input$bandwidth_Filter_newSample,
                           n = input$gridSize_newSample
                         )
                       nx <-
                         nrow(RvarsPeakDetectionNewSample$Data_Plot.newSample)
                       df <- expand.grid(x = dens$x, y = dens$y)
                       df$density <- (as.vector(dens$z))
                       df$density <- df$density / max(df$density)
                       #df$group <- data$group[1]
                       df$ndensity <-
                         df$density / max(df$density, na.rm = TRUE)
                       df$count <- nx * df$density
                       df$n <- nx
                       df$level <- 1
                       df$piece <- 1
                       df_filter <- df %>%
                         dplyr::filter(density >= req(input$minDensity_newSample))
                       
                       colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                       
                       df_filter
                     })
                   
                   ##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Fit model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   if (length(data_dens_filter.newSample()) != 0) {
                     if (!is.null(data_dens_filter.newSample())) {
                       dataDensity <- isolate(data_dens_filter.newSample())
                       
                       if (!is.null(dataDensity)) {
                         withProgress(message = 'Fit model...', value = 0, {
                           incProgress(1 / 3, detail = "")
                           
                           #~~~~~~~~~~~~~~~~~ Kernel density estimation ~~~~~~~~~~~~~~~~~~~~~~~#
                           RvarsPeakDetectionNewSample$modelKernelDensity <-
                             npreg(
                               rt.1 ~ rt.2,
                               bws = req(input$"bandwidth_Model_newSample"),
                               bwtype = c("fixed", "generalized_nn", "adaptive_nn")[1],
                               regtype = "ll",
                               ckertype = input$KernelType_newSample,
                               #bwmethod = "cv.aic",
                               gradients = TRUE,
                               data = dataDensity
                             )
                           
                           #~~~~~~~~~~~~~~~~~ Calculate prediction rt for sample selected ~~~~~~~~~~~~~~~~~~~~~~~#
                           if (!is.null(RvarsPeakDetectionNewSample$modelKernelDensity)) {
                             incProgress(1 / 3, detail = "")
                             
                             ### correction rt new sample Kernel Density
                             RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt <-
                               predict(
                                 RvarsPeakDetectionNewSample$modelKernelDensity,
                                 newdata = data.frame(rt.2 = RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]$rt)
                               )

                             ## Log parameters used for this sample
                             new_row <- data.frame(
                               Project          = isolate(RvarsPeakDetectionNewSample$Project_Name),
                               Reference_Run    = basename(isolate(RvarsPeakDetectionNewSample$run_ref_path)),
                               Sample           = input$SelectSample_KernelDensity_newSample,
                               Kernel_Type      = input$KernelType_newSample,
                               Bandwidth_Model  = input$bandwidth_Model_newSample,
                               Bandwidth_Filter = input$bandwidth_Filter_newSample,
                               Intensity_Filter = input$intensityFilter_newSample,
                               Min_Density      = input$minDensity_newSample,
                               stringsAsFactors = FALSE
                             )
                             existing_log <- isolate(RvarsPeakDetectionNewSample$kernelDensity_params_log)
                             if (is.null(existing_log)) {
                               RvarsPeakDetectionNewSample$kernelDensity_params_log <- new_row
                             } else {
                               existing_log <- existing_log[existing_log$Sample != input$SelectSample_KernelDensity_newSample, ]
                               RvarsPeakDetectionNewSample$kernelDensity_params_log <- rbind(existing_log, new_row)
                             }

                             ### Delete negative correction rt
                             
                             # RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt<-
                             #   RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]$rt %>% dplyr::filter(rt>0)
                             #
                             
                             
                             ## ~~~~~~~~~~~~~~~~~~ Plot correction rt with kernel Density ~~~~~~~~~~~~~#
                             
                             ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Before~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                             output$PlotCorrectionKernelDensity_Before_newSample <-
                               renderPlot({
                                 predict_data_model.np <-
                                   data.frame(
                                     rt.1 = predict(
                                       RvarsPeakDetectionNewSample$modelKernelDensity,
                                       newdata = data.frame(rt.2 = seq(
                                         min(
                                           range(
                                             RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                           )[1],
                                           range(
                                             RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                           )[1]
                                         ),
                                         max(
                                           range(
                                             RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                           )[2],
                                           range(
                                             RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                           )[2]
                                         )
                                       ), by = 50)
                                     ),
                                     rt.2 = seq(min(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[1],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[1]
                                     ),
                                     max(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[2],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[2]
                                     )),
                                     by = 50
                                   )
                                 
                                 median_line <-
                                   seq(min(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[1],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[1]
                                   ),
                                   max(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[2],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[2]
                                   ),
                                   by = 50)
                                 
                                 median_line_data <-
                                   data.frame(x =  median_line, y  =  median_line)
                                 
                                 ggplot(
                                   RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter,
                                   aes(x = rt.2, y = rt.1)
                                 ) +
                                   geom_point(size = 0.5) +
                                   
                                   coord_cartesian(xlim = c(min(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[1],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[1]
                                   ),
                                   max(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[2],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[2]
                                   )),
                                   ylim = c(min(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[1],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[1]
                                   ),
                                   max(
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                     )[2],
                                     range(
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                     )[2]
                                   ))) +
                                   
                                   scale_x_continuous(n.breaks = 14) +
                                   scale_y_continuous(n.breaks = 14) +
                                   
                                   # xlab("CE-time (sample to align)")+
                                   # ylab("CE-time (reference sample)")+
                                   
                                   geom_line(
                                     data = predict_data_model.np,
                                     aes(
                                       x = rt.2,
                                       y = rt.1,
                                       color = "Model"
                                     ),
                                     lwd = 1,
                                     size = 1.5
                                   ) +
                                   #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
                                   # geom_abline(yintercept = 0, lwd = 1, color = "green")+
                                   geom_line(
                                     data = median_line_data,
                                     aes(
                                       x = x,
                                       y = x,
                                       color = "Median"
                                     ),
                                     lwd = 1,
                                     size = 1.5
                                   ) +
                                   ggtitle("Before CE-time correction") +
                                   
                                   labs(
                                     x = paste(
                                       "CE-time (",
                                       RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$sample.2,
                                       ")"
                                     ),
                                     y = "CE-time (Reference map)",
                                     color = "Legend"
                                   ) +
                                   
                                   scale_color_manual(values = c(
                                     "Model" = "red",
                                     "Median" = "green"
                                   )) +
                                   
                                   
                                   theme_ben() +
                                   theme(
                                     plot.title = element_text(
                                       size = rel(1),
                                       face = "bold",
                                       color = "#760001",
                                       margin = margin(0, 0, 5, 0),
                                       hjust = 0.5
                                     ),
                                     plot.subtitle = element_text(hjust = 0.5),
                                     plot.background = element_rect(fill = "aliceblue"),
                                     legend.title = element_text(
                                       size = rel(0.95),
                                       face = "bold.italic",
                                       hjust = 0.5
                                     ),
                                     legend.text = element_text(size = rel(0.85), face = "bold.italic")
                                   )
                                 
                               })
                             
                             #### info-bulle
                             output$PlotCorrectionKernelDensity_Before_hover_info_newSample <-
                               renderUI({
                                 hover <-
                                   req(input$PlotCorrectionKernelDensity_Before_hover_newSample)
                                 
                                 if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter)) {
                                   point <-
                                     nearPoints(
                                       req(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter
                                       ),
                                       hover,
                                       threshold = 5,
                                       maxpoints = 1,
                                       addDist = TRUE
                                     )
                                   if (nrow(point) == 0)
                                     return(NULL)
                                   
                                   # calculate point position INSIDE the image as percent of total dimensions
                                   # from left (horizontal) and from top (vertical)
                                   left_pct <-
                                     (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                                   top_pct <-
                                     (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                                   
                                   # calculate distance from left and bottom side of the picture in pixels
                                   left_px <-
                                     hover$range$left + left_pct * (hover$range$right - hover$range$left)
                                   top_px <-
                                     hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                                   
                                   # create style property fot tooltip
                                   # background color is set so tooltip is a bit transparent
                                   # z-index is set so we are sure are tooltip will be on top
                                   style <-
                                     paste0(
                                       "position:absolute; z-index:100; background-color: #760001; color: white;",
                                       "left:",
                                       left_px + 2,
                                       "px; top:",
                                       top_px + 2,
                                       "px;"
                                     )
                                   
                                   # actual tooltip created as wellPanel
                                   div(class = "well well-sm",
                                       style = style,
                                       p(HTML(
                                         paste0(
                                           "<span class='bullText'> M+H (ref): </span>",
                                           round(point$mz.1, 4),
                                           "<br/>",
                                           "<span class='bullText'> CE-time (ref): </span>",
                                           round(point$rt.1, 2),
                                           "<br/>",
                                           "<span class='bullText'> Intensity (ref): </span>",
                                           round(point$maxo.1, 0),
                                           "<br/>",
                                           "<br>",
                                           "<span class='bullText'> M+H (sample): </span>",
                                           round(point$mz.2, 4),
                                           "<br/>",
                                           "<span class='bullText'> CE-time (sample): </span>",
                                           round(point$rt.2, 2),
                                           "<br/>",
                                           "<span class='bullText'> Intensity (sample): </span>",
                                           round(2 ^ (point$maxo.2), 0),
                                           "<br/>"
                                         )
                                       )))
                                 }
                                 
                               })
                             
                             incProgress(1 / 3, detail = "")
                             ####~~~~~~~~~~~~~~~~~~~~ Plot After ~~~~~~~~~~~~~~~~~~~~~~~~#
                             ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                             output$PlotCorrectionKernelDensity_After_newSample <-
                               renderPlot({
                                 if (!is.null(input$SelectSample_KernelDensity_newSample) &
                                     !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
                                     !is.null(RvarsPeakDetectionNewSample$map_ref) &
                                     !is.null(
                                       RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
                                     )) {
                                   source(
                                     "lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                                     local = TRUE
                                   )
                                   
                                   ref <-
                                     RvarsPeakDetectionNewSample$map_ref[2:4]
                                   colnames(ref) <-
                                     c("mz", "rt", "maxo")
                                   
                                   ref$maxo <- 2 ^ (ref$maxo)
                                   
                                   table.after <-
                                     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]
                                   
                                   table.after <-
                                     table.after[, c("mz", "rt", "maxo", "sample")]
                                   
                                   
                                   resMatch.after <- matchMz(
                                     x = ref,
                                     table = table.after,
                                     ppm_tolereance = 1000,
                                     mzcol = "mz",
                                     rtcol = "rt" ,
                                     session = session
                                   )
                                   
                                   Data_Plot.after <-
                                     resMatch.after$MatchTable[!is.na(resMatch.after$MatchTable$rt.2),
                                                               c(
                                                                 "mz.1",
                                                                 "rt.1",
                                                                 "maxo.1",
                                                                 "mz.2",
                                                                 "rt.2",
                                                                 "rt.2",
                                                                 "maxo.2",
                                                                 "sample.2"
                                                               )]
                                   
                                   RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity <-
                                     Data_Plot.after
                                   
                                   median_line.after <-
                                     seq(min(
                                       range(Data_Plot.after$rt.2)[1],
                                       range(Data_Plot.after$rt.1)[1]
                                     ),
                                     max(
                                       range(Data_Plot.after$rt.2)[2],
                                       range(Data_Plot.after$rt.1)[2]
                                     ),
                                     by = 50)
                                   
                                   median_line_data.after <-
                                     data.frame(x =  median_line.after,
                                                y  =  median_line.after)
                                   
                                   
                                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot after Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   Plot.after <-
                                     ggplot(Data_Plot.after, aes(x = rt.2, y = rt.1)) +
                                     geom_point(size = 0.5) +
                                     
                                     # coord_cartesian(xlim = c(
                                     #   min(
                                     #     range(Data_Plot.after$rt.2)[1],
                                     #     range(Data_Plot.after$rt.1)[1]
                                     #   ),
                                     #   max(
                                     #     range(Data_Plot.after$rt.2)[2],
                                     #     range(Data_Plot.after$rt.1)[2]
                                     #   )
                                     # ),
                                     # ylim = c(
                                     #   min(
                                     #     range(Data_Plot.after$rt.2)[1],
                                     #     range(Data_Plot.after$rt.1)[1]
                                     #   ),
                                     #   max(
                                     #     range(Data_Plot.after$rt.2)[2],
                                     #     range(Data_Plot.after$rt.1)[2]
                                     #   )
                                     # )) +
                                     
                                     
                                     coord_cartesian(xlim = c(min(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[1],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[1]
                                     ),
                                     max(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[2],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[2]
                                     )),
                                     ylim = c(min(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[1],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[1]
                                     ),
                                     max(
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.2
                                       )[2],
                                       range(
                                         RvarsPeakDetectionNewSample$Data_Plot.newSample_to_filter$rt.1
                                       )[2]
                                     ))) +
                                     
                                     
                                     
                                     scale_x_continuous(n.breaks = 14) +
                                     scale_y_continuous(n.breaks = 14) +
                                     
                                     # xlab("CE-time (sample to align)")+
                                     # ylab("CE-time (reference sample)")+
                                     
                                     # geom_line(data = predict_data_model.np, aes(x = rt2, y = rt1, color = "Model"), lwd = 1, size = 1.5) +
                                     # #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
                                     # # geom_abline(yintercept = 0, lwd = 1, color = "green")+
                                     
                                     geom_line(
                                       data = median_line_data.after,
                                       aes(
                                         x = x,
                                         y = x,
                                         color = "Median"
                                       ),
                                       lwd = 1,
                                       size = 1.5
                                     ) +
                                     
                                     labs(
                                       x = paste("CE-time (", Data_Plot.after$sample.2, ")"),
                                       y = "CE-time (Reference map)",
                                       color = "Legend"
                                     ) +
                                     ggtitle("Correction with Kernel Density") +
                                     
                                     scale_color_manual(values = c("Median" = "green")) +
                                     
                                     
                                     theme_ben() +
                                     theme(
                                       plot.title = element_text(
                                         size = rel(1),
                                         face = "bold",
                                         color = "#760001",
                                         margin = margin(0, 0, 5, 0),
                                         hjust = 0.5
                                       ),
                                       plot.subtitle = element_text(hjust = 0.5),
                                       plot.background = element_rect(fill = "aliceblue"),
                                       legend.title = element_text(
                                         size = rel(0.95),
                                         face = "bold.italic",
                                         hjust = 0.5
                                       ),
                                       legend.text = element_text(size = rel(0.85), face = "bold.italic")
                                     )
                                   
                                   Plot.after
                                 }
                                 
                               })
                             
                             #### info-bulle
                             output$PlotCorrectionKernelDensity_After_hover_info_newSample <-
                               renderUI({
                                 hover <-
                                   req(input$PlotCorrectionKernelDensity_After_hover_newSample)
                                 
                                 if (!is.null(RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity)) {
                                   point <-
                                     nearPoints(
                                       req(
                                         RvarsPeakDetectionNewSample$Data_Plot.after_KernelDensity
                                       ),
                                       hover,
                                       threshold = 5,
                                       maxpoints = 1,
                                       addDist = TRUE
                                     )
                                   if (nrow(point) == 0)
                                     return(NULL)
                                   
                                   # calculate point position INSIDE the image as percent of total dimensions
                                   # from left (horizontal) and from top (vertical)
                                   left_pct <-
                                     (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
                                   top_pct <-
                                     (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
                                   
                                   # calculate distance from left and bottom side of the picture in pixels
                                   left_px <-
                                     hover$range$left + left_pct * (hover$range$right - hover$range$left)
                                   top_px <-
                                     hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
                                   
                                   # create style property fot tooltip
                                   # background color is set so tooltip is a bit transparent
                                   # z-index is set so we are sure are tooltip will be on top
                                   style <-
                                     paste0(
                                       "position:absolute; z-index:100; background-color: #760001; color: white;",
                                       "left:",
                                       left_px + 2,
                                       "px; top:",
                                       top_px + 2,
                                       "px;"
                                     )
                                   
                                   # actual tooltip created as wellPanel
                                   div(class = "well well-sm",
                                       style = style,
                                       p(HTML(
                                         paste0(
                                           "<span class='bullText'> M+H (ref): </span>",
                                           round(point$mz.1, 4),
                                           "<br/>",
                                           "<span class='bullText'> CE-time (ref): </span>",
                                           round(point$rt.1, 2),
                                           "<br/>",
                                           "<span class='bullText'> Intensity (ref): </span>",
                                           round(point$maxo.1, 0),
                                           "<br/>",
                                           "<br>",
                                           "<span class='bullText'> M+H (sample): </span>",
                                           round(point$mz.2, 4),
                                           "<br/>",
                                           "<span class='bullText'> CE-time (sample): </span>",
                                           round(point$rt.2, 2),
                                           "<br/>",
                                           "<span class='bullText'> Intensity (sample): </span>",
                                           round(point$maxo.2, 0),
                                           "<br/>"
                                         )
                                       )))
                                 }
                                 
                               })
                             
                             #~~~~~~~~~ Plot mz (or M+H)~rt reference and mz(M+H)~rt sample (CE-time correction with xcms)~~~~~~~~~~~~~#
                             #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                             
                             output$CorrectimeKernelDensityViewer_2_newSample <-
                               renderPlot({
                                 if (!is.null(input$SelectSample_KernelDensity_newSample) &
                                     !is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) &
                                     !is.null(RvarsPeakDetectionNewSample$map_ref) &
                                     !is.null(
                                       RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
                                     )) {
                                   ref <- RvarsPeakDetectionNewSample$map_ref
                                   
                                   ref <-
                                     RvarsPeakDetectionNewSample$map_ref[2:4]
                                   
                                   ref$sample <- "Reference map"
                                   colnames(ref) <-
                                     c('mz', 'rt', 'maxo', 'sample')
                                   
                                   ref$maxo <- 2 ^ (ref$maxo)
                                   
                                   reqColstoPlot <-
                                     c('M+H', 'CE-time', 'intensity', 'sample')
                                   reqColsUsed <-
                                     c('mz', 'rt', 'maxo', 'sample')
                                   
                                   
                                   ##~~~~~~~~~~~~~~~~~~~~ After correction xcms ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   table.after <-
                                     RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[input$SelectSample_KernelDensity_newSample]]
                                   table.after <-
                                     table.after[, c("mz", "rt", "maxo", "sample")]
                                   
                                   Data_after <- rbind(table.after,
                                                       ref)
                                   rownames(Data_after) <-
                                     1:nrow(Data_after)
                                   colnames(Data_after)[which(colnames(Data_after) %in% reqColsUsed)] <-
                                     reqColstoPlot
                                   Data_after$intensity <-
                                     log2(Data_after$intensity)
                                   
                                   
                                   Data_after$sample <-
                                     factor(Data_after$sample,
                                            levels = c(
                                              unique(Data_after$sample)[unique(Data_after$sample) !=
                                                                          "Reference map"],
                                              "Reference map"
                                            ))
                                   
                                   Plot.After <- Data_after %>%
                                     ggplot() +
                                     aes(x = `CE-time`,
                                         y = `M+H`,
                                         colour = intensity) +
                                     #geom_point(shape = "circle", size = input$sizePoints) +
                                     geom_point(size = 0.5) +
                                     scale_color_viridis_c(option = "inferno", direction = -1) +
                                     theme_gray() +
                                     #facet_grid(vars(sample), vars())  +
                                     facet_wrap( ~ sample, dir = "v") +
                                     ylab("Mass (M+H) (Da)") +
                                     #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
                                     xlab(paste("CE-time")) +
                                     
                                     ggtitle("Before CE-time correction") +
                                     
                                     scale_x_continuous(n.breaks = 14) +
                                     scale_y_continuous(n.breaks = 5) +
                                     
                                     theme_ben() +
                                     labs(colour = "log2 Intensity") +
                                     theme(
                                       plot.title = element_text(
                                         size = rel(1),
                                         face = "bold",
                                         color = "#760001",
                                         margin = margin(0, 0, 5, 0),
                                         hjust = 0.5
                                       ),
                                       plot.subtitle = element_text(hjust = 0.5),
                                       panel.border = element_rect(
                                         fill = "transparent",
                                         # Needed to add the border
                                         color = "blue",
                                         linewidth = 0.5,
                                         linetype = "dashed"
                                       ),
                                       
                                       # Les étiquettes dans le cas d'un facetting
                                       strip.background = element_rect(
                                         fill = "grey",
                                         color = "grey"
                                       ),
                                       strip.text = element_text(
                                         size = rel(1),
                                         face = "bold.italic",
                                         color = "black",
                                         margin = margin(5, 0, 5, 0)
                                       ),
                                       plot.background = element_rect(fill = "aliceblue")
                                     )
                                   
                                   ##~~~~~~~~~~~~~~~~~~~~ After correction With Kernel Density ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   table.After_KernelDensity <-
                                     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[input$SelectSample_KernelDensity_newSample]]
                                   table.After_KernelDensity <-
                                     table.After_KernelDensity[, c("mz", "rt", "maxo", "sample")]
                                   
                                   Data_After_KernelDensity <-
                                     rbind(table.After_KernelDensity,
                                           ref)
                                   
                                   rownames(Data_After_KernelDensity) <-
                                     1:nrow(Data_After_KernelDensity)
                                   
                                   
                                   colnames(Data_After_KernelDensity)[which(colnames(Data_After_KernelDensity) %in% reqColsUsed)] <-
                                     reqColstoPlot
                                   Data_After_KernelDensity$intensity <-
                                     log2(Data_After_KernelDensity$intensity)
                                   
                                   
                                   Data_After_KernelDensity$sample <-
                                     factor(
                                       Data_After_KernelDensity$sample,
                                       levels = c(
                                         unique(Data_After_KernelDensity$sample)[unique(Data_After_KernelDensity$sample) !=
                                                                                   "Reference map"],
                                         "Reference map"
                                       )
                                     )
                                   
                                   
                                   
                                   Plot.After_KernelDensity <-
                                     Data_After_KernelDensity %>%
                                     ggplot() +
                                     aes(x = `CE-time`,
                                         y = `M+H`,
                                         colour = intensity) +
                                     #geom_point(shape = "circle", size = input$sizePoints) +
                                     geom_point(size = 0.5) +
                                     scale_color_viridis_c(option = "inferno", direction = -1) +
                                     theme_gray() +
                                     #facet_grid(vars(sample), vars())  +
                                     facet_wrap( ~ sample, dir = "v") +
                                     #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
                                     ylab("Mass (M+H) (Da)") +
                                     #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
                                     xlab(paste("CE-time")) +
                                     
                                     ggtitle("Correction with Kernel density") +
                                     
                                     scale_x_continuous(n.breaks = 14) +
                                     scale_y_continuous(n.breaks = 5) +
                                     
                                     theme_ben() +
                                     labs(colour = "log2 Intensity") +
                                     theme(
                                       plot.title = element_text(
                                         size = rel(1),
                                         face = "bold",
                                         color = "#760001",
                                         margin = margin(0, 0, 5, 0),
                                         hjust = 0.5
                                       ),
                                       plot.subtitle = element_text(hjust = 0.5),
                                       panel.border = element_rect(
                                         fill = "transparent",
                                         # Needed to add the border
                                         color = "blue",
                                         linewidth = 0.5,
                                         linetype = "dashed"
                                       ),
                                       
                                       # Les étiquettes dans le cas d'un facetting
                                       strip.background = element_rect(
                                         fill = "grey",
                                         color = "grey"
                                       ),
                                       strip.text = element_text(
                                         size = rel(1),
                                         face = "bold.italic",
                                         color = "black",
                                         margin = margin(5, 0, 5, 0)
                                       ),
                                       plot.background = element_rect(fill = "aliceblue")
                                     )
                                   
                                   
                                   
                                   
                                   
                                   grid.arrange(Plot.After,
                                                Plot.After_KernelDensity,
                                                nrow = 2)
                                   
                                 }
                                 
                               })
                             
                             
                             
                           }
                           
                           
                         })
                         
                       }
                     }
                     
                   }
                 }
                 
               }
               
               
               
             })

##~~~~ Re-predict RT when sample selection changes (no npreg re-fit) ~~~~##
observeEvent(input$SelectSample_KernelDensity_newSample, ignoreNULL = TRUE, {

  if (is.null(RvarsPeakDetectionNewSample$modelKernelDensity)) return()

  sample_sel <- input$SelectSample_KernelDensity_newSample

  if (is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[sample_sel]])) return()

  RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[sample_sel]]$rt <-
    predict(
      RvarsPeakDetectionNewSample$modelKernelDensity,
      newdata = data.frame(
        rt.2 = RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[sample_sel]]$rt
      )
    )
})

##
observe({
  if (is.null(RvarsPeakDetectionNewSample$modelKernelDensity)) {
    output$PlotCorrectionKernelDensity_Before_newSample <-
      renderPlot({
        
      })
    output$PlotCorrectionKernelDensity_After_newSample <-
      renderPlot({
        
      })
    output$CorrectimeKernelDensityViewer_2_newSample <- renderPlot({
      
    })
  }
  
  if (is.null(input$SelectSample_KernelDensity_newSample) ||
      is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) ||
      is.null(RvarsPeakDetectionNewSample$map_ref)) {
    output$DensityFilterPlot_newSample <- renderPlot({
      
    })
  }
})

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~ Modal: RT distribution viewer (eye button) ~~~~~~~~~~~~~~~~~~~~~~~~~~~##

output$modal_rt_dist_before_newSample <- renderPlot({
  sample_sel <- req(input$SelectSample_KernelDensity_newSample)
  req(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)
  req(RvarsPeakDetectionNewSample$map_ref)

  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R", local = TRUE)

  ref <- RvarsPeakDetectionNewSample$map_ref[2:4]
  colnames(ref) <- c("mz", "rt", "maxo")
  ref$maxo <- 2 ^ (ref$maxo)

  table.before <- RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list[[sample_sel]]
  table.before <- table.before[, c("mz", "rt", "maxo", "sample")]

  resMatch.before <- matchMz(x = ref, table = table.before,
                             ppm_tolereance = 1000, mzcol = "mz", rtcol = "rt",
                             session = session)

  data_before <- resMatch.before$MatchTable[
    !is.na(resMatch.before$MatchTable$rt.2),
    c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "maxo.2", "sample.2")
  ]

  rt_min <- min(range(data_before$rt.2)[1], range(data_before$rt.1)[1])
  rt_max <- max(range(data_before$rt.2)[2], range(data_before$rt.1)[2])

  median_line_data <- data.frame(x = seq(rt_min, rt_max, by = 50),
                                 y = seq(rt_min, rt_max, by = 50))

  ggplot(data_before, aes(x = rt.2, y = rt.1)) +
    geom_point(size = 0.5) +
    coord_cartesian(xlim = c(rt_min, rt_max), ylim = c(rt_min, rt_max)) +
    scale_x_continuous(n.breaks = 14) +
    scale_y_continuous(n.breaks = 14) +
    geom_line(data = median_line_data, aes(x = x, y = x, color = "Median"),
              lwd = 1, size = 1.5) +
    ggtitle("Before CE-time correction") +
    labs(x = paste("CE-time (", data_before$sample.2[1], ")"),
         y = "CE-time (Reference map)", color = "Legend") +
    scale_color_manual(values = c("Median" = "green")) +
    theme_ben() +
    theme(
      plot.title = element_text(size = rel(1), face = "bold", color = "#760001",
                                margin = margin(0, 0, 5, 0), hjust = 0.5),
      plot.background = element_rect(fill = "aliceblue"),
      legend.title = element_text(size = rel(0.95), face = "bold.italic", hjust = 0.5),
      legend.text = element_text(size = rel(0.85), face = "bold.italic")
    )
})

output$modal_rt_dist_after_newSample <- renderPlot({
  sample_sel <- req(input$SelectSample_KernelDensity_newSample)
  req(RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection)
  req(RvarsPeakDetectionNewSample$map_ref)

  source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R", local = TRUE)

  ref <- RvarsPeakDetectionNewSample$map_ref[2:4]
  colnames(ref) <- c("mz", "rt", "maxo")
  ref$maxo <- 2 ^ (ref$maxo)

  table.after <- RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection[[sample_sel]]
  table.after <- table.after[, c("mz", "rt", "maxo", "sample")]

  resMatch.after <- matchMz(x = ref, table = table.after,
                            ppm_tolereance = 1000, mzcol = "mz", rtcol = "rt",
                            session = session)

  data_after <- resMatch.after$MatchTable[
    !is.na(resMatch.after$MatchTable$rt.2),
    c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "maxo.2", "sample.2")
  ]

  rt_min <- min(range(data_after$rt.2)[1], range(data_after$rt.1)[1])
  rt_max <- max(range(data_after$rt.2)[2], range(data_after$rt.1)[2])

  median_line_data <- data.frame(x = seq(rt_min, rt_max, by = 50),
                                 y = seq(rt_min, rt_max, by = 50))

  ggplot(data_after, aes(x = rt.2, y = rt.1)) +
    geom_point(size = 0.5) +
    coord_cartesian(xlim = c(rt_min, rt_max), ylim = c(rt_min, rt_max)) +
    scale_x_continuous(n.breaks = 14) +
    scale_y_continuous(n.breaks = 14) +
    geom_line(data = median_line_data, aes(x = x, y = x, color = "Median"),
              lwd = 1, size = 1.5) +
    ggtitle("After CE-time correction (Kernel Density)") +
    labs(x = paste("CE-time (", data_after$sample.2[1], ")"),
         y = "CE-time (Reference map)", color = "Legend") +
    scale_color_manual(values = c("Median" = "green")) +
    theme_ben() +
    theme(
      plot.title = element_text(size = rel(1), face = "bold", color = "#760001",
                                margin = margin(0, 0, 5, 0), hjust = 0.5),
      plot.background = element_rect(fill = "aliceblue"),
      legend.title = element_text(size = rel(0.95), face = "bold.italic", hjust = 0.5),
      legend.text = element_text(size = rel(0.85), face = "bold.italic")
    )
})

observeEvent(input$btn_view_rt_dist_newSample, ignoreNULL = TRUE, {
  req(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)

  showModal(
    modalDialog(
      title = "RT distribution — CE-time Kernel Density correction",
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close"),
      fluidRow(
        column(
          6,
          shinycssloaders::withSpinner(
            plotOutput("modal_rt_dist_before_newSample",
                       width = "100%", height = "400px"),
            type = 1, size = 0.8
          )
        ),
        column(
          6,
          shinycssloaders::withSpinner(
            plotOutput("modal_rt_dist_after_newSample",
                       width = "100%", height = "400px"),
            type = 1, size = 0.8
          )
        )
      )
    )
  )
})

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~ Grouping massifs into features  ~~~~~~~~~~~~~~~~~~~~~###
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GroupingButtonIDNewSample
             }
             ,
             handlerExpr = {
               if (!is.null(RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection)) {
                 ## Load some functions:
                 source("lib/NewReferenceMap/R_files/GenerateMapRef.lib.R",
                        local = TRUE)
                 
                 withProgress(message = 'Grouping massif to features...', value = 0, {
                   ####~~~~~~~~~~~~~~~~~~~~~~ Grouping massif in samples  ~~~~~~~~~~~~~~~~~~~~#
                   ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   
                   incProgress(1 / 4, detail = "starting")
                   
                   ## Change names of columns
                   
                   Massif_List_ToGroup <-
                     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
                   
                   for (i in 1:length(Massif_List_ToGroup)) {
                     colSelect <-
                       c(
                         "M+H",
                         "M+H.min",
                         "M+H.max",
                         "rt",
                         "rtmin",
                         "rtmax",
                         "Area",
                         "Height",
                         "SN",
                         "sample",
                         "iso.mass",
                         "iso.mass.link",
                         "mz_PeaksIsotopics_Group",
                         "rt_PeaksIsotopics_Group",
                         "Height_PeaksIsotopics_Group",
                         "Adduct"
                       )
                     
                     colnames(Massif_List_ToGroup[[i]])[c(1:10)] <-
                       colSelect[c(1:10)]
                   }
                   
                   
                   
                   
                   workers <- ceiling((detectCores()) - 1)
                   param <-
                     SnowParam(workers = workers, type = "SOCK")
                   
                   
                   incProgress(1 / 4, detail = "first grouping")
                   res1 <- bplapply(
                     Massif_List_ToGroup,
                     Grouping.Massif_NewRefMap,
                     mz.tolerance = 0.15,
                     rt.tolerance = 30,
                     BPPARAM = param
                   )
                   
                   incProgress(1 / 4, detail = "second grouping")
                   res2 <- bplapply(
                     res1,
                     Grouping.Massif_NewRefMap_Second,
                     mz.tolerance = 0.09,
                     rt.tolerance = 180,
                     BPPARAM = param
                   )
                   
                   
                   ## Change colnames
                   
                   for (i in 1:length(res2)) {
                     colSelect <-
                       c(
                         "M+H",
                         "M+H.min",
                         "M+H.max",
                         "rt",
                         "rtmin",
                         "rtmax",
                         "Area",
                         "Height",
                         "SN",
                         "sample",
                         "iso.mass",
                         "iso.mass.link",
                         "mz_PeaksIsotopics_Group",
                         "rt_PeaksIsotopics_Group",
                         "Height_PeaksIsotopics_Group",
                         "Adduct"
                       )
                     
                     reqColsNames <-
                       c(
                         'M+H',
                         'M+H.min',
                         'M+H.max',
                         'CE-time',
                         'CE-time.min',
                         'CE-time.max',
                         'integrated-intensity',
                         'intensity',
                         'sn',
                         'sample'
                       )
                     
                     colnames(res2[[i]])[c(1:10)] <- reqColsNames
                     
                     res2[[i]] <- res2[[i]][, -ncol(res2[[i]])]
                   }
                   
                   
                   RvarsPeakDetectionNewSample$FeaturesList_newSample <-
                     res2
                   incProgress(1 / 4, detail = "finish")
                   
                   
                 })
                 
                 
                 #"~~~~~~~ Enable Generate reference map button ~~~~~~~~#
                 
                 enable("CorrectionKernelDensityNexPage_newSample")
                 
                 updateRadioButtons(session = session,
                                    inputId = "IdAnalysisStep",
                                    selected = "4")
                 
                 
                 sendSweetAlert(
                   session = session,
                   title = "Preprocess complete !",
                   text = HTML(paste(
                     "Grouping massif into feature well done !<br>"
                   )),
                   type = "success",
                   closeOnClickOutside = FALSE,
                   html = TRUE
                 )
                 
               }
               
               
             })



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~ Get features list and plot of table features ~~~~~~~~~~~~~~###
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


###~~~~ Get features list~~~~~~~~#
ms_features_newSample <- reactive({
  if ((length(RvarsPeakDetectionNewSample$FeaturesList_newSample) > 0)) {
    ms_featuresTable <-
      do.call(rbind,
              RvarsPeakDetectionNewSample$FeaturesList_newSample)
    
    rownames(ms_featuresTable) <- 1:nrow(ms_featuresTable)
    
    ms_featuresTable$intensity <- log2(ms_featuresTable$intensity)
    ms_featuresTable
  }
})



##~~~~ Update select input (select samples to viewer or to use)~~~~~~#
observe({
  if (!is.null(ms_features_newSample())) {
    RvarsPeakDetectionNewSample$sample_name_newSample <-
      unique(ms_features_newSample()$sample)
    
    updatePickerInput(
      session = session,
      inputId = "levelSample",
      choices = RvarsPeakDetectionNewSample$sample_name_newSample,
      selected = RvarsPeakDetectionNewSample$sample_name_newSample[1]
    )
    
    updatePickerInput(
      session = session,
      inputId = "IncludeSample",
      choices = RvarsPeakDetectionNewSample$sample_name_newSample,
      selected = RvarsPeakDetectionNewSample$sample_name_newSample
    )
    
    
  }
  
})

##~~~~~~~~~~~~~~~~~ Get data features to plot ~~~~~~~~~~~~~~#
ms_features_newSample_toPlot <- reactive({
  if (!is.null(ms_features_newSample()) &
      !is.null(input$levelSample)) {
    values_plot <-
      req(ms_features_newSample()[ms_features_newSample()$sample %in% input$levelSample, ])
    
    j <- 1
    for (names in unique(values_plot$sample)) {
      values_plot[values_plot$sample == names, "sample"] <- j
      j <- j + 1
    }
    
    values_plot
    
  }
  
})

###~~~~~~ CE-time Conversion ~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$levelSample
             },
             handlerExpr = {
               RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
                 isolate(req(ms_features_newSample_toPlot()))
               #Because les data viennent initialement en second
               RvarsPeakDetectionNewSample$Second <- TRUE
               if (input$UnitTime == "Minute") {
                 print(
                   paste(
                     "Convert to min",
                     input$UnitTime == "Minute" &
                       RvarsPeakDetectionNewSample$Second == TRUE
                   )
                 )
                 if (input$UnitTime == "Minute" &
                     RvarsPeakDetectionNewSample$Second == TRUE) {
                   if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
                     print("Yes!")
                     RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
                       req(
                         RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
                       ) / 60
                     RvarsPeakDetectionNewSample$Second <- FALSE
                   }
                 }
               }
               
               
             })

## When uploaded features list
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$features_list
             },
             handlerExpr = {
               ## Because data is initially in second
               
               updateRadioGroupButtons(session = session,
                                       inputId = "UnitTime",
                                       selected = "Second")
               RvarsPeakDetectionNewSample$Second == TRUE
               ## reset coord_cartesian
               rangesZoomAnalyisPlotSamplesSelected$x <- NULL
               rangesZoomAnalyisPlotSamplesSelected$y <- NULL
               
               
             })


##~~~~~~ CE-time conversion second or minute ~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$UnitTime
             },
             handlerExpr = {
               RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
                 req(ms_features_newSample_toPlot())
               print(
                 paste(
                   "Convert to min",
                   input$UnitTime == "Minute" &
                     RvarsPeakDetectionNewSample$Second == TRUE
                 )
               )
               if (input$UnitTime == "Minute" &
                   RvarsPeakDetectionNewSample$Second == TRUE) {
                 if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
                   RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
                     req(
                       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
                     ) / 60
                   RvarsPeakDetectionNewSample$Second <- FALSE
                 }
               }
               
               print(
                 paste(
                   "Covert to Second",
                   input$UnitTime == "Second" &
                     RvarsPeakDetectionNewSample$Second == FALSE
                 )
               )
               if (input$UnitTime == "Second" &
                   RvarsPeakDetectionNewSample$Second == FALSE) {
                 if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
                   RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time` <-
                     req(
                       RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$`CE-time`
                     ) * 60
                   RvarsPeakDetectionNewSample$Second <- TRUE
                 }
               }
               
               if (input$UnitTime == "Second" &
                   RvarsPeakDetectionNewSample$Second == TRUE) {
                 RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime <-
                   req(ms_features_newSample_toPlot())
               }
               
               
             })


##~~~~~~ Number of features ~~~~~~#
number_of_features <- reactive({
  if (length(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) >
      0 &
      !is.null(ms_features_newSample()) &
      !is.null(input$levelSample)) {
    table(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
    
  }
})

##~~~~~~~~~~~~ Legend for plot ~~~~~~~~~#
legend_sample <- reactive({
  if (length(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) >
      0 &
      !is.null(ms_features_newSample()) &
      !is.null(input$levelSample)) {
    legend_values <- data.frame(
      xd = 1:length(input$levelSample),
      yd = 1:length(input$levelSample),
      Samples = paste(
        "\n",
        1:length(input$levelSample),
        ": ",
        input$levelSample,
        "\n",
        sep = ""
      )
    )
    legend_values
  }
  
})


##~~~~~~~Zoom: features list viewer ~~~~~~~~#
rangesZoomAnalyisPlotSamplesSelected <-
  reactiveValues(x = NULL, y = NULL)

# When a double-click happens, check if there's a brush on the plot.
# If so, zoom to the brush bounds; if not, reset the zoom.
observeEvent({
  input$plotAnalysisNewSample_dblclick
}, {
  brush <- input$plotAnalysisNewSample_brush
  if (!is.null(brush)) {
    rangesZoomAnalyisPlotSamplesSelected$x <- c(brush$xmin, brush$xmax)
    rangesZoomAnalyisPlotSamplesSelected$y <-
      c(brush$ymin, brush$ymax)
    
  } else {
    ## reset coord_cartesian
    rangesZoomAnalyisPlotSamplesSelected$x <- NULL
    rangesZoomAnalyisPlotSamplesSelected$y <- NULL
  }
})


#~~~~~~~~~ Features list plot ~~~~~~~#
output$AnalyisPlotSamplesSelected <- renderPlot({
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) > 1 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    if (TRUE) {
      myPlot <-
        req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) %>%
        
        ggplot() +
        aes(x = `CE-time`,
            y = `M+H`,
            colour = intensity) +
        #geom_point(shape = "circle", size = input$sizePoints) +
        geom_point(size = req(input$sizePoints)) +
        scale_color_viridis_c(option = "inferno", direction = -1) +
        theme_gray() +
        facet_grid(vars(sample), vars())  +
        # facet_wrap(~req(sample) , dir="v", ncol = 1)  +
        coord_cartesian(xlim = rangesZoomAnalyisPlotSamplesSelected$x,
                        ylim = rangesZoomAnalyisPlotSamplesSelected$y,
                        expand = TRUE) +
        ylab("Mass (M+H) (Da)") +
        xlab(paste("CE-time (", input$UnitTime, ")")) +
        
        ggtitle(paste("Features list")) +
        
        scale_x_continuous(n.breaks = 14) +
        #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
        
        
        #facet_grid(vars(sample), vars())+
        #option_graphe.2 +
        theme_ben() +
        labs(colour = "log2 Intensity") +
        theme(
          plot.title = element_text(
            size = rel(1),
            face = "bold",
            color = "#760001",
            margin = margin(0, 0, 5, 0),
            hjust = 0.5
          ),
          plot.subtitle = element_text(hjust = 0.5),
          panel.border = element_rect(
            fill = "transparent",
            # Needed to add the border
            color = "blue",
            linewidth = 0.5,
            linetype = "dashed"
          )
        )
      
    }
    
    
    
    
    
  }
  
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) == 1 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    myPlot <-
      req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime) %>%
      
      ggplot() +
      aes(x = `CE-time`, y = `M+H`, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints) +
      geom_point(size = input$sizePoints) +
      scale_color_viridis_c(option = "inferno", direction = -1) +
      ylab("Mass (M+H) (Da)") +
      xlab(paste("CE-time (", input$UnitTime, ")")) +
      coord_cartesian(xlim = rangesZoomAnalyisPlotSamplesSelected$x,
                      ylim = rangesZoomAnalyisPlotSamplesSelected$y,
                      expand = TRUE) +
      ggtitle(paste("Features list")) +
      
      scale_x_continuous(n.breaks = 14) +
      #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
      
      
      #facet_grid(vars(sample), vars())+
      #option_graphe.3
      theme_ben() +
      labs(colour = "log2 Intensity") +
      theme(
        plot.title = element_text(
          size = rel(1),
          face = "bold",
          color = "#760001",
          margin = margin(0, 0, 5, 0),
          hjust = 0.5
        ),
        plot.subtitle = element_text(hjust = 0.5)
      )
    
  }
  
  Values_myPlot <- reactive({
    myPlot
  })
  
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) > 0 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    shinyjs::show("PeaksMonoIsoPlotAnalysisNewSample_id")
    Values_myPlot()
    
  }
  
})


### Position mouse
output$PeaksMonoIsoPlotAnalysisNewSample_info <- renderText({
  paste0(
    "Mouse position : CE-time = ",
    round(req(input$plotAnalysisNewSample_click$x), 0),
    " (",
    input$UnitTime,
    "), ",
    " M+H = ",
    round(req(input$plotAnalysisNewSample_click$y), 4),
    " (Da)"
  )
})


##~~~~~~~~~~ Info bull for plot features list ~~~~~~~~#
output$plotAnalysisNewSamplet_hover_info <- renderUI({
  hover <- req(input$plotAnalysisNewSamplet_hover)
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) > 1 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    myPlot_data <-
      req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)
    
  }
  
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) == 1 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    myPlot_data <-
      req(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)
  }
  
  Values_myPlot_data <- reactive({
    myPlot_data
  })
  
  
  if (length(
    unique(
      RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
    )
  ) > 0 &
  !is.null(ms_features_newSample()) & !is.null(input$levelSample)) {
    point <-
      nearPoints(
        req(Values_myPlot_data()),
        hover,
        threshold = 5,
        maxpoints = 1,
        addDist = TRUE
      )
    if (nrow(point) == 0)
      return(NULL)
    
    
    # calculate point position INSIDE the image as percent of total dimensions
    # from left (horizontal) and from top (vertical)
    left_pct <-
      (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <-
      (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    # calculate distance from left and bottom side of the picture in pixels
    left_px <-
      hover$range$left + left_pct * (hover$range$right - hover$range$left)
    top_px <-
      hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
    
    # create style property fot tooltip
    # background color is set so tooltip is a bit transparent
    # z-index is set so we are sure are tooltip will be on top
    style <-
      paste0(
        "position:absolute; z-index:100; background-color: #f7f0f0; ",
        "left:",
        left_px + 2,
        "px; top:",
        top_px + 2,
        "px;"
      )
    
    # actual tooltip created as wellPanel
    div(class = "well well-sm",
        style = style,
        p(HTML(
          paste0(
            "<span class='bullText'> CE-time: </span>",
            round(point$`CE-time`, 2),
            "<br/>",
            "<span class='bullText'> M+H: </span>",
            round(point$`M+H`, 4),
            "<br/>",
            "<span class='bullText'> log2 Intensity: </span>",
            round(point$intensity, 2),
            "<br/>",
            "<span class='bullText'> Intensity: </span>",
            round(2 ^ (point$intensity), 0),
            "<br/>"
          )
        )))
    
  }
  
  
})

##~~~~~~~~~~~ Render plot number of features ~~~~~~~~~~#
output$NumberOfFeatures <- renderPlot({
  if (length(number_of_features()) > 0 &
      length(
        unique(
          RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime$sample
        )
      ) > 0 &
      !is.null(ms_features_newSample()) &
      !is.null(input$levelSample)) {
    NbPeak_for_each_sample_adj <- data.frame(number_of_features())
    colnames(NbPeak_for_each_sample_adj)[1] <- "Sample"
    ggplot(NbPeak_for_each_sample_adj) +
      aes(x = Sample,
          #colour = sample,
          weight = Freq) +
      geom_bar(width = 0.4, fill = "#4682B4") +
      geom_text(
        aes(label = paste0(round(..count.., 2))),
        stat = "count",
        vjust = 0,
        hjust = 0.5,
        size = 5,
        fontface = 4
      ) +
      scale_color_hue(direction = 1) +
      #coord_flip() +
      ylab("Number of Features") +
      xlab("") +
      coord_cartesian(ylim = c(0, max(NbPeak_for_each_sample_adj$Freq) +
                                 1000)) +
      theme_ben() +
      #theme(axis.text.x = element_text(angle = 90, size = rel(1), face = "bold"))
      theme(axis.text.x = element_text(size = rel(1.2), face = "bold"))
    
  }
  
})

output$sampleOutput <- renderText({
  legend_sample()$Samples
})


##~~~~~~~~~~~~ Get data to save ~~~~~~~~~~#
ms_features_newSample_toSave <- reactive({
  if (!is.null(ms_features_newSample()) &
      !is.null(input$IncludeSample)) {
    values <-
      ms_features_newSample()[ms_features_newSample()$sample %in% input$IncludeSample, ]
    values$intensity <- 2 ^ (values$intensity)
    split(values, f = values$sample)
    
  }
  
})

##~~~~~~~~~~~~ Get data to use ~~~~~~~~~~#

ms_features_list_newSample_toUse <- reactive({
  if (!is.null(ms_features_newSample()) &
      !is.null(input$IncludeSample)) {
    values <-
      ms_features_newSample()[ms_features_newSample()$sample %in% input$IncludeSample, ]
    values$intensity <- 2 ^ (values$intensity)
    
    split(values, f = values$sample)
  }
})


##~~~~~~~~~~~~ Save features list ~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveAnalysis
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "SaveAnalysis",
                             roots = volumes,
                             session = session)
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$SaveAnalysis)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <-
                   strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (length(ms_features_newSample_toSave()) > 0 &
                     !is.null(ms_features_newSample()) &
                     !is.null(input$IncludeSample)) {
                   if (length(ms_features_newSample_toSave()) == 1) {
                     write.table(
                       ms_features_newSample_toSave()[[1]],
                       #file = path_Save_Files_origine,
                       file = paste0(c(
                         directory_Save_Files,
                         paste(
                           names(ms_features_newSample_toSave())[1],
                           path_Save_Files[length(path_Save_Files)],
                           collapse = "",
                           sep = "-"
                         )
                       ), collapse = "/"),
                       sep = ",",
                       row.names = FALSE
                     )
                     print("Save ok")
                   } else{
                     withProgress(message = 'Saving files...', value = 0, {
                       for (i in 1:length(ms_features_newSample_toSave())) {
                         incProgress(1 / length(ms_features_newSample_toSave()),
                                     detail = paste(names(
                                       ms_features_newSample_toSave()
                                     )[i]))
                         print(basename(paste0(
                           c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(ms_features_newSample_toSave())[i],
                               path_Save_Files[length(path_Save_Files)],
                               collapse = "",
                               sep = "-"
                             )
                           ), collapse = "/"
                         )))
                         write.table(
                           ms_features_newSample_toSave()[[i]],
                           file = paste0(c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(ms_features_newSample_toSave())[i],
                               path_Save_Files[length(path_Save_Files)],
                               collapse = "",
                               sep = "-"
                             )
                           ), collapse = "/"),
                           sep = ",",
                           row.names = FALSE
                         )
                         print("Save ok")
                       }
                       
                     })
                     
                   }
                   
                   
                 }
               }
               
               
             })
