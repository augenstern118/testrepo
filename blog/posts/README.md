# Junzheng Yang's Economics Blog

Quarto website for Computational Methods for Economists. Analysis code is
written in R and can be run in RStudio. Source posts are under `blog/posts/`;
the rendered website is under `docs/`, as configured in `_quarto.yml`.

- **Website:** https://augenstern118.github.io/testrepo/
- **Blog:** https://augenstern118.github.io/testrepo/blog/

## Find the posts and their code

| Post | Article source | Replication instructions |
|---|---|---|
| 1: Interpreting a p-value in a funding decision | [index.qmd](blog/posts/post1/index.qmd) | [README](blog/posts/post1/README.md) |
| 2: Web scraping for a job-search shortlist | [index.qmd](blog/posts/post2/index.qmd) | [README](blog/posts/post2/README.md) |
| 3: IPUMS CPS college earnings comparisons | [index.qmd](blog/posts/post3/index.qmd) | [README](blog/posts/post3/README.md) |
| 4: Housing prices, mortgage rates and payment burden | [index.qmd](blog/posts/post4/index.qmd) | [README](blog/posts/post4/README.md) |
| 5: GIS maps of population growth and migration | [index.qmd](blog/posts/post5/index.qmd) | [README](blog/posts/post5/README.md) |

Each post's README explains its own inputs, packages, assumptions, outputs,
and replication commands. CPS raw-data requirements are documented separately
in Post 3; they are not required to reproduce Post 5.

## Reproduce Blog Post 5

Open this website's `.Rproj` file in RStudio. From the website root, run in the
**Console**:

```r
source("blog/posts/post5/setup.R")
source("blog/posts/post5/R/run_project.R")
```

Then run in the RStudio **Terminal**:

```bash
quarto render blog/posts/post5/index.qmd
quarto render blog/index.qmd
```

The [Post 5 README](blog/posts/post5/README.md) documents all files, formulas,
GIS decisions and limitations. Both official Census inputs are included, so
reproduction needs no network access. The analysis generates two maps and a
component chart using R; no local spatial system libraries are needed.

- [Original data manifest](blog/posts/post5/data/raw/manifest.csv)
- [Preparation and GIS code](blog/posts/post5/R/01_prepare.R)
- [Analysis and figures](blog/posts/post5/R/02_analyze.R)
- [All 50 states](blog/posts/post5/results/state_comparison.csv)
- [FIPS join audit](blog/posts/post5/results/join_audit.csv)

For earlier posts, use the corresponding README in the table above.

## Website layout

| Location | Purpose |
|---|---|
| `_quarto.yml` | Site navigation, theme and `docs` output directory |
| `index.qmd`, `bio.qmd`, `resume.qmd` | Main website pages |
| `blog/index.qmd` | Blog listing |
| `blog/posts/post*/` | Article sources, code, inputs and generated results |
| `docs/` | Generated site files used by GitHub Pages |
| `images/`, `files/`, `styles.css` | Shared website assets |

## Update the published site

Render the changed post and `blog/index.qmd`, then commit source files and
regenerated `docs/` files. For Post 5:

```bash
git add README.md blog/posts/post5 docs
git commit -m "Add Post 5 GIS population growth analysis"
git push origin main
```

Keep the existing GitHub Pages configuration. Check the published page after
deployment completes; the published URL alone is not a substitute for the
source and replication instructions above.
