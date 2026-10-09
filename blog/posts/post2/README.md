# Blog Post 2: Where Should an Economics Student Start the Job Search?

## Start here

- **Published article:** https://augenstern118.github.io/testrepo/blog/posts/post2/
- **Article source:** [index.qmd](index.qmd)
- **One-command analysis:** [R/run_project.R](R/run_project.R)
- **Original HTML evidence:** [data/raw/manifest.csv](data/raw/manifest.csv)
- **Calculated comparison:** [results/career_comparison.csv](results/career_comparison.csv)
- **Classification check:** [results/classification_audit.csv](results/classification_audit.csv)

The article compares six BLS occupational profiles to help a quantitative
student choose job searches. The October 8, 2026 revision separates occupational
classification from an economics background, makes the file locations explicit,
and supplies a single replication entry point. It does not infer employment
outcomes for economics graduates.

## Replicate in RStudio

Use R >= 4.1 and Quarto. Put this entire folder at `blog/posts/post2/` in your
existing website. Open the website's `.Rproj` file in RStudio. Do not put a
second `post2` folder inside the existing one.

In the RStudio **Console**, from the website root:

```r
source("blog/posts/post2/setup.R")       # once; installs only missing packages
source("blog/posts/post2/R/run_project.R")
```

The default analysis reads the included HTML and requires no network access.
It regenerates processed data, both charts, the displayed comparison table,
the shortlist, classification tables/audit, sensitivity results, and session
information. The runner restores the original working directory even on errors.
From inside `blog/posts/post2`, use `source("setup.R")` and
`source("R/run_project.R")` instead. Arbitrary other working directories are
not supported: open the website project or the post folder.

To build the article and refresh the blog listing, use the RStudio **Terminal**
from the website root (where `_quarto.yml` is located):

```bash
quarto render blog/posts/post2/index.qmd
quarto render blog/index.qmd
```

Opening the post's `index.qmd` and clicking **Render** also regenerates its
analysis. The build stops if the main rankings or selected occupations conflict
with the prose. Review all interpretation when intentionally changing inputs.

The analysis needs `rvest`, `dplyr`, `stringr`, `readr`, `ggplot2`, and `scales`;
rendering uses `knitr` and `rmarkdown`. These are the same core packages as the
original Post 2. No CPS extract, CPI lookup, API key, or compiled custom code
is used. `httr2` is needed only for optional live collection.

## File map

| Path relative to this folder | Role |
|---|---|
| `index.qmd` | Short article; computed numbers/table; expandable method and code notes |
| `setup.R` | Install missing core packages once |
| `R/run_project.R` | Run the entire archived-data workflow |
| `R/01_scrape.R` | rvest extraction, cleaning, validation, optional collection |
| `R/02_analyze.R` | SOC coverage audit, preference screen, sensitivity and figures |
| `data/raw/*.html` | Six original Summary HTML fragments, preserved from public pages |
| `data/raw/manifest.csv` | URLs, capture dates/method, original SHA-256 and checked MD5 hashes |
| `data/occupation_scope.csv` | Author-documented occupation/SOC metadata, separate from scraped numbers |
| `data/processed/careers.csv` | Cleaned numerical and text fields extracted from HTML |
| `results/career_comparison.csv` | Clean data joined to classification metadata and calculated screen |
| `results/display_table.csv` | Exact formatted values in the displayed table |
| `results/classification_table.csv` | Occupation names, component codes, scopes, and work focus |
| `results/classification_audit.csv` | One row per component SOC code; no repeated code allowed |
| `results/shortlist.csv` | Profiles passing the stated preference screen |
| `results/sensitivity.csv` | Shortlists under nine alternative thresholds |
| `results/growth.png`, `results/openings.png` | Programmatically generated figures |
| `results/sessionInfo.txt` | R/package versions used for the run |

## Classification: jobs versus backgrounds

The unit of comparison is a **BLS occupational profile**, not a degree holder,
self-described economist, unique person, or individual job advertisement.
A financial analyst may have economics training; that information is absent
from these profiles. These data cannot measure how many financial analysts are
also economists in that broader sense.

| Profile | Detailed SOC coverage | Scope |
|---|---|---|
| Data scientists | 15-2051 | One detailed occupation |
| Economists | 19-3011 | One detailed occupation |
| Operations research analysts | 15-2031 | One detailed occupation |
| Market research analysts | 13-1161 | Market research analysts and marketing specialists |
| Management analysts | 13-1111 | One detailed occupation |
| Financial analysts | 13-2051; 13-2054 | Combined financial/investment analysts and financial risk specialists |

SOC coding follows work performed and rules for mixed duties, not simply a
worker's academic major or an employer's title. The analysis expands each
profile's component codes and rejects duplicate codes across rows. This checks
the documented mapping's coverage; it does not deduplicate real job listings
or link individual workers, which are not observed. Counts are compared
profile by profile; no total or market-share denominator is constructed for
'economics graduates'. Shared skills or educational backgrounds are not
interpreted as duplicate SOC records.

The combined financial profile is retained because the archived Quick Facts
and openings paragraph report that aggregate. It is clearly labeled as a
two-code aggregate. Its median wage is not divided between components, and
component medians are not averaged to reconstruct it. Component-specific
comparisons would require additional data.

## Data provenance and cleaning

The six public BLS Summary articles were captured as browser DOM HTML
fragments on **September 20, 2026**. They are the original archived fragments,
not reconstructed numerical tables. Pay refers to **May 2025**; projections
cover **2025-2035**. URLs and capture method are in `data/raw/manifest.csv`.
The revision retains those files and measurement years rather than presenting
the findings as a newly downloaded October sample. SHA-256 hashes are retained;
base R's `tools::md5sum()` checks the additional MD5 hashes before extraction.

`rvest::read_html()`, `html_elements()`, and `html_text2()` extract each Quick
Facts row and the Summary's annual-openings sentence. Cleaning removes
whitespace and currency/number formatting. Annual pay is the first amount in
the wage field; hourly pay is deliberately excluded. Checks reject missing
fields, duplicated profiles, incompatible reference years, invalid counts,
changed archived bytes, and overlapping mapped SOC codes.

Classification metadata was author-documented from BLS definitions and the
financial profile's Employment Projections table, reviewed October 8, 2026.
It is stored separately and labeled as metadata; it is not presented as an
rvest estimate from the saved Summary fragment.

## Interpretation and preference rule

The screen is `median_pay_usd >= 85000 & growth_pct >= 10 & experience == "None"`.
These are a hypothetical student's preferences, not BLS quality ratings.
Sensitivity uses wage floors $80,000/$85,000/$90,000 and growth floors
8%/10%/15%. The original snapshot selects data science and operations research
at $85,000 and 10%; either the $90,000 floor or 15% floor leaves only data science.

Median wages cover workers at multiple career stages, not starting salaries.
Openings include replacement needs and all experience levels; they are not
current vacancies, internships, openings reserved for economics graduates,
or individual hiring probabilities. Wage gaps across occupations are not
causal returns to choosing a career. The six profiles are selected, not a
representative sample of the entire labor market. Geography, skills, work
authorization and actual posting requirements must be checked separately.

## Optional live collection

This is **not needed** to reproduce the supplied article. In the RStudio
Console from this `post2` folder:

```r
# Install httr2 once if it is missing: install.packages("httr2")
source("R/01_scrape.R")
source("R/02_analyze.R")
refresh_sources(destination = "data/live") # choose a new directory each time
fresh <- collect_data("data/live")
fresh_analysis <- analyze_careers(fresh)
```

This optional run overwrites processed/results files with new calculations,
while leaving `data/raw` intact. Re-run `R/run_project.R` to restore the archived
analysis before rendering this article. Live changes need their own reviewed
interpretation; the post always uses `data/raw` by default.

The collector checks current robots.txt rules, requests only six public
profiles with delays, and stops on HTTP/access errors without retrying or
bypassing protections. No login, CAPTCHA, paywall, or other restriction is
bypassed. Original direct HTTP acquisition was unavailable, so the default
workflow explicitly reproduces the included browser-captured evidence.

## Sources

Six BLS OOH profiles, accessed September 20, 2026:

- [Data scientists](https://www.bls.gov/ooh/math/data-scientists.htm)
- [Economists](https://www.bls.gov/ooh/life-physical-and-social-science/economists.htm)
- [Operations research analysts](https://www.bls.gov/ooh/math/operations-research-analysts.htm)
- [Market research analysts](https://www.bls.gov/ooh/business-and-financial/market-research-analysts.htm)
- [Management analysts](https://www.bls.gov/ooh/business-and-financial/management-analysts.htm)
- [Financial analysts](https://www.bls.gov/ooh/business-and-financial/financial-analysts.htm)

Classification documentation checked October 8, 2026:

- [2018 SOC classification principles and coding guidelines](https://www.bls.gov/soc/2018/soc_2018_class_prin_cod_guide.pdf)
- [2018 SOC definitions](https://www.bls.gov/soc/2018/soc_2018_definitions.pdf)
- Financial analysts' Employment Projections table identifies codes 13-2051 and 13-2054.

## Publish and submit

This existing website outputs to `docs/`. After rendering both the post and
blog index, review your local preview and use the Terminal from the website root:

```bash
git add README.md blog/posts/post2 docs
git commit -m "Revise Post 2 classification and reproducibility"
git push origin main
```

Submit the article URL and repository URL. Commit all Post 2 source, archived
HTML, metadata, processed data, results, and README, plus the updated website
output. The repository-root README links directly to the post's analysis and
replication instructions so a reviewer can find them immediately.
