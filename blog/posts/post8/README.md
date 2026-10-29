# Blog Post 8: Why a 95% Wage Interval Can Miss the Truth

- [Article source](index.qmd)
- [Article template](_article-template.qmd)
- [Run the analysis](R/run_analysis.R)
- [Numerical summary](results/summary.csv)
- [Hypothesis-test results](results/hypothesis_tests.csv)

## Question and data

Could a correctly constructed 95% interval from a wage survey still miss the
population mean? The article uses simulation to distinguish one survey's
bootstrap uncertainty, repeated-survey coverage, and evidence against a null
wage benchmark. All observations are explicitly **simulated**, not CPS data
or actual wages from a city. No empirical wage or policy claim is intended.

The teaching population is lognormal:

`log(wage) ~ Normal(log(30) - 0.35^2 / 2, 0.35^2)`.

This sets the arithmetic population mean to $30/hour. It is a deliberately
specified example, not an estimated model of the U.S. wage distribution.
The null model instead has mean $28/hour with the same log-standard deviation
0.35. Observations are independent; survey weights are not needed for these
i.i.d. simulated samples.

## Replication in RStudio

Software: R 4.1 or later, the R package `jsonlite`, and Quarto. The supplied
article and results are already generated. Rendering the supplied `index.qmd`
does not rerun simulations and needs no data downloads or running R server.

To regenerate **all analysis, figures and article numbers**, run in the
RStudio Console from the website root, where `_quarto.yml` is located:

```r
source("blog/posts/post8/R/run_analysis.R")
```

From inside the `post8` folder, the equivalent is:

```r
source("R/run_analysis.R")
```

Then run in the RStudio Terminal from the website root:

```bash
quarto render blog/posts/post8/index.qmd
quarto render blog/index.qmd
```

The runner restores the original working directory even after an error.
Edit `_article-template.qmd` when revising article text: the R publisher fills
its numerical placeholders to create `index.qmd`. Rerun analysis after changing
the simulation design, R code or template. Do not edit calculated numbers by hand.
The underscore keeps the template out of the Quarto blog listing.

## Three separate experiments

1. **One-sample bootstrap.** A fixed simulated sample of 400 wages is drawn.
   Samples of size 30 and 100 use its first observations, so the interactive
   examples are nested, not three unrelated selected samples. At each size,
   4,999 resamples with replacement produce bootstrap means. Confidence
   intervals use the 5th/95th or 2.5th/97.5th percentiles (`quantile`, type 7).
   The true mean is not used to construct intervals.
2. **Coverage.** For each sample size, 1,000 new independent population samples
   are drawn. Each gets its own 999-resample bootstrap and 90%/95% percentile
   intervals. Coverage is the fraction containing $30. The figure shows the
   first 60 intervals in original order; its coverage, mean width and Monte
   Carlo standard error use all selected 100, 500 or 1,000 experiments.
   The standard error is `sqrt(coverage * (1 - coverage) / experiments)`.
3. **Null test.** At each size, 10,000 new samples come from the $28-mean null
   lognormal population. The statistic is
   `Z = (sample_mean - 28) / (null_sd / sqrt(n))`, where
   `null_sd = 28 * sqrt(exp(0.35^2) - 1)`. This SD is known within the teaching
   model; the distribution is simulated rather than assumed exactly normal.
   The two-sided ordering uses `abs(Z)`. Rejection cutoffs are plus/minus the
   simulated `(1-alpha)` quantile of `abs(Z)`. The Monte Carlo p-value is
   `(1 + sum(abs(null_Z) >= abs(observed_Z))) / (10000 + 1)`.

The master seed is `20261029`, with documented deterministic offsets for each
sample size and simulation stage. `RNGkind` explicitly fixes the uniform,
normal and sampling algorithms. The code never searches seeds to obtain
particular findings. The shipped session information records the runtime.

## File organization

| Location | Content |
|---|---|
| `index.qmd` | Generated submission article with computed statements |
| `_article-template.qmd` | Editable article text and numerical placeholders |
| `R/01_simulate.R` | Population draws, bootstrap, coverage and null testing |
| `R/02_publish.R` | Interactive HTML, static figures and article generation |
| `R/run_analysis.R` | One-command reproduction entry point |
| `data/example_sample.csv` | The original 400 simulated wages |
| `data/simulation_parameters.csv` | Seed, model parameters and simulation counts |
| `results/bootstrap_draws.csv` | Individual bootstrap means for each sample size |
| `results/coverage_intervals.csv` | Every repeated survey's mean and intervals |
| `results/null_draws.csv` | Every simulated null statistic |
| `results/summary.csv` | Sample intervals, coverage, Monte Carlo SE and average width |
| `results/hypothesis_tests.csv` | Observed statistics, critical values, p-values and decisions |
| `results/bootstrap.html`, `coverage.html`, `null.html` | Generated interactive figures |
| `results/01_bootstrap.png`, `02_coverage.png`, `03_null_test.png` | Static default-case figures |
| `results/sessionInfo.txt` | R/package versions |
| `templates/figure.html` | Common HTML structure for the three explorers |
| `assets/figures.js`, `figures.css` | Display controls and styling; no statistical simulation in JavaScript |
| `assets/plotly-2.25.2.min.js`, `PLOTLY-LICENSE.txt` | Local Plotly library and MIT license |

Browser controls select precomputed R results. They do not generate new data
on every click. The vendored library works without a CDN or application server.
Article numbers refer to n=400, 95% confidence and 1,000 survey experiments;
controls change figures, not the fixed article text. All results, including
non-default cases, are saved. Quarto copies assets and results into `docs/`.

## Interpretation limits

Coverage is a long-run property of a procedure, not a posterior probability
for a fixed parameter. Percentile-bootstrap coverage need not exactly match
its nominal level, especially for small or more skewed samples. Monte Carlo
noise and finite bootstrap resampling also affect the measured rate.

More workers can improve estimation precision; more repeated survey experiments
improve the precision of the coverage estimate. These are different quantities.
The null test assumes the entire stated lognormal model. Its p-value is not
the probability that the null is true, an effect-size estimate or evidence
about any real city's wages. The bootstrap interval and model-based null test
are distinct constructions, not claimed to be exact inversions of each other.

## Sources

- [NIST: confidence intervals and repeated sampling](https://www.itl.nist.gov/div898/handbook/prc/section1/prc14.htm)
- [R: sample quantiles, including type 7](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/quantile.html)
- [R: bootstrap confidence-interval methods](https://stat.ethz.ch/R-manual/R-devel/library/boot/html/boot.ci.html)
- [Phipson and Smyth (2010): finite-simulation p-values](https://pubmed.ncbi.nlm.nih.gov/21044043/)
- [Plotly.js source and license, v2.25.2](https://github.com/plotly/plotly.js/tree/v2.25.2)
