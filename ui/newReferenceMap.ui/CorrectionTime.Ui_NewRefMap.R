CorrectionTimeTabPanelNewRefrenceMap <- function() {
  fluidRow(
    #### Analysis step
    hidden(div(
      radioButtons(
        inputId = "CorrectionTimeStep",
        label = "",
        inline = TRUE,
        choices = c("1", "2", "3", "4", "5", "6", "7"),
        selected = "1"
      )
    )),
    
    conditionalPanel(condition = "input.CorrectionTimeStep=='1'",
                     SampleCutting_NewRefMap_Ui()),
    
    conditionalPanel(condition = "input.CorrectionTimeStep=='2'",
                     ReferenceSample_Ui()),
    
    conditionalPanel(condition = "input.CorrectionTimeStep=='3'",
                     CorrectionTime_XCMS_Viwer_Ui()),
    
    conditionalPanel(condition = "input.CorrectionTimeStep=='4'",
                     CorrectionTime_KernelDensity_Ui()),
    
    
  )
  
  
}




##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ functions ~~~~~~~~~~~~~~~~~~~~~####
###~~~~~~~~~~~~~~~~~~~~~~~~ Cut samples Ui ~~~~~~~~~~~~~~~~~~~~~~~~~~~###

SampleCutting_NewRefMap_Ui <- function() {
  fluidRow(column(
    12,
    
    HTML('<h4>Step 2 : Samples filter </h4>'),
    hr(),
    fluidRow(
      column(
        5,
        
        ### Import saved files
        div(
          class = "well well-sm",
          div(class = "info",
              h4(
                "Import saved files",
                icon("question-circle",
                     class = "myIcoInfo",
                       #title = "Please put all files to be scanned in a working directory.
                       # A maximum of 8 files is supported.
                       # The accepted formats are: d, CDF, mzML, mzXML, raw.
                       # Load the directory containing the files to be analyzed."
                     )
                )),
              fileInput(
                inputId = "massif_list_NewRefMap",
                label = "Upload peptide-list files (accept .csv)",
                accept = c(".csv"),
                multiple = TRUE,
                width = "100%"
              )
          ),
          hr(),
          div(
            class = "well well-sm",
            div(
              id = "RetentionTimeFiltering_id",
              h4("CE-time filtering"),
              hr(),
              fluidRow(column(
                10,
                pickerInput(
                  inputId = "sample_selectedCutting",
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
                
                
              )),
              
              uiOutput("titleTimefilter"),
              fluidRow(
                column(
                  4,
                  align = "center",
                  numericInput(
                    inputId = "rt_min_cut",
                    label = "Min",
                    value = NULL,
                    min = 0
                  )
                ),
                column(
                  4,
                  align = "center",
                  numericInput(
                    inputId = "rt_max_cut",
                    label = "Max",
                    value = NULL,
                    min = 0
                  )
                ),
                column(4, div(
                  style = "position:relative;top:20px",
                  actionButton(
                    inputId = "cutOff",
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
              div(id = "id_validCuttingRun",
                  column(
                    6,
                    div(
                      class = "pull-left",
                      style = "display:inline-block",
                      actionButton(
                        inputId = "validCuttingRun",
                        label =
                          "Finsh",
                        class =
                          "btn-primary",
                        icon = icon("check-circle")
                      )
                    )
                  )),
              
              hidden(div(id = "id_ResetCuttingRun",
                         column(
                           6,
                           div(
                             class = "pull-left",
                             style = "display:inline-block",
                             actionButton(
                               inputId = "ResetCuttingRun",
                               label = "Reset",
                               icon = icon("undo"),
                               class = "btn btn-danger"
                             )
                           )
                         ))),
              
              column(
                6,
                
                div(
                  class = "pull-right",
                  style = "display:inline-block",
                  disabled(
                    shinySaveButton(
                      id =  "SaveCuttingSample",
                      label = "Save to",
                      title = "Save file as...",
                      filename = "Massif-list-Cutted-sample",
                      filetype = list(text = "csv"),
                      viewtype = "icon",
                      icon = icon("save", lib = "glyphicon"),
                      class = "btn-primary"
                    )
                  )
                )
                
              )
            )
          ),
          
          fluidRow(column(
            6,
            div(
              class = "pull-left",
              style = "display:inline-block",
              actionButton(
                inputId = "ReturnToPeakViewer",
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
                  inputId = "GoToSelectRefranceSample",
                  label = "Next",
                  class = "btn-primary",
                  icon = icon("arrow-right")
                )
              )
              
              
            )
          ))
          
        ),
        column(7,
               fluidRow(column(
                 12,
                 div(
                   style = "position:relative",
                   shinycssloaders::withSpinner(
                     plotOutput(
                       "sample_selectedCutting_Plot",
                       width = "100%",
                       height = "400px",
                       dblclick = "sample_selectedCutting_dblclick",
                       click = "sample_selectedCutting_click",
                       brush = brushOpts(id = "sample_selectedCutting_brush",
                                         resetOnNew = TRUE),
                       hover = hoverOpts(
                         "sample_selectedCutting_hover",
                         delay = 100,
                         delayType = "debounce"
                       )
                       
                     ),
                     type = 1,
                     size = 0.8
                   ),
                   uiOutput("sample_selectedCutting_hover_info"),
                   
                   hidden(
                     div(
                       id = "UnitTime_sampleCutting_id",
                       class = "pull-left",
                       style = "display:inline-block;",
                       awesomeRadio(
                         inputId = "UnitTime_sampleCutting",
                         label = "Unit of CE-time",
                         choices = c("Second" = "Second",
                                     "Minute" = "Minute"),
                         inline = TRUE,
                         checkbox = TRUE
                       )
                     )
                   )
                 )
               )),
               fluidRow(column(12,
                               hidden(
                                 div(
                                   id = "mousepositionSampleCutting",
                                   #class="pull-right",
                                   style = "font-weight:bold;width: 100%; color: #000;",
                                   verbatimTextOutput("sample_selectedCutting_Plot_info")
                                   
                                   
                                 )
                               ))))
      )
    ))
}



ReferenceSample_Ui <- function() {
  fluidRow(column(
    12,
    HTML('<h4>Step 3 : CE-time correction with R package xcms </h4>'),
    hr(),
    fluidRow(
      column(
        5,
        
        disabled(
          div(
            class = "well well-sm",
            id = "id_SelectRefrenceSamplePanel",
            h4("Select the refrence sample"),
            
            awesomeRadio(
              inputId = "SelectRefrenceSample",
              label = "",
              choices = c(
                "Choose sample" = 1,
                "Median CE-time sample" = 2
              ),
              selected = 1,
              inline = TRUE,
              checkbox = TRUE,
              status = "success"
            ),
            
            conditionalPanel(condition = "input.SelectRefrenceSample==1",
                             # selectInput(inputId = "SelectRefrenceSample_option1",
                             #             label = "Select a sample:",
                             #             choices = NULL),
                             fluidRow(column(
                               10,
                               pickerInput(
                                 inputId = "SelectRefrenceSample_option1",
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
            
            fluidRow(column(
              6,
              conditionalPanel(
                condition = "input.SelectRefrenceSample==2",
                div(
                  class = "pull-left",
                  style = "display:inline-block",
                  actionButton(
                    inputId = "runSelectRefrenceSample",
                    label = "Engage!",
                    icon = icon("rocket"),
                    class = "btn-primary"
                  )
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
                    inputId = "ConfirmRefrenceSample",
                    label = "Confirm",
                    icon = icon("thumbs-up"),
                    class = "btn-primary"
                  )
                )
              ),
              
              div(class = "pull-right",
                  style = "display:inline-block",
                  hidden(
                    actionButton(
                      inputId = "resetRefrenceSample",
                      label = "Reset",
                      icon = icon("undo"),
                      class = "btn btn-danger"
                    )
                  ))
            ))
            
          )
        ),
        
        ###~~~~~~~~~~~~~~~~~~samples offset to the reference ~~~~~~~~~~~~~~"
        hr(),
        
        ##~~~~~~~~~~~~~~~~~~~~~~~~ Correction time with xcms package ~~~~~~~~~~~~~~~~#
        hidden(
          div(
            id = "id_Panel_runCorrectionTime",
            class = "well well-sm",
            h5(list(
              "Raw data for alignment",
              icon("question-circle",
                   class = "myIcoInfo")
            )),
            fileInput(
              inputId = "rawDataMZml",
              label = "Upload mzML files.",
              accept = c(".mzML"),
              multiple = TRUE,
              width = "100%"
            ),
            
            h5(list(
              "Sample(s) information",
              icon("question-circle",
                   class = "myIcoInfo")
            )),
            fileInput(
              inputId = "UploadSampleClass",
              label = "Upload sample-class relationship file.",
              accept = c(".csv"),
              multiple = FALSE,
              width = "100%"
            ),
            
            hr(),
            div(fluidRow(column(
              6,
              div(
                class = "pull-left",
                style = "display:inline-block",
                actionButton(
                  inputId = "ViewSampleInfo",
                  label = "Enter samples classes!",
                  icon = icon("pen"),
                  class = "btn-primary"
                )
              )
            )))
            
            
          )
          
          
        ),
        
        
        hr(),
        fluidRow(br()),
        fluidRow(column(
          6,
          div(
            class = "pull-left",
            style = "display:inline-block",
            actionButton(
              inputId = "ReturnToFilteringSample",
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
                inputId = "RefrenceSampleNextPage",
                label = "Next",
                class = "btn-primary",
                icon = icon("arrow-right")
              )
            )
          )
        ))
        
      ),
      
      column(7,
             fluidRow(column(
               12,
               div(
                 id = "id_plotRefrenceSample",
                 conditionalPanel(
                   condition = "input.SelectRefrenceSample==1",
                   div(
                     style = "position:relative",
                     shinycssloaders::withSpinner(
                       plotOutput(
                         "ReferenceSample_option1_Plot",
                         width = "100%",
                         height = "400px",
                         dblclick = "ReferenceSample_option1_Plot_dblclick",
                         click = "ReferenceSample_option1_Plot_click",
                         brush = brushOpts(id = "ReferenceSample_option1_Plot_brush",
                                           resetOnNew = TRUE),
                         hover = hoverOpts(
                           "ReferenceSample_option1_Plot_hover",
                           delay = 100,
                           delayType = "debounce"
                         )
                         
                       ),
                       type = 1,
                       size = 0.8
                     ),
                     
                     uiOutput("ReferenceSample_option1_Plot_hover_info"),
                   )
                 ),
                 
                 conditionalPanel(
                   condition = "input.SelectRefrenceSample==2",
                   div(
                     style = "position:relative",
                     shinycssloaders::withSpinner(
                       plotOutput(
                         "ReferenceSample_option2_Plot",
                         width = "100%",
                         height = "400px",
                         dblclick = "ReferenceSample_option2_Plot_dblclick",
                         click = "ReferenceSample_option2_Plot_click",
                         brush = brushOpts(id = "ReferenceSample_option2_Plot_brush",
                                           resetOnNew = TRUE),
                         hover = hoverOpts(
                           "ReferenceSample_option2_Plot_hover",
                           delay = 100,
                           delayType = "debounce"
                         )
                         
                       ),
                       type = 1,
                       size = 0.8
                     ),
                     
                     uiOutput("ReferenceSample_option2_Plot_hover_info"),
                     
                     
                   )
                 )
               ),
               
               ##~~~~~~~~~~~~~~~~~~~~~~~~ Correction time with xcms package ~~~~~~~~~~~~~~~~#
               hidden(
                 div(
                   id = "id_PanelParametersGenerateMap",
                   class = "well well-sm",
                   h4("Parameters obiwarp"),
                   fluidRow(column(
                     12,
                     
                     awesomeRadio(
                       inputId = "CorrectionTimeXCMS_NewRefMap",
                       label = '',
                       inline =
                         TRUE,
                       checkbox = TRUE,
                       choices =
                         list("Use defaults" = "defaults",
                              "Customize" =
                                "custom")
                     )
                   )),
                   hr(),
                   
                   conditionalPanel(condition =
                                      "input.CorrectionTimeXCMS_NewRefMap=='custom'",
                                    fluidRow(column(
                                      12,
                                      fluidRow(column(
                                        6,
                                        numericInput(
                                          inputId = "binSizeObiwrap",
                                          label =
                                            list("Bin size (Da):",
                                                 div(
                                                   class = "info",
                                                   icon(
                                                     "question-circle",
                                                     title = "Numeric, defining the bin size (in mz (or M+H) dimension) to be used for the profile matrix generation.
See step parameter in profile-matrix documentation for more details (xcms documentation)."
                                                   )
                                                 )),
                                          
                                          value =
                                            1,
                                          min = 0.01,
                                          step = 0.01
                                        )
                                      ),
                                      column(
                                        6,
                                        selectInput(
                                          inputId = "MSlevelObiwrap",
                                          label =
                                            list("MS level",
                                                 div(
                                                   class = "info",
                                                   icon("question-circle",
                                                        title = "Defining the MS level on which the retention time should be performed.")
                                                 )),
                                          
                                          choices = c("1" = 1,
                                                      "2" = 2)
                                        )
                                      )),
                                      fluidRow(column(
                                        6,
                                        
                                        pickerInput(
                                          inputId = "subsetObiwrap",
                                          label = list("Subset samples:",
                                                       div(
                                                         class = "info",
                                                         icon(
                                                           "question-circle",
                                                           title = "It is possible to exclude certain samples within an experiment from the estimation of the alignment models.
The parameter subset allows to define the samples within object that should be aligned.
Samples not part of this subset are left out in the estimation of the alignment models, but their retention times are subsequently adjusted based on the alignment results of the closest sample in subset (close in terms of position within the object).
Alignment could thus be performed on only real samples leaving out e.g. blanks, which are then in turn adjusted based on the closest real sample."
                                                         )
                                                       )),
                                          choices = NULL,
                                          selected = NULL,
                                          options = pickerOptions(
                                            actionsBox = TRUE,
                                            size = 10,
                                            selectedTextFormat = "count",
                                            #showTick = TRUE,
                                            #"max-options" = 6,
                                            style = "btn-primary"
                                          ),
                                          multiple = TRUE
                                        )
                                      ),
                                      column(
                                        6,
                                        selectInput(
                                          inputId = "subsetAdjustObiwrap",
                                          label =
                                            list("Subset adjust:",
                                                 div(
                                                   class = "info",
                                                   icon(
                                                     "question-circle",
                                                     title = "How the non-subset samples are adjusted bases also on the parameter subsetAdjust: with subsetAdjust = 'previous',
each non-subset sample is adjusted based on the closest previous subset sample which results in most cases with adjusted retention times of the non-subset sample being identical to the subset sample on which the adjustment bases.
The second, default, option is to use subsetAdjust = 'average' in which case each non subset sample is adjusted based on the average retention time adjustment from the previous and following subset sample.
For the average a weighted mean is used with weights being the inverse of the distance of the non-subset sample to the subset samples used for alignment."
                                                   )
                                                 )),
                                          choices = c("average" = "average",
                                                      "previous" = "previous")
                                        ),
                                      ))
                                      
                                      
                                    )))
                   
                 ),
                 div(id = "id_runProcess",
                     fluidRow(column(
                       6,
                       div(
                         class = "pull-left",
                         style =
                           "display:inline-block",
                         disabled(
                           actionButton(
                             inputId = "ButtonCorrectionXCMS",
                             label =
                               "Start!",
                             icon =
                               icon("rocket"),
                             class =
                               "btn-primary"
                           )
                         )
                         
                       )
                     )))
               )
             )))
    )
  ))
}




##~~~~~~~~~~~~~~~~~~~~~~~~ Correction time with xcms package ~~~~~~~~~~~~~~~~#
CorrectionTime_XCMS_Viwer_Ui <- function() {
  fluidRow(column(
    12,
    HTML('<h4>Step 4: Visualization (CE-time correction xcms) </h4>'),
    hr(),
    fluidRow(
      column(
        5,
        div(
          id = "IDPanelViewerCorrectimeXcms",
          class = "well well-sm",
          
          fluidRow(column(
            10,
            pickerInput(
              inputId = "SelectSample_ViewerCorrectimeXcms",
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
          )),
          
          hr(),
          
          fluidRow(column(
            6,
            div(class = "pull-left",
                style = "display:inline-block",)
          ),
          column(
            6,
            div(
              class = "pull-right",
              style = "display:inline-block",
              
              actionButton(
                inputId = "Add_to",
                label = "Add for realignment with kernel density",
                class = "btn-primary",
                icon = icon("plus")
              )
              
            )
          ))
          
        ),
        
        fluidRow(br()),
        fluidRow(br()),
        fluidRow(br()),
        fluidRow(br()),
        
        fluidRow(column(
          6,
          div(
            class = "pull-left",
            style = "display:inline-block",
            actionButton(
              inputId = "ReturToCorrectionXCMS",
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
                inputId = "CorrectionXCMSNexPage",
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
          id = "TabPanelCorrectionTimeXCMS_ID",
          tabPanel(
            fluidRow(br()),
            title = "Scatter plot (CE-time: ref vs sample)",
            
            # div(
            #   style = "position:relative",
            #   shinycssloaders::withSpinner(
            #
            #     plotOutput("CorrectimeXCMSViewer_1",
            #                width = "100%",
            #                height = "450px"
            #
            #     ), type = 1, size = 0.8),
            #
            # ),
            
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "CorrectimeXCMSViewer_Before",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "CorrectimeXCMSViewer_Before_hover",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput("CorrectimeXCMSViewer_Before_hover_info"),
              
            ),
            
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "CorrectimeXCMSViewer_After",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "CorrectimeXCMSViewer_After_hover",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput("CorrectimeXCMSViewer_After_hover_info"),
              
            )
            
            
            
          ),
          tabPanel(
            fluidRow(br()),
            title = "Distribution: M+H vs CE-Time",
            
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "CorrectimeXCMSViewer_2",
                  width = "100%",
                  height = "650px"
                ),
                type = 1,
                size = 0.8
              )
            )
          )
        ),
        
        
        
      )
    )
  ))
}





##~~~~~~~~~~~~~~~~~~~~~~~~ Correction time with Kernel density ~~~~~~~~~~~~~~~~#
CorrectionTime_KernelDensity_Ui <- function() {
  fluidRow(column(
    12,
    HTML('<h4>Step 5: CE-time correction with kernel density </h4>'),
    hr(),
    fluidRow(
      column(
        5,
        div(id = "IDPanelCorrectimeKernelDensity",
            class = "well well-sm",
            
            fluidRow(column(
              10,
              pickerInput(
                inputId = "SelectSample_KernelDensity",
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
            "bandwidth_Filter",
            "Bandwidth",
            min = 1,
            max = 500,
            value = 20
          ),
          fluidRow(
            hidden(column(
              6,
              numericInput(
                inputId = "gridSize",
                label = "Grid size (n)",
                value = 500
              )
              
              
            )),
            
            
            column(
              6,
              numericInput(
                inputId = "intensityFilter",
                label = "Intensity filter",
                min = 0,
                value = 0
              )
              
            ),
            column(
              6,
              numericInput(
                inputId = "minDensity",
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
            inputId = "KernelType",
            label = "Kernel type: ",
            choices = list(
              "Gaussian" = "gaussian",
              "Truncated gaussian" = "truncated gaussian",
              "Epanechnikov" = "epanechnikov",
              "Uniform" = "uniform"
            )
          ),
          
          sliderInput(
            "bandwidth_Model",
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
                inputId = "fitModel",
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
                inputId = "resetFitModel",
                label = "Reset",
                icon = icon("undo"),
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
                  inputId = "btn_view_rt_dist",
                  label = "View RT distribution",
                  icon = icon("eye"),
                  class = "btn-default"
                )
              )
            )
          )


        ),

        # Download button for corrected CE-time data
        fluidRow(column(12, br())),
        fluidRow(column(
          12,
          div(
            class = "well well-sm",
            style = "background-color: #e8f5e9;",
            h4("Export corrected data", style = "color: #2e7d32;"),
            p("Download the CE-time corrected peak list after validation.", style = "font-size: 13px;"),

            # Validation button - enabled when all samples are corrected
            div(
              class = "pull-left",
              style = "display:inline-block; margin-right: 15px;",
              disabled(
                actionButton(
                  inputId = "validateCETimeCorrection",
                  label = "All Adjustments Complete - Step 5 Done",
                  class = "btn-warning",
                  icon = icon("check-circle"),
                  style = "font-weight: bold;"
                )
              )
            ),

            # Excel export button
            div(
              class = "pull-left",
              style = "display:inline-block; margin-right: 10px;",
              shinySaveButton(
                id = "SaveCETimeCorrected",
                label = "Save as Excel",
                title = "Save CE-time corrected data as Excel...",
                filename = "CE_time_corrected_peaks",
                filetype = list(Excel = "xlsx"),
                viewtype = "icon",
                icon = icon("file-excel"),
                class = "btn-success"
              )
            ),

            # CSV export button
            div(
              class = "pull-left",
              style = "display:inline-block",
              shinySaveButton(
                id = "SaveCETimeCorrectedCSV",
                label = "Save as CSV",
                title = "Save CE-time corrected data as CSV...",
                filename = "CE_time_corrected_peaks",
                filetype = list(CSV = "csv"),
                viewtype = "icon",
                icon = icon("file-csv"),
                class = "btn-info"
              )
            )
          )
        )),

        fluidRow(column(
          6,
          div(
            class = "pull-left",
            style = "display:inline-block",
            actionButton(
              inputId = "ReturToViewCorrectionXCMS",
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

            actionButton(
              inputId = "CorrectionKernelDensityNexPage",
              label = "Next",
              class = "btn-primary",
              icon = icon("arrow-right")
            )


          )
        ))
        
      ),
      column(
        7,
        
        tabsetPanel(
          id = "TabPanelKernelDensityFilter_ID",
          
          tabPanel(
            fluidRow(br()),
            title = "CE-time Correction",
            
            
            ##~~~~~~~~~~~~~~~ Density filter ~~~~~~~~~~~~~###
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput("DensityFilterPlot",
                           width = "100%",
                           height = "450px"),
                type = 1,
                size = 0.8
              )
            ),
            
            ##~~~~~~~~~~~~~~~ Correction time ~~~~~~~~~~~~~###
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            ###~~~~~Before correction~~~~~~~~##
            fluidRow(br()),
            h4("Correction model :"),
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "PlotCorrectionKernelDensity_Before",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "PlotCorrectionKernelDensity_Before_hover",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput("PlotCorrectionKernelDensity_Before_hover_info"),
              
            ),
            
            ###~~~~~After correction~~~~~~~~##
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "PlotCorrectionKernelDensity_After",
                  width = "100%",
                  height = "225px",
                  hover = hoverOpts(
                    "PlotCorrectionKernelDensity_After_hover",
                    delay = 100,
                    delayType = "debounce"
                  )
                  
                ),
                type = 1,
                size = 0.8
              ),
              uiOutput("PlotCorrectionKernelDensity_After_hover_info"),
              
            )
          ),
          
          tabPanel(
            fluidRow(br()),
            title = "Distribution: M+H vs CE-Time",
            
            div(
              style = "position:relative",
              shinycssloaders::withSpinner(
                plotOutput(
                  "CorrectimeKernelDensityViewer_2",
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
