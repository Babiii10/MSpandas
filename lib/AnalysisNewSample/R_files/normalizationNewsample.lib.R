

# Correct the intensity values by interpolating on MD diagram
# md : correct the mean-difference plot or the original?
normalizeSamples <- function(X, # Matrix to normalized
                             ref,
                             iset.ref,
                             min.iset,
                             span=0.75,
                             extrap=TRUE,
                             cutrat = 2,
                             method = c("lm","loess","kreg"),
                             plot.model = FALSE,
                             out.scale=c("log2", "natural")
) {
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
    
    
    pb_norm <- txtProgressBar(min=1, max = ncol(X), style = 3)
    cat("Normalize news samples...\n")
    message("R2 ajusté : ")
    withProgress(message = 'Normalizing sample', value = 0, {
      for (i in 1:ncol(X)) {
        setTxtProgressBar(pb_norm, i)
        #Sys.sleep(0.5)
        ########################################################################
        # Reset the timebar for later
        updateShinyProgressBar(
          shinyProgressData=list(
            session=session,
            progressId="normIntensityProgressBar",
            progressTotal=ncol(X),
            textId="normI_pre"
          ),
          pbValue=i,
          headerMsg= "",
          footerMsg=paste("Normalizing sample ",colnames(X)[i],"...")
        )
        ########################################################################
        incProgress(1/ncol(X), detail = paste(colnames(X)[i],"..."))
        
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
            
            
            print(adj.r.squared[i])
            
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
            message(paste("\n sample",i,
                          "is not normalized because there is too few normalizers",
                          length(iset_No_NA),"<",min.iset,"\n", sep = " "))
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
            
            
            message(paste("\n sample",i,
                          "is not normalized because there is too few normalizers",
                          length(iset_No_NA),"<",min.iset,"\n", sep = " "))
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
            
            message(paste("\n sample",i,
                          "is not normalized because there is too few normalizers",
                          length(iset_No_NA),"<",min.iset,"\n", sep = " "))
            
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
    
    close(pb_norm)
    
  }
  
  ### à voir
  if(ncol(res_MatrixNewSample)==4)
    Xn[,"Refrence.Map"]<-RvarsPeakDetectionNewSample$map_ref$maxo
  
  
  if(method == "lm") {
    
    
    names(adj.r.squared)<-colnames(Xn)
    attr(Xn, "adj.r.squared")<-adj.r.squared
  }
  
  if(!is.null(dim(Xn[,idxSampleNormalized]))){
    w.metric<- mad(apply(Xn[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE);
    w.metric.before <- mad(apply(X[,idxSampleNormalized],2,median,na.rm=TRUE),na.rm = TRUE)
    
    attr(Xn,"w.metric")<-w.metric
    names(iset.i)<-colnames(Xn)
    
    attr(Xn,"nbr_pep_normalizers")<-lapply(iset.i, length)
    names(attr(Xn,"nbr_pep_normalizers"))<-colnames(Xn)
    
    print(attr(Xn,"nbr_pep_normalizers"))
    message("Number minimum of normalizers")
    print(min(unlist(attr(Xn,"nbr_pep_normalizers"))))
    
    # for(i in 1:length(iset.i)){
    #   if(length(iset.i[[i]])==1){
    #     if(iset.i[[i]]==0)
    #       attr(Xn,"nbr_pep_normalizers")[[i]]<-0
    #   }
    #
    # }
    
    
    attr(Xn,"idX_normalizers")<-iset.i
    
    # output$W_before_norm<-renderText({
    #   paste("Variability before normalization : ",round(w.metric.before,3))
    # })
    #
    # output$W_norm<-renderText({
    #   paste("Variability after normalization : ",round(w.metric,3))
    # })
    #
    
    output$W_before_norm<-renderText({
      round(w.metric.before,3)
    })
    
    output$W_norm<-renderText({
      round(w.metric,3)
    })
    
    
    # if((plot.model == TRUE) & method == "lm") {
    #
    #   adj.r.squared<-attr(Xn,"adj.r.squared")
    #
    #   plot(adj.r.squared, cex.axis = 1.5, cex.lab = 1.5)
    #   lines(adj.r.squared, lwd = 3, col = "blue", ylim = c(min(adj.r.squared),
    #                                                        max(adj.r.squared)))
    # }
    
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
    
    
    
    
    ### Boxplot des intensitees
    
    
    shinyjs::show(id = "IdBoxplotNormalizing")
    # Normalization
    output$BoxplotNormalizing<-renderPlot({
      
      nbr_normalizers<-unlist(attr(Xn,"nbr_pep_normalizers"))
      palette_colors<-heat.colors(ncol(X), rev = TRUE)
      names(palette_colors)<-as.character(sort(unique(nbr_normalizers)))
      
      ### before normalization
      X_plot<-rbind(as.integer(nbr_normalizers),X)
      rownames(X_plot)[1]<-"nbr_pep_stable"
      #colnames(X_plot)<-as.character(1:ncol(X_plot))
      
      t_X_plot<-t(X_plot)
      t_X_plot<-t_X_plot[order(t_X_plot[,"nbr_pep_stable"]),]
      X_plot<-t(t_X_plot)
      #layout(matrix(1:2, ncol=1, nrow = 2, byrow = TRUE))
      #par(mar=c(1,5,1,5))
      
      X_plotDataFrame<-list()
      for (i in colnames(X_plot)) {
        X_plotDataFrame[[i]]<-data.frame(maxo = X_plot[-1,i],
                                         nbrNormalizers = X_plot[1,i],
                                         sample = i,
                                         groupe = "Before_normalization")
      }
      
      X_plotDataFrame<-do.call("rbind", X_plotDataFrame)
      ### after normalization
      X_plot_norm<-rbind(as.integer(nbr_normalizers),Xn)
      rownames(X_plot_norm)[1]<-"nbr_pep_stable"
      #colnames(X_plot_norm)<-as.character(1:ncol(X_plot_norm))
      
      
      t_X_plot_norm<-t(X_plot_norm)
      t_X_plot_norm<-t_X_plot_norm[order(t_X_plot_norm[,"nbr_pep_stable"]),]
      X_plot_norm<-t(t_X_plot_norm)
      
      sample_status<-c()
      sample_status_name<-c()
      n_nromalizers<-as.numeric(X_plot_norm[1,])
      for (i in 1:length(n_nromalizers)) {
        if(n_nromalizers[i]<min.iset){
          sample_status[i]<-"Not normalized"
          sample_status_name[i]<-colnames(X_plot_norm)[i]
        } else {
          sample_status[i]<-""
          sample_status_name[i]<-colnames(X_plot_norm)[i]
        }
        
      }
      
      
      
      tabe_infoNormalize<-data.frame(sample_status_name = sample_status_name, sample_status)
      
      samples_not_normalized<-tabe_infoNormalize[tabe_infoNormalize$sample_status!="",]$sample_status_name
      
      samples_not_normalized<-paste(samples_not_normalized," : <span style = 'font-weight: bold; color:red;'>",
                                    n_nromalizers[n_nromalizers<min.iset], " normalizers </span>")
      
      X_plotDataFrame_norm<-list()
      for (i in colnames(X_plot_norm)) {
        X_plotDataFrame_norm[[i]]<-data.frame(maxo = X_plot_norm[-1,i],
                                              nbrNormalizers = X_plot_norm[1,i],
                                              sample = i,
                                              groupe = "After_normalization")
        
      }
      
      X_plotDataFrame_norm<-do.call("rbind",X_plotDataFrame_norm)
      
      X_plotDataAll<-rbind(X_plotDataFrame,X_plotDataFrame_norm)
      
      rownames(X_plotDataAll)<-1:nrow(X_plotDataAll)
      
      X_plotDataAll$groupe<-factor(X_plotDataAll$groupe, levels = c("Before_normalization","After_normalization"))
      X_plotDataAll$sample<-factor(X_plotDataAll$sample, levels = unique(X_plotDataAll$sample))
      
      
      if(is.element("Not normalized",sample_status)){
        sendSweetAlert(
          session = session,
          title = paste("<h3>Attention !</h3>"),
          text = HTML(paste('<span class = "infoNormTitle">The following samples are not normalized : </span><br/>
                          <span class ="infoNorm">',
                            str_c(samples_not_normalized, collapse = " <br/> "),'
                <br/>
                <span style = "font-weight: bold";>Nb : </span>These samples contain less than
                <span style = "font-weight: bold;color:green;">', min.iset,
                            ' normalizers (Minimum number of normalizers)</span>.<br/>
                You can improve the normalization results by playing on the parmeters. </span>
                <br/>
                <h4>click Ok to continue!</h4>')),
          type = "info",
          width = "80%",
          closeOnClickOutside = TRUE,
          html = TRUE
        )
      }
      
      if(!all(is.na(X_plotDataAll$maxo))) {
        
        
        X_plotDataAll<-X_plotDataAll %>%
          dplyr::filter(nbrNormalizers>=min.iset)
        
        if(length(unique(X_plotDataAll$sample))>=10){
          X_plotDataAll<-X_plotDataAll %>%
            dplyr::filter(sample %in% unique(X_plotDataAll$sample)[c(seq(length(unique(X_plotDataAll$sample)), length.out = 10, by = -1))])
          
        }
        
        
        if(nrow(X_plotDataAll)==0){
          
          sendSweetAlert(
            session = session,
            title = "Warning !",
            text = HTML("No sample is normalize! <br/>
                  Please change the normalization parameters, <br/>"),
            type = "warning",
            html = TRUE
          )
          
          RvarsNormalizeNewsample$NoSampleNormalize<-TRUE
        } else{
          normalizers_ToPrint_input<-X_plotDataAll %>%
            dplyr::filter(groupe=="After_normalization") %>%
            dplyr::distinct(sample, .keep_all = TRUE)
          
          
          
          RvarsNormalizeNewsample$sample_ToPrint<-as.character(normalizers_ToPrint_input$sample)
          normalizers_ToPrint<-normalizers_ToPrint_input$nbrNormalizers
          names(normalizers_ToPrint)<-RvarsNormalizeNewsample$sample_ToPrint
          
          if(length(RvarsNormalizeNewsample$sample_ToPrint)>=10){
            ggplot(X_plotDataAll, aes(x = sample, y = maxo, fill = sample)) +
              geom_boxplot(na.rm = TRUE, outlier.colour = "red")+
              #scale_x_discrete(labels=paste(X_plot_norm[1,],"\n",sample_status)) +
              scale_x_discrete(labels=paste(normalizers_ToPrint)) +
              
              facet_grid(vars(groupe), vars())+
              ylab("log2 intensity")+
              xlab("Number of normalizer")+
              ggtitle(paste0("Top 10 samples (number of normalizers >= ",normalizers_ToPrint,")","\n"))+
              scale_y_continuous(n.breaks = 10)+
              #expand_limits(y = 8)+
              #coord_flip() +
              theme_ben.1()+
              theme(
                plot.title = element_text(size = rel(1),
                                          face = "bold",
                                          color = "#760001",
                                          margin = margin(0,0,5,0), hjust = 0.5),
                #axis.text.x = element_blank(),
                #axis.text.x = element_text(size = rel(0.80), face = "bold.italic", angle = 90),
                axis.text.x = element_text(size = rel(0.80), face = "bold.italic"),
                #axis.title.x = element_blank(),
                
                legend.title = element_text(size = rel(0.85), face = "bold.italic", hjust = 0.5),
                legend.text = element_text(size = rel(0.7), face = "bold.italic"))
            #legend.position = "none")
          } else{
            ggplot(X_plotDataAll, aes(x = sample, y = maxo, fill = sample)) +
              geom_boxplot(na.rm = TRUE, outlier.colour = "red")+
              #scale_x_discrete(labels=paste(X_plot_norm[1,],"\n",sample_status)) +
              scale_x_discrete(labels=paste(normalizers_ToPrint)) +
              
              facet_grid(vars(groupe), vars())+
              ylab("log2 intensity")+
              xlab("Number of normalizer")+
              scale_y_continuous(n.breaks = 10)+
              #expand_limits(y = 8)+
              #coord_flip() +
              theme_ben.1()+
              theme(#axis.text.x = element_blank(),
                #axis.text.x = element_text(size = rel(0.80), face = "bold.italic", angle = 90),
                axis.text.x = element_text(size = rel(0.80), face = "bold.italic"),
                #axis.title.x = element_blank(),
                
                legend.title = element_text(size = rel(0.85), face = "bold.italic", hjust = 0.5),
                legend.text = element_text(size = rel(0.7), face = "bold.italic"))
            #legend.position = "none")
          }
        }
        
        
        
        
      }
      
      
      
      
      
    })
    
    
    
    
    
    shinyjs::show(id = "IdNormalizresPlot")
    #### Plot intensity
    
    output$NormalizresPlot<-renderPlot({
      
      if(!RvarsNormalizeNewsample$NoSampleNormalize){
        
        '%ni%' <- Negate('%in%')
        # Plot three graphs side-by-side.
        
        
        
        Xn_data<-req(Xn[,RvarsNormalizeNewsample$sample_ToPrint])
        
        
        Xn_data<-data.frame(Xn_data, Refrence.Map = RvarsPeakDetectionNewSample$map_ref$maxo)
        
        
        
        if(ncol(res_MatrixNewSample)==4)
          Xn_data<-Xn_data[, -ncol(Xn_data)]
        
        Xn_data<-data.frame(Xn_data, Features = "No stable")
        layout(matrix(1:8,ncol=4, byrow = TRUE))
        #par(mar=c(5,5,2,1))
        #par(mar=c(4,4,1,0))
        par(mar=c(4,4,2,2), oma = c(0, 0, 2, 0))
        # par(mar=c(4,4,4,4),oma=c(1,1,0,0),pch=20,cex=0.8,cex.lab=1.3,
        #     cex.axis=1.2,cex.main=1.4,font.lab=2)
        
        
        if(ncol(Xn_data)-2<9) {
          RvarsNormalizeNewsample$n_nrom<-ncol(Xn_data)-2
        } else {
          RvarsNormalizeNewsample$n_nrom<-8
        }
        
        number_normalizer<-c()
        for (k in 1:RvarsNormalizeNewsample$n_nrom) {
          Xn_data_k<-Xn_data
          
          
          
          if(length(iset.i[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]])>=1)
            Xn_data_k[iset.i[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]],"Features"]<-"Stable"
          
          number_normalizer[k]<-length(iset.i[RvarsNormalizeNewsample$sample_ToPrint[k]][[1]])
          
          if(!all(is.na(Xn_data_k[,k]))) {
            plot(x = Xn_data_k[Xn_data_k$Features=="No stable","Refrence.Map"],
                 y = Xn_data_k[Xn_data_k$Features=="No stable",k], pch=20, col= "gray", cex=1.2, #0.8
                 xlab = "Refrence map",
                 ylab = paste("sample",k,sep = "-"),
                 main = paste(number_normalizer[k] ,"Normalizers"),
                 cex.lab = 1.5, #1.3
                 cex.axis = 1.2,
                 font.axis = 2,
                 font.main = 2,
                 cex.main = 1.2)
            abline(coef = c(0,1), col = "red", lwd = 2)
            points(x = Xn_data_k[Xn_data_k$Features=="Stable","Refrence.Map"],
                   y = Xn_data_k[Xn_data_k$Features=="Stable",k], pch=20, col= "green", cex=1.2, #0.8
                   # cex.lab = 1.3,
                   # cex.axis = 1.2,
                   # font.axis = 2
            )
            
          }
          
          
        }
        
      } else {
        
      }

      
      
    })
    
    
    
    
    
    
    output$LegendNormalizresPlot<-renderPlot({
      
      
      if(!RvarsNormalizeNewsample$NoSampleNormalize){
        data_legend<-data.frame(x=seq.int(length.out = 10),y=(seq.int(length.out = 10))^2, Legend=c(rep("Stable",5),rep("Unstable",5)))
        ggplot_legend<-ggplot(data_legend) +
          aes(x = x, y = y, colour = Legend) +
          geom_point(size = 5L) +
          scale_color_manual(
            values = c(Stable = "green",
                       Unstable = "gray")
          ) +
          theme_ben()+
          theme(legend.title = element_text(size = rel(1.1), face = "bold.italic", hjust = 0.5),
                legend.text = element_text(size = rel(0.8), face = "bold.italic"),
                legend.key = element_rect(fill = "transparent", colour = NA),
                legend.key.size = unit(0.5, "cm"),
                legend.key.width = unit(0.5,"cm"),
                legend.background = element_rect(fill = "transparent", colour = "#f7f6f1"))
        
        legend <- get_legend(ggplot_legend)
        grid.newpage()
        grid.draw(legend)
      } else {
        
      }
      
      
      
    })
    
    
    
    
    output$LegendNormalizresPlotSampleName<-renderText({
      
      if(!RvarsNormalizeNewsample$NoSampleNormalize){
        if(RvarsNormalizeNewsample$n_nrom==1){
          
          
          data_legend<-data.frame(x=1,
                                  y=2^2,
                                  Samples=paste("\n",paste("sample",1:1,sep = "-"),": ",RvarsNormalizeNewsample$sample_ToPrint[1], sep = ""))
          data_legend$Samples
          
        } else {
          
          
          Xn_legend<-Xn[,RvarsNormalizeNewsample$sample_ToPrint[1:RvarsNormalizeNewsample$n_nrom]]
          data_legend<-data.frame(x=seq.int(length.out = ncol(Xn_legend)),
                                  y=(seq.int(length.out = ncol(Xn_legend)))^2,
                                  Samples=paste("\n",paste("sample",1:ncol(Xn_legend),sep = "-"),": ",colnames(Xn_legend),sep = ""))
          data_legend$Samples
        }
      } else {
        
      }
      
     
      
      
    })
    
    
    
    
    
    
    
    
    ########################################################################
    # Reset the timebar for later
    updateShinyProgressBar(
      shinyProgressData=list(
        session=session,
        progressId="normIntensityProgressBar",
        progressTotal=ncol(X),
        textId="normI_pre"
      ),
      pbValue=ncol(X),
      headerMsg= "",
      footerMsg=""
    )
    ########################################################################
    
    # write.table(X[,idxSampleNormalized], file = "Matrix-abondance-Before-Validation.csv", sep = ",", row.names = FALSE)
    attr(Xn,"idX_normalizers")<-iset.i
    
    X_save<-Xn[,idxSampleNormalized]
    attr(X_save,"idX_normalizers")<-iset.i[idxSampleNormalized]
    # # Convert back to original form
    # if (!log.scaled && out.scale=="log2")
    #   return(Xn)
    # else if (!log.scaled && out.scale=="natural")
    #   return(2^Xn)
    # else if (log.scaled && out.scale=="natural")
    #   return(2^Xn)
    # else
    #   return(Xn)
    
    # Convert back to original form
    
    
    if(!RvarsNormalizeNewsample$NoSampleNormalize){
      
      if (!log.scaled && out.scale=="log2")
        return(X_save)
      else if (!log.scaled && out.scale=="natural")
        return(2^X_save)
      else if (log.scaled && out.scale=="natural")
        return(2^X_save)
      else
        return(X_save)
    } else {
      return(NULL)
    }
   
    
  } else{
    sendSweetAlert(
      session = session,
      title = "Warning !",
      text = HTML("No or only one sample is normalize! <br/>
                  When you have a least 2 samples to analyze, <br/>
                  the variability before and after normalization can't be calculat for only one sample normalized."),
      type = "warning",
      html = TRUE
    )
    w.metric<-NA
    w.metric.before<-NA
    
    return(NULL)
  }
  
  
 
  
  
}



