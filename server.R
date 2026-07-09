library(jsonlite)

server <- function(input, output, session) {
  
  #Fermer les sessions R créées par Shiny à la sortie
  
  # onStop(function() {
  
  #   cat("Fermeture de l'application Shiny - arrêt des processus R...\n")
  
  #   system("taskkill /F /IM Rscript.exe /T", intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
  
  # })
  
  
  
  
  
  # future, promises, parallel) créent des processus Rscript.exe ou Rterm.exe
  
  #qui ne se ferment pas automatiquement.
  
  # onStop(function() {
  
  #   parallel::stopCluster(parallel::getDefaultCluster())
  
  #   system("taskkill /F /IM Rscript.exe /T", intern = FALSE)
  
  # })
  
  
  
  
  
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
  
  
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  #~~~~~~~~~~~~~~~~~~~ GLOBAL CACHE SYSTEM INITIALIZATION ~~~~~~~~~~~~~~~~~~~~~#
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  
  # source("server/cache.server/cacheManagement.server.R")
  
  # 
  
  # Load Global Cache Controller (New Reference Map)
  
  source("lib/cache/GlobalCacheController.lib.R", local = FALSE)

  # Load ANS Cache Controller
  source("lib/cache/AnalysisNewSamplesCacheController.lib.R", local = FALSE)

  # Reactive value to store the cache controller
  
  globalCacheController <- reactiveVal(NULL)
  
  
  
  # Reactive value to track cache initialization state
  
  cacheState <- reactiveValues(
    
    initialized = FALSE,
    
    project_name = NULL,
    
    can_resume = FALSE,
    
    recovery_pending = FALSE,
    
    auto_save_enabled = FALSE
    
  )
  
  
  
  # Reactive value to store the ANS cache controller
  
  globalCacheControllerANS <- reactiveVal(NULL)
  
  # Reactive value to track ANS cache initialization state
  
  cacheStateANS <- reactiveValues(
    
    initialized = FALSE,
    
    project_name = NULL,
    
    can_resume = FALSE,
    
    recovery_pending = FALSE
    
  )
  
  ## Increase timeouts for long-running operations (Kernel Density with gc())
  
  ## Disable session timeout (allow infinite processing time)
  
  options(shiny.usecairo = FALSE)  # Disable Cairo for better performance
  
  
  
  ## Allow session reconnection if disconnected during long operations
  
  #session$allowReconnect(TRUE)
  
  # 
  
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  
  
  # Load necessaries packages
  
  initPackages(session = session)
  
  
  
  
  
  # Initialize all the reactive variables used for new reference map...
  
  source("server/newReferenceMap.server/reactiveVarsNewRefMap.R")
  
  allReactiveVarsNewRefMap <- initReactiveVarsNewRefMap()
  
  
  
  # Load Cache Management server logic (requires: globalCacheController, cacheState,
  
  # and allReactiveVarsNewRefMap to be defined)
  
  source("server/cache.server/cacheManagement.server.R", local = TRUE)
  
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
  
  # Load ANS Cache Management server logic (requires: globalCacheControllerANS, cacheStateANS,
  
  # RvarsPeakDetectionNewSample, RvarsMatchNewsample, RvarsNormalizeNewsample, directoryInput)
  
  source("server/cache.server/cacheManagementAnalysisNewSamples.server.R", local = TRUE)
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  
  
  
  ###~~~~~~~~~~~~~~~~Database reference map manager ~~~~~~~~~~~~~~~####
  
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  source("server/database.server/database.server.R", local = TRUE)
  
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
  
  
  
  
  
}

