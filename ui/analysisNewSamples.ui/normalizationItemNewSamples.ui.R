matchTabPanel<-function(){
  fluidRow(
    matchTabPanelInputOutput()
  )
}

normalizationTabPanel<-function(){
  fluidRow(
    normalizationTabPanelInputOutput()
  )
}




matchTabPanelInputOutput<-function(){
  
  
  fluidRow(
    column(5,
           HTML('<h4>Step 3 : Match to reference map </h4>'),
           hr(),
           
           fluidRow(column(12,
                           
                           ### Import saved files
                           div(
                             class = "well well-sm",
                             div(
                               class = "info",
                               h4("Import saved files", icon("question-circle",
                                                             class = "myIcoInfo",
                                                             title = "Here you can upload the files contain features detection list for 'Analysis new sample'.
The files must contain columns: 'M+H', 'CE-time', 'intensity', 'sample', 'iso.mass', 'iso.mass.link', 'mz_PeaksIsotopics_Group', 'rt_PeaksIsotopics_Group', 'Height_PeaksIsotopics_Group'."
                               ))),
                             fileInput(
                               inputId = "features_list",
                               label = "Upload feature list files (accept .csv)",
                               accept = c(".csv"),
                               multiple = TRUE,
                               width = "100%"
                             )
                           ),
                           
                           fluidRow(column(12,
                                           selectInput(
                                             inputId = "levelSampleMatch",
                                             label = "Select a sample",
                                             choices = NULL,
                                             width = "100%"),
                           )),
                           
                           hr(),
                           fluidRow(
                             column(4,
                                    div(
                                      class="pull-left",
                                      style="display:inline-block",
                                      actionButton(inputId="returnAnalysisViewer",
                                                   label="Return",
                                                   class="btn-primary",
                                                   icon = icon("arrow-left")))),
                             # conditionalPanel(
                             #   condition="input.matchParameters=='custom'",
                             column(4,
                                    div(
                                      class="pull-center",
                                      style="display:inline-block",
                                      actionButton(inputId="match",
                                                   label="Update",
                                                   class="btn-primary"))),
                             hidden(
                               div(
                                 id = "buttonNormIntensity",
                                 column(4,
                                        div(
                                          class="pull-right",
                                          style="display:inline-block",
                                          actionButton(inputId="normIntensity",
                                                       label="Next",
                                                       class="btn-primary",
                                                       icon = icon("arrow-right"))))
                               )
                             )
                             
                             
                           ),
                           
                           hr(),
                           fluidRow(br()),
                           hidden(
                             div(
                               id = "peakListToSave",
                               fluidRow(
                                 
                                 column(12,
                                        div(
                                          class="pull-left",
                                          style="display:inline-block",
                                          shinySaveButton(id = "PeakListNewSample",
                                                          label = "Save massif list no aligned",
                                                          title = "Save file as...",
                                                          filename = "Massif-list-no-aligned",
                                                          
                                                          
                                                          filetype = list(text = "csv"),
                                                          viewtype = "icon",
                                                          icon = icon("save", lib = "glyphicon"),
                                                          class="btn-primary"))
                                 )),
                               fluidRow(br()),
                               
                               fluidRow(
                                 
                                 column(12,
                                        
                                        div(
                                          class="pull-left",
                                          style="display:inline-block",
                                          
                                          shinySaveButton(id = "PeakListAlignedNewSample",
                                                          label = "Save massif list aligned",
                                                          title = "Save file as...",
                                                          filename = "Massif-list-aligned",
                                                          
                                                          
                                                          filetype = list(text = "csv"),
                                                          viewtype = "icon",
                                                          icon = icon("save", lib = "glyphicon"),
                                                          class="btn-primary")
                                        )),
                                 
                               )
                             )
                           ),
                           
                           
                           
                           fluidRow(br()),
                           
                           shinySaveButton(id = "MatchResult",
                                           label = "Save matrix abundance before normalization",
                                           title = "Save file as...",
                                           filename = "Matrix abundance before normalization",
                                           
                                           
                                           filetype = list(text = "csv"),
                                           viewtype = "icon",
                                           icon = icon("save", lib = "glyphicon"),
                                           class="btn-primary")
                           
                           
           )),
           
           
           hr(),
           fluidRow(column(12,
                           # conditionalPanel(
                           #   condition="input.matchParameters=='custom'",
                           hidden(
                             div(id = "idpanel_matchProgress",
                                 conditionalPanel(
                                   condition="input.match>=1",
                                   fluidRow(column(12,
                                                   div(
                                                     class = "well well-sm",
                                                     # h4("Analysis progress"),
                                                     # hr(),
                                                     div(
                                                       id="matchProgress",
                                                       style="font-size: 1.2em; margin-bottom: 5px;",
                                                       ""
                                                     ),
                                                     hidden(div(
                                                       id="matchProgressWrapper",
                                                       div(
                                                         class="progressbar-header",
                                                         id="progressBarHeader_match_pre",""
                                                       ),
                                                       
                                                       progressBar(
                                                         id="matchProgressBar",
                                                         value=1,
                                                         #total=14,
                                                         display_pct=TRUE,
                                                         status="primary",
                                                         striped=TRUE
                                                       ),
                                                       div(
                                                         class="progressbar-footer",
                                                         id="progressBarFooter_match_pre",""
                                                       )
                                                     )),
                                                     class="well-panel"
                                                   )))))))),
           
    ),
    
    column(7,
           
           hidden(
             div(id = "wellPanelMatchOutput",
                 fluidRow(column(12,
                                 # wellPanel(
                                 
                                 # h4("Matching results"),
                                 # hr(),
                                 #
                                 tabsetPanel(
                                   id="matchOutput",
                                   
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Match viewer",
                                     
                                     div(
                                       id = "detailPlot",
                                       
                                       div(
                                         actionButton(inputId="detail",
                                                      label="Detail",
                                                      class="btn-primary")
                                       ),
                                       
                                       dropdown(
                                         
                                         tags$h4("Visual parameters"),
                                         
                                         fluidRow(column(12,
                                                         conditionalPanel(
                                                           condition = "input.matchOutput=='Match viewer'",
                                                           wellPanel(
                                                             
                                                             radioGroupButtons(
                                                               inputId = "UnitTimeMatch",
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
                                                               inputId="ViewSizePointsMatch",
                                                               label="Size for points:",
                                                               inline=TRUE,
                                                               choices=list(
                                                                 "Use defaults"="defaults",
                                                                 "Change size"="custom"
                                                               )
                                                             ),
                                                             conditionalPanel(
                                                               condition = "input.ViewSizePointsMatch=='custom'",
                                                               sliderInput(
                                                                 inputId = "sizePointsMatch",
                                                                 label = NULL,
                                                                 min= 0.5,
                                                                 max = 2,
                                                                 value = 0.5)
                                                             )))
                                         )
                                         ),
                                         
                                         
                                         style = "unite", icon = icon("search-plus", class = "opt"),
                                         status = "primary", width = "350px",
                                         animate = animateOptions(
                                           enter = animations$fading_entrances$fadeInLeftBig,
                                           exit = animations$fading_exits$fadeOutRightBig
                                         ),
                                         
                                         tooltip = tooltipOptions(title = "Click to see parameters of the graph !")
                                       )
                                       
                                     ),
                                     
                                     
                                     
                                     #fluidRow(br()),
                                     div(
                                       style = "position:relative",
                                       shinycssloaders::withSpinner(plotOutput("features_matchViewer",
                                                                               width = "100%",
                                                                               height = "600px",
                                                                               dblclick = "matchViewerNewSample_dblclick",
                                                                               brush = brushOpts(
                                                                                 id = "matchViewerNewSample_brush",
                                                                                 resetOnNew = TRUE
                                                                               ),
                                                                               hover = hoverOpts("matchViewerNewSamplet_hover",
                                                                                                 delay = 100, delayType = "debounce")
                                       ),
                                       type = 1, size = 0.8,
                                       id = "Idfeatures_matchViewer"),
                                       uiOutput("matchViewerNewSamplet_hover_info")
                                     )
                                   ),
                                   
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Percentage match",
                                     
                                     shinycssloaders::withSpinner(DTOutput("percent_matchViewer"), type = 1, size = 0.8,
                                                                  id = "Idpercent_matchViewer")
                                     #DTOutput("percent_matchViewer")
                                   ),
                                   ### Matchedtable
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Matching table",
                                     
                                     shinycssloaders::withSpinner(DTOutput("matchedTableViewer"), type = 1, size = 0.8,
                                                                  id = "IdmatchedTableViewer")
                                     #DTOutput("percent_matchViewer")
                                   ),
                                   
                                   
                                 )))))
           
    )
  )
  
}

##################################################

normalizationTabPanelInputOutput<-function(){
  
  fluidRow(
    column(5,
           
           HTML('<h4>Step 4 : Samples normlization</h4>'),
           hr(),
           
           
           fluidRow(column(12,
                           div(
                             class = "well well-sm",
                             h4("Normalization parameters"),
                             hr(),
                             fluidRow(column(12,
                                             radioButtons(
                                               inputId="normalizingParameters",
                                               label=NULL,
                                               inline=TRUE,
                                               choices=list(
                                                 "Use defaults"="defaults",
                                                 "Customize"="custom"
                                               )
                                             ),
                                             
                                             conditionalPanel(
                                               condition="input.normalizingParameters=='custom'",
                                               fluidRow(
                                                 column(6,
                                                        numericInput(
                                                          inputId="min_iset",
                                                          label="Min normalizers",
                                                          value=10,
                                                          min=5,
                                                          step=1
                                                        )),
                                                 column(6,
                                                        numericInput(
                                                          inputId="cutrat",
                                                          label= list(div(class = "info", actionButton(inputId = "click_info_cutrat",
                                                                                                       #class = "btn-primary",
                                                                                                       style="padding: 0px 3px 0px 3px;
                                                                                                                        border: white;
                                                                                                                         margin: 0px;
                                                                                                                         color:lightcyan;",
                                                                                                       icon("question-circle",
                                                                                                            style="color:white",
                                                                                                            title = "Deviation of intensity between the normalizers in the new sample and the reference.
This parameter is used to manage the outlier normalizers, that is, the normalizers in the new sample that deviate too far from the reference normalizers."))),"Intensity deviation"),
                                                          value=1,
                                                          min=0,
                                                          step=0.1
                                                        )
                                                 ))
                                             )))),
                           
                           hr(),
                           fluidRow(
                             
                             column(6,
                                    div(
                                      class="pull-left",
                                      style="display:inline-block",
                                      actionButton(inputId="returnMatchRef",
                                                   label="Return",
                                                   class="btn-primary",
                                                   icon = icon("arrow-left")))),
                             # conditionalPanel(
                             #   condition="input.normalizingParameters=='custom'",
                             column(6,
                                    div(
                                      class="pull-right",
                                      style="display:inline-block",
                                      actionButton(inputId="runNormalizing",
                                                   label="Update",
                                                   class="btn-primary"))),
                             
                             
                           ),
                           hr(),
                           
                           fluidRow(br()),
                           
                           fluidRow(column(12,
                                           
                                           div(
                                             class="pull-left",
                                             style="display:inline-block",
                                             downloadButton(outputId="ExportParam",
                                                            label="Export the parameters",
                                                            class="btn-primary"),
                                           ))),
                           fluidRow(br()),
                           fluidRow(column(12,

                                           div(
                                             class="pull-left",
                                             style="display:inline-block",
                                             shinySaveButton(id =  "SaveAnalysisResults",
                                                             label = "Save matrix abundance normalized",
                                                             title = "Save file as...",
                                                             filename = "Matrix-abondance-normalized",


                                                             filetype = list(text = "csv"),
                                                             viewtype = "icon",
                                                             icon = icon("save", lib = "glyphicon"),
                                                             class="btn-primary")
                                           ))),
                           fluidRow(br()),
                           fluidRow(column(12,

                                           div(
                                             class="pull-left",
                                             style="display:inline-block",
                                             shinySaveButton(id =  "ExportRunSummary_newSample",
                                                             label = "Export bilan par run",
                                                             title = "Save file as...",
                                                             filename = "Bilan-par-run",
                                                             filetype = list(text = "csv"),
                                                             viewtype = "icon",
                                                             icon = icon("list-alt", lib = "glyphicon"),
                                                             class="btn-primary")
                                           ))),
                           fluidRow(br()),
                           fluidRow(column(12,



                                           div(
                                             class="pull-left",
                                             style="display:inline-block",
                                             actionButton(inputId="finishAnalyze",
                                                          label="Finish the analysis",
                                                          class="btn btn-danger")
                                           )
                                           
                                           
                           )),
                           
                           
                           
           )),
           hr(),
           fluidRow(column(12,
                           # conditionalPanel(
                           #   condition="input.normalizingParameters=='custom'",
                           hidden(
                             div(id = "idpanel_normIntensityProgress",
                                 conditionalPanel(
                                   condition="input.runNormalizing>=1",
                                   fluidRow(column(12,
                                                   div(
                                                     class = "well well-sm",
                                                     # h4("Analysis progress"),
                                                     # hr(),
                                                     div(
                                                       id="normIntensityProgress",
                                                       style="font-size: 1.2em; margin-bottom: 5px;",
                                                       ""
                                                     ),
                                                     hidden(div(
                                                       id="normIntensityProgressWrapper",
                                                       div(
                                                         class="progressbar-header",
                                                         id="progressBarHeader_normI_pre",""
                                                       ),
                                                       
                                                       progressBar(
                                                         id="normIntensityProgressBar",
                                                         value=1,
                                                         #total=14,
                                                         display_pct=TRUE,
                                                         status="primary",
                                                         striped=TRUE
                                                       ),
                                                       div(
                                                         class="progressbar-footer",
                                                         id="progressBarFooter_normI_pre",""
                                                       )
                                                     )),
                                                     class="well-panel"
                                                   )
                                   )))))
           )
           
           )
    ),
    column(7,
           
           hidden(
             div(id = "wellPanelNormIntensityOutput",
                 fluidRow(column(12,
                                 
                                 tabsetPanel(
                                   
                                   id="normalizeViewer",
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Boxplot-intensity",
                                     
                                     
                                     shinycssloaders::withSpinner(plotOutput("BoxplotNormalizing",
                                                                             width = "100%",
                                                                             height = "500px"), type = 1, size = 0.8,
                                                                  id = "IdBoxplotNormalizing"),
                                     
                                     hr(),
                                     
                                     fluidRow(column(12,
                                                     HTML(paste('
                                                            <table>
                                                            <thead>
                                                                 <tr>
                                                                     <th></th>
                                                                     <th>Before normalization</th>
                                                                     <th>After normalization</th>

                                                                 </tr>
                                                            </thead>

                                                            <tbody>
                                                                 <tr>
                                                                     <th>Variability</th>
                                                                     <td>',tags$b(textOutput("W_before_norm"),  style = "color: blue;"),'</td>
                                                                     <td>',tags$b(textOutput("W_norm"),  style = "color: blue;"),'</td>
                                                                 </tr>
                                                            </tbody>
                                                              </table>
                                                            ')),
                                                     
                                     )
                                     )),
                                   
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Internal standards",
                                     
                                     h5("Distribution log2 intensity", style = "text-align: center;"),
                                     shinycssloaders::withSpinner(plotOutput("NormalizresPlot",
                                                                             width = "100%"), type = 1, size = 0.8,
                                                                  id = "IdNormalizresPlot"),
                                     
                                     fluidRow(column(5,
                                                     div(
                                                       id = "LegendNorm",
                                                       plotOutput("LegendNormalizresPlot",
                                                                  height = "85px")
                                                     )),
                                              column(7,
                                                     div(
                                                       id="LegendSampleNam",
                                                       verbatimTextOutput("LegendNormalizresPlotSampleName")
                                                     ))
                                     )),
                                   tabPanel(
                                     fluidRow(br()),
                                     title="Distibution",
                                     
                                     h5("Distribution masse~ CE-time", style = "text-align: center;"),
                                     shinycssloaders::withSpinner(plotOutput("NormalizersDistribution",
                                                                             width = "100%"), type = 1, size = 0.8,
                                                                  id = "id_NormalizersDistribution"),
                                     
                                     fluidRow(column(5,
                                                     div(
                                                       id = "id_LegendNormDistribution",
                                                       plotOutput("LegendNormalizersDistribution",
                                                                  height = "85px"
                                                       )
                                                     )),
                                              column(7,
                                                     div(
                                                       id="id_LegendSampleNamDistribution",
                                                       verbatimTextOutput("LegendNormalizersDistributionSampleName")
                                                     )),
                                     ))
                                 )
                                 
                 ))
             ))
    )
  )
  
}


