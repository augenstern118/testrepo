/* R computes every draw and interval. This script only displays saved results. */
(function () {
  "use strict";
  const payload = JSON.parse(document.getElementById("figure-data").textContent);
  const kind = document.body.dataset.figure;
  const byId = id => document.getElementById(id);
  const usd = x => "$" + Number(x).toFixed(2);
  const percent = x => (100 * x).toFixed(1) + "%";
  const colors = {blue:"#0072b2", hit:"#0f766e", miss:"#c2410c", purple:"#7c3aed"};
  byId("confidence-control").hidden = kind === "null";
  byId("surveys-control").hidden = kind !== "coverage";
  byId("alpha-control").hidden = kind !== "null";

  function vertical(x, color, dash) {
    return {type:"line",x0:x,x1:x,y0:0,y1:1,yref:"paper",line:{color:color,width:2,dash:dash || "solid"}};
  }
  function layout(xTitle, yTitle) {
    return {margin:{l:62,r:14,t:20,b:60},font:{family:"Arial, sans-serif",size:12,color:"#182b3c"},
      paper_bgcolor:"white",plot_bgcolor:"white",showlegend:false,
      xaxis:{title:{text:xTitle,standoff:12},gridcolor:"#e5e7eb",zeroline:false},
      yaxis:{title:{text:yTitle,standoff:8},gridcolor:"#e5e7eb",zeroline:false}};
  }
  function draw() {
    const n = byId("sample-size").value;
    const d = payload.cases[n];
    const level = byId("confidence").value;
    const conf = Number(level) / 100;
    let traces, settings;
    if (kind === "bootstrap") {
      const ci = d.intervals[level];
      byId("figure-title").textContent = "Figure 1. Reuse one sample to estimate its uncertainty";
      byId("metrics").textContent = "Sample mean: " + usd(d.sampleMean) + "/hour. " + level +
        "% percentile interval: " + usd(ci[0]) + " to " + usd(ci[1]) + ". Based on " +
        d.resamples.toLocaleString() + " resamples of the SAME " + n + " workers.";
      traces = [{type:"bar",x:d.hist.x,y:d.hist.y,width:d.hist.width * 0.94,marker:{color:colors.blue},
        hovertemplate:"Bootstrap mean: $%{x:.2f}<br>Resamples in bin: %{y}<extra></extra>"}];
      settings = layout("Bootstrap mean hourly wage ($)","Number of resamples");
      settings.shapes = [
        {type:"rect",x0:ci[0],x1:ci[1],y0:0,y1:1,yref:"paper",fillcolor:"#bfdbfe",opacity:0.3,line:{width:0},layer:"below"},
        vertical(ci[0],colors.blue),vertical(ci[1],colors.blue),vertical(payload.trueMean,colors.miss,"dash")
      ];
      byId("explanation").textContent = "Blue boundaries show the percentile interval; the dashed orange line is the known $30 truth. Changing confidence reuses the same draws. The bootstrap does not use the known truth to build its interval.";
    } else if (kind === "coverage") {
      const M = Number(byId("surveys").value);
      const lo = d["lower" + level], hi = d["upper" + level];
      let hits = 0, totalWidth = 0;
      const series = [true,false].map(hit => ({type:"scatter",mode:"lines",name:hit?"Contains $30":"Misses $30",
        x:[],y:[],customdata:[],line:{color:hit?colors.hit:colors.miss,width:2.5,dash:hit?"solid":"dash"},
        hovertemplate:"Survey %{customdata[0]}<br>Mean: $%{customdata[3]:.2f}<br>Interval: $%{customdata[1]:.2f}–$%{customdata[2]:.2f}<extra>%{fullData.name}</extra>"}));
      for (let i = 0; i < M; i++) {
        const hit = lo[i] <= payload.trueMean && hi[i] >= payload.trueMean;
        hits += Number(hit); totalWidth += hi[i] - lo[i];
        if (i < 60) {
          const s = series[hit?0:1], data = [i+1,lo[i],hi[i],d.means[i]];
          s.x.push(lo[i],hi[i],null);s.y.push(i+1,i+1,null);s.customdata.push(data,data,data);
        }
      }
      const rate = hits / M, mcse = Math.sqrt(rate * (1-rate) / M);
      byId("figure-title").textContent = "Figure 2. Start over with a new survey each time";
      byId("metrics").textContent = hits + " of " + M.toLocaleString() + " intervals contain $30: " +
        percent(rate) + " coverage (target " + level + "%). Monte Carlo SE: " +
        (100 * mcse).toFixed(2) + " percentage points. Mean interval width: " + usd(totalWidth/M) + ".";
      traces = series;settings = layout("Confidence interval for mean hourly wage ($)","New survey number");
      settings.showlegend = true;
      settings.legend = {orientation:"h",x:0,y:-0.26,font:{size:11}};
      settings.margin.b = 85;settings.yaxis.autorange = "reversed";
      settings.shapes = [vertical(payload.trueMean,"#182b3c","dash")];
      byId("explanation").textContent = "First 60 intervals shown in their original order; coverage uses ALL " +
        M.toLocaleString() + " selected surveys. Teal contains $30; orange misses it. Each survey uses 999 bootstrap resamples. More survey experiments make the measured coverage less noisy, not each survey more precise.";
    } else {
      const alpha = Number(byId("alpha").value);
      const test = d.tests.find(t => Math.abs(t.alpha-alpha)<1e-12);
      const z = d.observedZ, absZ = Math.abs(z), critical = test.critical;
      const edge = Math.max(Math.abs(d.hist.min),Math.abs(d.hist.max),absZ+0.5,critical+0.5);
      const pText = d.p.toFixed(4);
      byId("figure-title").textContent = "Figure 3. Ask what the null population would produce";
      byId("metrics").textContent = "H0: mean hourly wage = $28. Observed Z = " + z.toFixed(2) +
        ". " + d.extreme + " of " + d.simulations.toLocaleString() +
        " null draws are at least as extreme; Monte Carlo p = " + pText + ". At α = " +
        (100*alpha).toFixed(0) + "%: " + (d.p<=alpha?"reject H0":"do not reject H0") + ".";
      traces = [{type:"bar",x:d.hist.x,y:d.hist.y,width:d.hist.width*0.94,marker:{color:"#64748b"},
        hovertemplate:"Null Z: %{x:.2f}<br>Null draws in bin: %{y}<extra></extra>"}];
      settings = layout("Z (distance from $28 in standard errors)","Number of null draws");
      settings.xaxis.range = [-edge,edge];
      settings.shapes = [
        {type:"rect",x0:-edge,x1:-absZ,y0:0,y1:1,yref:"paper",fillcolor:"#fb923c",opacity:0.24,line:{width:0},layer:"above"},
        {type:"rect",x0:absZ,x1:edge,y0:0,y1:1,yref:"paper",fillcolor:"#fb923c",opacity:0.24,line:{width:0},layer:"above"},
        vertical(-critical,colors.purple,"dash"),vertical(critical,colors.purple,"dash"),vertical(z,colors.blue)
      ];
      byId("explanation").textContent = "Blue: observed Z. Purple: rejection cutoffs ±" + critical.toFixed(2) +
        ", estimated from |Z| under H0. Orange: |Z| at least as large as observed. p = (extreme count + 1)/(10,000 + 1). Changing α moves the rejection cutoffs; it does not change p.";
    }
    byId("chart").setAttribute("aria-label",byId("figure-title").textContent + ". " + byId("metrics").textContent);
    Plotly.react("chart",traces,settings,{responsive:true,displaylogo:false,displayModeBar:false});
  }
  ["sample-size","confidence","surveys","alpha"].forEach(id => byId(id).addEventListener("change",draw));
  draw();
})();
