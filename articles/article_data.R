# Get reading data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(tidyr)
library(stringr)
library(Microsoft365R)

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
write_rds(data, "articles/article_data.rds")

# od <- get_personal_onedrive()
# od$list_items()
# 


# Code below is now in shiny apps -----------------------------------------

# # Group by podcast
# publisher_summary <- data |>
#   group_by(publisher) |>
#   summarize(
#     total_articles = n()
#   )
# 
# 
# # Create base date df
# dates <- data.frame(date_read = min(data$date_read):Sys.Date() |> as_date()) |>
#   mutate(
#     year_read = year(date_read),
#     month_read = month(date_read, label = TRUE),
#     wday_read = wday(date_read, label = TRUE)
#   )
# # Group by date - initial date calculations
# date_summary <- data |>
#   group_by(date_read, year_read, month_read, wday_read) |>
#   summarize(
#     total_articles = n()
#   )
# # Add in days without listening to any podcasts + calculations for calendar heatmap
# date_summary <- left_join(dates, date_summary) |>
#   mutate(
#     total_articles = replace_na(total_articles, 0)
#   ) |>
#   mutate(
#     year_month = factor(as.yearmon(date_read)),
#     week = week(date_read)
#   ) |>
#   filter(year_month != "Feb 2023") |>
#   group_by(year_month) |>
#   mutate(month_week = 1 + week - min(week)) |>
#   ungroup()
# 
# 
# # Group by weekday
# wday_summary <- date_summary |>
#   group_by(wday_read) |>
#   summarize( 
#     avg_articles = mean(total_articles, na.rm = TRUE) |> round(2)
#   )
# 
# 
# 
# 
# write_rds(publisher_summary, "articles/article_publisher_summary.rds")
# write_rds(date_summary, "articles/article_date_summary.rds")
# write_rds(wday_summary, "articles/article_wday_summary.rds")
# 
