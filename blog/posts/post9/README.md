# Blog Post 9: Can a Better Stock Forecast Beat the S&P 500?

This project compares the original classroom XGBoost specification, a revised
XGBoost specification, and simple forecast and investment benchmarks. They use
the 95 tickers in the class script and the same frozen price snapshot.

## Replicate

From the website root in the RStudio Console:

```r
source("blog/posts/post9/R/run_analysis.R")
```

Tested with R 4.5.0 and `xgboost` 3.2.0.1. The analysis runs offline and
regenerates both figures, all results, and `index.qmd`. Edit
`_article-template.qmd` for prose changes.

The bundled article already includes the computed results. To render the post
and update the listing, use the RStudio Terminal at the website root:

```sh
quarto render blog/posts/post9/index.qmd
quarto render blog/index.qmd
```

## Files

| Location | Purpose |
|---|---|
| `index.qmd`, `_article-template.qmd` | Generated article and editable template |
| `R/01_data.R`, `data/` | Feature engineering and documented input snapshots |
| `R/02_models.R` | Chronological splits, tuning, and the portfolio backtest |
| `R/03_publish.R`, `results/` | Figures, metrics, and compressed held-out predictions |
| `scripts/` | Optional reproduction of the input snapshots |

## Classroom model and revision

The reference uses the predictor columns that enter the class recipe after the
date and symbol are marked as IDs. That includes same-day OHLCV, adjusted
price, one-day return, the original three lagged price ratios, one-month
volatility, the original short-run price ratio, and one-day excess return
relative to SPY. Neither the sign of those ratios nor the target formula is
changed for that model. The model uses 300 rounds, maximum depth five,
learning rate 0.05, zero minimum split gain, and minimum child weight 10.
It fits the XGBoost engine directly rather than loading the whole tidymodels
workflow. The input snapshot is fixed rather than queried from Yahoo at run
time, so this is a rerun of the specification, not a claim that the handout's
graph can be reproduced pixel for pixel.

The revision replaces raw stock price and volume levels with price and volume
ratios, fixes the direction of the momentum ratios, adds two cross-sectional
ranks, sets minimum child weight to 50, and tunes depth and rounds. It uses
only the July–November 2023 validation signals with completed returns by
year-end. All fits use an exit-date cutoff before the next split. The test
begins in January 2024. The forecast benchmark is the pooled mean of the
eligible training returns. RMSE is pooled; stock-ranking correlations average
daily Spearman correlations. A constant forecast has no rank correlation.

## Trading comparison

- The original formula is `adjusted[t + 20] / adjusted[t + 1] - 1`. Each signal
  uses that day's close or earlier. A 19-session signal spacing makes the prior
  exit and next entry coincide without overlapping return windows. SPY uses
  those exact closes. Both XGBoost models retain the intended class rule:
  top ten by predicted return, with weights proportional to positive scores
  (equal weight among ten if none are positive). A scalar `if/else` returns
  all ten weights instead of recycling the first one as the original `ifelse`
  expression can do. Portfolio weights sum to one.
- SPY buys once and stays invested. Equal weight rebalances the same 95 stocks
  each period. For both models and equal weight, the previous portfolio's
  holdings drift with realized returns. Turnover is the sum of absolute
  differences between the new and drifted weights, counting both buys and
  sells. Net growth is `(1 - trading_rate * turnover) * (1 + gross_return)`.
  The initial purchase is charged, with no assumed final liquidation.
- Wealth uses nominal dollars; returns, RMSE and turnover in CSV files are
  decimals. Drawdown uses only observed holding-period endpoints. The result
  is a historical comparison with a fixed stock list. It includes no risk
  adjustment, taxes, capacity limits, or intraperiod drawdown measurement.
