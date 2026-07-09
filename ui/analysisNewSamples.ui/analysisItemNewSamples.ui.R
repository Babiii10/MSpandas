analysisTabPanelNewSamples <- function() {
  fluidRow(
    #### Analysis step
    hidden(div(
      radioButtons(
        inputId = "IdAnalysisStep",
        label = "",
        inline = TRUE,
        choices = c("1", "2", "3", "4"),
        selected = "1"
      )
    )),
    
    conditionalPanel(condition = "input.IdAnalysisStep=='1'",
                     analysisTabPanelNewSamplesContainer()),
    
    conditionalPanel(condition = "input.IdAnalysisStep=='2'",
                     analysisTabPanelNewSamples_Filtering()),
    
    
    conditionalPanel(
      condition = "input.IdAnalysisStep=='3'",
      analysisTabPanelNewSamplesAlignementGrouping()
    ),
    
    conditionalPanel(condition = "input.IdAnalysisStep=='4'",
                     analysisTabPanelNewSamplesViewer())
    
    
    
    
  )
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

analysisTabPanelNewSamplesContainer <- function() {
  fluidRow(column(
    12,
    HTML('<h4>Step 1 : Peak detection</h4>'),
    hr(),
    
    tabsetPanel(
      id = "AnalysisProject",
      
      tabPanel(fluidRow(br()),
               title = "New analysis",
               
               fluidRow(
                 column(6,
                        
                        
                        
                        # Project info
                        fluidRow(column(
                          12,
                          
                          ##### Data collection
                          div(
                            class = "well well-sm",
                            h4("Data collection"),
                            
                            selectInput(
                              inputId = "chosseRef",
                              label = "Choose a reference map",
                              choices = ref_map
                            ),
                            
                            awesomeRadio(
                              inputId = "IdDataType",
                              label = NULL,
                              inline = TRUE,
                              checkbox = TRUE,
                              choices = list(
                                "Use defaults (CE-MS/Profile)" = "defaults",
                                "Customize" = "custom"
                              )
                            ),
                            
                            conditionalPanel(
                              condition = "input.IdDataType == 'custom'",
                              radioButtons(
                                inputId = "dataType",
                                label = "Data type",
                                inline = TRUE,
                                choices = list(
                                  "CE-MS or LC-MS" = "MS1",
                                  "CE-MS/MS or LC-MS/MS" =
                                    "MS2"
                                )
                              ),
                              
                              
                              fluidRow(
                                column(
                                  6,
                                  selectInput(
                                    inputId = "MS1_type",
                                    label =
                                      "MS1 type",
                                    choices =
                                      list("Profile" = "Profile",
                                           "Centroid" =
                                             "Centroid")
                                  )
                                ),
                                conditionalPanel(condition = "input.dataType=='MS2'",
                                                 column(
                                                   6,
                                                   selectInput(
                                                     inputId = "MS2_type",
                                                     label =
                                                       "MS2 type",
                                                     choices =
                                                       list("Profile" = "Profile",
                                                            "Centroid" =
                                                              "Centroid"),
                                                     selected =
                                                       "Profile"
                                                   )
                                                 ))
                              )
                            )
                            
                          ),
                          
                          hr(),
                          
                          ### New data files
                          div(
                            class = "well well-sm",
                            div(class = "info",
                                h4(
                                  "New data files",
                                  icon(
                                    "question-circle",
                                    class = "myIcoInfo",
                                    title = "Please put all files to be analyzed in a working directory.
For processing fast, put maximum 10 files.
The accepted formats are: major MS vendor formats including: d, mzML and raw.
Load the directory containing the files to be analyzed."
                                  )
                                ),),
                            ###### directory input for new sample
                            
                            
                            
                            fluidRow(column(12,
                                            div(
                                              title =
                                                HTML('Accepted formats are: d, mzML, raw'),
                                              directoryInput(
                                                inputId = "directory",
                                                label = "Folder path (raw data)",
                                                value = "Choose working directory"
                                              ),
                                              #verbatimTextOutput("value",placeholder = TRUE),
                                              
                                              
                                            ))),
                            textInput(
                              inputId = "projectName",
                              label = "Project name (100 chars max)",
                              value = "Analysis new samples",
                              placeholder = "Project name"
                            )
                          ),
                          
                          
                          
                        )),
                        
                        fluidRow(column(
                          4,
                          div(
                            class = "pull-left",
                            style = "display:inline-block",
                            actionButton(
                              inputId = "runPeakPicking",
                              label =
                                "Execute",
                              class =
                                "btn-primary",
                              icon =
                                icon("rocket")
                            )
                          )
                        ),
                        hidden(
                          div(id = "buttonResetViewAnalysis",
                              column(
                                4,
                                div(
                                  class = "pull-center",
                                  style = "display:inline-block",
                                  actionButton(
                                    inputId = "RestartProjects",
                                    label =
                                      "Reset all",
                                    class =
                                      "btn btn-danger",
                                    icon =
                                      icon("undo")
                                  )
                                )
                              ),
                              column(
                                4,
                                div(
                                  class = "pull-right",
                                  style = "display:inline-block",
                                  actionButton(
                                    inputId = "ViewAnalysis",
                                    label =
                                      "View results",
                                    class =
                                      "btn-primary",
                                    icon =
                                      icon("eye")
                                  )
                                )
                              ))
                        ))),
                 
                 #### Preprocessing
                 column(6,
                        hidden(
                          div(
                            id = "idpanel_analysisProgress",
                            conditionalPanel(condition =
                                               "input.runPeakPicking>=1",
                                             fluidRow(column(
                                               12,
                                               wellPanel(
                                                 div(id = "analysisProgress",
                                                     style =
                                                       "font-size: 1.2em; margin-bottom: 5px;",
                                                     ""),
                                                 hidden(div(
                                                   id = "progressWrapper",
                                                   div(class =
                                                         "progressbar-header",
                                                       id =
                                                         "progressBarHeader_analysis_pre", ""),
                                                   progressBar(
                                                     id = "preprocessProgressBar",
                                                     value =
                                                       1,
                                                     display_pct =
                                                       TRUE,
                                                     status =
                                                       "primary",
                                                     striped =
                                                       TRUE
                                                   ),
                                                   div(class =
                                                         "progressbar-footer",
                                                       id =
                                                         "progressBarFooter_analysis_pre", "")
                                                 )),
                                                 class =
                                                   "well-panel"
                                               )
                                             )))
                          )
                        ))
               )),
      
      tabPanel(fluidRow(br()),
               title = "Upload massif list files",
               fluidRow(column(
                 7,
                 
                 ##Import massif list files
                 hr(),
                 div(
                   class = "well well-sm",
                   div(
                     id = "RetentionTimeFiltering_id_newSample",
                     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                     div(class = "info",
                         h4(
                           "Import massif list files",
                           icon(
                             "question-circle",
                             class = "myIcoInfo",
                             title = "Here you can upload the massif list files for new samples if exist and continue the analyze.
The files must contain columns: 'M+H', 'M+H.min','M+H.max', 'CE-time','CE-time.min','CE-time.max', 'integrated-intensity', 'intensity','sn', 'sample', '
iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group', 'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group' and 'Adduct'."
                           )
                         )),
                     fileInput(
                       inputId = "massif_list_newSample",
                       label = "Upload massif list files (accept .csv)",
                       accept = c(".csv"),
                       multiple = TRUE,
                       width = "100%"
                     ),
                     hr(),
                     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                     #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
                   )
                 ),
                 
                 fluidRow(
                   div(id = "buttonResetViewAnalysis_duplicate",
                       column(6,
                              div(
                                class="pull-left",
                                style="display:inline-block",
                                )
                              ),
                              column(
                                6,
                                div(
                                  class = "pull-right",
                                  style = "display:inline-block",
                                  disabled(
                                    actionButton(
                                      inputId = "ViewAnalysis_duplicate",
                                      label =
                                        "Next",
                                      class =
                                        "btn-primary",
                                      icon = icon("arrow-right")
                                    )
                                  )
                                )
                              )
                       
                       
                       
                   )
                   
                   
                 )))
      )
      
      
    )
    )
    )
    
    
    
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

analysisTabPanelNewSamples_Filtering <- function() {
  fluidRow(column(
    12,
    
    HTML('<h4>Step 2 : Filter samples </h4>'),
    hr(),
    fluidRow(
      column(
        5,
        
        div(
          class = "well well-sm",
          div(
            id = "RetentionTimeFiltering_id_newSample",
            
            h4("Retention time filtering"),
            fluidRow(column(10,
                            uiOutput(
                              "SelectSampleCut"
                            ),)),
            uiOutput("titleTimefilter_newSample"),
            fluidRow(
              column(
                4,
                align = "center",
                numericInput(
                  inputId = "rt_min_cut_newSample",
                  label = "Min",
                  value = NULL,
                  min = 0
                )
              ),
              column(
                4,
                align = "center",
                numericInput(
                  inputId = "rt_max_cut_newSample",
                  label = "Max",
                  value = NULL,
                  min = 0
                )
              ),
              column(4, div(
                style = "position:relative;top:20px",
                actionButton(
                  inputId = "cutOff_newSample",
                  label =
                    "Cut-off",
                  class =
                    "btn-primary",
                  icon = icon("scissors")
                )
              ))
            )
            
          ),
          hr(),
          fluidRow(
            div(id = "id_validCuttingRun_newSample",
                column(
                  6,
                  div(
                    class = "pull-left",
                    style = "display:inline-block",
                    actionButton(
                      inputId = "validCuttingRun_newSample",
                      label =
                        "Finsh",
                      class =
                        "btn-primary",
                      icon = icon("check-circle")
                    )
                  )
                )),
            
            hidden(div(id = "id_ResetCuttingRun_newSample",
                       column(
                         6,
                         div(
                           class = "pull-left",
                           style = "display:inline-block",
                           actionButton(
                             inputId = "ResetCuttingRun_newSample",
                             label = "Reset",
                             icon = icon("undo"),
                             class = "btn btn-danger"
                           )
                         )
                       ))),
          )
        ),
        
        fluidRow(br()),
        fluidRow(br()),
        fluidRow(br()),
        hr(),
        
        fluidRow(column(
          6,
          div(
            class = "pull-left",
            style = "display:inline-block",
            actionButton(
              inputId = "ReturnToPeakViewer_newSample",
              label = "Return",
              class = "btn-primary",
              icon = icon("arrow-left")
            )
            
          )
        ),
        column(
          6,
          div(
            class = "pull-right",
            style = "display:inline-block",
            disabled(
              actionButton(
                inputId = "GoToPeakView_newSample",
                label = "Next",
                class = "btn-primary",
                icon = icon("arrow-right")
              )
            )
            
            
          )
        ))
        
      ),
      column(7,
             fluidRow(column(12,
                             hidden(
                               div(
                                 id = "id_PlotCutt_newSample",
                                 style = "position:relative",
                                 shinycssloaders::withSpinner(
                                   plotOutput(
                                     "sample_selectedCutting_Plot_newSample",
                                     width = "100%",
                                     height = "400px",
                                     dblclick = "sample_selectedCutting_dblclick_newSample",
                                     click = "sample_selectedCutting_click_newSample",
                                     brush = brushOpts(id = "sample_selectedCutting_brush_newSample",
                                                       resetOnNew = TRUE),
                                     hover = hoverOpts(
                                       "sample_selectedCutting_hover_newSample",
                                       delay = 100,
                                       delayType = "debounce"
                                     )
                                     
                                   ),
                                   type = 1,
                                   size = 0.8
                                 ),
                                 uiOutput("sample_selectedCutting_hover_info_newSample"),
                                 
                                 hidden(
                                   div(
                                     id = "UnitTime_sampleCutting_id_newSample",
                                     class = "pull-left",
                                     style = "display:inline-block;",
                                     awesomeRadio(
                                       inputId = "UnitTime_sampleCutting_newSample",
                                       label = "Unit of CE-time",
                                       choices = c("Second" = "Second",
                                                   "Minute" = "Minute"),
                                       inline = TRUE,
                                       checkbox = TRUE
                                     )
                                   )
                                 )
                               )
                             ))),
             fluidRow(column(12,
                             hidden(
                               div(
                                 id = "mousepositionSampleCutting_newSample",
                                 style = "font-weight:bold;width: 100%; color: #000;",
                                 verbatimTextOutput("sample_selectedCutting_Plot_info_newSample")
                                 
                                 
                               )
                             ))))
    )
  ))
}







#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~CE-time correction with kernel density~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

analysisTabPanelNewSamplesAlignementGrouping <- function() {
  fluidRow(column(
    12,
    HTML(
      '<h4>Step 3: CE-time correction with kernel density and grouping </h4>'
    ),
    hr(),
    fluidRow(
      column(
        5,
        div(id = "IDPanelCorrectimeKernelDensity_newSample",
            class = "well well-sm",
            
            fluidRow(column(
              10,
              pickerInput(
                inputId = "SelectSample_KernelDensity_newSample",
                label = "Select a sample:",
                choices = NULL,
                options = pickerOptions(
                  liveSearch = TRUE,
                  size = 10,
                  showTick = TRUE,
                  style = "btn-primary"
                ),
                width = "100%"
              )
            ))),
        ##~~~~~~~~~~~~~~~~~~ Parameters for filter density kernel ~~~~~~~~~~~~#
        ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        div(
          class = "well well-sm",
          h4("Filter with kernel density:"),
          sliderInput(
            "bandwidth_Filter_newSample",
            "Bandwidth",
            min = 1,
            max = 500,
            value = 20
          ),
          fluidRow(
            hidden(column(
              6,
              numericInput(
                inputId = "gridSize_newSample",
                label = "Grid size (n)",
                value = 500
              )
            )),
            column(
              6,
              numericInput(
                inputId = "intensityFilter_newSample",
                label = "Intensity filter",
                min = 0,
                value = 0
              )
              
            ),
            column(
              6,
              numericInput(
                inputId = "minDensity_newSample",
                label = "Min density",
                min = 0,
                max = 1,
                step = 0.01,
                value = 0.15
              )
            )
          )
          
        ),
        
        ##~~~~~~~~~~~~~~~~~~ Parameters for correction model with kernel density ~~~~~~~~~~~~#
        ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
        div(
          class = "well well-sm",
          h4("Correction model with Kernel density:"),
          selectInput(
            inputId = "KernelType_newSample",
            label = "Kernel type: ",
            choices = list(
              "Gaussian" = "gaussian",
              "Truncated gaussian" = "truncated gaussian",
              "Epanechnikov" = "epanechnikov",
              "Uniform" = "uniform"
            )
          ),
          
          sliderInput(
            "bandwidth_Model_newSample",
            "Bandwidth:",
            min = 1,
            max = 1000,
            value = 100
          ),
          fluidRow(column(
            6,
            div(
              class = "pull-left",
              style = "display:inline-block",

              actionButton(
                inputId = "fitModel_newSample",
                label = "Adjust CE-time",
                icon = icon("rocket"),
                class = "btn-primary"
              )

            )
          ),
          column(
            6,
            div(
              class = "pull-right",
              style = "display:inline-block",

              actionButton(
                inputId = "Finish_fitModel_newSample",
                label = "Finish",
                class = "btn-primary"
              )

            )
          )),

          fluidRow(
            column(
              12,
              div(
                class = "text-center",
                style = "margin-top: 8px;",
                actionButton(
                  inputId = "btn_view_rt_dist_newSample",
                  label = "View RT distribution",
                  icon = icon("eye"),
                  class = "btn-default"
                )
              )
            )
          )

        ),
        
        div(
          class = "well well-sm",
          
          h4("Grouping massif into features:"),
          fluidRow(br()),
          fluidRow(column(
            6,
            div(
              class = "pull-left",
              style = "display:inline-block",
              disabled(
                actionButton(
                  inputId = "GroupingButtonIDNewSample",
                  label = "Start grouping",
                  icon = icon("rocket"),
                  class = "btn-primary"
                )
              )
            )
          )),
          hr(),
        ),
        
        fluidRow(column(
          6,
          div(
            class = "pull-left",
            style = "display:inline-block",
            actionButton(
              inputId = "ReturToFilterSample_newSample",
              label = "Return",
              class = "btn-primary",
              icon = icon("arrow-left")
            )
            
          )
        ),
        column(
          6,
          div(
            class = "pull-right",
            style = "display:inline-block",
            disabled(
              actionButton(
                inputId = "CorrectionKernelDensityNexPage_newSample",
                label = "Next",
                class = "btn-primary",
                icon = icon("arrow-right")
              )
            )
          )
        ))
        
      ),
      column(
        7,
        
        tabsetPanel(
          id = "TabPanelKernelDensityFilter_ID_newSample",
          
          tabPanel(
            fluidRow(br()),
            title = "CE-time Correction",
            
            
            ##~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~###
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            h4("Density filter:"),
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "DensityFilterPlot_newSample",
                  width = "100%",
                  height = "450px"
                ),
                type = 1,
                size = 0.8
              )
            ),
            
            ##~~~~~~~~~~~~~~~ Correction time ~~~~~~~~~~~~~###
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            ###~~~~~Before correction~~~~~~~~##
            fluidRow(br()),
            h4("Correction model:"),
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "PlotCorrectionKernelDensity_Before_newSample",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "PlotCorrectionKernelDensity_Before_hover_newSample",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput(
                "PlotCorrectionKernelDensity_Before_hover_info_newSample"
              ),
              
            ),
            
            ###~~~~~After correction~~~~~~~~##
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "PlotCorrectionKernelDensity_After_newSample",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "PlotCorrectionKernelDensity_After_hover_newSample",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput("PlotCorrectionKernelDensity_After_hover_info_newSample"),
              
            )
          ),
          
          tabPanel(
            fluidRow(br()),
            title = "Distribution: M+H vs CE-Time",
            
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "CorrectimeKernelDensityViewer_2_newSample",
                  width = "100%",
                  height = "650px"
                ),
                type = 1,
                size = 0.8
              )
            )
            
          )
        )
        
        
      )
    )
  ))
  
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

analysisTabPanelNewSamplesViewer <- function() {
  fluidRow(column(
    12,
    
    HTML('<h4>Visualization of peak detection </h4>'),
    hr(),
    div(
      id = "NewSampleViewer",
      div(
        pickerInput(
          inputId = "levelSample",
          label = "Select/deselect sample(s) (to viewer):",
          choices = NULL,
          selected = NULL,
          options = pickerOptions(
            actionsBox = TRUE,
            size = 10,
            selectedTextFormat = "count",
            style = "btn-primary"
          ),
          multiple = TRUE
        )
        
      ),
      
      dropdown(
        tags$h4("Visual parameters"),
        
        fluidRow(column(
          12,
          wellPanel(
            radioGroupButtons(
              inputId = "UnitTime",
              label = "Unit of CE-time.",
              choices = c("Second",
                          "Minute"),
              checkIcon = list(
                yes = tags$i(class = "fa fa-check-square",
                             style = "color: steelblue"),
                no = tags$i(class = "fa fa-square-o",
                            style = "color: steelblue")
              )
            ),
            
            radioButtons(
              inputId = "ViewSizePoints",
              label = "Size for points:",
              inline = TRUE,
              choices = list("Use defaults" =
                               "defaults",
                             "Change size" = "custom")
            ),
            conditionalPanel(
              condition = "input.ViewSizePoints=='custom'",
              sliderInput(
                inputId = "sizePoints",
                label = NULL,
                min = 0.5,
                max = 2,
                value = 0.7
              )
            )
            
            
          )
        )),
        
        
        style = "unite",
        icon = icon("search-plus", class = "opt"),
        status = "primary",
        width = "350px",
        animate = animateOptions(
          enter = animations$fading_entrances$fadeInLeftBig,
          exit = animations$fading_exits$fadeOutRightBig
        ),
        
        tooltip = tooltipOptions(title = "Click to see all parameters !")
      )
      
      
    ),
    
    fluidRow(
      column(
        7,
        
        div(
          style = "position:relative",
          shinycssloaders::withSpinner(
            plotOutput(
              "AnalyisPlotSamplesSelected",
              width = "100%",
              height = "480px",
              click = "plotAnalysisNewSample_click",
              dblclick = "plotAnalysisNewSample_dblclick",
              brush = brushOpts(id = "plotAnalysisNewSample_brush",
                                resetOnNew = TRUE),
              hover = hoverOpts(
                "plotAnalysisNewSamplet_hover",
                delay = 100,
                delayType = "debounce"
              )
              
            ),
            type = 1,
            size = 0.8
          ),
          uiOutput("plotAnalysisNewSamplet_hover_info"),
          hidden(
            div(
              id = "PeaksMonoIsoPlotAnalysisNewSample_id",
              class = "pull-right",
              style = "display:inline-block;font-weight:bold;color: #f7f0f0;",
              #disabled(
              verbatimTextOutput("PeaksMonoIsoPlotAnalysisNewSample_info")
              
              #)
            )
            
          )
          
        ),
        fluidRow(br()),
        
        fluidRow(column(
          12,
          align = "left",
          column(
            2,
            actionButton(
              inputId = "returnAnalysis",
              label = "Return",
              class = "btn-primary",
              icon = icon("arrow-left")
            )
          ),
          column(
            6,
            pickerInput(
              inputId = "IncludeSample",
              label = NULL,
              #label =NULL,
              choices = NULL,
              options = pickerOptions(
                actionsBox = TRUE,
                size = 10,
                selectedTextFormat = "count",
                #showTick = TRUE,
                style = "btn-primary"
              ),
              multiple = TRUE
            ),
            h5("Select/deselect sample(s) (to save)")
          ),
          column(
            2,
            
            shinySaveButton(
              id =  "SaveAnalysis",
              label = "Save to",
              title = "Save file as...",
              filename = "Features-list-",
              filetype = list(text = "csv"),
              viewtype = "icon",
              icon = icon("save", lib = "glyphicon"),
              class =
                "btn-primary"
            ),
            
          ),
          column(
            2,
            actionButton(
              inputId = "GoMatch",
              label = "Go to match",
              class = "btn-primary",
              icon = icon("arrow-right")
            )
          )
        )),
        
        
        
      ),
      
      column(
        5,
        shinycssloaders::withSpinner(
          plotOutput("NumberOfFeatures",
                     width = "100%",
                     height = "250px"),
          type = 1,
          size = 0.8
        ),
        
        
        h5("Samples name:",
           style = "margin-top:2rem"),
        verbatimTextOutput("sampleOutput")
      )
    ),
    
  ))
}
