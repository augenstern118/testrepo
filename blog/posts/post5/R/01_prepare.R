# Read the included official Census files. Never download during rendering.
prepare_data <- function() {
  manifest <- read.csv("data/raw/manifest.csv", stringsAsFactors = FALSE)
  files <- file.path("data/raw", manifest$file)
  if (!all(file.exists(files))) stop("Keep the complete data/raw folder with the post.")
  if (!all(unname(tools::md5sum(files)) == manifest$md5)) {
    stop("An input file changed. Review its provenance before using it.")
  }
  pop <- read.csv("data/raw/population_2025.csv", stringsAsFactors = FALSE)
  # 040 = state-level records. Analyze 50 states; exclude DC and Puerto Rico.
  pop <- pop[pop$SUMLEV == 40 & !pop$STATE %in% c(11, 72), ]
  stopifnot(nrow(pop) == 50, !anyDuplicated(pop$STATE))
  d <- data.frame(
    fips = sprintf("%02d", pop$STATE), state = pop$NAME,
    population_2024 = pop$POPESTIMATE2024,
    population_2025 = pop$POPESTIMATE2025,
    population_change = pop$NPOPCHG_2025,
    domestic = pop$DOMESTICMIG2025,
    international = pop$INTERNATIONALMIG2025,
    natural = pop$NATURALCHG2025,
    residual = pop$RESIDUAL2025,
    stringsAsFactors = FALSE
  )
  # Use a common average-population denominator so component rates add exactly.
  d$average_population <- (d$population_2024 + d$population_2025) / 2
  for (name in c("population_change", "domestic", "international", "natural", "residual")) {
    d[[paste0(name, "_rate")]] <- 1000 * d[[name]] / d$average_population
  }
  stopifnot(!anyNA(d), all(d$average_population > 0),
    all(d$population_2025 - d$population_2024 == d$population_change),
    all(d$domestic + d$international + d$natural + d$residual == d$population_change),
    max(abs(d$domestic_rate - pop$RDOMESTICMIG2025)) < 0.000001)

  # ESRI JSON polygons are already projected by the Census service into meters.
  # Read coordinate rings directly; sf/GDAL/PROJ are not needed on the laptop.
  geo <- jsonlite::fromJSON("data/raw/states_2024_albers.json", simplifyVector = FALSE)
  stopifnot(geo$spatialReference$wkid == 5070,
            !isTRUE(geo$exceededTransferLimit))
  points <- list()
  keys <- list()
  n <- 0L
  for (feature in geo$features) {
    id <- feature$attributes$GEOID
    if (!id %in% d$fips) next
    keys[[length(keys) + 1L]] <- data.frame(fips = id,
      boundary_state = feature$attributes$NAME,
      abbreviation = feature$attributes$STUSAB)
    for (r in seq_along(feature$geometry$rings)) {
      xy <- do.call(rbind, lapply(feature$geometry$rings[[r]], unlist))
      n <- n + 1L
      points[[n]] <- data.frame(fips = id, ring = paste(id, r, sep = "_"),
        vertex = seq_len(nrow(xy)), x = xy[, 1], y = xy[, 2])
    }
  }
  points <- do.call(rbind, points)
  keys <- do.call(rbind, keys)
  stopifnot(nrow(keys) == 50, !anyDuplicated(keys$fips),
            setequal(d$fips, keys$fips), all(is.finite(points$x)), all(is.finite(points$y)))
  d <- merge(d, keys, by = "fips", sort = FALSE)
  stopifnot(all(d$state == d$boundary_state))
  # Preserve original vertex order: a sorting join can corrupt polygon shapes.
  map <- cbind(points, d[match(points$fips, d$fips), setdiff(names(d), "fips")])
  rownames(map) <- NULL
  map <- map[!map$fips %in% c("02", "15"), ]
  stopifnot(length(unique(map$fips)) == 48, !anyNA(map))
  audit <- data.frame(fips = d$fips, state = d$state,
    boundary_match = TRUE, mapped_in_lower48 = !d$fips %in% c("02", "15"))
  dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
  write.csv(d, "data/processed/state_rates.csv", row.names = FALSE)
  write.csv(map, "data/processed/map_vertices.csv", row.names = FALSE)
  write.csv(audit, "results/join_audit.csv", row.names = FALSE)
  list(states = d, map = map)
}
