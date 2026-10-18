# OPTIONAL acquisition; not run when rendering. Existing cached inputs stay intact.
# Source from post5, then call download_raw(). No API key is needed.
download_raw <- function(destination = "data/downloaded") {
  if (dir.exists(destination)) stop("Choose a new destination to preserve existing files.")
  urls <- c(
    population_2025.csv = "https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/state/totals/NST-EST2025-ALLDATA.csv",
    states_2024_albers.json = "https://tigerweb.geo.census.gov/arcgis/rest/services/Generalized_ACS2024/State_County/MapServer/9/query?where=1%3D1&outFields=GEOID%2CNAME%2CSTUSAB&outSR=5070&f=json&returnGeometry=true"
  )
  old_timeout <- getOption("timeout")
  on.exit(options(timeout = old_timeout), add = TRUE)
  options(timeout = 120)
  dir.create(destination, recursive = TRUE)
  for (i in seq_along(urls)) {
    target <- file.path(destination, names(urls)[i])
    download.file(urls[i], target, mode = "wb", quiet = TRUE)
  }
  pop <- read.csv(file.path(destination, "population_2025.csv"))
  geo <- jsonlite::fromJSON(file.path(destination, "states_2024_albers.json"), simplifyVector = FALSE)
  stopifnot("POPESTIMATE2025" %in% names(pop), length(geo$features) >= 50,
            geo$spatialReference$wkid == 5070, !isTRUE(geo$exceededTransferLimit))
  manifest <- data.frame(file = names(urls), source_url = unname(urls),
    access_date = as.character(Sys.Date()),
    description = c("Census Population Estimates, Vintage 2025", "TIGERweb 2024 States 20M; EPSG:5070"),
    md5 = unname(tools::md5sum(file.path(destination, names(urls)))))
  write.csv(manifest, file.path(destination, "manifest.csv"), row.names = FALSE)
  message("Saved verified inputs to ", destination, ". Original data/raw was not changed.")
  invisible(manifest)
}
