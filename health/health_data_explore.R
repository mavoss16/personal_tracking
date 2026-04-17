


library(DBI)
library(readr)
library(dplyr)
library(ggplot2)
library(purrr)


db_folder <- file.path("C:", "Users", "mavos", "HealthData", "DBs")

files <- list.files(db_folder)

db_data <- data.frame()
for(file in files){
  print(file)
  con <- dbConnect(RSQLite::SQLite(), file.path(db_folder, file))
  tables <- dbListTables(con)
  
  con_data <- data.frame(file = rep(file, length.out = length(table)), table = tables)
  db_data <- bind_rows(db_data, con_data)
  dbDisconnect(con)
  Sys.sleep(1)
}



cons <- map(files, function(x){dbConnect(RSQLite::SQLite(), file.path(db_folder, x))})
names(cons) <- files

activities <- dbReadTable(cons$garmin_activities.db, "activities")

monitoring_hr <- dbReadTable(cons$garmin_monitoring.db, "monitoring_hr")


library(janitor)
library(zoo)

# Note: days_summary is same in garmin_summary.db and summary.db
daily_summary <- dbReadTable(cons$garmin_summary.db, "days_summary") |>
  mutate(
    date = ymd(day),
    year = year(date),
    month = month(date),
    weekday = wday(date, label = TRUE),
    steps_roll7d = rollmean(steps, 7, fill = c(NA, "extend", NA)),
    steps_roll30d = rollmean(steps, 30, fill = c(NA, "extend", NA))
  ) |>
  mutate(
    sleep_duration = (as.duration(hms(sleep_avg)) |> as.numeric()) / 3600,
    sleep_roll7d = rollmean(sleep_duration, 7, fill = c(NA, "extend", NA)),
    sleep_roll30d = rollmean(sleep_duration, 30, fill = c(NA, "extend", NA))
  )

# Notable daily_summary variables:
#   hr_avg, hr_max, rhr_avg, inactive_hr_avg, intensity_time, steps, floors, 
#   sleep_avg, rem_sleep_avg, stress_avg, calories_avg,
#   activities, activities_distance,
#   rr_waking_avg

ggplot(daily_summary, aes(x = date, y = steps_roll7d)) +
  geom_line() +
  theme_minimal()

ggplot(daily_summary, aes(x = date, y = steps_roll30d)) +
  geom_line() +
  theme_minimal()

ggplot(daily_summary, aes(x = date, y = sleep_roll7d)) +
  geom_line() +
  scale_y_continuous(limits = c(0, 9)) +
  theme_minimal()

ggplot(daily_summary, aes(x = date, y = sleep_roll30d)) +
  geom_line() +
  theme_minimal()


weeks_summary <- dbReadTable(cons$garmin_summary.db, "weeks_summary") |>
  mutate(
    date = ymd(first_day),
    year = year(date),
    month = month(date),
    sleep_duration = (as.duration(hms(sleep_avg)) |> as.numeric()) / 3600
  )

ggplot(weeks_summary, aes(x = date, y = sleep_duration)) +
  geom_line() +
  scale_y_continuous(limits = c(0, 9)) +
  theme_minimal()

months_summary <- dbReadTable(cons$garmin_summary.db, "months_summary") |>
  mutate(
    date = ymd(first_day),
    year = year(date),
    month = month(date),
    sleep_duration = (as.duration(hms(sleep_avg)) |> as.numeric()) / 3600
  )

ggplot(months_summary, aes(x = date, y = sleep_duration)) +
  geom_line() +
  theme_minimal()
