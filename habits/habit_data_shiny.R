# Get habit data from Notion using notionR package
# Author: Matthew Voss

library(dplyr)
library(notionR) # https://github.com/Eflores89/notionR
library(lubridate)
library(zoo)
library(tidyr)
library(stringr)
library(purrr)

# Daily Habits
token <- Sys.getenv("NOTION_TOKEN_SHINY")
database_id <- "f82fbc4056864f8b94e5c4ea6e4c4956"

orig <- getNotionDatabase(
  secret = token,
  database = database_id
)

df <- orig |>
  select(
    id,
    created_time,
    `properties.Exercise.checkbox`,
    `properties.Step Goal.checkbox`,
    `properties.Stair Goal.checkbox`,
    `properties.Reading.checkbox`,
    `properties.Project.checkbox`,
    `properties.To-Dos.checkbox`,
    `properties.E-Bike Ride.checkbox`,
    `properties.Activity Summary.rich_text.plain_text`
  )

names(df) <- c("id", "datetime", "exercise", "step_goal", "stair_goal", "reading", "project", "todos", "ebike", "summary")


data <- df |>
  mutate(
    datetime = as_datetime(datetime) |> with_tz(tzone = "America/Chicago"),
    date = as_date(force_tz(datetime, tzone = "UTC") |> as_date()),
    year = year(date),
    month = month(date, label = TRUE),
    wday = wday(date, label = TRUE),
    .after = date
  )

text <- data |>
  select(id, date, summary) |>
  mutate(
    exercise_text = str_extract(summary, "Exercise: [^;]+"),
    reading_text = str_extract(summary, "Reading: [^;]+"),
    project_text = str_extract(summary, "[a-zA-Z ]+ Project: [^;]+"),
    todo_text = str_extract(summary, "To-Dos: [^;]+")
  ) |>
  rowwise() |>
  mutate(
    num_pages = str_extract_all(reading_text, "\\d+") |> flatten() |> list_simplify() |> as.numeric() |> sum()
  ) |>
  ungroup()

habit_data <- left_join(data, text)


library(readr)
write_rds(habit_data, "C:/Users/mavos/Documents/GitHub/personal_tracking/habits/habit_data.rds")
