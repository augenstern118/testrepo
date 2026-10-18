# Post 5 data dictionary

## Raw inputs

- `raw/population_2025.csv`: original Census Population Division file, Vintage
  2025. The script selects summary level 040 and the 50 states.
- `raw/states_2024_albers.json`: original TIGERweb generalized 20M state polygon
  response, requested in EPSG:5070 meters. Its geographic vintage is 2024.
- `raw/manifest.csv`: public source URLs, access date, descriptions and hashes.

## Processed state fields

| Field | Definition |
|---|---|
| `fips` | Two-character state identifier; join key |
| `state`, `boundary_state`, `abbreviation` | Names from the two inputs and postal abbreviation |
| `population_2024`, `population_2025` | July 1 resident population estimates |
| `average_population` | Arithmetic mean of those two endpoints |
| `population_change` | Endpoint difference, matching `NPOPCHG_2025` |
| `domestic` | `DOMESTICMIG2025`, net domestic migration |
| `international` | `INTERNATIONALMIG2025`, net international migration |
| `natural` | `NATURALCHG2025`, births minus deaths |
| `residual` | `RESIDUAL2025`, Census reconciliation adjustment |
| `*_rate` | Corresponding count / average population * 1,000 |

`processed/state_rates.csv` retains all 50 states. These are aggregate counts
and rates, not individual-level records. Component rates use one common
denominator, so they reconcile to the total rate before rounding.

`processed/map_vertices.csv` adds `ring`, `vertex`, `x` and `y` to the matched
state attributes. Its projected coordinates are meters; row order is preserved
for polygon drawing. It includes only the contiguous 48 states. Multiple rings
can represent disconnected pieces or holes; the plotting rule handles both.
Do not edit either processed file by hand; run `R/run_project.R` instead.
