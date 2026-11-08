"""Draws the memory of each grpc build over time from timings/out/*.timeline, as plain SVG (no plotting library).

    python3 timings/chart.py > timings/memory.svg

Every point comes from a timeline that timings/measure.sh wrote: seconds since the start, anonymous memory of the
build container in MiB, and the load average. The dashed line is the memory Docker had (MemTotal in the VM).
"""

from __future__ import annotations

import sys
from html import escape
from pathlib import Path

OUT = Path(__file__).parent / "out"
MEMORY_MIB = 7834  # MemTotal of the Docker VM the timings ran in

RUNS = [  # timeline, label, colour
    ("pie-j8", "pie install -j8 (default)", "#dc2626"),
    ("pie-j4", "pie install -j4", "#ea580c"),
    ("pie-j2", "pie install -j2", "#64748b"),
    ("pecl", "pecl install (one job)", "#94a3b8"),
]

INK = "#0f172a"
INK_2 = "#475569"
GRID = "#e2e8f0"
FONT = "'Helvetica Neue', Helvetica, Arial, sans-serif"
W, H = 1200, 640
LEFT, RIGHT, TOP, BOTTOM = 110, 250, 70, 80


def text(x, y, s, size=18, fill=INK, anchor="start", weight="normal") -> str:
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{FONT}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{escape(str(s))}</text>')


WINDOW = 10  # seconds: each point is the highest sample of the last WINDOW seconds, so the line follows the peaks


def timeline(name: str) -> list[tuple[int, int]]:
    rows = [line.split() for line in (OUT / f"{name}.timeline").read_text().splitlines() if line.strip()]
    raw = [(int(r[0]), int(r[1])) for r in rows]
    return [(s, max(m for t, m in raw if s - WINDOW < t <= s)) for s, _ in raw]


def main() -> int:
    runs = [(timeline(name), label, colour) for name, label, colour in RUNS if (OUT / f"{name}.timeline").exists()]
    name_of = {label: name for name, label, _ in RUNS}
    max_s = max(points[-1][0] for points, _, _ in runs)
    max_minutes = (max_s // 300 + 1) * 5
    top_mib = 8192
    plot_w, plot_h = W - LEFT - RIGHT, H - TOP - BOTTOM

    def x(seconds: float) -> float:
        return LEFT + plot_w * seconds / (max_minutes * 60)

    def y(mib: float) -> float:
        return TOP + plot_h * (1 - mib / top_mib)

    body = [text(LEFT, 36, "Memory of the grpc build over time, by number of make jobs (highest value in each 10 s)", 22, weight="bold")]
    for gib in range(0, 9):
        yy = y(gib * 1024)
        body.append(f'<line x1="{LEFT}" y1="{yy:.1f}" x2="{LEFT + plot_w}" y2="{yy:.1f}" stroke="{GRID}"/>')
        body.append(text(LEFT - 14, yy + 6, f"{gib} GiB", 16, INK_2, "end"))
    for minute in range(0, max_minutes + 1, 5):
        xx = x(minute * 60)
        body.append(f'<line x1="{xx:.1f}" y1="{TOP + plot_h}" x2="{xx:.1f}" y2="{TOP + plot_h + 6}" stroke="{INK_2}"/>')
        body.append(text(xx, TOP + plot_h + 28, f"{minute} min", 16, INK_2, "middle"))
    limit = y(MEMORY_MIB)
    body.append(f'<line x1="{LEFT}" y1="{limit:.1f}" x2="{LEFT + plot_w}" y2="{limit:.1f}" stroke="{INK}" '
                f'stroke-width="2" stroke-dasharray="8 6"/>')
    body.append(text(LEFT + plot_w + 12, limit + 6, "all memory Docker had", 16, INK))
    for points, label, colour in runs:
        path = " ".join(f"{'M' if i == 0 else 'L'}{x(s):.1f},{y(m):.1f}" for i, (s, m) in enumerate(points))
        body.append(f'<path d="{path}" fill="none" stroke="{colour}" stroke-width="2.5" stroke-linejoin="round"/>')
        end_s, end_m = points[-1]
        body.append(f'<circle cx="{x(end_s):.1f}" cy="{y(end_m):.1f}" r="5" fill="{colour}"/>')
        if name_of[label] == "pie-j8":
            body.append(text(x(end_s) + 10, y(max(m for _, m in points)) - 10, "compiler killed, build failed", 16, colour))
    legend_y = TOP + 120
    for i, (points, label, colour) in enumerate(runs):
        ly = legend_y + i * 34
        body.append(f'<line x1="{LEFT + plot_w + 12}" y1="{ly - 6}" x2="{LEFT + plot_w + 40}" y2="{ly - 6}" '
                    f'stroke="{colour}" stroke-width="4"/>')
        body.append(text(LEFT + plot_w + 48, ly, label.replace("pie install ", "PIE ").replace(" install", ""), 16))
    desc = ("Line chart of the memory used by the grpc build over time. "
            + "Each point is the highest value in the preceding 10 seconds. "
            + " ".join(f"{label}: peak {max(m for _, m in points):,} MiB, ended at {points[-1][0] // 60} min {points[-1][0] % 60} s."
                       for points, label, _ in runs)
            + f" A dashed line marks the {MEMORY_MIB:,} MiB Docker had.")
    print(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
          f'aria-label="{escape(desc, quote=True)}">\n<title>Memory of the grpc build over time</title>\n'
          f'<rect width="{W}" height="{H}" fill="#ffffff"/>\n' + "\n".join(body) + "\n</svg>")
    return 0


if __name__ == "__main__":
    sys.exit(main())
