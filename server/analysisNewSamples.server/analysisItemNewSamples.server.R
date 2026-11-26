###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ Configure some buttons ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button returnAnalysisViewer ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$returnAnalysisViewer
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Peak detection and grouping")
               
               
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "4")
               
               enable("GoToPeakView_newSample")
               enable("CorrectionKernelDensityNexPage_newSample")
               
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button normIntensity ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$normIntensity
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Samples normalization")
               
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Button normIntensity ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$normIntensity
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Samples normalization")
               
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ returnMatchRef ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$returnMatchRef
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Match reference map")
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~ returnAnalysisViewer ~~~~~~~~~~~~~~~~~~~~~~~~#*
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$returnAnalysisViewer
             }
             , {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Peak detection and grouping")
               
               
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "4")
               
               
             })



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ Manage default parameters ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observe({
  if (length(input$normalizingParameters) != 0) {
    if (input$normalizingParameters == "defaults") {
      updateNumericInput(session = session,
                         inputId = "min_iset",
                         value = 10)
      updateNumericInput(session = session,
                         inputId = "cutrat",
                         value = 1)
    }
    
  }
  
  if (length(input$ViewSizePointsMatch) != 0) {
    if (input$ViewSizePointsMatch == "defaults") {
      shinyjs::reset("sizePointsMatch")
    }
  }
  
})

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~ Manage button finishAnalyze ~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$finishAnalyze
             },
             
             handlerExpr = {
               ### End Processing
               sendSweetAlert(
                 session = session,
                 title = paste("Thank you !", "\n", "Data Analysis has been completed."),
                 text = HTML(
                   '<h3> You have done the following : </h3>
                <ol style = "list-style-type: none;">
                <li>Peak picking, CE-time correction and grouping of features which are similar in the samples.</li>
                <li>Match features on the original reference map.</li>
                <li>Normalization in intensity of features using internal standards.</li>
                </ol>
                <br/>
                <h3>Click ok to return to the "Analysis new samples" page.</h3>'
                 ),
                 type = "success",
                 width = "80%",
                 closeOnClickOutside = FALSE,
                 html = TRUE
               )
               
               updateNavbarPage(inputId = "analysisNavbar",
                                session = session,
                                selected = "Peak detection and grouping")
               
               updateRadioButtons(session = session,
                                  inputId = "IdAnalysisStep",
                                  selected = "1")
               
               shinyjs::show("runPeakPicking")
               shinyjs::show(id = "buttonResetViewAnalysis")
               shinyjs::show(id = "RestartProjects")
               shinyjs::show(id = "ViewAnalysis")
               enable("runPeakPicking")
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ Uploading features list files ~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$features_list
             }
             , {
               files <- input$features_list
               ext <- tools::file_ext(files$datapath)
               
               
               if (length(ext) > 1) {
                 if (all.equal(ext, rep("csv", length(ext))) != TRUE) {
                   message("Please upload a csv file...!")
                   # hide("progressWrapper")
                   # hide("analysisProgress")
                   # shinyjs::html("analysisProgress",html = NULL)
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning"
                   )
                 } else {
                   # req(files)
                   # validate(need(ext == "csv", "Please upload a csv file"))
                   
                   a <- lapply(input$features_list$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     # hide("progressWrapper")
                     # hide("analysisProgress")
                     # shinyjs::html("analysisProgress",html = NULL)
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'CE-time', 'intensity', 'sample', 'iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group',
                            'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group', not found in files.",
                       type = "warning"
                     )
                   })
                   
                   
                   
                   if (!is.element("M.H", colnames(a)) ||
                       !is.element('CE.time', colnames(a)) ||
                       !is.element("intensity", colnames(a)) ||
                       !is.element("sample", colnames(a)) ||
                       !is.element("iso.mass", colnames(a)) ||
                       !is.element("iso.mass.link", colnames(a)) ||
                       !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
                       ncol(a) < 9) {
                     message("Please upload a csv file...!")
                     # hide("progressWrapper")
                     # hide("analysisProgress")
                     # shinyjs::html("analysisProgress",html = NULL)
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'CE-time', 'intensity', 'sample', 'iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group',
                   'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group', not found in files.",
                       type = "warning"
                     )
                   } else {
                     ColnameData <-
                       c(
                         'M.H',
                         'CE.time',
                         'intensity',
                         'sample',
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group'
                       )
                     
                     ColnamesToUse <- c(
                       'M+H',
                       'CE-time',
                       'intensity',
                       'sample',
                       'iso.mass',
                       'iso.mass.link',
                       'mz_PeaksIsotopics_Group',
                       'rt_PeaksIsotopics_Group',
                       'Height_PeaksIsotopics_Group'
                     )
                     
                     colnames(a)[which(colnames(a) %in% ColnameData)] <-
                       ColnamesToUse
                     
                     a <-
                       a[, c(
                         "M+H",
                         "CE-time",
                         "intensity",
                         "sample",
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group'
                       )]
                     #colnames(a)<-c("mz","rt","maxo","sample")
                     a <- split(a, f = a$sample)
                     names(a) <- 1:length(a)
                     RvarsPeakDetectionNewSample$FeaturesList_newSample <- a
                     #hide("runPeakPicking")
                   }
                   
                 }
               } else {
                 if (ext != "csv") {
                   message("Please upload a csv file...!")
                   # hide("progressWrapper")
                   # hide("analysisProgress")
                   # shinyjs::html("analysisProgress",html = NULL)
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning"
                   )
                 } else {
                   # req(files)
                   # validate(need(ext == "csv", "Please upload a csv file"))
                   a <- lapply(input$features_list$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     # hide("progressWrapper")
                     # hide("analysisProgress")
                     # shinyjs::html("analysisProgress",html = NULL)
                     
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'CE-time', 'intensity', 'sample', 'iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group',
                   'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group', not found in files.",
                       type = "warning",
                     )
                   })
                   
                   
                   
                   
                   if (!is.element("M.H", colnames(a)) ||
                       !is.element("CE.time", colnames(a)) ||
                       !is.element("intensity", colnames(a)) ||
                       !is.element("sample", colnames(a)) ||
                       !is.element("iso.mass", colnames(a)) ||
                       !is.element("iso.mass.link", colnames(a)) ||
                       !is.element("mz_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("rt_PeaksIsotopics_Group", colnames(a)) ||
                       !is.element("Height_PeaksIsotopics_Group", colnames(a)) ||
                       ncol(a) < 9) {
                     message("Please upload a csv file...!")
                     # hide("progressWrapper")
                     # hide("analysisProgress")
                     # shinyjs::html("analysisProgress",html = NULL)
                     message("\n Probleme inconnu")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Required columns : 'M+H', 'CE-time', 'intensity', 'sample', 'iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group',
                   'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group', not found in files.",
                       type = "warning"
                     )
                   } else {
                     ColnameData <- c(
                       'M.H',
                       'CE.time',
                       'intensity',
                       'sample',
                       'iso.mass',
                       'iso.mass.link',
                       'mz_PeaksIsotopics_Group',
                       'rt_PeaksIsotopics_Group',
                       'Height_PeaksIsotopics_Group'
                     )
                     
                     ColnamesToUse <- c(
                       'M+H',
                       'CE-time',
                       'intensity',
                       'sample',
                       'iso.mass',
                       'iso.mass.link',
                       'mz_PeaksIsotopics_Group',
                       'rt_PeaksIsotopics_Group',
                       'Height_PeaksIsotopics_Group'
                     )
                     
                     colnames(a)[which(colnames(a) %in% ColnameData)] <-
                       ColnamesToUse
                     
                     a <-
                       a[, c(
                         "M+H",
                         "CE-time",
                         "intensity",
                         "sample",
                         'iso.mass',
                         'iso.mass.link',
                         'mz_PeaksIsotopics_Group',
                         'rt_PeaksIsotopics_Group',
                         'Height_PeaksIsotopics_Group'
                       )]
                     #colnames(a)<-c("mz","rt","maxo","sample")
                     a <- split(a, f = a$sample)
                     names(a) <- 1:length(a)
                     RvarsPeakDetectionNewSample$FeaturesList_newSample <- a
                     #hide(id = "runPeakPicking")
                     
                   }
                 }
               }
               
               
             })



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~ Matching new sample on reference map ~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Automatic compute ~~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$IncludeSample
             },
             handlerExpr = {
               shinyjs::show("wellPanelMatchOutput")
               if (!is.null(ms_features_list_newSample_toUse())) {
                 source("lib/AnalysisNewSample/R_files/matched_reference_map.lib.R",
                        local = TRUE)
                 
                 
                 RvarsMatchNewsample$res_match_ref <- matchNewSample_ref(
                   ms_features_MSDIAL_list = req(ms_features_list_newSample_toUse()),
                   map_ref = req(RvarsPeakDetectionNewSample$map_ref),
                   rt_tolerance = req(
                     as.numeric(RvarsPeakDetectionNewSample$defaultParam$bw)
                   ),
                   mass_tolerance = req(
                     as.numeric(
                       RvarsPeakDetectionNewSample$defaultParam$mass_tolerance
                     )
                   )
                 )
                 
                 
                 
                 res_MatrixNewSample_save <-
                   RvarsMatchNewsample$res_match_ref$res_newSample
                 # RvarsMatchNewsample$res_MatrixNewSample<-
                 #   read.csv("C:/Users/mouhamed.seye/Desktop/Test/New project_2022-07-22 09-04-39/Peak list result/Matrix_abondance.csv")
                 
                 colnames(res_MatrixNewSample_save)[2] <- "M+H"
                 colnames(res_MatrixNewSample_save)[3] <- "CE-time"
                 
                 # write.table(res_MatrixNewSample_save,
                 #           file = file.path(file.path(directoryInput$directory, rValues$Project_Name,
                 #                                      "Peak list result","Matrix_abondance.csv"),
                 #                            sep = ""), sep = ",", row.names = FALSE)
                 
                 
                 ##### plot results
                 RvarsMatchNewsample$res_MatrixNewSample <-
                   req(RvarsMatchNewsample$res_match_ref$res_newSample)
                 
                 if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                   updateSelectInput(
                     session = session,
                     inputId = "levelSampleMatch",
                     choices = colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]
                   )
                   
                   
                   
                   
                   res_MatrixNewSampleViewer <- reactive({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         valuesNomatch <-
                           RvarsMatchNewsample$res_match_ref$noMatch_newSample[input$levelSampleMatch][[1]]
                         
                         values <-
                           data.frame(
                             RvarsMatchNewsample$res_MatrixNewSample[, 1:3],
                             M.H_newSample = NA,
                             CE.time_adj = NA,
                             sample = RvarsMatchNewsample$res_MatrixNewSample[, input$levelSampleMatch],
                             Match = "NULL"
                           )
                         
                         
                         
                         valuesMatched <-
                           valuesNomatch[!is.na(valuesNomatch$ID), ]
                         
                         for (i in valuesMatched$ID) {
                           values[values$ID == i, ]$M.H_newSample <-
                             valuesMatched[valuesMatched$ID == i, ]$`M+H`
                           values[values$ID == i, ]$CE.time_adj <-
                             valuesMatched[valuesMatched$ID == i, ]$`CE-time`
                         }
                         
                         
                         if (is.element(TRUE, is.na(values$sample)))
                           values[is.na(values$sample), ]$Match <- "Ref map"
                         if (is.element(TRUE,!is.na(values$sample)))
                           values[!is.na(values$sample), ]$Match <- "Matched"
                         
                         
                         colnames(values)[2:3] <- c("M+H", "CE-time")
                         values <-
                           values[, c("M+H",
                                      "CE-time",
                                      "M.H_newSample",
                                      "CE.time_adj",
                                      "sample",
                                      "Match")]
                         
                         
                         
                         valuesNomatch$sample <- NA
                         valuesNomatch$sample <- as.numeric(valuesNomatch$sample)
                         
                         idx_Duplicates_ref <-
                           valuesNomatch[valuesNomatch$Match == "Duplicates", ]$ID
                         
                         
                         if (length(idx_Duplicates_ref)) {
                           values[idx_Duplicates_ref, ]$Match <- "Duplicates"
                         }
                         
                         
                         
                         
                         valuesNomatch <- valuesNomatch[is.na(valuesNomatch$ID), ]
                         valuesNomatch$M.H_newSample <- valuesNomatch$`M+H`
                         valuesNomatch$CE.time_adj <- valuesNomatch$`CE-time`
                         valuesNomatch <-
                           valuesNomatch[, c("M+H",
                                             "CE-time",
                                             "M.H_newSample",
                                             "CE.time_adj",
                                             "sample",
                                             "Match")]
                         
                         
                         res <- rbind(values, valuesNomatch)
                         res <- as.data.frame(res)
                         res$Match <-
                           factor(res$Match,
                                  levels = c("Ref map", "Matched", "No match", "Duplicates"))
                         
                         res
                         
                         
                       }
                     }
                     
                   })
                   
                   ##### Matched table
                   observe({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         RvarsMatchNewsample$matchedTable_newSample <-
                           RvarsMatchNewsample$res_match_ref$matchedTable_newSample[input$levelSampleMatch][[1]]
                         
                       }
                     }
                   })
                   
                   shinyjs::show(id = "IdmatchedTableViewer")
                   output$matchedTableViewer <- renderDT({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         rColsUsed <-
                           c(
                             "M+H.ref",
                             "CE-time.ref",
                             "intensity.ref",
                             "iso.mass.ref",
                             "iso.mass.link.ref",
                             "mz_PeaksIsotopics_Group.ref",
                             "rt_PeaksIsotopics_Group.ref",
                             "Height_PeaksIsotopics_Group.ref"
                           )
                         
                         colnames(RvarsMatchNewsample$matchedTable_newSample)[1:8] <-
                           rColsUsed
                         
                         datatable(req(RvarsMatchNewsample$matchedTable_newSample))
                       }
                     }
                   })
                   
                   
                   
                   ####### Convert to min or sec the plot
                   
                   observe({
                     RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime <-
                       req(res_MatrixNewSampleViewer())
                     
                   })
                   
                   
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$levelSampleMatch
                     },
                     handlerExpr = {
                       RvarsMatchNewsample$SecondMatch <- TRUE
                       if (input$UnitTimeMatch == "Minute") {
                         ### Conversion Seconde en min
                         print(
                           paste(
                             "Convert to min",
                             input$UnitTimeMatch == "Minute" &
                               RvarsMatchNewsample$SecondMatch == TRUE
                           )
                         )
                         if (input$UnitTimeMatch == "Minute" &
                             RvarsMatchNewsample$SecondMatch == TRUE) {
                           if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                             RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                               req(
                                 RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                               ) / 60
                             
                             RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                               req(
                                 RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                               ) / 60
                             RvarsMatchNewsample$SecondMatch <- FALSE
                           }
                         }
                       }
                       
                       
                     }
                   )
                   
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$features_list
                     },
                     handlerExpr = {
                       updateRadioGroupButtons(session = session,
                                               inputId = "UnitTimeMatch",
                                               selected = "Second")
                       RvarsMatchNewsample$SecondMatch == TRUE
                       ## reset coord_cartesian
                       rangesZoomAnalyisPlotSamplesSelected$x <- NULL
                       rangesZoomAnalyisPlotSamplesSelected$y <- NULL
                       
                       
                     }
                   )
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$UnitTimeMatch
                     },
                     handlerExpr = {
                       #RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime<-ms_features_MSDIAL_newSample_toPlot()
                       print(
                         paste(
                           "Convert to min",
                           input$UnitTimeMatch == "Minute" &
                             RvarsMatchNewsample$SecondMatch == TRUE
                         )
                       )
                       if (input$UnitTimeMatch == "Minute" &
                           RvarsMatchNewsample$SecondMatch == TRUE) {
                         if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                             ) / 60
                           
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                             ) / 60
                           RvarsMatchNewsample$SecondMatch <- FALSE
                         }
                       }
                       
                       print(
                         paste(
                           "Covert to Second",
                           input$UnitTimeMatch == "Second" &
                             RvarsMatchNewsample$SecondMatch == FALSE
                         )
                       )
                       if (input$UnitTimeMatch == "Second" &
                           RvarsMatchNewsample$SecondMatch == FALSE) {
                         if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                             ) * 60
                           
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                             ) * 60
                           RvarsMatchNewsample$SecondMatch <- TRUE
                         }
                       }
                       
                       if (input$UnitTimeMatch == "Second" &
                           RvarsMatchNewsample$SecondMatch == TRUE) {
                         RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime <-
                           req(res_MatrixNewSampleViewer())
                       }
                       
                       
                     }
                   )
                   
                   number_matched <- reactive({
                     if (!is.null(res_MatrixNewSampleViewer())) {
                       #sum(!is.na(res_MatrixNewSampleViewer()$sample))
                       nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                          "Matched", ])
                     }
                   })
                   
                   rangesZoommatchViewer <- reactiveValues(x = NULL, y = NULL)
                   
                   # When a double-click happens, check if there's a brush on the plot.
                   # If so, zoom to the brush bounds; if not, reset the zoom.
                   observeEvent({
                     input$matchViewerNewSample_dblclick
                   }, {
                     brush <- input$matchViewerNewSample_brush
                     if (!is.null(brush)) {
                       rangesZoommatchViewer$x <- c(brush$xmin, brush$xmax)
                       rangesZoommatchViewer$y <- c(brush$ymin, brush$ymax)
                       
                     } else {
                       rangesZoommatchViewer$x <- NULL
                       rangesZoommatchViewer$y <- NULL
                     }
                   })
                   
                   shinyjs::show(id = "Idfeatures_matchViewer")
                   output$features_matchViewer <- renderPlot({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                       res_Matrix_toPlot <-
                         RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
                       
                       
                       numberFeatures_RefMap <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Matched", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Ref map", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Duplicates", ])
                       
                       
                       numberFeatures_NewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "No match", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Matched", ])
                       
                       message("\n numberFeatures_NewSample:")
                       print(numberFeatures_NewSample)
                       percentMatched_ByNewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Matched", ]) *
                         100 / numberFeatures_NewSample
                       
                       percentDuplicates_ByNewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Duplicates", ]) *
                         100 / numberFeatures_NewSample
                       
                       
                       
                       par(fig = c(0, 1, 0, 1), mar = c(4, 4, 10, 0))
                       plot(
                         x = res_Matrix_toPlot$`CE-time`,
                         y = res_Matrix_toPlot$`M+H`,
                         axes = T,
                         pch = 20,
                         col = "white",
                         cex = input$sizePointsMatch,
                         xlab = paste("CE-time(", input$UnitTimeMatch, ")"),
                         ylab = "M+H(Da)",
                         xlim = rangesZoommatchViewer$x,
                         ylim = rangesZoommatchViewer$y,
                         main = paste0(
                           "REFRENCE MAP: ",
                           req(input$chosseRef),
                           " (",
                           numberFeatures_RefMap,
                           " features)",
                           "\n",
                           "Sample: ",
                           input$levelSampleMatch,
                           "\n",
                           "Number of features matched: ",
                           number_matched(),
                           "\n",
                           "",
                           "\n",
                           "% of matched rapported to ref map: ",
                           round(number_matched() / numberFeatures_RefMap * 100, 2),
                           "%",
                           "\n",
                           "% of matched rapported to new sample: ",
                           round(percentMatched_ByNewSample, 2),
                           "%",
                           "\n",
                           "% of Duplicates rapported to new sample: ",
                           round(percentDuplicates_ByNewSample, 5),
                           "%"
                         ),
                         
                         col.main = "#760001",
                         
                         font.main = 2,
                         cex.lab = 1.2,
                         font.lab = 2,
                         cex.axis = 1.1,
                         font.axis = 2,
                         cex.main = 1.2
                       )
                       
                       
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Ref map", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Ref map", ]$`M+H`,
                         pch = 20,
                         col = "gray61",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Matched", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Matched", ]$`M+H`,
                         pch = 20,
                         col = "dodgerblue",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "No match", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "No match", ]$`M+H`,
                         pch = 20,
                         col = "red",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Duplicates", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Duplicates", ]$`M+H`,
                         pch = 20,
                         col = "green",
                         cex = input$sizePointsMatch
                       )
                       
                       # axis(1,col="black",col.axis="black",
                       #      font = 2, cex.lab = 1.3, cex.axis = 1.2, lwd = 2, line = 0)
                       # # mtext("Ce-time(second)",side=1,line=3,col="black", font = 2, cex=1.2)
                       # #
                       # axis(2,col="black",col.axis="black",
                       #      font = 2, cex.lab = 1.3, cex.axis = 1.2, lwd = 2, line = 0)
                       # # mtext("M+H(Da)",side=2,line=3,col="black", font = 2, cex=1.2)
                       
                       legend(
                         "topleft",
                         pch = 20,
                         pt.cex = 2,
                         inset = 0,
                         text.font = 2.3,
                         legend = levels(res_Matrix_toPlot$Match),
                         bty = "n",
                         xpd = NA,
                         cex = 1.2,
                         col = c("gray61", "dodgerblue", "red", "green"),
                         horiz = FALSE
                       )
                       grid(nx = 14)
                       
                       
                     }
                   })
                   
                   output$matchViewerNewSamplet_hover_info <- renderUI({
                     hover <- req(input$matchViewerNewSamplet_hover)
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                       point <-
                         suppressWarnings(
                           nearPoints(
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
                             ),
                             hover,
                             xvar = "CE-time",
                             yvar = "M+H",
                             threshold = 5,
                             maxpoints = 1,
                             addDist = TRUE
                           )
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
                       # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                       #                 "left:", left_px + 2, "px; top:", top_px + 2, "px;")
                       
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
                               "<span class='bullText'> M+H: </span>",
                               round(point$`M+H`, 4),
                               "<br/>",
                               "<span class='bullText'> CE-time: </span>",
                               round(point$`CE-time`, 2),
                               "<br/>"
                             )
                           )))
                       
                     }
                     
                     
                   })
                 }
                 
                 shinyjs::show(id = "Idpercent_matchViewer")
                 output$percent_matchViewer <- renderDT({
                   datatable(req(RvarsMatchNewsample$res_match_ref$pct_match_ref))
                 })
                 
                 shinyjs::show("buttonNormIntensity")
                 shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                 
               }
               
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~ When clicking button match ~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$match
             },
             handlerExpr = {
               shinyjs::show("wellPanelMatchOutput")
               if (!is.null(ms_features_list_newSample_toUse())) {
                 source("lib/AnalysisNewSample/R_files/matched_reference_map.lib.R",
                        local = TRUE)
                 
                 
                 RvarsMatchNewsample$res_match_ref <- matchNewSample_ref(
                   ms_features_MSDIAL_list = req(ms_features_list_newSample_toUse()),
                   map_ref = req(RvarsPeakDetectionNewSample$map_ref),
                   rt_tolerance = req(
                     as.numeric(RvarsPeakDetectionNewSample$defaultParam$bw)
                   ),
                   mass_tolerance = req(
                     as.numeric(
                       RvarsPeakDetectionNewSample$defaultParam$mass_tolerance
                     )
                   )
                 )
                 
                 
                 
                 res_MatrixNewSample_save <-
                   RvarsMatchNewsample$res_match_ref$res_newSample
                 # RvarsMatchNewsample$res_MatrixNewSample<-
                 #   read.csv("C:/Users/mouhamed.seye/Desktop/Test/New project_2022-07-22 09-04-39/Peak list result/Matrix_abondance.csv")
                 
                 colnames(res_MatrixNewSample_save)[2] <- "M+H"
                 colnames(res_MatrixNewSample_save)[3] <- "CE-time"
                 
                 # write.table(res_MatrixNewSample_save,
                 #           file = file.path(file.path(directoryInput$directory, rValues$Project_Name,
                 #                                      "Peak list result","Matrix_abondance.csv"),
                 #                            sep = ""), sep = ",", row.names = FALSE)
                 
                 
                 ##### plot results
                 RvarsMatchNewsample$res_MatrixNewSample <-
                   req(RvarsMatchNewsample$res_match_ref$res_newSample)
                 
                 if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                   updateSelectInput(
                     session = session,
                     inputId = "levelSampleMatch",
                     choices = colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]
                   )
                   
                   
                   
                   
                   res_MatrixNewSampleViewer <- reactive({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         valuesNomatch <-
                           RvarsMatchNewsample$res_match_ref$noMatch_newSample[input$levelSampleMatch][[1]]
                         
                         values <-
                           data.frame(
                             RvarsMatchNewsample$res_MatrixNewSample[, 1:3],
                             M.H_newSample = NA,
                             CE.time_adj = NA,
                             sample = RvarsMatchNewsample$res_MatrixNewSample[, input$levelSampleMatch],
                             Match = "NULL"
                           )
                         
                         
                         
                         valuesMatched <-
                           valuesNomatch[!is.na(valuesNomatch$ID), ]
                         
                         for (i in valuesMatched$ID) {
                           values[values$ID == i, ]$M.H_newSample <-
                             valuesMatched[valuesMatched$ID == i, ]$`M+H`
                           values[values$ID == i, ]$CE.time_adj <-
                             valuesMatched[valuesMatched$ID == i, ]$`CE-time`
                         }
                         
                         
                         if (is.element(TRUE, is.na(values$sample)))
                           values[is.na(values$sample), ]$Match <- "Ref map"
                         if (is.element(TRUE,!is.na(values$sample)))
                           values[!is.na(values$sample), ]$Match <- "Matched"
                         
                         
                         colnames(values)[2:3] <- c("M+H", "CE-time")
                         values <-
                           values[, c("M+H",
                                      "CE-time",
                                      "M.H_newSample",
                                      "CE.time_adj",
                                      "sample",
                                      "Match")]
                         
                         
                         
                         valuesNomatch$sample <- NA
                         valuesNomatch$sample <- as.numeric(valuesNomatch$sample)
                         
                         idx_Duplicates_ref <-
                           valuesNomatch[valuesNomatch$Match == "Duplicates", ]$ID
                         
                         
                         if (length(idx_Duplicates_ref)) {
                           values[idx_Duplicates_ref, ]$Match <- "Duplicates"
                         }
                         
                         
                         
                         valuesNomatch <- valuesNomatch[is.na(valuesNomatch$ID), ]
                         valuesNomatch$M.H_newSample <- valuesNomatch$`M+H`
                         valuesNomatch$CE.time_adj <- valuesNomatch$`CE-time`
                         valuesNomatch <-
                           valuesNomatch[, c("M+H",
                                             "CE-time",
                                             "M.H_newSample",
                                             "CE.time_adj",
                                             "sample",
                                             "Match")]
                         
                         
                         res <- rbind(values, valuesNomatch)
                         res <- as.data.frame(res)
                         res$Match <-
                           factor(res$Match,
                                  levels = c("Ref map", "Matched", "No match", "Duplicates"))
                         
                         res
                         
                         
                       }
                     }
                     
                   })
                   
                   ##### Matched table
                   observe({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         RvarsMatchNewsample$matchedTable_newSample <-
                           RvarsMatchNewsample$res_match_ref$matchedTable_newSample[input$levelSampleMatch][[1]]
                         
                       }
                     }
                   })
                   
                   shinyjs::show(id = "IdmatchedTableViewer")
                   output$matchedTableViewer <- renderDT({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSample)) {
                       if (input$levelSampleMatch %in% colnames(RvarsMatchNewsample$res_MatrixNewSample)[4:ncol(RvarsMatchNewsample$res_MatrixNewSample)]) {
                         rColsUsed <-
                           c(
                             "M+H.ref",
                             "CE-time.ref",
                             "intensity.ref",
                             "iso.mass.ref",
                             "iso.mass.link.ref",
                             "mz_PeaksIsotopics_Group.ref",
                             "rt_PeaksIsotopics_Group.ref",
                             "Height_PeaksIsotopics_Group.ref"
                           )
                         
                         colnames(RvarsMatchNewsample$matchedTable_newSample)[1:8] <-
                           rColsUsed
                         
                         datatable(req(RvarsMatchNewsample$matchedTable_newSample))
                       }
                     }
                   })
                   
                   
                   
                   ####### Convert to min or sec the plot
                   
                   observe({
                     RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime <-
                       req(res_MatrixNewSampleViewer())
                     
                   })
                   
                   
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$levelSampleMatch
                     },
                     handlerExpr = {
                       RvarsMatchNewsample$SecondMatch <- TRUE
                       if (input$UnitTimeMatch == "Minute") {
                         ### Conversion Seconde en min
                         print(
                           paste(
                             "Convert to min",
                             input$UnitTimeMatch == "Minute" &
                               RvarsMatchNewsample$SecondMatch == TRUE
                           )
                         )
                         if (input$UnitTimeMatch == "Minute" &
                             RvarsMatchNewsample$SecondMatch == TRUE) {
                           if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                             RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                               req(
                                 RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                               ) / 60
                             
                             RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                               req(
                                 RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                               ) / 60
                             RvarsMatchNewsample$SecondMatch <- FALSE
                           }
                         }
                       }
                       
                       
                     }
                   )
                   
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$features_list
                     },
                     handlerExpr = {
                       updateRadioGroupButtons(session = session,
                                               inputId = "UnitTimeMatch",
                                               selected = "Second")
                       RvarsMatchNewsample$SecondMatch == TRUE
                       ## reset coord_cartesian
                       rangesZoomAnalyisPlotSamplesSelected$x <- NULL
                       rangesZoomAnalyisPlotSamplesSelected$y <- NULL
                       
                       
                     }
                   )
                   
                   observeEvent(
                     ignoreNULL = TRUE,
                     eventExpr = {
                       input$UnitTimeMatch
                     },
                     handlerExpr = {
                       #RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime<-ms_features_MSDIAL_newSample_toPlot()
                       print(
                         paste(
                           "Convert to min",
                           input$UnitTimeMatch == "Minute" &
                             RvarsMatchNewsample$SecondMatch == TRUE
                         )
                       )
                       if (input$UnitTimeMatch == "Minute" &
                           RvarsMatchNewsample$SecondMatch == TRUE) {
                         if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                             ) / 60
                           
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                             ) / 60
                           RvarsMatchNewsample$SecondMatch <- FALSE
                         }
                       }
                       
                       print(
                         paste(
                           "Covert to Second",
                           input$UnitTimeMatch == "Second" &
                             RvarsMatchNewsample$SecondMatch == FALSE
                         )
                       )
                       if (input$UnitTimeMatch == "Second" &
                           RvarsMatchNewsample$SecondMatch == FALSE) {
                         if (!is.null(RvarsPeakDetectionNewSample$ms_features_newSample_toPlot_ConvertTime)) {
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time` <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$`CE-time`
                             ) * 60
                           
                           RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj <-
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime$CE.time_adj
                             ) * 60
                           RvarsMatchNewsample$SecondMatch <- TRUE
                         }
                       }
                       
                       if (input$UnitTimeMatch == "Second" &
                           RvarsMatchNewsample$SecondMatch == TRUE) {
                         RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime <-
                           req(res_MatrixNewSampleViewer())
                       }
                       
                       
                     }
                   )
                   
                   number_matched <- reactive({
                     if (!is.null(res_MatrixNewSampleViewer())) {
                       #sum(!is.na(res_MatrixNewSampleViewer()$sample))
                       nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                          "Matched", ])
                     }
                   })
                   
                   rangesZoommatchViewer <- reactiveValues(x = NULL, y = NULL)
                   
                   # When a double-click happens, check if there's a brush on the plot.
                   # If so, zoom to the brush bounds; if not, reset the zoom.
                   observeEvent({
                     input$matchViewerNewSample_dblclick
                   }, {
                     brush <- input$matchViewerNewSample_brush
                     if (!is.null(brush)) {
                       rangesZoommatchViewer$x <- c(brush$xmin, brush$xmax)
                       rangesZoommatchViewer$y <- c(brush$ymin, brush$ymax)
                       
                     } else {
                       rangesZoommatchViewer$x <- NULL
                       rangesZoommatchViewer$y <- NULL
                     }
                   })
                   
                   shinyjs::show(id = "Idfeatures_matchViewer")
                   output$features_matchViewer <- renderPlot({
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                       res_Matrix_toPlot <-
                         RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
                       
                       
                       numberFeatures_RefMap <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Matched", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Ref map", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Duplicates", ])
                       
                       
                       numberFeatures_NewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "No match", ]) +
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match ==
                                                            "Matched", ])
                       
                       message("\n numberFeatures_NewSample:")
                       print(numberFeatures_NewSample)
                       percentMatched_ByNewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Matched", ]) *
                         100 / numberFeatures_NewSample
                       
                       percentDuplicates_ByNewSample <-
                         nrow(res_MatrixNewSampleViewer()[res_MatrixNewSampleViewer()$Match == "Duplicates", ]) *
                         100 / numberFeatures_NewSample
                       
                       
                       
                       par(fig = c(0, 1, 0, 1), mar = c(4, 4, 10, 0))
                       plot(
                         x = res_Matrix_toPlot$`CE-time`,
                         y = res_Matrix_toPlot$`M+H`,
                         axes = T,
                         pch = 20,
                         col = "white",
                         cex = input$sizePointsMatch,
                         xlab = paste("CE-time(", input$UnitTimeMatch, ")"),
                         ylab = "M+H(Da)",
                         xlim = rangesZoommatchViewer$x,
                         ylim = rangesZoommatchViewer$y,
                         main = paste0(
                           "REFRENCE MAP: ",
                           req(input$chosseRef),
                           " (",
                           numberFeatures_RefMap,
                           " features)",
                           "\n",
                           "Sample: ",
                           input$levelSampleMatch,
                           "\n",
                           "Number of features matched: ",
                           number_matched(),
                           "\n",
                           "",
                           "\n",
                           "% of matched rapported to ref map: ",
                           round(number_matched() / numberFeatures_RefMap * 100, 2),
                           "%",
                           "\n",
                           "% of matched rapported to new sample: ",
                           round(percentMatched_ByNewSample, 2),
                           "%",
                           "\n",
                           "% of Duplicates rapported to new sample: ",
                           round(percentDuplicates_ByNewSample, 5),
                           "%"
                         ),
                         
                         col.main = "#760001",
                         
                         font.main = 2,
                         cex.lab = 1.2,
                         font.lab = 2,
                         cex.axis = 1.1,
                         font.axis = 2,
                         cex.main = 1.2
                       )
                       
                       
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Ref map", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Ref map", ]$`M+H`,
                         pch = 20,
                         col = "gray61",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Matched", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Matched", ]$`M+H`,
                         pch = 20,
                         col = "dodgerblue",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "No match", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "No match", ]$`M+H`,
                         pch = 20,
                         col = "red",
                         cex = input$sizePointsMatch
                       )
                       
                       points(
                         x = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Duplicates", ]$`CE-time` ,
                         y = res_Matrix_toPlot[res_Matrix_toPlot$Match == "Duplicates", ]$`M+H`,
                         pch = 20,
                         col = "green",
                         cex = input$sizePointsMatch
                       )
                       
                       # axis(1,col="black",col.axis="black",
                       #      font = 2, cex.lab = 1.3, cex.axis = 1.2, lwd = 2, line = 0)
                       # # mtext("Ce-time(second)",side=1,line=3,col="black", font = 2, cex=1.2)
                       # #
                       # axis(2,col="black",col.axis="black",
                       #      font = 2, cex.lab = 1.3, cex.axis = 1.2, lwd = 2, line = 0)
                       # # mtext("M+H(Da)",side=2,line=3,col="black", font = 2, cex=1.2)
                       
                       legend(
                         "topleft",
                         pch = 20,
                         pt.cex = 2,
                         inset = 0,
                         text.font = 2.3,
                         legend = levels(res_Matrix_toPlot$Match),
                         bty = "n",
                         xpd = NA,
                         cex = 1.2,
                         col = c("gray61", "dodgerblue", "red", "green"),
                         horiz = FALSE
                       )
                       grid(nx = 14)
                       
                       
                     }
                   })
                   
                   output$matchViewerNewSamplet_hover_info <- renderUI({
                     hover <- req(input$matchViewerNewSamplet_hover)
                     if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
                       point <-
                         suppressWarnings(
                           nearPoints(
                             req(
                               RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
                             ),
                             hover,
                             xvar = "CE-time",
                             yvar = "M+H",
                             threshold = 5,
                             maxpoints = 1,
                             addDist = TRUE
                           )
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
                       # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                       #                 "left:", left_px + 2, "px; top:", top_px + 2, "px;")
                       
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
                               "<span class='bullText'> M+H: </span>",
                               round(point$`M+H`, 4),
                               "<br/>",
                               "<span class='bullText'> CE-time: </span>",
                               round(point$`CE-time`, 2),
                               "<br/>"
                             )
                           )))
                       
                     }
                     
                     
                   })
                 }
                 
                 shinyjs::show(id = "Idpercent_matchViewer")
                 output$percent_matchViewer <- renderDT({
                   datatable(req(RvarsMatchNewsample$res_match_ref$pct_match_ref))
                 })
                 
                 shinyjs::show("buttonNormIntensity")
                 shinyjs::enable(selector = '.navbar-nav a[data-value="Samples normalization"')
                 
               }
               
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~ matching new samples results ~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


##~~~~~~~~~~~~~~~~~~~~~~~~~~ View zoom matching ~~~~~~~~~~~~~~~~~~~~~~~~~~#

rangesZoomDeatails <- reactiveValues(x = NULL, y = NULL)

# When a double-click happens, check if there's a brush on the plot.
# If so, zoom to the brush bounds; if not, reset the zoom.
observeEvent({
  input$matchViewerNewSample_dblclick
}, {
  brush <- input$matchViewerNewSample_brush
  if (!is.null(brush)) {
    rangesZoomDeatails$x <- c(brush$xmin, brush$xmax)
    rangesZoomDeatails$y <- c(brush$ymin, brush$ymax)
  }
})

output$TableZoom <- renderDT({
  print(paste(
    "Table statut: ",
    !is.null(
      RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
    )
  ))
  if (!is.null(RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime)) {
    print(paste("Range X:", rangesZoomDeatails$x))
    print(paste("Range Y:", rangesZoomDeatails$y))
    
    if (!is.null(rangesZoomDeatails$x) &&
        !is.null(rangesZoomDeatails$y)) {
      res_Matrix_toPlot <-
        RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
      res_Matrix_toPlot <- res_Matrix_toPlot %>%
        dplyr::filter(
          `CE-time` >= req(rangesZoomDeatails$x[1]),
          `CE-time` <= req(rangesZoomDeatails$x[2])
        ) %>%
        dplyr::filter(`M+H` >= req(rangesZoomDeatails$y[1]),
                      `M+H` <= req(rangesZoomDeatails$y[2])) %>%
        dplyr::select(`M+H`, `CE-time`, M.H_newSample, CE.time_adj, Match)
      
      RvarsMatchNewsample$res_Matrix_toPlotZoomed <- res_Matrix_toPlot
      datatable(data.frame(req(res_Matrix_toPlot)))
    } else{
      res_Matrix_toPlot <-
        RvarsMatchNewsample$res_MatrixNewSampleViewer_ConvertTime
      res_Matrix_toPlot <- res_Matrix_toPlot %>%
        dplyr::select(`M+H`, `CE-time`, M.H_newSample, CE.time_adj, Match)
      
      RvarsMatchNewsample$res_Matrix_toPlotZoomed <- res_Matrix_toPlot
      datatable(data.frame(req(res_Matrix_toPlot)))
    }
    
    
  }
  
})

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$detail
             }
             ,
             handlerExpr = {
               showModal(
                 modalDialog(
                   title = "Details table",
                   
                   div(
                     id = "detailTable",
                     class = "well well-sm",
                     h4("Table"),
                     hr(),
                     
                     fluidRow(column(
                       12,
                       div(
                         class = "small",
                         DTOutput("TableZoom",
                                  width = "100%"),
                         style = "overflow: auto;"
                       )
                     ))
                   ),
                   
                   shinySaveButton(
                     id =  "SaveTableDetails",
                     label = "Save",
                     title = "Save file as...",
                     filename = "Matched-Table",
                     filetype = list(text = "csv"),
                     viewtype = "icon",
                     icon = icon("save", lib = "glyphicon"),
                     class = "btn-primary"
                   ),
                   
                   size = "l",
                   easyClose = FALSE,
                   fade = TRUE,
                   footer = modalButton("Close (Esc)")
                 )
               )
               
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Hide some panel ~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
observe({
  hide(id = "Idfeatures_matchViewer")
  hide(id = "Idpercent_matchViewer")
  hide(id = "IdBoxplotNormalizing")
  hide(id = "IdNormalizresPlot")
  #hide(id = "id_NormalizersDistribution")
})



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~~~ Normalization new samples ~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

#~~~~~~~~~~~~~~~~ Info bull for to explain the parameter cutrat ~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$click_info_cutrat
             },
             
             handlerExpr = {
               showModal(
                 modalDialog(
                   title = "Helper",
                   p(column(
                     12,
                     p(
                       "Deviation of intensity between the normalizers in the new sample and the reference."
                     ),
                     p(
                       "This parameter is used to manage the outlier normalizers, that is,
             the normalizers in the new sample that deviate too far from the reference normalizers."
                     ),
                   ),
                   br()),
                   size = "l",
                   easyClose = TRUE,
                   fade = TRUE,
                   footer = modalButton("Close (Esc)")
                 )
               )
             })



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~ Starting automatically the normalization for new samples ~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$IncludeSample
             },
             handlerExpr = {
               updateTabsetPanel(session = session,
                                 inputId = "normalizeViewer",
                                 selected = "Boxplot-intensity")
               
               RvarsNormalizeNewsample$NoSampleNormalize <- FALSE
               
               shinyjs::show("wellPanelNormIntensityOutput")
               if ((!is.null(ms_features_list_newSample_toUse()))) {
                 res_MatrixNewSample <-
                   req(RvarsMatchNewsample$res_match_ref$res_newSample)
                 
                 
                 if (ncol(res_MatrixNewSample) == 4) {
                   res_MatrixNewSample_toNormalize <-
                     cbind(
                       res_MatrixNewSample,
                       Refrence.Map = 2 ^ (RvarsPeakDetectionNewSample$map_ref$maxo)
                     )
                 } else{
                   res_MatrixNewSample_toNormalize <- res_MatrixNewSample
                 }
                 
                 RvarsNormalizeNewsample$matrix_abondance <-
                   as.matrix(res_MatrixNewSample_toNormalize[,-(1:3)])
                 
                 
                 rownames(RvarsNormalizeNewsample$matrix_abondance) <-
                   res_MatrixNewSample$ID
                 normalizers_intensity <-
                   req(RvarsPeakDetectionNewSample$map_ref$maxo)
                 names(normalizers_intensity) <-
                   RvarsPeakDetectionNewSample$map_ref$ID
                 # names(normalizers_intensity)<-req(RvarsPeakDetectionNewSample$normalizers_ref$ID)
                 source("lib/AnalysisNewSample/R_files/normalizationNewsample.lib.R",
                        local = TRUE)
                 
                 
                 RvarsNormalizeNewsample$matrix_abondance_Normalize <-
                   normalizeSamples(
                     X = req(RvarsNormalizeNewsample$matrix_abondance),
                     ref = 2 ^
                       normalizers_intensity,
                     iset.ref = req(RvarsPeakDetectionNewSample$normalizers_ref$ID),
                     min.iset = isolate(input$min_iset),
                     extrap =
                       TRUE,
                     cutrat = isolate(input$cutrat),
                     out.scale = "natural",
                     method = "lm"
                   )
                 
                 if (length(RvarsNormalizeNewsample$matrix_abondance_Normalize) !=
                     0) {
                   if (ncol(RvarsNormalizeNewsample$matrix_abondance_Normalize) !=
                       0) {
                     RvarsNormalizeNewsample$iset.normalizer.selected <-
                       attr(RvarsNormalizeNewsample$matrix_abondance_Normalize,
                            "idX_normalizers")
                     
                     if (ncol(res_MatrixNewSample) == 4) {
                       extract_OneSample <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                         extract_OneSample[,-ncol(extract_OneSample)]
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot <-
                         extract_OneSample[,-ncol(extract_OneSample)]
                       
                       idx_Duplicates_ref <-
                         unique(unlist(
                           RvarsMatchNewsample$res_match_ref$idx_Duplicates_ref
                         ))
                       
                       if (length(idx_Duplicates_ref)) {
                         RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave[RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave$ID %in% idx_Duplicates_ref,-c(1:3)] <-
                           NA
                       }
                       
                       
                     } else{
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       
                       idx_Duplicates_ref <-
                         unique(unlist(
                           RvarsMatchNewsample$res_match_ref$idx_Duplicates_ref
                         ))
                       
                       if (length(idx_Duplicates_ref)) {
                         RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave[RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave$ID %in% idx_Duplicates_ref,-c(1:3)] <-
                           NA
                       }
                     }
                     
                   } else {
                     RvarsNormalizeNewsample$matrix_abondance_Normalize <- NULL
                     RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                       NULL
                     RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlo <-
                       NULL
                     
                     output$LegendNormalizersDistributionSampleName <- renderText({})
                     output$LegendNormalizersDistribution <- renderPlot({})
                     output$NormalizersDistribution <- renderPlot({})
                   }
                 } else {
                   RvarsNormalizeNewsample$matrix_abondance_Normalize <- NULL
                   RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                     NULL
                   RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlo <-
                     NULL
                   
                   output$LegendNormalizersDistributionSampleName <- renderText({})
                   output$LegendNormalizersDistribution <- renderPlot({})
                   output$NormalizersDistribution <- renderPlot({})
                 }
                 
                 
                 
               }
               
             })



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~ When the user click the button runNormalizing ~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$runNormalizing
             }
             , {
               updateTabsetPanel(session = session,
                                 inputId = "normalizeViewer",
                                 selected = "Boxplot-intensity")
               
               RvarsNormalizeNewsample$NoSampleNormalize <- FALSE
               
               
               
               tryCatch({
                 shinyjs::show("wellPanelNormIntensityOutput")
                 # shinyjs::html("normIntensityProgress","")
                 # shinyjs::toggle(id = "idpanel_normIntensityProgress", condition = input$runNormalizing>=1)
                 # shinyjs::show("normIntensityProgressWrapper")
                 res_MatrixNewSample <-
                   RvarsMatchNewsample$res_match_ref$res_newSample
                 
                 if (ncol(res_MatrixNewSample) == 4) {
                   res_MatrixNewSample_toNormalize <-
                     cbind(
                       res_MatrixNewSample,
                       Refrence.Map = 2 ^ (RvarsPeakDetectionNewSample$map_ref$maxo)
                     )
                 } else{
                   res_MatrixNewSample_toNormalize <- res_MatrixNewSample
                 }
                 
                 RvarsNormalizeNewsample$matrix_abondance <-
                   as.matrix(res_MatrixNewSample_toNormalize[,-(1:3)])
                 rownames(RvarsNormalizeNewsample$matrix_abondance) <-
                   res_MatrixNewSample$ID
                 normalizers_intensity <-
                   RvarsPeakDetectionNewSample$map_ref$maxo
                 names(normalizers_intensity) <-
                   RvarsPeakDetectionNewSample$map_ref$ID
                 # names(normalizers_intensity)<-RvarsPeakDetectionNewSample$normalizers_ref$ID
                 source("lib/AnalysisNewSample/R_files/normalizationNewsample.lib.R",
                        local = TRUE)
                 
                 
                 RvarsNormalizeNewsample$matrix_abondance_Normalize <-
                   normalizeSamples(
                     X = RvarsNormalizeNewsample$matrix_abondance,
                     ref = 2 ^ normalizers_intensity,
                     iset.ref = req(RvarsPeakDetectionNewSample$normalizers_ref$ID),
                     min.iset = req(input$min_iset),
                     extrap = TRUE,
                     cutrat = req(input$cutrat),
                     out.scale = "naturel",
                     method = "lm"
                   )
                 
                 if (length(RvarsNormalizeNewsample$matrix_abondance_Normalize) !=
                     0) {
                   if (ncol(RvarsNormalizeNewsample$matrix_abondance_Normalize) !=
                       0) {
                     RvarsNormalizeNewsample$iset.normalizer.selected <-
                       attr(RvarsNormalizeNewsample$matrix_abondance_Normalize,
                            "idX_normalizers")
                     shinyjs::html("normIntensityProgress", "Normalizing complete !")
                     
                     if (ncol(res_MatrixNewSample) == 4) {
                       extract_OneSample <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                         extract_OneSample[,-ncol(extract_OneSample)]
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot <-
                         extract_OneSample[,-ncol(extract_OneSample)]
                       
                       idx_Duplicates_ref <-
                         unique(unlist(
                           RvarsMatchNewsample$res_match_ref$idx_Duplicates_ref
                         ))
                       
                       if (length(idx_Duplicates_ref)) {
                         RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave[RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave$ID %in% idx_Duplicates_ref,-c(1:3)] <-
                           NA
                       }
                       
                       
                       
                     } else{
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot <-
                         cbind(
                           RvarsMatchNewsample$res_match_ref$res_newSample[1:3],
                           RvarsNormalizeNewsample$matrix_abondance_Normalize
                         )
                       
                       idx_Duplicates_ref <-
                         unique(unlist(
                           RvarsMatchNewsample$res_match_ref$idx_Duplicates_ref
                         ))
                       
                       if (length(idx_Duplicates_ref)) {
                         RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave[RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave$ID %in% idx_Duplicates_ref,-c(1:3)] <-
                           NA
                       }
                     }
                   } else {
                     RvarsNormalizeNewsample$matrix_abondance_Normalize <- NULL
                     RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                       NULL
                     RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlo <-
                       NULL
                     
                     
                     output$LegendNormalizersDistributionSampleName <- renderText({})
                     output$LegendNormalizersDistribution <- renderPlot({})
                     output$NormalizersDistribution <- renderPlot({})
                   }
                 } else {
                   RvarsNormalizeNewsample$matrix_abondance_Normalize <- NULL
                   RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave <-
                     NULL
                   RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlo <-
                     NULL
                   
                   
                   output$LegendNormalizersDistributionSampleName <- renderText({})
                   output$LegendNormalizersDistribution <- renderPlot({})
                   output$NormalizersDistribution <- renderPlot({})
                 }
                 
                 
               },
               error = function(e) {
                 hide("idpanel_normIntensityProgress")
                 message("No match results !")
                 # hide("progressWrapper")
                 # hide("analysisProgress")
                 # shinyjs::html("analysisProgress",html = NULL)
                 
                 sendSweetAlert(
                   session = session,
                   title = "Warning !",
                   text = HTML(
                     "No match results ! Please upload some samples and do step 3 : match reference map.<br>",
                     "Or change the normalization parameters (please decrease the parameters : 'min normalizers', 'intensity deviation') <br>"
                   ),
                   type = "warning",
                   html = TRUE
                 )
               })
               
             })


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot results of normalization ~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
output$NormalizersDistribution <- renderPlot({
  if (!is.null(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot)) {
    if (ncol(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot) ==
        4) {
      X_data <-
        RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot
    } else{
      X_data <-
        RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot %>%
        dplyr::select(c(1:3, RvarsNormalizeNewsample$sample_ToPrint))
    }
    
    
    
    if (ncol(X_data) == 4) {
      # layout(matrix(1:8,ncol=4, byrow = TRUE))
      # par(mar=c(4,4,2,2), oma = c(0, 0, 2, 0))
      
      
      
      ID_NoNA <- X_data[!is.na(X_data[, 4]),]$ID
      if (!all(is.na(X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[1]][[1]], 4]))) {
        plot(
          x = X_data[ID_NoNA,]$`CE-time`,
          y = X_data[ID_NoNA,]$`M+H`,
          pch = 20,
          col = "gray",
          cex = 1.2,
          #0.8
          xlab = "Ce-time(second)",
          ylab = "M+H(Da)",
          main = colnames(X_data)[4],
          cex.lab = 1.5,
          #1.3
          cex.axis = 1.2,
          font.axis = 2,
          font.main = 2,
          cex.main = 1.2
        )
        grid(nx = 8)
        points(
          x = X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[1]][[1]],]$`CE-time`,
          y = X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[1]][[1]],]$`M+H`,
          pch = 20,
          col = "blue",
          cex = 1.2,
          #0.8
          # cex.lab = 1.3,
          # cex.axis = 1.2,
          # font.axis = 2
        )
      }
      
      
    } else {
      layout(matrix(1:8, ncol = 4, byrow = TRUE))
      par(mar = c(4, 4, 2, 2), oma = c(0, 0, 2, 0))
      
      if (ncol(X_data[,-c(1:3)]) < 9) {
        n <- ncol(X_data[,-c(1:3)])
      } else {
        n <- 8
      }
      
      
      for (k in 1:n) {
        ID_NoNA <- X_data[!is.na(X_data[, k + 3]),]$ID
        
        if (!all(is.na(X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]], 4:ncol(X_data)]))) {
          plot(
            x = X_data[ID_NoNA,]$`CE-time`,
            y = X_data[ID_NoNA,]$`M+H`,
            pch = 20,
            col = "gray",
            cex = 1.2,
            #0.8
            xlab = "Ce-time(second)",
            ylab = "M+H(Da)",
            main = paste("sample", k, sep = "-"),
            cex.lab = 1.5,
            #1.3
            cex.axis = 1.2,
            font.axis = 2,
            font.main = 2,
            cex.main = 1.2
          )
          points(
            x = X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]],]$`CE-time`,
            y = X_data[RvarsNormalizeNewsample$iset.normalizer.selected[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]],]$`M+H`,
            pch = 20,
            col = "blue",
            cex = 1.2,
            #0.8
            # cex.lab = 1.3,
            # cex.axis = 1.2,
            # font.axis = 2
          )
          
        }
        
      }
    }
    
    
    
  } else {
  }
  
  
})


output$LegendNormalizersDistribution <- renderPlot({
  if (!is.null(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot)) {
    data_legend <-
      data.frame(
        x = seq.int(length.out = 10),
        y = (seq.int(length.out = 10)) ^ 2,
        Legend = c(rep("Stable", 5), rep("Unstable", 5))
      )
    ggplot_legend <- ggplot(data_legend) +
      aes(x = x, y = y, colour = Legend) +
      geom_point(size = 5L) +
      scale_color_manual(values = c(Stable = "blue",
                                    Unstable = "gray")) +
      theme_ben() +
      theme(
        legend.title = element_text(
          size = rel(1.1),
          face = "bold.italic",
          hjust = 0.5
        ),
        legend.text = element_text(size = rel(0.8), face = "bold.italic"),
        legend.key = element_rect(fill = "transparent", colour = NA),
        legend.key.size = unit(0.5, "cm"),
        legend.key.width = unit(0.5, "cm"),
        legend.background = element_rect(fill = "transparent", colour = "#f7f6f1")
      )
    
    legend <- get_legend(ggplot_legend)
    grid.newpage()
    grid.draw(legend)
    
    # plot.new()
    # legend("topleft", title="Legend",
    #        c("Stable peptides", "Unstable peptides"),
    #        xjust = 0, yjust = 0, inset=0, title.adj = 0, title.font = 2,
    #        fill=c("green", "gray"), horiz=FALSE, cex=1.1, border = "white")
    
    
  } else {
    
  }
})


output$LegendNormalizersDistributionSampleName <- renderText({
  if (!is.null(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot)) {
    if (ncol(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot) >
        4) {
      Xn_legend <-
        RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toPlot[,-c(1:3)]
      Xn_legend <-
        Xn_legend[, RvarsNormalizeNewsample$sample_ToPrint[1:RvarsNormalizeNewsample$n_nrom]]
      data_legend <-
        data.frame(
          x = seq.int(length.out = ncol(Xn_legend)),
          y = (seq.int(length.out = ncol(Xn_legend))) ^
            2,
          Samples = paste(
            "\n",
            paste("sample", 1:ncol(Xn_legend), sep = "-"),
            ": ",
            colnames(Xn_legend),
            sep = ""
          )
        )
      data_legend$Samples
      
    }
  } else {
  }
})



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~ Saving results for match and normalization ~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

observe({
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
      as.character(RvarsPeakDetectionNewSample$defaultParam$mz_range_begin)
    ),
    mz_range_end = req(
      as.character(RvarsPeakDetectionNewSample$defaultParam$mz_range_end)
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
      as.character(RvarsPeakDetectionNewSample$defaultParam$min_Peakwidth)
    ),
    min_PeakHeight = req(
      as.character(RvarsPeakDetectionNewSample$defaultParam$min_PeakHeight)
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
      as.character(RvarsPeakDetectionNewSample$defaultParam$mass_tolerance)
    ),
    min_iset = req(as.character(input$min_iset)),
    cutrat = req(as.character(input$cutrat)),
    Ref = req(input$chosseRef)
  )
  
})




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Saving matching results (Matrix before normalizing intensity) ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$MatchResult
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "MatchResult",
                             roots = volumes,
                             session = session)
               
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$MatchResult)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(RvarsMatchNewsample$res_match_ref) &
                     !is.null(RvarsPeakDetectionNewSample$map_ref)) {
                   input_Matrix <- RvarsMatchNewsample$res_match_ref$res_newSample
                   
                   
                   idx_Duplicates_ref <-
                     unique(unlist(RvarsMatchNewsample$res_match_ref$idx_Duplicates_ref))
                   
                   if (length(idx_Duplicates_ref)) {
                     input_Matrix[input_Matrix$ID %in% idx_Duplicates_ref, -c(1:3)] <- NA
                   }
                   input_Matrix[input_Matrix$ID %in% idx_Duplicates_ref, -c(1:3)] <-
                     NA
                   
                   
                   colnames(input_Matrix)[1:3] <- c("ID", "M+H",	"CE-time")
                   
                   write.table(
                     input_Matrix,
                     file = paste0(c(
                       directory_Save_Files,
                       paste(path_Save_Files[length(path_Save_Files)],
                             collapse = "", sep = "-")
                     ), collapse = "/"),
                     sep = ",",
                     row.names = FALSE
                   )
                   print("Save ok")
                   
                 }
                 
               }
               
               
             })

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Saving detail table ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveTableDetails
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "SaveTableDetails",
                             roots = volumes,
                             session = session)
               
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$SaveTableDetails)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(RvarsMatchNewsample$res_Matrix_toPlotZoomed) &
                     !is.null(input$levelSampleMatch)) {
                   RvarsMatchNewsample$res_Matrix_toPlotZoomed$sample <-
                     input$levelSampleMatch
                   
                   
                   write.table(
                     RvarsMatchNewsample$res_Matrix_toPlotZoomed,
                     file = paste0(c(
                       directory_Save_Files,
                       paste(
                         input$levelSampleMatch,
                         path_Save_Files[length(path_Save_Files)],
                         collapse = "",
                         sep = "-"
                       )
                     ), collapse = "/"),
                     sep = ",",
                     row.names = FALSE
                   )
                   print("OK")
                   print("Save ok")
                   
                   
                 }
               }
               
               
             })

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Saving normalize matrix ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveAnalysisResults
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "SaveAnalysisResults",
                             roots = volumes,
                             session = session)
               
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$SaveAnalysisResults)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(ms_features_newSample()) &
                     !is.null(input$IncludeSample) &
                     (length(ms_features_list_newSample_toUse()) >= 1) &
                     !is.null(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave)) {
                   colnames(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave)[2] <-
                     "M+H"
                   colnames(RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave)[3] <-
                     "CE-time"
                   
                   write.table(
                     RvarsNormalizeNewsample$res_MatrixNewSample_normalized_toSave,
                     file = paste0(c(
                       directory_Save_Files,
                       paste(path_Save_Files[length(path_Save_Files)],
                             collapse = "", sep = "-")
                     ), collapse = "/"),
                     sep = ",",
                     row.names = FALSE
                   )
                   print("Save ok")
                   
                   
                 }
               }
               
               
             })



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Export percentage match table ~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
## Export direct de la table affichée dans l'onglet "Percentage match"
## (sample, percent_matched, number_match), telle quelle.
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ExportPercentMatch_newSample
             },
             handlerExpr = {
               shinyFileSave(input,
                             id = "ExportPercentMatch_newSample",
                             roots = volumes,
                             session = session)
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$ExportPercentMatch_newSample)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 pct_match_df <- RvarsMatchNewsample$res_match_ref$pct_match_ref
                 if (is.null(pct_match_df)) {
                   showNotification("Aucune table de pourcentage de match disponible.",
                                    type = "error", duration = 8)
                   return()
                 }
                 
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 write.table(
                   pct_match_df,
                   file = paste0(c(
                     directory_Save_Files,
                     paste(path_Save_Files[length(path_Save_Files)],
                           collapse = "", sep = "-")
                   ), collapse = "/"),
                   sep = ",",
                   row.names = FALSE
                 )
                 showNotification("Table de pourcentage de match exportée.", type = "message", duration = 6)
               }
             })
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Export bilan par run ~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
## Table combinée, une ligne par échantillon : nombre de features, pourcentage
## de match avec la carte de référence, nombre de normalisateurs utilisés, et
## si l'échantillon a été normalisé ou non (même seuil que normalizeSamples() :
## nbr_pep_normalizers >= min.iset). Ces 3 derniers calculs existent déjà en
## interne (pct_match_ref, attr(...,"nbr_pep_normalizers")) mais n'étaient
## jusqu'ici jamais exportés.
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ExportRunSummary_newSample
             },
             handlerExpr = {
               shinyFileSave(input,
                             id = "ExportRunSummary_newSample",
                             roots = volumes,
                             session = session)
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$ExportRunSummary_newSample)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 if (is.null(RvarsPeakDetectionNewSample$FeaturesList_newSample)) {
                   showNotification("Aucune feature list disponible.", type = "error", duration = 8)
                   return()
                 }
                 
                 n_features <- sapply(RvarsPeakDetectionNewSample$FeaturesList_newSample, nrow)
                 bilan <- data.frame(
                   Sample = names(n_features),
                   Nombre_features = unname(n_features),
                   stringsAsFactors = FALSE
                 )
                 
                 pct_match_df <- RvarsMatchNewsample$res_match_ref$pct_match_ref
                 if (!is.null(pct_match_df)) {
                   bilan <- merge(
                     bilan,
                     data.frame(
                       Sample = as.character(pct_match_df$sample),
                       Pourcentage_match = pct_match_df$percent_matched,
                       stringsAsFactors = FALSE
                     ),
                     by = "Sample", all.x = TRUE
                   )
                 } else {
                   bilan$Pourcentage_match <- NA
                 }
                 
                 if (!is.null(RvarsNormalizeNewsample$matrix_abondance) &&
                     !is.null(RvarsPeakDetectionNewSample$normalizers_ref) &&
                     !is.null(RvarsPeakDetectionNewSample$map_ref) &&
                     !is.null(pct_match_df)) {
                   
                   Xraw <- RvarsNormalizeNewsample$matrix_abondance
                   if (max(Xraw, na.rm = TRUE) > 107) Xraw <- log2(Xraw)
                   
                   ref_vec <- RvarsPeakDetectionNewSample$map_ref$maxo
                   names(ref_vec) <- RvarsPeakDetectionNewSample$map_ref$ID
                   
                   iset_ref <- as.character(req(RvarsPeakDetectionNewSample$normalizers_ref$ID))
                   iset_ref <- intersect(iset_ref, rownames(Xraw))
                   cutrat_val <- req(input$cutrat)
                   
                   nbr_norm_vec <- sapply(seq_len(ncol(Xraw)), function(i) {
                     iset_i <- iset_ref[abs(Xraw[iset_ref, i] - ref_vec[iset_ref]) <= cutrat_val]
                     sum(!is.na(Xraw[iset_i, i]))
                   })
                   
                   if (length(nbr_norm_vec) == nrow(pct_match_df)) {
                     nbr_norm_df <- data.frame(
                       Sample = as.character(pct_match_df$sample),
                       Nombre_normalisateurs = nbr_norm_vec,
                       stringsAsFactors = FALSE
                     )
                     bilan <- merge(bilan, nbr_norm_df, by = "Sample", all.x = TRUE)
                     bilan$Normalisation_OK <- bilan$Nombre_normalisateurs >= req(input$min_iset)
                   } else {
                     bilan$Nombre_normalisateurs <- NA
                     bilan$Normalisation_OK <- NA
                   }
                 } else {
                   cat("on est dans le else pour nbr_norm \n")
                   bilan$Nombre_normalisateurs <- NA
                   bilan$Normalisation_OK <- NA
                 }
                 
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 write.table(
                   bilan,
                   file = paste0(c(
                     directory_Save_Files,
                     paste(path_Save_Files[length(path_Save_Files)],
                           collapse = "", sep = "-")
                   ), collapse = "/"),
                   sep = ",",
                   row.names = FALSE
                 )
                 showNotification("Bilan par run exporté.", type = "message", duration = 6)
               }
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Saving parameters ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
output$ExportParam <- downloadHandler(
  filename = function() {
    paste(
      "Parsmeters used-",
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
      ".txt",
      sep = ""
    )
  },
  content = function(file) {
    exportParam <-
      readLines(file.path("data/References", req(input$chosseRef), "outputParam.txt"))
    
    writeLines(exportParam, file)
  }
)





observe({
  if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list) ||
      !is.null(RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection)) {
    shinyjs::show("peakListToSave")
  }
})


#~~~~~~~~~~~~~ Saving massif list(before CE-time correction) ~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$PeakListNewSample
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "PeakListNewSample",
                             roots = volumes,
                             session = session)
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$PeakListNewSample)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list)) {
                   massifListBefore <-
                     RvarsPeakDetectionNewSample$peaks_mono_iso_newSample_list
                   
                   for (i in 1:length(massifListBefore)) {
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
                     
                     colnames(massifListBefore[[i]])[c(1:10)] <- reqColsNames
                   }
                   
                   
                   if (length(massifListBefore) == 1) {
                     write.table(
                       massifListBefore[[1]],
                       #file = path_Save_Files_origine,
                       file = paste0(c(
                         directory_Save_Files,
                         paste(
                           names(massifListBefore)[1],
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
                       for (i in 1:length(massifListBefore)) {
                         incProgress(1 / length(massifListBefore),
                                     detail = paste(names(massifListBefore)[i]))
                         print(basename(paste0(
                           c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(massifListBefore)[i],
                               path_Save_Files[length(path_Save_Files)],
                               collapse = "",
                               sep = "-"
                             )
                           ), collapse = "/"
                         )))
                         write.table(
                           massifListBefore[[i]],
                           file = paste0(c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(massifListBefore)[i],
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

#~~~~~~~~~~~~~ Saving massif list(after CE-time correction) ~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$PeakListAlignedNewSample
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "PeakListAlignedNewSample",
                             roots = volumes,
                             session = session)
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$PeakListAlignedNewSample)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection)) {
                   massifListAfter <-
                     RvarsPeakDetectionNewSample$peaks_newSample_list_KernelDensityCorrection
                   
                   for (i in 1:length(massifListAfter)) {
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
                     
                     colnames(massifListAfter[[i]])[c(1:10)] <- reqColsNames
                   }
                   
                   
                   if (length(massifListAfter) == 1) {
                     write.table(
                       massifListAfter[[1]],
                       #file = path_Save_Files_origine,
                       file = paste0(c(
                         directory_Save_Files,
                         paste(
                           names(massifListAfter)[1],
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
                       for (i in 1:length(massifListAfter)) {
                         incProgress(1 / length(massifListAfter),
                                     detail = paste(names(massifListAfter)[i]))
                         print(basename(paste0(
                           c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(massifListAfter)[i],
                               path_Save_Files[length(path_Save_Files)],
                               collapse = "",
                               sep = "-"
                             )
                           ), collapse = "/"
                         )))
                         write.table(
                           massifListAfter[[i]],
                           file = paste0(c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(massifListAfter)[i],
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


