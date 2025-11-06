## ============================================================================
## Additional Data Merge Library
## ============================================================================
## Functions for handling and merging additional uploaded data with
## existing peak detection data for grouping and reference map generation
## ============================================================================

#' Validate Additional Data Structure
#'
#' @param data Data frame to validate
#' @return List with 'valid' (logical) and 'message' (character)
validateAdditionalData <- function(data) {
  if (is.null(data) || !is.data.frame(data)) {
    return(list(valid = FALSE, message = "Data must be a data frame"))
  }

  if (nrow(data) == 0) {
    return(list(valid = FALSE, message = "Data frame is empty"))
  }

  # Required columns
  requiredCols <- c("M+H", "rt", "Area", "Height", "sample")
  missingCols <- requiredCols[!requiredCols %in% colnames(data)]

  if (length(missingCols) > 0) {
    return(list(
      valid = FALSE,
      message = paste("Missing required columns:", paste(missingCols, collapse = ", "))
    ))
  }

  # Check data types
  if (!is.numeric(data$`M+H`)) {
    return(list(valid = FALSE, message = "Column 'M+H' must be numeric"))
  }

  if (!is.numeric(data$rt)) {
    return(list(valid = FALSE, message = "Column 'rt' must be numeric"))
  }

  if (!is.numeric(data$Area)) {
    return(list(valid = FALSE, message = "Column 'Area' must be numeric"))
  }

  if (!is.numeric(data$Height)) {
    return(list(valid = FALSE, message = "Column 'Height' must be numeric"))
  }

  return(list(valid = TRUE, message = "Data validation successful"))
}


#' Standardize Additional Data Columns
#'
#' @param data Data frame to standardize
#' @return Standardized data frame with all required columns
standardizeAdditionalData <- function(data) {
  # Define all expected columns
  expectedCols <- c(
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

  # Fill missing columns with appropriate defaults
  for (col in expectedCols) {
    if (!(col %in% colnames(data))) {
      if (col %in% c("M+H.min", "M+H.max")) {
        # Use M+H value for min/max if not provided
        data[[col]] <- data[["M+H"]]
      } else if (col %in% c("rtmin", "rtmax")) {
        # Use rt value for min/max if not provided
        data[[col]] <- data[["rt"]]
      } else if (col == "SN") {
        # Default signal-to-noise ratio
        data[[col]] <- 100
      } else if (col %in% c("iso.mass", "iso.mass.link", "mz_PeaksIsotopics_Group",
                             "rt_PeaksIsotopics_Group", "Height_PeaksIsotopics_Group")) {
        # Empty string for isotopic pattern info
        data[[col]] <- ""
      } else if (col == "Adduct") {
        # Default adduct
        data[[col]] <- "M+H"
      }
    }
  }

  # Reorder columns to match expected order
  data <- data[, expectedCols]

  return(data)
}


#' Merge Additional Data with Existing Peak Data
#'
#' @param existingData Existing peak list data frame
#' @param additionalData Additional data frame(s) to merge
#' @return Combined data frame
mergeAdditionalData <- function(existingData, additionalData) {
  if (is.null(additionalData) || nrow(additionalData) == 0) {
    return(existingData)
  }

  # Validate additional data
  validation <- validateAdditionalData(additionalData)
  if (!validation$valid) {
    warning(validation$message)
    return(existingData)
  }

  # Standardize additional data
  standardizedData <- standardizeAdditionalData(additionalData)

  # Ensure both data frames have the same columns
  commonCols <- intersect(colnames(existingData), colnames(standardizedData))

  if (length(commonCols) == 0) {
    warning("No common columns between existing and additional data")
    return(existingData)
  }

  # Combine the datasets
  tryCatch({
    combined <- rbind(
      existingData[, commonCols],
      standardizedData[, commonCols]
    )

    # Add row names
    rownames(combined) <- 1:nrow(combined)

    message(paste("Successfully merged", nrow(standardizedData),
                  "additional peaks with", nrow(existingData), "existing peaks"))

    return(combined)
  }, error = function(e) {
    warning(paste("Error merging data:", e$message))
    return(existingData)
  })
}


#' Read Multiple Data Files and Combine
#'
#' @param filePaths Vector of file paths to read
#' @return Combined data frame
readAndCombineFiles <- function(filePaths) {
  if (length(filePaths) == 0) {
    return(NULL)
  }

  allData <- list()

  for (i in seq_along(filePaths)) {
    filePath <- filePaths[i]

    if (!file.exists(filePath)) {
      warning(paste("File does not exist:", filePath))
      next
    }

    fileExt <- tools::file_ext(filePath)

    tryCatch({
      if (fileExt %in% c("csv", "txt")) {
        data <- read.csv(filePath, stringsAsFactors = FALSE)
      } else if (fileExt %in% c("xlsx", "xls")) {
        if (!requireNamespace("openxlsx", quietly = TRUE)) {
          warning("Package 'openxlsx' is required to read Excel files")
          next
        }
        data <- openxlsx::read.xlsx(filePath)
      } else {
        warning(paste("Unsupported file format:", fileExt))
        next
      }

      allData[[i]] <- as.data.frame(data)
    }, error = function(e) {
      warning(paste("Error reading file", basename(filePath), ":", e$message))
    })
  }

  if (length(allData) == 0) {
    return(NULL)
  }

  # Combine all files
  tryCatch({
    combined <- do.call("rbind", allData)
    return(combined)
  }, error = function(e) {
    warning(paste("Error combining files:", e$message))
    return(NULL)
  })
}


#' Generate Sample Data Template
#'
#' @return Data frame template for additional data
generateDataTemplate <- function() {
  template <- data.frame(
    `M+H` = numeric(0),
    `M+H.min` = numeric(0),
    `M+H.max` = numeric(0),
    rt = numeric(0),
    rtmin = numeric(0),
    rtmax = numeric(0),
    Area = numeric(0),
    Height = numeric(0),
    SN = numeric(0),
    sample = character(0),
    iso.mass = character(0),
    iso.mass.link = character(0),
    mz_PeaksIsotopics_Group = character(0),
    rt_PeaksIsotopics_Group = character(0),
    Height_PeaksIsotopics_Group = character(0),
    Adduct = character(0),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  return(template)
}
