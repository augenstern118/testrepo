# Blog Post 3: A Bigger College Earnings Premium Without Bigger Paychecks?

- [Published article](https://augenstern118.github.io/testrepo/blog/posts/post3/)
- [Article source](index.qmd)
- [Data preparation](R/01_prepare.R)
- [Weighted analysis and figures](R/02_analyze.R)

## Question

Did a larger bachelor's earnings premium between 2000 and 2024 mean that
bachelor's graduates earned substantially more in real terms? Three figures
show the relative premium, the underlying real earnings levels, and changes
within sex/education groups. The comparison is descriptive, not a causal
estimate of college's return.

## Data needed for replication

Use an [IPUMS CPS](https://cps.ipums.org/cps/) rectangular ASEC extract with
these survey years:

**2001, 2005, 2009, 2013, 2017, 2020, 2021, 2022, 2023, 2024 and 2025.**

These correspond to income years 2000, 2004, 2008, 2012, 2016 and 2019–2024.
Annual wage income refers to the calendar year before the survey.

Required variables:

`YEAR`, `ASECWT`, `AGE`, `SEX`, `EDUC`, `INCWAGE`, `WKSWORK1`, `UHRSWORKLY`.

Put exactly one matching DDI `.xml` and compressed `.dat.gz` file in
`data/raw/`. Keep the data compressed. The file locator also accepts
`.csv.gz`; the documented route uses fixed-width `.dat.gz`. The current
code does not require an extract-level `CPI99` variable. ASEC 2026 is outside
the preparation script's supported year lookup.

Raw microdata are excluded from Git. Each replicator obtains the extract
through IPUMS and follows its access conditions. The repository includes
code, aggregate outputs and replication instructions.

## Replication

Software: R 4.1 or later and Quarto. Dependencies are `ipumsr`, `dplyr`,
`tidyr`, `ggplot2`, `stringr`, `forcats`, `readr`, `scales`, `haven`, `knitr`
and `rmarkdown`; the fixed-width reader may also require `hipread` in the
existing R environment.

Open the website's `.Rproj` in RStudio and retain the local extract in
`blog/posts/post3/data/raw/`. From the website root, run in the Terminal:

```bash
quarto render blog/posts/post3/index.qmd
quarto render blog/index.qmd
```

Opening `index.qmd` and clicking Render performs the same analysis. It reads
the local extract, recalculates weighted medians, writes the output files
and renders the article. The interpretation check stops rendering if a
changed extract no longer supports the written findings.

## Sample, weights and transformations

- The preparation keeps survey ages 25–64, 50–52 weeks worked, at least 35
  usual weekly hours excluding the 999 not-in-universe code, positive valid
  wage income, and positive finite ASEC person weights.
- `INCWAGE` is annual pre-tax wage and salary income. Weekly earnings equal
  annual wage income divided by weeks worked. They exclude self-employment
  income and do not measure total household resources.
- `ASECWT` weights each person. The weighted median is the first sorted value
  where cumulative positive weight reaches half the group's total weight.
  Raw observation counts are recorded separately from population weights.
- The published CPI99 factors stored in `R/01_prepare.R` transform income to
  2024 dollars: `INCWAGE * cpi99_factor / 0.531 / WKSWORK1`. The factor 0.531
  corresponds to ASEC 2025, whose income refers to 2024.
- The premium equals `100 * (BA weighted median / HS weighted median - 1)`.
  It is a ratio of group medians, not a median individual treatment effect.
- Endpoint changes equal `100 * (2024 median / 2000 median - 1)`. They are
  calculated for the pooled sample and separately within sex/education groups.
- `EDUC` labels identify degree categories. The main comparison uses high-school
  and bachelor's graduates. The full education summary is retained as an
  audit output. The CPS female/male categories are labeled women/men.

## File organization and outputs

| Location | Content |
|---|---|
| `index.qmd` | Short article, computed statements and three figures |
| `R/01_prepare.R` | Read extract, classify groups, restrict sample and adjust dollars |
| `R/02_analyze.R` | ASEC-weighted medians, comparisons, plots and saved outputs |
| `data/raw/` | Local matching XML/data pair; excluded from Git |
| `results/earnings_by_education.csv` | Weighted medians, population weight totals and observation counts |
| `results/earnings_by_sex.csv` | Weighted medians by income year, sex and comparison education group |
| `results/college_premium.csv` | Pooled bachelor's/high-school premium |
| `results/college_premium_by_sex.csv` | Within-sex premiums and their underlying medians |
| `results/earnings_change_overall.csv` | Pooled endpoint medians and percentage changes |
| `results/earnings_change_by_sex.csv` | Endpoint medians and changes by sex/education |
| `results/01_college_premium.png` | Figure 1: relative earnings premium |
| `results/02_real_earnings.png` | Figure 2: real median earnings levels |
| `results/03_earnings_change_by_sex.png` | Figure 3: endpoint changes by sex/education |
| `results/sessionInfo.txt` | R and package versions |

The generated website is saved under the site's `docs/` directory. All article
numbers and figures are generated programmatically. The analysis helper
`make_cps_outputs()` can also recreate comparisons and figures from already
weighted aggregate tables; this does not replace microdata preparation or
independently verify the original weighted estimates.

## Interpretation limits

The figures describe the CPS population within the sample restrictions.
They exclude absent or unstable wage employment and do not follow the same
workers through time. Changes in group composition, nonresponse, top coding,
population controls and sampling error can affect medians. No confidence
intervals are reported. A small difference between sex-specific premiums
should not be described as a clear statistical difference. The analysis
cannot attribute patterns to industries, policies, individual career growth
or the causal effect of college.

## Sources

- [IPUMS CPS data](https://cps.ipums.org/cps/)
- [Person and household weight guidance](https://cps.ipums.org/cps/sample_weights.shtml)
- [Published CPI99 factors](https://cps.ipums.org/cps/cpi99.shtml)
- [INCWAGE](https://cps.ipums.org/cps-action/variables/INCWAGE),
  [WKSWORK1](https://cps.ipums.org/cps-action/variables/WKSWORK1),
  [UHRSWORKLY](https://cps.ipums.org/cps-action/variables/UHRSWORKLY),
  [EDUC](https://cps.ipums.org/cps-action/variables/EDUC), and the extract's DDI.
