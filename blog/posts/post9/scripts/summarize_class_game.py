"""Summarize the supplied Fall 2026 workbook without executing Excel macros."""
import argparse
import csv
from pathlib import Path
from statistics import mean, median
from xml.etree import ElementTree as ET
from zipfile import ZipFile

NS = {"x": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}


def sheet_values(path):
    # This version of the class workbook stores the results in hidden Sheet1.
    with ZipFile(path) as book:
        sheet = ET.fromstring(book.read("xl/worksheets/sheet1.xml"))
        strings = ET.fromstring(book.read("xl/sharedStrings.xml"))
    shared = ["".join(item.itertext()).strip() for item in strings.findall("x:si", NS)]

    def value(cell):
        val = cell.findtext("x:v", namespaces=NS)
        if cell.get("t") == "s":
            return shared[int(val)]
        return val

    return [{cell.get("r").rstrip("0123456789"): value(cell)
             for cell in row.findall("x:c", NS)}
            for row in sheet.findall("x:sheetData/x:row", NS)]


def summarize(path):
    header, *rows = sheet_values(path)
    if (header.get("A"), header.get("B")) != ("portfolio1", "portfolio2"):
        raise ValueError("Expected portfolio1 and portfolio2 in columns A and B.")
    pairs = []
    for row in rows:
        first, second = row.get("A"), row.get("B")
        if first is None and second is None:
            continue
        if first is None or second is None:
            raise ValueError("Found a team with only one recorded balance.")
        pairs.append((float(first), float(second)))
    if not pairs:
        raise ValueError("No paired portfolio values were found.")

    intuition, indicator = zip(*pairs)
    gap = [b - a for a, b in pairs]
    return {
        "teams": len(pairs),
        "indicator_ahead": sum(d > 0 for d in gap),
        "intuition_ahead": sum(d < 0 for d in gap),
        "ties": sum(d == 0 for d in gap),
        "mean_intuition_usd": f"{mean(intuition):.6f}",
        "mean_indicator_usd": f"{mean(indicator):.6f}",
        "mean_paired_gap_usd": f"{mean(gap):.6f}",
        "median_paired_gap_usd": f"{median(gap):.6f}",
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workbook", type=Path)
    args = parser.parse_args()
    summary = summarize(args.workbook)
    destination = Path(__file__).resolve().parents[1] / "data" / "class_game_summary.csv"
    with destination.open("w", newline="", encoding="utf-8") as out:
        writer = csv.DictWriter(out, fieldnames=list(summary), lineterminator="\n")
        writer.writeheader()
        writer.writerow(summary)
