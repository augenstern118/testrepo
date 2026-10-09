# Blog Post 1: A P-Value of 0.03 Is Not a Funding Recommendation

## Purpose

Explain why a p-value is a probability of possible test results under a null
model, not the probability that the hypothesis is true. A hypothetical
job-training decision connects that distinction to benefit-cost reasoning.

The article was revised October 8, 2026 to address feedback about unsupported
claims of widespread misunderstanding and an overly strong conclusion.

## Folder structure

- `index.qmd`: Quarto article, generated table, and expandable R code.
- `R/analysis.R`: readable base-R calculations and figure creation.
- `data/example_inputs.csv`: invented teaching inputs, not observed trial data.
- `results/summary.csv`: full-precision calculated statistics.
- `results/display_table.csv`: formatted table shown in the article.
- `results/null_curve.csv`: points used to draw the normal sampling distribution.
- `results/null_distribution.png`: generated figure.
- `results/sessionInfo.txt`: R version and environment used for replication.

## Requirements

R and RStudio, plus Quarto (already bundled with recent RStudio versions).
The analysis script uses only base R. Rendering uses `knitr` and `rmarkdown`;
if these are missing, run `install.packages(c("knitr", "rmarkdown"))` once
in the RStudio Console. No other analysis packages, Rtools, downloads, or
API credentials are required. Rendering does not retrieve the cited articles.

## Replication in RStudio

1. Put the complete `post1` folder under `blog/posts/` in your existing website.
   Replace the old `index.qmd` and keep the accompanying folders together.
2. Open the website's `.Rproj` file.
3. For calculations alone, run in the Console from the website root:

   ```r
   source("blog/posts/post1/R/analysis.R")
   ```

   Alternatively, from the `post1` folder run `source("R/analysis.R")`.
   The script supports these two locations without changing your working directory.
4. Render and update the blog listing in the RStudio **Terminal** from the
   website root (the folder containing `_quarto.yml`):

   ```bash
   quarto render blog/posts/post1/index.qmd
   quarto render blog/index.qmd
   ```

   Opening `index.qmd` and clicking **Render** also builds the article.
   Re-rendering `blog/index.qmd` refreshes the title and thumbnail on the blog list.
5. For this website, `_quarto.yml` sets `output-dir: docs`. Check the local
   preview before committing the source folder and generated website files:

   ```bash
   git add blog/posts/post1 docs
   git commit -m "Revise Post 1 motivation and interpretation"
   git push origin main
   ```

   Commit generated changes to `docs/blog/index.html`, `docs/listings.json`,
   `docs/search.json`, and the article assets when present. Adding `docs` covers
   these files. GitHub Pages publication can take a few minutes.

## Model and limitations

All program amounts are illustrative: wage effect estimate $20/month,
known standard error $9.20, and cost $100/participant/month. No raw observations
or real program effects are inferred. The model assumes a normal sampling
distribution centered on the true effect with the specified known standard error.

For testing a zero average effect, the two-sided p-value is
`2 * pnorm(-abs(estimate / standard_error))` (approximately 0.0297).
The 95% interval is `estimate +/- qnorm(0.975) * standard_error`
(approximately $1.97 to $38.03). The figure shows both normal tails outside
the observed estimate's absolute magnitude. Tail probabilities are calculated
analytically, not by counting or integrating the plotted grid.

The p-value is not a posterior probability, a probability the decision is wrong,
or an effect size. The confidence interval does not assign a 95% posterior
probability to this particular interval. Repeated intervals constructed by this
procedure cover the true effect 95% of the time under the model.

The cost comparison is a teaching illustration, not a full benefit-cost analysis:
non-wage benefits, duration, taxation, and distributional effects are omitted.

## Sources

1. Lytsy, P., Hartman, M., and Pingel, R. (2022). *Misinterpretations of P-values
   and statistical tests persists among researchers and professionals working
   with statistics and epidemiology*. Upsala Journal of Medical Sciences, 127.
   DOI: https://doi.org/10.48101/ujms.v127.8760
   Accessible abstract: https://pubmed.ncbi.nlm.nih.gov/35991465/
   The article reports the authors' published survey percentages; it does not
   treat the respondents as a representative sample of all researchers.
2. Wasserstein, R. L., and Lazar, N. A. (2016). *The ASA's Statement on
   p-Values: Context, Process, and Purpose*. The American Statistician, 70(2),
   129-133. DOI: https://doi.org/10.1080/00031305.2016.1154108
   ASA's official release reproducing the six principles:
   https://www.amstat.org/asa/files/pdfs/p-valuestatement.pdf

Sources checked October 8, 2026. The percentages are attributed literature
evidence, not an analysis of downloaded survey records. All training figures
and statistics are generated locally from the openly documented synthetic inputs.
