#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-2-Clause
"""analyze.py - the tables of tools/avif-bench.sh from its raw TSV files.

Usage: python3 -I analyze.py <dir> <report.md> <head.md>
<dir>: sweep.tsv, timing.tsv, checks.tsv, lossless.tsv (each optional, with a header line);
<head.md>: the lines put first (system, CPU, versions, sources). The report: per set of images a
table "benchmark | unit | <config> ..." (one row per measure, one column per configuration),
then the raw TSV files in full.

Lossy: the BD-rate of each configuration against the baseline (BASE, the AVIF of the resize script
today), per image over the quality range of the baseline between two of its Q (the working range,
Q 70 to 85, and Q 30 to 85), the mean over the images; log(bytes) as a function of the metric,
a monotone piecewise cubic (PCHIP) through the points of each curve, integrated on 400 points.
Q 90 stays out of the BD-rate: from Q 90 on heifsave asks for 4:4:4 (subsample_mode auto), which
the encoder of SVT-AV1 does not have (always 4:2:0) and that of libaom does.
"Same quality as BASE at Q": the bytes of a configuration at the SSIMULACRA2 that BASE has at that
Q on that image (on its curve, as above), against those of BASE, and the Q it takes.
Time: in the process (heifbench), one CPU, threads 1; per image the median of the rounds, then the
median over the images.
"""
import math
import os
import statistics
import sys

BASE = "svt-p5-psnr"
METRICS = [("ssimulacra2", 1), ("butteraugli_p3", -1), ("psnr_y", 1), ("ssim_y", 1)]


def read_tsv(path):
    if not os.path.isfile(path):
        return []
    with open(path, encoding="utf-8") as f:
        lines = [ln.rstrip("\n") for ln in f if ln.strip() and not ln.startswith("#")]
    if not lines:
        return []
    head = lines[0].split("\t")
    return [dict(zip(head, ln.split("\t"))) for ln in lines[1:]]


def num(x):
    try:
        v = float(x)
    except (TypeError, ValueError):
        return None
    return v if math.isfinite(v) else None


def pchip(xs, ys):
    """the slopes of a monotone piecewise cubic Hermite through (xs, ys), xs increasing"""
    n = len(xs)
    h = [xs[i + 1] - xs[i] for i in range(n - 1)]
    d = [(ys[i + 1] - ys[i]) / h[i] for i in range(n - 1)]
    if n == 2:
        return [d[0], d[0]]
    m = [0.0] * n
    for i in range(1, n - 1):
        if d[i - 1] * d[i] <= 0:
            m[i] = 0.0
        else:
            w1, w2 = 2 * h[i] + h[i - 1], h[i] + 2 * h[i - 1]
            m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])

    def end(h0, h1, d0, d1):
        s = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1)
        if s * d0 <= 0:
            return 0.0
        if d0 * d1 <= 0 and abs(s) > abs(3 * d0):
            return 3 * d0
        return s
    m[0] = end(h[0], h[1], d[0], d[1])
    m[-1] = end(h[-1], h[-2], d[-1], d[-2])
    return m


class Curve:
    """y as a function of x through the points, x made strictly increasing (equal x: the mean y)"""

    def __init__(self, pts):
        pts = sorted((x, y) for x, y in pts if x is not None and y is not None)
        xs, ys = [], []
        for x, y in pts:
            if xs and abs(x - xs[-1]) < 1e-9:
                ys[-1] = (ys[-1] + y) / 2
            else:
                xs.append(x)
                ys.append(y)
        self.xs, self.ys = xs, ys
        self.ok = len(xs) >= 2
        self.m = pchip(xs, ys) if self.ok else []

    def lo(self):
        return self.xs[0]

    def hi(self):
        return self.xs[-1]

    def __call__(self, t):
        xs, ys, m = self.xs, self.ys, self.m
        if t <= xs[0]:
            i = 0
        elif t >= xs[-1]:
            i = len(xs) - 2
        else:
            i = max(k for k in range(len(xs) - 1) if xs[k] <= t)
        h = xs[i + 1] - xs[i]
        s = (t - xs[i]) / h
        h00, h10 = 2 * s ** 3 - 3 * s ** 2 + 1, s ** 3 - 2 * s ** 2 + s
        h01, h11 = -2 * s ** 3 + 3 * s ** 2, s ** 3 - s ** 2
        return h00 * ys[i] + h10 * h * m[i] + h01 * ys[i + 1] + h11 * h * m[i + 1]


def bd_rate(base_pts, test_pts, lo, hi):
    """the BD-rate (%) of test against base: points (quality, bytes), on [lo, hi] of the quality"""
    a = Curve([(q, math.log(b)) for q, b in base_pts])
    b = Curve([(q, math.log(v)) for q, v in test_pts])
    if not a.ok or not b.ok:
        return None
    lo, hi = max(lo, a.lo(), b.lo()), min(hi, a.hi(), b.hi())
    if hi - lo < 1e-6 * max(1.0, abs(hi)):
        return None
    n = 400
    s = 0.0
    for k in range(n + 1):
        t = lo + (hi - lo) * k / n
        w = 0.5 if k in (0, n) else 1.0
        s += w * (b(t) - a(t))
    return (math.exp(s / n) - 1) * 100


def fmt(v, nd=1, pct=False):
    if v is None:
        return "-"
    if pct:
        return "%+.*f" % (nd, v)
    return "%.*f" % (nd, v)


def med(xs):
    xs = [x for x in xs if x is not None]
    return statistics.median(xs) if xs else None


def mean(xs):
    xs = [x for x in xs if x is not None]
    return sum(xs) / len(xs) if xs else None


def table(title, cols, rows, para=""):
    out = ["## " + title, ""]
    if para:
        out += [para, ""]
    out.append("| benchmark | unit | " + " | ".join(cols) + " |")
    out.append("|---|---|" + "---|" * len(cols))
    for name, unit, vals in rows:
        out.append("| %s | %s | %s |" % (name, unit, " | ".join(vals)))
    out.append("")
    return out


def lossy(sweep, timing, checks, sets):
    out = []
    order = []
    for r in sweep:
        if r["config"] not in order:
            order.append(r["config"])
    if BASE in order:
        order.remove(BASE)
        order.insert(0, BASE)
    for st in sets:
        rows = [r for r in sweep if r["set"] == st]
        if not rows:
            continue
        cfgs = [c for c in order if any(r["config"] == c for r in rows)]
        imgs = sorted({r["image"] for r in rows})
        pts = {}
        for r in rows:
            pts.setdefault((r["config"], r["image"]), {})[int(r["q"])] = r
        px = {}
        for r in rows:
            px[r["image"]] = int(r["width"]) * int(r["height"])
        res = []

        def bd(metric, sign, qlo, qhi, cfg):
            vals = []
            for im in imgs:
                bp, tp = pts.get((BASE, im), {}), pts.get((cfg, im), {})
                qs = [q for q in bp if q < 90]
                if qlo not in bp or qhi not in bp:
                    continue
                lo_v, hi_v = num(bp[qlo][metric]), num(bp[qhi][metric])
                if lo_v is None or hi_v is None:
                    continue
                lo_v, hi_v = sorted((sign * lo_v, sign * hi_v))
                b = [(sign * num(bp[q][metric]), float(bp[q]["bytes"])) for q in qs if num(bp[q][metric]) is not None]
                t = [(sign * num(tp[q][metric]), float(tp[q]["bytes"])) for q in tp if q < 90 and num(tp[q][metric]) is not None]
                v = bd_rate(b, t, lo_v, hi_v)
                if v is not None:
                    vals.append(v)
            return vals

        for metric, sign, mname in [("ssimulacra2", 1, "SSIMULACRA2"), ("butteraugli_p3", -1, "Butteraugli 3-norm"),
                                    ("psnr_y", 1, "PSNR-Y"), ("ssim_y", 1, "SSIM-Y")]:
            for qlo, qhi in ([(70, 85), (30, 85)] if metric == "ssimulacra2" else [(70, 85)]):
                per = {c: bd(metric, sign, qlo, qhi, c) for c in cfgs}
                res.append(("BD-rate %s Q%d-%d (mean of images)" % (mname, qlo, qhi), "%",
                            [fmt(mean(per[c]), 1, True) for c in cfgs]))
                if metric == "ssimulacra2" and qlo == 70:
                    res.append(("BD-rate %s Q%d-%d (median of images)" % (mname, qlo, qhi), "%",
                                [fmt(med(per[c]), 1, True) for c in cfgs]))
                    res.append(("images better than %s (BD-rate %s Q%d-%d < 0)" % (BASE, mname, qlo, qhi), "of %d" % len(imgs),
                                [str(sum(1 for v in per[c] if v < 0)) if per[c] else "-" for c in cfgs]))
        for q in (75, 80):
            res.append(("bytes Q%d (mean)" % q, "B", [fmt(mean([float(pts[(c, im)][q]["bytes"]) for im in imgs
                                                                    if q in pts.get((c, im), {})]), 0) for c in cfgs]))
            res.append(("bits per pixel Q%d (mean)" % q, "bpp", [fmt(mean([8 * float(pts[(c, im)][q]["bytes"]) / px[im] for im in imgs
                                                                             if q in pts.get((c, im), {})]), 3) for c in cfgs]))

            def rel(c):
                v = []
                for im in imgs:
                    a, b = pts.get((BASE, im), {}).get(q), pts.get((c, im), {}).get(q)
                    if a and b:
                        v.append((float(b["bytes"]) / float(a["bytes"]) - 1) * 100)
                return mean(v)
            res.append(("bytes Q%d against %s (mean of images)" % (q, BASE), "%", [fmt(rel(c), 1, True) for c in cfgs]))
            for metric, unit, nd in [("ssimulacra2", "score", 2), ("butteraugli_p3", "distance", 3), ("psnr_y", "dB", 2),
                                     ("ssim_y", "index", 4)]:
                res.append(("%s Q%d (mean)" % (metric, q), unit,
                            [fmt(mean([num(pts[(c, im)][q][metric]) for im in imgs if q in pts.get((c, im), {})]), nd)
                             for c in cfgs]))
            # the bytes at the SSIMULACRA2 of BASE at this Q
            eqb, eqq = {}, {}
            for c in cfgs:
                vb, vq = [], []
                for im in imgs:
                    bp, tp = pts.get((BASE, im), {}), pts.get((c, im), {})
                    if q not in bp:
                        continue
                    s = num(bp[q]["ssimulacra2"])
                    tq = [k for k in tp if k < 90 and num(tp[k]["ssimulacra2"]) is not None]
                    cb = Curve([(num(tp[k]["ssimulacra2"]), math.log(float(tp[k]["bytes"]))) for k in tq])
                    cq = Curve([(num(tp[k]["ssimulacra2"]), float(k)) for k in tq])
                    if s is None or not cb.ok or s < cb.lo() or s > cb.hi():
                        continue
                    vb.append((math.exp(cb(s)) / float(bp[q]["bytes"]) - 1) * 100)
                    vq.append(cq(s))
                eqb[c], eqq[c] = (mean(vb), len(vb)), mean(vq)
            res.append(("bytes at the SSIMULACRA2 of %s Q%d, against it (mean of images)" % (BASE, q), "%",
                        [fmt(eqb[c][0], 1, True) for c in cfgs]))
            res.append(("Q for the SSIMULACRA2 of %s Q%d (mean of images)" % (BASE, q), "Q", [fmt(eqq[c], 1) for c in cfgs]))
            res.append(("images on the curve for the SSIMULACRA2 of %s Q%d" % (BASE, q), "of %d" % len(imgs),
                        [str(eqb[c][1]) for c in cfgs]))
        # time
        tr = [t for t in timing if t["set"] == st]
        tcfgs = cfgs + [c for c in sorted({t["config"] for t in tr}) if c not in cfgs]
        for thr in ("1", "4"):
            for q in (75, 80):
                per = {}
                for t in tr:
                    if t["threads"] != thr or int(t["q"]) != q:
                        continue
                    per.setdefault((t["config"], t["image"]), []).append(float(t["cpu_us"]) / 1000)
                    per.setdefault(("wall", t["config"], t["image"]), []).append(float(t["wall_us"]) / 1000)
                if not per:
                    continue
                for kind, label in (("cpu", "CPU"), ("wall", "wall")):
                    if thr == "1" and kind == "wall":
                        continue
                    vals, ratio = [], []
                    for c in tcfgs:
                        k = (lambda im: (c, im)) if kind == "cpu" else (lambda im: ("wall", c, im))
                        m = [med(per[k(im)]) for im in imgs if k(im) in per]
                        vals.append(fmt(med(m), 1))
                        kb = (lambda im: (BASE, im)) if kind == "cpu" else (lambda im: ("wall", BASE, im))
                        rr = [med(per[k(im)]) / med(per[kb(im)]) for im in imgs if k(im) in per and kb(im) in per]
                        ratio.append(fmt(med(rr), 2))
                    res.append(("%s time Q%d, threads %s (median of images)" % (label, q, thr), "ms", vals))
                    res.append(("%s time Q%d, threads %s, against %s (median of images)" % (label, q, thr, BASE), "x", ratio))
        title = "lossy %s" % st
        out += table(title, tcfgs, [(n, u, v + ["-"] * (len(tcfgs) - len(v))) for n, u, v in res])
    return out


def lossless_tables(rows, sets):
    out = []
    order = []
    for r in rows:
        if r["format"] not in order:
            order.append(r["format"])
    for st in sets:
        rs = [r for r in rows if r["set"] == st]
        if not rs:
            continue
        fm = [f for f in order if any(r["format"] == f for r in rs)]
        imgs = sorted({r["image"] for r in rs})
        one = {}
        tm = {}
        for r in rs:
            one[(r["format"], r["image"])] = r
            if num(r.get("cpu_s")) is not None:
                tm.setdefault((r["format"], r["image"]), []).append((float(r["wall_s"]) * 1000, float(r["cpu_s"]) * 1000))
        res = []
        res.append(("exact images (all samples equal after decoding)", "of %d" % len(imgs),
                    [str(sum(1 for im in imgs if (f, im) in one and one[(f, im)]["maxdiff"] == "0")) for f in fm]))
        res.append(("max abs diff of a sample (worst image)", "0-255",
                    [str(max(int(one[(f, im)]["maxdiff"]) for im in imgs if (f, im) in one and one[(f, im)]["maxdiff"] not in ("", "-")))
                     if any((f, im) in one and one[(f, im)]["maxdiff"] not in ("", "-") for im in imgs) else "-" for f in fm]))
        res.append(("PSNR RGB of the inexact (mean)", "dB",
                    [fmt(mean([num(one[(f, im)]["psnr_rgb"]) for im in imgs if (f, im) in one and one[(f, im)]["maxdiff"] != "0"]), 2)
                     for f in fm]))
        res.append(("bytes (mean)", "B", [fmt(mean([float(one[(f, im)]["bytes"]) for im in imgs if (f, im) in one]), 0) for f in fm]))
        res.append(("bits per pixel (mean)", "bpp", [fmt(mean([8 * float(one[(f, im)]["bytes"]) / (int(one[(f, im)]["width"]) * int(one[(f, im)]["height"]))
                                                               for im in imgs if (f, im) in one]), 3) for f in fm]))
        ref = "png-vips-c9"
        if ref in fm:
            res.append(("bytes against %s (mean of images)" % ref, "%", [fmt(mean([(float(one[(f, im)]["bytes"]) / float(one[(ref, im)]["bytes"]) - 1) * 100
                                                                             for im in imgs if (f, im) in one and (ref, im) in one]), 1, True) for f in fm]))
        res.append(("wall time of the command (median of images)", "ms", [fmt(med([med([w for w, _ in tm[(f, im)]]) for im in imgs if (f, im) in tm]), 1) for f in fm]))
        res.append(("CPU time of the command (median of images)", "ms", [fmt(med([med([c for _, c in tm[(f, im)]]) for im in imgs if (f, im) in tm]), 1) for f in fm]))
        out += table("lossless %s" % st, fm, res)
    return out


def checks_section(checks):
    if not checks:
        return []
    out = ["## checks", "", "| check | set | config | Q | files | the same | different |", "|---|---|---|---|---|---|---|"]
    agg = {}
    for r in checks:
        k = (r["check"], r["set"], r["config"], r["q"])
        a = agg.setdefault(k, [0, 0, []])
        if r["same"] == "yes":
            a[0] += 1
        else:
            a[1] += 1
            a[2].append(r["image"] + (" (" + r["note"] + ")" if r.get("note") else ""))
    for (c, s, cfg, q), (y, n, which) in sorted(agg.items()):
        out.append("| %s | %s | %s | %s | %d | %d | %s |" % (c, s, cfg, q, y + n, y, ("%d: " % n + ", ".join(which[:6])) if n else "0"))
    out.append("")
    return out


def main():
    d, report, head = sys.argv[1], sys.argv[2], sys.argv[3]
    sweep = read_tsv(os.path.join(d, "sweep.tsv"))
    timing = read_tsv(os.path.join(d, "timing.tsv"))
    checks = read_tsv(os.path.join(d, "checks.tsv"))
    ll = read_tsv(os.path.join(d, "lossless.tsv"))
    sets = []
    for r in sweep + timing + ll:
        if r["set"] not in sets:
            sets.append(r["set"])
    out = []
    if os.path.isfile(head):
        out += open(head, encoding="utf-8").read().rstrip("\n").split("\n") + [""]
    out += lossy(sweep, timing, checks, sets)
    out += lossless_tables(ll, sets)
    out += checks_section(checks)
    for name in ("sweep.tsv", "timing.tsv", "checks.tsv", "lossless.tsv"):
        p = os.path.join(d, name)
        if os.path.isfile(p):
            out += ["## raw: %s" % name, "", "```", open(p, encoding="utf-8").read().rstrip("\n"), "```", ""]
    with open(report, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
