# Sources

## Classroom stock predictions

`class_universe.txt` reproduces the 95 ticker symbols listed in the supplied
`UPenn_XGBoostStockPrediction copy.R`. The professor's R Crash Course Assignment,
“Third Time is the Charm” section (pp. 30–31), describes the model and example
graph. The original teaching files are not included in this archive.

`daily_prices.csv.gz` covers all 95 tickers and SPY, with 1,190 sessions per
ticker, January 3, 2022–September 30, 2026. Source: the
[November 2026 sp500-data release](https://github.com/Johnbrick123/sp500-data/releases/tag/snapshot-2026-11).
The selected rows are Yahoo-sourced OHLCV with closing prices adjusted by
the snapshot provider for dividends and splits. Those `adj_close` values
need not match a live Yahoo download exactly. The source calendar and ticker
rows are complete; no prices are imputed. The model still uses the fixed
classroom universe, which is not a point-in-time stock selection.

To reconstruct the extract from the optional full snapshot, download
[`prices.parquet`](https://github.com/Johnbrick123/sp500-data/releases/download/snapshot-2026-11/prices.parquet)
from the pinned release (SHA-256
`7b58eeafc855a502469fc5090eb703f76516172deebe13d51609fd6eb2c5f3f5`),
then run `scripts/snapshot_prices.py` with the parquet path (Python and
`pyarrow`). Neither download nor Python is required to run the R analysis.

## Stock market game

`class_game_summary.csv` contains paired aggregates from the supplied
`Full_Results copy.xlsm` (`Sheet1`) and portfolio labels from
`stockmarketgameresultsFall2026.R`. All 45 teams had both ending balances.
Each paired gap subtracts the intuition-based balance from the
indicator-based balance. Team-level results and the original workbook are
not redistributed. To refresh the summary from a local copy, run:

```sh
python blog/posts/post9/scripts/summarize_class_game.py "path/to/Full_Results copy.xlsm"
```

The script reads stored values and does not execute workbook macros. The game
results provide motivation and never enter the market forecast or backtest.
