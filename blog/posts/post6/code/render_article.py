"""Generate article text and tables from the analysis outputs and SQL files."""
from pathlib import Path
import re

import pandas as pd


def render_article(post, summary):
    text = (post/"_article_template.md").read_text(encoding="utf-8")
    def value(match):
        key, spec = match.group(1).split(":", 1)
        return format(summary[key], spec)
    text = re.sub(r"\[\[value:([^]]+)\]\]", value, text)
    def sql(match):
        code = (post/"sql"/match.group(1)).read_text(encoding="utf-8").rstrip()
        return "```sql\n" + code + "\n```"
    text = re.sub(r"\[\[sql:([^]]+)\]\]", sql, text)
    estimates = pd.read_csv(post/"results/ige_estimates.csv")
    table = ["| Income measures | IGE | Approx. 95% interval |",
             "|:--|--:|:--|"]
    for r in estimates.itertuples():
        table.append(f"| {r.label} | {r.ige:.3f} | {r.lower:.3f} to {r.upper:.3f} |")
    text = text.replace("[[estimates_table]]", "\n".join(table))
    flow = pd.read_csv(post/"results/sample_flow.csv")
    table = ["| Sample step | Children |", "|:--|--:|"]
    for r in flow.itertuples(): table.append(f"| {r.stage} | {r.child_count:,} |")
    text = text.replace("[[flow_table]]", "\n".join(table))
    if re.search(r"\[\[(?:value|sql|estimates_table|flow_table)", text):
        raise ValueError("Unfilled article placeholder")
    (post/"results/_article.md").write_text(text, encoding="utf-8")
