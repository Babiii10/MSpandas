##" Initialize reactive values
RvarsGrouping <- allReactiveVarsNewRefMap$Grouping

## Track additional file inputs with reactive values
additionalFilesState <- reactiveValues(
  counter = 1,           # Total number of files created
  activeFiles = c(1)     # IDs of currently active/visible files
)

## Load additional data merge library
source("lib/NewReferenceMap/R_files/AdditionalDataMerge.lib.R", local = TRUE)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Template Download Handler ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

## Download CSV template for additional data
output$downloadTemplate_NewRefMap <- downloadHandler(
  filename = function() {
    paste0("additional_data_template_", format(Sys.Date(), "%Y%m%d"), ".csv")
  },
  content = function(file) {
    templatePath <- "docs/additional_data_template.csv"
    if (file.exists(templatePath)) {
      file.copy(templatePath, file)
    } else {
      # Generate template on the fly if file doesn't exist
      template <- generateDataTemplate()
      write.csv(template, file, row.names = FALSE)
    }
  }
)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Dynamic File Inputs Management ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

## Add more file inputs
observeEvent(input$addMoreFiles_NewRefMap, {
  additionalFilesState$counter <- additionalFilesState$counter + 1
  additionalFilesState$activeFiles <- c(additionalFilesState$activeFiles, additionalFilesState$counter)
})

## Render dynamic file inputs
output$dynamicFileInputs_NewRefMap <- renderUI({
  activeFiles <- additionalFilesState$activeFiles

  # Only show files after the first one (first one is static in UI)
  filesToShow <- activeFiles[activeFiles > 1]

  if (length(filesToShow) > 0) {
    lapply(filesToShow, function(fileId) {
      fluidRow(
        column(
          8,
          fileInput(
            inputId = paste0("additionalDataFile_", fileId),
            label = paste0("Upload file ", fileId, " (CSV/XLSX)"),
            accept = c(".csv", ".xlsx", ".xls"),
            multiple = FALSE
          )
        ),
        column(
          4,
          div(
            style = "position:relative;top:25px",
            actionButton(
              inputId = paste0("removeFile_", fileId),
              label = "Remove",
              icon = icon("trash"),
              class = "btn-danger btn-sm"
            )
          )
        )
      )
    })
  }
})

## Dynamic observers for remove buttons
observe({
  activeFiles <- additionalFilesState$activeFiles

  # Create observers for each active file's remove button
  lapply(activeFiles, function(fileId) {
    if (fileId > 1) {  # Can't remove the first file
      observeEvent(input[[paste0("removeFile_", fileId)]], {
        # Remove this file ID from active files
        additionalFilesState$activeFiles <- additionalFilesState$activeFiles[
          additionalFilesState$activeFiles != fileId
        ]

        showNotification(
          paste("File", fileId, "removed"),
          type = "message",
          duration = 2
        )
      }, ignoreInit = TRUE)
    }
  })
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Load and Combine Additional Data ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

## Function to read uploaded files
readAdditionalFile <- function(filePath) {
  if (is.null(filePath) || !file.exists(filePath)) {
    return(NULL)
  }

  fileExt <- tools::file_ext(filePath)

  tryCatch({
    if (fileExt %in% c("csv", "txt")) {
      data <- read.csv(filePath, stringsAsFactors = FALSE)
    } else if (fileExt %in% c("xlsx", "xls")) {
      data <- openxlsx::read.xlsx(filePath)
    } else {
      return(NULL)
    }
    return(as.data.frame(data))
  }, error = function(e) {
    showNotification(
      paste("Error reading file:", basename(filePath), "-", e$message),
      type = "error",
      duration = 5
    )
    return(NULL)
  })
}

## Combine all uploaded files with existing data
combineAdditionalData <- reactive({
  if (!input$enableAdditionalData_NewRefMap) {
    return(NULL)
  }

  allFiles <- list()
  activeFiles <- additionalFilesState$activeFiles

  # Loop through only active files
  for (fileId in activeFiles) {
    fileInput <- input[[paste0("additionalDataFile_", fileId)]]
    if (!is.null(fileInput)) {
      fileData <- readAdditionalFile(fileInput$datapath)
      if (!is.null(fileData)) {
        allFiles[[length(allFiles) + 1]] <- fileData
      }
    }
  }

  if (length(allFiles) == 0) {
    return(NULL)
  }

  # Combine all uploaded files
  tryCatch({
    combinedData <- do.call("rbind", allFiles)
    return(combinedData)
  }, error = function(e) {
    showNotification(
      paste("Error combining files:", e$message),
      type = "error",
      duration = 5
    )
    return(NULL)
  })
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Control some buttons ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#~
## Return to Correction time
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReurnToCorrectionTime
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "CorrectionTimeStep",
                                  selected = "4")
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "CE-time correction")
               
             })


## Go to reference map viewer
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GroupingMassifNexPage
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "GenerateRefMapStep",
                                  selected = "2")
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Generate the reference map")
               
             })

# return to create reference map
observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ReturnToCreateMap
             }
             ,
             handlerExpr = {
               updateRadioButtons(session = session,
                                  inputId = "GenerateRefMapStep",
                                  selected = "1")
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Generate the reference map")
               
             })

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$ViewRefMapNextPage
             },
             handlerExpr = {
               updateNavbarPage(session = session,
                                inputId = "analysisNavbar",
                                selected = "Identification internal standards")
               
             })
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Grouping Massif ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GroupingButtonID
             }
             ,
             handlerExpr = {
               if (!is.null(RvarsCorrectionTime$peakListAligned_KernelDensity) &
                   !is.null(RvarsCorrectionTime$pheno_Data_mzML)) {
                 ## Load some functions:
                 source("lib/NewReferenceMap/R_files/GenerateMapRef.lib.R",
                        local = TRUE)

                 ## Change names of columns

                 Massif_List_ToGroup <-
                   RvarsCorrectionTime$peakListAligned_KernelDensity

                 ## Combine with additional uploaded data if available
                 additionalData <- combineAdditionalData()

                 if (!is.null(additionalData) && nrow(additionalData) > 0) {
                   # Validate that additional data has required columns
                   requiredCols <- c("M+H", "rt", "Area", "Height", "sample")

                   if (all(requiredCols %in% colnames(additionalData))) {
                     # Standardize column names if needed
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

                     # Fill missing columns in additional data with default values
                     for (col in colSelect) {
                       if (!(col %in% colnames(additionalData))) {
                         if (col %in% c("M+H.min", "M+H.max")) {
                           additionalData[[col]] <- additionalData[["M+H"]]
                         } else if (col %in% c("rtmin", "rtmax")) {
                           additionalData[[col]] <- additionalData[["rt"]]
                         } else if (col %in% c("SN")) {
                           additionalData[[col]] <- 100
                         } else if (col %in% c("iso.mass", "iso.mass.link", "mz_PeaksIsotopics_Group",
                                                "rt_PeaksIsotopics_Group", "Height_PeaksIsotopics_Group", "Adduct")) {
                           additionalData[[col]] <- ""
                         }
                       }
                     }

                     # Combine datasets
                     Massif_List_ToGroup <- rbind(Massif_List_ToGroup, additionalData[, colSelect])

                     showNotification(
                       paste("Combined", nrow(additionalData), "additional peaks with existing data"),
                       type = "message",
                       duration = 5
                     )
                   } else {
                     showNotification(
                       paste("Additional data missing required columns:",
                             paste(requiredCols[!requiredCols %in% colnames(additionalData)], collapse = ", ")),
                       type = "warning",
                       duration = 5
                     )
                   }
                 }
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
                 
                 colnames(Massif_List_ToGroup)[c(1:10)] <- colSelect[c(1:10)]
                 
                 
                 withProgress(message = 'Grouping massif to features...', value = 0, {
                   ####~~~~~~~~~~~~~~~~~~~~~~ Grouping massif in samples  ~~~~~~~~~~~~~~~~~~~~#
                   ####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   
                   incProgress(1 / 4, detail = "starting")
                   
                   Massif_List_ToGroup <-
                     split(Massif_List_ToGroup, f = Massif_List_ToGroup$sample)
                   
                   workers <- ceiling((detectCores()) - 1)
                   param <- SnowParam(workers = workers, type = "SOCK")
                   
                   
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
                   
                   res3 <- do.call("rbind", res2)
                   
                   res3 <- as.data.frame(res3)
                   rownames(res3) <- 1:nrow(res3)
                   RvarsGrouping$FeaturesList <- res3[,-ncol(res3)]
                   incProgress(1 / 4, detail = "finish")
                 })
                 
                 #### Grouping massif between samples
                 RvarsGrouping$FeaturesListGroupingBetweenSamples <-
                   Grouping.Between.Sample(
                     X = RvarsGrouping$FeaturesList,
                     ppm.tolerance = 0,
                     mz.tolerance = input$mzToleranceID,
                     rt.tolerance = input$rt_tolGroupingRefMap
                   )
                 
                 #"~~~~~~~ Enable Generate reference map button ~~~~~~~~#
                 
                 
                 sendSweetAlert(
                   session = session,
                   title = "Preprocess complete !",
                   text = HTML(
                     paste(
                       "Grouping features between sample well done !<br>",
                       "you can now 'Generate the reference map'"
                     )
                   ),
                   type = "success",
                   closeOnClickOutside = FALSE,
                   html = TRUE
                 )
                 
                 enable("GenerateMapRefButtonID")
               }
               
               
             })

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Generate Reference map ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$GenerateMapRefButtonID
             }
             ,
             handlerExpr = {
               if (!is.null(RvarsGrouping$FeaturesListGroupingBetweenSamples) &
                   !is.null(RvarsCorrectionTime$pheno_Data_mzML) &
                   !is.null(RvarsGrouping$FeaturesList)) {
                 ## Load some functions:
                 source("lib/NewReferenceMap/R_files/GenerateMapRef.lib.R",
                        local = TRUE)
                 
                 res <-
                   ExtractRefMap(
                     ref = RvarsGrouping$FeaturesListGroupingBetweenSamples,
                     peaksMassif = RvarsGrouping$FeaturesList,
                     pheno_Data = RvarsCorrectionTime$pheno_Data_mzML,
                     minFract = input$minFraction_RefMap,
                     prefixID = input$prefixID_NewRefMap
                   )
                 
                 
                 
                 ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Process duplicates peptides ~~~~~~~~~~~~~~~~~~~~~~#
                 ## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                 
                 ## Extract the reference map
                 refMap <- ProcessDuplicates(res$RefMap)
                 
                 Clnames_RefMap <- colnames(refMap)
                 
                 RvarsGrouping$RefereanceMap <-
                   data.frame(ID = createID(
                     ref = input$prefixID_NewRefMap,
                     number = nrow(refMap)
                   ),
                   refMap)
                 
                 
                 
                 rownames(RvarsGrouping$RefereanceMap) <-
                   RvarsGrouping$RefereanceMap$ID
                 
                 RvarsGrouping$RefereanceMap <- RvarsGrouping$RefereanceMap %>%
                   relocate(ID)
                 
                 colnames(RvarsGrouping$RefereanceMap)[-1] <- Clnames_RefMap
                 
                 ## Extract the matrix abundance
                 refMap2 <- RvarsGrouping$RefereanceMap
                 RvarsGrouping$MatrixAbundance <-
                   refMap2[, c(c(1:3), c(11:ncol(refMap2)))]
                 
                 
                 ## Enable the button for go toview reference map
                 enable("GroupingMassifNexPage")
                 enable("ViewRefMapNextPage")
                 
                 updateRadioButtons(session = session,
                                    inputId = "GenerateRefMapStep",
                                    selected = "2")
                 updateNavbarPage(session = session,
                                  inputId = "analysisNavbar",
                                  selected = "Generate the reference map")
                 
                 
                 sendSweetAlert(
                   session = session,
                   title = "Preprocess complete !",
                   text = HTML(paste("")),
                   type = "success",
                   closeOnClickOutside = FALSE,
                   html = TRUE
                 )
                 
                 # write.table(RvarsGrouping$RefereanceMap,
                 #             file = "C:/Users/mouhamed.seye.ADN/Desktop/Test Methodes Data/Process Sample-1/Reference Map Sample-1 Une fois Grouping/Refereance_Map.csv",
                 #             sep = ",", row.names =  FALSE)
                 #
                 # write.table(RvarsGrouping$MatrixAbundance,
                 #             file = "C:/Users/mouhamed.seye.ADN/Desktop/Test Methodes Data/Process Sample-1/Reference Map Sample-1 Une fois Grouping/Matrix_Abundance.csv",
                 #             sep = ",", row.names =  FALSE)
                 
                 
               }
               
             })


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Reference map Viewer ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observe({
  if (!is.null(RvarsGrouping$RefereanceMap) &&
      !is.null(RvarsGrouping$MatrixAbundance)) {
    ## zoom the plot
    rangesZoomMapRef <- reactiveValues(x = NULL, y = NULL)
    
    # When a double-click happens, check if there's a brush on the plot.
    # If so, zoom to the brush bounds; if not, reset the zoom.
    observeEvent({
      input$RefMapPlot_dblclick
    }, {
      brush <- input$RefMapPlot_brush
      if (!is.null(brush)) {
        rangesZoomMapRef$x <- c(brush$xmin, brush$xmax)
        rangesZoomMapRef$y <- c(brush$ymin, brush$ymax)
        
      } else {
        ## reset coord_cartesian
        rangesZoomMapRef$x <- NULL
        rangesZoomMapRef$y <- NULL
      }
    })
    
    
    shinyjs::show("RefMapPlotInfo_id")
    
    ## Plot when rt_min_RefMp and rt_max_RefMap are NA values
    observe({
      if (is.na(input$rt_min_RefMap) && is.na(input$rt_max_RefMap)) {
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        # Get all data
        referenceMap <- RvarsGrouping$RefereanceMap
        
        
        
        RvarsGrouping$RefereanceMap_selected <- referenceMap
        
        RvarsGrouping$MatrixAbundance_selected <-
          RvarsGrouping$MatrixAbundance[RvarsGrouping$RefereanceMap_selected$ID, ]
        
        rownames(RvarsGrouping$RefereanceMap_selected) <-
          createID(
            ref = input$prefixID_NewRefMap,
            number = nrow(RvarsGrouping$RefereanceMap_selected)
          )
        
        RvarsGrouping$RefereanceMap_selected$ID <-
          rownames(RvarsGrouping$RefereanceMap_selected)
        
        rownames(RvarsGrouping$MatrixAbundance_selected) <-
          rownames(RvarsGrouping$RefereanceMap_selected)
        ##########
        
        
        
        
        output$ReferenceMapViewer <- renderPlot({
          referenceMap %>%
            
            ggplot() +
            aes(x = rt, y = `M+H`) +
            #geom_point(shape = "circle", size = input$sizePointsMatch) +
            geom_point(size = 1, colour = "blue") +
            #scale_color_hue(direction = 1) +
            coord_cartesian(xlim = rangesZoomMapRef$x,
                            ylim = rangesZoomMapRef$y,
                            expand = TRUE) +
            ylab("Mass (M+H) (Da)") +
            xlab("CE-time (Second)") +
            ggtitle(
              paste(
                "REFRENCE MAP : ",
                input$Name_NewRefMap,
                "\n",
                "Number of features :",
                nrow(referenceMap)
              )
            ) +
            scale_x_continuous(n.breaks = 14) +
            scale_y_continuous(n.breaks = 14) +
            theme_ben() +
            theme(
              plot.title = element_text(
                size = rel(1),
                face = "bold",
                color = "#760001",
                margin = margin(0, 0, 5, 0),
                hjust = 0.5
              ),
              legend.title = element_text(
                size = rel(0.95),
                face = "bold.italic",
                hjust = 0.5
              ),
              legend.text = element_text(size = rel(0.90), face = "bold")
            )
        })
        
        
        # info for the position of the mouse
        output$RefMapPlot_info <- renderText({
          paste0(
            "Mouse position: ",
            xy_str(input$RefMap_hover, "CE-time", "M+H"),
            "Click: ",
            xy_str(input$RefMapPlot_click, "CE-time", "M+H")
          )
        })
        
        
        ## Bulle info
        
        #### info-bulle
        output$RefMapPlot_hover_info <- renderUI({
          hover <- req(input$RefMap_hover)
          
          point <- nearPoints(
            req(referenceMap),
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
          # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85);",
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
                  round(point$rt, 2),
                  "<br/>"
                )
              )))
          
        })
        
      }
      
    })
    
    ## Plot when filtered whith rt_min_RefMp and rt_max_RefMap values
    observeEvent(
      ignoreNULL = TRUE,
      eventExpr = {
        input$FilterRefmap
      },
      handlerExpr = {
        if (!is.na(input$rt_min_RefMap) && !is.na(input$rt_max_RefMap) &&
            !is.null(RvarsGrouping$RefereanceMap)) {
          rt_min <- min(RvarsGrouping$RefereanceMap$rt)
          rt_max <- max(RvarsGrouping$RefereanceMap$rt)
          
          # Update the data for reference map
          if (input$rt_min_RefMap > input$rt_max_RefMap) {
            sendSweetAlert(
              session = session,
              title = "Warning !",
              text = HTML("'CE-time max' must be more than 'CE-time min'"),
              type = "warning",
              html = TRUE
            )
            
          } else if (rt_min > input$rt_min_RefMap |
                     rt_max < input$rt_min_RefMap) {
            sendSweetAlert(
              session = session,
              title = "Warning !",
              text = HTML(
                paste(
                  "'CE-time min' must between",
                  round(rt_min, 0),
                  " and ",
                  round(rt_max, 0)
                )
              ),
              type = "warning",
              html = TRUE
            )
          } else if (rt_min > input$rt_max_RefMap |
                     rt_max < input$rt_max_RefMap) {
            sendSweetAlert(
              session = session,
              title = "Warning !",
              text = HTML(
                paste(
                  "'CE-time max' must between",
                  round(rt_min, 0),
                  " and ",
                  round(rt_max, 0)
                )
              ),
              type = "warning",
              html = TRUE
            )
            
          } else{
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            # Get all data
            referenceMap <- RvarsGrouping$RefereanceMap
            
            
            # Update the data for reference map
            
            RvarsGrouping$RefereanceMap_selected <- referenceMap %>%
              dplyr::filter(rt >= input$rt_min_RefMap, rt <= input$rt_max_RefMap)
            
            RvarsGrouping$MatrixAbundance_selected <-
              RvarsGrouping$MatrixAbundance[RvarsGrouping$RefereanceMap_selected$ID, ]
            
            rownames(RvarsGrouping$RefereanceMap_selected) <-
              createID(
                ref = input$prefixID_NewRefMap,
                number = nrow(RvarsGrouping$RefereanceMap_selected)
              )
            
            RvarsGrouping$RefereanceMap_selected$ID <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            
            rownames(RvarsGrouping$MatrixAbundance_selected) <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            ##########
            
            
            
            #Plot
            output$ReferenceMapViewer <- renderPlot({
              referenceMap %>%
                
                ggplot() +
                aes(x = rt, y = `M+H`) +
                #geom_point(shape = "circle", size = input$sizePointsMatch) +
                geom_point(size = 1, colour = "blue") +
                #scale_color_hue(direction = 1) +
                coord_cartesian(xlim = rangesZoomMapRef$x,
                                ylim = rangesZoomMapRef$y,
                                expand = TRUE) +
                geom_vline(
                  xintercept = isolate(input$rt_min_RefMap),
                  color = "gray",
                  linetype = "dashed"
                ) +
                geom_vline(
                  xintercept = isolate(input$rt_max_RefMap),
                  color = "gray",
                  linetype = "dashed"
                ) +
                ggplot2::annotate(
                  "rect",
                  xmin = c(0, isolate(input$rt_max_RefMap)),
                  xmax = c(isolate(input$rt_min_RefMap), Inf),
                  ymin = -Inf ,
                  ymax = Inf,
                  alpha = 0.5,
                  fill = "gray"
                ) +
                ylab("Mass (M+H) (Da)") +
                xlab("CE-time (Second)") +
                ggtitle(
                  paste(
                    "REFRENCE MAP : ",
                    input$Name_NewRefMap,
                    "\n",
                    "Number of features :",
                    nrow(RvarsGrouping$RefereanceMap_selected)
                  )
                ) +
                scale_x_continuous(n.breaks = 14) +
                scale_y_continuous(n.breaks = 14) +
                theme_ben() +
                theme(
                  plot.title = element_text(
                    size = rel(1),
                    face = "bold",
                    color = "#760001",
                    margin = margin(0, 0, 5, 0),
                    hjust = 0.5
                  ),
                  legend.title = element_text(
                    size = rel(0.95),
                    face = "bold.italic",
                    hjust = 0.5
                  ),
                  legend.text = element_text(size = rel(0.90), face = "bold")
                )
            })
            
            
            
            # info for the position of the mouse
            output$RefMapPlot_info <- renderText({
              paste0(
                "Mouse position: ",
                xy_str(input$RefMap_hover, "CE-time", "M+H"),
                "Click: ",
                xy_str(input$RefMapPlot_click, "CE-time", "M+H")
              )
            })
            
            ## Bulle info
            
            #### info-bulle
            output$RefMapPlot_hover_info <- renderUI({
              hover <- req(input$RefMap_hover)
              
              if (!is.null(RvarsGrouping$RefereanceMap_selected)) {
                point <- nearPoints(
                  req(RvarsGrouping$RefereanceMap_selected),
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
                # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85);",
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
                        round(point$rt, 2),
                        "<br/>"
                      )
                    )))
              }
              
            })
            
            
          }
          
          
          
          
        } else if (!is.na(input$rt_min_RefMap) &&
                   is.na(input$rt_max_RefMap) &&
                   !is.null(RvarsGrouping$RefereanceMap_selected)) {
          rt_min <- min(RvarsGrouping$RefereanceMap$rt)
          rt_max <- max(RvarsGrouping$RefereanceMap$rt)
          
          if (rt_min > input$rt_min_RefMap |
              rt_max < input$rt_min_RefMap) {
            sendSweetAlert(
              session = session,
              title = "Warning !",
              text = HTML(
                paste(
                  "'CE-time min' must between",
                  round(rt_min, 0),
                  " and ",
                  round(rt_max, 0)
                )
              ),
              type = "warning",
              html = TRUE
            )
            
          } else {
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            # Get all data
            referenceMap <- RvarsGrouping$RefereanceMap
            
            
            # Update the data for reference map
            
            RvarsGrouping$RefereanceMap_selected <- referenceMap %>%
              dplyr::filter(rt >= input$rt_min_RefMap)
            
            RvarsGrouping$MatrixAbundance_selected <-
              RvarsGrouping$MatrixAbundance[RvarsGrouping$RefereanceMap_selected$ID, ]
            
            rownames(RvarsGrouping$RefereanceMap_selected) <-
              createID(
                ref = input$prefixID_NewRefMap,
                number = nrow(RvarsGrouping$RefereanceMap_selected)
              )
            
            RvarsGrouping$RefereanceMap_selected$ID <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            
            rownames(RvarsGrouping$MatrixAbundance_selected) <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            ##########
            
            
            
            
            
            
            
            #Plot
            output$ReferenceMapViewer <- renderPlot({
              referenceMap %>%
                
                ggplot() +
                aes(x = rt, y = `M+H`) +
                #geom_point(shape = "circle", size = input$sizePointsMatch) +
                geom_point(size = 1, colour = "blue") +
                #scale_color_hue(direction = 1) +
                coord_cartesian(xlim = rangesZoomMapRef$x,
                                ylim = rangesZoomMapRef$y,
                                expand = TRUE) +
                geom_vline(
                  xintercept = isolate(req(input$rt_min_RefMap)),
                  color = "gray",
                  linetype = "dashed"
                ) +
                ggplot2::annotate(
                  "rect",
                  xmin = 0,
                  xmax = isolate(req(input$rt_min_RefMap)),
                  ymin = -Inf ,
                  ymax = Inf,
                  alpha = 0.5,
                  fill = "gray"
                ) +
                ylab("Mass (M+H) (Da)") +
                xlab("CE-time (Second)") +
                ggtitle(
                  paste(
                    "REFRENCE MAP : ",
                    input$Name_NewRefMap,
                    "\n",
                    "Number of features :",
                    nrow(RvarsGrouping$RefereanceMap_selected)
                  )
                ) +
                scale_x_continuous(n.breaks = 14) +
                scale_y_continuous(n.breaks = 14) +
                theme_ben() +
                theme(
                  plot.title = element_text(
                    size = rel(1),
                    face = "bold",
                    color = "#760001",
                    margin = margin(0, 0, 5, 0),
                    hjust = 0.5
                  ),
                  legend.title = element_text(
                    size = rel(0.95),
                    face = "bold.italic",
                    hjust = 0.5
                  ),
                  legend.text = element_text(size = rel(0.90), face = "bold")
                )
            })
            
            # info for the position of the mouse
            output$RefMapPlot_info <- renderText({
              paste0(
                "Mouse position: ",
                xy_str(input$RefMap_hover, "CE-time", "M+H"),
                "Click: ",
                xy_str(input$RefMapPlot_click, "CE-time", "M+H")
              )
            })
            
            ## Bulle info
            
            #### info-bulle
            output$RefMapPlot_hover_info <- renderUI({
              hover <- req(input$RefMap_hover)
              
              if (!is.null(RvarsGrouping$RefereanceMap_selected)) {
                point <- nearPoints(
                  req(RvarsGrouping$RefereanceMap_selected),
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
                # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85);",
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
                        round(point$rt, 2),
                        "<br/>"
                      )
                    )))
              }
              
            })
          }
          
          
          
        } else if (is.na(input$rt_min_RefMap) &&
                   !is.na(input$rt_max_RefMap) &&
                   !is.null(RvarsGrouping$RefereanceMap)) {
          rt_min <- min(RvarsGrouping$RefereanceMap$rt)
          rt_max <- max(RvarsGrouping$RefereanceMap$rt)
          
          if (rt_min > input$rt_max_RefMap |
              rt_max < input$rt_max_RefMap) {
            sendSweetAlert(
              session = session,
              title = "Warning !",
              text = HTML(
                paste(
                  "'CE-time max' must between",
                  round(rt_min, 0),
                  " and ",
                  round(rt_max, 0)
                )
              ),
              type = "warning",
              html = TRUE
            )
            
          } else {
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            # Get all data
            referenceMap <- RvarsGrouping$RefereanceMap
            
            
            # Update the data for reference map
            
            RvarsGrouping$RefereanceMap_selected <- referenceMap %>%
              dplyr::filter(rt <= input$rt_max_RefMap)
            
            RvarsGrouping$MatrixAbundance_selected <-
              RvarsGrouping$MatrixAbundance[RvarsGrouping$RefereanceMap_selected$ID, ]
            
            rownames(RvarsGrouping$RefereanceMap_selected) <-
              createID(
                ref = input$prefixID_NewRefMap,
                number = nrow(RvarsGrouping$RefereanceMap_selected)
              )
            
            RvarsGrouping$RefereanceMap_selected$ID <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            
            rownames(RvarsGrouping$MatrixAbundance_selected) <-
              rownames(RvarsGrouping$RefereanceMap_selected)
            ##########
            
            
            
            ## Plot
            output$ReferenceMapViewer <- renderPlot({
              referenceMap %>%
                
                ggplot() +
                aes(x = rt, y = `M+H`) +
                #geom_point(shape = "circle", size = input$sizePointsMatch) +
                geom_point(size = 1, colour = "blue") +
                #scale_color_hue(direction = 1) +
                coord_cartesian(xlim = rangesZoomMapRef$x,
                                ylim = rangesZoomMapRef$y,
                                expand = TRUE) +
                geom_vline(
                  xintercept = isolate(req(input$rt_max_RefMap)),
                  color = "gray",
                  linetype = "dashed"
                ) +
                ggplot2::annotate(
                  "rect",
                  xmin = isolate(req(input$rt_max_RefMap)),
                  xmax = Inf,
                  ymin = -Inf ,
                  ymax = Inf,
                  alpha = 0.5,
                  fill = "gray"
                ) +
                ylab("Mass (M+H) (Da)") +
                xlab("CE-time (Second)") +
                ggtitle(
                  paste(
                    "REFRENCE MAP : ",
                    input$Name_NewRefMap,
                    "\n",
                    "Number of features :",
                    nrow(RvarsGrouping$RefereanceMap_selected)
                  )
                ) +
                scale_x_continuous(n.breaks = 14) +
                scale_y_continuous(n.breaks = 14) +
                theme_ben() +
                theme(
                  plot.title = element_text(
                    size = rel(1),
                    face = "bold",
                    color = "#760001",
                    margin = margin(0, 0, 5, 0),
                    hjust = 0.5
                  ),
                  legend.title = element_text(
                    size = rel(0.95),
                    face = "bold.italic",
                    hjust = 0.5
                  ),
                  legend.text = element_text(size = rel(0.90), face = "bold")
                )
            })
            
            # info for the position of the mouse
            output$RefMapPlot_info <- renderText({
              paste0(
                "Mouse position: ",
                xy_str(input$RefMap_hover, "CE-time", "M+H"),
                "Click: ",
                xy_str(input$RefMapPlot_click, "CE-time", "M+H")
              )
            })
            
            ## Bulle info
            
            #### info-bulle
            output$RefMapPlot_hover_info <- renderUI({
              hover <- req(input$RefMap_hover)
              
              if (!is.null(RvarsGrouping$RefereanceMap_selected)) {
                point <- nearPoints(
                  req(RvarsGrouping$RefereanceMap_selected),
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
                # style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85);",
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
                        round(point$rt, 2),
                        "<br/>"
                      )
                    )))
              }
              
            })
          }
          
          
        }
      }
    )
    
    
  }
})

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Data table Reference map Viewer ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
output$dataTableRefernceMapViewer <- renderDT({
  if (!is.null(RvarsGrouping$RefereanceMap_selected)) {
    datatable(RvarsGrouping$RefereanceMap_selected)
  }
})
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#
# observe({
#   if(!is.null(RvarsGrouping$RefereanceMap_selected) & !is.null(RvarsGrouping$MatrixAbundance_selected)){
#     View(RvarsGrouping$RefereanceMap_selected)
#     View(RvarsGrouping$MatrixAbundance_selected)
#   }
# })



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~ Saving the reference map ~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

observeEvent(ignoreNULL = TRUE,
             eventExpr = {
               input$SaveMatrixBeforeNormalize
             }
             ,
             handlerExpr = {
               shinyFileSave(input,
                             id = "SaveMatrixBeforeNormalize",
                             roots = volumes,
                             session = session)
               
               
               
               path_Save_Files_origine <-
                 parseSavePath(volumes, input$SaveMatrixBeforeNormalize)$datapath
               
               if (length(path_Save_Files_origine) > 0) {
                 path_Save_Files <- strsplit(path_Save_Files_origine, split = "/")[[1]]
                 directory_Save_Files <-
                   paste0(path_Save_Files[-length(path_Save_Files)], collapse = "/")
                 
                 if (!is.null(RvarsGrouping$MatrixAbundance_selected)) {
                   Matrix_Abundance_Before <- RvarsGrouping$MatrixAbundance_selected
                   
                   # Format xlsx
                   write.xlsx(Matrix_Abundance_Before,
                              file = paste0(c(
                                directory_Save_Files,
                                paste(path_Save_Files[length(path_Save_Files)],
                                      collapse = "", sep = "-")
                              ), collapse = "/"))
                   
                   
                   # Format csv
                   # write.table(Matrix_Abundance_Before,
                   #             file = paste0(c(directory_Save_Files,
                   #                             paste(
                   #                               path_Save_Files[length(path_Save_Files)],
                   #                               collapse = "", sep = "-")), collapse = "/"),
                   #             sep = ",", row.names = FALSE)
                   print("Save ok")
                   
                 }
                 
               }
               
               
             })


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
###~~~~~~~~~~~~~~~~~~~~~~~~~ Manage somes iputs values  ~~~~~~~~~~~~~~~~~~~~~~~###
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

observe({
  if (length(input$groupingMassifChoice_NewRefMap) != 0) {
    if (input$groupingMassifChoice_NewRefMap == "defaults") {
      shinyjs::reset("rt_tolGroupingRefMap")
      shinyjs::reset("mzToleranceID")
    }
    
  }
  
  if (length(input$generateParameters_NewRefMap) != 0) {
    if (input$generateParameters_NewRefMap == "defaults") {
      shinyjs::reset("minFraction_RefMap")
      shinyjs::reset("prefixID_NewRefMap")
    }
    
  }
  
  
})
