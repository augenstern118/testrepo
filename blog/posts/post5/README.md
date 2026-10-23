# Blog Post 5: Florida and South Carolina — Two Different Growth Stories

## Start here

- **Article source:** [index.qmd](index.qmd)
- **Run all analysis:** [R/run_project.R](R/run_project.R)
- **Data sources and hashes:** [data/raw/manifest.csv](data/raw/manifest.csv)
- **All 50 states:** [results/state_comparison.csv](results/state_comparison.csv)
- **Geographic join checks:** [results/join_audit.csv](results/join_audit.csv)
- **Published article:** `https://augenstern118.github.io/testrepo/blog/posts/post5/`

Question: Is recent state population growth mainly a story of domestic migration?
Two Census choropleths compare total growth and net domestic migration. A third
figure decomposes change for South Carolina, Florida, Pennsylvania and California.
The main article is written for a general audience; detailed methods and code
are in expandable notes and this README. This is descriptive demographic
accounting, not a causal analysis of migration decisions.

## Reproduce in RStudio

Use R >= 4.1 and Quarto. Open the repository's `.Rproj` file in RStudio. From the
website root, run in the RStudio **Console**:

```r
source("blog/posts/post5/setup.R")        # once; install only missing packages
source("blog/posts/post5/R/run_project.R")
```

If working inside the post5 folder, use `source("setup.R")` and
`source("R/run_project.R")`. Other working directories are not supported;
open the website project or the post folder. The runner restores the original
working directory even if analysis fails. There are no hard-coded Windows
paths in the analysis.

The workflow reads both included raw files and regenerates processed data,
join checks, maps, the component chart, tables, the state comparison and
session information. **No download is needed to reproduce the article.**
Rendering never installs packages or contacts a data service.

Dependencies are only `ggplot2` and `jsonlite` for analysis, plus `knitr` and
`rmarkdown` for rendering. The projection is performed by the Census service
when acquiring the saved spatial file; the laptop does not need `sf`,
`tigris`, GDAL, PROJ, a Census API key, or a CPS extract.

In the RStudio **Terminal**, from the website root:

```bash
quarto render blog/posts/post5/index.qmd
quarto render blog/index.qmd
```

Opening `index.qmd` and clicking **Render** also runs the analysis. Rendering
the blog index refreshes its title, description and thumbnail. Keep the existing
`_quarto.yml`, theme and GitHub Pages settings.

## File map

| File or directory | Purpose |
|---|---|
| `index.qmd` | English article, inline computed values, figures and expandable code |
| `setup.R` | Install missing packages once |
| `R/run_project.R` | Single analysis entry point |
| `R/01_prepare.R` | Validate raw files, compute rates, read polygon rings, join by FIPS |
| `R/02_analyze.R` | Two choropleths, component chart, exact tables and summaries |
| `R/download_data.R` | Optional public-URL acquisition into a separate folder |
| `data/raw/population_2025.csv` | Original Census Vintage 2025 population file |
| `data/raw/states_2024_albers.json` | Original Census service response: projected polygon coordinates |
| `data/raw/manifest.csv` | Source URLs, access date and input hashes |
| `data/README.md` | Input/processed field dictionary |
| `data/processed/state_rates.csv` | One row per analyzed state; counts and per-1,000 rates |
| `data/processed/map_vertices.csv` | Joined lower-48 polygon vertices in meters |
| `results/01_population_growth_map.png` | Central map of total population change |
| `results/02_domestic_migration_map.png` | Same-scale map of net domestic migration |
| `results/03_growth_components.png` | Signed component bars and total-change diamonds |
| `results/component_chart_data.csv` | Unrounded data used in the third figure |
| `results/component_table.csv` | Exact displayed component table, rounded to two decimals |
| `results/state_comparison.csv` | All 50 states, sorted by growth per 1,000 |
| `results/summary.csv` | Counts of states growing and growing despite domestic losses |
| `results/join_audit.csv` | 50 state-boundary matches and 48-state map inclusion flags |
| `results/sessionInfo.txt` | R and package versions |

## Population data and economically meaningful units

Source: U.S. Census Bureau Population Division, **Vintage 2025**
`NST-EST2025-ALLDATA`, released January 2026. The article uses the interval
from July 1, 2024 to July 1, 2025. All numbers come from the same vintage;
previous releases can differ because Census revises estimates.

Each component is divided by the average of the two endpoint populations
and multiplied by 1,000. The total population-change rate uses that same
denominator, so its components add exactly before rounding. This total is
not the conventional percent change using the beginning population. It is
explicitly labeled people per 1,000 average residents throughout.

The code checks that endpoint population differences equal reported total
change, component counts reconcile including the residual, and calculated
domestic rates match Census's supplied rates within rounding tolerance.
These are official aggregate estimates; this is not an unweighted microdata
analysis and no additional survey sampling weights are applied.

Domestic and international migration are **net** flows. Domestic migration
is a geographic category, not a citizenship category. International migration
also covers U.S.-born return migration, movement involving Puerto Rico and
other movements defined by Census. It is not a count of foreign-born people,
visa holders, or gross immigrant arrivals. The residual is a reconciliation
adjustment, not a separate observed group of movers.

## GIS specification and checks

The boundary source is the U.S. Census Bureau's **TIGERweb Generalized ACS2024
State_County service**, States 20M feature layer 9. The layer contains
January 1, 2024 generalized state outlines; it is a spatial/cartographic
product, not ACS income or population observations. Its 2024 outline vintage
is separate from the 2025 population-estimate vintage.

The documented query requests `GEOID,NAME,STUSAB`, polygon geometry, and
`outSR=5070`. The returned ESRI JSON contains **NAD83 / Conus Albers
(EPSG:5070)** coordinates in meters. Both maps use these same projected
coordinates with a fixed aspect ratio. They are equal-area choropleths;
land area is not used as the population denominator.

The numeric table's FIPS code is padded to two digits and matched to boundary
`GEOID`. The workflow verifies 50 unique state matches, exact agreement of
state names, no missing mapped values, finite coordinates, the returned CRS,
and no server transfer-limit truncation. It preserves vertex order and
individual polygon rings; even-odd filling preserves holes and disconnected
parts. Joining polygons with a sorting merge can scramble their order; this
code indexes attributes onto the existing vertex rows instead.

The analysis excludes Washington, D.C., and Puerto Rico because the comparison
is of 50 states. Maps show only the contiguous 48 states; Alaska and Hawaii
are retained in the all-state CSV and the count of states growing despite
outmigration. There is no claim that the two maps display all U.S. territory.
The audit explicitly records these scope choices.

Both maps use a continuous diverging scale centered at zero with fixed limits
-15 to +15 people per 1,000. Teal means positive change, orange negative;
light gray is near zero, not missing data. An assertion prevents silent color
clipping if revised data exceed those limits. Selected state labels use
bounding-box midpoint positions with small presentation adjustments. All
rates are calculated from source values, not typed into the map labels.

The component chart uses the same population denominator. Positive and
negative contributions stack separately; the diamond is their signed sum.
Four cases illustrate contrasts rather than constitute a representative
sample: South Carolina is domestic-led, Florida international-led,
Pennsylvania grows despite domestic outflows and natural decrease, and
California's positive components nearly offset its domestic loss.

## Limits and interpretation

Net migration cannot reveal gross arrival or departure counts. These state
estimates do not identify migrants' motives, occupations, ages, legal status,
or an individual household's prospects. Births and deaths are affected by a
state's population composition. Geographic patterns do not establish that
taxes, housing prices or policies caused moves. A map also cannot establish
neighborhood-level conditions from a state average. Close-to-zero changes
should be read cautiously; estimates and migration methods may be revised.

The figures are an accounting description of one year, not a forecast. Components
classify geographic flows, not mutually exclusive groups of people. The maps
locate population change; they do not directly measure housing shortages or
public-service pressure.
Understanding demographic sources can guide further local investigation,
but specific school, housing or service plans require finer geographic and
age data. The article does not turn population growth into a policy scorecard.

## Optional programmatic acquisition

To repeat acquisition without overwriting the pinned evidence, from the
`post5` folder in the RStudio Console:

```r
source("R/download_data.R")
download_raw(destination = "data/downloaded")
```

Choose a new destination on later runs. Two public requests download the
population CSV and projected polygon response. There is no login or API key.
Network failure affects only this optional acquisition; included inputs
remain available for rendering. The new manifest records MD5 hashes; the
original manifest additionally retains SHA-256 hashes. Do not replace the
pinned inputs or update the narrative automatically after a new download.

## Sources

Both raw files were downloaded October 17, 2026. Exact query parameters and
hashes are in [the manifest](data/raw/manifest.csv).

- [State population estimates and components landing page](https://www.census.gov/data/tables/time-series/demo/popest/2020s-state-total.html)
- [Original CSV](https://www2.census.gov/programs-surveys/popest/datasets/2020-2025/state/totals/NST-EST2025-ALLDATA.csv)
- [File layout and rate definitions](https://www2.census.gov/programs-surveys/popest/technical-documentation/file-layouts/2020-2025/NST-EST2025-ALLDATA.pdf)
- [Vintage 2025 methodology](https://www2.census.gov/programs-surveys/popest/technical-documentation/methodology/2020-2025/methods-statement-v2025.pdf)
- [TIGERweb 2024 state service and query interface](https://tigerweb.geo.census.gov/arcgis/rest/services/Generalized_ACS2024/State_County/MapServer/9)

## Updating and publishing

After changing analysis code or inputs, rerun `R/run_project.R`, render the
article and `blog/index.qmd`, and inspect the local pages. Commit the changed
Post 5 source/input files, generated data/results, and regenerated `docs/`
files. Source scripts, manifests, and data definitions document replication;
generated HTML should not be edited by hand.

See the [repository overview](../../../README.md) for website structure and
publication. The [data dictionary](data/README.md) documents the input and
processed fields.
