# Paths below are relative to post_dir, supplied by run_project.R or index.qmd.
# All calculations use base R. No API, sample weights, or CPI factors are needed.
metadata <- read.csv(file.path(post_dir, "data/series.csv"), stringsAsFactors = FALSE)
manifest <- read.csv(file.path(post_dir, "data/raw/manifest.csv"), stringsAsFactors = FALSE)
raw_file <- file.path(post_dir, "data/raw/fred_employment.csv")
raw <- read.csv(raw_file, na.strings = c("", "."), check.names = FALSE)
stopifnot(all(c("observation_date", metadata$series_id) %in% names(raw)))
raw$observation_date <- as.Date(raw$observation_date)
stopifnot(!anyNA(raw$observation_date), !anyDuplicated(raw$observation_date))

# Some FRED multi-series responses contain a wider date range than requested.
# Explicitly select the fixed window BEFORE checking for missing values.
start_date <- as.Date("2020-02-01")
end_date <- as.Date("2024-12-01")
wide <- raw[raw$observation_date >= start_date & raw$observation_date <= end_date,
            c("observation_date", metadata$series_id)]
wide <- wide[order(wide$observation_date), ]
stopifnot(identical(wide$observation_date, seq(start_date, end_date, by = "month")),
          nrow(metadata) == 12L, sum(metadata$kind == "sector") == 11L,
          !anyDuplicated(metadata$series_id))
for (id in metadata$series_id) {
  stopifnot(is.numeric(wide[[id]]), all(is.finite(wide[[id]])), all(wide[[id]] > 0))
}

dir.create(file.path(post_dir, "data/processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(post_dir, "results"), recursive = TRUE, showWarnings = FALSE)

# Each sector gets its OWN February 2020 denominator. FRED levels are thousands.
parts <- vector("list", nrow(metadata))
for (i in seq_len(nrow(metadata))) {
  id <- metadata$series_id[i]
  level <- wide[[id]]
  baseline <- level[1]
  parts[[i]] <- data.frame(
    date = wide$observation_date, series_id = id, sector = metadata$sector[i],
    kind = metadata$kind[i], jobs_thousands = level,
    baseline_thousands = baseline,
    change_thousands = level - baseline,
    change_pct = 100 * (level / baseline - 1),
    stringsAsFactors = FALSE
  )
}
employment <- do.call(rbind, parts)
row.names(employment) <- NULL
stopifnot(!anyDuplicated(employment[c("date", "series_id")]))

# First recovery is the first observed post-baseline month at or above baseline.
# This is not a requirement to stay above baseline in all later months.
total <- employment[employment$series_id == "PAYEMS", ]
recovery_date <- min(total$date[total$date > start_date & total$change_thousands >= 0])
stopifnot(length(recovery_date) == 1, is.finite(as.numeric(recovery_date)))
recovery_snapshot <- employment[employment$date == recovery_date, ]
end_snapshot <- employment[employment$date == end_date, ]
sector_recovery <- recovery_snapshot[recovery_snapshot$kind == "sector", ]
sector_end <- end_snapshot[end_snapshot$kind == "sector", ]

sector_summary <- metadata[c("series_id", "sector", "kind")]
sector_summary$first_return <- NA_character_
sector_summary$change_at_total_recovery_pct <- recovery_snapshot$change_pct
sector_summary$change_at_total_recovery_thousands <- recovery_snapshot$change_thousands
sector_summary$end_change_pct <- end_snapshot$change_pct
sector_summary$end_change_thousands <- end_snapshot$change_thousands
sector_summary$end_below_baseline <- end_snapshot$change_thousands < 0
for (i in seq_len(nrow(metadata))) {
  d <- employment[employment$series_id == metadata$series_id[i], ]
  return_dates <- d$date[d$date > start_date & d$change_thousands >= 0]
  if (length(return_dates)) sector_summary$first_return[i] <- as.character(min(return_dates))
}

# Audit the broad-sector coverage without imposing exact additivity as a general
# requirement: separately adjusted published series can differ through rounding.
sector_ids <- metadata$series_id[metadata$kind == "sector"]
partition_difference <- rowSums(wide[sector_ids]) - wide$PAYEMS
partition_audit <- data.frame(date = wide$observation_date,
                              sector_sum_thousands = rowSums(wide[sector_ids]),
                              total_thousands = wide$PAYEMS,
                              difference_thousands = partition_difference)
stopifnot(max(abs(partition_difference)) <= 20)

write.csv(employment, file.path(post_dir, "data/processed/employment.csv"), row.names = FALSE)
write.csv(sector_summary, file.path(post_dir, "results/sector_summary.csv"), row.names = FALSE)
write.csv(recovery_snapshot, file.path(post_dir, "results/recovery_snapshot.csv"), row.names = FALSE)
write.csv(end_snapshot, file.path(post_dir, "results/end_snapshot.csv"), row.names = FALSE)
write.csv(partition_audit, file.path(post_dir, "results/partition_audit.csv"), row.names = FALSE)

key_findings <- data.frame(
  measure = c("total_first_return", "sectors_below_at_total_return", "sector_count",
              "sectors_below_at_end", "total_change_at_end_thousands"),
  value = c(as.character(recovery_date), sum(sector_recovery$change_thousands < 0),
            nrow(sector_recovery), sum(sector_end$change_thousands < 0),
            end_snapshot$change_thousands[end_snapshot$series_id == "PAYEMS"])
)
write.csv(key_findings, file.path(post_dir, "results/key_findings.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(post_dir, "results/sessionInfo.txt"))

# Article numbers are computed here, not pasted from a spreadsheet.
at_return <- function(id, column) recovery_snapshot[[column]][recovery_snapshot$series_id == id]
at_end <- function(id, column) end_snapshot[[column]][end_snapshot$series_id == id]
pct_text <- function(x) paste0(formatC(abs(x), format = "f", digits = 1, decimal.mark = "."), "%")
jobs_text <- function(x) format(round(abs(x) * 1000), big.mark = ",", scientific = FALSE, trim = TRUE)
# English month names are independent of Windows/RStudio's display language.
month_text <- paste(month.name[as.integer(format(recovery_date, "%m"))], format(recovery_date, "%Y"))
below_return <- sum(sector_recovery$change_thousands < 0)
below_end <- sum(sector_end$change_thousands < 0)
small_gaps <- sum(sector_end$change_pct < 0 & sector_end$change_pct > -1)
snapshot_date <- as.Date(substr(manifest$retrieved_utc[1], 1, 10))
snapshot_text <- paste0(month.name[as.integer(format(snapshot_date, "%m"))], " ",
                       as.integer(format(snapshot_date, "%d")), ", ", format(snapshot_date, "%Y"))
