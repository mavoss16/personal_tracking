library(quarto)
quarto_publish_app(
  input = "podcasts/podcast_data_analysis_shiny.qmd",
  server = "shinyapps.io",
  name = "mjv_podcasts",
  account = "mavoss",
  forceUpdate = TRUE,
  appFiles = c(
    "podcast_data_analysis_shiny.qmd",
    "podcast_data_analysis_shiny.html",
    "podcast_data.rds",
    "podcast_data_analysis_shiny_data/data_chunks_index.txt",
    "podcast_data_analysis_shiny_data/unnamed-chunk-2.RData"
  )
)
