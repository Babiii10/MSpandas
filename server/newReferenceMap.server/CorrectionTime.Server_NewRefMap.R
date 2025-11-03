##" Initialize reactive values
RvarsCorrectionTime <- allReactiveVarsNewRefMap$CorrectionTime

## Initialize plot update trigger to fix memory leak
## (prevents renderPlot() recreation inside observeEvent)
plotUpdateTrigger_KernelDensity <- reactiveVal(0)

## Track corrected samples for validation button
correctedSamples_KernelDensity <- reactiveVal(character(0))

## ~~~~~~~~~~~~Control some buttons ~~~~~~~~~~~~~~~~~~~~~~~~~#
### Return to view peak detection
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturnToPeakViewer
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "NewRefrenceMapStep",
                                  selected = "2")
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Peak detection")
               
             })

### Go to select reference sample
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GoToSelectRefranceSample
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "2")
               
               
             })

### Return to retention time filtering
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturnToFilteringSample
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "1")
               # updateNavbarPage(
               #   session = session,
               #   inputId = "analysisNavbar",
               #   selected = "Peak detection"
               # )
               
             })

### Got to correction time xcms
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$RefrenceSampleNextPage
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "3")
             })


## Return to XCMS correction
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturToCorrectionXCMS
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "2")
             })

## Go to correction with Kernel Density
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$CorrectionXCMSNexPage
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "4")
             })
## Return to Correction time viewer
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturToViewCorrectionXCMS
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "3")
             })

## Go to Generate reference Map
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$CorrectionKernelDensityNexPage
             }
             ,
             handlerExpr = {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Generate the reference map")
               
             })





### Reset some input when changing input "IncludeSample_NewRefMap"
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$IncludeSample_NewRefMap
             }
             , {
               #~~~~~~~~~~~~~~ cut sample reset ~~~~~~~~~~~~~~~~~~~~~~~#
               enable("RetentionTimeFiltering_id")
               hide("id_ResetCuttingRun")
               shinyjs::show("id_validCuttingRun")
               disable("SaveCuttingSample")
               shinyjs::reset("rt_min_cut")
               shinyjs::reset("rt_max_cut")
               disable("GoToSelectRefranceSample")
               disable("id_SelectRefrenceSamplePanel")
               
               
               if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
                 RvarsCorrectionTime$samplesCuttingTable <-
                   data.frame(
                     row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
                     rt_min_cut = rep(NA, length(peaks_mono_iso_toUsed_NewRefMap())),
                     rt_max_cut = rep(NA, length(peaks_mono_iso_toUsed_NewRefMap())),
                     Unit = rep("Second", length(peaks_mono_iso_toUsed_NewRefMap()))
                   )
               }
               
               updateAwesomeRadio(session = session,
                                  inputId = "UnitTime_sampleCutting",
                                  selected = "Second")
               RvarsCorrectionTime$Second_Cutting <- TRUE
               
               ##~~~~~~~~~~~~~~~~~~ reset reference sample~~~~~~~~~~~~~~~~~~~~~~#
               hide("resetRefrenceSample")
               shinyjs::show("ConfirmRefrenceSample")
               
               shinyjs::show("id_plotRefrenceSample")
               enable("id_SelectRefrenceSamplePanel")
               disable("id_Panel_runCorrectionTime")
               hide("id_Panel_runCorrectionTime")
               hide("id_PanelDamplesInfo")
               hide("id_PanelParametersGenerateMap")
               hide("id_runProcess")
               
               hide("Id_SampleOffset")
               hide("IDoffsetSamplePlot_div")
               
               disable("RefrenceSampleNextPage")
               
               shinyjs::show("id_PanelcutOff_sample_NewRefMap")
               if (input$SelectRefrenceSample == 2) {
                 disable("ConfirmRefrenceSample")
               }
               
               
             })

observe({
  if (is.null(input$IncludeSample_NewRefMap)) {
    #~~~~~~~~~~~~~~ cut sample reset ~~~~~~~~~~~~~~~~~~~~~~~#
    enable("RetentionTimeFiltering_id")
    hide("id_ResetCuttingRun")
    shinyjs::show("id_validCuttingRun")
    disable("SaveCuttingSample")
    shinyjs::reset("rt_min_cut")
    shinyjs::reset("rt_max_cut")
    disable("GoToSelectRefranceSample")
    disable("id_SelectRefrenceSamplePanel")
    
    
    if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
      RvarsCorrectionTime$samplesCuttingTable <-
        data.frame(
          row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
          rt_min_cut = rep(NA, length(
            peaks_mono_iso_toUsed_NewRefMap()
          )),
          rt_max_cut = rep(NA, length(
            peaks_mono_iso_toUsed_NewRefMap()
          )),
          Unit = rep("Second", length(
            peaks_mono_iso_toUsed_NewRefMap()
          ))
        )
    }
    
    updateAwesomeRadio(session = session,
                       inputId = "UnitTime_sampleCutting",
                       selected = "Second")
    RvarsCorrectionTime$Second_Cutting <- TRUE
    
    ##~~~~~~~~~~~~~~~~~~ reset reference sample~~~~~~~~~~~~~~~~~~~~~~#
    hide("resetRefrenceSample")
    shinyjs::show("ConfirmRefrenceSample")
    
    shinyjs::show("id_plotRefrenceSample")
    enable("id_SelectRefrenceSamplePanel")
    disable("id_Panel_runCorrectionTime")
    hide("id_Panel_runCorrectionTime")
    hide("id_PanelDamplesInfo")
    hide("id_PanelParametersGenerateMap")
    hide("id_runProcess")
    
    hide("Id_SampleOffset")
    hide("IDoffsetSamplePlot_div")
    
    shinyjs::show("id_PanelcutOff_sample_NewRefMap")
    
    if (length(input$SelectRefrenceSample) != 0) {
      if (input$SelectRefrenceSample == 2) {
        disable("ConfirmRefrenceSample")
      }
    }
    
  }
})




##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Samples filter Server~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

##~~~~~~~~~~~~~~~~~~~~~~~ Upload samples to cut ~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$massif_list_NewRefMap
             }
             , {
               files <- input$massif_list_NewRefMap
               ext <- tools::file_ext(files$datapath)
               reqCols <-
                 c(
                   'M.H',
                   'M.H.min',
                   'M.H.max',
                   'CE.time',
                   'CE.time.min',
                   'CE.time.max',
                   'integrated.intensity',
                   'intensity',
                   'sn',
                   'sample',
                   'iso.mass',
                   'iso.mass.link',
                   'mz_PeaksIsotopics_Group',
                   'rt_PeaksIsotopics_Group',
                   'Height_PeaksIsotopics_Group',
                   "Adduct"
                 )
               
               reqColsUsed <- c(
                 'mz',
                 'mzmin',
                 'mzmax',
                 'rt',
                 'rtmin',
                 'rtmax',
                 'into',
                 'maxo',
                 'sn',
                 'sample',
                 'iso.mass',
                 'iso.mass.link',
                 'mz_PeaksIsotopics_Group',
                 'rt_PeaksIsotopics_Group',
                 'Height_PeaksIsotopics_Group',
                 "Adduct"
               )
               
               reqColsMess <-
                 " 'M+H', 'M+H.min', 'M+H.max', 'CE-time', 'CE-time.min', 'CE-time.max',
                   'integrated-intensity', 'intensity', 'sn', 'sample'
                   'iso.mass','iso.mass.link','mz_PeaksIsotopics_Group',
               'rt_PeaksIsotopics_Group','Height_PeaksIsotopics_Group', 'Adduct'"
               
               if (length(ext) > 1) {
                 if (all.equal(ext, rep("csv", length(ext))) != TRUE) {
                   message("Please upload a csv file...!")
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning",
                     width = "80%"
                   )
                 } else {
                   a <- lapply(input$massif_list_NewRefMap$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste(
                         "Required columns :",
                         reqColsMess,
                         "not found in files.",
                         sep = " "
                       ),
                       type = "warning",
                       width = "80%"
                     )
                   })
                   
                   if (!all(reqCols %in% colnames(a))) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste(
                         "Required columns :",
                         reqColsMess,
                         "not found in files.",
                         sep = " "
                       ),
                       type = "warning",
                       width = "80%"
                     )
                   } else {
                     a <- a[, reqCols]
                     colnames(a) <- reqColsUsed
                     RvarsPeakDetection$peaks_MSDIAL_mono_iso_NewRefMap <-
                       a
                     
                     # Lunch the Reset button
                     enable("RetentionTimeFiltering_id")
                     hide("id_ResetCuttingRun")
                     shinyjs::show("id_validCuttingRun")
                     disable("SaveCuttingSample")
                     shinyjs::reset("rt_min_cut")
                     shinyjs::reset("rt_max_cut")
                     disable("GoToSelectRefranceSample")
                     disable("id_SelectRefrenceSamplePanel")
                     
                     
                     if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
                       RvarsCorrectionTime$samplesCuttingTable <-
                         data.frame(
                           row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
                           rt_min_cut = rep(NA, length(
                             peaks_mono_iso_toUsed_NewRefMap()
                           )),
                           rt_max_cut = rep(NA, length(
                             peaks_mono_iso_toUsed_NewRefMap()
                           )),
                           Unit = rep(
                             "Second",
                             length(peaks_mono_iso_toUsed_NewRefMap())
                           )
                         )
                     }
                     
                     updateAwesomeRadio(session = session,
                                        inputId = "UnitTime_sampleCutting",
                                        selected = "Second")
                     RvarsPeakDetection$Second <- TRUE
                     
                     RvarsCorrectionTime$Ref_Mdian_samplePeaks <-
                       NULL
                     
                     shinyjs::show("Id_resetAll_NewRefMap_PeakDetectionView")
                   }
                   
                 }
               } else {
                 if (ext != "csv") {
                   message("Please upload a csv file...!")
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning",
                     width = "80%"
                   )
                 } else {
                   a <- lapply(input$massif_list_NewRefMap$datapath, read.csv)
                   tryCatch({
                     a <- do.call("rbind", a)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste(
                         "Required columns :",
                         reqColsMess,
                         "not found in files.",
                         sep = " "
                       ),
                       type = "warning",
                       width = "80%"
                     )
                   })
                   
                   if (!all(reqCols %in% colnames(a))) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste(
                         "Required columns :",
                         reqColsMess,
                         "not found in files.",
                         sep = " "
                       ),
                       type = "warning",
                       width = "80%"
                     )
                   } else {
                     a <- a[, reqCols]
                     colnames(a) <- reqColsUsed
                     RvarsPeakDetection$peaks_MSDIAL_mono_iso_NewRefMap <-
                       a
                     
                     # Lunch the Reset button
                     enable("RetentionTimeFiltering_id")
                     hide("id_ResetCuttingRun")
                     shinyjs::show("id_validCuttingRun")
                     disable("SaveCuttingSample")
                     shinyjs::reset("rt_min_cut")
                     shinyjs::reset("rt_max_cut")
                     disable("GoToSelectRefranceSample")
                     disable("id_SelectRefrenceSamplePanel")
                     
                     
                     if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
                       RvarsCorrectionTime$samplesCuttingTable <-
                         data.frame(
                           row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
                           rt_min_cut = rep(NA, length(
                             peaks_mono_iso_toUsed_NewRefMap()
                           )),
                           rt_max_cut = rep(NA, length(
                             peaks_mono_iso_toUsed_NewRefMap()
                           )),
                           Unit = rep(
                             "Second",
                             length(peaks_mono_iso_toUsed_NewRefMap())
                           )
                         )
                     }
                     
                     updateAwesomeRadio(session = session,
                                        inputId = "UnitTime_sampleCutting",
                                        selected = "Second")
                     RvarsPeakDetection$Second <- TRUE
                     
                     RvarsCorrectionTime$Ref_Mdian_samplePeaks <-
                       NULL
                     
                     shinyjs::show("Id_resetAll_NewRefMap_PeakDetectionView")
                   }
                 }
               }
               
               
             })


# Features table
observe({
  if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
    RvarsCorrectionTime$samplesCuttingTable <-
      data.frame(
        row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
        rt_min_cut = rep(NA, length(peaks_mono_iso_toUsed_NewRefMap())),
        rt_max_cut = rep(NA, length(peaks_mono_iso_toUsed_NewRefMap())),
        Unit = rep("Second", length(peaks_mono_iso_toUsed_NewRefMap()))
      )
    
    
    
    updatePickerInput(
      session = session,
      inputId = "sample_selectedCutting",
      choices = names(peaks_mono_iso_toUsed_NewRefMap())
    )
    
    
  } else{
    updatePickerInput(
      session = session,
      inputId = "sample_selectedCutting",
      choices = character(0),
      selected = character(0)
    )
    
    RvarsCorrectionTime$samplesCuttingTable <- NULL
  }
})


## used for the plot

sample_cutting <- reactive({
  sample_cutting_rv <-
    req(peaks_mono_iso_toUsed_NewRefMap()[input$sample_selectedCutting][[1]])
  colnames(sample_cutting_rv)[c(1, 4, 8)] <-
    c("M.H", "CE.time", "intensity")
  sample_cutting_rv$intensity <- log2(sample_cutting_rv$intensity)
  sample_cutting_rv
  
})


##~~~~~~~~~~~~~~~~~~~~~~~ CE-time conversion for plot ~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting
             },
             handlerExpr = {
               RvarsCorrectionTime$sample_cutting_viewer_ConvertTime <-
                 req(peaks_mono_iso_toUsed_NewRefMap()[input$sample_selectedCutting][[1]])
               colnames(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)[c(1, 4, 8)] <-
                 c("M.H", "CE.time", "intensity")
               RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$intensity <-
                 log2(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$intensity)
               
               
               
               #Because les data viennent initialement en second
               RvarsCorrectionTime$Second_Cutting <- TRUE
               if (input$UnitTime_sampleCutting == "Minute") {
                 #RvarsCorrectionTime$peaks_mono_iso_NewRefMap_toPlot_ConvertTime<-peaks_mono_iso_NewRefMap_toPlot()
                 print(
                   paste(
                     "Convert to min",
                     input$UnitTime_sampleCutting == "Minute" &
                       RvarsCorrectionTime$Second_Cutting == TRUE
                   )
                 )
                 if (input$UnitTime_sampleCutting == "Minute" &
                     RvarsCorrectionTime$Second_Cutting == TRUE) {
                   if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                     RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time <-
                       req(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time) / 60
                     RvarsCorrectionTime$Second_Cutting <- FALSE
                   }
                 }
               }
               
               if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 3] <-
                   input$UnitTime_sampleCutting
                 
               }
             })

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$UnitTime_sampleCutting
             },
             handlerExpr = {
               print(
                 paste(
                   "Convert to min",
                   input$UnitTime_sampleCutting == "Minute" &
                     RvarsCorrectionTime$Second_Cutting == TRUE
                 )
               )
               if (isolate(input$UnitTime_sampleCutting) == "Minute" &
                   RvarsCorrectionTime$Second_Cutting == TRUE) {
                 if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                   RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time <-
                     req(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time) /
                     60
                   RvarsCorrectionTime$Second_Cutting <- FALSE
                 }
               }
               
               print(
                 paste(
                   "Covert to Second",
                   input$UnitTime_sampleCutting == "Second" &
                     RvarsCorrectionTime$Second_Cutting == FALSE
                 )
               )
               if (isolate(input$UnitTime_sampleCutting) == "Second" &
                   RvarsCorrectionTime$Second_Cutting == FALSE) {
                 if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                   RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time <-
                     req(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime$CE.time) *
                     60
                   RvarsCorrectionTime$Second_Cutting <- TRUE
                 }
               }
               
               if (input$UnitTime_sampleCutting == "Second" &
                   RvarsCorrectionTime$Second_Cutting == TRUE) {
                 RvarsCorrectionTime$sample_cutting_viewer_ConvertTime <-
                   req(sample_cutting())
               }
               
               if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 3] <-
                   input$UnitTime_sampleCutting
                 
               }
               
               
             })

##~~~~~~~~~~~~~~~~~~~~~~~ Cut samples and Plot ~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
rangesZoomSample_selectedCutting <-
  reactiveValues(x = NULL, y = NULL)

# When a double-click happens, check if there's a brush on the plot.
# If so, zoom to the brush bounds; if not, reset the zoom.
observeEvent({
  input$sample_selectedCutting_dblclick
}, {
  brush <- input$sample_selectedCutting_brush
  if (!is.null(brush)) {
    rangesZoomSample_selectedCutting$x <- c(brush$xmin, brush$xmax)
    rangesZoomSample_selectedCutting$y <- c(brush$ymin, brush$ymax)
    
  } else {
    ## reset coord_cartesian
    rangesZoomSample_selectedCutting$x <- NULL
    rangesZoomSample_selectedCutting$y <- NULL
  }
})


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting
             },
             handlerExpr = {
               updateNumericInput(
                 session = session,
                 inputId = "rt_min_cut",
                 value = RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut
               )
               
               updateNumericInput(
                 session = session,
                 inputId = "rt_max_cut",
                 value = RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut
               )
               
               
             })


observe({
  if (!is.null(input$sample_selectedCutting)) {
    if (!is.null(peaks_mono_iso_toUsed_NewRefMap()[input$sample_selectedCutting][[1]])) {
      if (is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut) &
          is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut)) {
        print("Sample selected not cutted")
        if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
          RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 1:2] <-
            c(NA, NA)
          
        }
        
        
        
        
        output$sample_selectedCutting_Plot <- renderPlot({
          if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
            shinyjs::show("UnitTime_sampleCutting_id")
            shinyjs::show("mousepositionSampleCutting")
            
            RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
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
                req(input$UnitTime_sampleCutting),
                ")"
              )) +
              coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                              ylim = rangesZoomSample_selectedCutting$y,
                              expand = TRUE) +
              ggtitle(paste(
                "Sample selected :",
                input$sample_selectedCutting,
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
                plot.subtitle = element_text(hjust = 0.5),
                plot.background = element_rect(fill = "aliceblue")
              )
            
          }
          
          
          
        })
        
        ## Mouse position
        # output$sample_selectedCutting_Plot_info <- renderText({
        #   paste0("Mouse position : ",
        #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
        #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
        # })
        
        output$sample_selectedCutting_Plot_info <- renderText({
          paste0(
            "Mouse position : ",
            xy_str(
              input$sample_selectedCutting_hover,
              "CE-time",
              "M+H"
            ),
            "Click: ",
            xy_str(
              input$sample_selectedCutting_click,
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
        output$sample_selectedCutting_hover_info <- renderUI({
          hover <- req(input$sample_selectedCutting_hover)
          
          if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
            point <-
              nearPoints(
                req(
                  RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                    round(point$M.H, 4),
                    "<br/>",
                    "<span class='bullText'> CE-time: </span>",
                    round(point$CE.time, 2),
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
    } else {
      output$sample_selectedCutting_Plot <- renderPlot({
        
      })
      output$sample_selectedCutting_Plot_info <- renderText({
        
      })
      output$sample_selectedCutting_hover_info <- renderUI({
        
      })
      hide("UnitTime_sampleCutting_id")
    }
  } else {
    output$sample_selectedCutting_Plot <- renderPlot({
      
    })
  }
  
  
})

###~~~~~~~~~~~~~~~~~~ button cut~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$cutOff
             },
             handlerExpr = {
               if (!is.null(peaks_mono_iso_toUsed_NewRefMap()[input$sample_selectedCutting][[1]])) {
                 if (!is.na(input$rt_min_cut) & !is.na(input$rt_max_cut)) {
                   print("cutoff")
                   output$sample_selectedCutting_Plot <-
                     renderPlot({
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         shinyjs::show("UnitTime_sampleCutting_id")
                         shinyjs::show("mousepositionSampleCutting")
                         
                         RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_min_cut),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           geom_vline(
                             xintercept = isolate(input$rt_max_cut),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = c(0, isolate(input$rt_max_cut)),
                             xmax = c(isolate(input$rt_min_cut), Inf),
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste("CE-time (", req(input$UnitTime_sampleCutting), ")")) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                           ylim = rangesZoomSample_selectedCutting$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             input$sample_selectedCutting,
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
                             plot.subtitle = element_text(hjust = 0.5),
                             plot.background = element_rect(fill = "aliceblue")
                           )
                       }
                       
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(input$sample_selectedCutting_hover, "CE-time", "M+H"),
                         "Click: ",
                         xy_str(input$sample_selectedCutting_click, "CE-time", "M+H")
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover)
                       
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         point <-
                           nearPoints(
                             req(
                               RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                             "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
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
                   
                   if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                     RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 1:2] <-
                       c(isolate(input$rt_min_cut),
                         isolate(input$rt_max_cut))
                   }
                   
                 } else if (!is.na(input$rt_min_cut) &
                            is.na(input$rt_max_cut)) {
                   print("cutoff")
                   output$sample_selectedCutting_Plot <-
                     renderPlot({
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         shinyjs::show("UnitTime_sampleCutting_id")
                         shinyjs::show("mousepositionSampleCutting")
                         
                         RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_min_cut),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = 0,
                             xmax = isolate(input$rt_min_cut),
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste("CE-time (", req(input$UnitTime_sampleCutting), ")")) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                           ylim = rangesZoomSample_selectedCutting$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             input$sample_selectedCutting,
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
                             plot.subtitle = element_text(hjust = 0.5),
                             plot.background = element_rect(fill = "aliceblue")
                           )
                         
                       }
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(input$sample_selectedCutting_hover, "CE-time", "M+H"),
                         "Click: ",
                         xy_str(input$sample_selectedCutting_click, "CE-time", "M+H")
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover)
                       
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         point <-
                           nearPoints(
                             req(
                               RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                             "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
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
                   
                   if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                     RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 1:2] <-
                       c(isolate(input$rt_min_cut), NA)
                   }
                   
                   
                 } else if (is.na(input$rt_min_cut) &
                            !is.na(input$rt_max_cut)) {
                   print("cutoff")
                   output$sample_selectedCutting_Plot <-
                     renderPlot({
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         shinyjs::show("UnitTime_sampleCutting_id")
                         shinyjs::show("mousepositionSampleCutting")
                         
                         RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                           ggplot() +
                           aes(x = CE.time,
                               y = M.H,
                               colour = intensity) +
                           #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                           geom_point(size = 1) +
                           geom_vline(
                             xintercept = isolate(input$rt_max_cut),
                             color = "gray",
                             linetype = "dashed"
                           ) +
                           ggplot2::annotate(
                             "rect",
                             xmin = isolate(input$rt_max_cut),
                             xmax = Inf,
                             ymin = -Inf ,
                             ymax = Inf,
                             alpha = 0.5,
                             fill = "gray"
                           ) +
                           scale_color_viridis_c(option = "inferno", direction = -1) +
                           ylab("Mass (M+H) (Da)") +
                           xlab(paste("CE-time (", req(input$UnitTime_sampleCutting), ")")) +
                           coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                           ylim = rangesZoomSample_selectedCutting$y,
                                           expand = TRUE) +
                           ggtitle(paste(
                             "Sample selected :",
                             input$sample_selectedCutting,
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
                             plot.subtitle = element_text(hjust = 0.5),
                             plot.background = element_rect(fill = "aliceblue")
                           )
                       }
                     })
                   
                   ## Mouse position
                   # output$sample_selectedCutting_Plot_info <- renderText({
                   #   paste0("Mouse position : ",
                   #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                   #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                   # })
                   
                   output$sample_selectedCutting_Plot_info <-
                     renderText({
                       paste0(
                         "Mouse position: ",
                         xy_str(input$sample_selectedCutting_hover, "CE-time", "M+H"),
                         "Click: ",
                         xy_str(input$sample_selectedCutting_click, "CE-time", "M+H")
                       )
                       # paste0("Mouse position : ",
                       #        "\n CE-time = ", round(req(input$sample_selectedCutting_hover$x),0)," (",req(input$UnitTime_sampleCutting),")",
                       #        "\n M+H = ", round(req(input$sample_selectedCutting_hover$y),4),(" (Da)"))
                     })
                   
                   ## Bulle info
                   
                   #### info-bulle
                   output$sample_selectedCutting_hover_info <-
                     renderUI({
                       hover <- req(input$sample_selectedCutting_hover)
                       
                       if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                         point <-
                           nearPoints(
                             req(
                               RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                             "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                 round(point$M.H, 4),
                                 "<br/>",
                                 "<span class='bullText'> CE-time: </span>",
                                 round(point$CE.time, 2),
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
                   
                   if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                     RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 1:2] <-
                       c(NA, isolate(input$rt_max_cut))
                   }
                   
                   
                 } else  if (is.na(input$rt_min_cut) &
                             is.na(input$rt_max_cut)) {
                   if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                     RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting, 1:2] <-
                       c(NA, NA)
                     
                   }
                 }
                 
               } else {
                 output$sample_selectedCutting_Plot <- renderPlot({
                   
                 })
                 output$sample_selectedCutting_Plot_info <-
                   renderText({
                     
                   })
                 output$sample_selectedCutting_hover_info <-
                   renderUI({
                     
                   })
                 hide("UnitTime_sampleCutting_id")
               }
               
             })

###~~~~~~~~~~~~Keep cut sample when choice a new sample~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting
             },
             handlerExpr = {
               updateNumericInput(
                 session = session,
                 inputId = "rt_min_cut",
                 value = as.numeric(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut)
               )
               
               updateNumericInput(
                 session = session,
                 inputId = "rt_max_cut",
                 value = as.numeric(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut)
               )
             })


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$sample_selectedCutting
             },
             handlerExpr = {
               if (!is.null(peaks_mono_iso_toUsed_NewRefMap()[input$sample_selectedCutting][[1]])) {
                 if (!is.null(RvarsCorrectionTime$samplesCuttingTable)) {
                   if (!is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut) &
                       !is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut)) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot <-
                       renderPlot({
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           shinyjs::show("UnitTime_sampleCutting_id")
                           shinyjs::show("mousepositionSampleCutting")
                           
                           RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = c(
                                 0,
                                 as.numeric(
                                   RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut
                                 )
                               ),
                               xmax = c(
                                 as.numeric(
                                   RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut
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
                               req(input$UnitTime_sampleCutting),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                             ylim = rangesZoomSample_selectedCutting$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               input$sample_selectedCutting,
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
                               plot.subtitle = element_text(hjust = 0.5),
                               plot.background = element_rect(fill = "aliceblue")
                             )
                         }
                         
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click,
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
                     output$sample_selectedCutting_hover_info <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover)
                         
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           point <-
                             nearPoints(
                               req(
                                 RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                               "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
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
                     
                     
                   } else if (!is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut) &
                              is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut)) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot <-
                       renderPlot({
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           shinyjs::show("UnitTime_sampleCutting_id")
                           shinyjs::show("mousepositionSampleCutting")
                           
                           RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = 0,
                               xmax = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut
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
                               req(input$UnitTime_sampleCutting),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                             ylim = rangesZoomSample_selectedCutting$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               input$sample_selectedCutting,
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
                               plot.subtitle = element_text(hjust = 0.5),
                               plot.background = element_rect(fill = "aliceblue")
                             )
                         }
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click,
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
                     output$sample_selectedCutting_hover_info <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover)
                         
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           point <-
                             nearPoints(
                               req(
                                 RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                               "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
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
                     
                   } else if (is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_min_cut) &
                              !is.na(RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut)) {
                     print("Selectsample")
                     output$sample_selectedCutting_Plot <-
                       renderPlot({
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           shinyjs::show("UnitTime_sampleCutting_id")
                           shinyjs::show("mousepositionSampleCutting")
                           
                           RvarsCorrectionTime$sample_cutting_viewer_ConvertTime %>%
                             ggplot() +
                             aes(x = CE.time,
                                 y = M.H,
                                 colour = intensity) +
                             #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                             geom_point(size = 1) +
                             geom_vline(
                               xintercept = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut
                               ),
                               color = "gray",
                               linetype = "dashed"
                             ) +
                             ggplot2::annotate(
                               "rect",
                               xmin = as.numeric(
                                 RvarsCorrectionTime$samplesCuttingTable[input$sample_selectedCutting,]$rt_max_cut
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
                               req(input$UnitTime_sampleCutting),
                               ")"
                             )) +
                             coord_cartesian(xlim = rangesZoomSample_selectedCutting$x,
                                             ylim = rangesZoomSample_selectedCutting$y,
                                             expand = TRUE) +
                             ggtitle(paste(
                               "Sample selected :",
                               input$sample_selectedCutting,
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
                               plot.subtitle = element_text(hjust = 0.5),
                               plot.background = element_rect(fill = "aliceblue")
                             )
                           
                         }
                         
                         
                         
                       })
                     
                     ## Mouse position
                     # output$sample_selectedCutting_Plot_info <- renderText({
                     #   paste0("Mouse position : ",
                     #          "\n CE-time = ", round(req(input$sample_selectedCutting_click$x),0)," (second)",
                     #         "\n M+H = ", round(req(input$sample_selectedCutting_click$y),4),(" (Da)"))
                     # })
                     
                     output$sample_selectedCutting_Plot_info <-
                       renderText({
                         paste0(
                           "Mouse position: ",
                           xy_str(
                             input$sample_selectedCutting_hover,
                             "CE-time",
                             "M+H"
                           ),
                           "Click: ",
                           xy_str(
                             input$sample_selectedCutting_click,
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
                     output$sample_selectedCutting_hover_info <-
                       renderUI({
                         hover <- req(input$sample_selectedCutting_hover)
                         
                         if (!is.null(RvarsCorrectionTime$sample_cutting_viewer_ConvertTime)) {
                           point <-
                             suppressWarnings(
                               nearPoints(
                                 req(
                                   RvarsCorrectionTime$sample_cutting_viewer_ConvertTime
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
                               "position:absolute; z-index:100; background-color: #760001; color:white;",
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
                                   round(point$M.H, 4),
                                   "<br/>",
                                   "<span class='bullText'> CE-time: </span>",
                                   round(point$CE.time, 2),
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
                 output$sample_selectedCutting_Plot <- renderPlot({
                   
                 })
                 output$sample_selectedCutting_Plot_info <-
                   renderText({
                     
                   })
                 output$sample_selectedCutting_hover_info <-
                   renderUI({
                     
                   })
                 hide("UnitTime_sampleCutting_id")
               }
             })


####~~~~~~~~~~~~~~ action buttons ~~~~~~~~~~~~~~~~~~~~~~~~
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$validCuttingRun
             },
             handlerExpr = {
               ask_confirmation(
                 inputId = "validCuttingRun_confirmation",
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
               input$ResetCuttingRun
             },
             handlerExpr = {
               ask_confirmation(
                 inputId = "ResetCuttingRun_confirmation",
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
               input$validCuttingRun_confirmation
             },
             handlerExpr = {
               if (input$validCuttingRun_confirmation == TRUE) {
                 disable("RetentionTimeFiltering_id")
                 shinyjs::show("id_ResetCuttingRun")
                 enable("SaveCuttingSample")
                 hide("id_validCuttingRun")
                 enable("GoToSelectRefranceSample")
                 enable("id_SelectRefrenceSamplePanel")
                 
                 
                 
               }
             })



observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ResetCuttingRun_confirmation
             },
             handlerExpr = {
               if (input$ResetCuttingRun_confirmation == TRUE) {
                 enable("RetentionTimeFiltering_id")
                 hide("id_ResetCuttingRun")
                 shinyjs::show("id_validCuttingRun")
                 disable("SaveCuttingSample")
                 shinyjs::reset("rt_min_cut")
                 shinyjs::reset("rt_max_cut")
                 disable("GoToSelectRefranceSample")
                 disable("id_SelectRefrenceSamplePanel")
                 
                 
                 if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
                   RvarsCorrectionTime$samplesCuttingTable <-
                     data.frame(
                       row.names = names(peaks_mono_iso_toUsed_NewRefMap()),
                       rt_min_cut = rep(NA, length(
                         peaks_mono_iso_toUsed_NewRefMap()
                       )),
                       rt_max_cut = rep(NA, length(
                         peaks_mono_iso_toUsed_NewRefMap()
                       )),
                       Unit = rep("Second", length(
                         peaks_mono_iso_toUsed_NewRefMap()
                       ))
                     )
                 }
                 
                 updateAwesomeRadio(session = session,
                                    inputId = "UnitTime_sampleCutting",
                                    selected = "Second")
                 RvarsCorrectionTime$Second_Cutting <- TRUE
               }
             })


output$titleTimefilter <- renderUI(h6(paste0(
  "CE-time (", input$UnitTime_sampleCutting, ") :"
)))

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Save samples  ~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
peaks_mono_iso_sample_selectedCutting <- reactive({
  if (!is.null(names(peaks_mono_iso_toUsed_NewRefMap()))) {
    table_to_save <- peaks_mono_iso_toUsed_NewRefMap()
    
    for (i in rownames(RvarsCorrectionTime$samplesCuttingTable)) {
      if (RvarsCorrectionTime$samplesCuttingTable[i, "Unit"] == "Second") {
        if (!is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
            !is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(
              RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut < rt,
              rt < RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut
            )
        } else if (!is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut <
                            rt)
        } else if (is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   !is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(rt < RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)
        } else if (is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]]
        }
      } else if (RvarsCorrectionTime$samplesCuttingTable[i, "Unit"] == "Minute") {
        if (!is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
            !is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(
              RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut < rt / 60,
              rt / 60 < RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut
            )
        } else if (!is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut <
                            rt / 60)
        } else if (is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   !is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]] %>%
            dplyr::filter(rt / 60 < RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)
        } else if (is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_min_cut) &
                   is.na(RvarsCorrectionTime$samplesCuttingTable[i,]$rt_max_cut)) {
          table_to_save[[i]] <- peaks_mono_iso_toUsed_NewRefMap()[[i]]
        }
      }
      
      
    }
    
    table_to_save
    
    
  }
  
})

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveCuttingSample
             },
             handlerExpr = {
               shinyFileSave(input,
                             id = "SaveCuttingSample",
                             roots = volumes,
                             session = session)
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$SaveCuttingSample)$datapath
               valuestoSave <-
                 peaks_mono_iso_sample_selectedCutting()
               if (length(valuestoSave) > 0) {
                 valuestoSave <- do.call("rbind", valuestoSave)
                 reqColsSaved <-
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
                 
                 reqColsUsed <- c('mz',
                                  'mzmin',
                                  'mzmax',
                                  'rt',
                                  'rtmin',
                                  'rtmax',
                                  'into',
                                  'maxo',
                                  'sn',
                                  'sample')
                 
                 idx_reqColsSaved <-
                   which(colnames(valuestoSave) %in% reqColsUsed)
                 colnames(valuestoSave)[idx_reqColsSaved] <-
                   reqColsSaved
                 valuestoSave <-
                   split(valuestoSave, f = valuestoSave$sample)
                 
                 if (length(path_Save_Files_origine) > 0) {
                   path_Save_Files <-
                     strsplit(path_Save_Files_origine, split = "/")[[1]]
                   directory_Save_Files <-
                     paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                   
                   
                   if (length(valuestoSave) == 1) {
                     write.table(
                       valuestoSave[[1]],
                       file = paste0(c(
                         directory_Save_Files,
                         paste(
                           names(valuestoSave)[1],
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
                       for (i in 1:length(valuestoSave)) {
                         incProgress(1 / length(peaks_mono_iso_toSave_NewRefMap()),
                                     detail = "")
                         print(paste0(c(
                           directory_Save_Files,
                           paste(
                             as.character(i),
                             path_Save_Files[length(path_Save_Files)],
                             collapse = "",
                             sep = "-"
                           )
                         ), collapse = "/"))
                         write.table(
                           valuestoSave[[i]],
                           file = paste0(c(
                             directory_Save_Files,
                             paste(
                               #as.character(i),
                               names(valuestoSave)[i],
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


###~~~~~~~~~~~~~~~~~~~ Validate cutted samples ~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$validCuttingRun_confirmation
             },
             handlerExpr = {
               if (input$validCuttingRun_confirmation) {
                 # if(length(peaks_mono_iso_sample_selectedCutting())>0){
                 #   RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse<-peaks_mono_iso_sample_selectedCutting()
                 #
                 #   updatePickerInput(session = session,
                 #                     inputId = "SelectRefrenceSample_option1",
                 #                     choices = names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse))
                 # }
                 
                 
                 RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse <-
                   peaks_mono_iso_sample_selectedCutting()
                 
                 if (!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)) {
                   updatePickerInput(
                     session = session,
                     inputId = "SelectRefrenceSample_option1",
                     choices = names(
                       RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse
                     )
                   )
                 } else{
                   updatePickerInput(
                     session = session,
                     inputId = "SelectRefrenceSample_option1",
                     choices = character(0),
                     selected = character(0)
                   )
                 }
                 
                 
               }
               
             })



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Choice of the reference sample Server~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#



##~~~~~~~~~~~~~~~~~~~~~~~~~~ For plot ~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
peaks_mono_iso_sample_selectedCutting_toPlot <- reactive({
  if (!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse) &
      !is.null(input$SelectRefrenceSample_option1)) {
    reqColstoPlot <- c('M+H', 'CE-time', 'intensity', 'sample')
    reqColsUsed <- c('mz', 'rt', 'maxo', 'sample')
    
    values <-
      RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse
    values <- req(values[input$SelectRefrenceSample_option1][[1]])
    idx_reqCols <- which(colnames(values) %in% reqColsUsed)
    colnames(values)[idx_reqCols] <- reqColstoPlot
    values$intensity <- log2(values$intensity)
    values
  }
  
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ When the user choose one sample ~~~~~~~~~~~~~~~~~~~~~~~~#
output$ReferenceSample_option1_Plot <- renderPlot({
  if (!is.null(peaks_mono_iso_sample_selectedCutting_toPlot()) &
      !is.null(input$SelectRefrenceSample_option1)) {
    # shinyjs::show("UnitTime_sampleCutting_id")
    # shinyjs::show("mousepositionSampleCutting")
    
    peaks_mono_iso_sample_selectedCutting_toPlot() %>%
      ggplot() +
      aes(x = `CE-time`, y = `M+H`, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
      geom_point(size = 1) +
      # geom_vline(xintercept = 3229, lwd = 1.5, color = "blue", linetype = "dashed")+
      # geom_vline(xintercept = 750, lwd = 1.5, color = "blue", linetype = "dashed")+
      scale_color_viridis_c(option = "inferno", direction = -1) +
      ylab("Mass (M+H) (Da)") +
      xlab(paste("CE-time (Second)")) +
      #coord_cartesian(xlim = rangesZoomSample_selectedCutting$x, ylim = rangesZoomSample_selectedCutting$y, expand = TRUE)+
      ggtitle(paste(
        "Reference sample :",
        input$SelectRefrenceSample_option1,
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
        plot.subtitle = element_text(hjust = 0.5),
        plot.background = element_rect(fill = "aliceblue")
      )
    
  }
  
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Reference sample if option 1 is choosed ~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observe({
  if (!is.null(input$SelectRefrenceSample_option1) &
      !is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)) {
    RvarsCorrectionTime$ref_Choose_sampleName <-
      req(input$SelectRefrenceSample_option1)
    RvarsCorrectionTime$ref_Choose_samplePeaks <-
      req(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[RvarsCorrectionTime$ref_Choose_sampleName][[1]])
    
  }
})


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Reference sample if option 2 is choosed (median sample) ~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$runSelectRefrenceSample
             },
             handlerExpr = {
               if (!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)) {
                 disable("cutOff_sample_NewRefMap")
                 
                 cutOff_PeakList <-
                   do.call("rbind",
                           RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
                 rownames(cutOff_PeakList) <-
                   1:nrow(cutOff_PeakList)
                 
                 RvarsCorrectionTime$Ref_Mdian_sampleName <-
                   choose_refSample_alignment(cutOff_PeakList = cutOff_PeakList)
                 
                 RvarsCorrectionTime$Ref_Mdian_samplePeaks <-
                   RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[RvarsCorrectionTime$Ref_Mdian_sampleName][[1]]
                 
                 
                 values_toPlot <-
                   RvarsCorrectionTime$Ref_Mdian_samplePeaks
                 reqColstoPlot <-
                   c('M+H', 'CE-time', 'intensity', 'sample')
                 reqColsUsed <- c('mz', 'rt', 'maxo', 'sample')
                 idx_reqCols <-
                   which(colnames(values_toPlot) %in% reqColsUsed)
                 colnames(values_toPlot)[idx_reqCols] <-
                   reqColstoPlot
                 values_toPlot$intensity <-
                   log2(values_toPlot$intensity)
                 
                 output$ReferenceSample_option2_Plot <- renderPlot({
                   if (!is.null(values_toPlot)) {
                     # shinyjs::show("UnitTime_sampleCutting_id")
                     # shinyjs::show("mousepositionSampleCutting")
                     
                     values_toPlot %>%
                       ggplot() +
                       aes(x = `CE-time`,
                           y = `M+H`,
                           colour = intensity) +
                       #geom_point(shape = "circle", size = input$sizePoints_NewRefMap) +
                       geom_point(size = 1) +
                       # geom_vline(xintercept = 3229, lwd = 1.5, color = "blue", linetype = "dashed")+
                       # geom_vline(xintercept = 750, lwd = 1.5, color = "blue", linetype = "dashed")+
                       scale_color_viridis_c(option = "inferno", direction = -1) +
                       ylab("Mass (M+H) (Da)") +
                       xlab(paste("CE-time (Second)")) +
                       #coord_cartesian(xlim = rangesZoomSample_selectedCutting$x, ylim = rangesZoomSample_selectedCutting$y, expand = TRUE)+
                       ggtitle(
                         paste(
                           "Reference sample :",
                           RvarsCorrectionTime$Ref_Mdian_sampleName,
                           "\n"
                         )
                       ) +
                       
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
                         plot.subtitle = element_text(hjust = 0.5),
                         plot.background = element_rect(fill = "aliceblue")
                       )
                     
                   }
                   
                   
                   
                 })
                 
                 enable("cutOff_sample_NewRefMap")
                 enable("ConfirmRefrenceSample")
                 
               }
               
             })

observe({
  if (is.null(RvarsCorrectionTime$Ref_Mdian_samplePeaks)) {
    output$ReferenceSample_option2_Plot <- renderPlot({
      
    })
  }
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ When confirm the reference sample ~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SelectRefrenceSample
             },
             handlerExpr = {
               if (input$SelectRefrenceSample == 2) {
                 disable("ConfirmRefrenceSample")
               } else if (input$SelectRefrenceSample == 1) {
                 enable("ConfirmRefrenceSample")
               }
             })


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ConfirmRefrenceSample
             },
             handlerExpr = {
               if (input$SelectRefrenceSample == 1) {
                 RvarsCorrectionTime$ref_sample_sampleName <-
                   RvarsCorrectionTime$ref_Choose_sampleName
                 RvarsCorrectionTime$ref_sample_samplePeaks <-
                   RvarsCorrectionTime$ref_Choose_samplePeaks
                 hide("id_plotRefrenceSample")
                 hide("ConfirmRefrenceSample")
                 disable("id_SelectRefrenceSamplePanel")
                 enable("resetRefrenceSample")
                 shinyjs::show("resetRefrenceSample")
                 enable("id_Panel_runCorrectionTime")
                 
                 shinyjs::show("Id_SampleOffset")
                 shinyjs::show("IDoffsetSamplePlot_div")
                 
                 
                 if (is.null(RvarsCorrectionTime$Filenames)) {
                   disable("ViewSampleInfo")
                   
                 }
                 shinyjs::show("id_Panel_runCorrectionTime")
                 shinyjs::show("id_PanelDamplesInfo")
                 shinyjs::show("id_PanelParametersGenerateMap")
                 shinyjs::show("id_runProcess")
                 hide("id_PanelcutOff_sample_NewRefMap")
               } else if (input$SelectRefrenceSample == 2) {
                 RvarsCorrectionTime$ref_sample_sampleName <-
                   RvarsCorrectionTime$Ref_Mdian_sampleName
                 RvarsCorrectionTime$ref_sample_samplePeaks <-
                   RvarsCorrectionTime$Ref_Mdian_samplePeaks
                 hide("id_plotRefrenceSample")
                 hide("ConfirmRefrenceSample")
                 disable("id_SelectRefrenceSamplePanel")
                 enable("resetRefrenceSample")
                 shinyjs::show("resetRefrenceSample")
                 enable("id_Panel_runCorrectionTime")
                 
                 shinyjs::show("Id_SampleOffset")
                 shinyjs::show("IDoffsetSamplePlot_div")
                 
                 if (is.null(RvarsCorrectionTime$Filenames)) {
                   disable("ViewSampleInfo")
                   
                 }
                 shinyjs::show("id_Panel_runCorrectionTime")
                 shinyjs::show("id_PanelDamplesInfo")
                 shinyjs::show("id_PanelParametersGenerateMap")
                 shinyjs::show("id_runProcess")
                 hide("id_PanelcutOff_sample_NewRefMap")
               }
               
               
             })

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Reset to choose again reference sample ~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$resetRefrenceSample
             },
             handlerExpr = {
               hide("resetRefrenceSample")
               shinyjs::show("ConfirmRefrenceSample")
               
               shinyjs::show("id_plotRefrenceSample")
               enable("id_SelectRefrenceSamplePanel")
               disable("id_Panel_runCorrectionTime")
               hide("id_Panel_runCorrectionTime")
               hide("id_PanelDamplesInfo")
               hide("id_PanelParametersGenerateMap")
               hide("id_runProcess")
               
               hide("Id_SampleOffset")
               hide("IDoffsetSamplePlot_div")
               
               disable("RefrenceSampleNextPage")
               
               shinyjs::show("id_PanelcutOff_sample_NewRefMap")
               if (input$SelectRefrenceSample == 2) {
                 disable("ConfirmRefrenceSample")
               }
               
             })
#
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Samples offset Server~~~~~~~~~~~~~~~~~~~~~~~~#
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#
#
# ##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Update Input SelectSampleOffset ~~~~~~~~~~~~~~~~~~~#
#
# observe({
#   if(!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse) & !is.null(RvarsCorrectionTime$ref_sample_sampleName)){
#
#     sample_name<-names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
#
#     if(!is.null(RvarsCorrectionTime$SelectSampleOffset_Selected)){
#       updatePickerInput(session = session,
#                         inputId = "SelectSampleOffset",
#                         choices = sample_name[sample_name != RvarsCorrectionTime$ref_sample_sampleName],
#                         selected = RvarsCorrectionTime$SelectSampleOffset_Selected
#       )
#     } else {
#       updatePickerInput(session = session,
#                         inputId = "SelectSampleOffset",
#                         choices = sample_name[sample_name != RvarsCorrectionTime$ref_sample_sampleName]
#       )
#     }
#
#
#   } else {
#
#     updatePickerInput(session = session,
#                       inputId = "SelectSampleOffset",
#                       choices = character(0),
#                       selected = character(0))
#
#
#   }
# })
#
# ##~~~~~~~~~~~~~~~ Plot sample selected and Reference sample ~~~~~~~~~~~~~~~~~~~#
#
# observe({
#
#   if(!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse) & !is.null(input$SelectSampleOffset)){
#
#     RvarsCorrectionTime$peaks_mono_iso_shift_plot<-
#       RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[c(input$SelectSampleOffset, RvarsCorrectionTime$ref_sample_sampleName)]
#   } else {
#     RvarsCorrectionTime$peaks_mono_iso_shift_plot<-NULL
#   }
#
# })
#
#
# ## Parameters plot
#
# rangesZoomOffsetSamplePlot<- reactiveValues(x = NULL, y = NULL)
#
# # When a double-click happens, check if there's a brush on the plot.
# # If so, zoom to the brush bounds; if not, reset the zoom.
# observeEvent({input$offsetSamplePlot_dblclick},{
#   brush <- input$offsetSamplePlot_brush
#   if (!is.null(brush)) {
#     rangesZoomOffsetSamplePlot$x <- c(brush$xmin, brush$xmax)
#     rangesZoomOffsetSamplePlot$y <- c(brush$ymin, brush$ymax)
#
#   } else {
#     ## reset coord_cartesian
#     rangesZoomOffsetSamplePlot$x <- NULL
#     rangesZoomOffsetSamplePlot$y <- NULL
#   }
# })
#
# output$offsetSamplePlot<-renderPlot({
#
#   if(length(RvarsCorrectionTime$peaks_mono_iso_shift_plot)>1){
#
#     peaks_shift_plot<-do.call("rbind", RvarsCorrectionTime$peaks_mono_iso_shift_plot)
#
#     rownames(peaks_shift_plot)<-1:nrow(peaks_shift_plot)
#
#     reqColstoPlot<-c('M+H','CE-time','intensity', 'sample')
#     reqColsUsed<-c('mz','rt','maxo', 'sample')
#
#     colnames(peaks_shift_plot)[which(colnames(peaks_shift_plot) %in% reqColsUsed)]<-reqColstoPlot
#
#     peaks_shift_plot$intensity<-log2(peaks_shift_plot$intensity)
#
#
#     peaks_shift_plot$sample[peaks_shift_plot$sample == RvarsCorrectionTime$ref_sample_sampleName]<-"Reference sample"
#
#     peaks_shift_plot$sample<-factor(peaks_shift_plot$sample,
#                                     levels = c(unique(peaks_shift_plot$sample)[unique(peaks_shift_plot$sample)!="Reference sample"],
#                                                "Reference sample"
#                                                ))
#
#     shinyjs::show("IDoffsetSamplePlot_info_div")
#
#     peaks_shift_plot %>%
#       ggplot() +
#       aes(x = `CE-time`, y = `M+H`, colour = intensity) +
#       #geom_point(shape = "circle", size = input$sizePoints) +
#       geom_point(size = 0.5) +
#       scale_color_viridis_c(option = "inferno", direction = -1) +
#       theme_gray() +
#       #facet_grid(vars(sample), vars())  +
#       facet_wrap(~sample, dir = "v")+
#       coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
#       ylab("Mass (M+H) (Da)") +
#       #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
#       xlab(paste("CE-time")) +
#
#       #ggtitle(paste("Nubmer of features :", number_of_features()))+
#
#       scale_x_continuous(n.breaks = 14)+
#       scale_y_continuous(n.breaks = 10)+
#       #scale_y_continuous(breaks=seq(input$mzRange[1],input$mzRange[2],by=200))+
#
#
#       #facet_grid(vars(sample), vars())+
#       #option_graphe.2 +
#       theme_ben() +
#       labs(colour ="log2 Intensity")+
#       theme(plot.title = element_text(size = rel(1),
#                                       face = "bold",
#                                       color = "blue",
#                                       margin = margin(0,0,5,0), hjust = 0.5),
#             plot.subtitle = element_text(hjust = 0.5),
#             panel.border = element_rect(fill = "transparent", # Needed to add the border
#                                         color = "blue",
#                                         linewidth = 0.5,
#                                         linetype = "dashed"),
#
#             # Les étiquettes dans le cas d'un facetting
#             strip.background = element_rect(fill = "grey", color = "grey"),
#             strip.text = element_text(size = rel(1), face = "bold.italic", color = "black", margin = margin(5,0,5,0)),
#             plot.background = element_rect(fill = "aliceblue"))
#   }
# })
#
# ###~~~~~~~~~~~~~~~~~~~~~~~~~~ Position mouse ~~~~~~~~~~~~~~~~~~~~~~~~#
# output$IDoffsetSamplePlot_info<- renderText({
#   paste0("Mouse position : CE-time = ", round(req(input$offsetSamplePlot_click$x),0)," (second), ",
#          " M+H = ", round(req(input$offsetSamplePlot_click$y),4)," (Da)")
# })
#
# ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~ info-bulle ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# output$offsetSamplePlot_hover_info <- renderUI({
#   hover <- req(input$offsetSamplePlot_hover)
#   if(length(RvarsCorrectionTime$peaks_mono_iso_shift_plot)>1){
#
#     peaks_shift_plot<-do.call("rbind", RvarsCorrectionTime$peaks_mono_iso_shift_plot)
#
#     rownames(peaks_shift_plot)<-1:nrow(peaks_shift_plot)
#
#     reqColstoPlot<-c('M+H','CE-time','intensity', 'sample')
#     reqColsUsed<-c('mz','rt','maxo', 'sample')
#
#     colnames(peaks_shift_plot)[which(colnames(peaks_shift_plot) %in% reqColsUsed)]<-reqColstoPlot
#
#     peaks_shift_plot$intensity<-log2(peaks_shift_plot$intensity)
#
#
#     peaks_shift_plot$sample[ peaks_shift_plot$sample == RvarsCorrectionTime$ref_sample_sampleName]<-"Reference sample"
#
#     peaks_shift_plot$sample<-factor(peaks_shift_plot$sample,
#                                     levels = c(unique(peaks_shift_plot$sample)[unique(peaks_shift_plot$sample)!="Reference sample"],
#                                                "Reference sample"
#                                     ))
#
#
#     Values_myPlot_data_peaks_shift_plot<-reactive({
#       peaks_shift_plot
#     })
#
#
#     point <-suppressWarnings(nearPoints(req(Values_myPlot_data_peaks_shift_plot()), hover, threshold = 5, maxpoints = 1, addDist = TRUE))
#     if (nrow(point) == 0) return(NULL)
#
#     # calculate point position INSIDE the image as percent of total dimensions
#     # from left (horizontal) and from top (vertical)
#     left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
#     top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
#
#     # calculate distance from left and bottom side of the picture in pixels
#     left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
#     top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
#
#     # create style property fot tooltip
#     # background color is set so tooltip is a bit transparent
#     # z-index is set so we are sure are tooltip will be on top
#     style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85);",
#                     "left:", left_px + 2, "px; top:", top_px + 2, "px;")
#
#     # actual tooltip created as wellPanel
#     div(
#       class = "well well-sm",
#       style = style,
#       p(HTML(paste0(
#         "<span class='bullText'> M+H: </span>", round(point$`M+H`,4), "<br/>",
#         "<span class='bullText'> CE-time: </span>", round(point$`CE-time`,2), "<br/>",
#
#         "<span class='bullText'> log2 Intensity: </span>", round(point$intensity,2), "<br/>",
#         "<span class='bullText'> Intensity: </span>", round(2^(point$intensity),0), "<br/>"
#       )))
#     )
#
#     }
#
# })
#
#
# ###~~~~~~~~~~~~~~ Action button shift "ButtonShift" ~~~~~~~~~~~~~~#
#
# observeEvent(
#   ignoreNULL = TRUE,
#   eventExpr = {
#     input$ButtonShift
#   },
#   handlerExpr = {
#
#     print(input$IdValue)
#     print(input$IdRefValue)
#
#     if(!is.na(input$IdValue) &
#        !is.na(input$IdRefValue) &
#        !is.null(input$SelectSampleOffset) &
#        !is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)){
#
#       shiftValue<-input$IdRefValue-input$IdValue
#
#       if(shiftValue>=0){
#
#         RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[input$SelectSampleOffset][[1]]$rt<-
#           RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[input$SelectSampleOffset][[1]]$rt+shiftValue
#       }else{
#         RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[input$SelectSampleOffset][[1]]$rt<-
#           RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse[input$SelectSampleOffset][[1]]$rt+shiftValue
#       }
#
#       RvarsCorrectionTime$SelectSampleOffset_Selected<-input$SelectSampleOffset
#     }
#
#   })



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###~~~~~~~~~~~~~~~~ CE-time correction with R package xcms~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

##~~~~~~~~~~~~~~~ Update values for subsetObiwrap ~~~~~~~~~~~#
observe({
  if (!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)) {
    sample_name <-
      names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
    updatePickerInput(
      session = session,
      inputId = "subsetObiwrap",
      choices = sample_name,
      selected = sample_name
    )
  } else {
    updatePickerInput(
      session = session,
      inputId = "subsetObiwrap",
      choices = character(0),
      selected = character(0)
    )
  }
})






##~~~~~~~~~~~~~~~~~~~~~~~~~ Upload raw data format mzML~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$rawDataMZml
             },
             handlerExpr = {
               files <- input$rawDataMZml
               ext <- tools::file_ext(files$datapath)
               
               if (length(ext) >= 1) {
                 if (length(ext) > 1) {
                   if (all.equal(ext, rep("mzML", length(ext))) != TRUE) {
                     message("Please upload a mzML files...!")
                     # hide("progressWrapper")
                     # hide("analysisProgress")
                     # shinyjs::html("analysisProgress",html = NULL)
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "Please upload a mzML files!",
                       type = "warning"
                     )
                     
                   } else {
                     ## Verify if files mzML matched well files csv
                     path_mzML <- input$rawDataMZml$datapath
                     Filenames_csv <-
                       names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
                     Filenames_mzML <- sub(
                       basename(input$rawDataMZml$name),
                       pattern = ".mzML",
                       replacement = "",
                       fixed = TRUE
                     )
                     if (length(Filenames_csv) != length(Filenames_mzML) ||
                         !all(Filenames_mzML %in% Filenames_csv)) {
                       RvarsCorrectionTime$rawData_mzML_path <- NULL
                       RvarsCorrectionTime$Filenames <- NULL
                       RvarsCorrectionTime$Class <- NULL
                       RvarsCorrectionTime$ImportClass <- FALSE
                       
                       sendSweetAlert(
                         session = session,
                         title = "Warning !",
                         text = "the mzML files uploaded don't matched well files csv!",
                         type = "warning"
                       )
                       
                     } else {
                       ## get path raw data mzML and files names
                       RvarsCorrectionTime$rawData_mzML_path <-
                         input$rawDataMZml$datapath
                       
                       RvarsCorrectionTime$Filenames <-
                         sub(
                           basename(input$rawDataMZml$name),
                           pattern = ".mzML",
                           replacement = "",
                           fixed = TRUE
                         )
                       
                       RvarsCorrectionTime$Class <-
                         rep("", length(RvarsCorrectionTime$rawData_mzML_path))
                       if (!is.null(RvarsCorrectionTime$Filenames)) {
                         enable("ViewSampleInfo")
                       }
                       
                     }
                     
                     
                     
                     
                     
                   }
                   
                 } else if (ext != "mzML") {
                   message("Please upload a mzML file...!")
                   # hide("progressWrapper")
                   # hide("analysisProgress")
                   # shinyjs::html("analysisProgress",html = NULL)
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a mzML file !",
                     type = "warning"
                   )
                   
                 } else {
                   RvarsCorrectionTime$rawData_mzML_path <- input$rawDataMZml$datapath
                   ## Verify if files mzML matched well files csv
                   path_mzML <- input$rawDataMZml$datapath
                   Filenames_csv <-
                     names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
                   Filenames_mzML <- sub(
                     basename(input$rawDataMZml$name),
                     pattern = ".mzML",
                     replacement = "",
                     fixed = TRUE
                   )
                   if (length(Filenames_csv) != length(Filenames_mzML) ||
                       !all(Filenames_mzML %in% Filenames_csv)) {
                     RvarsCorrectionTime$rawData_mzML_path <- NULL
                     RvarsCorrectionTime$Filenames <- NULL
                     RvarsCorrectionTime$Class <- NULL
                     RvarsCorrectionTime$ImportClass <- FALSE
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = "The mzML files uploaded don't matched well files csv!",
                       type = "warning"
                     )
                     
                   } else {
                     ## get path raw data mzML and files names
                     RvarsCorrectionTime$rawData_mzML_path <-
                       input$rawDataMZml$datapath
                     
                     RvarsCorrectionTime$Filenames <-
                       sub(
                         basename(input$rawDataMZml$name),
                         pattern = ".mzML",
                         replacement = "",
                         fixed = TRUE
                       )
                     
                     RvarsCorrectionTime$Class <-
                       rep("", length(RvarsCorrectionTime$rawData_mzML_path))
                     if (!is.null(RvarsCorrectionTime$Filenames)) {
                       enable("ViewSampleInfo")
                     }
                     
                   }
                   
                   
                 }
                 
                 
                 
               }
               
               # Filenames and classes
               
               
               output$sampleInfoEdit <- renderUI({
                 if (!is.null(RvarsCorrectionTime$Filenames)) {
                   lapply(1:length(RvarsCorrectionTime$Filenames), function(i, n) {
                     fluidRow(column(6,
                                     disabled(
                                       textInput(
                                         inputId = paste("sampleName_", i, sep = ""),
                                         value = n[i],
                                         label = ""
                                       )
                                     )), column(
                                       6,
                                       textInput(
                                         inputId = paste("className_", i, sep = ""),
                                         placeholder = "Enter class name",
                                         value = "",
                                         label = ""
                                       )
                                     ))
                   }, RvarsCorrectionTime$Filenames)
                 }
                 
                 
               })
               
               
               #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Samples Info Edit~~~~~~~~~~~~~~~~~~~~~#
               if (!is.null(RvarsCorrectionTime$Filenames)) {
                 showModal(
                   modalDialog(
                     title = "Edit the class that matches each sample",
                     
                     div(
                       id = "id_PanelDamplesInfo",
                       class = "well well-sm",
                       h4("Sample(s) information"),
                       hr(),
                       #htmlOutput("sampleInfoFileWrapper"),
                       
                       fluidRow(column(12,
                                       p(
                                         paste(
                                           "Manually enter sample-class information ",
                                           "(after file mzML upload)",
                                           sep = ""
                                         )
                                       ))),
                       fluidRow(column(6,
                                       div(
                                         style = paste(
                                           "font-weight:bold;",
                                           "border-style: none none dashed none;",
                                           "border-width: 2px;"
                                         ),
                                         "Filename"
                                       )), column(6,
                                                  div(
                                                    style = paste(
                                                      "font-weight:bold;",
                                                      "border-style: none none dashed none;",
                                                      "border-width: 2px;"
                                                    ),
                                                    "Class"
                                                  ))),
                       fluidRow(column(12,
                                       div(
                                         class = "small",
                                         htmlOutput("sampleInfoEdit")
                                       )))
                     ),
                     
                     size = "l",
                     easyClose = FALSE,
                     fade = TRUE,
                     footer = modalButton("Close (Esc)")
                   )
                 )
                 
                 
               }
               
             })


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ When upload Samples Info ~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$UploadSampleClass
             }
             , {
               if (is.null(RvarsCorrectionTime$Filenames)) {
                 sendSweetAlert(
                   session = session,
                   title = "Warning !",
                   text = "Please upload mzML files first",
                   type = "warning"
                 )
               } else {
                 files <- input$UploadSampleClass
                 ext <- tools::file_ext(files$datapath)
                 
                 reqCols <- c('Filenames', 'Class')
                 
                 reqColsMess <- " 'Filenames', 'Class'"
                 
                 
                 if (ext != "csv") {
                   message("Please upload a csv file...!")
                   
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = "Please upload a csv file !",
                     type = "warning"
                   )
                 } else {
                   tryCatch({
                     a <- read.csv(input$UploadSampleClass$datapath)
                   },
                   error = function(e) {
                     message("Please upload a csv file...!")
                     
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste("Please upload a csv file...! "),
                       type = "warning"
                     )
                   })
                   
                   if (!all(reqCols %in% colnames(a))) {
                     message("Please upload a csv file...!")
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = paste(
                         "Required columns :",
                         reqColsMess,
                         "not found in files.",
                         sep = " "
                       ),
                       type = "warning"
                     )
                   } else {
                     a <- a[, reqCols]
                     
                     if (!all(RvarsCorrectionTime$Filenames %in% a$Filenames)) {
                       sendSweetAlert(
                         session = session,
                         title = "Warning !",
                         text = paste("Files names mzML don't match samples names in file csv"),
                         type = "warning"
                       )
                     } else {
                       RvarsCorrectionTime$Class <- c()
                       for (i in 1:length(RvarsCorrectionTime$Filenames)) {
                         RvarsCorrectionTime$Class[i] <-
                           a[a$Filenames == RvarsCorrectionTime$Filenames[i], "Class"]
                       }
                       
                       RvarsCorrectionTime$ImportClass <- TRUE
                       
                       
                     }
                     
                     
                   }
                 }
                 
               }
             })

###~~~~~~~~~~~~~~~~~~~~~~~~~ update the Pheno Data~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
observe({
  if (!is.null(RvarsCorrectionTime$Filenames)) {
    if (!RvarsCorrectionTime$ImportClass) {
      RvarsCorrectionTime$Class <-
        unlist(sapply(1:length(RvarsCorrectionTime$Filenames), function(i) {
          n <- input[[paste("className_", i, sep = "")]]
          if (length(n) > 0)
            return(n)
          return("")
        }))
    }
    
    
    RvarsCorrectionTime$pheno_Data_mzML <-
      data.frame(Filenames = RvarsCorrectionTime$Filenames,
                 Class = RvarsCorrectionTime$Class)
  }
  
})


##~~~~~~~~~~~~~~~~~~~~~~ When click at button 'Enter samples classes~~~~~~~~~~~~~~~~~~~~~~~##
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ViewSampleInfo
             },
             handlerExpr = {
               if (!is.null(RvarsCorrectionTime$Class)) {
                 lapply(1:length(RvarsCorrectionTime$Class), function(i, n) {
                   updateTextInput(
                     session = session,
                     inputId = paste("className_", i, sep = ""),
                     placeholder = "Enter class name",
                     value = n[i],
                     label = ""
                   )
                 }, RvarsCorrectionTime$Class)
               }
               
               
               
               showModal(
                 modalDialog(
                   title = "Edit the class that matches each sample",
                   
                   div(
                     id = "id_PanelDamplesInfo",
                     class = "well well-sm",
                     h4("Sample(s) information"),
                     hr(),
                     #htmlOutput("sampleInfoFileWrapper"),
                     
                     fluidRow(column(12,
                                     p(
                                       paste(
                                         "Manually enter sample-class information ",
                                         "(after file mzML upload)",
                                         sep = ""
                                       )
                                     ))),
                     fluidRow(column(6,
                                     div(
                                       style = paste(
                                         "font-weight:bold;",
                                         "border-style: none none dashed none;",
                                         "border-width: 2px;"
                                       ),
                                       "Filename"
                                     )), column(6,
                                                div(
                                                  style = paste(
                                                    "font-weight:bold;",
                                                    "border-style: none none dashed none;",
                                                    "border-width: 2px;"
                                                  ),
                                                  "Class"
                                                ))),
                     fluidRow(column(12,
                                     div(
                                       class = "small",
                                       htmlOutput("sampleInfoEdit")
                                     )))
                   ),
                   
                   size = "l",
                   easyClose = FALSE,
                   fade = TRUE,
                   footer = modalButton("Close (Esc)")
                 )
               )
               
             })


###~~~~~~~~~~~~~~~~~ Disable and enable button 'ButtonCorrectionXCMS'~~~~~~~~~~~#

observe({
  ClassOK <- (
    !is.null(RvarsCorrectionTime$pheno_Data_mzML$Class) &&
      all(RvarsCorrectionTime$pheno_Data_mzML$Class != "")
  )
  
  if (ClassOK) {
    enable("ButtonCorrectionXCMS")
  } else{
    disable("ButtonCorrectionXCMS")
  }
})



##~~~~~~~~~~~~~ Reset some parameters when them in default ~~~~~~~~~~~~~~~~~~~~#

observe({
  if (length(input$CorrectionTimeXCMS_NewRefMap) != 0) {
    if (input$CorrectionTimeXCMS_NewRefMap == "defaults") {
      shinyjs::reset("binSizeObiwrap")
      
      shinyjs::reset("MSlevelObiwrap")
      
      shinyjs::reset("subsetAdjustObiwrap")
      
      
      
      if (!is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)) {
        sample_name <-
          names(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse)
        updatePickerInput(
          session = session,
          inputId = "subsetObiwrap",
          choices = sample_name,
          selected = sample_name
        )
      } else {
        updatePickerInput(
          session = session,
          inputId = "subsetObiwrap",
          choices = character(0),
          selected = character(0)
        )
      }
      
    }
    
  }
})


##~~~~~~~~~~~~~ Start Correction Obiwrap with xcms (button 'ButtonCorrectionXCMS') ~~~~~~~~~~~~~~~~~~~~#


observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ButtonCorrectionXCMS
             },
             handlerExpr = {
               ClassOK <- (
                 !is.null(RvarsCorrectionTime$pheno_Data_mzML$Class) &&
                   all(RvarsCorrectionTime$pheno_Data_mzML$Class != "")
               )
               
               if (!is.null(RvarsCorrectionTime$rawData_mzML_path) &
                   !is.null(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse) &
                   !is.null(RvarsCorrectionTime$ref_sample_sampleName) &
                   ClassOK) {
                 if (length(RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse) <
                     2) {
                   sendSweetAlert(
                     session = session,
                     title = "Warning !",
                     text = HTML(
                       "Can’t do CE-time correction with only 1 file. <br/>
                      Please load at least 2 files.!"
                     ),
                     type = "warning",
                     html = TRUE
                   )
                   
                 } else {
                   if (!is.element(RvarsCorrectionTime$ref_sample_sampleName,
                                   input$subsetObiwrap)) {
                     print(paste(
                       "Length sample selected :",
                       length(input$subsetObiwrap)
                     ))
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = HTML(
                         paste(
                           "Please include the reference sample: ",
                           RvarsCorrectionTime$ref_sample_sampleName,
                           " in parameter 'Subset'!"
                         )
                       ),
                       type = "warning",
                       html = TRUE
                     )
                     
                   } else if (length(input$subsetObiwrap) < 2) {
                     print(paste(
                       "Length sample selected :",
                       length(input$subsetObiwrap)
                     ))
                     
                     sendSweetAlert(
                       session = session,
                       title = "Warning !",
                       text = HTML(
                         paste(
                           "Please select at least 2 sample and include the reference sample: ",
                           RvarsCorrectionTime$ref_sample_sampleName,
                           " in parameter 'Subset'!"
                         )
                       ),
                       type = "warning",
                       html = TRUE
                     )
                   } else {
                     print(paste(
                       "Length sample selected :",
                       length(input$subsetObiwrap)
                     ))
                     
                     ### Disable some buttons when processes started
                     shinyjs::disable(selector = '.navbar-nav a[data-value="Analysis new samples"')
                     shinyjs::disable(selector = '.navbar-nav a[data-value="New reference map"')
                     shinyjs::disable(selector = '.navbar-nav a[data-value="Database"')
                     shinyjs::disable(selector = '.navbar-nav a[data-value="Statistical analysis"')
                     shinyjs::disable(selector = '.navbar-nav a[data-value="Help"')
                     
                     
                     
                     
                     
                     withProgress(message = 'CE-time correction:', value = 0, {
                       message("\n 1. Importing the necessary functions...")
                       incProgress(1 / 6, detail = "Importing the necessary functions...")
                       source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                              local = TRUE)
                       
                       message("\n 2. Getting data...")
                       incProgress(1 / 6, detail = "Getting data...")
                       peaks_mono_iso_toUSe <-
                         do.call(
                           "rbind",
                           RvarsCorrectionTime$peaks_mono_iso_sample_selectedCutting_toUse
                         )
                       rownames(peaks_mono_iso_toUSe) <-
                         1:nrow(peaks_mono_iso_toUSe)
                       
                       
                       incProgress(1 / 6, detail = "Reading mzML raw files...")
                       message("\n 3. Reading mzML raw files for the time correction...")
                       
                       
                       #~~~~~~~~~~~ Normalize path mzML and Filenames in pheno_Data ~~~~~~~~~~#
                       
                       rownames(RvarsCorrectionTime$pheno_Data_mzML) <-
                         1:nrow(RvarsCorrectionTime$pheno_Data_mzML)
                       rownames(peaks_mono_iso_toUSe) <-
                         1:nrow(peaks_mono_iso_toUSe)
                       
                       
                       rawData_mzML_OnDiskMSnExp <-
                         readMSData(
                           RvarsCorrectionTime$rawData_mzML_path,
                           pdata = new(
                             "NAnnotatedDataFrame",
                             RvarsCorrectionTime$pheno_Data_mzML
                           ),
                           mode = "onDisk"
                         )
                       
                       message("\n 4. Preprocessing in progress...")
                       incProgress(1 / 6, detail = "Preprocessing in progress...")
                       
                       ## Convert the object raw_data_mzML ('OnDiskMSnExp') into class 'XCMSnExp'
                       rawData_mzML_XCMSnExp <-
                         as(rawData_mzML_OnDiskMSnExp, "XCMSnExp")
                       
                       #select sample in pheno_Data
                       #please, make sure that column sample in peaks match with column sample_nampe pheno_Data
                       peaks_mono_iso_toUSe <-
                         peaks_mono_iso_toUSe %>%
                         dplyr::filter(sample %in% RvarsCorrectionTime$pheno_Data_mzML$Filenames)
                       
                       # numbering of samples
                       j <- 1
                       for (names in RvarsCorrectionTime$pheno_Data_mzML$Filenames) {
                         peaks_mono_iso_toUSe[peaks_mono_iso_toUSe$sample == names, "sample"] <-
                           j
                         j <- j + 1
                       }
                       peaks_mono_iso_toUSe$sample <-
                         as.double(peaks_mono_iso_toUSe$sample)
                       peaks_mono_iso_toUSe <-
                         order.data.frame(data = peaks_mono_iso_toUSe,
                                          column = "sample",
                                          rename.index = TRUE)
                       peaksMatrix <-
                         as.matrix.data.frame(peaks_mono_iso_toUSe[, 1:10]) ## modify
                       
                       ## Add peakMatrix in object 'rawData_mzML_XCMSnExp'
                       chromPeaks(rawData_mzML_XCMSnExp) <-
                         peaksMatrix
                       
                       # change column 'sample' with real names
                       
                       for (i in 1:length(unique(peaks_mono_iso_toUSe$sample))) {
                         peaks_mono_iso_toUSe[peaks_mono_iso_toUSe$sample == i, "sample"] <-
                           RvarsCorrectionTime$pheno_Data_mzML$Filenames[i]
                       }
                       peaks_mono_iso_toUSe$sample <-
                         as.character(peaks_mono_iso_toUSe$sample)
                       
                       ###~~~~~~~~~~~~~~~~~~~ Run function correction time ~~~~~~~~~~~~~~~~~#
                       message("\n 5. Correcting time in progress...")
                       incProgress(1 / 6, detail = "Correcting time in progress...")
                       
                       message(
                         "\n Reference sample name used : ",
                         RvarsCorrectionTime$ref_sample_sampleName
                       )
                       
                       system.time(
                         RvarsCorrectionTime$dataObiwarp_Aligned <-
                           alignement_Obiwrap(
                             xdata = rawData_mzML_XCMSnExp,
                             binSize = input$binSizeObiwrap,
                             msLevel = input$MSlevelObiwrap,
                             subset = which(
                               RvarsCorrectionTime$pheno_Data_mzML$Filenames %in% req(input$subsetObiwrap)
                             ),
                             subsetAdjust = input$subsetAdjustObiwrap,
                             centerSample = which(
                               RvarsCorrectionTime$pheno_Data_mzML$Filenames == RvarsCorrectionTime$ref_sample_sampleName
                             )
                           )
                       )
                       
                       message("\n 6. End of correction time...")
                       incProgress(1 / 6, detail = "End of correction time...")
                       ##~~~~~~~~~~~~~~~~~~~~~~~~ Get Features list aligned ~~~~~~~~~~~~~~~~#
                       RvarsCorrectionTime$peakListAligned <-
                         data.frame(chromPeaks(RvarsCorrectionTime$dataObiwarp_Aligned))
                       
                       for (i in 1:length(unique(RvarsCorrectionTime$peakListAligned$sample))) {
                         RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                               i, "sample"] <-
                           RvarsCorrectionTime$pheno_Data_mzML$Filenames[i]
                       }
                       
                       
                       RvarsCorrectionTime$peakListAligned$sample <-
                         as.character(RvarsCorrectionTime$peakListAligned$sample)
                       
                       
                       RvarsCorrectionTime$peakListAligned <-
                         cbind(RvarsCorrectionTime$peakListAligned,
                               peaks_mono_iso_toUSe[, 11:ncol(peaks_mono_iso_toUSe)])
                       
                       ##~~~~~ For correction with kernel density ~~~~~~#
                       RvarsCorrectionTime$peakListAligned_KernelDensity <-
                         RvarsCorrectionTime$peakListAligned
                       
                       # colSelect<-c("M+H","M+H.min","M+H.max","rt","rtmin","rtmax","Area","Height","SN","sample",
                       #              "iso.mass","iso.mass.link","mz_PeaksIsotopics_Group","rt_PeaksIsotopics_Group","Height_PeaksIsotopics_Group")
                       #
                       # colnames(RvarsCorrectionTime$peakListAligned)[c(1:10)]<-colSelect[c(1:10)]
                       
                       ##~~~~~~~~~~~~~~~~~~~~~~~~ Get Features list Before ~~~~~~~~~~~~~~~~#
                       RvarsCorrectionTime$peakListBefore <-
                         peaks_mono_iso_toUSe
                       
                       
                       ##~~~~~~~~~~~ Enable and show some inputs and outputs ~~~~~~~#
                       
                       
                       enable("RefrenceSampleNextPage")
                       enable("CorrectionXCMSNexPage")
                       
                       shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
                       shinyjs::enable(selector = '.navbar-nav a[data-value="New reference map"')
                       shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
                       shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
                       shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
                       
                       updateRadioButtons(session = session,
                                          inputId = "CorrectionTimeStep",
                                          selected = "3")
                       
                       
                     })
                     
                   }
                   
                   
                   
                   
                 }
                 
               }
               
             })


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###~~~~~~~~~~~~ Visualization CE-time correction with R package xcms  ~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

##~~~~~~~~~~~~ update input 'SelectSample_ViewerCorrectimeXcms' ~~~~~~~~~#

observe({
  if (!is.null(RvarsCorrectionTime$peakListAligned)) {
    sample_name <- unique(RvarsCorrectionTime$peakListAligned$sample)
    
    updatePickerInput(session = session,
                      inputId = "SelectSample_ViewerCorrectimeXcms",
                      choices = sample_name)
    
    # if(input$TabPanelCorrectionTimeXCMS_ID == "Graph 1"){
    #
    #   updatePickerInput(session = session,
    #                     inputId = "SelectSample_ViewerCorrectimeXcms",
    #                     choices = sample_name)
    #
    # } else{
    #   updatePickerInput(session = session,
    #                     inputId = "SelectSample_ViewerCorrectimeXcms",
    #                     choices = sample_name[sample_name != RvarsCorrectionTime$ref_sample_sampleName])
    # }
    
    
  } else {
    updatePickerInput(
      session = session,
      inputId = "SelectSample_ViewerCorrectimeXcms",
      choices = character(0),
      selected = character(0)
    )
  }
})


# observe({
#
#
#   if(!is.null(RvarsCorrectionTime$peakListBefore) &
#      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
#      !is.null(input$SelectSample_ViewerCorrectimeXcms)){
#
#     source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R", local=TRUE)
#
#     ref<-RvarsCorrectionTime$ref_sample_samplePeaks
#     table<-RvarsCorrectionTime$peakListBefore[RvarsCorrectionTime$peakListBefore$sample==input$SelectSample_ViewerCorrectimeXcms,]
#
#
#     View(ref)
#     View(table)
#
#     Test<-matchMz(x = ref,
#                   table = table,
#                   ppm_tolereance = 500,
#                   mzcol = "mz",
#                   rtcol = "rt",
#                   )
#
#     View(Test)
#   }
# })

#~~~~~~~~~ Plot rt reference and rt sample (CE-time correction with xcms)~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


output$CorrectimeXCMSViewer_1 <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
           local = TRUE)
    
    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    table.before <-
      RvarsCorrectionTime$peakListBefore[RvarsCorrectionTime$peakListBefore$sample ==
                                           input$SelectSample_ViewerCorrectimeXcms,]
    table.after <-
      RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                            input$SelectSample_ViewerCorrectimeXcms,]
    
    # write.table(table.before[,1:10], file = "table.before.csv",  sep = ",", row.names =  FALSE)
    # write.table(table.after[,1:10], file = "table.after.csv", sep = ",", row.names =  FALSE)
    #
    # write.table(ref[,1:10], file = "ref.csv", sep = ",", row.names =  FALSE)
    
    resMatch.before <- matchMz(
      x = ref,
      table = table.before,
      ppm_tolereance = 1000,
      mzcol = "mz",
      rtcol = "rt" ,
      session = session
    )
    
    resMatch.after <- matchMz(
      x = ref,
      table = table.after,
      ppm_tolereance = 1000,
      mzcol = "mz",
      rtcol = "rt" ,
      session = session
    )
    
    
    Data_Plot.before <-
      resMatch.before$MatchTable[!is.na(resMatch.before$MatchTable$rt.2),
                                 c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "rt.2", "maxo.2")]
    Data_Plot.after <-
      resMatch.after$MatchTable[!is.na(resMatch.after$MatchTable$rt.2),
                                c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "rt.2", "maxo.2")]
    
    
    
    median_line.before <- seq(min(
      range(Data_Plot.before$rt.2)[1],
      range(Data_Plot.before$rt.1)[1]
    ),
    max(
      range(Data_Plot.before$rt.2)[2],
      range(Data_Plot.before$rt.1)[2]
    ), by = 50)
    
    median_line_data.before <- data.frame(x =  median_line.before,
                                          y  =  median_line.before)
    
    
    median_line.after <- seq(min(
      range(Data_Plot.after$rt.2)[1],
      range(Data_Plot.after$rt.1)[1]
    ),
    max(
      range(Data_Plot.after$rt.2)[2],
      range(Data_Plot.after$rt.1)[2]
    ), by = 50)
    
    median_line_data.after <- data.frame(x =  median_line.after,
                                         y  =  median_line.after)
    
    
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot before Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
    Plot.before <-
      ggplot(Data_Plot.before, aes(x = rt.2, y = rt.1)) +
      geom_point() +
      
      coord_cartesian(xlim = c(min(
        range(Data_Plot.before$rt.2)[1],
        range(Data_Plot.before$rt.1)[1]
      ),
      max(
        range(Data_Plot.before$rt.2)[2],
        range(Data_Plot.before$rt.1)[2]
      )),
      ylim = c(min(
        range(Data_Plot.before$rt.2)[1],
        range(Data_Plot.before$rt.1)[1]
      ),
      max(
        range(Data_Plot.before$rt.2)[2],
        range(Data_Plot.before$rt.1)[2]
      ))) +
      
      
      
      scale_x_continuous(n.breaks = 14) +
      scale_y_continuous(n.breaks = 14) +
      
      # xlab("CE-time (sample to align)")+
      # ylab("CE-time (reference sample)")+
      
      # geom_line(data = predict_data_model.np, aes(x = rt2, y = rt1, color = "Model"), lwd = 1, size = 1.5) +
      # #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
      # # geom_abline(yintercept = 0, lwd = 1, color = "green")+
      
      geom_line(
        data = median_line_data.before,
        aes(x = x, y = x, color = "Median"),
        lwd = 1,
        size = 1.5
      ) +
      
      labs(
        x = paste("CE-time (", input$SelectSample_ViewerCorrectimeXcms, ")"),
        y = "CE-time (reference sample)",
        color = "Legend"
      ) +
      ggtitle("Before correction with xcms") +
      
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
    
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot after Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
    Plot.after <- ggplot(Data_Plot.after, aes(x = rt.2, y = rt.1)) +
      geom_point() +
      
      coord_cartesian(xlim = c(min(
        range(Data_Plot.after$rt.2)[1],
        range(Data_Plot.after$rt.1)[1]
      ),
      max(
        range(Data_Plot.after$rt.2)[2],
        range(Data_Plot.after$rt.1)[2]
      )),
      ylim = c(min(
        range(Data_Plot.after$rt.2)[1],
        range(Data_Plot.after$rt.1)[1]
      ),
      max(
        range(Data_Plot.after$rt.2)[2],
        range(Data_Plot.after$rt.1)[2]
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
        aes(x = x, y = x, color = "Median"),
        lwd = 1,
        size = 1.5
      ) +
      
      labs(
        x = paste("CE-time (", input$SelectSample_ViewerCorrectimeXcms, ")"),
        y = "CE-time (reference sample)",
        color = "Legend"
      ) +
      ggtitle("After correction with xcms") +
      
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
    
    
    grid.arrange(Plot.before, Plot.after, nrow = 2)
    
  }
})


####~~~~~~~~~~~~~~~~~~~~ Plot before ~~~~~~~~~~~~~~~~~~~~~~~~#
####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
output$CorrectimeXCMSViewer_Before <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
           local = TRUE)
    
    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    table.before <-
      RvarsCorrectionTime$peakListBefore[RvarsCorrectionTime$peakListBefore$sample ==
                                           input$SelectSample_ViewerCorrectimeXcms,]
    
    resMatch.before <- matchMz(
      x = ref,
      table = table.before,
      ppm_tolereance = 1000,
      mzcol = "mz",
      rtcol = "rt" ,
      session = session
    )
    
    
    Data_Plot.before <-
      resMatch.before$MatchTable[!is.na(resMatch.before$MatchTable$rt.2),
                                 c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "rt.2", "maxo.2")]
    
    RvarsCorrectionTime$Data_Plot.before <-
      Data_Plot.before # for info bull
    
    median_line.before <- seq(min(
      range(Data_Plot.before$rt.2)[1],
      range(Data_Plot.before$rt.1)[1]
    ),
    max(
      range(Data_Plot.before$rt.2)[2],
      range(Data_Plot.before$rt.1)[2]
    ), by = 50)
    
    median_line_data.before <- data.frame(x =  median_line.before,
                                          y  =  median_line.before)
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot before Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
    Plot.before <-
      ggplot(Data_Plot.before, aes(x = rt.2, y = rt.1)) +
      geom_point() +
      
      coord_cartesian(xlim = c(min(
        range(Data_Plot.before$rt.2)[1],
        range(Data_Plot.before$rt.1)[1]
      ),
      max(
        range(Data_Plot.before$rt.2)[2],
        range(Data_Plot.before$rt.1)[2]
      )),
      ylim = c(min(
        range(Data_Plot.before$rt.2)[1],
        range(Data_Plot.before$rt.1)[1]
      ),
      max(
        range(Data_Plot.before$rt.2)[2],
        range(Data_Plot.before$rt.1)[2]
      ))) +
      
      
      
      scale_x_continuous(n.breaks = 14) +
      scale_y_continuous(n.breaks = 14) +
      
      # xlab("CE-time (sample to align)")+
      # ylab("CE-time (reference sample)")+
      
      # geom_line(data = predict_data_model.np, aes(x = rt2, y = rt1, color = "Model"), lwd = 1, size = 1.5) +
      # #geom_smooth(method ="loess", color="blue", fill="#69b3a2", se=TRUE, span = input$span) +
      # # geom_abline(yintercept = 0, lwd = 1, color = "green")+
      
      geom_line(
        data = median_line_data.before,
        aes(x = x, y = x, color = "Median"),
        lwd = 1,
        size = 1.5
      ) +
      
      labs(
        x = paste("CE-time (", input$SelectSample_ViewerCorrectimeXcms, ")"),
        y = "CE-time (reference sample)",
        color = "Legend"
      ) +
      ggtitle("Before correction with xcms") +
      
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
    
    
    Plot.before
    
  }
})

#### info-bulle
output$CorrectimeXCMSViewer_Before_hover_info <- renderUI({
  hover <- req(input$CorrectimeXCMSViewer_Before_hover)
  
  if (!is.null(RvarsCorrectionTime$Data_Plot.before)) {
    point <- nearPoints(
      req(RvarsCorrectionTime$Data_Plot.before),
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
        "position:absolute; z-index:100; background-color: #760001; color:white;",
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

####~~~~~~~~~~~~~~~~~~~~ Plot After ~~~~~~~~~~~~~~~~~~~~~~~~#
####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
output$CorrectimeXCMSViewer_After <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
           local = TRUE)
    
    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    table.after <-
      RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                            input$SelectSample_ViewerCorrectimeXcms,]
    
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
                                c("mz.1", "rt.1", "maxo.1", "mz.2", "rt.2", "rt.2", "maxo.2")]
    
    RvarsCorrectionTime$Data_Plot.after <- Data_Plot.after
    
    median_line.after <- seq(min(
      range(Data_Plot.after$rt.2)[1],
      range(Data_Plot.after$rt.1)[1]
    ),
    max(
      range(Data_Plot.after$rt.2)[2],
      range(Data_Plot.after$rt.1)[2]
    ), by = 50)
    
    median_line_data.after <- data.frame(x =  median_line.after,
                                         y  =  median_line.after)
    
    
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot after Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~#
    Plot.after <- ggplot(Data_Plot.after, aes(x = rt.2, y = rt.1)) +
      geom_point() +
      
      coord_cartesian(xlim = c(min(
        range(Data_Plot.after$rt.2)[1],
        range(Data_Plot.after$rt.1)[1]
      ),
      max(
        range(Data_Plot.after$rt.2)[2],
        range(Data_Plot.after$rt.1)[2]
      )),
      ylim = c(min(
        range(Data_Plot.after$rt.2)[1],
        range(Data_Plot.after$rt.1)[1]
      ),
      max(
        range(Data_Plot.after$rt.2)[2],
        range(Data_Plot.after$rt.1)[2]
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
        aes(x = x, y = x, color = "Median"),
        lwd = 1,
        size = 1.5
      ) +
      
      labs(
        x = paste("CE-time (", input$SelectSample_ViewerCorrectimeXcms, ")"),
        y = "CE-time (reference sample)",
        color = "Legend"
      ) +
      ggtitle("After correction with xcms") +
      
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
output$CorrectimeXCMSViewer_After_hover_info <- renderUI({
  hover <- req(input$CorrectimeXCMSViewer_After_hover)
  
  if (!is.null(RvarsCorrectionTime$Data_Plot.after)) {
    point <- nearPoints(
      req(RvarsCorrectionTime$Data_Plot.after),
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
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

output$CorrectimeXCMSViewer_2 <- renderPlot({
  if (!is.null(RvarsCorrectionTime$peakListBefore) &
      !is.null(RvarsCorrectionTime$peakListAligned) &
      !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
      !is.null(input$SelectSample_ViewerCorrectimeXcms)) {
    ref <- RvarsCorrectionTime$ref_sample_samplePeaks
    
    reqColstoPlot <- c('M+H', 'CE-time', 'intensity', 'sample')
    reqColsUsed <- c('mz', 'rt', 'maxo', 'sample')
    
    
    ##~~~~~~~~~~~~~~~~~~~~ Before correction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    table.before <-
      RvarsCorrectionTime$peakListBefore[RvarsCorrectionTime$peakListBefore$sample ==
                                           input$SelectSample_ViewerCorrectimeXcms,]
    Data_before <- rbind(table.before,
                         ref)
    
    rownames(Data_before) <- 1:nrow(Data_before)
    
    
    colnames(Data_before)[which(colnames(Data_before) %in% reqColsUsed)] <-
      reqColstoPlot
    Data_before$intensity <- log2(Data_before$intensity)
    
    Data_before$sample[Data_before$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
      "Reference sample"
    Data_before$sample <- factor(Data_before$sample,
                                 levels = c(unique(Data_before$sample)[unique(Data_before$sample) !=
                                                                         "Reference sample"],
                                            "Reference sample"))
    
    
    
    Plot.Before <- Data_before %>%
      ggplot() +
      aes(x = `CE-time`, y = `M+H`, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints) +
      geom_point(size = 0.5) +
      scale_color_viridis_c(option = "inferno", direction = -1) +
      theme_gray() +
      #facet_grid(vars(sample), vars())  +
      facet_wrap(~ sample, dir = "v") +
      #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
      ylab("Mass (M+H) (Da)") +
      #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
      xlab(paste("CE-time")) +
      
      ggtitle("Before correction with xcms") +
      
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
        strip.background = element_rect(fill = "grey", color = "grey"),
        strip.text = element_text(
          size = rel(1),
          face = "bold.italic",
          color = "black",
          margin = margin(5, 0, 5, 0)
        ),
        plot.background = element_rect(fill = "aliceblue")
      )
    
    
    ##~~~~~~~~~~~~~~~~~~~~ After correction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    table.after <-
      RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                            input$SelectSample_ViewerCorrectimeXcms,]
    Data_after <- rbind(table.after,
                        ref)
    rownames(Data_after) <- 1:nrow(Data_after)
    colnames(Data_after)[which(colnames(Data_after) %in% reqColsUsed)] <-
      reqColstoPlot
    Data_after$intensity <- log2(Data_after$intensity)
    
    Data_after$sample[Data_after$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
      "Reference sample"
    Data_after$sample <- factor(Data_after$sample,
                                levels = c(unique(Data_after$sample)[unique(Data_after$sample) !=
                                                                       "Reference sample"],
                                           "Reference sample"))
    
    Plot.After <- Data_after %>%
      ggplot() +
      aes(x = `CE-time`, y = `M+H`, colour = intensity) +
      #geom_point(shape = "circle", size = input$sizePoints) +
      geom_point(size = 0.5) +
      scale_color_viridis_c(option = "inferno", direction = -1) +
      theme_gray() +
      #facet_grid(vars(sample), vars())  +
      facet_wrap(~ sample, dir = "v") +
      #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
      ylab("Mass (M+H) (Da)") +
      #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
      xlab(paste("CE-time")) +
      
      ggtitle("After correction with xcms") +
      
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
        strip.background = element_rect(fill = "grey", color = "grey"),
        strip.text = element_text(
          size = rel(1),
          face = "bold.italic",
          color = "black",
          margin = margin(5, 0, 5, 0)
        ),
        plot.background = element_rect(fill = "aliceblue")
      )
    
    
    grid.arrange(Plot.Before, Plot.After, nrow = 2)
    
  }
  
})



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
###~~~~~~~~~~~~~~~~ Correction time with kernel Density ~~~~~~~~~~~~~~~~~~~~~~##
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

##~~~~~~~~~~~~ update input 'SelectSample_KernelDensity' ~~~~~~~~~#

# observe({
#   if(!is.null(RvarsCorrectionTime$peakListAligned)){
#
#     sample_name<-unique(RvarsCorrectionTime$peakListAligned$sample)
#
#     updatePickerInput(session = session,
#                       inputId = "SelectSample_KernelDensity",
#                       choices = sample_name[sample_name != RvarsCorrectionTime$ref_sample_sampleName])
#
#
#
#   } else {
#     updatePickerInput(session = session,
#                       inputId = "SelectSample_KernelDensity",
#                       choices = character(0),
#                       selected = character(0))
#   }
# })

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$Add_to
             },
             
             handlerExpr = {
               RvarsCorrectionTime$samples_names_to_align_withKernDensity <-
                 unique(
                   c(
                     RvarsCorrectionTime$samples_names_to_align_withKernDensity,
                     input$SelectSample_ViewerCorrectimeXcms
                   )
                 )
               
               message("\n RvarsCorrectionTime$samples_names_to_align_withKernDensity: ")
               print(RvarsCorrectionTime$samples_names_to_align_withKernDensity)
               
               if (length(RvarsCorrectionTime$samples_names_to_align_withKernDensity) !=
                   0) {
                 sample_name <-
                   RvarsCorrectionTime$samples_names_to_align_withKernDensity
                 
                 updatePickerInput(session = session,
                                   inputId = "SelectSample_KernelDensity",
                                   choices = sample_name[sample_name != RvarsCorrectionTime$ref_sample_sampleName])
                 
                 
                 sendSweetAlert(
                   session = session,
                   title = "",
                   text = HTML(paste0("Sample: <span style = 'font-weight:bold;color: #760001;'>",
                                      input$SelectSample_ViewerCorrectimeXcms, 
                                      "</span> has been added !")),
                   type = "success",
                   closeOnClickOutside = FALSE,
                   html = TRUE
                 )
                 
               } else {
                 updatePickerInput(
                   session = session,
                   inputId = "SelectSample_KernelDensity",
                   choices = character(0),
                   selected = character(0)
                 )
               }
               
               
               
             })


##~~~~~~~~~~~~ Kernel density filter ~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SelectSample_KernelDensity
             },
             handlerExpr = {
               if (!is.null(input$SelectSample_KernelDensity) &
                   !is.null(RvarsCorrectionTime$peakListAligned) &
                   !is.null(RvarsCorrectionTime$ref_sample_samplePeaks)) {
                 ##Matched samples
                 
                 source("lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                        local = TRUE)
                 
                 ref <- RvarsCorrectionTime$ref_sample_samplePeaks
                 table.after <-
                   RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                         input$SelectSample_KernelDensity,]
                 
                 
                 resMatch.after_xcms <- matchMz(
                   x = ref,
                   table = table.after,
                   ppm_tolereance = 1000,
                   mzcol = "mz",
                   rtcol = "rt" ,
                   session = session
                 )
                 
                 
                 RvarsCorrectionTime$Data_Plot.after_xcms_to_filter <-
                   resMatch.after_xcms$MatchTable[!is.na(resMatch.after_xcms$MatchTable$rt.2),
                                                  c("mz.1",
                                                    "rt.1",
                                                    "maxo.1",
                                                    "mz.2",
                                                    "rt.2",
                                                    "rt.2",
                                                    "maxo.2",
                                                    "sample.2")]
                 
                 ##Log2 intensity sample to align
                 RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$maxo.2 <-
                   log2(RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$maxo.2)
                 
                 ## Filter intensity
                 observe({
                   if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms_to_filter)) {
                     RvarsCorrectionTime$Data_Plot.after_xcms <-
                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter %>%
                       dplyr::filter(maxo.2 >= req(input$intensityFilter))
                   }
                 })
                 
                 ## Median line
                 if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms)) {
                   median_line.after_xcms <-
                     seq(min(
                       range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[1],
                       range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[1]
                     ),
                     max(
                       range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[2],
                       range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[2]
                     ), by = 50)
                   
                   median_line_data.after_xcms <-
                     data.frame(x =  median_line.after_xcms,
                                y  =  median_line.after_xcms)
                 }
                 
                 
                 ####~~~~~~~~~~~~~~~~ Correction with Kernel Density ~~~~~~~~~~~~~~~~~~~~###
                 
                 #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
                 data_dens_filter <-
                   reactive(if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms) &
                                nrow(RvarsCorrectionTime$Data_Plot.after_xcms) != 0) {
                     dens <-
                       kde2d(
                         RvarsCorrectionTime$Data_Plot.after_xcms$rt.2,
                         RvarsCorrectionTime$Data_Plot.after_xcms$rt.1,
                         h = input$bandwidth_Filter,
                         n = input$gridSize
                       )
                     nx <-
                       nrow(RvarsCorrectionTime$Data_Plot.after_xcms)
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
                       dplyr::filter(density >= req(input$minDensity))
                     
                     colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                     
                     df_filter
                   })
                 
                 
                 #~~~~~~~~~~~~~~~~~~~~~~~~ Plot filter density ~~~~~~~~~~~~~~~~~~~~~~~#
                 output$DensityFilterPlot <- renderPlot({
                   if (length(data_dens_filter()) != 0) {
                     if (!is.null(data_dens_filter()) &
                         nrow(data_dens_filter()) != 0 &
                         nrow(RvarsCorrectionTime$Data_Plot.after_xcms) != 0) {
                       p1 <- RvarsCorrectionTime$Data_Plot.after_xcms %>%
                         ggplot() +
                         aes(x = rt.2, y = rt.1) +
                         geom_point(aes(color = maxo.2), size = 0.8) +
                         scale_color_viridis_c(option = "H", direction = -1) +
                         geom_density_2d(h = input$bandwidth_Filter,
                                         n = input$gridSize) +
                         scale_x_continuous(n.breaks = 14) +
                         scale_y_continuous(n.breaks = 14) +
                         
                         coord_cartesian(xlim = c(min(
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[1],
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[1]
                         ),
                         max(
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[2],
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[2]
                         )),
                         
                         ylim = c(min(
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[1],
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[1]
                         ),
                         max(
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.2)[2],
                           range(RvarsCorrectionTime$Data_Plot.after_xcms$rt.1)[2]
                         ))) +
                         
                         
                         xlab(
                           paste(
                             "CE-time (",
                             RvarsCorrectionTime$Data_Plot.after_xcms$sample.2,
                             ")"
                           )
                         ) +
                         ylab("CE-time (reference sample)") +
                         #labs(colour ="log2 Intensity")+
                         theme_ben() +
                         labs(colour = "log2 Intensity") 
                       
                       p2 <-
                         ggplot(data_dens_filter(), aes(x = rt.2, y = rt.1)) +
                         geom_point(aes(color = density)) +
                         
                         scale_x_continuous(n.breaks = 14) +
                         scale_y_continuous(n.breaks = 14) +
                         
                         coord_cartesian(xlim = c(min(
                           range(data_dens_filter()$rt.2)[1],
                           range(data_dens_filter()$rt.1)[1]
                         ),
                         max(
                           range(data_dens_filter()$rt.2)[2],
                           range(data_dens_filter()$rt.1)[2]
                         )),
                         
                         ylim = c(min(
                           range(data_dens_filter()$rt.2)[1],
                           range(data_dens_filter()$rt.1)[1]
                         ),
                         max(
                           range(data_dens_filter()$rt.2)[2],
                           range(data_dens_filter()$rt.1)[2]
                         ))) +
                         
                         xlab(
                           paste(
                             "CE-time (",
                             RvarsCorrectionTime$Data_Plot.after_xcms$sample.2,
                             ")"
                           )
                         ) +
                         ylab("CE-time (reference sample)") +
                         
                         theme_ben() +
                         theme(
                           legend.title = element_text(
                             size = rel(0.95),
                             face = "bold.italic",
                             hjust = 0.5
                           ),
                           legend.text = element_text(size = rel(0.85), face = "bold.italic")
                         )
                       
                       grid.arrange(p1, p2, nrow = 2)
                       
                     }
                   }
                   
                   
                 })
                 
                 
                 
               }
               
             })

##~~~~~~~~~~~~~~~~~~~~ Fit model kernel density estimation ~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$fitModel
             },
             handlerExpr = {
               
               if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms)) {
                 
                 
                 if (nrow(RvarsCorrectionTime$Data_Plot.after_xcms) != 0) {
                   
                   
                   #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
                   data_dens_filter <-
                     reactive(if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms)) {
                       dens <-
                         kde2d(
                           RvarsCorrectionTime$Data_Plot.after_xcms$rt.2,
                           RvarsCorrectionTime$Data_Plot.after_xcms$rt.1,
                           h = input$bandwidth_Filter,
                           n = input$gridSize
                         )
                       nx <-
                         nrow(RvarsCorrectionTime$Data_Plot.after_xcms)
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
                         dplyr::filter(density >= req(input$minDensity))
                       
                       colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                       
                       df_filter
                     })
                   
                   
                   ##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Fit model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   if (length(data_dens_filter()) != 0) {
                     if (!is.null(data_dens_filter())) {
                       dataDensity <- isolate(data_dens_filter())
                       
                       if (!is.null(dataDensity)) {
                         withProgress(message = 'Fit model...', value = 0, {
                           incProgress(1 / 3, detail = "")
                           
                           #~~~~~~~~~~~~~~~~~ Kernel density estimation ~~~~~~~~~~~~~~~~~~~~~~~#
                           RvarsCorrectionTime$modelKernelDensity <-
                             npreg(
                               rt.1 ~ rt.2,
                               bws = req(input$"bandwidth_Model"),
                               bwtype = c("fixed", "generalized_nn", "adaptive_nn")[1],
                               regtype = "ll",
                               ckertype = input$KernelType,
                               #bwmethod = "cv.aic",
                               gradients = TRUE,
                               data = dataDensity
                             )
                           
                           #~~~~~~~~~~~~~~~~~ Calculate prediction rt for sample selected ~~~~~~~~~~~~~~~~~~~~~~~#
                           if (!is.null(RvarsCorrectionTime$modelKernelDensity)) {
                             incProgress(1 / 3, detail = "")
                             
                             ### correction rt xcms by correction rt Kernel Density
                             RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                                 input$SelectSample_KernelDensity,]$rt <-
                               predict(
                                 RvarsCorrectionTime$modelKernelDensity,
                                 newdata = data.frame(rt.2 = RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                                                                   input$SelectSample_KernelDensity,]$rt)
                               )
                             
                             ### Delete negative correction rt
                             
                             # RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity==input$SelectSample_KernelDensity,]$rt<-
                             #   RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity==input$SelectSample_KernelDensity,]$rt %>% dplyr::filter(rt>0)
                             #
                             
                             
                             ## ~~~~~~~~~~~~~~~~~~ Plot correction rt with kernel Density ~~~~~~~~~~~~~#
                             
                             ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Before~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                             output$PlotCorrectionKernelDensity_Before <-
                               renderPlot({
                                 predict_data_model.np <-
                                   data.frame(
                                     rt.1 = predict(
                                       RvarsCorrectionTime$modelKernelDensity,
                                       newdata = data.frame(rt.2 = seq(
                                         min(
                                           range(
                                             RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                           )[1],
                                           range(
                                             RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                           )[1]
                                         ),
                                         max(
                                           range(
                                             RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                           )[2],
                                           range(
                                             RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                           )[2]
                                         )
                                       ), by = 50)
                                     ),
                                     rt.2 = seq(
                                       min(
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                         )[1],
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                         )[1]
                                       ),
                                       max(
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                         )[2],
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                         )[2]
                                       )
                                     ),
                                     by = 50
                                   )
                                 
                                 median_line <-
                                   seq(min(
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                     )[1],
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                     )[1]
                                   ),
                                   max(
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                     )[2],
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                     )[2]
                                   ),
                                   by = 50)
                                 
                                 median_line_data <-
                                   data.frame(x =  median_line, y  =  median_line)
                                 
                                 ggplot(
                                   RvarsCorrectionTime$Data_Plot.after_xcms_to_filter,
                                   aes(x = rt.2, y = rt.1)
                                 ) +
                                   geom_point() +
                                   
                                   coord_cartesian(xlim = c(
                                     min(
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                       )[1],
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                       )[1]
                                     ),
                                     max(
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                       )[2],
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                       )[2]
                                     )
                                   ),
                                   ylim = c(
                                     min(
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                       )[1],
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                       )[1]
                                     ),
                                     max(
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                       )[2],
                                       range(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                       )[2]
                                     )
                                   )) +
                                   
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
                                   ggtitle("Correction with xcms") +
                                   
                                   labs(
                                     x = paste(
                                       "CE-time (",
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$sample.2,
                                       ")"
                                     ),
                                     y = "CE-time (reference sample)",
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
                             output$PlotCorrectionKernelDensity_Before_hover_info <-
                               renderUI({
                                 hover <- req(input$PlotCorrectionKernelDensity_Before_hover)
                                 
                                 if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms_to_filter)) {
                                   point <-
                                     nearPoints(
                                       req(
                                         RvarsCorrectionTime$Data_Plot.after_xcms_to_filter
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
                             output$PlotCorrectionKernelDensity_After <-
                               renderPlot({
                                 if (!is.null(input$SelectSample_KernelDensity) &
                                     !is.null(RvarsCorrectionTime$peakListAligned) &
                                     !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
                                     !is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {
                                   source(
                                     "lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                                     local = TRUE
                                   )
                                   
                                   ref <-
                                     RvarsCorrectionTime$ref_sample_samplePeaks
                                   table.after <-
                                     RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                                         input$SelectSample_KernelDensity,]
                                   
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
                                   
                                   RvarsCorrectionTime$Data_Plot.after_KernelDensity <-
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
                                     geom_point() +
                                     
                                     coord_cartesian(xlim = c(
                                       min(
                                         range(Data_Plot.after$rt.2)[1],
                                         range(Data_Plot.after$rt.1)[1]
                                       ),
                                       max(
                                         range(Data_Plot.after$rt.2)[2],
                                         range(Data_Plot.after$rt.1)[2]
                                       )
                                     ),
                                     ylim = c(
                                       min(
                                         range(Data_Plot.after$rt.2)[1],
                                         range(Data_Plot.after$rt.1)[1]
                                       ),
                                       max(
                                         range(Data_Plot.after$rt.2)[2],
                                         range(Data_Plot.after$rt.1)[2]
                                       )
                                     )) +
                                     
                                     
                                     
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
                                       x = paste(
                                         "CE-time (",
                                         Data_Plot.after$sample.2,
                                         ")"
                                       ),
                                       y = "CE-time (reference sample)",
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
                             output$PlotCorrectionKernelDensity_After_hover_info <-
                               renderUI({
                                 hover <- req(input$PlotCorrectionKernelDensity_After_hover)
                                 
                                 if (!is.null(RvarsCorrectionTime$Data_Plot.after_KernelDensity)) {
                                   point <-
                                     nearPoints(
                                       req(
                                         RvarsCorrectionTime$Data_Plot.after_KernelDensity
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
                             
                             output$CorrectimeKernelDensityViewer_2 <-
                               renderPlot({
                                 if (!is.null(input$SelectSample_KernelDensity) &
                                     !is.null(RvarsCorrectionTime$peakListAligned) &
                                     !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
                                     !is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {
                                   ref <- RvarsCorrectionTime$ref_sample_samplePeaks
                                   
                                   reqColstoPlot <-
                                     c('M+H', 'CE-time', 'intensity', 'sample')
                                   reqColsUsed <-
                                     c('mz', 'rt', 'maxo', 'sample')
                                   
                                   
                                   ##~~~~~~~~~~~~~~~~~~~~ After correction xcms ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                   table.after <-
                                     RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                                           input$SelectSample_KernelDensity,]
                                   Data_after <- rbind(table.after,
                                                       ref)
                                   rownames(Data_after) <-
                                     1:nrow(Data_after)
                                   colnames(Data_after)[which(colnames(Data_after) %in% reqColsUsed)] <-
                                     reqColstoPlot
                                   Data_after$intensity <-
                                     log2(Data_after$intensity)
                                   
                                   Data_after$sample[Data_after$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
                                     "Reference sample"
                                   Data_after$sample <-
                                     factor(Data_after$sample,
                                            levels = c(
                                              unique(Data_after$sample)[unique(Data_after$sample) != "Reference sample"],
                                              "Reference sample"
                                            ))
                                   
                                   Plot.After <- Data_after %>%
                                     ggplot() +
                                     aes(x = `CE-time`,
                                         y = `M+H`,
                                         colour = intensity) +
                                     #geom_point(shape = "circle", size = input$sizePoints) +
                                     geom_point(size = 0.5) +
                                     scale_color_viridis_c(option = "inferno",
                                                           direction = -1) +
                                     theme_gray() +
                                     #facet_grid(vars(sample), vars())  +
                                     facet_wrap(~ sample, dir = "v") +
                                     #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
                                     ylab("Mass (M+H) (Da)") +
                                     #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
                                     xlab(paste("CE-time")) +
                                     
                                     ggtitle("Correction with xcms") +
                                     
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
                                     RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                                         input$SelectSample_KernelDensity,]
                                   Data_After_KernelDensity <-
                                     rbind(table.After_KernelDensity,
                                           ref)
                                   
                                   rownames(Data_After_KernelDensity) <-
                                     1:nrow(Data_After_KernelDensity)
                                   
                                   
                                   colnames(Data_After_KernelDensity)[which(colnames(Data_After_KernelDensity) %in% reqColsUsed)] <-
                                     reqColstoPlot
                                   Data_After_KernelDensity$intensity <-
                                     log2(Data_After_KernelDensity$intensity)
                                   
                                   Data_After_KernelDensity$sample[Data_After_KernelDensity$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
                                     "Reference sample"
                                   Data_After_KernelDensity$sample <-
                                     factor(
                                       Data_After_KernelDensity$sample,
                                       levels = c(
                                         unique(Data_After_KernelDensity$sample)[unique(Data_After_KernelDensity$sample) !=
                                                                                   "Reference sample"],
                                         "Reference sample"
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
                                     scale_color_viridis_c(option = "inferno",
                                                           direction = -1) +
                                     theme_gray() +
                                     #facet_grid(vars(sample), vars())  +
                                     facet_wrap(~ sample, dir = "v") +
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

               # Track corrected sample and check if all samples are done
               if (!is.null(input$SelectSample_KernelDensity)) {
                 # Add current sample to list of corrected samples
                 current_corrected <- correctedSamples_KernelDensity()
                 if (!input$SelectSample_KernelDensity %in% current_corrected) {
                   correctedSamples_KernelDensity(c(current_corrected, input$SelectSample_KernelDensity))
                 }

                 # Check if all samples are corrected
                 if (!is.null(RvarsCorrectionTime$peakListAligned)) {
                   all_samples <- unique(RvarsCorrectionTime$peakListAligned$sample)
                   corrected <- correctedSamples_KernelDensity()

                   # Enable validation button if all samples are corrected
                   if (length(corrected) > 0 && all(all_samples %in% corrected)) {
                     shinyjs::enable("validateCETimeCorrection")
                     showNotification(
                       "All samples have been corrected! You can now validate and export the data.",
                       type = "message",
                       duration = 5
                     )
                   }
                 }
               }

               # Force garbage collection to free memory from old renderPlot() instances
               # This reduces (but doesn't eliminate) memory leak from renderPlot() recreation
               invisible(gc(verbose = FALSE))

             })


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~ reset CE-time kernel correction to CE-time correction XCMS ~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$resetFitModel
             },
             handlerExpr = {
               if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms)) {
                 if (nrow(RvarsCorrectionTime$Data_Plot.after_xcms) != 0) {
                   #~~~~~~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~~~~~~#
                   data_dens_filter <-
                     reactive(if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms)) {
                       dens <-
                         kde2d(
                           RvarsCorrectionTime$Data_Plot.after_xcms$rt.2,
                           RvarsCorrectionTime$Data_Plot.after_xcms$rt.1,
                           h = input$bandwidth_Filter,
                           n = input$gridSize
                         )
                       nx <-
                         nrow(RvarsCorrectionTime$Data_Plot.after_xcms)
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
                         dplyr::filter(density >= req(input$minDensity))
                       
                       colnames(df_filter)[1:2] <- c("rt.2", "rt.1")
                       
                       df_filter
                     })
                   
                   ##~~~~~~~~~~~~~~~~~~~~~~~~~~~ Fit model ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   if (!is.null(data_dens_filter())) {
                     dataDensity <- isolate(data_dens_filter())
                     
                     if (!is.null(dataDensity)) {
                       withProgress(message = 'Fit model...', value = 0, {
                         incProgress(1 / 3, detail = "")
                         
                         #~~~~~~~~~~~~~~~~~ Kernel density estimation ~~~~~~~~~~~~~~~~~~~~~~~#
                         RvarsCorrectionTime$modelKernelDensity <-
                           npreg(
                             rt.1 ~ rt.2,
                             bws = req(input$"bandwidth_Model"),
                             bwtype = c("fixed", "generalized_nn", "adaptive_nn")[1],
                             regtype = "ll",
                             ckertype = input$KernelType,
                             #bwmethod = "cv.aic",
                             gradients = TRUE,
                             data = dataDensity
                           )
                         
                         #~~~~~~~~~~~~~~~~~ Calculate prediction rt for sample selected ~~~~~~~~~~~~~~~~~~~~~~~#
                         if (!is.null(RvarsCorrectionTime$modelKernelDensity)) {
                           incProgress(1 / 3, detail = "")
                           
                           ### correction rt xcms by correction rt Kernel Density
                           RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                               input$SelectSample_KernelDensity,]$rt <-
                             RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                                   input$SelectSample_KernelDensity,]$rt
                           
                           ### Delete negative correction rt
                           
                           # RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity==input$SelectSample_KernelDensity,]$rt<-
                           #   RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity==input$SelectSample_KernelDensity,]$rt %>% dplyr::filter(rt>0)
                           #
                           
                           
                           ## ~~~~~~~~~~~~~~~~~~ Plot correction rt with kernel Density ~~~~~~~~~~~~~#
                           ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Before~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                           output$PlotCorrectionKernelDensity_Before <-
                             renderPlot({
                               predict_data_model.np <-
                                 data.frame(
                                   rt.1 = predict(
                                     RvarsCorrectionTime$modelKernelDensity,
                                     newdata = data.frame(rt.2 = seq(
                                       min(
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                         )[1],
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                         )[1]
                                       ),
                                       max(
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                         )[2],
                                         range(
                                           RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                         )[2]
                                       )
                                     ), by = 50)
                                   ),
                                   rt.2 = seq(min(
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                     )[1],
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                     )[1]
                                   ),
                                   max(
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                     )[2],
                                     range(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                     )[2]
                                   )),
                                   by = 50
                                 )
                               
                               median_line <-
                                 seq(min(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[1],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                   )[1]
                                 ),
                                 max(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[2],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                   )[2]
                                 ),
                                 by = 50)
                               
                               median_line_data <-
                                 data.frame(x =  median_line, y  =  median_line)
                               
                               ggplot(
                                 RvarsCorrectionTime$Data_Plot.after_xcms_to_filter,
                                 aes(x = rt.2, y = rt.1)
                               ) +
                                 geom_point() +
                                 
                                 coord_cartesian(xlim = c(min(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[1],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                   )[1]
                                 ),
                                 max(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[2],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                   )[2]
                                 )),
                                 ylim = c(min(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[1],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
                                   )[1]
                                 ),
                                 max(
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.2
                                   )[2],
                                   range(
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$rt.1
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
                                 ggtitle("Correction with xcms") +
                                 
                                 labs(
                                   x = paste(
                                     "CE-time (",
                                     RvarsCorrectionTime$Data_Plot.after_xcms_to_filter$sample.2,
                                     ")"
                                   ),
                                   y = "CE-time (reference sample)",
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
                           output$PlotCorrectionKernelDensity_Before_hover_info <-
                             renderUI({
                               hover <- req(input$PlotCorrectionKernelDensity_Before_hover)
                               
                               if (!is.null(RvarsCorrectionTime$Data_Plot.after_xcms_to_filter)) {
                                 point <-
                                   nearPoints(
                                     req(
                                       RvarsCorrectionTime$Data_Plot.after_xcms_to_filter
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
                           output$PlotCorrectionKernelDensity_After <-
                             renderPlot({
                               if (!is.null(input$SelectSample_KernelDensity) &
                                   !is.null(RvarsCorrectionTime$peakListAligned) &
                                   !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
                                   !is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {
                                 source(
                                   "lib/NewReferenceMap/R_files/CE_time_Correction.lib.R",
                                   local = TRUE
                                 )
                                 
                                 ref <-
                                   RvarsCorrectionTime$ref_sample_samplePeaks
                                 table.after <-
                                   RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                                       input$SelectSample_KernelDensity,]
                                 
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
                                 
                                 RvarsCorrectionTime$Data_Plot.after_KernelDensity <-
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
                                   geom_point() +
                                   
                                   coord_cartesian(xlim = c(
                                     min(
                                       range(Data_Plot.after$rt.2)[1],
                                       range(Data_Plot.after$rt.1)[1]
                                     ),
                                     max(
                                       range(Data_Plot.after$rt.2)[2],
                                       range(Data_Plot.after$rt.1)[2]
                                     )
                                   ),
                                   ylim = c(
                                     min(
                                       range(Data_Plot.after$rt.2)[1],
                                       range(Data_Plot.after$rt.1)[1]
                                     ),
                                     max(
                                       range(Data_Plot.after$rt.2)[2],
                                       range(Data_Plot.after$rt.1)[2]
                                     )
                                   )) +
                                   
                                   
                                   
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
                                     y = "CE-time (reference sample)",
                                     color = "Legend"
                                   ) +
                                   ggtitle("Correction with xcms (Correction with Kernel Density deleted)") +
                                   
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
                           output$PlotCorrectionKernelDensity_After_hover_info <-
                             renderUI({
                               hover <- req(input$PlotCorrectionKernelDensity_After_hover)
                               
                               if (!is.null(RvarsCorrectionTime$Data_Plot.after_KernelDensity)) {
                                 point <-
                                   nearPoints(
                                     req(
                                       RvarsCorrectionTime$Data_Plot.after_KernelDensity
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
                           
                           output$CorrectimeKernelDensityViewer_2 <-
                             renderPlot({
                               if (!is.null(input$SelectSample_KernelDensity) &
                                   !is.null(RvarsCorrectionTime$peakListAligned) &
                                   !is.null(RvarsCorrectionTime$ref_sample_samplePeaks) &
                                   !is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {
                                 ref <- RvarsCorrectionTime$ref_sample_samplePeaks
                                 
                                 reqColstoPlot <-
                                   c('M+H', 'CE-time', 'intensity', 'sample')
                                 reqColsUsed <-
                                   c('mz', 'rt', 'maxo', 'sample')
                                 
                                 
                                 ##~~~~~~~~~~~~~~~~~~~~ After correction xcms ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                 #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                                 table.after <-
                                   RvarsCorrectionTime$peakListAligned[RvarsCorrectionTime$peakListAligned$sample ==
                                                                         input$SelectSample_KernelDensity,]
                                 Data_after <- rbind(table.after,
                                                     ref)
                                 rownames(Data_after) <-
                                   1:nrow(Data_after)
                                 colnames(Data_after)[which(colnames(Data_after) %in% reqColsUsed)] <-
                                   reqColstoPlot
                                 Data_after$intensity <-
                                   log2(Data_after$intensity)
                                 
                                 Data_after$sample[Data_after$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
                                   "Reference sample"
                                 Data_after$sample <-
                                   factor(Data_after$sample,
                                          levels = c(
                                            unique(Data_after$sample)[unique(Data_after$sample) != "Reference sample"],
                                            "Reference sample"
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
                                   facet_wrap(~ sample, dir = "v") +
                                   #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
                                   ylab("Mass (M+H) (Da)") +
                                   #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
                                   xlab(paste("CE-time")) +
                                   
                                   ggtitle("Correction with xcms") +
                                   
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
                                   RvarsCorrectionTime$peakListAligned_KernelDensity[RvarsCorrectionTime$peakListAligned_KernelDensity$sample ==
                                                                                       input$SelectSample_KernelDensity,]
                                 Data_After_KernelDensity <-
                                   rbind(table.After_KernelDensity,
                                         ref)
                                 
                                 rownames(Data_After_KernelDensity) <-
                                   1:nrow(Data_After_KernelDensity)
                                 
                                 
                                 colnames(Data_After_KernelDensity)[which(colnames(Data_After_KernelDensity) %in% reqColsUsed)] <-
                                   reqColstoPlot
                                 Data_After_KernelDensity$intensity <-
                                   log2(Data_After_KernelDensity$intensity)
                                 
                                 Data_After_KernelDensity$sample[Data_After_KernelDensity$sample == RvarsCorrectionTime$ref_sample_sampleName] <-
                                   "Reference sample"
                                 Data_After_KernelDensity$sample <-
                                   factor(
                                     Data_After_KernelDensity$sample,
                                     levels = c(
                                       unique(Data_After_KernelDensity$sample)[unique(Data_After_KernelDensity$sample) !=
                                                                                 "Reference sample"],
                                       "Reference sample"
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
                                   facet_wrap(~ sample, dir = "v") +
                                   #coord_cartesian(xlim = rangesZoomOffsetSamplePlot$x, ylim = rangesZoomOffsetSamplePlot$y, expand = TRUE)+
                                   ylab("Mass (M+H) (Da)") +
                                   #xlab(paste("CE-time (",input$UnitTime_NewRefMap,")")) +
                                   xlab(paste("CE-time")) +
                                   
                                   ggtitle("Correction with xcms (Correction with Kernel Density deleted)") +
                                   
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

               # Remove sample from corrected list and disable validation button
               if (!is.null(input$SelectSample_KernelDensity)) {
                 current_corrected <- correctedSamples_KernelDensity()
                 # Remove this sample from corrected list
                 correctedSamples_KernelDensity(current_corrected[current_corrected != input$SelectSample_KernelDensity])

                 # Disable validation button since not all samples are corrected anymore
                 shinyjs::disable("validateCETimeCorrection")
                 showNotification(
                   paste("Reset completed for sample:", input$SelectSample_KernelDensity),
                   type = "warning",
                   duration = 3
                 )
               }

               # Force garbage collection to free memory from old renderPlot() instances
               # This reduces (but doesn't eliminate) memory leak from renderPlot() recreation
               invisible(gc(verbose = FALSE))

             })




observe({
  if (is.null(RvarsCorrectionTime$modelKernelDensity)) {
    output$PlotCorrectionKernelDensity_Before <- renderPlot({
      
    })
    output$PlotCorrectionKernelDensity_After <- renderPlot({
      
    })
    output$CorrectimeKernelDensityViewer_2 <- renderPlot({
      
    })
  }
  
  if (is.null(input$SelectSample_KernelDensity) ||
      is.null(RvarsCorrectionTime$peakListAligned) ||
      is.null(RvarsCorrectionTime$ref_sample_samplePeaks)) {
    output$DensityFilterPlot <- renderPlot({
      
    })
  }
})

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~ Save CE-time Corrected Data with shinyFiles ~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveCETimeCorrected
             },
             handlerExpr = {
               # Open file save dialog
               shinyFileSave(input,
                             id = "SaveCETimeCorrected",
                             roots = volumes,
                             session = session)

               # Get the selected file path
               path_Save_File <- parseSavePath(volumes, input$SaveCETimeCorrected)$datapath

               # Only proceed if user selected a valid path
               if (length(path_Save_File) > 0) {

                 # Check if data exists
                 if (!is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {

                   # Show progress notification
                   showNotification(
                     "Creating Excel file with corrected data...",
                     type = "message",
                     duration = NULL,
                     id = "save_progress"
                   )

                   tryCatch({
                     # Get corrected data
                     corrected_data <- RvarsCorrectionTime$peakListAligned_KernelDensity

                     # Create workbook with multiple sheets
                     wb <- openxlsx::createWorkbook()

                     # Sheet 1: Corrected peaks data
                     openxlsx::addWorksheet(wb, "Corrected_Peaks")
                     openxlsx::writeData(wb, "Corrected_Peaks", corrected_data,
                                        startRow = 1, startCol = 1,
                                        rowNames = FALSE)

                     # Add header styling
                     header_style <- openxlsx::createStyle(
                       fontSize = 12,
                       fontColour = "#FFFFFF",
                       fgFill = "#4F81BD",
                       halign = "center",
                       valign = "center",
                       textDecoration = "bold",
                       border = "TopBottomLeftRight"
                     )

                     openxlsx::addStyle(wb, "Corrected_Peaks",
                                       style = header_style,
                                       rows = 1,
                                       cols = 1:ncol(corrected_data),
                                       gridExpand = TRUE)

                     # Freeze first row
                     openxlsx::freezePane(wb, "Corrected_Peaks", firstRow = TRUE)

                     # Auto-size columns
                     openxlsx::setColWidths(wb, "Corrected_Peaks",
                                           cols = 1:ncol(corrected_data),
                                           widths = "auto")

                     # Sheet 2: Metadata/Parameters (if available)
                     if (!is.null(RvarsCorrectionTime$pheno_Data_mzML)) {
                       openxlsx::addWorksheet(wb, "Sample_Info")
                       openxlsx::writeData(wb, "Sample_Info",
                                          RvarsCorrectionTime$pheno_Data_mzML,
                                          rowNames = FALSE)

                       openxlsx::addStyle(wb, "Sample_Info",
                                         style = header_style,
                                         rows = 1,
                                         cols = 1:ncol(RvarsCorrectionTime$pheno_Data_mzML),
                                         gridExpand = TRUE)

                       openxlsx::freezePane(wb, "Sample_Info", firstRow = TRUE)
                     }

                     # Sheet 3: Correction summary
                     openxlsx::addWorksheet(wb, "Correction_Summary")

                     summary_info <- data.frame(
                       Parameter = c("Correction Method",
                                    "Kernel Type",
                                    "Bandwidth (Model)",
                                    "Bandwidth (Filter)",
                                    "Min Density",
                                    "Intensity Filter",
                                    "Export Date",
                                    "Number of Peaks",
                                    "Number of Samples"),
                       Value = c("Kernel Density",
                                ifelse(!is.null(input$KernelType), input$KernelType, "N/A"),
                                ifelse(!is.null(input$bandwidth_Model), input$bandwidth_Model, "N/A"),
                                ifelse(!is.null(input$bandwidth_Filter), input$bandwidth_Filter, "N/A"),
                                ifelse(!is.null(input$minDensity), input$minDensity, "N/A"),
                                ifelse(!is.null(input$intensityFilter), input$intensityFilter, "N/A"),
                                format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
                                nrow(corrected_data),
                                length(unique(corrected_data$sample)))
                     )

                     openxlsx::writeData(wb, "Correction_Summary", summary_info, rowNames = FALSE)

                     openxlsx::addStyle(wb, "Correction_Summary",
                                       style = header_style,
                                       rows = 1,
                                       cols = 1:2,
                                       gridExpand = TRUE)

                     # Ensure the file has .xlsx extension
                     if (!grepl("\\.xlsx$", path_Save_File, ignore.case = TRUE)) {
                       path_Save_File <- paste0(path_Save_File, ".xlsx")
                     }

                     # Save workbook to selected path
                     openxlsx::saveWorkbook(wb, path_Save_File, overwrite = TRUE)

                     # Remove progress notification
                     removeNotification(id = "save_progress")

                     # Show success notification
                     showNotification(
                       paste0("File saved successfully to:\n", basename(path_Save_File)),
                       type = "message",
                       duration = 5
                     )

                     # Log save event
                     cat(paste0(
                       "\n[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ",
                       "CE-Time corrected data saved to: ", path_Save_File,
                       " (", nrow(corrected_data), " peaks, ",
                       length(unique(corrected_data$sample)), " samples)\n"
                     ))

                   }, error = function(e) {
                     # Remove progress notification
                     removeNotification(id = "save_progress")

                     # Show error notification
                     showNotification(
                       paste0("Error saving file: ", e$message),
                       type = "error",
                       duration = 10
                     )

                     # Log error
                     cat(paste0(
                       "\n[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ",
                       "ERROR saving CE-Time data: ", e$message, "\n"
                     ))
                   })

                 } else {
                   # No data available
                   showNotification(
                     "No corrected data available. Please apply Kernel Density correction first.",
                     type = "warning",
                     duration = 5
                   )
                 }
               }
               # If path_Save_File is empty, user cancelled the dialog - no action needed
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~ Save CE-time Corrected Data as CSV ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveCETimeCorrectedCSV
             },
             handlerExpr = {
               # Open file save dialog
               shinyFileSave(input,
                             id = "SaveCETimeCorrectedCSV",
                             roots = volumes,
                             session = session)

               # Get the selected file path
               path_Save_File <- parseSavePath(volumes, input$SaveCETimeCorrectedCSV)$datapath

               # Only proceed if user selected a valid path
               if (length(path_Save_File) > 0) {

                 # Check if data exists
                 if (!is.null(RvarsCorrectionTime$peakListAligned_KernelDensity)) {

                   # Show progress notification
                   showNotification(
                     "Creating CSV file with corrected data...",
                     type = "message",
                     duration = NULL,
                     id = "save_csv_progress"
                   )

                   tryCatch({
                     # Get corrected data
                     corrected_data <- RvarsCorrectionTime$peakListAligned_KernelDensity

                     # Ensure the file has .csv extension
                     if (!grepl("\\.csv$", path_Save_File, ignore.case = TRUE)) {
                       path_Save_File <- paste0(path_Save_File, ".csv")
                     }

                     # Save as CSV
                     write.csv(corrected_data,
                               file = path_Save_File,
                               row.names = FALSE,
                               quote = TRUE,
                               na = "")

                     # Remove progress notification
                     removeNotification(id = "save_csv_progress")

                     # Show success notification
                     showNotification(
                       paste0("CSV file saved successfully to:\n", basename(path_Save_File)),
                       type = "message",
                       duration = 5
                     )

                     # Log save event
                     cat(paste0(
                       "\n[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ",
                       "CE-Time corrected data saved as CSV to: ", path_Save_File,
                       " (", nrow(corrected_data), " peaks, ",
                       length(unique(corrected_data$sample)), " samples)\n"
                     ))

                   }, error = function(e) {
                     # Remove progress notification
                     removeNotification(id = "save_csv_progress")

                     # Show error notification
                     showNotification(
                       paste0("Error saving CSV file: ", e$message),
                       type = "error",
                       duration = 10
                     )

                     # Log error
                     cat(paste0(
                       "\n[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ",
                       "ERROR saving CE-Time data as CSV: ", e$message, "\n"
                     ))
                   })

                 } else {
                   # No data available
                   showNotification(
                     "No corrected data available. Please apply Kernel Density correction first.",
                     type = "warning",
                     duration = 5
                   )
                 }
               }
               # If path_Save_File is empty, user cancelled the dialog - no action needed
             })

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~ Validation Button Handler ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
observeEvent(input$validateCETimeCorrection, {
  # Show confirmation message
  showModal(modalDialog(
    title = "CE-Time Correction Complete - Step 5 Done",
    tags$div(
      style = "font-size: 15px;",
      tags$p(
        icon("check-circle", style = "color: green; font-size: 24px;"),
        tags$strong(" All samples have been successfully corrected!")
      ),
      tags$hr(),
      tags$h4("Correction Summary:"),
      tags$ul(
        tags$li(tags$strong("Total samples corrected: "), length(correctedSamples_KernelDensity())),
        tags$li(tags$strong("Correction method: "), "Kernel Density Estimation"),
        tags$li(tags$strong("Status: "), tags$span("Ready for export", style = "color: green; font-weight: bold;"))
      ),
      tags$hr(),
      tags$p(
        "You can now download the corrected data using the ",
        tags$strong("'Download Corrected Data (Excel)'"),
        " button below."
      ),
      tags$p(
        style = "color: #666; font-size: 13px;",
        "The Excel file will contain 3 sheets: Corrected peaks, Sample info, and Correction summary."
      )
    ),
    footer = tagList(
      modalButton("Close")
    ),
    easyClose = TRUE,
    size = "m"
  ))

  # Log validation event
  cat(paste0(
    "\n[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ",
    "CE-Time Correction Validated - ",
    length(correctedSamples_KernelDensity()), " samples ready for export\n"
  ))
})
