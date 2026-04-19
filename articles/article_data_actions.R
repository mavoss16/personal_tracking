# Get reading data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(stringr)
library(readr)

token <- Sys.getenv("NOTION_TOKEN_SHINY")
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

write_rds(data, "articles/article_data.rds")
