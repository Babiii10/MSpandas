InternalStandardsTabPanelNewRefrenceMap<-function(){
  
  fluidRow(
    
    #### Analysis step
    hidden(
      div(
        radioButtons(
          inputId="InternalStandardsStep",
          label="",
          inline=TRUE,
          choices=c("1","2"),
          selected = "1")
      )
    ),
    
    conditionalPanel(
      condition = "input.InternalStandardsStep=='1'",
      IndentificationInternalStandards()
    ),
    
    conditionalPanel(
      condition = "input.InternalStandardsStep=='2'",
      IndentificationInternalStandards_Plot()
    )
    
  )
  
}



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
IndentificationInternalStandards<-function(){
  
  fluidRow(column(12,
                  
                  HTML('<h4>Step 4 : Identification internal standards </h4>'),
                  hr(),
                  
                  fluidRow(
                    column(5,
                           
                           #hr(),
                           div(
                             id = "id_InternalStandardsParametersPanel",
                             class = "well well-sm",
                             h4("Data source selection"),

                             fluidRow(column(12,
                                             awesomeRadio(
                                               inputId="dataSourceChoice_IS",
                                               label = '',
                                               inline=TRUE,
                                               checkbox = TRUE,
                                               choices=list(
                                                 "Use generated matrix"="generated",
                                                 "Upload external matrix"="upload"
                                               ),
                                               selected = "generated"
                                             )
                             )),

                             conditionalPanel(
                               condition="input.dataSourceChoice_IS=='upload'",
                               fluidRow(column(12,

                                               div(
                                                 class = "well well-sm",
                                                 style = "background-color: #f0f8ff; border: 1px solid #4682b4;",

                                                 h5(icon("upload"), "Upload Matrix File", style = "color: #2c5282; font-weight: bold;"),

                                                 p(
                                                   style = "color: #2c5282; font-size: 12px;",
                                                   icon("info-circle"),
                                                   "Upload a CSV or Excel file containing your abundance matrix.",
                                                   br(),
                                                   strong("Format required:"),
                                                   "Rows = Features, Columns = Samples",
                                                   br(),
                                                   "First column should contain Feature IDs."
                                                 ),

                                                 fluidRow(column(12,
                                                                 fileInput(
                                                                   inputId = "uploadMatrix_IS",
                                                                   label = "Select matrix file (CSV/XLSX)",
                                                                   accept = c(".csv", ".xlsx", ".xls"),
                                                                   multiple = FALSE,
                                                                   buttonLabel = "Browse...",
                                                                   placeholder = "No file selected"
                                                                 )
                                                 )),

                                                 # Status indicator
                                                 uiOutput("uploadStatus_IS"),

                                                 # Preview button
                                                 conditionalPanel(
                                                   condition = "output.showMatrixPreview_IS",
                                                   fluidRow(column(12,
                                                                   actionButton(
                                                                     inputId = "previewMatrix_IS",
                                                                     label = "Preview Matrix",
                                                                     icon = icon("eye"),
                                                                     class = "btn-info btn-sm"
                                                                   )
                                                   ))
                                                 )
                                               )
                               ))
                             ),

                             hr(),
                             h4("Internal standards parameters"),
                             fluidRow(column(12,
                                             
                                             awesomeRadio(
                                               inputId="InternalStandardsParameters",
                                               label = '',
                                               inline=TRUE,
                                               checkbox = TRUE,
                                               choices=list(
                                                 "Use defaults"="defaults",
                                                 "Customize"="custom"
                                               )
                                             )
                             )),
                             
                             conditionalPanel(
                               condition="input.InternalStandardsParameters=='custom'",
                               fluidRow(column(12,
                                               fluidRow(column(6,
                                                               numericInput(
                                                                 inputId="pSample",
                                                                 label="Min sample (%)",
                                                                 value=50,
                                                                 min = 0,
                                                                 max = 100,
                                                                 step = 1
                                                               ),
                                                               
                                                               numericInput(
                                                                 inputId="minNormalizers",
                                                                 label="Min normalizers",
                                                                 value=100,
                                                                 min = 10,
                                                                 step = 1
                                                               )
                                                               
                                                               
                                                               
                                               ),
                                               column(6,
                                                      numericInput(
                                                        inputId="pFeatures",
                                                        label="Min features (%)",
                                                        value=10,
                                                        min = 0,
                                                        max = 100,
                                                        step = 1
                                                      )
                                                      
                                                      
                                               )
                                               )
                                               
                               ))
                               
                               
                             )
                           ),
                           hr(),
                           
                           fluidRow(
                             column(6,
                                    div(
                                      class="pull-left",
                                      style="display:inline-block",
                                      #disabled(
                                      actionButton(
                                        inputId="IdentifyNormalizers",
                                        label="Start!",
                                        icon=icon("rocket"),
                                        class="btn-primary"
                                      )
                                      #)
                                      
                                    )
                             )
                             
                           )
                           
                           
                           
                    ),
                    
                    column(7,
                           plotOutput("DistibutionVar",
                                      height = "550px")   
                    )),
                  
                  fluidRow(
                    column(5,
                           hr(),
                           div(
                             fluidRow(
                               column(6,
                                      div(
                                        class="pull-left",
                                        style="display:inline-block",
                                        #disabled(
                                        actionButton(
                                          inputId="PreviousPageGenerateRefMap",
                                          label="Return",
                                          icon=icon("arrow-left"),
                                          class="btn-primary"
                                        )
                                        #)
                                        
                                      )),
                               column(6,
                                      div(
                                        class="pull-right",
                                        style="display:inline-block",
                                        #disabled(
                                        actionButton(
                                          inputId="nextPageIS",
                                          label="Next",
                                          icon=icon("arrow-right"),
                                          class="btn-primary"
                                        )
                                        #)
                                        
                                      ))
                             )
                           )
                    )
                  )
  )
  
  
  )
  
  
}

### nomalization viewer
IndentificationInternalStandards_Plot<-function(){
  
  fluidRow(column(12,
                  
                  HTML('<h4>Step 4 : Identification internal standards </h4>'),
                  hr(),
                  
                  fluidRow(column(7,
                                  
                                  shinycssloaders::withSpinner(plotOutput("DistibutionNormalizers",
                                                                          height = "550px"), type = 1, size = 0.8),
                  ),
                  column(5,
                         
                         
                         shinycssloaders::withSpinner(plotOutput("DensityIntensity",
                                                                 height = "400px"), type = 1, size = 0.8)
                         
                  )),
                  
                  
                  
                  
                  fluidRow(
                    column(12,
                           hr(),
                           div(
                             fluidRow(
                               column(6,
                                      div(
                                        class="pull-left",
                                        style="display:inline-block",
                                        #disabled(
                                        actionButton(
                                          inputId="PreviousPage1",
                                          label="Return",
                                          icon=icon("arrow-left"),
                                          class="btn-primary"
                                        )
                                        #)
                                        
                                      )),
                               column(6,
                                      div(
                                        class="pull-right",
                                        style="display:inline-block",
                                        disabled(
                                          actionButton(
                                            inputId="ValidRefrenceMap",
                                            label="Validate the reference map",
                                            icon=icon("save", lib = "glyphicon"),
                                            class="btn-primary"
                                          )
                                        )
                                        
                                      )
                               )
                               
                             )
                           )
                    )
                  )
                  
                  
                  
  )
  
  
  )
  
  
}
