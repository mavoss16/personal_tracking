

library(shiny)
library(bslib)
library(shinyauthr)
library(shinydashboard)
library(shinyWidgets)
library(ggplot2)
library(reactable)

login_tab <- nav_panel(
  title = icon("lock"),
  value = "login",
  shinyauthr::loginUI(id = "login")
)

ui <- page_navbar(
  title = "Matthew's Tracking Data",
  fillable = FALSE,
  id = "main_tabs",
  login_tab
)