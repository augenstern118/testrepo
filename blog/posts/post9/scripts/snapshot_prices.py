"""Extract the classroom tickers from the documented November 2026 snapshot.

Run with Python and pyarrow. Pass the downloaded prices.parquet as argument.
The article and the R analysis already include the resulting extract.
"""
import argparse
import csv
import gzip
import io
from datetime import datetime
from pathlib import Path

import pyarrow.parquet as pq

post = Path(__file__).resolve().parents[1]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("parquet", type=Path)
    args = parser.parse_args()
    symbols = (post / "data" / "class_universe.txt").read_text().split() + ["SPY"]
    columns = ["date", "ticker", "open", "high", "low", "close", "volume",
               "adj_close", "source"]
    data = pq.read_table(args.parquet, columns=columns, filters=[
        ("ticker", "in", symbols),
        ("date", ">=", datetime(2022, 1, 1)),
        ("date", "<=", datetime(2026, 9, 30)),
    ]).sort_by([("date", "ascending"), ("ticker", "ascending")])
    records = data.to_pylist()
    if {r["source"] for r in records} != {"yahoo"}:
        raise ValueError("Unexpected price source.")
    if {r["ticker"] for r in records} != set(symbols):
        raise ValueError("The source is missing tickers.")
    with (post / "data" / "daily_prices.csv.gz").open("wb") as stream:
        with gzip.GzipFile(fileobj=stream, mode="wb", filename="", mtime=0) as compressed:
            with io.TextIOWrapper(compressed, encoding="utf-8", newline="") as text:
                writer = csv.writer(text, lineterminator="\n")
                writer.writerow(columns[:-1])
                for row in records:
                    writer.writerow([row["date"].date().isoformat()] +
                                    [row[c] for c in columns[1:-1]])
