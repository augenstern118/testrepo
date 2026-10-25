# Post 7 data dictionary

`raw/fred_employment.csv` is the original multi-series FRED response, acquired
programmatically. `raw/manifest.csv` records its source, acquisition time,
requested window, units, seasonal adjustment, and file hashes. The download
can include extra dates; only February 2020–December 2024 enters the analysis.

`series.csv` maps twelve FRED IDs to readable labels, original BLS series
codes, the `total`/`sector` distinction, chart colors, and source pages.

| Processed field | Definition |
|---|---|
| `date` | Observation month, represented by the month's first calendar date |
| `series_id`, `sector` | Source ID and readable label |
| `kind` | `total` for PAYEMS, otherwise `sector` |
| `jobs_thousands` | Published seasonally adjusted payroll employment, thousands of jobs |
| `baseline_thousands` | Same series' February 2020 employment |
| `change_thousands` | Current jobs minus baseline, thousands of jobs |
| `change_pct` | 100 times current jobs divided by baseline minus 100 |

There are 708 processed rows (59 months × 12 series). Government is one of
the eleven broad sectors; the national total must not be added to them.
The [post README](../README.md) explains methods, controls, and replication.
