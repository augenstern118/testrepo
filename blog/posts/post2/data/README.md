# Post 2 inputs and extracted data

`raw/` contains the original six HTML Summary fragments. `raw/manifest.csv`
records their source URLs, September 20, 2026 capture date/method and hashes.
`processed/careers.csv` is regenerated from those fragments; do not edit it by hand.
`occupation_scope.csv` is separately author-documented SOC classification metadata.

## Extracted fields

| Field | Meaning/unit |
|---|---|
| `id`, `occupation`, `source_url` | Stable profile ID, display name, BLS source |
| `median_pay_usd`, `pay_year` | Median annual pay in nominal USD; common wage year |
| `education`, `experience` | Typical entry-level education and related experience |
| `employment` | Number of jobs at the projection start year |
| `growth_pct`, `net_new_jobs` | Decade growth percent and net employment change |
| `annual_openings` | Projected average annual openings, including replacement |
| `projection_start`, `projection_end` | Projection interval |
| `access_date`, `capture_method` | Original HTML provenance |

## Classification fields

`soc_codes` lists all detailed codes represented by a profile; semicolons
separate components. `soc_title`, `scope`, `work_focus`, `definition_url` and
`mapping_note` document the author-reviewed mapping. None identifies a worker's
academic major. The financial profile is a two-code aggregate. The mapping
is joined by profile ID and checked for repeated component codes across rows.

All profiles use May 2025 wages and 2025-2035 projections. Occupation-level
aggregates are not starting salaries or a sample of economics degree holders.
See ../README.md for the full replication workflow and limitations.
