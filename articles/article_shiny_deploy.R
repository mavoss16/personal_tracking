options(repos = c(CRAN = "https://cran.rstudio.com/")) 

library(quarto)

setwd("C:/Users/mavos/OneDrive/notion_analysis/articles")
quarto_publish_app(
  input = "article_data_analysis_shiny.qmd",
  server = "shinyapps.io",
  name = "mjv_articles",
  account = "mavoss",
  render = "server",
  forceUpdate = TRUE,
  appFiles = c(
    "article_data_analysis_shiny.qmd",
    "article_data_analysis_shiny.html",
    "article_data.rds",
    "data_chunks_index.txt",
    "unnamed-chunk-2.RData"
  )
)
