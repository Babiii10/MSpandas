#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  #~~~~~~~~~~~~~~~~~~~~~ For shinymanager (secure shiny app) ~~~~~~~~~~~~~~~~~~#
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  # # branchement à la base sqlite
  # res_auth <- secure_server(
  #   check_credentials = check_credentials(
  #     "data/Secure/database.sqlite",
  #     passphrase = "passphrase_wihtout_keyring"
  
  #   )
  # )
  #
  # # user info
  # output$auth_output <- renderPrint({
  #   reactiveValuesToList(res_auth)
  # })
  #
  # # shinymanager input
  # output$shinymanager_language <- renderPrint({
  #   input$shinymanager_language
  # })
  #
  # output$shinymanager_where <- renderPrint({
  #   input$shinymanager_where
  # })
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  

  ## Extend size for inputs files
  options(shiny.maxRequestSize = 60000 * 1024 ^ 2)

  ## Increase timeouts for long-running operations (Kernel Density with gc())
  ## Disable session timeout (allow infinite processing time)
  options(shiny.usecairo = FALSE)  # Disable Cairo for better performance

  ## Allow session reconnection if disconnected during long operations
  session$allowReconnect(TRUE)

  # Load necessaries packages
  initPackages(session = session)
  
  
  # Initialize all the reactive variables used for new reference map...
  source("server/newReferenceMap.server/reactiveVarsNewRefMap.R")
  allReactiveVarsNewRefMap <- initReactiveVarsNewRefMap()
  # Initialize all the reactive variables used for Analysis new sample...
  source("server/analysisNewSamples.server/reactiveVarsAnalysisNewSample.R")
  
  # Initialize all the reactive variables used for Database reference map...
  source("server/database.server/reactiveValuesDatabase.server.R")
  
  
  ###~~~~~~~~~~~~~~~~~~~~~New reference map~~~~~~~~~~~~~~~~~~~~~~~~~#######
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  source("lib/NewReferenceMap/R_files/utils.fonctions.R", local = TRUE)
  
  source("server/newReferenceMap.server/peakDetection.Server_NewRefMap.R",
         local = TRUE)
  source("server/newReferenceMap.server/CorrectionTime.Server_NewRefMap.R",
         local = TRUE)
  source("server/newReferenceMap.server/GenerateMapRef.Server_NewRefMap.R",
         local = TRUE)
  source("server/newReferenceMap.server/InternalStandard.server_NewRefMap.R",
         local = TRUE)
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  
  ###~~~~~~~~~~~~~~~~~~~~~Analysis new sample~~~~~~~~~~~~~~~~~~~~~~~~~#######
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  source("server/analysisNewSamples.server/analysisItemNewSamples.server.R",
         local = TRUE)
  source(
    "server/analysisNewSamples.server/normalzationItemNewSamples.server.R",
    local = TRUE
  )
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  ###~~~~~~~~~~~~~~~~Database reference map manager ~~~~~~~~~~~~~~~####
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  source("server/database.server/database.server.R", local = TRUE)
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
}
