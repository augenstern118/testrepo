# Blog Post 3 — IPUMS CPS data visualization

This folder belongs at `blog/posts/post3/` in the existing Quarto website. It
contains the article, preparation code, weighted analysis, and replication
instructions. The project investigates how the descriptive college earnings
premium varies over time, by sex, and across the life cycle.

## 1. Create the IPUMS CPS extract

1. Sign in or register at <https://cps.ipums.org/cps/>.
2. Choose **Get Data** and select these **ASEC** samples:
   2001, 2005, 2009, 2013, 2017, 2020, 2021, 2022, 2023, 2024, and 2025.
   These correspond to income years 2000, 2004, 2008, 2012, 2016, and
   2019–2024 because ASEC income questions refer to the previous calendar year.
3. Add these variables:
   `YEAR`, `ASECWT`, `AGE`, `SEX`, `EDUC`, `INCWAGE`, `WKSWORK1`,
   `UHRSWORKLY`, and `CPI99`.
4. Submit the extract using the default rectangular fixed-width format.
5. When it finishes, download both **Data** (`.dat.gz`) and **DDI** (`.xml`).
6. Put both files, still with their matching original names, in `data/raw/`.

Do not upload the raw microdata to GitHub. The included `.gitignore` prevents
accidental commits while retaining these instructions.

## 2. Install packages and render

From the website root in the RStudio Console, run once:

```r
source("blog/posts/post3/setup.R")
```

Then open `blog/posts/post3/index.qmd` and click **Render**. To update the blog
listing and all site files, use **Build Website** before committing and pushing.

The code reads the DDI and data with `ipumsr`, restricts the analysis to wage
and salary workers ages 25–64 who worked at least 50 weeks and usually at least
35 hours per week, converts earnings to the latest income year's dollars using
`CPI99`, and calculates every median with the person weight `ASECWT`.

## 3. Generated outputs

Rendering creates these reproducible files in `results/`:

- `earnings_by_education.csv`
- `college_premium.csv`
- `college_premium_by_sex.csv`
- `earnings_by_age.csv`
- `01_earnings_trend.png`
- `02_premium_by_sex.png`
- `03_age_profile.png`
- `sessionInfo.txt`

The Quarto article generates its numeric claims and figures directly from these
weighted calculations; nothing needs to be copied manually into the prose.

## Data and interpretation notes

- `ASECWT` is the appropriate person-level weight for ASEC income analysis.
- `INCWAGE` is annual pre-tax wage and salary income for the prior calendar year.
- Weekly earnings equal real annual wage income divided by weeks worked.
- The sample excludes self-employment income and is restricted to full-time,
  full-year workers to improve comparability of earnings across education groups.
- The “college premium” is descriptive, not a causal return to schooling. It may
  reflect occupation, experience, field of study, location, selection, and other
  differences between education groups.
- CPS topcoding, nonresponse, changing population controls, and sampling error
  remain limitations. The post does not report standard errors.

## Sources

- IPUMS CPS: <https://cps.ipums.org/cps/>
- CPS weight guidance: <https://cps.ipums.org/cps/sample_weights.shtml>
- Inflation adjustment (`CPI99`): <https://cps.ipums.org/cps/cpi99.shtml>
- Variable documentation: `INCWAGE`, `WKSWORK1`, `UHRSWORKLY`, and `EDUC` on
  the IPUMS CPS website.

For the assignment, submit the published Blog Post 3 URL and the existing GitHub
repository URL after rebuilding, committing, and pushing the website.
