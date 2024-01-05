# Get reading data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(stringr)
library(rsconnect)

setwd("C:/Users/mavos/OneDrive/notion_analysis/articles")
# Daily Reading
# https://www.notion.so/4b65ebb0ce37442eb862954d1dd8fa1c?v=4166c2a6b45a433ba19a45dc4940c780
# https://www.notion.so/99e0b70084994976b066dc2ead02e176?v=a607576a249a4bb091248c94adb68274
token <- "secret_lO3gKIZIMpzcRUeRt6hKZwxcUB4t9yvGwpWTXbNIQSP"
database_id <- "99e0b70084994976b066dc2ead02e176"

orig <- getNotionDatabase(
  secret = token,
  database = database_id
)

df <- orig |>
  select(
    id, 
    `properties.Name.title.plain_text`,
    properties.URL.url,
    `properties.Date Read.created_time`
  )

names(df) <- c("id", "article_title", "url", "date_read")


data <- df |>
  mutate(
    publisher = str_remove_all(url, "https://") |>
      str_remove_all("www\\.") |>
      str_extract("[a-z0-9]+\\.") |>
      str_sub(1, -2)
  ) |>
  mutate(
    datetime_read = as_datetime(date_read) |> with_tz(tzone = "America/Chicago"),
    date_read = as_date(force_tz(datetime_read, tzone = "UTC") |> as_date()),
    year_read = year(date_read),
    month_read = month(date_read, label = TRUE),
    wday_read = wday(date_read, label = TRUE),
    hour_read = hour(datetime_read),
    .after = date_read
  )



library(readr)
write_rds(data, "article_data.rds")

# od <- get_personal_onedrive()
# od$list_items()
# 
# deployApp(
#   appDir = "articles",
#   appFiles = c(
#     "article_data_analysis_shiny.qmd",
#     "article_data_analysis_shiny.html",
#     "article_data.rds",
#     "article_data_analysis_shiny_data/data_chunks_index.txt",
#     "article_data_analysis_shiny_data/unnamed-chunk-2.RData"
#   ),
#   appPrimaryDoc = "article_data_analysis_shiny.qmd",
#   appName = "mjv_articles",
#   quarto = TRUE
# )


