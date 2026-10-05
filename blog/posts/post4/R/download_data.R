# Optional refresh: the complete original CSV snapshots are already included.
# Run from the website root:
#   post_dir <- "blog/posts/post4"
#   source(file.path(post_dir, "R", "download_data.R"))
# This script uses base R only. It does not run during normal rendering.

if (!exists("post_dir")) post_dir <- "."
raw_dir <- file.path(post_dir, "data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
options(timeout = 120)

series_ids <- c("MSPUS", "MORTGAGE30US", "MEHOINUSA646N")
urls <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", series_ids,
               "&cosd=2015-01-01&coed=2024-12-31")

for (i in seq_along(series_ids)) {
  # Download and check a temporary file first; keep the old CSV on failure.
  temp_csv <- tempfile(fileext = ".csv")
  download.file(urls[i], destfile = temp_csv, mode = "wb", method = "libcurl")
  check <- read.csv(temp_csv, na.strings = c(".", ""))
  stopifnot(nrow(check) > 0, series_ids[i] %in% names(check))
  copied <- file.copy(temp_csv, file.path(raw_dir, paste0(series_ids[i], ".csv")),
                      overwrite = TRUE)
  stopifnot(copied)
  unlink(temp_csv)
}

manifest <- data.frame(series_id = series_ids, url = urls,
                       retrieved_on = as.character(Sys.Date()),
                       start = "2015-01-01", end = "2024-12-31")
write.csv(manifest, file.path(raw_dir, "source_manifest.csv"), row.names = FALSE)
message("CSV files refreshed. Render index.qmd to regenerate all results.")
