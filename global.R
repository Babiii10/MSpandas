

'%ni%' <- Negate('%in%')

get_r_version <- function() {
  paste(R.version$major, sep = ".", R.version$minor)
}

usePackage <- function(p)
{
  if (!is.element(p, installed.packages()[, 1]))
    install.packages(p,
                     dep = TRUE,
                     force = TRUE,
                     repos = "http://cran.us.r-project.org")
  require(p, character.only = TRUE)
}


## Verify R-version

if (!require("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
  if (get_r_version() > "4.1.3") {
    message(
      paste0(
        "R version ",
        get_r_version(),
        " is detected \n",
        "Installing package BiocManager..."
      )
    )
    BiocManager::install()
  } else if (get_r_version() == "4.1.3") {
    message(
      paste0(
        "R version ",
        get_r_version(),
        " is detected \n",
        "Installing package BiocManager 3.14..."
      )
    )
    BiocManager::install(version = "3.14", update = FALSE)
  } else {
    stop("Pleas Install R version >= 4.1.3")
  }
}


## Require package to start the app
usePackage("shiny")
usePackage("shinyjs")
usePackage("shinythemes")
usePackage("shinyWidgets")
usePackage("shinycssloaders")
usePackage("shinyalert")
usePackage("shinydashboard")
usePackage("shinyFiles")
usePackage("bslib")
usePackage("progressr")
usePackage("devtools")
usePackage("reticulate")
usePackage("Rcpp")
usePackage("DT")
usePackage("shinymanager")
usePackage("stringr")

## shinyDirectoryInput Package
if (!is.element("shinyDirectoryInput", installed.packages()[, 1])) {
  #devtools::install_github('wleepang/shiny-directory-input')
  devtools::install_local("lib/PackagesR/shiny-directory-input")
  library(shinyDirectoryInput)
} else {
  require(shinyDirectoryInput)
}

## Python exe
# Fix: Enhanced Python configuration for Windows 11 compatibility
# Set environment variable before loading reticulate to avoid Error 322
python_path <- normalizePath(file.path(getwd(), "lib", "Python", "python.exe"),
                             winslash = "/", mustWork = FALSE)

if (file.exists(python_path)) {
  # Fix: Set RETICULATE_PYTHON environment variable before use_python
  # This prevents reticulate from trying to run config.py with wrong encoding
  Sys.setenv(RETICULATE_PYTHON = python_path)

  # Suppress py_config warnings during initialization
  suppressWarnings({
    tryCatch({
      use_python(python_path, required = FALSE)
    }, error = function(e) {
      message("Python initialization warning (non-critical): ", e$message)
    })
  })
} else {
  warning("Python executable not found at: ", python_path)
  # Try fallback to relative path
  tryCatch({
    use_python('lib/Python/python.exe', required = FALSE)
  }, error = function(e) {
    warning("Python initialization failed: ", e$message)
  })
}

initPackages <- function(session) {
  #Bioconductor packages
  pkgsBiocManager <- c(
    "xcms",
    "RNetCDF",
    "CAMERA",
    "RCurl",
    "tools",
    "RSQLite",
    "colourpicker",
    "yaml",
    "utils",
    "BiocParallel"
  )
  
  #CRAN packages
  pkgsCRAN <- c(
    "bigstatsr",
    "bigreadr",
    "combinat",
    "cowplot",
    "doParallel",
    "dplyr",
    "foreach",
    "ggalt",
    "ggplot2",
    "parallel",
    "grid",
    "gridExtra",
    "hrbrthemes",
    "itertools",
    "MASS",
    "MsCoreUtils",
    "np",
    "plotly",
    "patchwork",
    "Rcpp",
    "readxl",
    "signal",
    "tidyr",
    "tidyverse",
    "viridis",
    "openxlsx",
    "DBI"
  )
  
  
  allPkgs <- c(pkgsBiocManager, pkgsCRAN)
  
  idxpkgsBiocManager_missing <-
    which(!is.element(pkgsBiocManager, installed.packages()[, 1]))
  idxpkgsCRAN_missing <-
    which(!is.element(pkgsCRAN, installed.packages()[, 1]))
  
  ## Install necessaries packages if not exit
  
  if (length(idxpkgsBiocManager_missing) >= 1) {
    message("Installing packages of Biconductor...\n")
    withProgress(message = 'Installing packages of Biconductor...', value = 0, {
      for (i in idxpkgsBiocManager_missing) {
        incProgress(
          1 / length(idxpkgsBiocManager_missing),
          detail = paste("Installing ", pkgsBiocManager[i], collapse = "")
        )
        BiocManager::install(pkgsBiocManager[i])
      }
    })
    
  }
  
  
  if (length(idxpkgsCRAN_missing) >= 1) {
    message("Installing packages of CRAN...\n")
    withProgress(message = 'Installing packages of Biconductor...', value = 0, {
      for (i in idxpkgsCRAN_missing) {
        incProgress(
          1 / length(idxpkgsCRAN_missing),
          detail = paste("Installing ", pkgsCRAN[i], collapse = "")
        )
        install.packages(pkgsCRAN[i],
                         dep = TRUE,
                         force = TRUE,
                         repos = "http://cran.us.r-project.org")
      }
    })
    
    message("Installing packages finished Ok!\n")
  }
  
  
  
  ## Loading necessaries packages
  withProgress(message = 'Loading packages...', value = 0, {
    for (i in 1:length(allPkgs)) {
      incProgress(1 / length(allPkgs),
                  detail = paste("Loading ", allPkgs[i], collapse = ""))
      require(allPkgs[i], character.only = TRUE)
    }
  })
}


#necessaries variables and functions

theme_ben <- function(base_size = 14) {
  theme_bw(base_size = base_size) %+replace%
    theme(
      # L'ensemble de la figure
      plot.title = element_text(
        size = rel(0.85),
        face = "bold",
        color = "blue",
        margin = margin(0, 0, 5, 0),
        hjust = 0.5
      ),
      # Zone où se situe le graphique
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      # Les axes
      axis.title = element_text(size = rel(0.85), face = "bold.italic"),
      axis.text = element_text(size = rel(0.70), face = "bold.italic"),
      #axis.text.y = element_text(margin = margin(r = 0.8 *(100/2) / 2), hjust = 1),
      axis.line = element_line(
        color = "black",
        arrow = arrow(length = unit(0.3, "lines"), type = "closed")
      ),
      # La légende
      legend.title = element_text(
        size = rel(0.85),
        face = "bold.italic",
        hjust = 0.5
      ),
      legend.text = element_text(size = rel(0.70), face = "bold.italic"),
      legend.key = element_rect(fill = "transparent", colour = NA),
      legend.key.size = unit(0.5, "cm"),
      legend.key.width = unit(0.5, "cm"),
      legend.background = element_rect(fill = "transparent", colour = NA),
      # Les étiquettes dans le cas d'un facetting
      strip.background = element_rect(fill = "#17252D", color = "#17252D"),
      strip.text = element_text(
        size = rel(1),
        face = "bold.italic",
        color = "white",
        margin = margin(5, 0, 5, 0)
      )
    )
}


theme_ben.1 <- function(base_size = 14) {
  theme_bw(base_size = base_size) %+replace%
    theme(
      # L'ensemble de la figure
      plot.title = element_text(
        size = rel(1),
        face = "bold",
        color = "blue",
        margin = margin(0, 0, 5, 0),
        hjust = 0.5
      ),
      # Zone où se situe le graphique
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      # Les axes
      axis.title = element_text(size = rel(1), face = "bold.italic"),
      axis.text = element_text(size = rel(1), face = "bold.italic"),
      axis.line = element_line(
        color = "black",
        arrow = arrow(length = unit(0.3, "lines"), type = "closed")
      ),
      # La légende
      legend.title = element_text(
        size = rel(0.85),
        face = "bold.italic",
        hjust = 0.5
      ),
      legend.text = element_text(size = rel(0.70), face = "bold.italic"),
      legend.key = element_rect(fill = "transparent", colour = NA),
      legend.key.size = unit(1.5, "cm"),
      legend.key.width = unit(0.5, "cm"),
      legend.background = element_rect(fill = "transparent", colour = NA),
      
      # Les étiquettes dans le cas d'un facetting
      #strip.background = element_rect(fill = "#17252D", color = "#17252D"),
      strip.text = element_text(
        size = rel(1),
        face = "bold",
        margin = margin(5, 0, 5, 0)
      )
    )
}

### Volume for shinyFiles
volumes <- c(Home = fs::path_home(), getVolumes()())

#volumes<- c(Home = fs::path_home(), "R Installation" = R.home(), getVolumes()())


xy_str <- function(e, x, y) {
  if (is.null(e))
    return("NULL\n")
  paste0(x, " = ", round(e$x, 0), ", ", y, " = ", round(e$y, 4), "\n")
}




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Copy files or folders ~~~~~~~~~~~~~~~~~~~~~~~#

copy_files <- function(from, to, recursive = FALSE) {
  #initialise progress bar
  if (length(from) == 1) {
    message("Copy ", length(from), " files\n")
    file.copy(from = from[1],
              to = to,
              recursive = recursive)
  } else{
    pb <- txtProgressBar(min = 1,
                         max = length(from),
                         style = 3)
    cat("Copy", length(from), "files\n")
    for (i in 1:length(from)) {
      setTxtProgressBar(pb, i)
      file.copy(from = from[i],
                to = to,
                recursive = recursive)
    }
    #close progress bar
    close(pb)
  }
  message("Copy finished")
}



######### Function to generate ID
createID <- function(ref, number) {
  ID <-
    ID <-
    sprintf(paste0(ref, "%0", ceiling(log10(number + 1L)), "d"), 1L:number)
  return(ID)
}



###### Function to order data frame by column
order.data.frame <-
  function(data,
           column,
           rename.index = FALSE,
           decreasing = FALSE) {
    data <- data[order(data[, column], decreasing = decreasing), ]
    if (rename.index == TRUE) {
      rownames(data) <- 1:nrow(data)
    }
    
    return(data)
  }

## sort data frame by column
order.data.frame.V2 <-
  function(data,
           column,
           rename.index = FALSE,
           decreasing = FALSE,
           ref = "ID") {
    data <- data[order(data[, column], decreasing = decreasing), ]
    if (rename.index == TRUE) {
      rownames(data) <- createID(ref = ref, number = nrow(data))
      
    }
    
    return(data)
  }





updateShinyProgressBar <-
  function(shinyProgressData,
           pbValue,
           headerMsg = "",
           footerMsg = "") {
    if (is.null(shinyProgressData))
      return()
    
    if (is.null(shinyProgressData$progressTotal))
      shinyProgressData$progressTotal <- 100
    
    updateProgressBar(
      session = shinyProgressData$session,
      id = shinyProgressData$progressId,
      value = pbValue,
      total = shinyProgressData$progressTotal
    )
    
    shinyProgressData$session$sendCustomMessage("changeProgressHeader",
                                                list(value = headerMsg,
                                                     tid = shinyProgressData$textId))
    shinyProgressData$session$sendCustomMessage("changeProgressFooter",
                                                list(value = footerMsg,
                                                     tid = shinyProgressData$textId))
  }


#~~~~~~~~~~~~~~~~~~~ Directory ~~~~~~~~~~~~~~~~~~~~~~~~~~#
ref_map_directory <- "data/References"
ref_map <- basename(dir(ref_map_directory))

ref_map_databases_directory<-"data/ReferencesDatabases"
ref_map_databases <- str_remove_all(basename(dir(ref_map_databases_directory)), pattern = ".sqlite") 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~ For shinymanager (secure shiny app) ~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
# # Dans le global.R :
# set_labels(
#   language = "en",
#   "Please authenticate" = "You have to login",
#   "Username:" = "Your username:",
#   "Password:" = "Enter your password:"
# )

# ## Create database
# credentials <- data.frame(
#   user = c("mouhamed.seye"),
#   password = c("1234!"),
#   # password will automatically be hashed

#   admin = c(TRUE), # utilisateurs avec droits d'admin ?
#   stringsAsFactors = FALSE
# )
#
# create_db(
#   credentials_data = credentials,
#   sqlite_path = "data/Secure/database.sqlite", # elle sera crée
#   passphrase = "passphrase_wihtout_keyring"
# )
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#