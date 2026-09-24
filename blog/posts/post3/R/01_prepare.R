find_ipums_extract <- function(raw_dir = "data/raw") {
  xml <- list.files(raw_dir, pattern = "\\.xml$", full.names = TRUE,
                    ignore.case = TRUE)
  data <- list.files(raw_dir, pattern = "\\.(dat|csv)\\.gz$", full.names = TRUE,
                     ignore.case = TRUE)

  if (length(xml) != 1 || length(data) != 1) {
    stop(
      "Place exactly one IPUMS DDI .xml file and its matching .dat.gz ",
      "(or .csv.gz) file in data/raw. See README.md."
    )
  }

  list(xml = xml, data = data)
}

classify_education <- function(x) {
  labels <- as.character(haven::as_factor(x, levels = "labels"))

  dplyr::case_when(
    stringr::str_detect(labels, stringr::regex(
      "high school (diploma|graduate)|GED|equivalent", ignore_case = TRUE
    )) ~ "High school",
    stringr::str_detect(labels, stringr::regex(
      "some college|associate", ignore_case = TRUE
    )) ~ "Some college / associate",
    stringr::str_detect(labels, stringr::regex(
      "bachelor", ignore_case = TRUE
    )) ~ "Bachelor's",
    stringr::str_detect(labels, stringr::regex(
      "master|professional school|doctor", ignore_case = TRUE
    )) ~ "Advanced degree",
    TRUE ~ NA_character_
  )
}

classify_sex <- function(x) {
  labels <- as.character(haven::as_factor(x, levels = "labels"))

  dplyr::case_when(
    stringr::str_detect(labels, stringr::regex("female", ignore_case = TRUE)) ~ "Women",
    stringr::str_detect(labels, stringr::regex("male", ignore_case = TRUE)) ~ "Men",
    TRUE ~ NA_character_
  )
}

load_and_prepare_cps <- function(raw_dir = "data/raw") {
  files <- find_ipums_extract(raw_dir)
  required <- c(
    "YEAR", "ASECWT", "AGE", "SEX", "EDUC", "INCWAGE", "WKSWORK1",
    "UHRSWORKLY"
  )

  cps <- ipumsr::read_ipums_micro(
    files$xml,
    vars = required,
    data_file = files$data,
    verbose = FALSE
  )
  names(cps) <- tolower(names(cps))

  missing <- setdiff(tolower(required), names(cps))
  if (length(missing) > 0) {
    stop("The IPUMS extract is missing: ", paste(toupper(missing), collapse = ", "))
  }

  cps <- cps |>
    dplyr::mutate(
      year = as.integer(year),
      income_year = year - 1L,
      education = classify_education(educ),
      sex_group = classify_sex(sex),
      age = as.numeric(age),
      asecwt = as.numeric(asecwt),
      incwage = as.numeric(incwage),
      wkswork1 = as.numeric(wkswork1),
      uhrsworkly = as.numeric(uhrsworkly)
    )

  # IPUMS CPS CPI99 factors convert prior-year income to constant 1999 dollars.
  # Keeping this small published lookup in the script avoids requiring CPI99 in
  # the user's extract. The selected ASEC years are documented in README.md.
  cpi99_lookup <- c(
    `2001` = 0.967,
    `2005` = 0.882,
    `2009` = 0.774,
    `2013` = 0.726,
    `2017` = 0.694,
    `2020` = 0.652,
    `2021` = 0.644,
    `2022` = 0.615,
    `2023` = 0.569,
    `2024` = 0.547,
    `2025` = 0.531
  )
  
  lookup_years <- as.integer(names(cpi99_lookup))
  
  # Only keep years covered by the documented inflation factors.
  ignored_years <- setdiff(sort(unique(cps$year)), lookup_years)
  if (length(ignored_years) > 0) {
    message("Ignoring years without a CPI99 factor: ",
            paste(ignored_years, collapse = ", "))
  }
  cps <- dplyr::filter(cps, year %in% lookup_years)
  cps$cpi99_factor <- unname(cpi99_lookup[match(cps$year, lookup_years)])

  prepared <- cps |>
    dplyr::filter(
      age >= 25, age <= 64,
      wkswork1 >= 50, wkswork1 <= 52,
      uhrsworkly >= 35, uhrsworkly < 999,
      incwage > 0, incwage < 99999999,
      is.finite(asecwt), asecwt > 0,
      !is.na(education), !is.na(sex_group),
      is.finite(cpi99_factor), cpi99_factor > 0
    ) |>
    dplyr::mutate(
      # CPI99 converts nominal income to 1999 dollars. Dividing by the
      # 2025-ASEC factor (0.531) converts 1999 dollars to 2024 dollars.
      weekly_earnings = incwage * cpi99_factor / 0.531 / wkswork1,
      education = factor(
        education,
        levels = c(
          "High school", "Some college / associate", "Bachelor's",
          "Advanced degree"
        )
      ),
      sex_group = factor(sex_group, levels = c("Women", "Men")),
      age_band = cut(
        age,
        breaks = c(25, 30, 35, 40, 45, 50, 55, 60, 65),
        right = FALSE,
        labels = c(
          "25–29", "30–34", "35–39", "40–44",
          "45–49", "50–54", "55–59", "60–64"
        )
      )
    )

  if (nrow(prepared) == 0) {
    stop("No usable observations remain. Check the selected ASEC samples and variables.")
  }
  if (dplyr::n_distinct(prepared$income_year) < 3) {
    stop("Select at least three ASEC sample years; the README recommends eleven.")
  }
  if (!all(levels(prepared$education) %in% unique(as.character(prepared$education)))) {
    stop("Not all four education groups were found. Check EDUC labels in the extract.")
  }

  attr(prepared, "latest_dollar_year") <- 2024L
  prepared
}
