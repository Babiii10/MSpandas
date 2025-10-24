# Configure Traitement parallel
# Only register if not already done (prevents socket connection leak)
# This file is sourced multiple times (in renderPlot), causing cluster duplication
if (!exists(".biocparallel_registered_ce_time", envir = .GlobalEnv)) {
  # Use register() without bpstart() to avoid immediate cluster creation
  # Cluster will be created on-demand by bplapply() when needed
  register(SnowParam(workers = 1, type = "SOCK"), default = FALSE)
  assign(".biocparallel_registered_ce_time", TRUE, envir = .GlobalEnv)
}


## Define functions utils

"%ni%"<-Negate("%in%")

#~~~~~~~~~~~~~~~~ Correction time ~~~~~~~~~~~~~~~~~~~~~~~~~~#
alignement_Obiwrap<-function(xdata, 
                             binSize = 1,
                             distFun = "cor_opt",
                             subset = integer(),
                             subsetAdjust = c("average", "previous"),
                             centerSample = integer(),
                             localAlignment = FALSE,
                             response = 1L,
                             factorDiag = 2,
                             factorGap = 1,
                             initPenalty = 0,
                             msLevel = 1L
){
  
  
  parObiwrap<- ObiwarpParam(binSize = binSize,
                            centerSample = centerSample,
                            response = response,
                            distFun = distFun,
                            gapInit = numeric(),
                            gapExtend = numeric(),
                            factorDiag = factorDiag,
                            factorGap = factorGap,
                            localAlignment = localAlignment,
                            initPenalty = initPenalty,
                            subset = subset,
                            subsetAdjust = subsetAdjust
  )
  
  
  data_align<-adjustRtime(xdata, param = parObiwrap, msLevel = msLevel)
  
  return(data_align)
}


###~~~~~~~~~~~~~~~~~~~~~~ Match mz or M+H ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
matchMz <- function(x,
                    table,
                    nomatch = NA_integer_,
                    ppm_tolereance = 50,
                    mzcol = "mz",
                    rtcol = "rt",
                    session
                     ) {
  
  if(!require(MsCoreUtils))
    stop("R package \"MsCoreUtils\" is not found, please install R package \"MsCoreUtils\" ")
  
  
  if (!is.numeric(nomatch) || length(nomatch) != 1L){
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("'nomatch' has to be a 'numeric' of length one."),
      type = "warning"
    )
  }
  
  if (length(dim(x)) != 2 || length(dim(table)) != 2){
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("'x' and 'table' have to be two data frames"),
      type = "warning"
    )
  }
  if (!all(c(mzcol, rtcol) %in% colnames(x)) ||
      !all(c(mzcol, rtcol) %in% colnames(table))){

    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = paste("Required columns : '", 
                   mzcol,"', '",
                   rtcol,
                   "' not found at the same time in reference file and file to align."),
      type = "warning"
    )
    
    return(NULL)
  } else{
    
    if(nrow(x)<2) {
      
      sendSweetAlert(
        session = session,
        title = "Warning !",
        text = paste("'x' must have two or more rows!."),
        type = "warning"
      )
    } else {
      
      table<- table[order(table[,mzcol]), ]
      x<- x[order(x[,mzcol]), ]
      
      table$IDSample<-createID(ref = "IDMatch", number = nrow(table))
      
      rownames(table)<-createID(ref = "IDMatch", number = nrow(table))
      
      
      
      mz1 <- x[, mzcol]
      rt1 <- x[, rtcol]
      mz2 <- table[, mzcol]
      rt2 <- table[, rtcol]
      
      names(mz2)<-createID(ref = "IDMatch", number = length(mz2))
      
      
      idxl <- vector("list", length = nrow(x))
      
      
      withProgress(message = 'In progress..', value = 0, {
        
        pb_match <- txtProgressBar(min=1, max = length(seq_along(idxl)), style = 3)
        cat("matching rt1~rt2 and mz1~mz2 ...!\n")
        
        
        for (i in seq_along(idxl)) {
          
          setTxtProgressBar(pb_match, i)
          
          incProgress(1/length(seq_along(idxl)), detail = "")
          
          matches <- which(abs(mz2-mz1[i])<=MsCoreUtils::ppm(mz1[i], ppm_tolereance))

          if (length(matches)) {
            
            matche <- matches[abs(mz2[matches]-mz1[i])==min(abs(mz2[matches]-mz1[i]))][1]
            idxl[[i]] <- names(mz2)[matche]
            mz2<-mz2[-which(names(mz2) %in% names(mz2)[matche])] 
            
          } else idxl[[i]] <- nomatch
        }
        close(pb_match)
        
      })
      
      cat("OK...!\n")
      
      colnames_x<-colnames(x)
      colnames_table<-colnames(table)
      colnames(x)<-paste0(colnames_x,".1")
      colnames(table)[-ncol(table)]<-paste0(colnames_table[-ncol(table)],".2")

      MatchTable = cbind(x[seq_along(x[,paste0(mzcol,".1")]),],
                         table[unlist(idxl),])
      

      rownames(MatchTable)<-1:nrow(MatchTable)
      
      percentageMatch = round((nrow(MatchTable)-sum(is.na(MatchTable[,paste0(mzcol,".2")])))*100/nrow(MatchTable), digits = 2)
      numberMatch = (nrow(MatchTable)-sum(is.na(MatchTable[,paste0(mzcol,".2")])))
      
    
      return(ResMatch = list(idxl = idxl,
                             percentageMatch = percentageMatch,
                             numberMatch = numberMatch,
                             MatchTable = MatchTable))
        
    }
    
  }
  
  
}
