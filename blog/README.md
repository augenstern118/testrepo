# Junzheng Yang's Economics Blog

Quarto coursework for Computational Methods for Economists.

- [Published website](https://augenstern118.github.io/testrepo/)
- [Blog listing](https://augenstern118.github.io/testrepo/blog/)
- [GitHub repository](https://github.com/augenstern118/testrepo)

## Articles and replication

| Post | Topic | Article source | Replication |
|---|---|---|---|
| 1 | What can a p-value establish in a funding decision? | [index.qmd](blog/posts/post1/index.qmd) | [README](blog/posts/post1/README.md) |
| 2 | Where should an economics student start the job search? | [index.qmd](blog/posts/post2/index.qmd) | [README](blog/posts/post2/README.md) |
| 3 | Can the college earnings premium grow without larger real paychecks? | [index.qmd](blog/posts/post3/index.qmd) | [README](blog/posts/post3/README.md) |
| 4 | Mortgage rates and housing payments | [index.qmd](blog/posts/post4/index.qmd) | [README](blog/posts/post4/README.md) |
| 5 | State population growth and domestic migration | [index.qmd](blog/posts/post5/index.qmd) | [README](blog/posts/post5/README.md) |
| 6 | Parent-child income matching and intergenerational elasticity | [index.qmd](blog/posts/post6/index.qmd) | [README](blog/posts/post6/README.md) |
| 7 | Interactive employment visualization with Plotly | [index.qmd](blog/posts/post7/index.qmd) | [README](blog/posts/post7/README.md) |
| 8 | How can a 95% wage interval miss the truth? | [index.qmd](blog/posts/post8/index.qmd) | [README](blog/posts/post8/README.md) |

## Repository organization

| Location | Purpose |
|---|---|
| `_quarto.yml` | Website configuration |
| `blog/index.qmd` | Blog listing |
| `blog/posts/postN/index.qmd` | Article source |
| Each post's `R/`, Python or SQL files | Analysis code |
| Each post's `data/` | Inputs, provenance or access instructions |
| Each post's `results/` | Programmatically generated tables, figures and other outputs |
| Each post's `README.md` | Data definitions and replication commands |
| `docs/` | Rendered website published through GitHub Pages |

## Replication and publishing

Open the website's `.Rproj` file in RStudio. Follow each post's linked README
for its data inputs, software requirements and analysis commands. Commands
specified for the website root run where `_quarto.yml` is located.

For example, rebuild Posts 2 and 3 and the blog listing from that directory:

```bash
quarto render blog/posts/post2/index.qmd
quarto render blog/posts/post3/index.qmd
quarto render blog/index.qmd
```

Post 3 requires a separately obtained local IPUMS extract. Post 6 requires
its documented Python analysis step before rendering. Post 8 includes saved
simulation results; its README explains how to regenerate them in R. A full `quarto render`
requires the inputs and dependencies for every article.

Commit changed article sources, analysis code, relevant README/data files,
generated results and rendered `docs/` files. Keep Post 3's raw microdata
excluded from Git. Edit source files and rerender rather than editing HTML.
