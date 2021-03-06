run_wiki <- function(session, input, output){
  
  comp_string <- input$select_data_comp_wiki
  comp_number <- which(grepl(comp_string, dpmsr_set$y$stats$groups$comp_name))
  
  cat(file=stderr(), str_c("Run wiki...1" ), "\n")
  
  data_in <- dpmsr_set$data$stats[[comp_string]]

  if(input$wiki_direction == 'Up') {
    go_df <- subset(data_in, data_in$Stats == "Up" ) 
  }else if (input$wiki_direction == 'Down') {
    go_df <- subset(data_in, data_in$Stats == "Down" ) 
  }else{
    go_df <- subset(data_in, data_in$Stats == "Up" | data_in$Stats == "Down") 
  }

  cat(file=stderr(), str_c("Run wiki...2" ), "\n")
  atest <- go_df$Accession

  test.df <- bitr(atest, fromType = "UNIPROT",
                  toType = c("ENTREZID", "ENSEMBL", "SYMBOL","GENENAME","PATH", "ONTOLOGY"),
                  OrgDb = dpmsr_set$pathway$tax_db)
  
  cat(file=stderr(), str_c("Run wiki...3" ), "\n")
  universe.df <- bitr(data_in$Accession, fromType = "UNIPROT",
                   toType = c("ENTREZID", "ENSEMBL", "SYMBOL","GENENAME","PATH", "ONTOLOGY"),
                   OrgDb = dpmsr_set$pathway$tax_db)
  
 # wp2gene <<- gmt_get(tax_choice)
  
  #wp2gene <- read.gmt(wpgmtfile)
  #dpmsr_set$pathway$wp2gene <<-   dpmsr_set$pathway$wp2gene %>% tidyr::separate(ont, c("name","version","wpid","org"), "%")
  cat(file=stderr(), str_c("Run wiki...4" ), "\n")
  wpid2gene <-   dpmsr_set$pathway$wp2gene %>% dplyr::select(wpid, gene) #TERM2GENE
  wpid2name <-   dpmsr_set$pathway$wp2gene %>% dplyr::select(wpid, name) #TERM2NAME
  
  cat(file=stderr(), str_c("Run wiki...5" ), "\n")
  ewp <- enricher(gene=test.df$ENTREZID, universe=universe.df$ENTREZID, TERM2GENE = wpid2gene, TERM2NAME = wpid2name)
  ewp <- setReadable(ewp, dpmsr_set$pathway$tax_db, keyType = "ENTREZID")
  
  cat(file=stderr(), str_c("Run wiki...6" ), "\n")
  Simple_Excel(ewp@result, str_c(dpmsr_set$file$string, "Wiki_", input$select_data_comp_wiki, "_", 
                          input$select_ont_wiki,input$select_level_wiki, ".xlsx", collapse = " "))
  #ggo_result <<- ggo@result[1:5]
  #ggo_result <- ggo_result[order(-ggo_result$Count),]
  return(ewp@result)
}



run_profile <- function(session, input, output){
  
  comp_string <- input$select_data_comp_profile
  comp_number <- which(grepl(comp_string, dpmsr_set$y$stats$groups$comp_name))
  
  cat(file=stderr(), str_c("Run go profile..." ), "\n")
  
  data_in <- dpmsr_set$data$stats[[comp_string]]
  
  if(input$profile_direction == 'Up') {
    go_df <- subset(data_in, data_in$Stats == "Up" ) 
  }else if (input$profile_direction == 'Down') {
    go_df <- subset(data_in, data_in$Stats == "Down" ) 
  }else{
    go_df <- subset(data_in, data_in$Stats == "Up" | data_in$Stats == "Down") 
  }
  
  atest <- go_df$Accession
  
  test.df <- bitr(atest, fromType = "UNIPROT",
                  toType = c("ENTREZID", "ENSEMBL", "SYMBOL","GENENAME","PATH", "ONTOLOGY"),
                  OrgDb = dpmsr_set$pathway$tax_db)
  
  ggo <- groupGO(gene     = test.df$ENTREZID,
                 OrgDb    = dpmsr_set$pathway$tax_db,
                 ont      = input$select_ont_profile,
                 level    = as.numeric(input$select_level_profile),
                 readable = TRUE) 
  
  Simple_Excel(ggo, str_c(dpmsr_set$file$string, "GO_Profile_", input$select_data_comp_profile, "_", 
                          input$select_ont_profile,input$select_level_profile, ".xlsx", collapse = " "))
  #ggo_result <<- ggo@result[1:5]
  #ggo_result <- ggo_result[order(-ggo_result$Count),]
  return(ggo)
}