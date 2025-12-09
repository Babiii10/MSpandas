



## Define functions utils

"%ni%" <- Negate("%in%")



########~~~~~~~~~~~~~~~ Grouping massif by similarity of iso.mass for each sample ~~~~~~~~~~~~########

Grouping.Massif_NewRefMap <- function(X,
                                      ppm.tolerance = 0,
                                      mz.tolerance = 0.150,
                                      rt.tolerance = 30) {
  '%ni%' <- Negate('%in%')
  X <- as.data.frame(X)
  
  
  
  
  rownames(X) <- 1:nrow(X)
  
  N <- nrow(X)
  
  X_new <- X[1, ]
  X_new <- X_new[-1, ]
  
  
  
  while (nrow(X) >= 1) {
    ## sorting by intensity
    #X<-X[order(X$Height),]
    
    # ## sorting by rt
    # X<-X[order(X$rt),]
    
    ## sorting `M+H`
    X <- X[order(X$`M+H`), ]
    
    X_new_iterate <- X[1, ]
    
    print(paste(N - nrow(X), "/", N))
    
    TabSearch <- X[2:nrow(X), ]
    
    #~~~~~~~~~~~~~~~~ Sort by mass column ~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    TabSearch <- TabSearch[order(TabSearch$`M+H`), ]
    
    matchesRTidx <- which(abs(TabSearch$rt - X$rt[1]) <= rt.tolerance)
    TabSearchMatchedRt <- TabSearch[matchesRTidx, ]
    
    
    
    ##~~~~~~~~~~~~ Mass filter ~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    TabSearchMatchedRt$ID <- rownames(TabSearchMatchedRt)
    
    massRef <- X_new_iterate[1, ]$`M+H`
    TabSearchMatchedRt <- TabSearchMatchedRt %>%
      dplyr::filter(abs(`M+H` - massRef) <= 20)
    
    rownames(TabSearchMatchedRt) <- TabSearchMatchedRt$ID
    
    TabSearchMatchedRt <-
      TabSearchMatchedRt[, -ncol(TabSearchMatchedRt)]
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    
    
    if (nrow(TabSearchMatchedRt) == 0) {
      X[1, ]$iso.mass <- str_c(X[1, ]$iso.mass,
                               paste0(X[1, ]$Adduct, ")"),
                               sep = "(",
                               collapse = "(")
      
      X[1, ]$mz_PeaksIsotopics_Group <-
        str_c(
          X[1, ]$mz_PeaksIsotopics_Group,
          paste0(X[1, ]$Adduct, ")"),
          sep = "(",
          collapse = "("
        )
      
      X_new <- rbind(X_new, X[1, ])
      X <- X[-1, ]
      
    } else{
      ## Second matched: compare 3 first iso.mass.of massifs
      massifMatched <- list()
      massifMatchedBool <- c()
      for (j in 1:nrow(TabSearchMatchedRt)) {
        N_Ref_Massif <-
          length(sort(as.numeric(unlist(
            str_split(X$iso.mass.link[1], pattern = ",")
          ))))
        N_Candiadte_Massif <-
          length(sort(as.numeric(unlist(
            str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
          ))))
        
        if (N_Ref_Massif >= 3) {
          if (N_Ref_Massif == 3) {
            if (N_Candiadte_Massif == 2) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:2],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
              
            } else if (N_Candiadte_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:3],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            } else if (N_Candiadte_Massif > 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:4],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            }
          } else {
            if (N_Candiadte_Massif == 2) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:2],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
              
            } else if (N_Candiadte_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:3],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            } else if (N_Candiadte_Massif > 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:4],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            }
          }
          
          
        } else {
          if (N_Candiadte_Massif == 2) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:2],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
            
          } else if (N_Candiadte_Massif == 3) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:3],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
          } else if (N_Candiadte_Massif > 3) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:4],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
          }
          
        }
        
        
      }
      
      idxMassifMatch <-
        rownames(TabSearchMatchedRt[which(!massifMatchedBool), ])
      
      if (length(idxMassifMatch) != 0) {
        ####--------------- Compute Precise mass--------------------------######
        
        # massifMatchedTable<-TabSearchMatchedRt[which(!massifMatchedBool),]
        # massifMatchedTable<-rbind(X_new_iterate[1,],massifMatchedTable)
        # ## Mass order
        # massifMatchedTable<-massifMatchedTable[order(massifMatchedTable$`M+H`),]
        #
        #
        # diff<-c()
        # for(i in 1:length(massifMatchedTable$`M+H`)) {
        #   diff[i]<-abs(massifMatchedTable$`M+H`[i]-massifMatchedTable$`M+H`[1])
        # }
        #
        # massifMatchedTable$diff_massFirstPeak<-diff
        #
        # massifMatchedTable_filter<-massifMatchedTable %>%
        #   dplyr::filter(diff_massFirstPeak<=0.5)
        #
        # Height_firstPeak<-c()
        # for(i in 1:nrow(massifMatchedTable_filter)){
        #   Height_firstPeak[i]<-as.numeric(unlist(str_split(massifMatchedTable_filter[i,"Height_PeaksIsotopics"], pattern = ",")))[1]
        # }
        #
        # massifMatchedTable_filter$Height_firstPeak<-Height_firstPeak
        #
        # idxMassPrecise<-which(massifMatchedTable_filter$Height_firstPeak==max(massifMatchedTable_filter$Height_firstPeak))[1]
        #
        # X_new_iterate[1,]$`M+H`<-massifMatchedTable_filter[idxMassPrecise,]$`M+H`
        # X_new_iterate[1,]$Precursor.mz<-massifMatchedTable_filter[idxMassPrecise,]$Precursor.mz
        
        
        #####-----------------------Add Group info-----------------------#################
        X_new_iterate[1, ]$iso.mass <-
          str_c(
            str_c(
              X_new_iterate[1, ]$iso.mass,
              paste0(X_new_iterate[1, ]$Adduct, ")"),
              sep = "(",
              collapse = "("
            ),
            str_c(
              paste0(X[idxMassifMatch, ]$iso.mass,
                     "(", X[idxMassifMatch, ]$Adduct, ")"),
              sep = "--->",
              collapse = "--->"
            )
            ,
            sep = "--->",
            collapse = "--->"
          )
        
        ####--------------- Compute Precise mass--------------------------######
        
        massifMatchedTable <-
          TabSearchMatchedRt[which(!massifMatchedBool), ]
        massifMatchedTable <-
          rbind(X_new_iterate[1, ], massifMatchedTable)
        ## Mass order
        massifMatchedTable <-
          massifMatchedTable[order(massifMatchedTable$`M+H`), ]
        
        
        diff <- c()
        for (i in 1:length(massifMatchedTable$`M+H`)) {
          diff[i] <-
            abs(massifMatchedTable$`M+H`[i] - massifMatchedTable$`M+H`[1])
        }
        
        massifMatchedTable$diff_massFirstPeak <- diff
        
        TabGroup.iso.mass <- rbind(X_new_iterate[1, ],
                                   X[idxMassifMatch, ])
        
        P1_mass <- c()
        for (i in 1:nrow(TabGroup.iso.mass)) {
          n_massif <-
            length(as.numeric(unlist(
              str_split(TabGroup.iso.mass[i, ]$iso.mass.link, pattern = ",")
            )))
          P1_mass[i] <-
            median(as.numeric(unlist(
              str_split(TabGroup.iso.mass[i, ]$iso.mass.link, pattern = ",")
            )) - c(0:(n_massif - 1)))
        }
        
        ## sort P1
        P1_mass <- sort(P1_mass)
        idxP1 <- which(abs(P1_mass - P1_mass[1]) <= 0.4)
        X_new_iterate_P1_mass <- median(P1_mass[idxP1])
        X_new_iterate[1, ]$`M+H` <- X_new_iterate_P1_mass
        
        ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~####
        
        #### Extract complete massif by using all massif grouping
        # iso.mass.link
        TabGoup.Link <- rbind(X_new_iterate[1, ]$iso.mass.link,
                              X[idxMassifMatch, ]$iso.mass.link)
        
        
        # ## Extract iso.mass link
        
        TabGoup.Link <-
          as.numeric(unlist(str_split(TabGoup.Link, pattern = ",")))
        TabGoup.Link <- sort(TabGoup.Link)
        
        mass.iso.mass.link <- c()
        
        while (length(TabGoup.Link) != 0) {
          idxP <- which(abs(TabGoup.Link - TabGoup.Link[1]) <= 0.4)
          mass.iso.mass.link <-
            c(mass.iso.mass.link, median(TabGoup.Link[idxP]))
          
          TabGoup.Link <- TabGoup.Link[-idxP]
          
        }
        
        
        if (length(mass.iso.mass.link) > 1) {
          X_new_iterate[1, ]$iso.mass.link <- toString(mass.iso.mass.link)
          
          #####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~###
          
          X_new_iterate[1, ]$mz_PeaksIsotopics_Group <-
            str_c(
              str_c(
                X_new_iterate[1, ]$mz_PeaksIsotopics_Group,
                paste0(X_new_iterate[1, ]$Adduct, ")"),
                sep = "(",
                collapse = "("
              ),
              str_c(
                paste0(X[idxMassifMatch, ]$mz_PeaksIsotopics_Group,
                       "(", X[idxMassifMatch, ]$Adduct, ")"),
                sep = "--->",
                collapse = "--->"
              ),
              sep = "--->",
              collapse = "--->"
            )
          
          X_new_iterate[1, ]$rt_PeaksIsotopics_Group <-
            str_c(
              c(
                X_new_iterate[1, ]$rt_PeaksIsotopics_Group,
                X[idxMassifMatch, ]$rt_PeaksIsotopics
              ),
              sep = ",",
              collapse = ","
            )
          
          X_new_iterate[1, ]$Height_PeaksIsotopics_Group <-
            str_c(
              c(
                X_new_iterate[1, ]$Height_PeaksIsotopics_Group,
                X[idxMassifMatch, ]$Height_PeaksIsotopics_Group
              ),
              sep = ",",
              collapse = ","
            )
          
          
          
          
          #sum intensity for all massif grouped
          X_new_iterate[1, ]$Height <- sum(massifMatchedTable$Height)
          X_new_iterate[1, ]$Area <- sum(massifMatchedTable$Area)
          X_new_iterate[1, ]$rt <- median(massifMatchedTable$rt)
          X_new_iterate[1, ]$rtmin <- median(massifMatchedTable$rtmin)
          X_new_iterate[1, ]$rtmax <- median(massifMatchedTable$rtmax)
          
          
          
          X <- X[-1, ]
          X <- X[-which(rownames(X) %in% idxMassifMatch), ]
          X_new <- rbind(X_new, X_new_iterate)
          
        } else {
          X <- X[-1, ]
          X <- X[-which(rownames(X) %in% idxMassifMatch), ]
        }
        
        
      } else{
        X[1, ]$iso.mass <- str_c(X[1, ]$iso.mass,
                                 paste0(X[1, ]$Adduct, ")"),
                                 sep = "(",
                                 collapse = "(")
        
        X[1, ]$mz_PeaksIsotopics_Group <-
          str_c(
            X[1, ]$mz_PeaksIsotopics_Group,
            paste0(X[1, ]$Adduct, ")"),
            sep = "(",
            collapse = "("
          )
        X_new <- rbind(X_new, X[1, ])
        X <- X[-1, ]
      }
      
      
    }
    
  }
  
  X_new <- X_new[order(X_new$`M+H`), ]
  
  return(X_new)
}



########~~~~~~~~~~~~~~~ Second Grouping massif by similarity of iso.mass for each sample ~~~~~~~~~~~~########

Grouping.Massif_NewRefMap_Second <- function(X,
                                             ppm.tolerance = 0,
                                             mz.tolerance = 0.09,
                                             rt.tolerance = 180) {
  '%ni%' <- Negate('%in%')
  X <- as.data.frame(X)
  
  
  
  rownames(X) <- 1:nrow(X)
  
  N <- nrow(X)
  
  X_new <- X[1, ]
  X_new <- X_new[-1, ]
  
  while (nrow(X) >= 1) {
    ## sorting by intensity
    #X<-X[order(X$Height),]
    
    # ## sorting by rt
    # X<-X[order(X$rt),]
    
    ## sorting `M+H`
    X <- X[order(X$`M+H`), ]
    
    X_new_iterate <- X[1, ]
    
    print(paste(N - nrow(X), "/", N))
    
    TabSearch <- X[2:nrow(X), ]
    #~~~~~~~~~~~~~~~~ Sort by mass column ~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    TabSearch <- TabSearch[order(TabSearch$`M+H`), ]
    
    matchesRTidx <- which(abs(TabSearch$rt - X$rt[1]) <= rt.tolerance)
    TabSearchMatchedRt <- TabSearch[matchesRTidx, ]
    
    ##~~~~~~~~~~~~ Mass filter ~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    TabSearchMatchedRt$ID <- rownames(TabSearchMatchedRt)
    
    massRef <- X_new_iterate[1, ]$`M+H`
    TabSearchMatchedRt <- TabSearchMatchedRt %>%
      dplyr::filter(abs(`M+H` - massRef) <= 20)
    
    rownames(TabSearchMatchedRt) <- TabSearchMatchedRt$ID
    
    TabSearchMatchedRt <-
      TabSearchMatchedRt[, -ncol(TabSearchMatchedRt)]
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    
    if (nrow(TabSearchMatchedRt) == 0) {
      X_new <- rbind(X_new, X[1, ])
      X <- X[-1, ]
      
    } else{
      ## Second matched: compare 3 first iso.mass.of massifs
      massifMatched <- list()
      massifMatchedBool <- c()
      for (j in 1:nrow(TabSearchMatchedRt)) {
        N_Ref_Massif <-
          length(sort(as.numeric(unlist(
            str_split(X$iso.mass.link[1], pattern = ",")
          ))))
        N_Candiadte_Massif <-
          length(sort(as.numeric(unlist(
            str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
          ))))
        
        if (N_Ref_Massif >= 3) {
          if (N_Ref_Massif == 3) {
            if (N_Candiadte_Massif == 2) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:2],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
              
            } else if (N_Candiadte_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:3],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            } else if (N_Candiadte_Massif > 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:4],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            }
          } else {
            if (N_Candiadte_Massif == 2) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:2],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
              
            } else if (N_Candiadte_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:3],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            } else if (N_Candiadte_Massif > 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                sort(as.numeric(unlist(
                  str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                )))[1:4],
                sort(as.numeric(unlist(
                  str_split(X$iso.mass.link[1], pattern = ",")
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              
              
              massifMatchedBool[j] <-
                sum(!is.na(massifMatched[[j]])) <= 1
            }
          }
          
          
        } else {
          if (N_Candiadte_Massif == 2) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:2],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
            
          } else if (N_Candiadte_Massif == 3) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:3],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
          } else if (N_Candiadte_Massif > 3) {
            massifMatched[[j]] <- MsCoreUtils::closest(
              sort(as.numeric(unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )))[1:4],
              sort(as.numeric(unlist(
                str_split(X$iso.mass.link[1], pattern = ",")
              )))[1:2],
              tolerance = mz.tolerance,
              ppm = ppm.tolerance,
              duplicates = "closest"
            )
            
            
            massifMatchedBool[j] <- sum(!is.na(massifMatched[[j]])) <= 1
          }
          
        }
        
        
      }
      
      idxMassifMatch <-
        rownames(TabSearchMatchedRt[which(!massifMatchedBool), ])
      
      if (length(idxMassifMatch) != 0) {
        massifMatchedTable <- TabSearchMatchedRt[which(!massifMatchedBool), ]
        massifMatchedTable <-
          rbind(X_new_iterate[1, ], massifMatchedTable)
        
        idxMassifSelected <-
          which(massifMatchedTable$Height == max(massifMatchedTable$Height))[1]
        
        
        
        
        #####-----------------------Add Group info-----------------------#################
        X_new_iterate[1, ]$iso.mass <-
          massifMatchedTable[idxMassifSelected, ]$iso.mass
        
        
        # ####--------------- Compute Precise mass--------------------------######
        #
        # massifMatchedTable<-TabSearchMatchedRt[which(!massifMatchedBool),]
        # massifMatchedTable<-rbind(X_new_iterate[1,],massifMatchedTable)
        #
        # diff<-c()
        # for(i in 1:length(massifMatchedTable$`M+H`)) {
        #   diff[i]<-abs(massifMatchedTable$`M+H`[i]-massifMatchedTable$`M+H`[1])
        # }
        #
        # massifMatchedTable$diff_massFirstPeak<-diff
        #
        # TabGroup.iso.mass<-rbind(X_new_iterate[1,],
        #                          X[idxMassifMatch,])
        #
        # P1_mass<-c()
        # for(i in 1:nrow(TabGroup.iso.mass)){
        #   n_massif<-length(as.numeric(unlist(str_split(TabGroup.iso.mass[i,]$iso.mass.link, pattern = ","))))
        #   P1_mass[i]<-median(as.numeric(unlist(str_split(TabGroup.iso.mass[i,]$iso.mass.link, pattern = ",")))-c(0:(n_massif-1)))
        # }
        #
        # ## sort P1
        # P1_mass<-sort(P1_mass)
        # idxP1<-which(abs(P1_mass-P1_mass[1])<=0.4)
        # X_new_iterate_P1_mass<-median(P1_mass[idxP1])
        # X_new_iterate[1,]$`M+H`<-X_new_iterate_P1_mass
        #
        # ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~####
        #
        # # iso.mass.link
        # TabGoup.Link<-rbind(X_new_iterate[1,]$iso.mass.link,
        #                     X[idxMassifMatch,]$iso.mass.link)
        #
        # # #Extract iso.mass link with has the minimum mass
        # # mass.iso.mass.link<-c()
        # # for (i in 1:nrow(TabGoup.Link)) {
        # #   mass.iso.mass.link[i]<-min(unlist(str_split(TabGoup.Link[i], pattern = ",")))
        # # }
        # #
        # # idx.iso.mass.link<-which(mass.iso.mass.link == min(mass.iso.mass.link))[1]
        # #
        # # X_new_iterate[1,]$iso.mass.link<-TabGoup.Link[idx.iso.mass.link]
        #
        # # ## Extract iso.mass link
        #
        # TabGoup.Link<-as.numeric(unlist(str_split(TabGoup.Link, pattern = ",")))
        # TabGoup.Link<-sort(TabGoup.Link)
        #
        # mass.iso.mass.link<-c()
        #
        # while(length(TabGoup.Link)!=0){
        #   idxP<-which(abs(TabGoup.Link-TabGoup.Link[1])<=0.4)
        #   mass.iso.mass.link<-c(mass.iso.mass.link, median(TabGoup.Link[idxP]))
        #
        #   TabGoup.Link<-TabGoup.Link[-idxP]
        #
        #   message("\n TabGoup.Link")
        #   print(TabGoup.Link)
        # }
        #
        # message("\n mass.iso.mass.link")
        # print(mass.iso.mass.link)
        #
        # if(length(mass.iso.mass.link)>1){
        #   X_new_iterate[1,]$iso.mass.link<-toString(mass.iso.mass.link)
        # }
        
        
        #####~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#####
        X_new_iterate[1, ]$mz_PeaksIsotopics_Group <-
          massifMatchedTable[idxMassifSelected, ]$mz_PeaksIsotopics_Group
        
        X_new_iterate[1, ]$rt_PeaksIsotopics_Group <-
          massifMatchedTable[idxMassifSelected, ]$rt_PeaksIsotopics_Group
        
        X_new_iterate[1, ]$Height_PeaksIsotopics_Group <-
          massifMatchedTable[idxMassifSelected, ]$Height_PeaksIsotopics_Group
        
        
        
        
        #max intensity for all massif grouped
        X_new_iterate[1, ]$Height <-
          massifMatchedTable[idxMassifSelected, ]$Height
        X_new_iterate[1, ]$Area <-
          massifMatchedTable[idxMassifSelected, ]$Area
        X_new_iterate[1, ]$rt <-
          massifMatchedTable[idxMassifSelected, ]$rt
        X_new_iterate[1, ]$rtmin <-
          massifMatchedTable[idxMassifSelected, ]$rtmin
        X_new_iterate[1, ]$rtmax <-
          massifMatchedTable[idxMassifSelected, ]$rtmax
        
        
        
        X <- X[-1, ]
        X <- X[-which(rownames(X) %in% idxMassifMatch), ]
        X_new <- rbind(X_new, X_new_iterate)
      } else{
        X_new <- rbind(X_new, X[1, ])
        X <- X[-1, ]
      }
      
    }
    
  }
  
  X_new <- X_new[order(X_new$`M+H`), ]
  
  return(X_new)
}


########~~~~~~~~~~~~~~~~~~~~~~ Grouping massif by similarity of iso.mass between samples ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~########
###################################################################################################################################
#######~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

Grouping.Between.Sample <- function(X,
                                    ppm.tolerance = 0,
                                    mz.tolerance = 0.150,
                                    rt.tolerance = 180) {
  '%ni%' <- Negate('%in%')
  X <- as.data.frame(X)
  
  
  X <- X[order(X$`M+H`), ]
  
  X$rt_GroupSample_Adjust <- X$rt
  
  N <- nrow(X)
  X$ID <- rownames(X) # new
  X$FeaturesIDx <- X$ID
  
  X_new <- X[1, ]
  X_new <- X_new[-1, ]
  
  
  #####~~~~~~~~~~~~~To iterate~~~~~~~~~~~~~~######
  
  niterj <- nrow(X)
  withProgress(message = 'Grouping features between samples...', value = 0, {
    while (nrow(X) >= 1) {
      incProgress(1 / niterj, detail = "")
      
      print(paste0(N - nrow(X), "/", N))
      ## Go by Feature more intense
      X <- X[order(X$`M+H`), ]
      
      X_new_iterate <- X[1, ]
      
      matchesRTidx <- which(abs(X[-1, ]$rt - X$rt[1]) <= rt.tolerance)
      TabSearchMatchedRt <- X[-1, ][matchesRTidx, ]
      
      #"~~~~~~~~~~~~~~ sort by mass ~~~~~~~~~~~~~~~~~~~#
      TabSearchMatchedRt <-
        TabSearchMatchedRt[order(TabSearchMatchedRt$`M+H`), ]
      
      ## Mass filter
      massRef <- X_new_iterate[1, ]$`M+H`
      TabSearchMatchedRt <- TabSearchMatchedRt %>%
        dplyr::filter(abs(`M+H` - massRef) <= 20)
      
      rownames(TabSearchMatchedRt) <- TabSearchMatchedRt$ID
      
      
      
      
      if (nrow(TabSearchMatchedRt) == 0) {
        X_new <- rbind(X_new, X[1, ])
        X <- X[-1, ]
        
      } else{
        massifMatched <- list()
        massifMatchedBool <- c()
        
        
        for (j in 1:nrow(TabSearchMatchedRt)) {
          N_Ref_Massif <-
            length(unique(sort(as.numeric(
              unlist(str_split(X$iso.mass.link[1], pattern = ","))
            ))))
          N_Candidate_Massif <-
            length(unique(sort(as.numeric(
              unlist(
                str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
              )
            ))))
          
          if (N_Candidate_Massif == 2 | N_Candidate_Massif == 3) {
            if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                ))),
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif > 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            }
            
            
          } else if (N_Candidate_Massif == 4 |
                     N_Candidate_Massif == 5) {
            if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                ))),
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif  == 4) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif > 4) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:3],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            }
          } else if (N_Candidate_Massif == 6 |
                     N_Candidate_Massif == 7) {
            if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                ))),
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif  == 4) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif == 5) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:3],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif > 5) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:4],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:5],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            }
            
          } else if (N_Candidate_Massif >= 8) {
            if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                ))),
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif  == 4) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:2],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:3],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif  == 5) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:3],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:4],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif == 6) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:4],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:5],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            } else if (N_Ref_Massif > 6) {
              massifMatched[[j]] <- MsCoreUtils::closest(
                unique(sort(as.numeric(
                  unlist(
                    str_split(TabSearchMatchedRt[j, ]$iso.mass.link, pattern = ",")
                  )
                )))[1:5],
                unique(sort(as.numeric(
                  unlist(str_split(
                    X$iso.mass.link[1], pattern = ","
                  ))
                )))[1:6],
                tolerance = mz.tolerance,
                ppm = ppm.tolerance,
                duplicates = "closest"
              )
              massifMatchedBool[j] <-
                is.element(NA, massifMatched[[j]])
            }
          }
          
        }
        
        
        
        idxMassifMatch <-
          rownames(TabSearchMatchedRt[which(!massifMatchedBool), ])
        
        
        
        if (length(idxMassifMatch) != 0) {
          TabGroup_idxMassifMatch <- X[idxMassifMatch, ]
          
          
          #1.Exclude features in sample
          idxInsample <-
            which(TabGroup_idxMassifMatch$sample == X_new_iterate[1, ]$sample)
          
          
          if (length(idxInsample) != 0) {
            idxMassifMatch <- idxMassifMatch[-idxInsample]
            
            
          }
          
          
          #2. choice features in same sample
          if (length(idxMassifMatch) != 0) {
            TabGroup_idxMassifMatch <- X[idxMassifMatch, ]
            
            for (sample in unique(TabGroup_idxMassifMatch$sample)) {
              idxInOtherSample <- which(TabGroup_idxMassifMatch$sample == sample)
              if (length(idxInOtherSample) >= 2) {
                TabInOthersample <- TabGroup_idxMassifMatch[idxInOtherSample, ]
                idxSelectedInOtherSample <-
                  rownames(TabInOthersample[which(abs(TabInOthersample$rt - X_new_iterate[1, ]$rt) ==
                                                    min(abs(
                                                      TabInOthersample$rt - X_new_iterate[1, ]$rt
                                                    )))[1], ])
                
                idxExcludeInOtherSample <-
                  rownames(TabInOthersample)[rownames(TabInOthersample) != idxSelectedInOtherSample]
                
                idxMassifMatch <-
                  idxMassifMatch[-which(idxMassifMatch %in% idxExcludeInOtherSample)]
                
              }
            }
            
            
            #####-----------------------Add Group info-----------------------#################
            TableGroup <- rbind(X_new_iterate[1, ],
                                X[idxMassifMatch, ])
            
            TableGroup$iso.mass.link[1] <-
              paste0(TableGroup$iso.mass.link[1], "***")
            TableGroup <- TableGroup[order(TableGroup$sample), ]
            
            
            X_new_iterate[1, ]$iso.mass <- str_c(TableGroup$iso.mass,
                                                 sep = "--->",
                                                 collapse = "--->")
            
            # iso.mass.link
            X_new_iterate[1, ]$iso.mass.link <-
              str_c(TableGroup$iso.mass.link,
                    sep = "--->",
                    collapse = "--->")  # new
            
            ## delete mark "***" in "TableGroup"
            TableGroup$iso.mass.link <-
              str_remove(TableGroup$iso.mass.link, pattern = "\\*\\*\\*")
            
            
            X_new_iterate[1, ]$mz_PeaksIsotopics_Group <-
              str_c(
                TableGroup$mz_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            X_new_iterate[1, ]$rt_PeaksIsotopics_Group <-
              str_c(
                TableGroup$rt_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            X_new_iterate[1, ]$Height_PeaksIsotopics_Group <-
              str_c(
                TableGroup$Height_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            X_new_iterate[1, ]$FeaturesIDx <- list(TableGroup$ID) #new
            
            
            # ####--------------- Computing some columns --------------------------######
            
            ###~~~~~~~~~~~~~~~~~~~~~~ Computing precise mass ~~~~~~~~~~~~~~~~~~~~###
            
            iso.mass.link.Group <-
              sort(as.numeric(unlist(
                str_split(TableGroup$iso.mass.link, pattern = ",")
              )))
            idxP1 <-
              which(abs(iso.mass.link.Group - iso.mass.link.Group[1]) <= 0.4)
            
            X_new_iterate[1, ]$`M+H` <-
              median(iso.mass.link.Group[idxP1])
            
            X_new_iterate[1, ]$`M+H.min` <-
              median(TableGroup$`M+H.min`)
            X_new_iterate[1, ]$`M+H.max` <-
              median(TableGroup$`M+H.max`)
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            X_new_iterate[1, ]$rt <- median(TableGroup$rt)
            ## Info rt adj
            X_new_iterate[1, ]$rt_GroupSample_Adjust <-
              str_c(TableGroup$rt,
                    sep = "--->",
                    collapse = "--->")
            X_new_iterate[1, ]$rtmin <- median(TableGroup$rtmin)
            X_new_iterate[1, ]$rtmax <- median(TableGroup$rtmax)
            
            X_new_iterate[1, ]$Height <- median(TableGroup$Height)
            
            X_new_iterate[1, ]$Area <- median(TableGroup$Area)
            
            
            
            
            
            X <- X[-1, ]
            X <- X[-which(rownames(X) %in% idxMassifMatch), ]
            X_new <- rbind(X_new, X_new_iterate)
            
            
            
          } else {
            X_new <- rbind(X_new, X[1, ])
            X <- X[-1, ]
          }
          
          
        } else{
          X_new <- rbind(X_new, X[1, ])
          X <- X[-1, ]
        }
      }
    }
    
  })
  
  
  ##~~~~~~~~~~~~~~~~~~~~ When use C++ files ~~~~~~~~~~~~~~~~~##
  # iterateVal<-function(X, X_new){
  #
  #   print(paste0(N-nrow(X),"/",N))
  #   ## Go by Feature more intense
  #   X<-X[order(X$rt),]
  #
  #   X_new_iterate <- X[1,]
  #
  #   matchesRTidx<-which(abs(X[-1,]$rt - X$rt[1]) <= rt.tolerance)
  #   TabSearchMatchedRt<-X[-1,][matchesRTidx,]
  #
  #   #"~~~~~~~~~~~~~~ sort by mass ~~~~~~~~~~~~~~~~~~~#
  #   TabSearchMatchedRt<-TabSearchMatchedRt[order(TabSearchMatchedRt$`M+H`),]
  #
  #   ## Mass filter
  #   massRef<-X_new_iterate[1,]$`M+H`
  #   TabSearchMatchedRt<-TabSearchMatchedRt %>%
  #     dplyr::filter((`M+H`- massRef)<=10)
  #
  #   # matches[which(abs(mass2[matches]-mass1[i])<=5)]
  #
  #   if(nrow(TabSearchMatchedRt)==0){
  #
  #     X_new<-rbind(X_new, X[1,])
  #     X<-X[-1,]
  #
  #   } else{
  #
  #     massifMatched<-list()
  #     massifMatchedBool<-c()
  #     for(j in 1:nrow(TabSearchMatchedRt)) {
  #
  #       N_first_Massif<-length(unique(sort(as.numeric(unlist(str_split(X$iso.mass.link[1], pattern = ","))))))
  #
  #       if(N_first_Massif>=3){
  #
  #         massifMatched[[j]]<-MsCoreUtils::closest(
  #           unique(sort(as.numeric(unlist(str_split(TabSearchMatchedRt[j,]$iso.mass.link, pattern = ",")))))[1:2],
  #           unique(sort(as.numeric(unlist(str_split(X$iso.mass.link[1], pattern = ",")))))[1:3],
  #           tolerance = mz.tolerance, ppm = ppm.tolerance)
  #         massifMatchedBool[j]<-all(is.na(massifMatched[[j]]))
  #
  #       } else {
  #
  #         massifMatched[[j]]<-MsCoreUtils::closest(
  #           unique(sort(as.numeric(unlist(str_split(TabSearchMatchedRt[j,]$iso.mass.link, pattern = ",")))))[1:2],
  #           unique(sort(as.numeric(unlist(str_split(X$iso.mass.link[1], pattern = ",")))))[1:2],
  #           tolerance = mz.tolerance, ppm = ppm.tolerance)
  #         massifMatchedBool[j]<-all(is.na(massifMatched[[j]]))
  #
  #       }
  #
  #
  #
  #
  #     }
  #
  #     idxMassifMatch<-rownames(TabSearchMatchedRt[which(!massifMatchedBool),])
  #
  #
  #
  #     if(length(idxMassifMatch)!=0){
  #
  #       TabGroup_idxMassifMatch<-X[idxMassifMatch,]
  #
  #       message("X_new_iterate: ")
  #       print(X_new_iterate[1,])
  #
  #       message("TabGroup_idxMassifMatch: ")
  #       print(TabGroup_idxMassifMatch)
  #
  #       #1.Exclude features in sample
  #       idxInsample<-which(TabGroup_idxMassifMatch$sample == X_new_iterate[1,]$sample)
  #
  #       message("idxInsample: ")
  #       print(idxInsample)
  #
  #       if(length(idxInsample)!=0){
  #
  #         idxMassifMatch<-idxMassifMatch[-idxInsample]
  #
  #
  #       }
  #
  #
  #       #2. choice features in same sample
  #       if(length(idxMassifMatch)!=0){
  #
  #         TabGroup_idxMassifMatch<-X[idxMassifMatch,]
  #
  #         for(sample in unique(TabGroup_idxMassifMatch$sample)){
  #
  #           idxInOtherSample<-which(TabGroup_idxMassifMatch$sample == sample)
  #           if(length(idxInOtherSample)>=2){
  #             TabInOthersample<-TabGroup_idxMassifMatch[idxInOtherSample,]
  #             idxSelectedInOtherSample<-rownames(TabInOthersample[which(abs(TabInOthersample$rt-X_new_iterate[1,]$rt)==min(abs(TabInOthersample$rt-X_new_iterate[1,]$rt)))[1],])
  #
  #             idxExcludeInOtherSample<-rownames(TabInOthersample)[rownames(TabInOthersample) != idxSelectedInOtherSample]
  #
  #             idxMassifMatch<-idxMassifMatch[-which(idxMassifMatch %in% idxExcludeInOtherSample)]
  #
  #           }
  #         }
  #
  #
  #         #####-----------------------Add Group info-----------------------#################
  #         TableGroup<-rbind(X_new_iterate[1,],
  #                           X[idxMassifMatch,])
  #
  #         TableGroup<-TableGroup[order(TableGroup$sample),]
  #
  #         message("TableGroup:")
  #         print(TableGroup)
  #
  #         X_new_iterate[1,]$iso.mass<-str_c(TableGroup$iso.mass,
  #                                           sep = "--->", collapse = "--->")
  #
  #         # iso.mass.link
  #
  #         X_new_iterate[1,]$iso.mass.link<-str_c(TableGroup$iso.mass.link,
  #                                                sep = "--->", collapse = "--->")  # new
  #
  #
  #         X_new_iterate[1,]$mz_PeaksIsotopics_Group<-str_c(TableGroup$mz_PeaksIsotopics_Group,
  #                                                          sep = "--->", collapse = "--->")
  #
  #         X_new_iterate[1,]$rt_PeaksIsotopics_Group<-str_c(TableGroup$rt_PeaksIsotopics_Group,
  #                                                          sep = "--->", collapse = "--->")
  #
  #         X_new_iterate[1,]$Height_PeaksIsotopics_Group<-str_c(TableGroup$Height_PeaksIsotopics_Group,
  #                                                              sep = "--->", collapse = "--->")
  #
  #         X_new_iterate[1,]$FeaturesIDx<-list(TableGroup$ID) #new
  #
  #
  #         # ####--------------- Computing some columns --------------------------######
  #
  #         X_new_iterate[1,]$`M+H`<-median(TableGroup$`M+H`)
  #         X_new_iterate[1,]$`M+H.min`<-median(TableGroup$`M+H.min`)
  #         X_new_iterate[1,]$`M+H.max`<-median(TableGroup$`M+H.max`)
  #
  #
  #         X_new_iterate[1,]$rt<-median(TableGroup$rt)
  #         X_new_iterate[1,]$rtmin<-median(TableGroup$rtmin)
  #         X_new_iterate[1,]$rtmax<-median(TableGroup$rtmax)
  #
  #         X_new_iterate[1,]$Height<-median(TableGroup$Height)
  #
  #         X_new_iterate[1,]$Area<-median(TableGroup$Area)
  #
  #
  #
  #
  #
  #         X<-X[-1,]
  #         X<-X[-which(rownames(X) %in% idxMassifMatch),]
  #         X_new<-rbind(X_new, X_new_iterate)
  #
  #
  #
  #       } else {
  #         X_new<-rbind(X_new, X[1,])
  #         X<-X[-1,]
  #       }
  #
  #
  #     } else{
  #       X_new<-rbind(X_new, X[1,])
  #       X<-X[-1,]
  #     }
  #   }
  #
  #   return(list(X = X, X_new = X_new))
  # }
  
  
  # ## source the cpp file
  # sourceCpp("lib/NewReferenceMap/Rcpp_files/Gouping_Massif_Between_Sample.cpp")
  #
  # ## excute iterateFunction on iterateVal
  # X_new <-iterateFunction(X, X_new, iterateVal)[[2]]
  
  reColsReturn <-
    c(
      "M+H",
      "rt",
      "Height",
      "iso.mass",
      "iso.mass.link",
      "rt_GroupSample_Adjust",
      "mz_PeaksIsotopics_Group",
      "rt_PeaksIsotopics_Group",
      "Height_PeaksIsotopics_Group",
      "ID",
      "FeaturesIDx"
    )
  
  X_new <- X_new[, reColsReturn]
  return(X_new)
}


########~~~~~~~~~~~~~~~~~~~~~~ Grouping Between Samples - PARALLEL VERSION ~~~~~~~~~~~~~~~~~~########
###################################################################################################
#######~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

Grouping.Between.Sample.Parallel <- function(X,
                                              ppm.tolerance = 0,
                                              mz.tolerance = 0.150,
                                              rt.tolerance = 180,
                                              n_cores = NULL,
                                              use_parallel = TRUE) {

  # Check if parallel processing is requested and available
  if (!use_parallel) {
    message("Parallel processing disabled. Using sequential Grouping.Between.Sample...")
    return(Grouping.Between.Sample(X = X,
                                    ppm.tolerance = ppm.tolerance,
                                    mz.tolerance = mz.tolerance,
                                    rt.tolerance = rt.tolerance))
  }

  # Determine number of cores
  if (is.null(n_cores)) {
    n_cores <- max(1, parallel::detectCores() - 1)
  }

  # For small datasets, use sequential processing
  if (nrow(X) < 100 || n_cores == 1) {
    message("Dataset too small or only 1 core available. Using sequential processing...")
    return(Grouping.Between.Sample(X = X,
                                    ppm.tolerance = ppm.tolerance,
                                    mz.tolerance = mz.tolerance,
                                    rt.tolerance = rt.tolerance))
  }

  '%ni%' <- Negate('%in%')
  X <- as.data.frame(X)
  X <- X[order(X$`M+H`), ]

  message(paste("Starting parallel grouping with", n_cores, "cores..."))

  # Try-catch for error handling
  result <- tryCatch({

    # Check required packages
    if (!require(BiocParallel)) {
      warning("BiocParallel package not available. Falling back to sequential processing.")
      return(Grouping.Between.Sample(X = X,
                                      ppm.tolerance = ppm.tolerance,
                                      mz.tolerance = mz.tolerance,
                                      rt.tolerance = rt.tolerance))
    }

    # Divide data into blocks by m/z with overlap
    n_blocks <- min(n_cores * 2, nrow(X))  # 2x blocks vs cores for better load balancing
    mz_overlap <- 50  # Overlap in Da to handle features at block boundaries

    # Create block assignments
    X$block_id <- cut(1:nrow(X), breaks = n_blocks, labels = FALSE)

    # Create blocks list with overlap
    blocks_list <- list()
    for (block_num in 1:n_blocks) {
      block_data <- X[X$block_id == block_num, ]

      if (nrow(block_data) == 0) next

      # Add overlap with previous block
      if (block_num > 1) {
        prev_block <- X[X$block_id == (block_num - 1), ]
        if (nrow(prev_block) > 0) {
          mz_min <- min(block_data$`M+H`, na.rm = TRUE)
          overlap_prev <- prev_block[prev_block$`M+H` >= (mz_min - mz_overlap), ]
          if (nrow(overlap_prev) > 0) {
            overlap_prev$is_overlap <- TRUE
            block_data$is_overlap <- FALSE
            block_data <- rbind(overlap_prev, block_data)
          }
        }
      }

      # Add overlap with next block
      if (block_num < n_blocks) {
        next_block <- X[X$block_id == (block_num + 1), ]
        if (nrow(next_block) > 0) {
          mz_max <- max(block_data$`M+H`, na.rm = TRUE)
          overlap_next <- next_block[next_block$`M+H` <= (mz_max + mz_overlap), ]
          if (nrow(overlap_next) > 0) {
            overlap_next$is_overlap <- TRUE
            if (!"is_overlap" %in% colnames(block_data)) {
              block_data$is_overlap <- FALSE
            }
            block_data <- rbind(block_data, overlap_next)
          }
        }
      }

      # Mark core features (not overlap) if not already marked
      if (!"is_overlap" %in% colnames(block_data)) {
        block_data$is_overlap <- FALSE
      }

      blocks_list[[length(blocks_list) + 1]] <- block_data
    }

    # Remove empty blocks
    blocks_list <- blocks_list[sapply(blocks_list, function(x) !is.null(x) && nrow(x) > 0)]

    message(paste("Processing", length(blocks_list), "blocks in parallel..."))

    # Setup parallel backend
    if (.Platform$OS.type == "unix") {
      # Use MulticoreParam on Unix (more efficient)
      param <- MulticoreParam(workers = n_cores, progressbar = FALSE)
    } else {
      # Use SnowParam on Windows
      param <- SnowParam(workers = n_cores, type = "SOCK", progressbar = FALSE)
    }

    # Process each block in parallel
    process_block <- function(block_data) {
      if (is.null(block_data) || nrow(block_data) == 0) return(NULL)

      # Remove block_id and is_overlap columns before processing
      block_data$block_id <- NULL
      is_overlap_col <- block_data$is_overlap
      block_data$is_overlap <- NULL

      # Apply original grouping logic to this block
      result <- Grouping.Between.Sample(
        X = block_data,
        ppm.tolerance = ppm.tolerance,
        mz.tolerance = mz.tolerance,
        rt.tolerance = rt.tolerance
      )

      # Mark which rows were from overlap regions
      if (!is.null(result) && nrow(result) > 0) {
        result$was_overlap <- FALSE  # Will be filtered later if needed
      }

      return(result)
    }

    # Execute parallel processing
    results_list <- bplapply(blocks_list, process_block, BPPARAM = param)

    # Combine results
    results_combined <- do.call("rbind", results_list[!sapply(results_list, is.null)])

    # Remove helper columns
    if ("was_overlap" %in% colnames(results_combined)) {
      results_combined$was_overlap <- NULL
    }
    if ("block_id" %in% colnames(results_combined)) {
      results_combined$block_id <- NULL
    }
    if ("is_overlap" %in% colnames(results_combined)) {
      results_combined$is_overlap <- NULL
    }

    # Remove duplicate features that may have been grouped in multiple blocks
    # Keep unique features based on FeaturesIDx or ID
    if ("FeaturesIDx" %in% colnames(results_combined)) {
      # Extract unique features based on their grouped IDs
      # Split the concatenated IDs and get unique groups
      results_combined <- results_combined[!duplicated(results_combined$FeaturesIDx), ]
    }

    # Re-order by M+H
    results_combined <- results_combined[order(results_combined$`M+H`), ]
    rownames(results_combined) <- 1:nrow(results_combined)

    message(paste("Parallel grouping completed.", nrow(results_combined), "features grouped."))

    return(results_combined)

  }, error = function(e) {
    warning(paste("Parallel grouping failed with error:", e$message))
    warning("Falling back to sequential Grouping.Between.Sample...")

    # Fallback to sequential processing
    X_clean <- X
    if ("block_id" %in% colnames(X_clean)) X_clean$block_id <- NULL
    if ("is_overlap" %in% colnames(X_clean)) X_clean$is_overlap <- NULL

    return(Grouping.Between.Sample(X = X_clean,
                                    ppm.tolerance = ppm.tolerance,
                                    mz.tolerance = mz.tolerance,
                                    rt.tolerance = rt.tolerance))
  })

  return(result)
}


########~~~~~~~~~~~~~~~~~~~~~~ Extract the reference map ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~########
###################################################################################################
#######~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

ExtractRefMap <-
  function(ref,
           peaksMassif,
           pheno_Data,
           minFract = 75,
           prefixID = "FT") {
    minFract <- minFract / 100
    
    withProgress(message = 'Generate reference map...', value = 0, {
      incProgress(1 / 3, detail = "in progress")
      
      ## Define necessary function
      FilterCutOff <- function(x, colSampleGroups, cutOff = minFract) {
        x <- as.data.frame(x)
        x[, colSampleGroups] <- as.character(x[, colSampleGroups])
        sampleGroupsOrigine <- x[, colSampleGroups]
        sampleGroups <- paste0("Group", x[, colSampleGroups])
        x[, colSampleGroups] <- sampleGroups
        sampleGroupNames <- unique(sampleGroups)
        sampleGroupTable <- table(sampleGroups)
        nSample <- nrow(x)
        nSampleGroups <- length(sampleGroupNames)
        
        for (i in sampleGroupNames) {
          x[i, ] <- NA
        }
        for (i in sampleGroupNames) {
          x[i, ] <-
            round(colSums(!is.na(x[-c((nSample + 1):(nSample + nSampleGroups)), ][x[-c((nSample +
                                                                                          1):(nSample + nSampleGroups)), colSampleGroups] == i, ])) / sampleGroupTable[i][[1]], 2)
        }
        
        x[-c((nSample + 1):(nSample + nSampleGroups)), colSampleGroups] <-
          sampleGroupsOrigine
        
        T_x <- as.data.frame(t(x))
        T_x[, sampleGroupNames] <-
          data.frame(apply(as.data.frame(T_x[, sampleGroupNames]), 2, as.numeric))
        
        T_x <- T_x %>%
          filter_at(sampleGroupNames, any_vars(. >= cutOff))
        
        x <- as.data.frame(t(T_x))
        x[, -1] <- data.frame(apply(x[, -1], 2, as.numeric))
        x <- x[1:nSample, -1]
        x <- t(x)
        return(x)
      }
      
      
      createID <- function(ref, number) {
        ID <-
          ID <-
          sprintf(paste0(ref, "%0", ceiling(log10(number + 1L)), "d"), 1L:number)
        return(ID)
      }
      
      ### Algorithme
      Matrix_used <- ref[, -c(10, 11)]
      
      for (i in pheno_Data$Filenames) {
        Matrix_used[, i] <- NA
      }
      
      withProgress(message = 'Compute intensity in each sample...', value = 0, {
        for (j in rownames(ref)) {
          incProgress(1 / length(rownames(ref)), detail = "in progress")
          
          peaksGroup <- peaksMassif[ref[j, ]$FeaturesIDx[[1]], ]
          for (s in colnames(Matrix_used)[10:ncol(Matrix_used)]) {
            idxSample <- which(peaksGroup$sample == s)
            
            if (length(idxSample) >= 1) {
              idxSampleChoice <-
                which(peaksGroup[idxSample, ]$Height == max(peaksGroup[idxSample, ]$Height))[1]
              Matrix_used[j, s] <-
                peaksGroup[idxSample, ][idxSampleChoice, ]$Height
            }
          }
          
          Matrix_used[j, ]$Height <-
            median(as.matrix(Matrix_used[j, 10:ncol(Matrix_used)]), na.rm = TRUE)
        }
        
      })
      
      
      incProgress(1 / 3, detail = "Saving data")
      
      Matrix_Abundancy <-
        rbind(Class = pheno_Data$Class, Matrix_used[, 10:ncol(Matrix_used)])
      
      Matrix_Abundancy_filter <-
        FilterCutOff(x = t(Matrix_Abundancy),
                     colSampleGroups = "Class")
      
      RefMap <-
        cbind(Matrix_used[rownames(Matrix_Abundancy_filter), 1:9], Matrix_Abundancy_filter)
      
      RefMap <- RefMap[order(RefMap[, "M+H"]), ] #new
      
      rownames(RefMap) <- createID(ref = prefixID, number = nrow(RefMap))
      
      incProgress(1 / 3, detail = "Finish")
      res <- list(RefMap = RefMap,
                  Matrix_Abundancy = as.matrix(RefMap[, c(c(1:2), c(10:ncol(RefMap)))]))
      
    })
    
    return(res = res)
  }

##~~~~~~~~~~~~~~~~~~~~ Function to preprocess the duplicates pepetide ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

ProcessDuplicates <- function(Refereance_Map) {
  library(dplyr)
  library(tidyverse)
  library(ggplot2)
  library(MsCoreUtils)
  
  AllCondition <- TRUE
  while (AllCondition) {
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ## Compute median mass and median iso mass link
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    
    withProgress(message = 'Computing median massif...', value = 0, {
      for (i in 1:nrow(Refereance_Map)) {
        incProgress(1 / nrow(Refereance_Map), detail = "")
        ###~~~~~~~~~~~~ Massif median ~~~~~~~~~~~~#
        TabGoup.Link.Info <-
          str_remove_all(Refereance_Map[i, ]$iso.mass.link, "\\*\\*\\*")
        TabGoup.Link.Info <-
          str_replace_all(TabGoup.Link.Info, "--->", ",")
        TabGoup.Link.Info <-
          as.numeric(unlist(str_split(TabGoup.Link.Info, pattern = ",")))
        
        
        TabGoup.Link.Info <- sort(TabGoup.Link.Info)
        
        massPeak.iso.mass.link <- c()
        
        while (length(TabGoup.Link.Info) != 0) {
          idxP <- which(abs(TabGoup.Link.Info - TabGoup.Link.Info[1]) <= 0.4)
          massPeak.iso.mass.link <-
            c(massPeak.iso.mass.link  ,
              median(TabGoup.Link.Info[idxP]))
          
          TabGoup.Link.Info <- TabGoup.Link.Info[-idxP]
        }
        
        
        Refereance_Map[i, ]$iso.mass.link <-
          toString(massPeak.iso.mass.link)
      }
      
    })
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    
    ##~~~~~~~~~~~~~~~~~~~~ Compute all mass peptide in gold mass median ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    withProgress(message = 'Computing median mass...', value = 0, {
      for (i in 1:nrow(Refereance_Map)) {
        incProgress(1 / nrow(Refereance_Map), detail = "")
        n_massif <-
          length(as.numeric(unlist(
            str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
          )))
        Refereance_Map[i, ]$`M+H` <-
          median(as.numeric(unlist(
            str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
          )) - c(0:(n_massif - 1)))
      }
    })
    
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    
    
    
    
    
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~First Grouping ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    rownames(Refereance_Map) <- 1:nrow(Refereance_Map)
    
    X_new <- Refereance_Map[1, ]
    X_new <- X_new[-1, ]
    
    
    niterj1 <- nrow(Refereance_Map)
    withProgress(message = 'Processing duplicates peptides...', value = 0, {
      while (nrow(Refereance_Map) >= 1) {
        incProgress(1 / niterj1, detail = "")
        # Order the data
        Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
        
        ## Select peptide which we can find duplicates
        X_iter <- Refereance_Map[1, ]
        
        # Matched rt
        idxMatchedRt <- which(abs(Refereance_Map$rt - X_iter$rt) <= 180)
        dataMatchedRt <- Refereance_Map[idxMatchedRt, ]
        
        #Matched mass
        idxMatchedMass <-
          idxMatchedRt[which(abs(dataMatchedRt$`M+H` - X_iter$`M+H`) <= 0.150)]
        
        ## Verify if peptide are duplicate or not and get data
        if (length(idxMatchedMass) == 1) {
          # Compute precise mass :
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ## Compute median mass and median iso mass link
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ###~~~~~~~~~~~~ Massif median ~~~~~~~~~~~~#
          TabGoup.Link.Info <-
            str_remove_all(X_iter[1, ]$iso.mass.link, "\\*\\*\\*")
          TabGoup.Link.Info <-
            str_replace_all(TabGoup.Link.Info, "--->", ",")
          TabGoup.Link.Info <-
            as.numeric(unlist(str_split(TabGoup.Link.Info, pattern = ",")))
          
          
          TabGoup.Link.Info <- sort(TabGoup.Link.Info)
          
          massPeak.iso.mass.link <- c()
          
          while (length(TabGoup.Link.Info) != 0) {
            idxP <- which(abs(TabGoup.Link.Info - TabGoup.Link.Info[1]) <= 0.4)
            massPeak.iso.mass.link <-
              c(massPeak.iso.mass.link  ,
                median(TabGoup.Link.Info[idxP]))
            
            TabGoup.Link.Info <- TabGoup.Link.Info[-idxP]
            
          }
          
          
          X_iter[1, ]$iso.mass.link <-
            toString(massPeak.iso.mass.link)
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          
          ##~~~~~~~~~~~~~~~~~~~~ Compute all mass peptide in gold mass median ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          n_massif <-
            length(as.numeric(unlist(
              str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
            )))
          X_iter[1, ]$`M+H` <-
            median(as.numeric(unlist(
              str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
            )) - c(0:(n_massif - 1)))
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          
          
          X_new <- rbind(X_new, X_iter)
          Refereance_Map <- Refereance_Map[-idxMatchedMass, ]
        } else {
          # Compute intensity nsamples
          for (j in 10:(ncol(Refereance_Map))) {
            if (all(is.na(Refereance_Map[idxMatchedMass, j]))) {
              X_iter[1, j] <- NA
            } else{
              X_iter[1, j] <- max(Refereance_Map[idxMatchedMass, j], na.rm = TRUE)
            }
            
          }
          
          
          #~~~~~~~~~~~~~~~~~~~~~~ process massif ~~~~~~~~~~~~~#
          #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          
          #~~~~~~~~~~~~ Grouping info~~~~~~~~~~~~~~~#
          # iso mass
          X_iter[1, ]$iso.mass <-
            str_c(Refereance_Map[idxMatchedMass, ]$iso.mass,
                  sep = "--->",
                  collapse = "--->")
          
          # iso mass link
          X_iter[1, ]$iso.mass.link <-
            str_c(Refereance_Map[idxMatchedMass, ]$iso.mass.link,
                  sep = "--->",
                  collapse = "--->")
          
          # rt_GroupSample_Adjust
          X_iter[1, ]$rt_GroupSample_Adjust <-
            str_c(
              Refereance_Map[idxMatchedMass, ]$rt_GroupSample_Adjust,
              sep = "--->",
              collapse = "--->"
            )
          
          # mz_PeaksIsotopics_Group
          X_iter[1, ]$mz_PeaksIsotopics_Group <-
            str_c(
              Refereance_Map[idxMatchedMass, ]$mz_PeaksIsotopics_Group,
              sep = "--->",
              collapse = "--->"
            )
          
          # rt_PeaksIsotopics_Group
          X_iter[1, ]$rt_PeaksIsotopics_Group <-
            str_c(
              Refereance_Map[idxMatchedMass, ]$rt_PeaksIsotopics_Group,
              sep = "--->",
              collapse = "--->"
            )
          
          # Height_PeaksIsotopics_Group
          X_iter[1, ]$Height_PeaksIsotopics_Group <-
            str_c(
              Refereance_Map[idxMatchedMass, ]$Height_PeaksIsotopics_Group,
              sep = "--->",
              collapse = "--->"
            )
          
          ## Compute Intensity
          X_iter[1, ]$Height <-
            median(as.numeric(X_iter[1, 10:(ncol(X_iter))]), na.rm = TRUE)
          
          
          ## compute median rt time
          
          X_iter[1, ]$rt <-
            median(as.numeric(unlist(
              str_split(X_iter[1, ]$rt_GroupSample_Adjust,
                        pattern = "--->")
            )))
          
          
          # Compute precise mass :
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ## Compute median mass and median iso mass link
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ###~~~~~~~~~~~~ Massif median ~~~~~~~~~~~~#
          TabGoup.Link.Info <-
            str_remove_all(X_iter[1, ]$iso.mass.link, "\\*\\*\\*")
          TabGoup.Link.Info <-
            str_replace_all(TabGoup.Link.Info, "--->", ",")
          TabGoup.Link.Info <-
            as.numeric(unlist(str_split(TabGoup.Link.Info, pattern = ",")))
          
          
          TabGoup.Link.Info <- sort(TabGoup.Link.Info)
          
          massPeak.iso.mass.link <- c()
          
          while (length(TabGoup.Link.Info) != 0) {
            idxP <- which(abs(TabGoup.Link.Info - TabGoup.Link.Info[1]) <= 0.4)
            massPeak.iso.mass.link <-
              c(massPeak.iso.mass.link  ,
                median(TabGoup.Link.Info[idxP]))
            
            TabGoup.Link.Info <- TabGoup.Link.Info[-idxP]
            
          }
          
          
          X_iter[1, ]$iso.mass.link <-
            toString(massPeak.iso.mass.link)
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          
          ##~~~~~~~~~~~~~~~~~~~~ Compute all mass peptide in gold mass median ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          n_massif <-
            length(as.numeric(unlist(
              str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
            )))
          X_iter[1, ]$`M+H` <-
            median(as.numeric(unlist(
              str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
            )) - c(0:(n_massif - 1)))
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
          
          
          
          X_new <- rbind(X_new, X_iter)
          Refereance_Map <- Refereance_Map[-idxMatchedMass, ]
          
        }
        
      }
      Refereance_Map <- X_new
      
      Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
      
      rownames(Refereance_Map) <- 1:nrow(Refereance_Map)
      
      
      
      ## For to repeat the process
      # Order the data
      Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
      
      
      
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
      ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
    })
    
    
    
    
    ####################################################################################################################
    
    ####################################################################################################################
    
    ################################# Duplicate Massif in sthe reference map ###########################################
    
    ####################################################################################################################
    
    ####################################################################################################################
    
    mz.tolerance <- 0.150
    ppm.tolerance <- 0
    
    # idxAll<-1:nrow(Refereance_Map)
    #
    # Refereance_Map_process<-Refereance_Map %>%
    #   dplyr::mutate(diff_MH = c(2*2,diff(`M+H`)),
    #                 diff_rt = c(180*2,abs(diff(rt))))
    #
    # idxDiffRt<-which((Refereance_Map_process$diff_MH<=2) &
    #                    Refereance_Map_process$diff_rt<=180)
    
    
    
    rownames(Refereance_Map) <- 1:nrow(Refereance_Map)
    
    X_new <- Refereance_Map[1, ]
    X_new <- X_new[-1, ]
    
    
    niterj2 <- nrow(Refereance_Map)
    withProgress(message = 'Processing duplicates peptides...', value = 0, {
      while (nrow(Refereance_Map) >= 1) {
        incProgress(1 / niterj2, detail = "")
        # Order the data
        Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
        
        ## Select peptide which we can find duplicates
        X_iter <- Refereance_Map[1, ]
        
        # Matched rt
        idxMatchedRt <- which(abs(Refereance_Map$rt - X_iter$rt) <= 180)
        
        dataMatchedRt <- Refereance_Map[idxMatchedRt, ]
        
        #Matched mass
        idxMatchedMass_Candidat <-
          idxMatchedRt[which(abs(dataMatchedRt$`M+H` - X_iter$`M+H`) <= 5)]
        
        if (length(idxMatchedMass_Candidat) == 1) {
          # peptide has not duplicate massif
          X_new <- rbind(X_new, X_iter)
          Refereance_Map <- Refereance_Map[-idxMatchedMass_Candidat, ]
        } else{
          idxMatched <- c()
          for (i in idxMatchedMass_Candidat) {
            ## Verify if duplicate in idxDiffRt
            
            N_Ref_Massif <-
              length(unique(sort(as.numeric(
                unlist(
                  str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                )
              ))))
            N_Candidate_Massif <-
              length(unique(sort(as.numeric(
                unlist(
                  str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                )
              ))))
            
            if (N_Candidate_Massif == 2 | N_Candidate_Massif == 3) {
              if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  ))),
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif > 3) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              }
              
              
            } else if (N_Candidate_Massif == 4 |
                       N_Candidate_Massif == 5) {
              if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  ))),
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif  == 4) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif > 4) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:4],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              }
            } else if (N_Candidate_Massif == 6 |
                       N_Candidate_Massif == 7) {
              if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  ))),
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif  == 4) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif == 5) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:4],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif > 5) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:4],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:5],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              }
              
            } else if (N_Candidate_Massif >= 8) {
              if (N_Ref_Massif == 2 | N_Ref_Massif == 3) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  ))),
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif  == 4) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:2],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif  == 5) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:3],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:4],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif == 6) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:4],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:5],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              } else if (N_Ref_Massif > 6) {
                massifMatched <- MsCoreUtils::closest(
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[i, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:5],
                  unique(sort(as.numeric(
                    unlist(
                      str_split(Refereance_Map[1, ]$iso.mass.link, pattern = ",")
                    )
                  )))[1:6],
                  tolerance = mz.tolerance,
                  ppm = ppm.tolerance,
                  duplicates = "closest"
                )
                massifMatchedBool <- is.element(NA, massifMatched)
              }
            }
            
            
            # Verify if massif matched
            if (!massifMatchedBool) {
              idxMatched <- c(idxMatched, i)
              
            }
            
          }
          
          if (length(idxMatched) > 1) {
            # Compute intensity nsamples
            for (j in 10:(ncol(Refereance_Map))) {
              if (all(is.na(Refereance_Map[idxMatched, j]))) {
                X_iter[1, j] <- NA
              } else{
                X_iter[1, j] <- max(Refereance_Map[idxMatched, j], na.rm = TRUE)
              }
              
            }
            
            
            #~~~~~~~~~~~~~~~~~~~~~~ process massif ~~~~~~~~~~~~~#
            #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            #~~~~~~~~~~~~ Grouping info~~~~~~~~~~~~~~~#
            # iso mass
            X_iter[1, ]$iso.mass <-
              str_c(Refereance_Map[idxMatched, ]$iso.mass,
                    sep = "--->",
                    collapse = "--->")
            
            # iso mass link
            X_iter[1, ]$iso.mass.link <-
              str_c(Refereance_Map[idxMatched, ]$iso.mass.link,
                    sep = "--->",
                    collapse = "--->")
            
            # rt_GroupSample_Adjust
            X_iter[1, ]$rt_GroupSample_Adjust <-
              str_c(
                Refereance_Map[idxMatched, ]$rt_GroupSample_Adjust,
                sep = "--->",
                collapse = "--->"
              )
            
            # mz_PeaksIsotopics_Group
            X_iter[1, ]$mz_PeaksIsotopics_Group <-
              str_c(
                Refereance_Map[idxMatched, ]$mz_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            # rt_PeaksIsotopics_Group
            X_iter[1, ]$rt_PeaksIsotopics_Group <-
              str_c(
                Refereance_Map[idxMatched, ]$rt_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            # Height_PeaksIsotopics_Group
            X_iter[1, ]$Height_PeaksIsotopics_Group <-
              str_c(
                Refereance_Map[idxMatched, ]$Height_PeaksIsotopics_Group,
                sep = "--->",
                collapse = "--->"
              )
            
            ## Compute Intensity
            X_iter[1, ]$Height <-
              median(as.numeric(X_iter[1, 10:(ncol(X_iter))]), na.rm = TRUE)
            
            
            ## compute median rt time
            
            X_iter[1, ]$rt <-
              median(as.numeric(unlist(
                str_split(X_iter[1, ]$rt_GroupSample_Adjust,
                          pattern = "--->")
              )))
            
            
            # Compute precise mass :
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ## Compute median mass and median iso mass link
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ###~~~~~~~~~~~~ Massif median ~~~~~~~~~~~~#
            TabGoup.Link.Info <-
              str_remove_all(X_iter[1, ]$iso.mass.link, "\\*\\*\\*")
            TabGoup.Link.Info <-
              str_replace_all(TabGoup.Link.Info, "--->", ",")
            TabGoup.Link.Info <-
              as.numeric(unlist(str_split(TabGoup.Link.Info, pattern = ",")))
            
            
            TabGoup.Link.Info <- sort(TabGoup.Link.Info)
            
            massPeak.iso.mass.link <- c()
            
            while (length(TabGoup.Link.Info) != 0) {
              idxP <- which(abs(TabGoup.Link.Info - TabGoup.Link.Info[1]) <= 0.4)
              massPeak.iso.mass.link <-
                c(massPeak.iso.mass.link  ,
                  median(TabGoup.Link.Info[idxP]))
              
              TabGoup.Link.Info <- TabGoup.Link.Info[-idxP]
              
            }
            
            
            X_iter[1, ]$iso.mass.link <-
              toString(massPeak.iso.mass.link)
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            ##~~~~~~~~~~~~~~~~~~~~ Compute all mass peptide in gold mass median ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            n_massif <-
              length(as.numeric(unlist(
                str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
              )))
            X_iter[1, ]$`M+H` <-
              median(as.numeric(unlist(
                str_split(X_iter[1, ]$iso.mass.link, pattern = ",")
              )) - c(0:(n_massif - 1)))
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
            
            
            
            
            X_new <- rbind(X_new, X_iter)
            Refereance_Map <- Refereance_Map[-idxMatched, ]
            
          } else {
            X_new <- rbind(X_new, X_iter)
            Refereance_Map <- Refereance_Map[-idxMatched, ]
          }
          
          
        }
        
        
        
      }
      
      Refereance_Map <- X_new
      
      Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
      
      rownames(Refereance_Map) <- 1:nrow(Refereance_Map)
      
      # Order the data
      Refereance_Map <- Refereance_Map[order(Refereance_Map$`M+H`), ]
    })
    
    
    
    ##~~~~~~~~~~~~~~~~ Check again the process~~~~~~~~~~~~~~~~#
    
    
    ## Select peptide which we can find duplicates
    withProgress(message = 'Checking duplicates peptides again...', value = 0, {
      for (i in 1:nrow(Refereance_Map)) {
        incProgress(1 / nrow(Refereance_Map), detail = "")
        
        X_iter <- Refereance_Map[i, ]
        # Matched rt
        idxMatchedRt <- which(abs(Refereance_Map$rt - X_iter$rt) <= 180)
        dataMatchedRt <- Refereance_Map[idxMatchedRt, ]
        
        #Matched mass
        idxMatchedMass <-
          idxMatchedRt[which(abs(dataMatchedRt$`M+H` - X_iter$`M+H`) <= 0.150)]
        
        if ((length(idxMatchedMass) > 1)) {
          break
        }
      }
    })
    
    
    
    if (length(idxMatchedMass) == 1) {
      AllCondition <- FALSE
    } else {
      AllCondition <- TRUE
    }
    
    
  }
  
  return(Refereance_Map)
  
}
