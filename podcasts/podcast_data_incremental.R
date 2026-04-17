# Get recent podcast data from Notion and merge with existing dataset
# Incremental version of podcast_data.R — fetches last 5 days only
# Author: Matthew Voss

library(dplyr)
library(notionR)
library(lubridate)
library(zoo)
library(tidyr)
library(readr)

token <- Sys.getenv("NOTION_TOKEN")
database_id <- "4b65ebb0ce37442eb862954d1dd8fa1c"
days_back <- 5


# Fetch recent pages from Notion ---------------------------------------------

cutoff <- format(Sys.Date() - days_back, "%Y-%m-%dT00:00:00Z")

raw_new <- getNotionDatabase(
  secret = token,
  database = database_id,
  filters = list(
    timestamp = "created_time",
    created_time = list(on_or_after = cutoff)
  )
)

message("Fetched ", nrow(raw_new), " new/recent records from Notion.")


# Parse into same shape as podcast_data.R ------------------------------------

df_new <- raw_new |>
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

names(df_new) <- c("id", "episode_title", "podcast", "date_published", "date_listened", "minutes_listened", "url", "category_color")

new_data <- df_new |>
  mutate(
    date_published = ymd(date_published),
    category = case_when(
      category_color == "purple" ~ "Politics",
      category_color == "blue"   ~ "Iowa",
      category_color == "red"    ~ "Sports",
      category_color == "yellow" ~ "Lifestyle",
      category_color == "orange" ~ "Economics",
      category_color == "green"  ~ "Science",
      category_color == "gray"   ~ "Other",
      category_color == "brown"  ~ "History",
      TRUE ~ NA_character_
    ),
    minutes_listened = as.numeric(minutes_listened)
  ) |>
  mutate(
    datetime_listened = as_datetime(date_listened) |> with_tz(tzone = "America/Chicago"),
    date_listened = as_date(force_tz(datetime_listened, tzone = "UTC") |> as_date()),
    year_listened  = year(date_listened),
    month_listened = month(date_listened, label = TRUE),
    wday_listened  = wday(date_listened, label = TRUE),
    hour_listened  = hour(datetime_listened),
    time_after_publish = date_listened - date_published,
    .after = date_listened
  ) |>
  mutate(hours_listened = round(minutes_listened / 60, digits = 2))


# Merge with existing data ---------------------------------------------------

existing <- read_rds("podcasts/podcast_data.rds")
cutoff_date <- Sys.Date() - days_back

# Drop existing rows from the fetch window (replaced by fresh data)
existing_trimmed <- existing |> filter(date_listened < cutoff_date)

data <- bind_rows(existing_trimmed, new_data) |>
  arrange(date_listened)

message(
  "Merged: ", nrow(existing_trimmed), " kept + ",
  nrow(new_data), " new = ", nrow(data), " total rows."
)


# Recompute summaries (same logic as podcast_data.R) -------------------------

podcast_summary <- data |>
  group_by(podcast) |>
  summarize(
    total_minutes = sum(minutes_listened, na.rm = TRUE),
    total_hours   = sum(hours_listened, na.rm = TRUE),
    total_episodes = n(),
    avg_days_before_listen = mean(time_after_publish, na.rm = TRUE) |> round(2),
    category = unique(category)
  ) |>
  mutate(avg_ep_minutes = (total_minutes / total_episodes) |> round(2))


dates <- data.frame(date_listened = min(data$date_listened):Sys.Date() |> as_date()) |>
  mutate(
    year_listened  = year(date_listened),
    month_listened = month(date_listened, label = TRUE),
    wday_listened  = wday(date_listened, label = TRUE)
  )

date_summary <- data |>
  group_by(date_listened, year_listened, month_listened, wday_listened) |>
  summarize(
    total_minutes  = sum(minutes_listened, na.rm = TRUE),
    total_hours    = sum(hours_listened, na.rm = TRUE),
    total_episodes = n()
  ) |>
  mutate(avg_ep_minutes = total_minutes / total_episodes)

date_summary <- left_join(dates, date_summary) |>
  mutate(
    total_minutes  = replace_na(total_minutes, 0),
    total_hours    = replace_na(total_hours, 0),
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


wday_summary <- date_summary |>
  group_by(wday_listened) |>
  summarize(
    avg_minutes    = mean(total_minutes, na.rm = TRUE) |> round(2),
    total_minutes  = sum(total_minutes, na.rm = TRUE),
    avg_hours      = mean(total_hours, na.rm = TRUE) |> round(2),
    total_hours    = sum(total_hours, na.rm = TRUE),
    avg_episodes   = mean(total_episodes, na.rm = TRUE) |> round(2),
    total_episodes = sum(total_episodes, na.rm = TRUE)
  ) |>
  mutate(avg_ep_minutes = (total_minutes / total_episodes) |> round(2))


# Write outputs --------------------------------------------------------------

write_rds(data,             "podcasts/podcast_data.rds")
write_rds(podcast_summary,  "podcasts/podcast_summary.rds")
write_rds(date_summary,     "podcasts/podcast_date_summary.rds")
write_rds(wday_summary,     "podcasts/podcast_wday_summary.rds")

message("Done. RDS files updated.")
