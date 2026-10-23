# Blog Post 3: The College Earnings Premium Is Not One Number

## Question and scope

How does the descriptive bachelor's earnings premium vary over time, by
reported sex, and across age groups? IPUMS CPS Annual Social and Economic
Supplement (ASEC) microdata provide the income, education, and person weights.
The comparisons describe full-time, full-year workers; they do not estimate
the causal return to college.

## Obtain the IPUMS CPS extract

1. Sign in or register at <https://cps.ipums.org/cps/> and choose **Get Data**.
2. Select these **ASEC** samples: **2001, 2005, 2009, 2013, 2017, 2020, 2021,
   2022, 2023, 2024, and 2025**. These correspond to income years **2000, 2004,
   2008, 2012, 2016, and 2019–2024**. ASEC annual income refers to the previous
   calendar year.
3. Include `YEAR`, `ASECWT`, `AGE`, `SEX`, `EDUC`, `INCWAGE`, `WKSWORK1`, and
   `UHRSWORKLY`. Additional automatically included identifiers may remain.
   **The current code does not require `CPI99` in the extract.**
4. Submit a rectangular fixed-width extract. Download both the compressed
   data (`.dat.gz`) and matching DDI codebook (`.xml`). If the DDI opens in
   the browser, save the XML file rather than an HTML copy of the page.
5. Place exactly one matching XML/data pair in
   `blog/posts/post3/data/raw/`, retaining the original filenames and keeping
   the data compressed. The file locator also accepts `.csv.gz`; the
   documented replication route is the fixed-width `.dat.gz` extract.

Raw CPS microdata are intentionally excluded from Git. Each replicator must
obtain access through IPUMS and follow its use conditions. Keep the existing
raw-data `.gitignore` rules when committing other project files.

## Software and replication

Use R, Quarto, and the R packages listed in `setup.R`: `ipumsr`, `dplyr`,
`tidyr`, `ggplot2`, `stringr`, `forcats`, `readr`, `scales`, `haven`, and
`knitr`. R rendering also uses `rmarkdown`.

Open the repository's `.Rproj` file in RStudio. From the website root, run
once in the RStudio **Console**:

```r
source("blog/posts/post3/setup.R")
if (!requireNamespace("rmarkdown", quietly = TRUE)) install.packages("rmarkdown")
```

For an installation of `ipumsr` that reports a missing `hipread` dependency
when reading fixed-width data, install that dependency once in the Console:

```r
# Only if the reader reports that hipread is missing:
install.packages("hipread")
```

Package installation requires a working CRAN connection. If CRAN offers only
a source package requiring compilation, a compatible R build toolchain is
also needed. Reuse a working installation; none of these installation steps
belongs inside the article's Render chunks.

After placing the extract in `data/raw/`, run in the RStudio **Terminal**
from the website root:

```bash
quarto render blog/posts/post3/index.qmd
quarto render blog/index.qmd
```

Opening the article's `index.qmd` and clicking **Render** also executes the
preparation and analysis. The default analysis reads the local extract and
does not download data during rendering. Review the page and generated
results before publishing; the website output directory is `docs/`.

## File organization

| Path relative to this folder | Purpose |
|---|---|
| `index.qmd` | Article, analysis execution, inline results, and figures |
| `setup.R` | Installs missing R packages |
| `R/01_prepare.R` | Locates the extract, classifies education/sex, filters workers, adjusts income |
| `R/02_analyze.R` | Weighted medians, earnings premiums, figures, and CSV outputs |
| `data/raw/README.md` | Local input placement and access requirements |
| `data/raw/*.xml`, `data/raw/*.dat.gz` | Matching local IPUMS codebook/data; excluded from Git |
| `results/` | Generated tables, figures, and R session information |

## Income, weights, and inflation adjustment

- `AGE` is age recorded in the ASEC survey; annual wage income refers to the
  prior calendar year. The analytic sample keeps survey ages 25–64, 50–52
  weeks worked, at least 35 usual weekly hours (excluding the 999 code),
  positive wage income below the code's missing-value cutoff, and positive
  finite person weights.
- `INCWAGE` measures annual pre-tax wage and salary income. It does not
  represent total household income or self-employment income.
- `ASECWT` supplies the person-level ASEC weight. Each reported group median
  is the first ordered earnings value at which cumulative positive weight
  reaches at least half the group's total weight. The population totals
  saved with summaries are sums of `ASECWT`, not raw observation counts.
- The bachelor's premium is
  `100 * (weighted_median_bachelors / weighted_median_high_school - 1)`.
  It is a ratio of weighted group medians, not a median individual return.
- `R/01_prepare.R` contains a fixed `cpi99_lookup` for the listed ASEC years.
  It computes weekly earnings as
  `INCWAGE * cpi99_factor / 0.531 / WKSWORK1` and labels them in **2024
  dollars**. The value `0.531` is the code's 2025-ASEC reference factor.
  These factors are stored in the script; an extract-level `CPI99` column
  is not read.
- Years outside that lookup, including ASEC 2026, are excluded by the current
  preparation code with a message. Select the eleven documented samples for
  the intended comparison; adding a later sample does not extend the analysis
  or change its dollar base. The code requires at least three usable income
  years and all four education groups.

Education labels are grouped into high school, some college/associate,
bachelor's, and advanced degree. Records not assigned to these groups are
excluded. Sex labels are grouped into women and men. The latest-year age
profile uses five-year age bands from 25–29 through 60–64.

## Generated outputs

Rendering regenerates the following files under `results/`:

- `earnings_by_education.csv`: weighted median earnings by year and education,
  with weight totals and observation counts.
- `college_premium.csv`: bachelor's premium relative to high school by year.
- `college_premium_by_sex.csv`: the same comparison within each sex group.
- `earnings_by_age.csv`: weighted earnings by age band and education in the
  latest retained income year.
- `01_earnings_trend.png`, `02_premium_by_sex.png`, `03_age_profile.png`:
  the three programmatically generated figures.
- `sessionInfo.txt`: R and package versions for the run.

The article obtains numeric statements and plots from these weighted
calculations. Do not copy new values manually into the prose or edit the
generated CSVs to change a result.

## Interpretation and limitations

The estimates describe the population represented by ASEC **within the stated
sample restrictions**. Conditioning on full-time, full-year wage work excludes
people with unstable or absent employment. Education differences can reflect
occupation, experience, field of study, geography, and selection; they are
not causal schooling effects. The latest-year age comparison is cross-sectional,
not the earnings history of a fixed cohort. CPS top coding, nonresponse,
population-control changes, and sampling error remain limitations. The post
does not report standard errors or confidence intervals.

## Sources

- [IPUMS CPS](https://cps.ipums.org/cps/)
- [CPS weight guidance](https://cps.ipums.org/cps/sample_weights.shtml)
- [IPUMS inflation-adjustment documentation](https://cps.ipums.org/cps/cpi99.shtml)
- Variable definitions and code labels in the downloaded IPUMS DDI and the
  IPUMS pages for `ASECWT`, `AGE`, `SEX`, `EDUC`, `INCWAGE`, `WKSWORK1`, and
  `UHRSWORKLY`.
