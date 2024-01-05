# Get podcast data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(tidyr)

setwd("C:/Users/mavos/OneDrive/notion_analysis/podcasts")


# Daily Listening
# https://www.notion.so/4b65ebb0ce37442eb862954d1dd8fa1c?v=4166c2a6b45a433ba19a45dc4940c780
token <- "secret_lO3gKIZIMpzcRUeRt6hKZwxcUB4t9yvGwpWTXbNIQSP"
database_id <- "4b65ebb0ce37442eb862954d1dd8fa1c"

orig <- getNotionDatabase(
  secret = token,
  database = database_id
)

df <- orig |>
  select(
    id, 
    `properties.Episode Title.title.plain_text`,
    `properties.Podcast.select.name`,
    `properties.Date Published.date.start`,
    `properties.Date Listened.created_time`,
    `properties.Minutes Listened.number`,
    properties.URL.url,
    properties.Podcast.select.color,
    `properties.Topic Override.select.color`
  )

names(df) <- c("id", "episode_title", "podcast", "date_published", "date_listened", "minutes_listened", "url", "category_color", "override_color")


data <- df |>
  mutate(
    date_published = ymd(date_published),
    category_color = ifelse(is.na(override_color), yes = category_color, no = override_color),
    category = case_when(
      category_color == "purple" ~ "Politics",
      category_color == "blue" ~ "Iowa",
      category_color == "red" ~ "Sports",
      category_color == "yellow" ~ "Lifestyle",
      category_color == "orange" ~ "Economics",
      category_color == "green" ~ "Science",
      category_color == "gray" ~ "Other",
      category_color == "brown" ~ "History",
      TRUE ~ NA_character_
    ),
    minutes_listened = as.numeric(minutes_listened)
  ) |>
  mutate(
    datetime_listened = as_datetime(date_listened) |> with_tz(tzone = "America/Chicago"),
    date_listened = as_date(force_tz(datetime_listened, tzone = "UTC") |> as_date()),
    year_listened = year(date_listened),
    month_listened = month(date_listened, label = TRUE),
    wday_listened = wday(date_listened, label = TRUE),
    hour_listened = hour(datetime_listened),
    time_after_publish = date_listened - date_published,
    .after = date_listened
  ) |>
  mutate(
    hours_listened = round(minutes_listened/60, digits = 2)
  )


library(readr)
write_rds(data, "podcast_data.rds")

