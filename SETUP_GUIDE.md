# Building Your Own Personal Tracking Shiny Dashboard

This guide walks through everything needed to clone this repository and adapt it to track your own reading and podcast listening data.

## Overview

The project has three layers:

1. **Data source** — Notion databases, queried via the `notionR` R package
2. **Data pipeline** — R scripts that pull from Notion, process the data, and write `.rds` files committed to the repo
3. **Shiny dashboards** — apps deployed to shinyapps.io that load `.rds` files directly from the GitHub raw URL

Because the deployed apps read data from GitHub at runtime, you only need to redeploy to shinyapps.io when the dashboard code itself changes — not when new data comes in.

## Two Dashboard Options

There are two ways to run the dashboards, depending on how much you want to combine:

### Option A: Individual Quarto Dashboards (simpler)

`podcasts/podcast_data_analysis_shiny.qmd` and `articles/article_data_analysis_shiny.qmd` are standalone Shiny apps, one per domain. Each covers only its own data (podcasts or articles) and is deployed independently to shinyapps.io. This is the simpler path if you only want one or two domains, or want to keep things separate.

**Additional packages needed:** Quarto (1.4+)

### Option B: Unified `bslib` Dashboard (more complete)

`ui.R`, `server.R`, and `ui_tabs.R` at the repo root form a single unified app built with `bslib`'s `page_navbar`. It combines all domains — **Health, Podcasts, Articles, and Habits** — into one tabbed interface behind a login screen (via `shinyauthr`). This app loads four `.rds` files at startup:

- `health/daily_health_summary.rds`
- `podcasts/podcast_data.rds`
- `articles/article_data.rds`
- `habits/habit_data.rds`

The Health tab visualizes Garmin metrics (steps, sleep, heart rate, etc.) with 7-day and 30-day rolling averages. The Habits tab is present in the UI but its server logic is not yet fully implemented.

**Additional packages needed** (beyond the base list below): `bslib`, `shinyauthr`, `shinyWidgets`, `scales`

```r
install.packages(c("bslib", "shinyWidgets", "scales"))
remotes::install_github("paulc91/shinyauthr")
```

> **Note on authentication:** The unified app uses `shinyauthr` with a hardcoded username/password in `server.R`. For any shared or public deployment, replace the `user_base` tibble with a more secure credential store.

The Quarto dashboards and the unified dashboard use the **same `.rds` files**, so the data pipeline setup (Steps 1–2) is identical regardless of which option you choose.

---

## Prerequisites

### Software

- [R](https://cran.r-project.org/) (4.3+)
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended) or another IDE
- [Quarto](https://quarto.org/docs/get-started/) (1.4+)

### R Packages

Install from CRAN (required for both dashboard options):

```r
install.packages(c(
  "dplyr", "readr", "ggplot2", "reactable", "forcats",
  "shiny", "lubridate", "zoo", "tidyr", "shinydashboard",
  "ggwordcloud", "stringr", "tidytext", "pluralize",
  "rsconnect", "remotes"
))
```

If using the unified dashboard (`ui.R` / `server.R`), also install:

```r
install.packages(c("bslib", "shinyWidgets", "scales"))
remotes::install_github("paulc91/shinyauthr")
```

Install `notionR` from GitHub:

```r
remotes::install_github("Eflores89/notionR")
```

---

## Step 1: Set Up Notion

### Create a Notion Integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations) and create a new integration
2. Copy the **Internal Integration Token** — this is your `NOTION_TOKEN_SHINY`
3. For each database you create below, open the database in Notion → **...** menu → **Connect to** → select your integration

### Podcast Database

Create a Notion database with the following properties:

| Property Name   | Type     | Notes |
|-----------------|----------|-------|
| Episode Title   | Title    | The default title field |
| Podcast         | Select   | Use colors to drive categories (see below) |
| Date Published  | Date     | Publication date of the episode |
| Date Listened   | Formula  | A formula that returns the date you listened |
| Minutes Listened| Number   | Episode length in minutes |
| URL             | URL      | Link to the episode |
| Topic Override  | Select   | Optional — overrides the Podcast color for categorization |

**Category color mapping** — the select colors on the `Podcast` (or `Topic Override`) field map to categories as follows:

| Notion Color | Category  |
|--------------|-----------|
| Purple       | Politics  |
| Blue         | Iowa      |
| Red          | Sports    |
| Yellow       | Lifestyle |
| Orange       | Economics |
| Green        | Science   |
| Gray         | Other     |
| Brown        | History   |

You can rename or change these categories by editing the `case_when` block in `podcasts/podcast_data_actions.R`.

### Article Database

Create a Notion database with the following properties:

| Property Name | Type         | Notes |
|---------------|--------------|-------|
| Name          | Title        | Article title |
| URL           | URL          | Link to the article |
| Date Read     | Created time | Auto-populated when the record is created |

> **Tip:** Using `Created time` for `Date Read` means you can log articles simply by adding them to the database — the date is recorded automatically.

---

## Step 2: Configure the Data Scripts

Open `podcasts/podcast_data_actions.R` and `articles/article_data_actions.R` and update the `database_id` variable in each to match your Notion database IDs.

You can find a database ID in the Notion URL:
```
https://www.notion.so/<workspace>/<DATABASE_ID>?v=...
```

The token is read from the environment variable `NOTION_TOKEN_SHINY`. Set it in your `.Renviron` file (never hardcode it):

```
NOTION_TOKEN_SHINY=secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Restart R after editing `.Renviron`, then run the scripts to confirm data loads correctly:

```r
source("podcasts/podcast_data_actions.R")
source("articles/article_data_actions.R")
```

This writes `podcasts/podcast_data.rds` and `articles/article_data.rds`.

---

## Step 3: Update the Shiny Apps

All apps load data from your GitHub repository's raw URL at runtime. Search each file for `mavoss16/personal_tracking` and replace it with `<your-username>/personal_tracking`.

The relevant lines are:

- `podcasts/podcast_data_analysis_shiny.qmd` — one `readRDS(url(...))` call in the server block
- `articles/article_data_analysis_shiny.qmd` — one `readRDS(url(...))` call in the server block
- `server.R` (unified dashboard) — four `readRDS(url(...))` calls at the top of the file

The wordcloud cleanup logic in both the Quarto apps and `server.R` uses `str_remove_all` to strip show-specific terms before tokenizing episode/article titles. Update those strings to match your own data:

```r
# Remove terms specific to your shows or publishers
str_remove_all("your show name|another show|etc")
```

---

## Step 4: Deploy to shinyapps.io

1. Create a free account at [shinyapps.io](https://www.shinyapps.io/)
2. In RStudio: **Tools** → **Global Options** → **Publishing** → connect your shinyapps.io account
3. Deploy whichever apps you want:

```r
# Individual Quarto dashboards (Option A)
rsconnect::deployApp("podcasts/", appName = "my_podcasts")
rsconnect::deployApp("articles/", appName = "my_articles")

# Unified dashboard (Option B) — deploy from the repo root
rsconnect::deployApp(".", appName = "my_tracking")
```

You only need to redeploy when the dashboard code changes. Data updates (new `.rds` files committed to GitHub) are picked up automatically the next time a user loads the app.

---

## Step 5: Automate Daily Data Refresh with GitHub Actions

The workflow in `.github/workflows/daily-data-update.yml` runs the data scripts on a schedule and commits the updated `.rds` files back to the repository.

### Add the Notion token as a GitHub Actions secret

1. Go to your repository on GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `NOTION_TOKEN_SHINY`, Value: your integration token

### Trigger a manual run to test

After pushing the workflow file, go to **Actions** → **Daily Data Update** → **Run workflow** to confirm everything works before waiting for the scheduled run.

The workflow runs daily at 07:00 UTC (2:00 AM CDT / 1:00 AM CST). Adjust the cron expression in the YAML to change the schedule.

---

## Running Locally

**Individual Quarto dashboards** (requires the `.rds` files to already exist):

```r
quarto::quarto_preview("podcasts/podcast_data_analysis_shiny.qmd")
quarto::quarto_preview("articles/article_data_analysis_shiny.qmd")
```

Render a static (non-interactive) version to HTML:

```r
quarto::quarto_render("podcasts/podcast_data_analysis.qmd")
quarto::quarto_render("articles/article_data_analysis.qmd")
```

**Unified dashboard** — run from the repo root in RStudio using the Run App button, or:

```r
shiny::runApp(".")
```
