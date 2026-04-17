health_tab <- nav_panel(
  title = "Health",
  
  page_sidebar(
    sidebar = sidebar(
      width = 280,
      dateRangeInput(
        "health_date_range_input", label = "Select a Date Range:",
        start = "2024-01-01", end = Sys.Date()
      ),
      pickerInput(
        "health_var_input", choices = c("Steps", "Stairs", "Sleep", "Heart Rate Avg.", "Heart Rate Max.", "Resting HR", "Inactive HR", "REM Sleep", "Respiration Rate")
      ),
    ),
    htmlOutput("health_plot_settings"),
    layout_columns(
      col_widths = c(4, 4, 4),
      plotOutput("health"),
      plotOutput("health_7d"),
      plotOutput("health_30d")
    ),
    layout_columns(
      col_widths = c(4, 8),
      layout_columns(
        col_widths = c(6, 6),
        pickerInput(
          "health_var_x_input", label = "Pick an X Variable:",
          choices = c("Steps", "Stairs", "Sleep", "Heart Rate Avg.", "Heart Rate Max.", "Resting HR", "Inactive HR", "REM Sleep", "Respiration Rate")
        ),
        pickerInput(
          "health_var_y_input", label = "Pick a Y Variable:", selected = "Stairs",
          choices = c("Steps", "Stairs", "Sleep", "Heart Rate Avg.", "Heart Rate Max.", "Resting HR", "Inactive HR", "REM Sleep", "Respiration Rate")
        )
      ),
      plotOutput("health_xy")
    )
  )
)

podcast_tab <- nav_panel(
  title = "Podcasts",
  page_sidebar(
    sidebar = sidebar(
      width = 280,
      # uiOutput("podcast_sidebar")
      dateRangeInput(
        "podcast_date_range_input", label = "Select a Date Range:",
        start = Sys.Date() - 7, end = Sys.Date()
      ),
      checkboxGroupInput(
        "podcast_category_input", label = "Select Categories",
        choices = c("Economics", "History", "Iowa", "Lifestyle", "Politics", "Science", "Sports") |> sort(),
        selected = c("Economics", "History", "Iowa", "Lifestyle", "Politics", "Science", "Sports") |> sort()
      )
    ),
    layout_column_wrap(
      # col_widths = rep(12/5, length.out = 5),
      actionButton("podcast_current_week_input", label = "Current Week"),
      actionButton("podcast_previous_week_input", label = "Previous Week"),
      actionButton("podcast_current_month_input", label = "Current Month"),
      # actionButton("podcast_last_3_month_input", label = "Last 3 Months"),
      actionButton("podcast_current_year_input", label = "Current Year"),
      actionButton("podcast_full_input", label = "All-Time")
    ),
    layout_columns(
      col_widths = c(4, 4, 4),
      value_box(value = uiOutput("podcast_hours_text"), title = "Total Hours"),
      value_box(value = uiOutput("podcast_days_text"), title = "Number of Days"),
      value_box(value = uiOutput("podcast_episodes_text"), title = "Total Episodes")
    ),
    navset_tab(
      nav_panel(
        title = "Data Viz",
        layout_columns(
          col_widths = c(6, 6),
          plotOutput("podcast_hours_bar"),
          plotOutput("podcast_episodes_bar"),
          plotOutput("podcast_category_hours_bar"),
          plotOutput("podcast_category_episodes_bar"),
          plotOutput("podcast_wdays_hours_bar"),
          plotOutput("podcast_wdays_episodes_bar"),
          plotOutput("podcast_hours_calendar", height = "750px"),
          plotOutput("podcast_episodes_calendar", height = "750px")
        )
      ),
      nav_panel(
        title = "Podcast Table",
        reactableOutput("podcast_table")
      ),
      nav_panel(
        title = "Episode Table",
        reactableOutput("podcast_episode_table")
      ),
      nav_panel(
        title = "Episode Title Wordcloud",
        plotOutput("podcast_wordcloud")
      )
    )
    
  )
)

article_tab <- nav_panel(
  title = "Articles",
  page_sidebar(
    sidebar = sidebar(
      width = 280,
      # uiOutput("podcast_sidebar")
      dateRangeInput(
        "article_date_range_input", label = "Select a Date Range:",
        start = Sys.Date() - 7, end = Sys.Date()
      )
    ),
    layout_column_wrap(
      # col_widths = rep(12/5, length.out = 5),
      actionButton("article_current_week_input", label = "Current Week"),
      actionButton("article_previous_week_input", label = "Previous Week"),
      actionButton("article_current_month_input", label = "Current Month"),
      # actionButton("article_last_3_month_input", label = "Last 3 Months"),
      actionButton("article_current_year_input", label = "Current Year"),
      actionButton("article_full_input", label = "All-Time")
    ),
    #   layout_columns(
    #     col_widths = c(4, 4, 4),
    #     value_box(value = uiOutput("podcast_hours_text"), title = "Total Hours"),
    #     value_box(value = uiOutput("podcast_days_text"), title = "Number of Days"),
    #     value_box(value = uiOutput("podcast_episodes_text"), title = "Total Episodes")
    #   ),
    navset_tab(
      nav_panel(
        title = "Data Viz",
        plotOutput("article_publishers_bar"),
        plotOutput("article_wdays_bar"),
        plotOutput("article_calendar", height = "750px")
      ),
      nav_panel(
        title = "Publisher Table",
        reactableOutput("article_publisher_table")
      ),
      nav_panel(
        title = "Article Table",
        reactableOutput("article_table")
      ),
      nav_panel(
        title = "Article Title Wordcloud",
        plotOutput("article_wordcloud")
      )
    )
    
  )
)

habit_tab <- nav_panel(
  title = "Habits",
  page_sidebar(
    sidebar = sidebar(
      width = 280,
      dateRangeInput(
        "habit_date_range_input", label = "Select a Date Range:",
        start = Sys.Date() - 7, end = Sys.Date()
      )
    ),
    # layout_column_wrap(
    #   # col_widths = rep(12/5, length.out = 5),
    #   actionButton("article_current_week_input", label = "Current Week"),
    #   actionButton("article_previous_week_input", label = "Previous Week"),
    #   actionButton("article_current_month_input", label = "Current Month"),
    #   # actionButton("article_last_3_month_input", label = "Last 3 Months"),
    #   actionButton("article_current_year_input", label = "Current Year"),
    #   actionButton("article_full_input", label = "All-Time")
    # ),
    #   layout_columns(
    #     col_widths = c(4, 4, 4),
    #     value_box(value = uiOutput("podcast_hours_text"), title = "Total Hours"),
    #     value_box(value = uiOutput("podcast_days_text"), title = "Number of Days"),
    #     value_box(value = uiOutput("podcast_episodes_text"), title = "Total Episodes")
    #   ),
    navset_tab(
      nav_panel(
        title = "Data Viz",
        plotOutput("habit_reading_line"),
        plotOutput("habit_wdays_bar"),
        plotOutput("habit_calendar", height = "750px")
      ),
      nav_panel(
        title = "Daily Table",
        reactableOutput("habit_day_table")
      ),
      nav_panel(
        title = "Weekly Table",
        reactableOutput("habit_week_table")
      )
    )
    
  )
)