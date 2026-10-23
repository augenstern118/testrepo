# Blog Post 6: Matching parents and children with SQL in Python

Question: How much does the measured intergenerational earnings elasticity
change when we average income over several years and observe children later
in their careers?

This is a tutorial using **real BLS NLSY79 and Children/Young Adult public-use
microdata**, not simulated data. It estimates **maternal wage-and-salary
earnings persistence in a selected matched sample**, not a national causal
effect or the persistence of total parental family income.

## Rendering and editing the article

`index.qmd` includes the generated `results/_article.md` and the saved figures.
Quarto does not execute Python during Render. To render the saved results,
run in the RStudio **Terminal** from the website root:

```bash
quarto render blog/posts/post6/index.qmd
quarto render blog/index.qmd
```

For durable prose changes, edit `_article_template.md`, then rerun the Python
analysis described below. Do not edit `results/_article.md` directly: it is
regenerated. After changing the template, Python analysis, SQL, or inputs,
**rerun Python before rendering** so the article, tables, and figures agree.
Keep the leading underscores on these two Markdown filenames; they identify
supporting content rather than separate blog articles.

The saved page can be rendered without a Python execution step, Jupyter,
or reticulate. Reproducing or changing the analysis requires the Python
environment below. Open the repository's `.Rproj` for website work in RStudio.

## Reproduce the complete analysis

Use Python **3.11 or newer** with SQLite support. In the RStudio **Terminal**,
starting at the website root:

```bash
python -m pip install -r blog/posts/post6/requirements.txt
python blog/posts/post6/code/run_analysis.py
quarto render blog/posts/post6/index.qmd
quarto render blog/index.qmd
```

If Windows recognizes the `py` launcher instead of `python`, use:

```bash
py -3 -m pip install -r blog/posts/post6/requirements.txt
py -3 blog/posts/post6/code/run_analysis.py
```

Use the same interpreter for installation and analysis. SQL is executed by
Python's built-in `sqlite3` module. The only external packages are numpy,
pandas, and matplotlib; they normally install as Windows binary packages.
`results/versions.json` records the versions used for the saved outputs.

The script resolves paths relative to its own location. It works from the
website root, the `post6` folder, or another directory, including Windows paths
containing spaces. No network is needed for the default analysis once the
packages are installed.

Expected results for the included inputs: 356 children from 290 mothers; log-log slopes
about 0.017 (single year in each generation), 0.098 (average mother, single
later child year), and 0.084 (averages in both generations). Confidence
intervals are wide and include zero. These expectations refer to this fixed
extract, not to a general estimate for the United States.

## File organization

| Location | Purpose |
|---|---|
| `index.qmd` | Quarto page metadata and generated-article include |
| `_article_template.md` | Editable tutorial prose, numeric placeholders, and SQL includes |
| `code/run_analysis.py` | Cleaning, SQLite loading/execution, regression, uncertainty, figures |
| `code/render_article.py` | Generates article numbers, tables, and displayed SQL from source files |
| `code/reacquire_data.py` | Optional reconstruction from the original official archives |
| `sql/01_link.sql` | Actual parent–child matching using individual and family identifiers |
| `sql/02_real_income.sql` | Real-income person-year tables |
| `sql/03_average.sql` | Income aggregation, coverage counts, GROUP BY and HAVING |
| `sql/04_single.sql` | Anchor-year selection using predeclared age targets |
| `sql/05_matched.sql` | One record per matched child and a common analysis sample |
| `data/raw/` | Small source-column extracts, selected codebook, CPI, variable map, provenance |
| `data/processed/` | Generated matched sample, real-income panels, links and SQLite database |
| `results/` | Programmatically generated article, figures, estimates, uncertainty and audits |

## Data sources and acquisition

Downloaded October 20, 2026. The fixed archived releases are used for
reproducibility; newer NLS releases also exist.

- BLS access page:
  <https://www.bls.gov/nls/getting-started/accessing-data.htm>
- NLSY79 original archive:
  <https://www.bls.gov/nls/getting-started/nlsy79_all_1979-2018.zip>
- Children/Young Adult original archive:
  <https://www.bls.gov/nls/getting-started/nlscya_all_1979-2018.zip>
- Mother–child linkage definitions:
  <https://www.bls.gov/nls/questions-and-answers.htm>
- Child sample design and four-year interview cycle after age 30:
  <https://nlsinfo.org/content/cohorts/nlsy79-children/intro-to-the-sample/sample-design>
- CPI-U raw file:
  <https://download.bls.gov/pub/time.series/cu/cu.data.1.AllItems>
  Series **CUUR0000SA0**, period **M13** (annual average), 1990–2019.
- BLS public-domain policy:
  <https://www.bls.gov/bls/linksite.htm>

The raw CSV extracts preserve the original data values and original variable
names for selected columns and **all rows**: 12,686 NLSY79 respondents and
11,545 children. Filtering and the actual matching occur in the analysis,
not in a manually constructed paired dataset. These are public-use identifiers;
no names, addresses, restricted geographic data or attempts at identification
are included.

`data/raw/variables.csv` lists every selected variable, original question,
survey year, role and title. `codebook_selected.txt` provides the corresponding
original codebook entries, including missing codes and top-code notes.
`sources.json` records URLs, original archive hashes and included input hashes.
Text input hashes normalize CRLF to LF so Windows Git line-ending changes do
not produce a false data-change error. Archive hashes remain byte-for-byte.

The default analysis uses the included small files. To verify acquisition from
the original archives (about **590 MB** to download; several GB of CSV read
while still compressed), run:

```bash
python blog/posts/post6/code/reacquire_data.py
```

This writes to `data/reacquired/` and checks agreement with included hashes.
An existing archive cache can be supplied with `--archive-dir "path/to/cache"`.
It does not overwrite the verified raw inputs. Do not commit the large archive
cache or reacquired duplicate files to GitHub. The original archives can change
at their URLs; a changed archive triggers a clear hash error rather than
silently mixing releases. If unavailable, the included extracts still suffice.

## Identifiers and SQL operations

- Mother's individual identifier: NLSY79 **R00001.00**.
- Child's individual identifier: CYA **C00001.00**.
- Maternal-family identifier: CYA **C00002.00**, equal to the mother's
  R00001.00. We rename it `family_id`. It groups maternal siblings across
  households and years. It is not an independently invented household ID.
- Maternal sex: R02148.00. Sample: R01736.00; codes 5–8 designate
  cross-sectional-sample females. Birth year: R00005.00 (add 1900).
- Child sex: C00054.00; birth year: C00057.00.

`SELECT` chooses fields. `JOIN ... ON` matches the documented keys. `WHERE`
filters person-year inputs. `GROUP BY` creates one group per person, `AVG`
and `COUNT` aggregate the group, and `HAVING` filters groups by coverage.
The code aggregates the two annual panels **before** joining income summaries.
Joining both person-year panels directly would create multiple combinations
of parent and child years and change the weighting of the regression.

The persisted database `data/processed/parent_child.sqlite` contains the actual
input tables and every intermediate SQL result. Students can inspect it from
Python with `sqlite3.connect(...)` and `pandas.read_sql_query(...)`.

## Income and sample choices

1. Income is annual pre-tax wages/salary/commissions/tips, using the original
   NLSY79 `Q13-5` revised/top-coded fields and CYA `Q15-5`/`Q15-5-TOP` fields.
   It excludes self-employment and non-wage income. Maternal income does not
   measure the combined resources of both parents.
2. Negative survey codes are missing; they never enter averages as negative
   incomes or as zero. Reported zero wages remain in averages. Top-coded values
   are retained as published, with no imputation of their unknown true values.
3. Mothers' selected income questions specify fixed prior calendar years
   1992, 1993, 1995, 1997, 1999, 2001 and 2003. Child questions through 2012
   likewise specify the prior wave-year calendar year. From child wave 2014,
   the question refers to the calendar year before the **actual interview**;
   use CURDATE~Y, not simply wave year minus one. The original codebook shows
   this change. One extremely late 2016-wave response overlaps a later
   reference year but has missing wages; the code removes missing income
   observations before checking unique person-income-year keys.
4. Convert each observation to 2018 dollars with
   `nominal_wages * CPI_2018 / CPI_income_year`. Deflate **before** averaging.
   No CPI99 variable, hand-maintained deflator lookup, or external API key is
   required. Age is the year-based age attained in the income year, not age
   on a specific interview date.
5. Maternal average: ages **35–40**, at least **3** observed income years.
   Early child average: ages **20–25**, at least **2** observed years.
   Later child average: ages **30–39**, at least **2** observed years.
   Children over 30 have often been interviewed only every four years since
   2010. Sparse coverage motivates the wider later window. These averages
   summarize observed years; they are not six- or ten-year complete incomes.
6. Single-year observations are closest to ages **38**, **23** and **35**
   within their respective windows, breaking ties toward the earlier year.
   Choose the year before imposing positivity. We do not search for a
   convenient positive year when an anchor observation is zero.
7. All five primary specifications use the same children with adequate
   coverage and positive anchors/averages. OLS uses natural logs of arithmetic
   mean income levels, **not** means of logged annual incomes. Each child has
   one regression row; mothers with several eligible children appear in
   several pairs. Standard errors cluster by mother.

## Estimation, interpretation, and limitations

`log(child income) = intercept + IGE * log(maternal income) + error` is fitted
using `numpy.linalg.lstsq`. The IGE is an elasticity, not a correlation and not
a causal effect. A slope near zero with a wide interval is not evidence that
family background is irrelevant. There are 356 children but only 290 independent
maternal clusters in the primary sample.

Mother-clustered sandwich standard errors use finite-sample correction
`G/(G-1) * (N-1)/(N-K)`. Displayed intervals use +/- 1.96 SE. The separate
500-draw **paired mother-cluster bootstrap** estimates uncertainty for changes
between specifications. It resamples observed families, retains siblings, and
uses seed 20261020. This resampling is not a simulated survey or fabricated
income data. Intervals for the early-to-later single-year change and for the
single-to-average change include zero.

The life-cycle demonstration combines (a) the same-pair comparison at different
child ages while fixing maternal income, and (b) the simple measurement model
`log(Y_child_at_age_a) = lambda_a * log(Y_child_long_run) + unrelated_noise`.
With accurate parental income, `beta_a = lambda_a * beta_long_run` under the
stated assumptions; lambda below one yields downward bias. Real-data age
sensitivity is consistent with this risk, but cannot identify the true lifetime
IGE. Later income averages are imperfect proxies, not known truth. Calendar
conditions also change as the children age. Averaging reduces independent
temporary shocks more effectively than persistent ones and does not by itself
remove life-cycle bias.

The results are **unweighted descriptions of this selected tutorial sample**.
They do not purport to describe the entire U.S. population. Selection involves
maternal cohort, age at motherhood, survey response/retention and positive
anchor income; it can change the relationship itself. Published top coding,
individual wage income versus household resources, and gender differences
also matter. An adjusted-specification table controls for child sex and birth
year; it is a sensitivity check, not a causal identification strategy.

Reference: Haider, Steven, and Gary Solon. 2006. "Life-Cycle Variation in the
Association between Current and Lifetime Earnings." *American Economic Review*
96(4): 1308–1320. <https://doi.org/10.1257/aer.96.4.1308>.

## Generated outputs

- `matched_pairs.csv`, `links.csv`, `mother_real.csv`, `child_real.csv` and the
  SQLite database under `data/processed/`.
- `ige_estimates.csv`, `adjusted_estimates.csv`: slopes, standard errors,
  intervals and sample sizes.
- `sample_flow.csv`, `checks.json`: matching and exclusion audit.
- `paired_cluster_bootstrap.csv`, `difference_intervals.csv`: uncertainty in
  specification changes.
- `income_bins.csv`: exact inputs to the binned figure.
- `01_single_vs_average.png`, `02_life_cycle.png`,
  `03_income_relationship.png`: three generated figures.
- `summary.json`, `versions.json`, `_article.md`: article values, software
  versions, and generated prose/tables/SQL.

The code checks input hashes, unique individual and person-year keys,
documented family links, CPI coverage, income-year counts, plausible birth-year
ordering and one row per matched child. Results are generated from data and
queries; numeric statements and SQL displayed in the article are inserted
programmatically, rather than manually copied from output.

## Updating and publishing

From the website root, rerun the analysis and render the post and blog listing
using the commands above. Review the results, then commit changed Post 6
source/input files, generated outputs, and regenerated `docs/` files. Leave
large archive caches and `data/reacquired/` out of Git.

- **Published article:** https://augenstern118.github.io/testrepo/blog/posts/post6/
- **Repository:** https://github.com/augenstern118/testrepo
