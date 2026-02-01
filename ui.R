#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


## include files


#new reference map
source("ui/newReferenceMap.ui/peakDetection.Ui_NewRefMap.R")
source("ui/newReferenceMap.ui/CorrectionTime.Ui_NewRefMap.R")
source("ui/newReferenceMap.ui/GenerateMapRef.Ui_NewRefMap.R")
source("ui/newReferenceMap.ui/InternalStandard.Ui_NewRefMap.R")


## New sample analysis
source("ui/analysisNewSamples.ui/analysisItemNewSamples.ui.R")
source("ui/analysisNewSamples.ui/normalizationItemNewSamples.ui.R")

## Manage database references map
source("ui/database.ui/database.ui.R")

## About MSPANDA
source("ui/About.ui/about.ui.R")

## Cache Management UI
source("ui/cache.ui/cacheManagement.ui.R")


# Extract alll them for shiny
allThemes <- function() {
  themes <- dir(system.file("shinythemes/css", package = "shinythemes"),
                "*.min.css")
  sub(".min.css", "", themes)
}


# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel(title = NULL,
             windowTitle = "MS-PANDA-1.0.0"),
  
  
  ## Theme for shiny
  theme = shinytheme("lumen"),
  ## default them simplex spacelab
  #theme=shinytheme("spacelab"), ## default them simplex spacelab
 #shinythemes::themeSelector(),
 
  tags$script(
    "$('#shinytheme-selector')
  .on('change', function(el) {
    var allThemes = $(this).find('option').map(function() {
      if ($(this).val() === 'default')
        return 'bootstrap';
      else
        return $(this).val();
    });

    // Find the current theme
    var curTheme = el.target.value;
    if (curTheme === 'default') {
      curTheme = 'bootstrap';
      curThemePath = 'shared/bootstrap/css/bootstrap.min.css';
    } else {
      curThemePath = 'shinythemes/css/' + curTheme + '.min.css';
    }

    // Find the <link> element with that has the bootstrap.css
    var $link = $('link').filter(function() {
      var theme = $(this).attr('href');
      theme = theme.replace(/^.*\\//, '').replace(/(\\.min)?\\.css$/, '');
      return $.inArray(theme, allThemes) !== -1;
    });

    // Set it to the correct path
    $link.attr('href', curThemePath);
  });"
  ),
  
  
  
  ## including files in www for theme and proporties css
  shinyjs::useShinyjs(),
  useSweetAlert(),
  
  
  tags$head(
    tags$script(
      'Shiny.addCustomMessageHandler("changeProgressHeader",',
      'function(msg) {',
      '    $("#progressBarHeader_" + msg.tid).html(msg.value);',
      '});',
      'Shiny.addCustomMessageHandler("changeProgressFooter",',
      'function(msg) {',
      '    $("#progressBarFooter_" + msg.tid).html(msg.value);',
      '});',
      'Shiny.addCustomMessageHandler("emptyNode",',
      'function(msg) {',
      '    $("#" + msg.id).empty();',
      '});'
    )
  ),
  
  includeCSS("www/style.css"),

  ## Cache Management Styles
  cache_ui_styles(),

  #### Suppression the warning an error message in console shiny
  tags$style(
    type = "text/css",
    ".shiny-output-error { visibility: hidden; }",
    ".shiny-output-error:before { visibility: hidden; }"
  ),
  
  
  
  
  
  fluidRow(column(
    7,
    div(style = "padding:0px; border-width:0px;",
        tags$img(src = "logo_I2MC_RFlab.PNG", width = "45%"))
    
  ),
  column(
    5,
    div(
      class = "page-title",
      div(style = "font-size:1.3em; font-weight:bold;color: #760001;",
          "MS-PANDA"),
      
      "MS Processing And Normalization DAta"
    )
  )),
  
  #navbarPage
  navbarPage(
    id = "analysisNavbar",
    title = "MS-PANDA",
    inverse = TRUE,
    collapsible = TRUE,
    
    
    
    
    navbarMenu(
      "Analysis new samples",
      icon = icon("flask"),
      
      
      
      tabPanel("Peak detection and grouping",
               analysisTabPanelNewSamples()),
      
      tabPanel("Match reference map",
               matchTabPanel()),
      tabPanel("Samples normalization",
               normalizationTabPanel())
      
      
    ),
    
    navbarMenu(
      "New reference map",
      icon = icon("wrench"),
      
      tabPanel("Peak detection",
               tabPanelNewReferenceMap()),
      
      tabPanel(
        "CE-time correction",
        CorrectionTimeTabPanelNewRefrenceMap(),
        
      ),
      tabPanel(
        "Generate the reference map",
        GenerateRefMapTabPanelNewRefrenceMap(),
        
      ),
      
      tabPanel(
        "Identification internal standards",
        InternalStandardsTabPanelNewRefrenceMap(),
      )
      
      
    ),
    
    tabPanel("Database",
             icon = icon("database"),
             databaseTabPanel()
             ),

    
    tabPanel("About",
             icon = icon("info-circle"),
             aboutTabPanel())
    
  ),

  ## Cache Floating Controls Button
  cache_floating_button_ui(),

  # Footer
  fluidRow(br()),
  fluidRow(br()),
  fluidRow(br()),
  absolutePanel(
    bottom = "0%",
    width = "80%",
    fixed = TRUE,
    style = "min-width:850px;",
    fluidRow(column(
      12,
      div(
        class = "footer",
        "Copyright ",
        HTML("&copy;"),
        "2023",
        a("RF Lab", href = "http://renalfibrosis.fr/", target =
            "_blank"),
        "/",
        a("Inserm", href = "https://www.inserm.fr/", target =
            "_blank"),
        ", ",
        "Designed and maintened by ",
        a("Mouhamed SEYE", href = "https://www.linkedin.com/in/mouhamed-seye-59885b1b7", target =
            "_blank")
      )
    ))
  )
)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~ For shinymanager (secure shiny app) ~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# secure_app(ui,
#            enable_admin = TRUE,
#            theme = shinytheme("simplex"),
#            # ajout d'une image en haut ?
#            tags_top =
#              tags$div(
#                div(
#                  class="page-title",
#                  div(
#                    style="font-size:1.3em; font-weight:bold;color: #760001;",
#                    "MS-PANDA"
#                  ),
#
#                  "MS Processing And Normalization DAta"
#                ),
#                hr(),
#                tags$img(
#                  src = "logo_I2MC_RFlab.PNG", width="100%"
#                  # le chemin pourrait être local (www/img/image.jpg -> "img/image.jpg")
#                ),
#                tags$hr(),
#                br(),
#              ),
#
#            # information en bas ?
#            tags_bottom = tags$div(
#              tags$p(
#                "For any question, please  contact the developper",
#                tags$a(
#                  href = "mailto:mouhamedseye3694@gmail.com",
#                  target="_top", "Mouhamed SEYE"
#                )
#              )
#            ),
#
#            background  = "linear-gradient(rgba(0, 0, 255, 0.5),
#            rgba(255, 255, 0, 0.5))"
#            )
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#