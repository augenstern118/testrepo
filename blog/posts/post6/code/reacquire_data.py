"""Optional: reconstruct the small included inputs from official BLS downloads.

The analysis itself runs offline. The two original archives total about 590 MB
and contain several GB of uncompressed CSV data. They stay compressed on disk.
Usage: python code/reacquire_data.py --archive-dir path/to/cache
Default output is data/reacquired, so the supplied inputs are preserved.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import urllib.request
import zipfile

import pandas as pd

POST = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive-dir", type=Path, default=POST/"data"/"download_cache")
    parser.add_argument("--output", type=Path, default=POST/"data"/"reacquired")
    args = parser.parse_args()
    args.archive_dir.mkdir(parents=True, exist_ok=True)
    args.output.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((POST/"data/raw/sources.json").read_text())
    variables = pd.read_csv(POST/"data/raw/variables.csv", dtype=str)
    codebooks = []
    for cohort, source_key, filename in [
        ("mother", "nlsy79", "nlsy79_selected.csv"),
        ("child", "nlscya", "nlscya_selected.csv"),
    ]:
        source = manifest[source_key]
        archive = args.archive_dir / source["url"].rsplit("/", 1)[-1]
        if not archive.exists():
            print(f"Downloading {archive.name} from BLS ...", flush=True)
            urllib.request.urlretrieve(source["url"], archive)
        with archive.open("rb") as stream:
            actual_hash = hashlib.file_digest(stream, "sha256").hexdigest()
        if actual_hash != source["archive_sha256"]:
            raise ValueError(f"BLS archive changed: {archive.name}. Use the supplied inputs or review the new release.")
        cols = variables.loc[variables.cohort == cohort, "variable"].tolist()
        with zipfile.ZipFile(archive) as z:
            with z.open(source["member"]) as stream:
                frame = pd.read_csv(stream, usecols=cols)
            frame[cols].to_csv(args.output/filename, index=False, lineterminator="\n")
            codebook_name = source["member"].replace(".csv", ".cdb")
            text = z.read(codebook_name).decode("utf-8", errors="replace")
            for block in re.split(r"(?m)^-{30,}\s*\n", text):
                ref = re.match(r"([A-Z]\d{5}\.\d{2})", block)
                if ref and ref.group(1).replace(".", "") in cols:
                    codebooks.append(block)
        print(f"Extracted {filename}: {len(frame):,} rows", flush=True)
    (args.output/"codebook_selected.txt").write_text(
        ("\n" + "-"*80 + "\n").join(codebooks), encoding="utf-8", newline="\n")
    variables.to_csv(args.output/"variables.csv", index=False, lineterminator="\n")
    cpi_cache = args.archive_dir/"cu.data.1.AllItems"
    if not cpi_cache.exists():
        urllib.request.urlretrieve(manifest["cpi"]["url"], cpi_cache)
    cpi = pd.read_csv(cpi_cache, sep="\t")
    cpi.columns = cpi.columns.str.strip()
    cpi = cpi[(cpi.series_id.str.strip() == "CUUR0000SA0")
              & (cpi.period.str.strip() == "M13") & cpi.year.between(1990, 2019)]
    cpi = cpi[["year", "value"]].rename(columns={"value":"cpi_u"})
    cpi.to_csv(args.output/"cpi_u_annual.csv", index=False, lineterminator="\n")
    for item in manifest["included_files"]:
        path = args.output/item["file"]
        actual_hash = hashlib.sha256(path.read_bytes()).hexdigest()
        if actual_hash != item["sha256"]:
            raise ValueError(f"Reacquired file differs: {path.name}. Review the source release.")
    print("All reconstructed files match the included input hashes.")


if __name__ == "__main__":
    main()
