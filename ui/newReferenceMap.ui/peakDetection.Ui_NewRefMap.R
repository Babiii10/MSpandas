tabPanelNewReferenceMap<-function(){
  
  fluidRow(
    #### New reference map steps
    hidden(
      div(
        radioButtons(
          inputId="NewRefrenceMapStep",
          label="",
          inline=TRUE,
          choices=c("1","2"),
          selected = "1")
      )
    ),
    
    conditionalPanel(
      condition = 'input.NewRefrenceMapStep=="1"',
      PeakDetectionPanel(),
    ),
    
    conditionalPanel(
      condition = 'input.NewRefrenceMapStep=="2"',
      PeakDetectionViewerPanel()
    )
    
    
    
    
  )
  
}






##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Peak detection Ui ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
PeakDetectionPanel<-function(){
  
  
  fluidRow(column(12,
                  
                  HTML('<h4>Step 1 : Peak detection </h4>'),
                  
                  hr(),
                  fluidRow(column(6,
                                  
                                  fluidRow(column(12,
                                                  
                                                  div(
                                                    id = "id_PanelImportRawData",
                                                    class = "well well-sm",
                                                    div(
                                                      class = "info",
                                                      h4("New data files", icon("question-circle",
                                                                                class = "ClassInfoBull",
                                                                                title = "Please put all files to be analyzed in a working directory.
For processing fast, put maximum 8 files.
The accepted formats are: major MS vendor formats including: d, mzML and raw.
Load the directory containing the files to be analyzed."))
                                                      
                                                    ),
                                                    
                                                    fluidRow(column(12,
                                                                    directoryInput(inputId = "directory_rawData_NewRefMap",
                                                                                   label = "Folder path (raw data)",
                                                                                   value = "Choose working directory")
                                                    )),
                                                    
                                                    textInput(
                                                      inputId="projectName_NewRefMap",
                                                      label="Project name (100 chars max)",
                                                      value="New project",
                                                      placeholder="Project name"
                                                    ),

                                                    awesomeRadio(
                                                      inputId  = "resumeMode_NewRefMap",
                                                      label    = NULL,
                                                      inline   = TRUE,
                                                      checkbox = TRUE,
                                                      choices  = list(
                                                        "New project"              = "new",
                                                        "Resume existing project"  = "resume"
                                                      ),
                                                      selected = "new"
                                                    ),

                                                    conditionalPanel(
                                                      condition = "input.resumeMode_NewRefMap == 'resume'",
                                                      uiOutput("ui_existingProjects_NewRefMap")
                                                    ),
                                                    
                                                    textInput(
                                                      inputId="Name_NewRefMap",
                                                      label="Reference map name (100 chars max)",
                                                      value="New reference map",
                                                      placeholder="Name"),
                                                  ),
                                                  
                                                  div(
                                                    id = "id_PanelDataCollection",
                                                    class = "well well-sm",
                                                    h4("Data collection"),
                                                    awesomeRadio(
                                                      inputId="IdDataType_NewRefMap",
                                                      label = NULL,
                                                      inline=TRUE,
                                                      checkbox = TRUE,
                                                      choices=list(
                                                        "Use defaults (CE-MS/Profile)"="defaults",
                                                        "Customize"="custom"
                                                      )),
                                                    
                                                    conditionalPanel(
                                                      condition = "input.IdDataType_NewRefMap == 'custom'",
                                                      radioButtons(
                                                        inputId="dataType_NewRefMap",
                                                        label="Data type",
                                                        inline=TRUE,
                                                        choices=list(
                                                          "CE-MS"="MS1",
                                                          "CE-MS/MS"="MS2"
                                                        )),
                                                      
                                                      
                                                      fluidRow(column(6,
                                                                      selectInput(
                                                                        inputId="MS1_type_NewRefMap",
                                                                        label="MS1 type",
                                                                        choices=list(
                                                                          "Profile"="Profile",
                                                                          "Centroid"="Centroid"
                                                                        ))
                                                      ),
                                                      column(6,
                                                             selectInput(
                                                               inputId="MS2_type_NewRefMap",
                                                               label="MS2 type",
                                                               choices=list(
                                                                 "Profile"="Profile",
                                                                 "Centroid"="Centroid"),
                                                               selected="Profile"
                                                             )
                                                      )
                                                      )
                                                    ),
                                                    hr(),
                                                    fluidRow(column(6,
                                                                    numericInput(
                                                                      inputId="rt_begin_NewRefMap",
                                                                      label="CE-time begin (min)",
                                                                      value=0,
                                                                      min=0
                                                                      #width = '80%'
                                                                    ),
                                                                    numericInput(
                                                                      inputId="mz_range_begin_NewRefMap",
                                                                      label="MS1 mass range begin (mz)",
                                                                      value=350,
                                                                      min=0
                                                                      #width = '80%'
                                                                    )
                                                                    
                                                    ),
                                                    column(6,
                                                           numericInput(
                                                             inputId="rt_end_NewRefMap",
                                                             label="CE-time end (min)",
                                                             value=100,
                                                             min=0
                                                             #width = '80%'
                                                           ),
                                                           numericInput(
                                                             inputId="mz_range_end_NewRefMap",
                                                             label="MS1 mass range end (mz)",
                                                             value=3000,
                                                             min=0
                                                             #width = '80%'
                                                           )
                                                    ))
                                                    
                                                    
                                                  )
                                                  
                                                  
                                  ))
                                  
                                  
                  ),
                  column(6,
                         
                         div(
                           id = "id_PanelParametersNewRefMap",
                           class = "well well-sm",
                           h4("Peak detection parameters"),
                           #hr(),
                           fluidRow(column(12,
                                           
                                           awesomeRadio(
                                             inputId="peakDetectionParameters_NewRefMap",
                                             label = '',
                                             inline=TRUE,
                                             checkbox = TRUE,
                                             choices=list(
                                               "Use defaults"="defaults",
                                               "Customize"="custom"
                                             )
                                           ),
                           )),
                           conditionalPanel(
                             condition="input.peakDetectionParameters_NewRefMap=='custom'",
                             fluidRow(column(12,
                                             h5("Mass accuracy(centroid parameter):"),
                                             fluidRow(column(6,
                                                             numericInput(
                                                               inputId="mz_tolerance_centroid_MS1_NewRefMap",
                                                               label="MS1 tolerance (Da)",
                                                               value=0.01,
                                                               min = 0.01,
                                                               max = 0.05,
                                                               step = 0.01
                                                             )
                                             ),
                                             column(6,
                                                    numericInput(
                                                      inputId="mz_tolerance_centroid_MS2_NewRefMap",
                                                      label="MS2 tolerance (Da)",
                                                      value=0.025,
                                                      min = 0.025,
                                                      max = 0.1,
                                                      step = 0.001
                                                    )
                                             )),
                                             
                                             h5("Peak detection:"),
                                             fluidRow(column(6,
                                                             numericInput(
                                                               inputId="mass_slice_width_NewRefMap",
                                                               label="Mass slice width (Da)",
                                                               value=0.05,
                                                               min = 0.05,
                                                               max = 0.1,
                                                               step = 0.01
                                                             ),
                                                             numericInput(
                                                               inputId="maxCharge_NewRefMap",
                                                               label="Maximum charged number",
                                                               value=8,
                                                               min = 2,
                                                               max = 12,
                                                               step = 1
                                                             ),
                                                             selectInput(
                                                               inputId="Adduct_list_NewRefMap",
                                                               label="Adduct list",
                                                               choices=list(
                                                                 "[M+H]+"="[M+H]+",
                                                                 "[M+Na]+"="[M+Na]+",
                                                                 "[M+K]+" = "[M+K]+"
                                                               ),
                                                               multiple = TRUE,
                                                               selected=list("[M+H]+",
                                                                             "[M+Na]+",
                                                                             "[M+K]+")
                                                             )
                                             ),
                                             column(6,
                                                    numericInput(
                                                      inputId="min_Peakwidth_NewRefMap",
                                                      label="Minimum peak width (scan)",
                                                      value=4,
                                                      min = 4,
                                                      max = 10,
                                                      step = 1
                                                    ),
                                                    numericInput(
                                                      inputId="min_PeakHeight_NewRefMap",
                                                      label="Minimum peak height",
                                                      value=1000,
                                                      min = 1000,
                                                      max = 500000,
                                                      step = 1000
                                                    ),
                                                    numericInput(
                                                      inputId="minPeaksMassif_NewRefMap",
                                                      label="Minimum peaks per massif",
                                                      value=2,
                                                      min = 2,
                                                      step = 1
                                                    ),
                                                    
                                             ))
                             )),
                           )
                         ),
                         
                         div(
                           class="pull-left",
                           style="display:inline-block; margin-right:2rem;",
                           actionButton(inputId="runPeakPicking_NewRefMap",
                                        label="Run peak detction",
                                        class="btn-primary",
                                        icon=icon("rocket"))),
                         hidden(
                           div(
                             id= "Id_resetAll_NewRefMap_PeakDetectionView",
                             
                             div(
                                 class="pull-center",
                                 style="display:inline-block",
                                 actionButton(inputId="resetAll_NewRefMap",
                                              label="Reset all",
                                              class="btn btn-danger",
                                              icon=icon("undo"))),
                             
                             div(
                               class="pull-right",
                               style="display:inline-block",
                               actionButton(inputId="PeakDetectionView",
                                            label="View results",
                                            class="btn-primary",
                                            icon=icon("eye"))
                             )
                           )
                         )
                         
                                  
                                  
                                  
                                  
                         )
                         
                  ))
                  
  )
  
  
  
}


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Peak detection Viwer Ui ~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

PeakDetectionViewerPanel<-function(){
  fluidRow(column(12,
                  
                  HTML('<h4>Visualization of peak detection </h4>'),
                  hr(),
                  div(
                    id = "IDVisParameters",
                    div(class = "selectSampleViewer",
                         pickerInput(
                           inputId = "levelSample_NewRefMap",
                           label = "Select/deselect sample(s) (to viewer):",
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
                         )),
                    
                    dropdownButton(
                      
                      tags$h4("Visual parameters"),
                      
                      fluidRow(column(12,
                                      wellPanel(
                                        radioGroupButtons(
                                          inputId = "UnitTime_NewRefMap",
                                          label = "Unit of CE-time.",
                                          choices = c("Second",
                                                      "Minute"),
                                          checkIcon = list(
                                            yes = tags$i(class = "fa fa-check-square",
                                                         style = "color: steelblue"),
                                            no = tags$i(class = "fa fa-square-o",
                                                        style = "color: steelblue"))
                                        ),
                                        
                                        radioButtons(
                                          inputId="ViewSizePoints_NewRefMap",
                                          label="Size for points:",
                                          inline=TRUE,
                                          choices=list(
                                            "Use defaults"="defaults",
                                            "Change size"="custom"
                                          )
                                        ),
                                        conditionalPanel(
                                          condition = "input.ViewSizePoints_NewRefMap=='custom'",
                                          sliderInput(
                                            inputId = "sizePoints_NewRefMap",
                                            label = NULL,
                                            min = 0.5,
                                            max = 2,
                                            value = 0.5)
                                        ),
                                      ))
                               
                      ),
                      
                      
                      circle = TRUE, icon = icon("gear"),
                      status = "primary", width = "350px",
                      
                      tooltip = tooltipOptions(title = "Click to see all parameters !")
                    )
                  ),
                  
                  fluidRow(column(8,

                                  div(
                                    style = "position:relative",
                                    shinycssloaders::withSpinner(
                                      plotOutput("PeaksMonoIsoPlotSamplesSelected",
                                                 width = "100%",
                                                 height = "500px",
                                                 dblclick = "peakMonoIsoPlot_dblclick",
                                                 click = "peakMonoIsoPlot_click",
                                                 brush = brushOpts(
                                                   id = "peakMonoIsoPlot_brush",
                                                   resetOnNew = TRUE
                                                 ),
                                                 hover = hoverOpts("PeaksMonoIsoPlot_hover", delay = 100, delayType = "debounce")

                                      ), type = 1, size = 0.8),
                                    ## bule info
                                    uiOutput("PeaksMonoIsoPlot_hover_info"),
                                    hidden(
                                      div(
                                        id = "PeaksMonoIsoPlot_id",
                                        class="pull-right",
                                        style="display:inline-block;font-weight:bold;color: #760001;",
                                        #disabled(
                                        verbatimTextOutput("PeaksMonoIsoPlot_info")

                                        #)
                                      )

                                    )

                                  ),
                                  ## actionButton
                                  fluidRow(br()),
                                  fluidRow(
                                    column(12,
                                           align = "left",
                                           column(2,
                                                  actionButton(inputId="returnAnalysis_NewRefMap",
                                                               label="Return",
                                                               class="btn-primary",
                                                               icon = icon("arrow-left"))),
                                           column(6,
                                                  pickerInput(
                                                    inputId = "IncludeSample_NewRefMap",
                                                    #label = "Select/deselect sample(s) (to save):",
                                                    label =NULL,
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
                                           column(2,

                                                  shinySaveButton(id =  "SaveAnalysis_NewRefMap",
                                                                  label = "Save to",
                                                                  title = "Save file as...",
                                                                  filetype = list(text = "csv"),
                                                                  filename = "Massif-list",
                                                                  viewtype = "icon",
                                                                  icon = icon("save", lib = "glyphicon"),
                                                                  class="btn-primary")

                                           ),
                                           column(2,
                                                  actionButton(inputId="AlignementGrouping",
                                                               label="Next",
                                                               class="btn-primary",
                                                               icon = icon("arrow-right"))
                                           )
                                    )

                                  )
                  ),

                  column(4,
                         # shinycssloaders::withSpinner(plotOutput("MassifPlot_info",
                         #                                         width = "100%",
                         #                                         height = "300px"), type = 1, size = 0.8),
                         # fluidRow(br()),
                         shinycssloaders::withSpinner(plotOutput("NumberOfFeatures_NewRefMap",
                                                                 width = "100%",
                                                                 height = "300px"), type = 1, size = 0.8),

                         verbatimTextOutput("legend_samppleOutput_NewRefMap")


                  )
                  )
  ))
  
  
}

