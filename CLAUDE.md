# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R-based personal data tracking project that collects, processes, and visualizes data about articles read, podcasts listened to, habits, and health metrics. Data is sourced from personal APIs/services via R scripts (which are gitignored) and stored as `.rds` files that are committed to the repo.

## Key Commands

Render a static Quarto document to HTML:
```r
quarto::quarto_render("articles/article_data_analysis.qmd")
quarto::quarto_render("podcasts/podcast_data_analysis.qmd")
```

Run a Shiny Quarto app locally:
```r
quarto::quarto_preview("articles/article_data_analysis_shiny.qmd")
quarto::quarto_preview("podcasts/podcast_data_analysis_shiny.qmd")
```

Deploy a Shiny app to shinyapps.io (account: `mavoss`):
```r
rsconnect::deployApp("articles/", appName = "mjv_articles")
rsconnect::deployApp("podcasts/", appName = "mjv_podcasts")
```

## Architecture

### Data Pipeline (gitignored R scripts)
The `.gitignore` excludes all `*.R` files. These scripts (not in the repo) handle data collection from external APIs and produce the `.rds` files that are committed. The `.rds` files serve as the interface between the data pipeline and the analysis layer.

### Two Document Types per Domain

Each domain (`articles/`, `podcasts/`) has two Quarto documents:

1. **Static analysis** (`*_data_analysis.qmd`): Reads `.rds` files locally, renders to a standalone self-contained HTML file. Used for offline/local exploration.

2. **Interactive Shiny app** (`*_data_analysis_shiny.qmd`): Deployed to shinyapps.io. Loads `.rds` data at runtime directly from the GitHub raw URL (e.g., `readRDS(url("https://github.com/mavoss16/personal_tracking/raw/master/..."))`), so the deployed app always uses the latest committed data without redeployment.

### Domains

- `articles/` — tracks articles read; fields include `publisher`, `article_title`, `date_read`, `url`
- `podcasts/` — tracks podcast episodes; fields include `podcast`, `episode_title`, `date_listened`, `date_published`, `minutes_listened`, `hours_listened`, `category`, `category_color`, `time_after_publish`
- `habits/` — habit tracking data (`.rds` only, no analysis `.qmd` currently)
- `health/` — health summary data (`.rds` only, no analysis `.qmd` currently)

### Common R Libraries

`dplyr`, `readr`, `ggplot2`, `reactable`, `forcats`, `shiny`, `lubridate`, `zoo`, `tidyr`, `shinydashboard`, `ggwordcloud`, `stringr`, `tidytext`, `pluralize`

### Calendar Heatmap Pattern

Calendar heatmaps use a `month_week` column computed via `epiweek()`. December edge case: if `epiweek` returns 1 in December, it is recoded to 53. The `year_month` factor drives `facet_grid` layout. Data from before March 2023 is filtered out (`year_month != "Feb 2023"`).

### RStudio Project Settings

2-space indentation, UTF-8 encoding (see `personal_tracking.Rproj`).
