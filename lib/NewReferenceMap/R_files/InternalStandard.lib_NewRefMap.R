library(dplyr)
library(ggplot2)
library(combinat)
library(doParallel)
library(foreach)
library(itertools)


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

## Function to filter samples do not contains p% of features (deletes bad samples)
FilterMatrixAbundance<-function(X, p){
  "%ni%"<-Negate("%in%")
  idxCol<-which(colSums(!is.na(X))*100/nrow(X)>=p)
  if(length(idxCol)<2){
    #stop("\n The abodance matrix must have at least 2 columns! set the 'p' parameter to 0.")
    
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = HTML("The abodance matrix must have at least 2 columns! <br/>
                  Please decrease the value of the parameter 'Min features'., <br/>"),
      type = "warning",
      html = TRUE
    )
    
    ### Enable some buttons when prepossessing start
    shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Peak detection"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Generate the reference map"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
    
    enable("id_InternalStandardsParametersPanel")
    enable("IdentifyNormalizers")
    enable("ValidRefrenceMap")
    enable("PreviousPageGenerateRefMap")
    
    req(NULL)
    
  } else {
    
    idx_All<-1:ncol(X)
    X_filter<-X[,idxCol]
    samplesExcluded<-idx_All[idx_All %ni% idxCol]
    samplesSelected<-idxCol
    message(paste("\n ",ncol(X)-length(idxCol), " samples excluded... and ",length(idxCol), " samples selected"))
    
    return(list(X_filter = X_filter,
                samplesExcluded = samplesExcluded,
                samplesSelected = samplesSelected))
  }
  
}


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
### Function normalize matrix and 
### Computes variability after normalization, number of sample normalized and number median of normalizers in samples 
calculate_Variability <- function(X, # Matrix to normalized
                                  ref,
                                  iset.ref,
                                  min.iset,
                                  span=0.75,
                                  extrap=TRUE,
                                  cutrat = 2,
                                  method = c("lm","loess","kreg"),
                                  plot.model = FALSE,
                                  out.scale=c("log2", "natural")){
  
  if (is.vector(X))
    X <- as.matrix(X)
  
  
  
  # Data must be logged
  if (max(X, na.rm = TRUE) > 107) { # How possible it is to have intensity>1e+32
    log.scaled <- FALSE
    #X <- remove.zeros(X,strategy=replace.zero)
    X <- log2(X)
  } else log.scaled <- TRUE
  
  if (missing(ref)) 
    ref <- apply(X,1,function(x) median(x, na.rm = TRUE))
  
  if(max(ref, na.rm = TRUE)>107)
    ref<-log2(ref)
  
  
  method <- tolower(method[1])
  out.scale<-tolower(out.scale[1])
  
  iset.i<-list()
  adj.r.squared<-c()
  idxSampleNormalized<-NULL
  Xn <- matrix(NA,nrow(X),ncol(X))
  rownames(Xn)<-rownames(X)
  colnames(Xn)<-colnames(X)
  
  layout(matrix(1:15, ncol=3, byrow = TRUE))
  par(mar=c(5,5,2,1))
  
  
  if(ncol(X)>1) {
    
    
    for (i in 1:ncol(X)) {
      
      #iset.ref<-names(ref)
      
      if (!is.null(cutrat))
        iset <- iset.ref[which(abs(X[iset.ref,i]-ref[iset.ref])<=cutrat)]
      else iset<-iset.ref
      
      
      if(method == "lm") {
        
        idx_No_NA<-names(X[,i][!is.na(X[,i])])
        iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
        
        if(length(iset_No_NA)>=min.iset) {
          a <- X[iset_No_NA,i]
          m <- ref[iset_No_NA]
          
          
          model_lm<-lm(m~a)
          
          pred <- model_lm$coefficients[1]+model_lm$coefficients[2]*X[idx_No_NA,i]
          
          
          
          Xn[idx_No_NA,i] <-pred
          idxSampleNormalized<-c(idxSampleNormalized,i)
          iset.i[[i]]<-iset_No_NA
          adj.r.squared[i]<-summary(model_lm)$adj.r.squared
          
          
          if(plot.model == TRUE){
            plot(a,m, pch = 16, main = "Model")
            abline(model_lm, col = "green", lwd = 3)
            
            plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before")
            abline(coef = c(0,1), col = "blue", lwd = 3)
            
            plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
            abline(coef = c(0,1), col = "red", lwd = 3)
          }
          
        } else {
          Xn[idx_No_NA,i] <-X[idx_No_NA,i]
          iset.i[[i]]<-iset_No_NA
          
          # if(is.null(iset_No_NA))
          #   iset.i[[i]]<-0
          
          
          adj.r.squared[i]<-0
          
          if(plot.model == TRUE){
            if(length(iset_No_NA)>1) {
              plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
              
            } else {
              plot(0,0, pch = 16)
            }
          }
          
        }
        
        
        
      } else if (method == "kreg"){
        
        idx_No_NA<-names(X[,i][!is.na(X[,i])])
        iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
        
        
        if(length(iset_No_NA)>=min.iset) {
          
          
          a <- X[iset_No_NA,i]
          m <- ref[iset_No_NA]
          
          
          
          
          data_model<-data.frame(a = a, m = m)
          # fit the models using normalizers
          # bw <- npregbw(formula=m~a)
          
          model.np<-npreg(m ~ a,
                          bws = 15,
                          bwtype = c("fixed","generalized_nn","adaptive_nn")[1],
                          regtype = "ll",
                          ckertype = "gaussian",
                          #bwmethod = "cv.aic",
                          gradients = TRUE,
                          data = data_model)
          
          
          
          pred<-predict(model.np, newdata = data.frame(a = X[idx_No_NA,i]))
          
          ### Calibrated intensity
          Xn[idx_No_NA,i] <-pred
          
          idxSampleNormalized<-c(idxSampleNormalized,i)
          iset.i[[i]]<-iset_No_NA
          
          
          predict_data_model.np<-data.frame(a = a, m = predict(model.np, newdata = data.frame(a = a)))
          
          if(plot.model){
            plot(a,m, pch = 16, main = "Model")
            lines(predict_data_model.np$a, 
                  predict_data_model.np$m
                  , col = "red", lwd = 2)
            
            plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before" ) 
            abline(coef = c(0,1), col = "blue", lwd = 3)
            
            plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
            abline(coef = c(0,1), col = "green", lwd = 3)
          }
          
        } else {
          Xn[idx_No_NA,i] <-X[idx_No_NA,i]
          iset.i[[i]]<-iset_No_NA
          
          # if(is.null(iset_No_NA))
          #   iset.i[[i]]<-0
          
          if(plot.model == TRUE){
            if(length(iset_No_NA)>1) {
              plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
              
            } else {
              plot(0,0, pch = 16)
            }
          }
          
        }
        
      }else if (method == "loess"){
        
        idx_No_NA<-names(X[,i][!is.na(X[,i])])
        iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
        
        if(length(iset_No_NA)>=min.iset) {
          a <- X[iset_No_NA,i]
          m <- ref[iset_No_NA]
          
          
          #lc <- lowess(m ~ a,f=span)
          #pred <- extrap1(lc$x,lc$y,xo=X[idx_No_NA,i],extrap=extrap, method = "nearest")
          model_loess<-loess(m ~ a,data.frame(a=a,m=m),span=span, 
                             degree=1,family="symmetric")
          pred <- predict(model_loess,newdata=X[idx_No_NA,i])
          m_predict<-predict(model_loess,newdata=a)
          
          
          
          Xn[idx_No_NA,i] <-pred
          idxSampleNormalized<-c(idxSampleNormalized,i)
          iset.i[[i]]<-iset_No_NA
          
          if(plot.model == TRUE){
            plot(a,m, pch = 16)
            lines(a,m_predict, col = "red", lwd = 3)
            #lines(lc$x,lc$y, col = "red", lwd = 3)
          }
          
        } else {
          
          Xn[idx_No_NA,i] <-X[idx_No_NA,i]
          iset.i[[i]]<-iset_No_NA
          
          # if(is.null(iset_No_NA))
          #   iset.i[[i]]<-0
          
          
          if(plot.model == TRUE){
            if(length(iset_No_NA)>1) {
              plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
              
            } else {
              plot(0,0, pch = 16)
            }
          }
          
        }
        
        
      } else stop("method must be \"lm\" or \"loess\" or \"kreg\"")
    }
    
    
    
  }
  
  
  
  
  if(method == "lm") {
    names(adj.r.squared)<-colnames(Xn)
    attr(Xn, "adj.r.squared")<-adj.r.squared
  }
  
  if(!is.null(dim(Xn[,idxSampleNormalized]))){
    w.metric<- mad(apply(Xn[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE);
    w.metric.before <- mad(apply(X[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE)
    
    
    
  } else{
    
    w.metric<-NA
    w.metric.before<-NA
  }
  
  
  
  # attr(Xn,"w.metric")<-w.metric
  # names(iset.i)<-colnames(Xn)
  
  
  
  attr(Xn,"nbr_pep_normalizers")<-lapply(iset.i, length)
  # names(attr(Xn,"nbr_pep_normalizers"))<-colnames(Xn)
  # 
  # print(attr(Xn,"nbr_pep_normalizers"))
  
  
  
  attr(Xn,"idX_normalizers")<-iset.i
  
  
  if(method == "lm") {
    
    adj.r.squared<-attr(Xn,"adj.r.squared")
    
    if(plot.model==TRUE){
      
      #output$adj_r_squared<-renderPlot({
      plot(adj.r.squared, cex.axis = 1.5, cex.lab = 1.5)
      lines(adj.r.squared, lwd = 3, col = "blue", ylim = c(min(adj.r.squared), 
                                                           max(adj.r.squared)))
      # })
    }
  }
  
  
  
  
  # return(round(w.metric,3))
  
  return(list(w.metric = w.metric,
              nidxSampleNormalized = length(idxSampleNormalized),
              nbr_pep_normalizers = median(unlist(attr(Xn,"nbr_pep_normalizers")))
  ))
}


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#Function to normalize sample(s)
normalizeSamples <- function(X, # Matrix to normalized
                             ref,
                             iset.ref,
                             min.iset,
                             span=0.75,
                             extrap=TRUE,
                             cutrat = 2,
                             method = c("lm","loess","kreg"),
                             plot.model = FALSE,
                             out.scale=c("log2", "natural")){
  if (is.vector(X))
    X <- as.matrix(X)
  
  
  
  # Data must be logged
  if (max(X, na.rm = TRUE) > 107) { # How possible it is to have intensity>1e+32
    log.scaled <- FALSE
    #X <- remove.zeros(X,strategy=replace.zero)
    X <- log2(X)
  } else log.scaled <- TRUE
  
  if (missing(ref)) 
    ref <- apply(X,1,function(x) median(x, na.rm = TRUE))
  
  if(max(ref, na.rm = TRUE)>107)
    ref<-log2(ref)
  
  
  method <- tolower(method[1])
  out.scale<-tolower(out.scale[1])
  
  iset.i<-list()
  adj.r.squared<-c()
  idxSampleNormalized<-NULL
  Xn <- matrix(NA,nrow(X),ncol(X))
  rownames(Xn)<-rownames(X)
  colnames(Xn)<-colnames(X)
  
  layout(matrix(1:15, ncol=3, byrow = TRUE))
  par(mar=c(5,5,2,1))
  
  
  if(ncol(X)>1) {
    withProgress(message = 'Normalizing matrix abundance...', value = 0, {
      
      for (i in 1:ncol(X)) {
        
        incProgress(1/ncol(X), detail = "")
        
        #iset.ref<-names(ref)
        
        if (!is.null(cutrat))
          iset <- iset.ref[which(abs(X[iset.ref,i]-ref[iset.ref])<=cutrat)]
        else iset<-iset.ref
        
        
        if(method == "lm") {
          
          idx_No_NA<-names(X[,i][!is.na(X[,i])])
          iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
          
          if(length(iset_No_NA)>=min.iset) {
            a <- X[iset_No_NA,i]
            m <- ref[iset_No_NA]
            
            
            model_lm<-lm(m~a)
            
            pred <- model_lm$coefficients[1]+model_lm$coefficients[2]*X[idx_No_NA,i]
            
            
            
            Xn[idx_No_NA,i] <-pred
            idxSampleNormalized<-c(idxSampleNormalized,i)
            iset.i[[i]]<-iset_No_NA
            adj.r.squared[i]<-summary(model_lm)$adj.r.squared
            
            
            if(plot.model == TRUE){
              plot(a,m, pch = 16, main = "Model")
              abline(model_lm, col = "green", lwd = 3)
              
              plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before")
              abline(coef = c(0,1), col = "blue", lwd = 3)
              
              plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
              abline(coef = c(0,1), col = "red", lwd = 3)
            }
            
          } else {
            Xn[idx_No_NA,i] <-X[idx_No_NA,i]
            iset.i[[i]]<-iset_No_NA
            
            # if(is.null(iset_No_NA))
            #   iset.i[[i]]<-0
            
            
            adj.r.squared[i]<-0
            
            if(plot.model == TRUE){
              if(length(iset_No_NA)>1) {
                plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                
              } else {
                plot(0,0, pch = 16)
              }
            }
            
          }
          
          
          
        } else if (method == "kreg"){
          
          idx_No_NA<-names(X[,i][!is.na(X[,i])])
          iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
          
          
          if(length(iset_No_NA)>=min.iset) {
            
            
            a <- X[iset_No_NA,i]
            m <- ref[iset_No_NA]
            
            
            
            
            data_model<-data.frame(a = a, m = m)
            # fit the models using normalizers
            # bw <- npregbw(formula=m~a)
            
            model.np<-npreg(m ~ a,
                            bws = 15,
                            bwtype = c("fixed","generalized_nn","adaptive_nn")[1],
                            regtype = "ll",
                            ckertype = "gaussian",
                            #bwmethod = "cv.aic",
                            gradients = TRUE,
                            data = data_model)
            
            
            
            pred<-predict(model.np, newdata = data.frame(a = X[idx_No_NA,i]))
            
            ### Calibrated intensity
            Xn[idx_No_NA,i] <-pred
            
            idxSampleNormalized<-c(idxSampleNormalized,i)
            iset.i[[i]]<-iset_No_NA
            
            
            predict_data_model.np<-data.frame(a = a, m = predict(model.np, newdata = data.frame(a = a)))
            
            if(plot.model){
              plot(a,m, pch = 16, main = "Model")
              lines(predict_data_model.np$a, 
                    predict_data_model.np$m
                    , col = "red", lwd = 2)
              
              plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before" ) 
              abline(coef = c(0,1), col = "blue", lwd = 3)
              
              plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
              abline(coef = c(0,1), col = "green", lwd = 3)
            }
            
          } else {
            Xn[idx_No_NA,i] <-X[idx_No_NA,i]
            iset.i[[i]]<-iset_No_NA
            
            # if(is.null(iset_No_NA))
            #   iset.i[[i]]<-0
            
            if(plot.model == TRUE){
              if(length(iset_No_NA)>1) {
                plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                
              } else {
                plot(0,0, pch = 16)
              }
            }
            
          }
          
        }else if (method == "loess"){
          
          idx_No_NA<-names(X[,i][!is.na(X[,i])])
          iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
          
          if(length(iset_No_NA)>=min.iset) {
            a <- X[iset_No_NA,i]
            m <- ref[iset_No_NA]
            
            
            #lc <- lowess(m ~ a,f=span)
            #pred <- extrap1(lc$x,lc$y,xo=X[idx_No_NA,i],extrap=extrap, method = "nearest")
            model_loess<-loess(m ~ a,data.frame(a=a,m=m),span=span, 
                               degree=1,family="symmetric")
            pred <- predict(model_loess,newdata=X[idx_No_NA,i])
            m_predict<-predict(model_loess,newdata=a)
            
            
            
            Xn[idx_No_NA,i] <-pred
            idxSampleNormalized<-c(idxSampleNormalized,i)
            iset.i[[i]]<-iset_No_NA
            
            if(plot.model == TRUE){
              plot(a,m, pch = 16)
              lines(a,m_predict, col = "red", lwd = 3)
              #lines(lc$x,lc$y, col = "red", lwd = 3)
            }
            
          } else {
            
            Xn[idx_No_NA,i] <-X[idx_No_NA,i]
            iset.i[[i]]<-iset_No_NA
            
            # if(is.null(iset_No_NA))
            #   iset.i[[i]]<-0
            
            
            if(plot.model == TRUE){
              if(length(iset_No_NA)>1) {
                plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                
              } else {
                plot(0,0, pch = 16)
              }
            }
            
          }
          
          
        } else stop("method must be \"lm\" or \"loess\" or \"kreg\"")
      }
    })
    
    
  }
  
  
  
  
  if(method == "lm") {
    names(adj.r.squared)<-colnames(Xn)
    attr(Xn, "adj.r.squared")<-adj.r.squared
  }
  
  if(!is.null(dim(Xn[,idxSampleNormalized]))){
    w.metric<- mad(apply(Xn[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE);
    w.metric.before <- mad(apply(X[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE)
    
    
    
  } else{
    
    w.metric<-NA
    w.metric.before<-NA
  }
  
  
  
  attr(Xn,"w.metric")<-w.metric
  names(iset.i)<-colnames(Xn)
  
  attr(Xn,"nbr_pep_normalizers")<-lapply(iset.i, length)
  names(attr(Xn,"nbr_pep_normalizers"))<-colnames(Xn)
  
  print(attr(Xn,"nbr_pep_normalizers"))
  
  
  
  attr(Xn,"idX_normalizers")<-iset.i
  
  
  if(method == "lm") {
    
    adj.r.squared<-attr(Xn,"adj.r.squared")
    
    if(plot.model==TRUE){
      
      #output$adj_r_squared<-renderPlot({
      plot(adj.r.squared, cex.axis = 1.5, cex.lab = 1.5)
      lines(adj.r.squared, lwd = 3, col = "blue", ylim = c(min(adj.r.squared), 
                                                           max(adj.r.squared)))
      # })
    }
  }
  
  
  
  
  
  # X_save<-Xn[,idxSampleNormalized]
  # attr(X_save,"idX_normalizers")<-iset.i[idxSampleNormalized]
  # # Convert back to original form
  # if (!log.scaled && out.scale=="log2")
  #   return(Xn)
  # else if (!log.scaled && out.scale=="natural")
  #   return(2^Xn)
  # else if (log.scaled && out.scale=="natural")
  #   return(2^Xn)
  # else
  #   return(Xn)
  
  X_before_Normalizers<-X[,idxSampleNormalized]
  X_save<-Xn[,idxSampleNormalized]
  
  attr(X_save,"w.metric")<-w.metric
  attr(X_before_Normalizers,"w.metric.before")<-w.metric.before
  
  # # Convert back to original form
  # if (!log.scaled && out.scale=="log2")
  #   return(X_save)
  # else if (!log.scaled && out.scale=="natural")
  #   return(2^X_save)
  # else if (log.scaled && out.scale=="natural")
  #   return(2^X_save)
  # else
  #   return(X_save)
  
  # Convert back to original form
  if (!log.scaled && out.scale=="log2")
    X_save<-X_save
  else if (!log.scaled && out.scale=="natural")
    X_save<-2^X_save
  else if (log.scaled && out.scale=="natural")
    X_save<-2^X_save
  else
    X_save<-X_save
  
  #return(round(w.metric,3))
  
  
  return(list(X_save = X_save, 
              X_before_Normalizers = X_before_Normalizers))
  
}



###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#Function to search a set of normalizers stable by ratio

normalizers_StableRatio<-function(Matrix, 
                                  pFeatures = 10,
                                  pSample = 50){
  
  # Data must be logged
  if (max(Matrix, na.rm = TRUE) > 107) { # How possible it is to have intensity>1e+32
    log.scaled <- FALSE
    Matrix <- log2(Matrix)
  } else log.scaled <- TRUE
  
  
  ## Filter sample
  res_filter<-FilterMatrixAbundance(X = Matrix, p = pFeatures)
  
  Matrix_filter<-res_filter$X_filter
  
  #Convert matrix to list
  Matrix_list<-as.list(Matrix_filter)
  
  withProgress(message = 'Convert matrix to list', value = 0, {
    for (i in 1:length(Matrix_list)) {
      
      incProgress(1/length(Matrix_list), detail = paste(round(i/length(Matrix_list)*100,0),"%..."))
      names(Matrix_list[[i]])<-rownames(Matrix_filter)
    }
    
  })
  
  ## Extract Features by sample
  features_bySample_list<-list()
  
  withProgress(message = 'Extract Features by sample', value = 0, {
    for (i in 1:length(Matrix_list)) {
      incProgress(1/length(Matrix_list), detail = paste(round(i/length(Matrix_list)*100,0),"%..."))
      
      features_bySample_list[[i]]<-Matrix_list[[i]][!is.na(Matrix_list[[i]])]
      
      
    }
  })
  names(features_bySample_list)<-names(Matrix_list)
  
  
  ### Compute all ratios 
  
  features_Ratio_bySample<-list()
  
  all_features_finded<-c()
  message("Compute all ratios :")
  
  pb_ratio <- txtProgressBar(min=1, max = length(features_bySample_list), style = 3)
  withProgress(message = 'Compute all ratios', value = 0, {
    for (i in 1:length(features_bySample_list)) {
      incProgress(1/length(features_bySample_list), detail = paste(round(i/length(features_bySample_list)*100,0),"%..."))
      setTxtProgressBar(pb_ratio, i)
      combin<-combn(features_bySample_list[[i]],2)
      combin_name<-combn(names(features_bySample_list[[i]]),2)
      names_ratio<-paste(combin_name[1,], combin_name[2,], sep = "/")
      
      all_features_finded<-c(all_features_finded,names_ratio)
      
      combin_ratio<-combin[1,]/combin[2,]
      
      names(combin_ratio)<-names_ratio
      
      features_Ratio_bySample[[i]]<-combin_ratio
    }
    
    close(pb_ratio)
  })
  names(features_Ratio_bySample)<-names(features_bySample_list)
  
  message("Generate the ratio matrix : ")
  
  ### Couple filter not present enough in the samples.
  frequence_features_BySample<-table(all_features_finded)*100/length(features_bySample_list)
  
  selected_features_ratio<-frequence_features_BySample[frequence_features_BySample>=pSample]
  
  
  
  if(length(selected_features_ratio)<10){
    
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = HTML("Number of potential normalizer too low < 10! <br/>
                  Please decrease the value of the parameter 'Min sample', <br/>"),
      type = "warning",
      width = "50%",
      html = TRUE
    )
    
    ### Enable some buttons when prepossessing start
    shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Peak detection"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Generate the reference map"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
    shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
    
    enable("id_InternalStandardsParametersPanel")
    enable("IdentifyNormalizers")
    enable("ValidRefrenceMap")
    enable("PreviousPageGenerateRefMap")
    
    
    req(NULL)
    
  } else{
    
    ## Generate the ratio matrix
    
    
    Matrix_ratio<-matrix(NA_integer_,nrow = length(selected_features_ratio), ncol = length(features_bySample_list))
    
    names_features_ratio_selected<-rownames(Matrix_ratio)<-names(selected_features_ratio)
    colnames(Matrix_ratio)<-names(features_bySample_list)
    
    pb_1 <- txtProgressBar(min=1, max = length(features_Ratio_bySample), style = 3)
    withProgress(message = 'Generate the ratio matrix', value = 0, {
      for (i in 1:length(features_Ratio_bySample)) {
        
        incProgress(1/length(features_Ratio_bySample), detail = paste(round(i/length(features_Ratio_bySample)*100,0),"%..."))
        setTxtProgressBar(pb_1, i)
        idx<-names(Matrix_ratio[names_features_ratio_selected %in%  names(features_Ratio_bySample[[i]]),i])
        Matrix_ratio[names_features_ratio_selected %in%  names(features_Ratio_bySample[[i]]),i]<-features_Ratio_bySample[[i]][idx]
        
      }
      
      close(pb_1)
    })
    
    Matrix_ratio<-as.data.frame(Matrix_ratio)
    
    
    
    Matrix_ratio<-data.frame(ID_pair_features = rownames(Matrix_ratio), 
                             VarRatio = apply(Matrix_ratio,1, function(x) {var(x, na.rm = TRUE)}), 
                             Matrix_ratio)
    
    colnames(Matrix_ratio)<-c("ID_pair_features", "VarRatio", colnames(Matrix_filter))
    
    message("Prepocessing complete : ")
    
    Matrix_ratio<-Matrix_ratio[order(Matrix_ratio$VarRatio),]
    
    
    
    res<-list(Matrix_ratio = Matrix_ratio,
              Matrix_filter = Matrix_filter,
              samplesExcluded = res_filter$samplesExcluded,
              samplesSelected = res_filter$samplesSelected)
    
    return(res)
  }
  
  
  
}





###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#Function to search a set of normalizers who minimize the variability between samples
Search_normalizers<-function(Matrix, 
                             pFeatures = 10,
                             pSample = 50,
                             minNormalizersParam = 100){
  
  
  
  
  withProgress(message = 'Search normalizers...', value = 0, {
    
    incProgress(1/3, detail = paste("filter bad samples",round(1/3*100,0),"%"))
    # Data must be logged
    if (max(Matrix, na.rm = TRUE) > 107) { # How possible it is to have intensity>1e+32
      log.scaled <- FALSE
      Matrix <- log2(Matrix)
    } else log.scaled <- TRUE
    
    
    ## Filter the bad samples(samples do not containing p% of features)
    res_filter<-FilterMatrixAbundance(X = Matrix, p = pFeatures)
    
    Matrix_filter_BySample<-res_filter$X_filter
    
    Matrix_filter_BySample<-as.matrix(Matrix_filter_BySample)
    
    
    incProgress(1/3, detail = paste("Filter features missing in ", pSample,"% of samples",round(2/3*100,0),"%"))
    ##Filter features missing in (1-q)% of samples.
    freq_pSample<-apply(Matrix_filter_BySample, 1, function(x){sum(!is.na(x))})*100/ncol(Matrix_filter_BySample)
    
    
    Features_selected<-names(freq_pSample[freq_pSample>=pSample])
    
    
    if(length(Features_selected) == minNormalizersParam){
      minNormalizers<-ceiling(1/3*minNormalizersParam)
    } else {
      minNormalizers<-ceiling(minNormalizersParam)
    }
   
    if(length(Features_selected)<minNormalizers){
      
      sendSweetAlert(
        session = session,
        title = "Warning !",
        text = HTML(paste0("Number of potential normalizer(",length(Features_selected),") too lower than 'min normalizers'! <br/>
                  Please decrease the value of the parameter 'Min sample' or 'min minNormalizers', <br/>")),
        type = "warning",
        html = TRUE
      )
      
      ### Enable some buttons when prepossessing start
      shinyjs::enable(selector = '.navbar-nav a[data-value="Match reference map"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Analysis new samples"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Peak detection"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Generate the reference map"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Database"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Statistical analysis"')
      shinyjs::enable(selector = '.navbar-nav a[data-value="Help"')
      
      enable("id_InternalStandardsParametersPanel")
      enable("IdentifyNormalizers")
      enable("ValidRefrenceMap")
      enable("PreviousPageGenerateRefMap")
      
      
      req(NULL)
      
    }
    
    
    incProgress(1/3, detail = paste("Compute median intensity ", round(3/3*100,0),"%"))
    ref_intensity<-apply(Matrix_filter_BySample,
                         1,
                         median,
                         na.rm = TRUE)
    names(ref_intensity)<-rownames(Matrix_filter_BySample)
    
    if(!log.scaled){
      
      Matrix_filter_BySample<-2^(Matrix_filter_BySample)
      Matrix<-2^Matrix
      ref_intensity<-2^(ref_intensity)
      
    }
    
  })
  
  ## Parallel parameters

  # Clean up any previous implicit clusters before creating new one
  tryCatch(doParallel::stopImplicitCluster(), error = function(e) NULL)

  workers = ceiling((detectCores())-1)
  cl <- parallel::makeCluster(getOption("cl.cores", workers))
  # Ensure cluster is always closed, even if an error occurs
  on.exit(parallel::stopCluster(cl), add = TRUE)
  doParallel::registerDoParallel(cl)
  
  ##Initializing varCacul
  iset.Opt<- Features_selected
  idxDelete<-0
  varCalcul<-calculate_Variability(X = as.matrix(Matrix_filter_BySample),
                                   ref = ref_intensity,
                                   iset.ref = iset.Opt,
                                   min.iset = 10,
                                   extrap=TRUE,
                                   cutrat = 1,
                                   out.scale = "naturel",
                                   method = "lm")$w.metric
  varOpt<-varCalcul
  
  PepExclude<-c()
  pepInclude<-list(iset.Opt)
  #v<-c()
  
  iterj<-1
  niterj<-length(iset.Opt)-minNormalizers+1
  
  withProgress(message = 'Calculating variabilities...', value = 0, {
    
    while (!is.na(idxDelete)) {
      iterj<-iterj+1
      
      incProgress(1/niterj, detail = "Searching normalizers...")
      
      # message("Peptide delete")
      # print(idxDelete)
      # message("Number of normalizer")
      # print(length(iset.Opt))
      # message("varCalcul")
      # print(varCalcul)
      
      # ##~~~~~~~~~~~~~~~~~~~~ Version Parallel avec foreach~~~~~~~~~~~~~~~~~~~~~~~###
      # ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # 
      # 
      pb_Cal <- txtProgressBar(min=1, max = length(iset.Opt), style = 3)
      v<-foreach(i=1:length(iset.Opt),
                 .combine='c') %dopar% {
                   setTxtProgressBar(pb_Cal, i)
                   
                   ###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
                   ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
                   ### Function normalize matrix and 
                   ### Computes variability after normalization, number of sample normalized and number median of normalizers in samples 
                   calculate_Variability <- function(X, # Matrix to normalized
                                                     ref,
                                                     iset.ref,
                                                     min.iset,
                                                     span=0.75,
                                                     extrap=TRUE,
                                                     cutrat = 2,
                                                     method = c("lm","loess","kreg"),
                                                     plot.model = FALSE,
                                                     out.scale=c("log2", "natural")){
                     
                     if (is.vector(X))
                       X <- as.matrix(X)
                     
                     
                     
                     # Data must be logged
                     if (max(X, na.rm = TRUE) > 107) { # How possible it is to have intensity>1e+32
                       log.scaled <- FALSE
                       #X <- remove.zeros(X,strategy=replace.zero)
                       X <- log2(X)
                     } else log.scaled <- TRUE
                     
                     if (missing(ref)) 
                       ref <- apply(X,1,function(x) median(x, na.rm = TRUE))
                     
                     if(max(ref, na.rm = TRUE)>107)
                       ref<-log2(ref)
                     
                     
                     method <- tolower(method[1])
                     out.scale<-tolower(out.scale[1])
                     
                     iset.i<-list()
                     adj.r.squared<-c()
                     idxSampleNormalized<-NULL
                     Xn <- matrix(NA,nrow(X),ncol(X))
                     rownames(Xn)<-rownames(X)
                     colnames(Xn)<-colnames(X)
                     
                     layout(matrix(1:15, ncol=3, byrow = TRUE))
                     par(mar=c(5,5,2,1))
                     
                     
                     if(ncol(X)>1) {
                       
                       
                       for (i in 1:ncol(X)) {
                         
                         #iset.ref<-names(ref)
                         
                         if (!is.null(cutrat))
                           iset <- iset.ref[which(abs(X[iset.ref,i]-ref[iset.ref])<=cutrat)]
                         else iset<-iset.ref
                         
                         
                         if(method == "lm") {
                           
                           idx_No_NA<-names(X[,i][!is.na(X[,i])])
                           iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
                           
                           if(length(iset_No_NA)>=min.iset) {
                             a <- X[iset_No_NA,i]
                             m <- ref[iset_No_NA]
                             
                             
                             model_lm<-lm(m~a)
                             
                             pred <- model_lm$coefficients[1]+model_lm$coefficients[2]*X[idx_No_NA,i]
                             
                             
                             
                             Xn[idx_No_NA,i] <-pred
                             idxSampleNormalized<-c(idxSampleNormalized,i)
                             iset.i[[i]]<-iset_No_NA
                             adj.r.squared[i]<-summary(model_lm)$adj.r.squared
                             
                             
                             if(plot.model == TRUE){
                               plot(a,m, pch = 16, main = "Model")
                               abline(model_lm, col = "green", lwd = 3)
                               
                               plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before")
                               abline(coef = c(0,1), col = "blue", lwd = 3)
                               
                               plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
                               abline(coef = c(0,1), col = "red", lwd = 3)
                             }
                             
                           } else {
                             Xn[idx_No_NA,i] <-X[idx_No_NA,i]
                             iset.i[[i]]<-iset_No_NA
                             
                             # if(is.null(iset_No_NA))
                             #   iset.i[[i]]<-0
                             
                             
                             adj.r.squared[i]<-0
                             
                             if(plot.model == TRUE){
                               if(length(iset_No_NA)>1) {
                                 plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                                 
                               } else {
                                 plot(0,0, pch = 16)
                               }
                             }
                             
                           }
                           
                           
                           
                         } else if (method == "kreg"){
                           
                           idx_No_NA<-names(X[,i][!is.na(X[,i])])
                           iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
                           
                           
                           if(length(iset_No_NA)>=min.iset) {
                             
                             
                             a <- X[iset_No_NA,i]
                             m <- ref[iset_No_NA]
                             
                             
                             
                             
                             data_model<-data.frame(a = a, m = m)
                             # fit the models using normalizers
                             # bw <- npregbw(formula=m~a)
                             
                             model.np<-npreg(m ~ a,
                                             bws = 15,
                                             bwtype = c("fixed","generalized_nn","adaptive_nn")[1],
                                             regtype = "ll",
                                             ckertype = "gaussian",
                                             #bwmethod = "cv.aic",
                                             gradients = TRUE,
                                             data = data_model)
                             
                             
                             
                             pred<-predict(model.np, newdata = data.frame(a = X[idx_No_NA,i]))
                             
                             ### Calibrated intensity
                             Xn[idx_No_NA,i] <-pred
                             
                             idxSampleNormalized<-c(idxSampleNormalized,i)
                             iset.i[[i]]<-iset_No_NA
                             
                             
                             predict_data_model.np<-data.frame(a = a, m = predict(model.np, newdata = data.frame(a = a)))
                             
                             if(plot.model){
                               plot(a,m, pch = 16, main = "Model")
                               lines(predict_data_model.np$a, 
                                     predict_data_model.np$m
                                     , col = "red", lwd = 2)
                               
                               plot(X[idx_No_NA,i],ref[idx_No_NA], pch = 16, main = "Before" ) 
                               abline(coef = c(0,1), col = "blue", lwd = 3)
                               
                               plot(pred,ref[idx_No_NA], pch = 16, main = "After" ) 
                               abline(coef = c(0,1), col = "green", lwd = 3)
                             }
                             
                           } else {
                             Xn[idx_No_NA,i] <-X[idx_No_NA,i]
                             iset.i[[i]]<-iset_No_NA
                             
                             # if(is.null(iset_No_NA))
                             #   iset.i[[i]]<-0
                             
                             if(plot.model == TRUE){
                               if(length(iset_No_NA)>1) {
                                 plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                                 
                               } else {
                                 plot(0,0, pch = 16)
                               }
                             }
                             
                           }
                           
                         }else if (method == "loess"){
                           
                           idx_No_NA<-names(X[,i][!is.na(X[,i])])
                           iset_No_NA<-names(X[iset,i][!is.na(X[iset,i])])
                           
                           if(length(iset_No_NA)>=min.iset) {
                             a <- X[iset_No_NA,i]
                             m <- ref[iset_No_NA]
                             
                             
                             #lc <- lowess(m ~ a,f=span)
                             #pred <- extrap1(lc$x,lc$y,xo=X[idx_No_NA,i],extrap=extrap, method = "nearest")
                             model_loess<-loess(m ~ a,data.frame(a=a,m=m),span=span, 
                                                degree=1,family="symmetric")
                             pred <- predict(model_loess,newdata=X[idx_No_NA,i])
                             m_predict<-predict(model_loess,newdata=a)
                             
                             
                             
                             Xn[idx_No_NA,i] <-pred
                             idxSampleNormalized<-c(idxSampleNormalized,i)
                             iset.i[[i]]<-iset_No_NA
                             
                             if(plot.model == TRUE){
                               plot(a,m, pch = 16)
                               lines(a,m_predict, col = "red", lwd = 3)
                               #lines(lc$x,lc$y, col = "red", lwd = 3)
                             }
                             
                           } else {
                             
                             Xn[idx_No_NA,i] <-X[idx_No_NA,i]
                             iset.i[[i]]<-iset_No_NA
                             
                             # if(is.null(iset_No_NA))
                             #   iset.i[[i]]<-0
                             
                             
                             if(plot.model == TRUE){
                               if(length(iset_No_NA)>1) {
                                 plot(X[iset_No_NA,i], ref[iset_No_NA], pch = 16)
                                 
                               } else {
                                 plot(0,0, pch = 16)
                               }
                             }
                             
                           }
                           
                           
                         } else stop("method must be \"lm\" or \"loess\" or \"kreg\"")
                       }
                       
                       
                       
                     }
                     
                     
                     
                     
                     if(method == "lm") {
                       names(adj.r.squared)<-colnames(Xn)
                       attr(Xn, "adj.r.squared")<-adj.r.squared
                     }
                     
                     if(!is.null(dim(Xn[,idxSampleNormalized]))){
                       w.metric<- mad(apply(Xn[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE);
                       w.metric.before <- mad(apply(X[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE)
                       
                       
                       
                     } else{
                       
                       w.metric<-NA
                       w.metric.before<-NA
                     }
                     
                     
                     
                     # attr(Xn,"w.metric")<-w.metric
                     # names(iset.i)<-colnames(Xn)
                     
                     
                     
                     attr(Xn,"nbr_pep_normalizers")<-lapply(iset.i, length)
                     # names(attr(Xn,"nbr_pep_normalizers"))<-colnames(Xn)
                     # 
                     # print(attr(Xn,"nbr_pep_normalizers"))
                     
                     
                     
                     attr(Xn,"idX_normalizers")<-iset.i
                     
                     
                     if(method == "lm") {
                       
                       adj.r.squared<-attr(Xn,"adj.r.squared")
                       
                       if(plot.model==TRUE){
                         
                         #output$adj_r_squared<-renderPlot({
                         plot(adj.r.squared, cex.axis = 1.5, cex.lab = 1.5)
                         lines(adj.r.squared, lwd = 3, col = "blue", ylim = c(min(adj.r.squared), 
                                                                              max(adj.r.squared)))
                         # })
                       }
                     }
                     
                     
                     
                     
                     # return(round(w.metric,3))
                     
                     return(list(w.metric = w.metric,
                                 nidxSampleNormalized = length(idxSampleNormalized),
                                 nbr_pep_normalizers = median(unlist(attr(Xn,"nbr_pep_normalizers")))
                     ))
                   }
                   
                   calculate_Variability(X = as.matrix(Matrix_filter_BySample),
                                         ref = ref_intensity,
                                         iset.ref = iset.Opt[-i],
                                         min.iset = 10,
                                         extrap=TRUE,
                                         cutrat = 1,
                                         out.scale = "naturel",
                                         method = "lm")$w.metric
                 }
      
      close(pb_Cal)
      
      
      # ##~~~~~~~~~~~~~~~~~~~~ Version avec la boucle for~~~~~~~~~~~~~~~~~~~~~~~###
      # ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      # 
      #  pb_Cal <- txtProgressBar(min=1, max = length(iset.Opt), style = 3)
      # #withProgress(message = 'Calculating variabilities...', value = 0, {
      # for(i in 1:length(iset.Opt)){
      # 
      #   setTxtProgressBar(pb_Cal, i)
      #   #incProgress(1/length(iset.Opt), detail = paste(round((i/length(iset.Opt))*100,0),"%"))
      #   v[i]<-calculate_Variability(X = as.matrix(Matrix_filter_BySample),
      #                            ref = ref_intensity,
      #                            iset.ref = iset.Opt[-i],
      #                            min.iset = 10,
      #                            extrap=TRUE,
      #                            cutrat = 1,
      #                            out.scale = "naturel",
      #                            method = "lm")$w.metric
      # }
      # 
      #  close(pb_Cal)
      # 
      # #})
      
      ##Normalisateurs donnant une variabilité inférieur à varCalcul[1]
      idx<-which(v<=varCalcul[1])
      
      ##Normalisateurs dont on exclus minimise la variabilité
      idxDelete<-idx[which(v[idx]==min(v[idx], na.rm = TRUE))[1]]
      
      # idxSelected<-idx[which(v[idx]==min(v[idx], na.rm = TRUE))]
      # ## Soit du normalisateurs à exclure par ordre de stabilité des ratio 
      # idxDelete<-idxSelected[length(idxSelected)]
      
      if((length(iset.Opt) == minNormalizers) || (varOpt==0) || (idxDelete>length(iset.Opt))){
        idxDelete<-NA
      }
      
      
      if(!is.na(idxDelete)){
        varOpt<-min(v[idx], na.rm = TRUE)
        varCalcul<-c(varCalcul,varOpt)
        PepExclude<-c(PepExclude, iset.Opt[idxDelete])
        # message("peptide excluded")
        # print(PepExclude)
        
        
        
        iset.Opt<-iset.Opt[-idxDelete]
        pepInclude<-c(pepInclude,list(iset.Opt))
        
        
        
        
        
        
        
        # message("peptide included")
        # print(pepInclude)
      } else {
        message("Convergence")
        sendSweetAlert(
          session = session,
          title = "Finish !",
          text = HTML("Covergence<br/>"),
          type = "success",
          width = "50%",
          html = TRUE
        )
      }
      
      
    }
  })
  
  parallel::stopCluster(cl)
  
  
  ## Set optimal for normalizers
  idxOpt.normalizers<-which(varCalcul==min(varCalcul))[1]
  
  ID_normalizres<-pepInclude[[idxOpt.normalizers]]
  
  
  res_normalization_Matrix<-normalizeSamples(X = as.matrix(Matrix),
                                             ref = ref_intensity,
                                             iset.ref = ID_normalizres,
                                             min.iset = 10,
                                             extrap=TRUE,
                                             cutrat = 1,
                                             out.scale = "naturel",
                                             method = "lm")
  
  w.metric.before = attr(res_normalization_Matrix$X_before_Normalizers,"w.metric.before")
  w.metric.after = attr(res_normalization_Matrix$X_save,"w.metric")
  
  
  return(list(PepExclude = PepExclude,
              pepInclude = pepInclude,
              varCalcul = varCalcul,
              Matrix_filter_BySample = Matrix_filter_BySample,
              samplesExcluded = res_filter$samplesExcluded,
              samplesSelected = res_filter$samplesSelected,
              Features_selected = Features_selected,
              ref_intensity = ref_intensity,
              ID_normalizres = ID_normalizres,
              Matrix_Before = res_normalization_Matrix$X_before_Normalizers,
              Matrix_After = res_normalization_Matrix$X_save,
              w.metric.before = w.metric.before,
              w.metric.after = w.metric.after
  ))
  
}



