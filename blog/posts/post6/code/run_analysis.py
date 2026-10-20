"""Run from any folder: python path/to/post6/code/run_analysis.py.

SQLite performs the actual family matching, inflation adjustment and income
aggregation. Python fits the log-log regressions and saves every result.
Only the three packages in requirements.txt are needed; sqlite3 is built in.
"""
from pathlib import Path
import hashlib
import json
import platform
import sqlite3

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

POST = Path(__file__).resolve().parents[1]
RAW = POST / "data" / "raw"
PROCESSED = POST / "data" / "processed"
RESULTS = POST / "results"
PROCESSED.mkdir(parents=True, exist_ok=True)
RESULTS.mkdir(parents=True, exist_ok=True)


def check_inputs():
    """Fail clearly if an included input has changed or is missing."""
    manifest = json.loads((RAW / "sources.json").read_text(encoding="utf-8"))
    for item in manifest["included_files"]:
        path = RAW / item["file"]
        # Git on Windows may check text files out with CRLF line endings.
        # All included text hashes use canonical LF; values remain protected.
        digest = hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()
        if digest != item["sha256"]:
            raise ValueError(f"Input changed: {path.name}. Review the extract before use.")


def make_income_panel(wide, mapping, cohort):
    """Reshape selected original columns; preserve reported zero income."""
    records = []
    id_column = "R0000100" if cohort == "mother" else "C0000100"
    id_name = "mother_id" if cohort == "mother" else "child_id"
    variables = mapping[(mapping.cohort == cohort) & (mapping.role == "income")]
    for row in variables.itertuples(index=False):
        wave = int(row.survey_year)
        # Through 2012 the codebook names a fixed prior calendar year.
        # CYA 2014+ instead asks about the year before the ACTUAL interview.
        if cohort == "child" and wave >= 2014:
            date_column = mapping.loc[
                (mapping.cohort == cohort)
                & (mapping.survey_year == str(wave))
                & (mapping.role == "interview_year"), "variable"
            ].item()
            income_year = wide[date_column].where(wide[date_column] > 0) - 1
        else:
            income_year = pd.Series(wave - 1, index=wide.index)
        block = pd.DataFrame({
            id_name: wide[id_column], "income_year": income_year,
            "nominal_wages": wide[row.variable].where(wide[row.variable] >= 0),
        })
        records.append(block)
    panel = pd.concat(records, ignore_index=True)
    # Missing responses supply no income observation. One very late CYA
    # interview overlaps the next wave's reference year but has missing wages.
    panel = panel.dropna(subset=["income_year", "nominal_wages"])
    panel["income_year"] = panel["income_year"].astype(int)
    if panel.duplicated([id_name, "income_year"]).any():
        raise ValueError("Duplicate person-income-year. Review the reference-year rules.")
    return panel


def build_database():
    mapping = pd.read_csv(RAW / "variables.csv", dtype=str)
    mw = pd.read_csv(RAW / "nlsy79_selected.csv")
    cw = pd.read_csv(RAW / "nlscya_selected.csv")
    mothers = mw[["R0000100", "R0000500", "R0214800", "R0173600"]].copy()
    mothers.columns = ["mother_id", "birth_year", "sex", "sample_code"]
    mothers["birth_year"] += 1900  # The original variable stores 57,...,64.
    children = cw[["C0000100", "C0000200", "C0005700", "C0005400"]].copy()
    children.columns = ["child_id", "family_id", "birth_year", "sex"]
    # family_id is the documented maternal ID, not a changing household code.
    assert mothers.mother_id.is_unique and children.child_id.is_unique
    assert mothers.birth_year.between(1957, 1964).all()
    assert children.birth_year.between(1970, 2014).all()
    assert children.family_id.isin(mothers.mother_id).all()
    assert (children.child_id // 100 == children.family_id).all()

    mi = make_income_panel(mw, mapping, "mother")
    ci = make_income_panel(cw, mapping, "child")
    cpi = pd.read_csv(RAW / "cpi_u_annual.csv")
    assert cpi.year.is_unique and (cpi.cpi_u > 0).all()
    assert set(mi.income_year) | set(ci.income_year) <= set(cpi.year)
    assert (cpi.year == 2018).sum() == 1

    # A memory database is rebuilt each run; it needs no SQL server.
    con = sqlite3.connect(":memory:")
    for name, table in [("mothers", mothers), ("children", children),
                        ("mother_income", mi), ("child_income", ci), ("cpi", cpi)]:
        table.to_sql(name, con, index=False, if_exists="replace")
    for filename in ["01_link.sql", "02_real_income.sql", "03_average.sql",
                     "04_single.sql", "05_matched.sql"]:
        con.executescript((POST / "sql" / filename).read_text(encoding="utf-8"))

    matched = pd.read_sql_query("SELECT * FROM matched ORDER BY child_id", con)
    assert matched.child_id.is_unique
    assert len(matched) >= 100
    assert (matched.parent_years >= 3).all()
    assert (matched[["early_years", "mature_years"]] >= 2).all().all()
    assert (matched.child_birth_year - matched.mother_birth_year >= 12).all()
    matched.to_csv(PROCESSED / "matched_pairs.csv", index=False)
    for table in ["links", "mother_real", "child_real"]:
        pd.read_sql_query(f"SELECT * FROM {table}", con).to_csv(
            PROCESSED / f"{table}.csv", index=False)

    # Audit incomplete/zero-income exclusions instead of silently losing cases.
    stages = [("All child records", len(children)),
              ("Linked to cross-sectional-sample mothers", con.execute("SELECT COUNT(*) FROM links").fetchone()[0]),
              ("Required income-year coverage in all 3 windows", con.execute("SELECT COUNT(*) FROM covered_pairs").fetchone()[0]),
              ("Positive anchor years and averages: common sample", len(matched))]
    audit = pd.DataFrame(stages, columns=["stage", "child_count"])
    audit.to_csv(RESULTS / "sample_flow.csv", index=False)
    checks = {"unique_child_ids": True, "all_children_have_documented_mother": True,
              "unique_person_income_years": True, "complete_cpi_coverage": True,
              "matched_children": len(matched),
              "matched_mothers": int(matched.mother_id.nunique()),
              "minimum_parent_years": 3, "minimum_child_years_per_window": 2}
    (RESULTS / "checks.json").write_text(json.dumps(checks, indent=2) + "\n")
    return con, matched, audit


def fit_ige(data, parent_column, child_column, adjusted=False):
    """OLS log(child)=intercept+beta*log(mother); cluster SEs by mother."""
    x = np.log(data[parent_column].to_numpy(float))
    y = np.log(data[child_column].to_numpy(float))
    X = np.column_stack([np.ones(len(data)), x])
    if adjusted:
        controls = pd.get_dummies(data[["child_birth_year", "child_sex"]].astype(str),
                                  drop_first=True, dtype=float).to_numpy()
        X = np.column_stack([X, controls])
    beta = np.linalg.lstsq(X, y, rcond=None)[0]
    residual = y - X @ beta
    # Siblings share maternal income. Treating them as independent would
    # understate uncertainty; sum the regression scores within each mother.
    groups, cluster_index = np.unique(data.mother_id, return_inverse=True)
    n, k = X.shape
    scores = np.zeros((len(groups), k))
    np.add.at(scores, cluster_index, X * residual[:, None])
    bread = np.linalg.inv(X.T @ X)
    correction = len(groups) / (len(groups) - 1) * (n - 1) / (n - k)
    covariance = correction * bread @ (scores.T @ scores) @ bread
    se = float(np.sqrt(covariance[1, 1]))
    return dict(ige=float(beta[1]), se=se,
                lower=float(beta[1] - 1.96 * se), upper=float(beta[1] + 1.96 * se),
                children=n, mothers=len(groups))


def estimate_models(d):
    specifications = [
        ("single_both", "Single year in both generations", "parent_single", "mature_single"),
        ("average_parent", "Average mother; single child year", "parent_average", "mature_single"),
        ("average_both", "Average both generations", "parent_average", "mature_average"),
        ("early_single", "Child early 20s: single year", "parent_average", "early_single"),
        ("early_average", "Child ages 20–25: average", "parent_average", "early_average"),
    ]
    estimates = []
    for key, label, parent, child in specifications:
        estimates.append(dict(model=key, label=label, parent=parent, child=child,
                              **fit_ige(d, parent, child)))
    result = pd.DataFrame(estimates)
    result.to_csv(RESULTS / "ige_estimates.csv", index=False)
    robustness = []
    for key, label, parent, child in specifications:
        robustness.append(dict(model=key, specification="Child sex and birth-year controls",
                               **fit_ige(d, parent, child, adjusted=True)))
    pd.DataFrame(robustness).to_csv(RESULTS / "adjusted_estimates.csv", index=False)

    # Resample observed mother clusters, retaining siblings together. This is
    # uncertainty estimation, not synthetic income data or simulated evidence.
    rng = np.random.default_rng(20261020)
    groups = [g.index.to_numpy() for _, g in d.groupby("mother_id", sort=True)]
    differences = []
    def slope(sample, p, c):
        x = np.log(sample[p].to_numpy(float)); y = np.log(sample[c].to_numpy(float))
        return np.sum((x-x.mean())*(y-y.mean())) / np.sum((x-x.mean())**2)
    for draw in range(500):
        chosen = rng.integers(0, len(groups), size=len(groups))
        sample = d.iloc[np.concatenate([groups[i] for i in chosen])]
        differences.append([
            slope(sample, "parent_average", "mature_single") - slope(sample, "parent_average", "early_single"),
            slope(sample, "parent_average", "mature_average") - slope(sample, "parent_single", "mature_single"),
        ])
    boot = pd.DataFrame(differences, columns=["mature_minus_early", "average_minus_single"])
    boot.to_csv(RESULTS / "paired_cluster_bootstrap.csv", index=False)
    intervals = boot.quantile([0.025, 0.975]).T.rename(columns={0.025:"lower",0.975:"upper"})
    intervals.to_csv(RESULTS / "difference_intervals.csv", index_label="comparison")
    return result


def figures(d, estimates):
    plt.rcParams.update({"font.family":"DejaVu Sans", "font.size":11,
                         "axes.spines.top":False, "axes.spines.right":False,
                         "axes.titleweight":"bold", "savefig.facecolor":"white"})
    colors = ["#D88039", "#87AEB2", "#147D87"]
    models = estimates.set_index("model")
    fig, ax = plt.subplots(figsize=(9.5, 4.9))
    keys = ["single_both", "average_parent", "average_both"]
    labels = ["One year\nin each generation", "Average mother;\none child year", "Average income\nin both generations"]
    for i, key in enumerate(keys):
        r=models.loc[key]
        ax.errorbar(i, r.ige, yerr=1.96*r.se, fmt="o", color=colors[i],
                    markersize=10, capsize=6, elinewidth=2)
        ax.annotate(f"{r.ige:.3f}", (i,r.ige), xytext=(11,0),
                    textcoords="offset points", va="center", weight="bold")
    ax.set_xticks(range(3), labels); ax.set_xlim(-0.5,2.7)
    ax.axhline(0, color="#888888",linewidth=0.8)
    ax.set_ylabel("Maternal earnings elasticity (log–log OLS)")
    ax.set_title("Does an income snapshot change the answer?",loc="left",pad=20)
    ax.grid(axis="y",alpha=0.15)
    fig.text(.12,.01,f"Same {len(d):,} children in every estimate. Bars: approximate 95% intervals, clustered by mother.\nSource: BLS NLSY79 and Children/Young Adult public-use data. Unweighted selected sample.",fontsize=9,color="#555555")
    fig.tight_layout(rect=(0,.10,1,1));fig.savefig(RESULTS/"01_single_vs_average.png",dpi=180);plt.close(fig)

    fig,ax=plt.subplots(figsize=(9.5,5.1))
    for offset,keys,label,color in [(-.08,["early_single","average_parent"],"One child income year","#D88039"),(.08,["early_average","average_both"],"Average child income","#147D87")]:
        vals=models.loc[keys]
        ax.errorbar(np.array([0,1])+offset,vals.ige,yerr=1.96*vals.se,
                    marker="o",linewidth=2,color=color,capsize=5,label=label)
        for i,r in enumerate(vals.itertuples()):
            ax.annotate(f"{r.ige:.3f}",(i+offset,r.ige),xytext=(8,7),textcoords="offset points",fontsize=10)
    ax.axhline(0,color="#888888",linewidth=.8)
    ax.set_xticks([0,1],["Early career\nchild ages 20–25", "Later measurement\nchild ages 30–39"])
    ax.set_xlim(-.35,1.4);ax.set_ylabel("Maternal earnings elasticity (log–log OLS)")
    ax.set_title("An early-career snapshot gives a different point estimate",loc="left",pad=18)
    ax.grid(axis="y",alpha=.15);ax.legend(frameon=False,loc="best")
    fig.text(.12,.01,"Same children and same maternal average (ages 35–40) throughout. Bars: approximate 95% cluster intervals.\nSingle observations are closest to ages 23 and 35; averages use at least 2 observed child income years per window.",fontsize=9,color="#555555")
    fig.tight_layout(rect=(0,.10,1,1));fig.savefig(RESULTS/"02_life_cycle.png",dpi=180);plt.close(fig)

    # Bins help readers see the relationship; the fitted line uses all pairs.
    plot=d.copy();plot["parent_bin"]=pd.qcut(plot.parent_average,8,labels=False,duplicates="drop")
    bins=plot.groupby("parent_bin").agg(parent=("parent_average","mean"),child=("mature_average","mean"),children=("child_id","size"))
    bins.to_csv(RESULTS/"income_bins.csv",index_label="parent_bin")
    fig,ax=plt.subplots(figsize=(9.5,4.9))
    ax.scatter(bins.parent/1000,bins.child/1000,s=85,color="#147D87")
    ax.set_xlabel("Mother's average wages, ages 35–40 ($1,000, 2018 dollars)")
    ax.set_ylabel("Child's average wages, ages 30–39\n($1,000, 2018 dollars)")
    ax.set_title("Income averages still leave a noisy relationship",loc="left",pad=18)
    ax.grid(alpha=.15);ax.set_xlim(left=0);ax.set_ylim(bottom=0)
    fig.text(.12,.01,"Eight equal-count groups based on maternal average income; points are group means, not regression estimates.\nSource: BLS NLSY79/CYA. A descriptive relationship in the matched sample; no causal interpretation.",fontsize=9,color="#555555")
    fig.tight_layout(rect=(0,.10,1,1));fig.savefig(RESULTS/"03_income_relationship.png",dpi=180);plt.close(fig)


def main():
    check_inputs()
    con,d,audit=build_database()
    estimates=estimate_models(d)
    figures(d,estimates)
    summary={"children":len(d),"mothers":int(d.mother_id.nunique()),
             "child_birth_min":int(d.child_birth_year.min()),"child_birth_max":int(d.child_birth_year.max()),
             "parent_years_min":int(d.parent_years.min()),"parent_years_max":int(d.parent_years.max()),
             "early_years_min":int(d.early_years.min()),"early_years_max":int(d.early_years.max()),
             "mature_years_min":int(d.mature_years.min()),"mature_years_max":int(d.mature_years.max()),
             "parent_single_mean_age":float(d.parent_single_age.mean()),
             "early_single_mean_age":float(d.early_single_age.mean()),
             "mature_single_mean_age":float(d.mature_single_age.mean())}
    for row in estimates.itertuples(): summary[row.model]=row.ige
    summary["ten_percent_association"]=100*((1.10)**summary["average_both"]-1)
    (RESULTS/"summary.json").write_text(json.dumps(summary,indent=2)+"\n")
    versions={"Python":platform.python_version(),"SQLite":sqlite3.sqlite_version,
              "numpy":np.__version__,"pandas":pd.__version__,"matplotlib":matplotlib.__version__}
    (RESULTS/"versions.json").write_text(json.dumps(versions,indent=2)+"\n")
    # A saved database lets students inspect the tutorial's actual SQL tables.
    target=sqlite3.connect(PROCESSED/"parent_child.sqlite")
    con.backup(target);target.close();con.close()
    template=POST/"_article_template.md"
    if template.exists():
        from render_article import render_article
        render_article(POST,summary)
    print(audit.to_string(index=False))
    print(estimates[["model","ige","lower","upper","children","mothers"]].to_string(index=False))
    print(f"Saved results to {RESULTS}")


if __name__ == "__main__":
    main()
