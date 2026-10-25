# Blog Post 7: The Jobs Came Back. Did Every Industry?

## Question

When U.S. nonfarm payroll employment regained its February 2020 level, had
every major sector recovered too? One Plotly chart compares the national
total with eleven broad sectors using percentage and absolute job changes.
This is a descriptive analysis of real published BLS estimates, not simulated
data and not a causal explanation of the pandemic recovery.

## Software and reproduction

Use R >= 4.1, Quarto, and the R packages `plotly`, `htmlwidgets`, `knitr`,
and `rmarkdown`. The code uses base R for data preparation and named Plotly
arguments for chart construction. Open the repository's `.Rproj` in RStudio.
From the website root (the directory containing `_quarto.yml`), run once in
the RStudio **Console**:

```r
source("blog/posts/post7/setup.R")
```

The setup script installs only missing packages. It is not run during Render.
To regenerate the analysis without rendering the article, run in the Console:

```r
source("blog/posts/post7/R/run_project.R")
```

From a Console already inside `blog/posts/post7`, the corresponding commands
are `source("setup.R")` and `source("R/run_project.R")`.

In the RStudio **Terminal**, from the website root:

```bash
quarto render blog/posts/post7/index.qmd
quarto render blog/index.qmd
```

Opening the article's `index.qmd` and clicking **Render** also runs the
preparation and chart scripts. All default inputs are included. Reproduction
uses no data downloads after package installation and requires no CPS extract,
API key, Plotly account, Shiny server, or Python installation. A Pandoc
installation is used to save the standalone self-contained chart; Quarto and
RStudio provide Pandoc. Run within RStudio or ensure Pandoc is on PATH.

The accompanying `blog/index.qmd` uses `contents: "posts/**/index.qmd"`.
It lists each post's article source once and keeps previews or temporary
rendering files from becoming extra entries. This changes only the listing
file; the website configuration, navigation, and older articles are retained.

## File structure

| Location | Purpose |
|---|---|
| `index.qmd` | Short article; computed statements and the interactive chart |
| `setup.R` | Installs missing packages once |
| `R/run_project.R` | Runs the fixed-input analysis and chart scripts |
| `R/01_analyze.R` | Validates inputs; calculates changes, snapshots, and recovery dates |
| `R/02_plot.R` | Builds and saves the Plotly widget and static listing thumbnail |
| `R/download_data.R` | Optional programmatic acquisition into a new directory |
| `data/series.csv` | FRED/BLS IDs, sector definitions, colors, and source links |
| `data/raw/fred_employment.csv` | Unmodified CSV response from the public FRED URL |
| `data/raw/manifest.csv` | Acquisition URL, UTC access time, units, scope, and hashes |
| `data/processed/employment.csv` | All 708 plotted observations with baseline and both changes |
| `results/employment_explorer.html` | Standalone interactive HTML with embedded JavaScript |
| `results/thumbnail.png` | Static image for the blog listing |
| `results/sector_summary.csv` | First return dates and endpoint changes for all twelve series |
| `results/recovery_snapshot.csv` | Each sector at the national recovery month |
| `results/end_snapshot.csv` | Each sector in December 2024 |
| `results/partition_audit.csv` | Broad-sector sum compared with the published national total |
| `results/key_findings.csv` | Computed numbers used in the article |
| `results/sessionInfo.txt` | R and package versions from the analysis run |
| `data/README.md` | Data dictionary and input definitions |

## Sources and measurement

The source is the U.S. Bureau of Labor Statistics **Current Employment
Statistics (CES)** establishment survey, distributed by the Federal Reserve
Bank of St. Louis through FRED. All twelve series are **monthly, seasonally
adjusted**, in thousands of payroll jobs. They are aggregate published
estimates; no additional microdata sampling weights or inflation adjustment
are appropriate for this employment-count comparison.

The study window is February 2020–December 2024, inclusive: 59 months and
12 series. The source download can return a wider date range and blank
values outside the requested interval for some series. The script explicitly
selects the study window before checking complete monthly coverage. No
missing study-window observation is interpolated or replaced with zero.

The eleven broad groups are mining/logging, construction, manufacturing,
trade/transportation/utilities, information, financial activities,
professional/business services, private education/health services,
leisure/hospitality, other services, and government. They cover the broad
nonfarm payroll categories without overlapping sector/subsector series.
Private education/health excludes government education/health jobs, which
are included under government. The national total is a comparison series,
not a twelfth sector to add to the other eleven.

- [BLS CES program](https://www.bls.gov/ces/)
- [BLS jobs-versus-people measurement guidance](https://www.bls.gov/bls/empsitquickguide.htm)
- [BLS revision guidance](https://www.bls.gov/web/empsit/cesvininfo.htm)
- [FRED national payroll series](https://fred.stlouisfed.org/series/PAYEMS)
- All eleven sector-specific source links and original BLS codes are in
  `data/series.csv`; the exact download request and access time are in
  `data/raw/manifest.csv`.

## Calculations and checks

For each series, let `base` be its February 2020 employment in thousands:

```text
change_thousands = jobs_thousands - base
change_pct = 100 * (jobs_thousands / base - 1)
```

The chart starts at zero in both modes. Raw levels and both changes remain
available in the tooltip. Percentage lines use each series' own denominator;
they are not shares of total employment. The absolute axis is in thousands,
while tooltip job counts are converted to individual jobs.

The national recovery date is the first **post-February-2020** month with
`change_thousands >= 0`. This excludes the baseline itself. Sector return
dates use the same definition. Returning once does not mean staying above
baseline. The period ends in December 2024; missing (`NA`) first-return dates mean
no return was observed within this window, not that a sector never recovers.

The code validates unique dates and series, 59 consecutive months, positive
finite levels, required IDs, and broad-sector coverage. The sum of sectors
is audited against the total; a tolerance allows for separately adjusted
estimates or rounding, and discrepancies over 20,000 jobs stop the build.
This check is an input-coverage diagnostic, not a statistical confidence band.

The article uses inline R values generated by the analysis. The fixed
snapshot has a June 2022 national return, five of eleven sectors below
baseline then, and four below at December 2024. These are retrospective
results using this download, not a reconstruction of real-time announcements.
Changing inputs requires reviewing the interpretation, even when inline
numbers update automatically.

## What the interaction adds

- The industry dropdown provides a readable default comparison, a
  goods-sector comparison, and all-sector exploration.
- Legend clicks show/hide individual sectors. Double-clicking isolates one;
  dropdown presets restore a known selection.
- Unit buttons change the same observations between percentage and absolute
  job changes without resetting sector visibility.
- Hover or tap reveals sector, month, payroll level, and both change measures.
- The date slider and drag-to-zoom allow inspection of specific intervals.
  Double-click the plot to reset zoom. Scrolling the page does not zoom it.

These controls let readers distinguish a large percentage loss in a small
sector from a large numerical contribution in a bigger sector and see
temporary versus persistent crossings of the pre-pandemic baseline.

## Optional acquisition

To repeat the original public-URL request, from the website root in the Console:

```r
source("blog/posts/post7/R/download_data.R")
```

This saves a timestamped CSV and manifest under `data/downloaded/`. It does
not replace the archived input or the displayed results. BLS revises historical
estimates; a new download can change crossings and endpoint gaps. The original
SHA-256 and MD5 hashes document the included raw bytes. Exact replication
uses the archived input; the analysis does not reject Windows text line-ending
changes based on a raw-byte hash alone.

## Limitations and updating the website

CES counts payroll jobs, not unique people or vacancies. A return to a fixed
job count does not establish recovery in wages, hours, job quality, population-
adjusted employment, or a counterfactual trend. Broad categories hide changes
within sectors. The chart identifies differences in paths, not their causes.
Small below-baseline endpoint gaps should not be treated as large collapses.

After editing code, inputs, or interpretation, regenerate results and render
the post and blog listing. Review the interactive controls before publishing.
Commit the complete `blog/posts/post7/` folder, updated `blog/index.qmd`, and
regenerated `docs/` files.
Do not commit temporary download directories or edit generated HTML by hand.
The existing website output directory remains `docs/`.
