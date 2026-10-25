# Optional: run from the website root or post7. The archived article needs no download.
post_dir <- if (file.exists("blog/posts/post7/data/series.csv")) "blog/posts/post7" else "."
stopifnot(file.exists(file.path(post_dir, "data/series.csv")))
metadata <- read.csv(file.path(post_dir, "data/series.csv"), stringsAsFactors = FALSE)
url <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=",
              paste(metadata$series_id, collapse = ","),
              "&cosd=2020-02-01&coed=2024-12-01")
destination <- file.path(post_dir, "data/downloaded", format(Sys.time(), "%Y%m%d_%H%M%S"))
if (dir.exists(destination)) stop("Destination already exists. Run again at a later time.")
dir.create(destination, recursive = TRUE)
target <- file.path(destination, "fred_employment.csv")
download.file(url, target, mode = "wb", method = "libcurl", quiet = FALSE)
d <- read.csv(target, na.strings = c("", "."), check.names = FALSE)
stopifnot(all(c("observation_date", metadata$series_id) %in% names(d)))
d$observation_date <- as.Date(d$observation_date)
keep <- d$observation_date >= as.Date("2020-02-01") & d$observation_date <= as.Date("2024-12-01")
stopifnot(sum(keep) == 59, all(is.finite(as.matrix(d[keep, metadata$series_id]))))
write.csv(data.frame(url = url, downloaded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
                     md5 = unname(tools::md5sum(target))),
          file.path(destination, "manifest.csv"), row.names = FALSE)
message("Saved a new download to ", destination,
        ". Archived raw inputs were not changed. Review revisions before using new values.")
