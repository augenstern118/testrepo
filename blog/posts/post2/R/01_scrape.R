# Collect structured information from BLS HTML using rvest.
# Run from the project root. Archived HTML makes the default run reproducible.
suppressPackageStartupMessages({
  library(rvest)
  library(dplyr)
  library(stringr)
  library(readr)
})

sources <- tibble::tribble(
  ~id, ~occupation, ~path,
  "data-scientists", "Data scientists", "math/data-scientists.htm",
  "economists", "Economists", "life-physical-and-social-science/economists.htm",
  "operations-research-analysts", "Operations research analysts", "math/operations-research-analysts.htm",
  "market-research-analysts", "Market research analysts", "business-and-financial/market-research-analysts.htm",
  "management-analysts", "Management analysts", "business-and-financial/management-analysts.htm",
  "financial-analysts", "Financial analysts", "business-and-financial/financial-analysts.htm"
) |>
  mutate(url = paste0("https://www.bls.gov/ooh/", path))

scrape_profile <- function(file, id, occupation, url) {
  page <- read_html(file, encoding = "UTF-8")
  rows <- html_elements(page, "#quickfacts tbody tr")
  if (length(rows) != 7L) stop("Quick Facts structure changed: ", file)
  fields <- tibble::tibble(
    label = str_squish(html_text2(html_element(rows, "th"))),
    value = str_squish(html_text2(html_element(rows, "td")))
  )
  get_field <- function(pattern) {
    value <- fields$value[str_detect(fields$label, regex(pattern, ignore_case = TRUE))]
    if (length(value) != 1L || is.na(value) || value == "") {
      stop("Missing or ambiguous field: ", pattern, " in ", file)
    }
    value
  }
  # Scope to the Summary article, so the same sentence elsewhere is not counted twice.
  summary <- html_element(page, "article[aria-labelledby='Summary']")
  if (is.na(html_name(summary))) stop("Summary article missing: ", file)
  body <- str_squish(html_text2(summary))
  openings <- str_match(body, "About\\s+([0-9,]+)\\s+openings")[, 2]
  period <- str_match(body, "from\\s+(20[0-9]{2})\\s+to\\s+(20[0-9]{2})")
  pay_label <- fields$label[str_detect(fields$label, "Median Pay")]
  pay_text <- get_field("Median Pay")
  result <- tibble::tibble(
    id, occupation, source_url = url,
    # Annual pay is the FIRST amount; the hourly amount is deliberately excluded.
    median_pay_usd = parse_number(pay_text),
    pay_year = as.integer(str_extract(pay_label, "20[0-9]{2}")),
    education = get_field("Entry-Level Education"),
    experience = get_field("Work Experience"),
    employment = parse_number(get_field("Number of Jobs")),
    growth_pct = parse_number(get_field("Job Outlook")),
    net_new_jobs = parse_number(get_field("Employment Change")),
    annual_openings = parse_number(openings),
    projection_start = as.integer(period[, 2]),
    projection_end = as.integer(period[, 3])
  )
  if (anyNA(result)) stop("A required field could not be parsed: ", file)
  result
}

collect_data <- function(raw_dir = "data/raw") {
  manifest <- read_csv(file.path(raw_dir, "manifest.csv"), show_col_types = FALSE)
  if (anyDuplicated(manifest$id) || !setequal(manifest$id, sources$id)) {
    stop("Manifest must contain exactly one record for each source.")
  }
  data <- bind_rows(lapply(seq_len(nrow(sources)), function(i) {
    s <- sources[i, ]
    scrape_profile(file.path(raw_dir, paste0(s$id, ".html")),
                   s$id, s$occupation, s$url)
  })) |>
    left_join(select(manifest, id, access_date, capture_method), by = "id")
  stopifnot(nrow(data) == 6L, !anyDuplicated(data$id), !anyNA(data),
            all(data$median_pay_usd > 0), all(data$annual_openings > 0),
            all(data$employment > 0), all(data$projection_end > data$projection_start),
            length(unique(data$pay_year)) == 1L,
            length(unique(data$projection_start)) == 1L,
            length(unique(data$projection_end)) == 1L)
  # All monetary figures must refer to the same year for meaningful comparisons.
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  write_csv(data, "data/processed/careers.csv")
  data
}

# OPTIONAL live collection. The supplied report uses the archived September 2026
# snapshot. New data go to a separate directory, preserving that original evidence.
refresh_sources <- function(destination = "data/live") {
  if (!requireNamespace("httr2", quietly = TRUE)) stop("Install httr2 first.")
  if (dir.exists(destination)) stop("Use a new destination to preserve earlier data.")
  ua <- "EconomicsCourseProject/1.0 (six public BLS career pages; educational use)"
  get_public <- function(url) {
    httr2::request(url) |>
      httr2::req_user_agent(ua) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()  # Stops on HTTP errors, including 403 and 429. No retries.
  }
  robots <- httr2::resp_body_string(get_public("https://www.bls.gov/robots.txt"))
  if (!grepl("User-agent:", robots, ignore.case = TRUE)) stop("Cannot verify robots.txt.")
  # Conservative check: honor Disallow rules from ALL groups, ignore Allow
  # exceptions, and stop if any rule could exclude one of these six paths.
  # This intentionally may refuse more than necessary; it never tries to evade a rule.
  lines <- trimws(gsub("#.*$", "", strsplit(robots, "\n", fixed = TRUE)[[1]]))
  rules <- trimws(sub("^[Dd]isallow\\s*:", "", lines[grepl("^[Dd]isallow\\s*:", lines)]))
  rules <- rules[nzchar(rules)]
  url_paths <- sub("https://www.bls.gov", "", sources$url, fixed = TRUE)
  for (rule in rules) {
    # Convert robots wildcards to a regular expression. Unanchored rules
    # match prefixes; a terminal $ requires a match through the end of a path.
    pattern <- glob2rx(sub("\\$$", "", rule), trim.head = FALSE, trim.tail = FALSE)
    if (!endsWith(rule, "$")) pattern <- sub("\\$$", "", pattern)
    if (any(grepl(pattern, url_paths))) {
      stop("A robots.txt rule may disallow these pages: ", rule,
           ". Stop and review the site's policy; do not bypass it.")
    }
  }
  delay <- 3
  crawl <- lines[grepl("^Crawl-delay:", lines, ignore.case = TRUE)]
  if (length(crawl)) delay <- max(delay, parse_number(crawl), na.rm = TRUE)
  dir.create(destination, recursive = TRUE)
  writeLines(robots, file.path(destination, "robots.txt"))
  manifest <- list()
  for (i in seq_len(nrow(sources))) {
    Sys.sleep(delay)
    s <- sources[i, ]
    response <- get_public(s$url)
    content <- httr2::resp_body_raw(response)
    file <- file.path(destination, paste0(s$id, ".html"))
    writeBin(content, file)
    # rvest collects and validates the relevant fields immediately after download.
    scrape_profile(file, s$id, s$occupation, s$url)
    manifest[[i]] <- tibble::tibble(id = s$id, source_url = s$url,
      access_date = as.character(Sys.Date()), capture_method = "HTTP download; rvest extraction")
    write_csv(bind_rows(manifest), file.path(destination, "manifest.csv"))
  }
  message("Saved six pages. Run run_project(raw_dir = '", destination, "') to analyze them.")
  invisible(destination)
}
