interactive_go_volcano <- function(session, input, output)
{
    volcano_data <- create_go_volcano(session, input, output)
    
    # testdf <- data.frame(cbind(dpmsr_set$data$stats$final$Accession, dpmsr_set$data$stats$final$Description))
    # colnames(testdf) <- c("Accession", "Description")
    # volcano_data <- merge(x=volcano_data, y=testdf, by.x="Accession", by.y="Accession")
    
    
    volcano_go_plot <- reactive({
      ggplot(volcano_data, aes(x = log_fc, y = log_pvalue)) +
        theme_minimal() +
        geom_point(alpha=0.4, size=input$plot_dot_size, color = input$volcano_dot_color) +
        xlab(input$plot_x_axis_label) + ylab(input$plot_y_axis_label) +
        scale_colour_gradient(low = input$volcano_dot_color, high = input$volcano_dot_color) +
        ggtitle(input$plot_title)+    
        xlim(-max(volcano_data$log_fc), max(volcano_data$log_fc)) +
        theme(plot.title = element_text(size=input$plot_title_size, hjust = 0.5),
              axis.title = element_text(size=input$plot_label_size, color="black"),
              axis.text.x = element_text(size=10, color="black"),
              axis.text.y = element_text(size=10,  color="black"),
              legend.position = "none")
    })
    
    output$volcano_go_plot <- renderPlot({
      req(volcano_go_plot())
      volcano_go_plot()
    })
    
    output$Download <- downloadHandler(
      filename = function(){
        str_c(dpmsr_set$file$string, "GoVolcano_", input$select_data_comp_go, "_", input$go_volcano_id, "_", 
              input$select_ont_go, ".png", collapse = " ")
      },
      content = function(file){
        req(volcano_go_plot())
        ggsave(file, plot = volcano_go_plot(), device = 'png')
      }
    )
    
    
    output$hover_info <- renderUI({
      hover <- input$plot_hover
      point <- nearPoints(volcano_data, hover, threshold = 5, maxpoints = 1, addDist = TRUE)
      if (nrow(point) == 0) return(NULL)
      
      # calculate point position INSIDE the image as percent of total dimensions
      # from left (horizontal) and from top (vertical)
      left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
      top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
      
      # calculate distance from left and bottom side of the picture in pixels
      # left_px <- hover$range$left + left_pct * (hover$range$right - hover$range$left)
      # top_px <- hover$range$top + top_pct * (hover$range$bottom - hover$range$top)
      left_px <- left_pct * (hover$range$right - hover$range$left)
      top_px <- top_pct * (hover$range$bottom - hover$range$top)
      
      #cat(file=stderr(), str_c("hoverrr=", hover$range$right, "   hoverrl=", hover$range$left, "  left_pct=", left_pct), "\n")
      #cat(file=stderr(), str_c("hoverrb=", hover$range$bottom, "   hoverrt=", hover$range$top, "  top_pct=", top_pct), "\n")
      #cat(file=stderr(), str_c("leftpx=", left_px, "   toppx=", top_px), "\n", "\n"  )
      
      # create style property fot tooltip
      # background color is set so tooltip is a bit transparent
      # z-index is set so we are sure are tooltip will be on top
      
      if(top_pct > 0.3){
        top_custom <- 10
      }else{
        top_custom <- 200
      }
      
      style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                      "left:", 10, "px; top:", top_custom, "px;")
      # actual tooltip created as wellPanel
      wellPanel(
        style = style,
        p(HTML(paste0("<b> Accession: </b>", point$Accession, "<br/>",
                      "<b> Description: </b>", point$Description, "<br/>",
                      "<b> FC: </b>", point$foldchange, "<br/>",
                      "<b> pvalue: </b>", point$pvalue, "<br/>")))
      )
    })
    
    return(volcano_data)
}

#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
#match(namesdf, names(df))

interactive_barplot <- function(session, input, output, df, namex, color_list, output_name, comp_name)
{
  # df <<- df
  # namex <<- namex 
  # color_list <<- color_list
  # output_name <<- output_name
  # comp_name <<- comp_name
  
  
  datay <- colSums(df, na.rm = TRUE)
  df2 <- data.frame(namex)
  df2$Total_Intensity <- datay
  colnames(df2) <- c("Sample", "Total_Intensity")
  df2$Sample <- factor(df2$Sample, levels = df2$Sample)
  ymax <- max(datay)
  
  create_stats_barplot <- reactive({
    ggplot(data=df2, aes(x=Sample, y=Total_Intensity)) +
      geom_bar(stat="identity", fill=color_list)+ theme_classic() + 
      ggtitle(input[[str_c(output_name, "_title")]]) + 
      ylab(input[[str_c(output_name, "_y_axis_label")]]) +
      xlab(NULL) +
      #scale_y_discrete(labels = NULL) +
      coord_cartesian(ylim=NULL, expand = TRUE) +
      theme(plot.title = element_text(hjust = 0.5, size=input[[str_c(output_name, "_title_size")]]), 
            axis.title = element_text(size=input[[str_c(output_name, "_label_size")]], color="black"),
            axis.text.x = element_text(size=input[[str_c(output_name, "_label_size")]], angle = 90,  color="black"),
            axis.text.y = element_text(size=input[[str_c(output_name, "_label_size")]],  color="black"),
      ) 
  })
  
  output[[output_name]] <- renderPlot({
    req(create_stats_barplot())
    create_stats_barplot()
  })
  
  output[[str_c("download_", output_name)]] <- downloadHandler(
    filename = function(){
      str_c("Stats_Barplot_", comp_name,  ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_barplot())
      ggsave(file, plot = create_stats_barplot(), device = 'png')
    }
  )
  
}

#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_boxplot <- function(session, input, output, df, namex, color_list)
{
  colnames(df) <- namex
  df3 <- log2(df) %>% gather(Sample, Intensity, colnames(df))
  df3$Sample <- factor(df3$Sample, levels = rev(namex))
  
  create_stats_boxplot <- reactive({
    ggplot(data=df3, aes(x=Sample, y=Intensity)) +
      geom_boxplot(notch = TRUE, outlier.colour="red", outlier.shape=1,
                   outlier.size=1, fill=rev(color_list)) + theme_classic() + 
      coord_flip()+
      xlab(input$stats_boxplot_x_axis_label) +
      ggtitle(input$stats_boxplot_title) + 
      theme(plot.title = element_text(hjust = 0.5, size=input$stats_boxplot_title_size), 
            axis.title = element_text(size=input$stats_boxplot_label_size, color="black"),
            axis.text.x = element_text(size=input$stats_boxplot_label_size, angle = 90,  color="black"),
            axis.text.y = element_text(size=input$stats_boxplot_label_size,  color="black"),
      ) 
  })
  
  output$stats_boxplot <- renderPlot({
    req(create_stats_boxplot())
    create_stats_boxplot()
  })
  
  output$download_stats_boxplot <- downloadHandler(
    filename = function(){
      str_c("stats_Boxplot_", dpmsr_set$y$stats$groups$comp_name[as.numeric(input$stats_plot_comp)],
            ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_boxplot())
      ggsave(file, plot = create_stats_boxplot(), device = 'png')
    }
  )
  
}
#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_pca2d <- function(session, input, output, df, namex, color_list, groupx)
{
  x_transpose <- t(df)
  x_transpose <-data.frame(x_transpose)
  row.names(x_transpose) <- NULL
  x_transpose <-cbind(groupx, x_transpose)
  x_pca <- prcomp(x_transpose[,-1], scale=TRUE)
  test_this <-x_transpose[,1]
  x_gr <- factor(unlist(test_this))
  summary(x_gr)
  df_out <- as.data.frame(x_pca$x)
  df_out_test <<- df_out
  df_xgr <- data.frame(x_gr)
  df_xgr_test <<- df_xgr
  #df_xgr$x_gr <- as.character(df_xgr$x_gr)
  
  hover_data <- data.frame(cbind(namex, df_out[[input$stats_pca2d_x]], df_out[[input$stats_pca2d_y]]), stringsAsFactors = FALSE  )
  colnames(hover_data) <- c("Sample", "get(input$stats_pca2d_x)", "get(input$stats_pca2d_y)")
  hover_data$`get(input$stats_pca2d_x)` <- as.numeric(hover_data$`get(input$stats_pca2d_x)`)
  hover_data$`get(input$stats_pca2d_y)` <- as.numeric(hover_data$`get(input$stats_pca2d_y)`)
  
  hover_data_test <<- hover_data
  
  create_stats_pca2d <- reactive({
    ggplot(df_out, aes(x=get(input$stats_pca2d_x), y=get(input$stats_pca2d_y), color=x_gr )) +
      geom_point(alpha=0.8, size=input$stats_pca2d_dot_size) +
      theme(legend.title=element_blank()) +
      ggtitle(input$stats_pca2d_title) + 
      ylab(input$stats_pca2d_y) +
      xlab(input$stats_pca2d_x) +
      scale_color_manual(values = rev(unique(color_list))) +
      theme(plot.title = element_text(hjust = 0.5, size=input$stats_pca2d_title_size), 
            axis.title = element_text(size=input$stats_pca2d_label_size, color="black"),
            axis.text.x = element_text(size=input$stats_pca2d_label_size, angle = 90,  color="black"),
            axis.text.y = element_text(size=input$stats_pca2d_label_size,  color="black"),
    ) 
  })
  
  output$stats_pca2d <- renderPlot({
    req(create_stats_pca2d())
    create_stats_pca2d()
  })
  
  output$download_stats_pca2d <- downloadHandler(
    filename = function(){
      str_c("stats_pca2d_", dpmsr_set$y$stats$groups$comp_name[as.numeric(input$stats_plot_comp)],
            ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_pca2d())
      ggsave(file, plot = create_stats_pca2d(), device = 'png')
    }
  )
  
  output$hover_pca2d_info <- renderUI({
    hover <- input$plot_pca2d_hover
    point <- nearPoints(hover_data, hover, threshold = 5, maxpoints = 1, addDist = TRUE)
    if (nrow(point) == 0) return(NULL)

    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    left_px <- left_pct * (hover$range$right - hover$range$left)
    top_px <- top_pct * (hover$range$bottom - hover$range$top)
    
    # create style property fot tooltip
    # background color is set so tooltip is a bit transparent
    # z-index is set so we are sure are tooltip will be on top
    
    if(top_pct > 0.3){
      top_custom <- 10
    }else{
      top_custom <- 200
    }
    
    style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                    "left:", 10, "px; top:", top_custom, "px;")
    # actual tooltip created as wellPanel
    wellPanel(
      style = style,
      p(HTML(paste0("<b> Sample: </b>", point$Sample, "<br/>")))
    )
  })
  
}

#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_pca3d <- function(session, input, output, df, namex, color_list, groupx)
{
  x_transpose <- t(df)
  x_transpose <-data.frame(x_transpose)
  row.names(x_transpose) <- NULL
  x_transpose <-cbind(groupx, x_transpose)
  x_pca <- prcomp(x_transpose[,-1], scale=TRUE)
  test_this <-x_transpose[,1]
  x_gr <- factor(unlist(test_this))
  summary(x_gr)

  create_stats_pca3d <- reactive({
    pca3d(x_pca, 
          group=x_gr,
          new=FALSE,
          legend = "right",
          palette = rev(unique(color_list)), 
          radius = input$stats_pca3d_dot_size,
          title = input$stats_pca3d_title)
  })
  
  output$stats_pca3d <- renderRglwidget ({
    try(rgl.close())
    req(create_stats_pca3d())
    create_stats_pca3d()
    rglwidget()
  })
  
  output$download_stats_pca3d <- downloadHandler(
    filename = function(){
      str_c("stats_pca3d_", dpmsr_set$y$stats$groups$comp_name[as.numeric(input$stats_plot_comp)],
            ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_pca3d())
      snapshotPCA3d(file)
      #ggsave(file, plot = create_stats_pca3d(), device = 'png')
    }
  )
}

#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_cluster <- function(session, input, output, df, namex)
{
  colnames(df) <- namex
  
  df <- t(df)
  df <-data.frame(df)
  #row.names(df) <- NULL
  #df <- na.omit(df)
  df[] <- lapply(df, as.numeric)
  df <- scale(df)
  
  
  create_stats_cluster <- reactive({
    distance <- get_dist(df, method="euclidean")
    fviz_dist(distance,  show_labels = TRUE, gradient = list(low = input$cluster_low_color, mid = "white", high = input$cluster_high_color)) +
      ggtitle(input$stats_cluster_title) +
      theme(plot.title = element_text(hjust = 0.5, size=input$stats_cluster_title_size), 
            axis.text.x = element_text(size=input$stats_cluster_label_size, angle = 90,  color="black"),
            axis.text.y = element_text(size=input$stats_cluster_label_size,  color="black"))
      
  })
  
  output$stats_cluster <- renderPlot({
    req(create_stats_cluster())
    create_stats_cluster()
  })
  
  output$download_stats_cluster <- downloadHandler(
    filename = function(){
      str_c("stats_cluster_", dpmsr_set$y$stats$groups$comp_name[as.numeric(input$stats_plot_comp)],
            ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_cluster())
      ggsave(file, plot = create_stats_cluster(), device = 'png')
    }
  )
}


#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_heatmap <- function(session, input, output, df, namex, groupx)
{
  colnames(df) <- namex
  
  df <- log2(df)
  df <- data.matrix(df)
  
  create_stats_heatmap <- reactive({
    ## Row- and column-wise clustering 
    hr <- hclust(as.dist(1-cor(t(df), method="pearson")), method="complete")
    hc <- hclust(as.dist(1-cor(df, method="spearman")), method="complete") 
    ## Tree cutting
    mycl <- cutree(hr, h=max(hr$height)/1.5); mycolhc <- rainbow(length(unique(mycl)), start=0.1, end=0.9); mycolhc <- mycolhc[as.vector(mycl)] 
    ## Plot heatmap 
    mycol <- redgreen(75)
    #png(filename="erasemyheatmap.png", units="px", width = 1776, height = 1146)  
    heatmap.2(df, Rowv=as.dendrogram(hr), Colv=as.dendrogram(hc), col=mycol, labCol=groupx, 
              scale="row", density.info="none", trace="none", RowSideColors=mycolhc, main = input$stats_heatmap_title) 
  })
  
  output$stats_heatmap <- renderPlot({
    req(create_stats_heatmap())
    create_stats_heatmap()
  })
  
  output$download_stats_heatmap <- downloadHandler(
    filename = function(){
      str_c("stats_heatmap_", dpmsr_set$y$stats$groups$comp_name[as.numeric(input$stats_plot_comp)],
            ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_heatmap())
      png(filename=file, units="px", width = 1776, height = 1146)  
      create_stats_heatmap()
      dev.off()
    }
  )
}

#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------

interactive_stats_volcano <- function(session, input, output, i)
{
  df <- dpmsr_set$data$stats[[dpmsr_set$y$stats$groups$comp_name[i]]]
  df <- subset(df, df[ , dpmsr_set$y$stats$groups$mf[i]] >= input$missing_factor )
  df_fc <- df %>% dplyr::select(contains(dpmsr_set$y$stats$groups$fc[i]))
  df_pval <- df %>% dplyr::select(contains(dpmsr_set$y$stats$groups$pval[i]))
  
  #df_fc <- df %>% dplyr::select(contains(dpmsr_set$y$stats$groups$fc[1]))
  #df_pval <- df %>% dplyr::select(contains(dpmsr_set$y$stats$groups$pval[1]))
  
  df <- cbind(df$Accession, df$Description, df_fc, df_pval)
  colnames(df) <- c("Accession", "Description", "fc", "fc2", "pval")
  df$Accession <- as.character(df$Accession)
  df$Description <- as.character(df$Description)
  df$log_pvalue <- -log(as.numeric(df$pval), 10)
  df$log_fc <- log(as.numeric(df$fc2), 2)
  
  if(input$stats_volcano_fixed_axis){
     xmax <- input$stats_volcano_x_axis
     ymax <- input$stats_volcano_y_axis
  }else{
      xmax <- max(df$log_fc) 
      ymax <- max(df$log_pvalue)
  }
  
  
  volcano_stats_plot <- reactive({
    ggplot(df, aes(x = log_fc, y = log_pvalue)) +
      theme_minimal() +
      geom_point(alpha=0.4, size=input[[str_c("volcano",i,"_stats_plot_dot_size")]], color = input[[str_c("volcano",i,"_stats_dot_color")]] ) +
      xlab(input[[str_c("volcano",i,"_stats_plot_x_axis_label")]]) + 
      ylab(input[[str_c("volcano",i,"_stats_plot_y_axis_label")]]) +
      scale_colour_gradient(low = input[[str_c("volcano", i, "_stats_dot_color")]], high = input[[str_c("volcano", i, "_stats_dot_color")]] ) +
      ggtitle(input[[str_c("volcano",i,"_stats_plot_title")]])+    
      xlim(-xmax, xmax) +
      ylim(0, ymax) +
      theme(plot.title = element_text(size=input[[str_c("volcano",i,"_stats_plot_title_size")]], hjust = 0.5),
            axis.title = element_text(size=input[[str_c("volcano",i,"_stats_plot_label_size")]], color="black"),
            axis.text.x = element_text(size=10, color="black"),
            axis.text.y = element_text(size=10,  color="black"),
            legend.position = "none")+
      geom_vline(aes(xintercept = log(input$foldchange_cutoff, 2)),  linetype = "dotted", color = "black")  + 
      geom_vline(aes(xintercept = -log(input$foldchange_cutoff, 2)),  linetype = "dotted", color = "black")  + 
      geom_hline(aes(yintercept = -log(input$pvalue_cutoff, 10)),  linetype = "dotted", color = "black")  
    
    
  })
  
  plot_name <- str_c("volcano", i, "_stats_plot")
  download_name <- str_c("download_stats_volcano", i)
  hover_name <- str_c("volcano", i, "_stats_hover_info")
  hover_stats_name <- str_c("volcano", i, "_stats_hover")
  
  output[[plot_name]]<- renderPlot({
    req(volcano_stats_plot())
    volcano_stats_plot()
  })
  
  output[[download_name]] <- downloadHandler(
    filename = function(){
      str_c("Volcano_", dpmsr_set$y$stats$groups$comp_name[i], ".png", collapse = " ")
    },
    content = function(file){
      req(volcano_stats_plot())
      ggsave(file, plot = volcano_stats_plot(), device = 'png')
    }
  )
  
  output[[hover_name]] <- renderUI({
    hover <- input[[hover_stats_name]]
    point <- nearPoints(df, hover, threshold = 5, maxpoints = 1, addDist = TRUE)
    if (nrow(point) == 0) return(NULL)
    left_pct <- (hover$x - hover$domain$left) / (hover$domain$right - hover$domain$left)
    top_pct <- (hover$domain$top - hover$y) / (hover$domain$top - hover$domain$bottom)
    
    left_px <- left_pct * (hover$range$right - hover$range$left)
    top_px <- top_pct * (hover$range$bottom - hover$range$top)
    
    #cat(file=stderr(), str_c("top_pct = ", top_pct), "\n")
    #cat(file=stderr(), str_c("top_px = ", top_px), "\n")
    
    if(top_pct > 0.3){
      top_custom <- 10
    }else{
      top_custom <- 200
    }
    
    style <- paste0("position:absolute; z-index:100; background-color: rgba(245, 245, 245, 0.85); ",
                    "left:", 10, "px; top:", top_custom, "px;")
    # actual tooltip created as wellPanel
    wellPanel(
      style = style,
      p(HTML(paste0("<b> Accession: </b>", point$Accession, "<br/>",
                    "<b> Description: </b>", point$Description, "<br/>",
                    "<b> FC: </b>", point$fc, "<br/>",
                    "<b> pvalue: </b>", point$pval, "<br/>")))
    )
  })
}


#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
#match(namesdf, names(df))

interactive_grouped_peptide_barplot <- function(session, input, output, comp_string, df, info_columns, comp_name, peptide_pos_lookup, color_list)
{
  # comp_string <<- comp_string 
  # df <<- df
  # dfb <<- df
  # info_columns <<- info_columns 
  # comp_name  <<- comp_name
  # peptide_pos_lookup <<- peptide_pos_lookup
  # color_list <<- color_list
  

  if(input$stats_use_zscore){  
    updateTextInput(session, "stats_onepeptide_grouped_barplot_title", value = str_c(as.character(input$stats_onepeptide_accession), " - Average Peptide Zscore" )  )
  }else{
    updateTextInput(session, "stats_onepeptide_grouped_barplot_title", value = str_c(as.character(input$stats_onepeptide_accession), " - Average Peptide Intensity" )  )
  }
  
  cat(file=stderr(), "Interactive group barplot...1" , "\n")
  cat(file=stderr(), comp_string , "\n")
  
  cat(file=stderr(), "Interactive group barplot...2" , "\n")
  
  testname <- colnames(df[(info_columns+1):ncol(df)])
  df <- cbind(df$Sequence, df$Modifications, df[(info_columns+1):ncol(df)])
  testname2 <- list(match(testname, names(df)))
  df_test <- gather(df, test, z_score, unlist(testname2))

  colnames(df_test) <- c("Sequence", "Modifications", "Name", "y")
  
  cat(file=stderr(), "Interactive group barplot...3" , "\n")
  cat(file=stderr(), str_c("comp_string = ", comp_string) , "\n")
    
  comp_number <- which(dpmsr_set$y$stats$groups$comp_name == comp_string)
    
  cat(file=stderr(), str_c("comp_number = ", comp_number) , "\n")
    
  stats_data_N <- df_test
  stats_data_D <- df_test
    
  groupN <- unlist(str_split(dpmsr_set$y$stats$groups$comp_N[comp_number], "_"))
  groupD <- unlist(str_split(dpmsr_set$y$stats$groups$comp_D[comp_number], "_"))
    
  cat(file=stderr(), str_c("groupN = ", groupN) , "\n")
  cat(file=stderr(), str_c("groupD = ", groupD) , "\n")
    
  for(stats_group in groupN){stats_data_N <- stats_data_N %>% filter(str_detect(Name, stats_group))   }
  for(stats_group in groupD){stats_data_D <- stats_data_D %>% filter(str_detect(Name, stats_group))   }
  
  #work around to get all samples into a comparison for graphs
  if( groupN  == "All.Samples"){
    stats_data_N  <- df_test %>% filter(stringr::str_detect(Name, input$comp_spqc, negate = TRUE) )
  }
  if( groupD  == "All.Samples"){
    stats_data_D  <- df_test %>% filter(stringr::str_detect(Name, input$comp_spqc, negate = TRUE) )
  }
    
  stats_data_N$Comp <- dpmsr_set$y$stats$groups$comp_N[comp_number]
  stats_data_D$Comp <- dpmsr_set$y$stats$groups$comp_D[comp_number]
  stats_data_N$Order <- "1"
  stats_data_D$Order <- "2"
  
  stats_data_all <- rbind(stats_data_N, stats_data_D)

  cat(file=stderr(), "Interactive group barplot...4" , "\n")
  
  #add spqc to plots
  if(input$stats_onepeptide_plot_spqc){
    stats_data_spqc <- df_test %>% filter(str_detect(Name, dpmsr_set$y$stats$comp_spqc)) 
    stats_data_spqc$Comp <- dpmsr_set$y$stats$comp_spqc
    stats_data_spqc$Order <- "3"
    stats_data_all <- rbind(stats_data_all, stats_data_spqc)
    }
  
  cat(file=stderr(), "Interactive group barplot...5" , "\n")
  new_df <- merge(stats_data_all, peptide_pos_lookup, by="Sequence")
  new_df$Position <- str_c(new_df$Start, "-", new_df$Stop)

  new_df$Name <- NULL
  new_df$Accession <- NULL
  
  new_df$Comp<- as.character(new_df$Comp)
  new_df$Position <- as.character(new_df$Position )
  new_df$Sequence <- as.character(new_df$Sequence)
  
  new_df2 <- new_df %>% group_by(Order, Comp, Sequence, Modifications, Position, Start, Stop) %>% summarise(y_mean=mean(y), sd=sd(y))

  new_df2 <- data.frame(ungroup(new_df2))
  new_df2$Start<- as.numeric(new_df2$Start)
  new_df2$Stop<- as.numeric(new_df2$Stop)
  new_df2 <- new_df2[order(new_df2$Order,new_df2$Start, new_df2$Stop), ]

  new_df2$Position <- as.character(new_df2$Position)
  new_df2_sort <- unique(new_df2$Position)
  new_df2$Position <- factor(new_df2$Position, levels = new_df2_sort)
  
  new_df2$Comp <- as.character(new_df2$Comp)
  new_df2_sort2 <- unique(new_df2$Comp)
  new_df2$Comp <- factor(new_df2$Comp, levels = new_df2_sort2)
  
  new_df2$Label <- str_c(new_df2$Position, "\n", new_df2$Sequence, "\n", new_df2$Modifications)
  new_df2$Label  <- stringr::str_replace_all(new_df2$Label , "Carbamidomethyl", "Carb")
  new_df2$Label  <- stringr::str_replace_all(new_df2$Label , "Oxidation", "Ox")
  new_df2$Label  <- stringr::str_replace_all(new_df2$Label , "Phospho", "Phos")
  new_df2$Label  <- stringr::str_replace_all(new_df2$Label , "\\]", "")
  new_df2$Label  <- stringr::str_replace_all(new_df2$Label , "\\[", "")
  new_df2_sort3 <- unique(new_df2$Label)
  new_df2$Label <- factor(new_df2$Label, levels = new_df2_sort3)

  cat(file=stderr(), "Interactive group barplot...6" , "\n")
  
  color_list <- rep(color_list, nrow(new_df2)/length(color_list))
  xcolor_list <- color_list
  
  if (input$stats_onepeptide_residue > 0){
    new_df2 <- new_df2[(new_df2$Start <= input$stats_onepeptide_residue & new_df2$Stop >= input$stats_onepeptide_residue ),]
  }
  
  # Grouped
  create_stats_barplot <- reactive({
      ggplot(new_df2, aes(fill=Comp, y=y_mean, x=Label   )) + 
        geom_col(color="black", width = 0.5,
                 position=position_dodge(0.5))+
          theme_classic() + 
          ggtitle(input$stats_onepeptide_grouped_barplot_title) + 
          ylab(input$stats_onepeptide_grouped_barplot_y_axis_label) +
          xlab(input$stats_onepeptide_grouped_barplot_x_axis_label) +
          coord_cartesian(ylim=NULL, expand = TRUE) +
          theme(plot.title = element_text(hjust = 0.5, size=input$stats_onepeptide_grouped_barplot_title_size), 
                axis.title = element_text(size=input$stats_onepeptide_grouped_barplot_label_size, color="black"),
                axis.text.x = element_text(size=input$stats_onepeptide_grouped_barplot_label_size, 
                                           angle = input$stats_onepeptide_grouped_barplot_axis_angle, 
                                           vjust = input$stats_onepeptide_grouped_barplot_axis_vjust, color="black"),
                axis.text.y = element_text(size=input$stats_onepeptide_grouped_barplot_label_size,  color="black"),
          ) +
        scale_fill_manual(values = color_list)+
        geom_errorbar(aes(ymin=y_mean -sd, ymax=y_mean+sd), width=.25,
                    position=position_dodge(0.5)) +
        geom_hline(yintercept = 0, linetype="dotted", color = "black")+
        geom_hline(yintercept = 1, linetype="dotted", color = "black")+
        geom_hline(yintercept = -1, linetype="dotted", color = "black")
    
  })
    
     output$stats_onepeptide_grouped_barplot <- renderPlot({
       req(create_stats_barplot())
       create_stats_barplot()
     })
     
     output$download_stats_onepeptide_grouped_barplot <- downloadHandler(
       filename = function(){
         str_c("Grouped_Barplot_", as.character(input$stats_onepeptide_accession), "_", comp_name,  ".png", collapse = " ")
       },
       content = function(file){
         req(create_stats_barplot())
         ggsave(file, plot = create_stats_barplot(), device = 'png')
       }
     )  
    
  
}
  
  


#------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------
#match(namesdf, names(df))

interactive_grouped_barplot <- function(session, input, output, comp_string, df, info_columns, comp_name, peptide_pos_lookup, color_list)
{
  # comp_string <<- comp_string 
  # df <<- df
  # info_columns <<- info_columns 
  # comp_name  <<- comp_name
  # peptide_pos_lookup <<- peptide_pos_lookup
  # color_list <<- color_list
  
  
  if(input$stats_use_zscore){  
    updateTextInput(session, "stats_oneprotein_grouped_barplot_title", value = str_c(as.character(input$stats_oneprotein_accession), " - Average Peptide Zscore" )  )
  }else{
    updateTextInput(session, "stats_oneprotein_grouped_barplot_title", value = str_c(as.character(input$stats_oneprotein_accession), " - Average Peptide Intensity" )  )
  }
  
  cat(file=stderr(), "Interactive group barplot...1" , "\n")
  cat(file=stderr(), comp_string , "\n")
  
  cat(file=stderr(), "Interactive group barplot...2" , "\n")
  
  testname <- colnames(df[(info_columns+1):ncol(df)])
  df <- cbind(df$Sequence, df[(info_columns+1):ncol(df)])
  testname2 <- list(match(testname, names(df)))
  df_test <- gather(df, test, z_score, unlist(testname2))
  
  colnames(df_test) <- c("Sequence", "Name", "y")
  
  cat(file=stderr(), "Interactive group barplot...3" , "\n")
  cat(file=stderr(), str_c("comp_string = ", comp_string) , "\n")
  
  comp_number <- which(dpmsr_set$y$stats$groups$comp_name == comp_string)
  
  cat(file=stderr(), str_c("comp_number = ", comp_number) , "\n")
  
  stats_data_N <- df_test
  stats_data_D <- df_test
  
  groupN <- unlist(str_split(dpmsr_set$y$stats$groups$comp_N[comp_number], "_"))
  groupD <- unlist(str_split(dpmsr_set$y$stats$groups$comp_D[comp_number], "_"))
  
  cat(file=stderr(), str_c("groupN = ", groupN) , "\n")
  cat(file=stderr(), str_c("groupD = ", groupD) , "\n")
  
  for(stats_group in groupN){stats_data_N <- stats_data_N %>% filter(str_detect(Name, stats_group))   }
  for(stats_group in groupD){stats_data_D <- stats_data_D %>% filter(str_detect(Name, stats_group))   }
  
  #work around to get all samples into a comparison for graphs
  if( groupN  == "All.Samples"){
    stats_data_N  <- df_test %>% filter(stringr::str_detect(Name, input$comp_spqc, negate = TRUE) )
  }
  if( groupD  == "All.Samples"){
    stats_data_D  <- df_test %>% filter(stringr::str_detect(Name, input$comp_spqc, negate = TRUE) )
  }
  
  
  stats_data_N$Comp <- dpmsr_set$y$stats$groups$comp_N[comp_number]
  stats_data_D$Comp <- dpmsr_set$y$stats$groups$comp_D[comp_number]
  stats_data_N$Order <- "1"
  stats_data_D$Order <- "2"
  
  stats_data_all <- rbind(stats_data_N, stats_data_D)
  
  cat(file=stderr(), "Interactive group barplot...4" , "\n")
  
  #add spqc to plots
  if(input$stats_oneprotein_plot_spqc){
    stats_data_spqc <- df_test %>% filter(str_detect(Name, dpmsr_set$y$stats$comp_spqc)) 
    stats_data_spqc$Comp <- dpmsr_set$y$stats$comp_spqc
    stats_data_spqc$Order <- "3"
    stats_data_all <- rbind(stats_data_all, stats_data_spqc)
  }
  
  cat(file=stderr(), "Interactive group barplot...5" , "\n")
  new_df <- merge(stats_data_all, peptide_pos_lookup, by="Sequence")
  new_df$Position <- str_c(new_df$Start, "-", new_df$Stop)
  
  new_df$Name <- NULL
  new_df$Accession <- NULL
  
  new_df$Comp<- as.character(new_df$Comp)
  new_df$Position <- as.character(new_df$Position )
  new_df$Sequence <- as.character(new_df$Sequence)
  
  new_df2 <- new_df %>% group_by(Order, Comp, Sequence, Position, Start, Stop) %>% summarise(y_mean=mean(y), sd=sd(y))
  
  new_df2 <- data.frame(ungroup(new_df2))
  new_df2$Start<- as.numeric(new_df2$Start)
  new_df2$Stop<- as.numeric(new_df2$Stop)
  new_df2 <- new_df2[order(new_df2$Order,new_df2$Start, new_df2$Stop), ]
  
  new_df2$Position <- as.character(new_df2$Position)
  new_df2_sort <- unique(new_df2$Position)
  new_df2$Position <- factor(new_df2$Position, levels = new_df2_sort)
  
  new_df2$Comp <- as.character(new_df2$Comp)
  new_df2_sort2 <- unique(new_df2$Comp)
  new_df2$Comp <- factor(new_df2$Comp, levels = new_df2_sort2)
  
  cat(file=stderr(), "Interactive group barplot...6" , "\n")
  
  color_list <- rep(color_list, nrow(new_df2)/length(color_list))
  xcolor_list <- color_list
  
  xnew_df2 <<- new_df2
  
  # Grouped
  create_stats_barplot <- reactive({
    ggplot(new_df2, aes(fill=Comp, y=y_mean, x=Position   )) + 
      geom_col(color="black", width = 0.5,
               position=position_dodge(0.5))+
      theme_classic() + 
      ggtitle(input$stats_oneprotein_grouped_barplot_title) + 
      ylab(input$stats_oneprotein_grouped_barplot_y_axis_label) +
      xlab(input$stats_oneprotein_grouped_barplot_x_axis_label) +
      coord_cartesian(ylim=NULL, expand = TRUE) +
      theme(plot.title = element_text(hjust = 0.5, size=input$stats_oneprotein_grouped_barplot_title_size), 
            axis.title = element_text(size=input$stats_oneprotein_grouped_barplot_label_size, color="black"),
            axis.text.x = element_text(size=input$stats_oneprotein_grouped_barplot_label_size, angle = 90,  color="black"),
            axis.text.y = element_text(size=input$stats_oneprotein_grouped_barplot_label_size,  color="black"),
      ) +
      scale_fill_manual(values = color_list)+
      geom_errorbar(aes(ymin=y_mean -sd, ymax=y_mean+sd), width=.25,
                    position=position_dodge(0.5)) +
      geom_hline(yintercept = 0, linetype="dotted", color = "black")+
      geom_hline(yintercept = 1, linetype="dotted", color = "black")+
      geom_hline(yintercept = -1, linetype="dotted", color = "black")
    
  })
  
  output$stats_oneprotein_grouped_barplot <- renderPlot({
    req(create_stats_barplot())
    create_stats_barplot()
  })
  
  output$download_stats_oneprotein_grouped_barplot <- downloadHandler(
    filename = function(){
      str_c("Grouped_Barplot_", as.character(input$stats_oneprotein_accession), "_", comp_name,  ".png", collapse = " ")
    },
    content = function(file){
      req(create_stats_barplot())
      ggsave(file, plot = create_stats_barplot(), device = 'png')
    }
  )  
  
  
}