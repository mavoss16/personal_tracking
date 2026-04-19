
library(readr)
library(dplyr)
library(tidyr)

library(lubridate)
library(forcats)
library(zoo)
library(stringr)
library(tidytext)
library(pluralize)

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(ggplot2)
library(ggwordcloud)
library(reactable)

source("https://raw.githubusercontent.com/iascchen/VisHealth/master/R/calendarHeat.R")

source("ui_tabs.R")



# daily_health_summary <- read_rds("health/daily_health_summary.rds")
daily_health_summary <- readRDS(url("https://github.com/mavoss16/personal_tracking/raw/master/health/daily_health_summary.rds", "rb"))
orig_podcast_data <- readRDS(url("https://github.com/mavoss16/personal_tracking/raw/master/podcasts/podcast_data.rds"))
orig_article_data <- readRDS(url("https://github.com/mavoss16/personal_tracking/raw/master/articles/article_data.rds", "rb"))
# orig_habit_data <- readRDS(url("https://github.com/mavoss16/personal_tracking/raw/master/habits/habit_data.rds", "rb"))

user_base <- tibble::tibble(
  user = c("mv"),
  password = c("mv"),
  permissions = c("admin"),
  name = c("MV")
)

# Define server logic required to draw a histogram
function(input, output, session) {
  
  credentials <- shinyauthr::loginServer(
    id = "login", data = user_base, user_col = user, pwd_col = password, log_out = reactive(logout_init())
  )
  
  logout_init <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
  
  observeEvent(credentials()$user_auth, {
    # if user logs in successfully
    if (credentials()$user_auth) { 
      # remove the login tab
      removeTab("main_tabs", "login")
      # add home tab 
      appendTab("main_tabs", health_tab, select = TRUE)
      # add data tab
      appendTab("main_tabs", podcast_tab)
      appendTab("main_tabs", article_tab)
      
    }
  })
  
# Health ------------------------------------------------------------

  health_var_function <- function(input){
    case_when(
      input == "Steps" ~ "steps",
      input == "Stairs" ~ "floors",
      input == "Sleep" ~ "sleep",
      input == "Heart Rate Avg." ~ "hr_avg",
      input == "Heart Rate Max." ~ "hr_max",
      input == "Resting HR" ~ "rhr_avg",
      input == "Inactive HR" ~ "inactive_hr_avg",
      input == "REM Sleep" ~ "rem_sleep",
      input == "Respiration Rate" ~ "rr_waking_avg"
    )
  }
  
  # Date Action Buttons
  observe({
    updateDateRangeInput(
      inputId = "health_date_range_input", label = "Select a Date Range:",
      start = "2024-01-01", end = Sys.Date()
    )
  })
  
  daily_health_data <- reactive({
    daily_health_summary |>
      filter(
        date >= min(input$health_date_range_input) & date <= max(input$health_date_range_input)
      )
  })

  health_plot_limits <- reactive({
    c(
      (min(daily_health_summary[health_var_function(input$health_var_input)], na.rm = T) * 0.75),
      (max(daily_health_summary[health_var_function(input$health_var_input)], na.rm = T) * 1.25)
    )
  })
  
  output$health_plot_settings <- renderUI({
    dropdownButton(
      label = "Plot Settings",
      icon = icon("gear"), circle = FALSE,
      sliderInput(
        "health_plot_limits", label = "Select Y-axis Limits",
        min = 0, max = health_plot_limits()[2],
        value = health_plot_limits()
      )
    )
  })
  
  output$health <- renderPlot({
    req(credentials()$user_auth)
    ggplot(daily_health_data(), aes(x = date, y = .data[[health_var_function(input$health_var_input)]])) +
      geom_line() +
      scale_y_continuous(limits = input$health_plot_limits, labels = scales::label_comma()) +
      labs(y = input$health_var_input, x = "Date", title = paste0(input$health_var_input, " vs. Date")) +
      theme_minimal()
  })
  
  output$health_7d <- renderPlot({
    req(credentials()$user_auth)
    ggplot(daily_health_data(), aes(x = date, y = .data[[paste0(health_var_function(input$health_var_input), "_roll7d")]])) +
      geom_line() +
      scale_y_continuous(limits = input$health_plot_limits, labels = scales::label_comma()) +
      labs(y = input$health_var_input, x = "Date", title = paste0(input$health_var_input, " vs. Date, 7-day Rolling Average")) +
      theme_minimal()
  })
  
  output$health_30d <- renderPlot({
    req(credentials()$user_auth)
    ggplot(daily_health_data(), aes(x = date, y = .data[[paste0(health_var_function(input$health_var_input), "_roll30d")]])) +
      geom_line() +
      scale_y_continuous(limits = input$health_plot_limits, labels = scales::label_comma()) +
      labs(y = input$health_var_input, x = "Date", title = paste0(input$health_var_input, " vs. Date, 30-day Rolling Average")) +
      theme_minimal()
  })
  
  output$health_xy <- renderPlot({
    req(credentials()$user_auth)
    ggplot(daily_health_data(), aes(x = .data[[health_var_function(input$health_var_x_input)]], y = .data[[health_var_function(input$health_var_y_input)]])) +
      geom_point() +
      labs(y = input$health_var_y_input, x = input$health_var_x_input) +
      theme_minimal() +
      geom_smooth()
  })
  

# Podcasts ----------------------------------------------------------------

  podcast_sidebar <- renderUI({
    return_html <- fluidPage(
      dateRangeInput(
        "podcast_podcast_date_range_input", label = "Select a Date Range:",
        start = "2023-03-01", end = Sys.Date()
      ),
      checkboxGroupInput(
        "podcast_category_input", label = "Select Categories",
        choices = c("Economics", "History", "Iowa", "Lifestyle", "Politics", "Science", "Sports") |> sort(),
        selected = c("Economics", "History", "Iowa", "Lifestyle", "Politics", "Science", "Sports") |> sort()
      )
    )
    
    return(return_html)
  })
  
  # Date Action Buttons
  observe({
    updateDateRangeInput(
      inputId = "podcast_date_range_input", label = "Select a Date Range:",
      start = Sys.Date() - 7, end = Sys.Date()
    )
  })
  
  observeEvent(input$podcast_current_week_input, {
    updateDateRangeInput(inputId = "podcast_date_range_input", start = floor_date(Sys.Date(), unit = "week"), end = Sys.Date())
  })
  observeEvent(input$podcast_previous_week_input, {
    updateDateRangeInput(inputId = "podcast_date_range_input", start = floor_date(Sys.Date() - 7, unit = "week"), end = floor_date(Sys.Date(), unit = "week") - 1)
  })
  observeEvent(input$podcast_current_month_input, {
    updateDateRangeInput(inputId = "podcast_date_range_input", start = floor_date(Sys.Date(), unit = "month"), end = Sys.Date())
  })
  observeEvent(input$podcast_current_year_input, {
    updateDateRangeInput(inputId = "podcast_date_range_input", start = floor_date(Sys.Date(), unit = "year"), end = Sys.Date())
  })
  observeEvent(input$podcast_full_input, {
    updateDateRangeInput(inputId = "podcast_date_range_input", start = ymd("2023/03/01"), end = Sys.Date())
  })
  
  
  podcast_episode_data <- reactive({

    orig_podcast_data |>
      filter(
        date_listened >= min(input$podcast_date_range_input) & date_listened <= max(input$podcast_date_range_input),
        category %in% input$podcast_category_input
      )
  })
  
  podcast_categories <- reactive({
    podcast_episode_data() |>
      distinct(category, category_color) |>
      filter(!is.na(category) & !is.na(category_color))
  })
  
  # Group by podcast
  podcast_summary <- reactive({
    podcast_episode_data() |>
      group_by(podcast, category) |>
      summarize(
        total_minutes = sum(minutes_listened, na.rm = TRUE),
        total_hours = sum(hours_listened, na.rm = TRUE),
        total_episodes = n(),
        avg_days_before_listen = mean(time_after_publish, na.rm = TRUE) |> round(2),
        category = unique(category)
      ) |>
      mutate(avg_ep_minutes = (total_minutes/total_episodes) |> round(2)) |>
      ungroup()
  })
  
  # Group by podcast category
  podcast_category_summary <- reactive({
    podcast_episode_data() |>
      group_by(category) |>
      summarize(
        total_minutes = sum(minutes_listened, na.rm = TRUE),
        total_hours = sum(hours_listened, na.rm = TRUE),
        total_episodes = n(),
        category = unique(category)
      ) |>
      ungroup()
  })
  
  # Group by date
  podcast_date_summary <- reactive({
    
    # Create base date df
    dates <- data.frame(
      date_listened = min(input$podcast_date_range_input, na.rm = T):max(input$podcast_date_range_input, na.rm = T) |> as.Date()
    ) |>
      mutate(
        year_listened = year(date_listened),
        month_listened = month(date_listened, label = TRUE),
        wday_listened = wday(date_listened, label = TRUE)
      )
    
    
    # Group by date - initial date calculations
    date_summary <- podcast_episode_data() |>
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
        week = epiweek(date_listened),
        week = ifelse(month_listened == "Dec" & week == 1, yes = 53, no = week) # epiweek starts week 1 in December if necessary
      ) |>
      filter(year_month != "Feb 2023") |>
      group_by(year_month) |>
      mutate(month_week = 1 + week - min(week)) |>
      ungroup()
    
    date_summary
  })
  
  output$dates_test <- renderReactable({
    # min(podcast_episode_data()$date_listened, na.rm = T):max(podcast_episode_data()$date_listened, na.rm = T)
    reactable(podcast_date_summary())
  })
  
  # Group by day of week
  podcast_wday_summary <- reactive({
    podcast_date_summary() |>
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
  })
  
  # Wordcloud data
  podcast_wordcloud_data <- reactive({
    
    podcast_episode_data() |>
      select(episode_title) |>
      mutate(
        episode_title = tolower(episode_title) |> 
          str_remove_all("williams & blum|iowa everywhere|two guys named chris|sunday story|on iowa politics|pod|podcast|two guys") |>
          str_remove_all(" - .+$|\\| .+|$") |> 
          str_replace_all("[^a-z]s ", " ") |>
          str_replace_all(" [^a-z ]|[^a-z ] ", " ") |> 
          str_replace_all("[^a-z ]", "")
      ) |>
      unnest_tokens(word, episode_title) |>
      filter(!is.na(word) & !is.null(word)) |>
      anti_join(stop_words |> mutate(word = str_remove_all(word, "[^a-zA-Z]"))) |>
      count(word) |>
      arrange(-n) |>
      slice(1:100)
  })
  
  output$podcast_hours_text <- renderUI({
    hours <- sum(podcast_episode_data()$hours_listened, na.rm = T)
    h5(paste0(hours, " (", (hours/24) |> round(1), " days)"))
  })
  
  output$podcast_days_text <- renderUI({
    h5(paste0(sum(podcast_date_summary()$total_episodes >= 1, na.rm = T), "/", nrow(podcast_date_summary())))
  })
  
  output$podcast_episodes_text <- renderUI({
    h5(nrow(podcast_episode_data()))
  })
  
  output$podcast_table <- renderReactable({
    reactable(
      podcast_summary() |>
        select(podcast, total_hours, total_episodes, avg_ep_minutes, avg_days_before_listen, category),
      columns = list(
        podcast = colDef(name = "Podcast"),
        total_hours = colDef(name = "# Hours"),
        total_episodes = colDef(name = "# Episodes"),
        avg_ep_minutes = colDef(name = "Avg. Episode Length (min)"),
        avg_days_before_listen = colDef(name = "Avg. Days Before Listen", align = "right"),
        category = colDef(name = "Category")
      ),
      filterable = TRUE,
      searchable = TRUE
    )
  })
  
  output$podcast_episode_table <- renderReactable({
    reactable(
      podcast_episode_data() |>
        select(podcast, episode_title, date_published, date_listened, minutes_listened, category),
      columns = list(
        podcast = colDef(name = "Podcast"),
        episode_title = colDef(name = "Episode Name"),
        date_published = colDef(name = "Date Published"),
        date_listened = colDef(name = "Date Listened"),
        minutes_listened = colDef(name = "# Minutes"),
        category = colDef(name = "Category")
      ),
      filterable = TRUE,
      searchable = TRUE
    )
  })
  
  output$podcast_hours_bar <- renderPlot({
    # Nudge vs. just: https://stackoverflow.com/questions/69087133/in-r-ggplot2-vjust-and-nudge-y-can-adjust-text-position-for-vertical-axis
    max_value <- max(podcast_summary()$total_hours) * 1.2
    ggplot(
      podcast_summary() |> arrange(-total_hours) |> slice(1:10), 
      aes(x = fct_reorder(podcast, total_hours), y = total_hours, label = total_hours |> round(1), fill = category)
    ) +
      geom_col() +
      geom_text(aes(y = total_hours/2)) +
      scale_y_continuous(limits = c(0, max_value)) +
      scale_fill_manual(breaks = podcast_categories()$category, values = podcast_categories()$category_color) +
      labs(x = "", y = "", title = "Top Podcasts by Total Hours", fill = "Category") +
      coord_flip() +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  
  output$podcast_episodes_bar <- renderPlot({
    max_value <- max(podcast_summary()$total_episodes) * 1.2
    ggplot(
      podcast_summary() |> arrange(-total_episodes) |> slice(1:10), 
      aes(x = fct_reorder(podcast, total_episodes), y = total_episodes, label = total_episodes, fill = category)
    ) +
      geom_col() +
      geom_text(aes(y = total_episodes/2)) +
      scale_y_continuous(limits = c(0, max_value)) +
      scale_fill_manual(breaks = podcast_categories()$category, values = podcast_categories()$category_color) +
      labs(x = "", y = "", title = "Top Podcasts by Total Episodes", fill = "Category") +
      coord_flip() +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
    
  })
  
  output$podcast_category_hours_bar <- renderPlot({
    # Nudge vs. just: https://stackoverflow.com/questions/69087133/in-r-ggplot2-vjust-and-nudge-y-can-adjust-text-position-for-vertical-axis
    max_value <- max(podcast_category_summary()$total_hours) * 1.2
    ggplot(
      podcast_category_summary() |> arrange(-total_hours), 
      aes(x = fct_reorder(category, total_hours), y = total_hours, label = total_hours |> round(1), fill = category)
    ) +
      geom_col() +
      geom_text(aes(y = total_hours/2)) +
      scale_y_continuous(limits = c(0, max_value)) +
      scale_fill_manual(breaks = podcast_categories()$category, values = podcast_categories()$category_color) +
      labs(x = "", y = "", title = "Top Podcast Categories by Total Hours", fill = "Category") +
      coord_flip() +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  
  output$podcast_category_episodes_bar <- renderPlot({
    max_value <- max(podcast_category_summary()$total_episodes) * 1.2
    ggplot(
      podcast_category_summary() |> arrange(-total_episodes), 
      aes(x = fct_reorder(category, total_episodes), y = total_episodes, label = total_episodes, fill = category)
    ) +
      geom_col() +
      geom_text(aes(y = total_episodes/2)) +
      scale_y_continuous(limits = c(0, max_value)) +
      scale_fill_manual(breaks = podcast_categories()$category, values = podcast_categories()$category_color) +
      labs(x = "", y = "", title = "Top Podcast Categories by Total Episodes", fill = "Category") +
      coord_flip() +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
    
  })
  
  
  output$podcast_wdays_hours_bar <- renderPlot({
    ggplot(
      podcast_wday_summary(),
      aes(x = fct_rev(wday_listened), y = avg_hours, label = avg_hours |> round(1))
    ) +
      geom_col(fill = "lightblue", color = "black") +
      geom_text(aes(y = avg_hours/2)) +
      labs(x = "", y = "", title = "Days of the Week by Average Hours per Day") +
      coord_flip() +
      theme_minimal()
  })
  
  
  output$podcast_wdays_episodes_bar <- renderPlot({
    ggplot(
      podcast_wday_summary(),
      aes(x = fct_rev(wday_listened), y = avg_episodes, label = avg_episodes |> round(1))
    ) +
      geom_col(fill = "lightblue", color = "black") +
      geom_text(aes(y = avg_episodes/2)) +
      labs(x = "", y = "", title = "Days of the Week by Average Episodes per Day") +
      coord_flip() +
      theme_minimal()
  })
  
  
  output$podcast_hours_calendar <- renderPlot({
    ggplot(podcast_date_summary(), aes(x = wday_listened, y = -month_week, label = total_hours, fill = total_hours)) +
      geom_tile(color = "white") +
      geom_text() +
      facet_grid(month_listened~year_listened) +
      scale_fill_gradient(low = "red", high = "green") +
      scale_y_continuous() +
      labs(title = "Calendar Heatmap - Hours Listened", fill = "Hours") +
      theme_bw() +
      theme(
        axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  
  output$podcast_episodes_calendar <- renderPlot({
    ggplot(podcast_date_summary(), aes(x = wday_listened, y = -month_week, label = total_episodes, fill = total_episodes)) +
      geom_tile(color = "white") +
      geom_text() +
      facet_grid(month_listened~year_listened) +
      scale_fill_gradient(low = "red", high = "green") +
      scale_y_continuous() +
      labs(title = "Calendar Heatmap - Episodes Listened", fill = "Episodes") +
      theme_bw() +
      theme(
        axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  output$podcast_wordcloud <- renderPlot({
    # wordcloud(podcast_wordcloud_data(), max.words = 200)
    if(max(podcast_wordcloud_data()$n) / max(podcast_wordcloud_data()$n) <= 2){
      word_max_size = 10
    } else{
      word_max_size = 25
    }
    ggplot(data = podcast_wordcloud_data() |> slice(1:100), aes(label = word, size = n)) +
      geom_text_wordcloud() +
      scale_size_area(max_size = word_max_size) +
      theme_minimal()
    
  })
  

# Articles ----------------------------------------------------------------
  
  observe({
    updateDateRangeInput(
      inputId = "article_date_range_input", label = "Select a Date Range:",
      start = Sys.Date() - 7, end = Sys.Date()
    )
  })
  
  observeEvent(input$article_current_week_input, {
    updateDateRangeInput(inputId = "article_date_range_input", start = floor_date(Sys.Date(), unit = "week"), end = Sys.Date())
  })
  observeEvent(input$article_previous_week_input, {
    updateDateRangeInput(inputId = "article_date_range_input", start = floor_date(Sys.Date() - 7, unit = "week"), end = floor_date(Sys.Date(), unit = "week") - 1)
  })
  observeEvent(input$article_current_month_input, {
    updateDateRangeInput(inputId = "article_date_range_input", start = floor_date(Sys.Date(), unit = "month"), end = Sys.Date())
  })
  observeEvent(input$article_current_year_input, {
    updateDateRangeInput(inputId = "article_date_range_input", start = floor_date(Sys.Date(), unit = "year"), end = Sys.Date())
  })
  observeEvent(input$article_full_input, {
    updateDateRangeInput(inputId = "article_date_range_input", start = ymd("2023/03/01"), end = Sys.Date())
  })
  
  article_data <- reactive({
    orig_article_data |>
      filter(
        date_read >= min(input$article_date_range_input) & date_read <= max(input$article_date_range_input)
      )
  })
  
  # output$test_table <- renderReactable({
  #   reactable(updated_data())
  # })
  
  # Group by publisher
  article_publisher_summary <- reactive({
    article_data() |>
      group_by(publisher) |>
      summarize(
        total_articles = n()
      )
  })
  
  
  # Group by dates
  article_date_summary <- reactive({
    
    # Create base date df
    dates <- data.frame(date_read = min(input$article_date_range_input, na.rm = T):max(input$article_date_range_input, na.rm = T) |> as.Date()) |>
      mutate(
        year_read = year(date_read),
        month_read = month(date_read, label = TRUE),
        wday_read = wday(date_read, label = TRUE)
      )
    
    # Group by date - initial date calculations
    article_date_summary <- article_data() |>
      group_by(date_read, year_read, month_read, wday_read) |>
      summarize(
        total_articles = n()
      )
    
    # Add in days without listening to any podcasts + calculations for calendar heatmap
    article_date_summary <- left_join(dates, article_date_summary) |>
      mutate(
        total_articles = replace_na(total_articles, 0)
      ) |>
      mutate(
        year_month = factor(as.yearmon(date_read)),
        week = epiweek(date_read),
        week = ifelse(month_read == "Dec" & week == 1, yes = 53, no = week) # epiweek starts week 1 in December if necessary
      ) |>
      filter(year_month != "Feb 2023") |>
      group_by(year_month) |>
      mutate(month_week = 1 + week - min(week)) |>
      ungroup()
    
    article_date_summary
  })
  
  
  # Group by weekdays
  article_wday_summary <- reactive({
    article_date_summary() |>
      group_by(wday_read) |>
      summarize( 
        avg_articles = mean(total_articles, na.rm = TRUE) |> round(2)
      )
  })
  
  
  # Wordcloud data
  article_wordcloud_data <- reactive({
    
    article_data() |>
      select(article_title) |>
      mutate(
        article_title = tolower(article_title) |> 
          str_remove_all("iowa capital dispatch|the gazette|the new york times|the washington post|politico") |>
          str_remove_all(" - .+$|\\| .+|$") |> 
          str_replace_all("[^a-z]s ", " ") |>
          str_replace_all(" [^a-z ]|[^a-z ] ", " ") |> 
          str_replace_all("[^a-z ]", "")
      ) |>
      unnest_tokens(word, article_title) |>
      filter(!is.na(word), !is.null(word)) |>
      anti_join(stop_words |> mutate(word = str_remove_all(word, "[^a-zA-Z]"))) |>
      count(word) |>
      arrange(-n) |>
      slice(1:100)
  })
  
  output$box_articles <- renderValueBox({
    valueBox(
      nrow(article_data()),
      "Total Articles"
    )
  })
  
  output$box_days <- renderValueBox({
    valueBox(
      paste0(sum(article_date_summary()$total_articles >= 1, na.rm = T), "/", nrow(article_date_summary())),
      "Number of Days"
    )
  })
  
  
  output$article_publisher_table <- renderReactable({
    reactable(
      article_publisher_summary() |>
        select(publisher, total_articles),
      columns = list(
        publisher = colDef(name = "Publisher"),
        total_articles = colDef(name = "Total Number of Articles")
      ),
      filterable = TRUE,
      searchable = TRUE
    )
  })
  
  output$article_table <- renderReactable({
    reactable(
      article_data() |>
        select(publisher, article_title, date_read, url),
      columns = list(
        publisher = colDef(name = "Publisher"),
        article_title = colDef(name = "Article Title"),
        date_read = colDef(name = "Date Read"),
        url = colDef(cell = function(value, index) {
          # url <- article_data()[index, "url"]
          htmltools::tags$a(href = value, target = "_blank", "Article Link")
        })
      ),
      filterable = TRUE,
      searchable = TRUE
    )
  })
  
  
  output$article_publishers_bar <- renderPlot({
    max_value <- max(article_publisher_summary()$total_articles) * 1.2
    ggplot(
      article_publisher_summary() |> arrange(-total_articles) |> slice(1:10), 
      aes(x = fct_reorder(publisher, total_articles), y = total_articles, label = total_articles)
    ) +
      geom_col() +
      geom_text(nudge_y = (max_value * 0.025)) +
      scale_y_continuous(limits = c(0, max_value)) +
      labs(x = "", y = "", title = "Top Publishers by Total Articles", fill = "Category") +
      coord_flip() +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  
  output$article_wdays_bar <- renderPlot({
    ggplot(
      article_wday_summary(),
      aes(x = fct_rev(wday_read), y = avg_articles, label = avg_articles |> round(1))
    ) +
      geom_col() +
      geom_text(hjust = -.75) +
      labs(x = "", y = "", title = "Days of the Week by Average Articles per Day") +
      coord_flip() +
      theme_minimal()
  })
  
  output$article_calendar <- renderPlot({
    
    ggplot(article_date_summary(), aes(x = wday_read, y = -month_week, label = total_articles, fill = total_articles)) +
      geom_tile(color = "white") +
      geom_text() +
      facet_grid(month_read~year_read) +
      scale_fill_gradient(low = "red", high = "green") +
      scale_y_continuous() +
      labs(title = "Calendar Heatmap - Articles Read", fill = "Articles") +
      theme_bw() +
      theme(
        axis.text.y = element_blank(), axis.ticks.y = element_blank(),
        axis.title.x = element_blank(), axis.title.y = element_blank()
      )
  })
  
  output$article_wordcloud <- renderPlot({
    # wordcloud(article_wordcloud_data(), max.words = 200)
    if(max(article_wordcloud_data()$n) / max(article_wordcloud_data()$n) <= 2){
      word_max_size = 10
    } else{
      word_max_size = 25
    }
    ggplot(data = article_wordcloud_data() |> slice(1:100), aes(label = word, size = n)) +
      geom_text_wordcloud() +
      scale_size_area(max_size = word_max_size) +
      theme_minimal()
  })
  

# Habits ------------------------------------------------------------------


  

# Stop --------------------------------------------------------------------

  session$onSessionEnded(function() {
    stopApp()
  })
}
