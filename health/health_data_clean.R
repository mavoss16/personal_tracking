
library(DBI)
library(readr)
library(dplyr)
library(ggplot2)
library(purrr)
library(lubridate)
library(zoo)


db_folder <- file.path("C:", "Users", "mavos", "HealthData", "DBs")

con_summary <- dbConnect(RSQLite::SQLite(), file.path(db_folder, "garmin_summary.db"))

data <- dbReadTable(con_summary, "days_summary") 


# Notable daily_summary variables:
#   hr_avg, hr_max, rhr_avg, inactive_hr_avg, intensity_time, steps, floors, 
#   sleep_avg, rem_sleep_avg, stress_avg, calories_avg,
#   activities, activities_distance,
#   rr_waking_avg
days_summary <- data |>
  mutate(
    date = ymd(day),
    year = year(date),
    month = month(date),
    weekday = wday(date, label = TRUE),
    sleep = (as.duration(hms(sleep_avg)) |> as.numeric()) / 3600,
    sleep = ifelse(sleep == 0, yes = NA, no = sleep),
    rem_sleep = (as.duration(hms(rem_sleep_avg)) |> as.numeric()) / 3600,
    across(
      c(steps, floors, sleep, hr_avg, hr_max, rhr_avg, inactive_hr_avg, rem_sleep, rr_waking_avg),
      function(x){rollmean(x, 7, fill = c(NA, "extend", NA))},
      .names = "{.col}_roll7d"
    ),
    across(
      c(steps, floors, sleep, hr_avg, hr_max, rhr_avg, inactive_hr_avg, rem_sleep, rr_waking_avg),
      function(x){rollmean(x, 30, fill = c(NA, "extend", NA))},
      .names = "{.col}_roll30d"
    )
  )


# View(days_summary |> select(date, steps, floors, sleep, hr_avg, hr_max, rhr_avg, inactive_hr_avg, rem_sleep, contains("roll")))
# 
# 
# ggplot(days_summary, aes(x = date, y = rhr_avg_roll7d)) +
#   geom_line() +
#   theme_minimal()
# 
# ggplot(days_summary, aes(x = date, y = rhr_avg_roll30d)) +
#   geom_line() +
#   theme_minimal()


write_rds(days_summary, "C:/Users/mavos/Documents/GitHub/personal_tracking/health/daily_health_summary.rds")
# write_rds(days_summary, "health/MV_health/daily_health_summary.rds")
