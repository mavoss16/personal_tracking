# Get podcast data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(tidyr)

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
    properties.Podcast.select.color
  )

names(df) <- c("id", "episode_title", "podcast", "date_published", "date_listened", "minutes_listened", "url", "category_color")


data <- df |>
  mutate(
    date_published = ymd(date_published),
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


# Group by podcast
podcast_summary <- data |>
  group_by(podcast) |>
  summarize(
    total_minutes = sum(minutes_listened, na.rm = TRUE),
    total_hours = sum(hours_listened, na.rm = TRUE), 
    total_episodes = n(), 
    avg_days_before_listen = mean(time_after_publish, na.rm = TRUE) |> round(2),
    category = unique(category)
  ) |>
  mutate(avg_ep_minutes = (total_minutes/total_episodes) |> round(2))


# Create base date df
dates <- data.frame(date_listened = min(data$date_listened):Sys.Date() |> as_date()) |>
  mutate(
    year_listened = year(date_listened),
    month_listened = month(date_listened, label = TRUE),
    wday_listened = wday(date_listened, label = TRUE)
  )
# Group by date - initial date calculations
date_summary <- data |>
  group_by(date_listened, year_listened, month_listened, wday_listened) |>
  summarize(
    total_minutes = sum(minutes_listened, na.rm = TRUE),
    total_hours = sum(hours_listened, na.rm = TRUE), 
    total_episodes = n()
  ) |>
  mutate(avg_ep_minutes = total_minutes/total_episodes) 
# Add in days without listening to any podcasts + calculations for calendar heatmap
date_summary <- left_join(dates, date_summary) |>
  mutate(
    total_minutes = replace_na(total_minutes, 0),
    total_hours = replace_na(total_hours, 0),
    total_episodes = replace_na(total_episodes, 0)
  ) |>
  mutate(
    year_month = factor(as.yearmon(date_listened)),
    week = week(date_listened)
  ) |>
  filter(year_month != "Feb 2023") |>
  group_by(year_month) |>
  mutate(month_week = 1 + week - min(week)) |>
  ungroup()


# Group by weekday
wday_summary <- date_summary |>
  group_by(wday_listened) |>
  summarize( 
    avg_minutes = mean(total_minutes, na.rm = TRUE) |> round(2),
    total_minutes = sum(total_minutes, na.rm = TRUE),
    avg_hours = mean(total_hours, na.rm = TRUE) |> round(2),
    total_hours = sum(total_hours, na.rm = TRUE),
    avg_episodes = mean(total_episodes, na.rm = TRUE) |> round(2),
    total_episodes = sum(total_episodes, na.rm = TRUE)
  ) |>
  mutate(avg_ep_minutes = (total_minutes/total_episodes) |> round(2))

library(readr)
write_rds(data, "podcasts/podcast_data.rds")
write_rds(podcast_summary, "podcasts/podcast_summary.rds")
write_rds(date_summary, "podcasts/podcast_date_summary.rds")
write_rds(wday_summary, "podcasts/podcast_wday_summary.rds")


# ask <- GET(
#   url = "https://api.notion.com/v1/databases/4b65ebb0ce37442eb862954d1dd8fa1c/query",
#   add_headers(
#     "Authorization" = paste("Bearer", token),
#     "Notion-Version" = "2022-06-28"
#   )
# )
# 
# 
# 
# 
# ask <- GET(
#   url = "https://api.notion.com/v1/databases/",
#   add_headers(
#     "Authorization" = paste("Bearer", token),
#     "Notion-Version" = "2022-06-28"
#   )
# )
# stop_for_status(ask)
# fromJSON(rawToChar(ask$content))

