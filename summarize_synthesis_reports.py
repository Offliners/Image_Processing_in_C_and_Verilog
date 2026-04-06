#!/usr/bin/env python3
"""
Scan each module's RTL/Report/*.clock, *.area, *.power, *.timing (same basename)
and print a table: clock period, total cell area, total power, worst slack, MET/VIOLATED.

Usage:
  ./summarize_synthesis_reports.py
  ./summarize_synthesis_reports.py /path/to/Image_Processing_in_C_and_Verilog
"""

import re
import sys
from pathlib import Path


def find_repo_root(argv):
    if len(argv) >= 2:
        return Path(argv[1]).resolve()
    return Path(__file__).resolve().parent


def parse_clock(text):
    """First clock row: 'clk             20.00   {0 10}' -> period as string."""
    for line in text.splitlines():
        m = re.match(r"^\s*(\S+)\s+([\d.]+)\s+\{", line)
        if m and not line.strip().startswith("-"):
            name, period = m.group(1), m.group(2)
            if name in ("Clock", "Attributes", "Library"):
                continue
            return f"{name} {period}"
    return None


def parse_area(text):
    m = re.search(r"^Total cell area:\s+([\d.]+)\s*$", text, re.M)
    return m.group(1) if m else None


def parse_power_mw(text):
    """Prefer last 'Total ... mW' summary row; else 'Total Dynamic Power = X' (any unit)."""
    last = None
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("Total"):
            continue
        if "=" in line:
            continue
        if "Power Group" in line or ("Internal" in line and "Switching" in line):
            continue
        nums = re.findall(r"([\d.eE+-]+)\s+mW", line)
        if nums:
            last = nums[-1]
    if last is not None:
        return last
    m = re.search(r"Total Dynamic Power\s+=\s+([\d.eE+-]+)", text)
    return m.group(1) if m else None


def parse_slacks(text):
    """All slack values from report_timing (MET / VIOLATED)."""
    out = []
    for m in re.finditer(r"slack\s+\((?:MET|VIOLATED)\)\s+([-.\deE+]+)", text):
        try:
            out.append(float(m.group(1)))
        except ValueError:
            pass
    return out


def worst_slack(slacks):
    if not slacks:
        return None
    return min(slacks)


def load_report(report_dir, stem, suffix):
    p = report_dir / f"{stem}{suffix}"
    if not p.is_file():
        return None
    try:
        return p.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def main() -> int:
    root = find_repo_root(sys.argv)
    rows = []

    for rtl in sorted(root.glob("*/RTL")):
        module = rtl.parent.name
        report_dir = rtl / "Report"
        if not report_dir.is_dir():
            rows.append((module, "N/A", "N/A", "N/A", "N/A", "no Report/"))
            continue

        clocks = sorted(report_dir.glob("*.clock"))
        if not clocks:
            rows.append((module, "N/A", "N/A", "N/A", "N/A", "no .clock"))
            continue

        stem = clocks[0].stem  # e.g. MEAN_FILTER
        c_txt = load_report(report_dir, stem, ".clock")
        a_txt = load_report(report_dir, stem, ".area")
        p_txt = load_report(report_dir, stem, ".power")
        t_txt = load_report(report_dir, stem, ".timing")

        clk = parse_clock(c_txt) if c_txt else None
        area = parse_area(a_txt) if a_txt else None
        pwr = parse_power_mw(p_txt) if p_txt else None

        slacks = parse_slacks(t_txt) if t_txt else []
        wns = worst_slack(slacks)

        if wns is None:
            slack_s = "N/A"
            status = "no slack" if t_txt else "no .timing"
        else:
            slack_s = f"{wns:.4f}"
            status = "MET" if wns >= 0 else "VIOLATED"

        rows.append(
            (
                module,
                clk or "N/A",
                area or "N/A",
                pwr or "N/A",
                slack_s,
                status,
            )
        )

    # column widths
    h = ("Module", "Clock (name period)", "Total cell area", "Total power (mW)", "Slack (worst)", "Status")
    w = [max(len(h[i]), *(len(r[i]) for r in rows)) for i in range(6)]

    def line(cells):
        return " | ".join(cells[i].ljust(w[i]) for i in range(6))

    print(line(h))
    print("-+-".join("-" * w[i] for i in range(6)))
    for r in rows:
        print(line(r))

    violated = sum(1 for r in rows if r[5] == "VIOLATED")
    if violated:
        print(f"\nVIOLATED count: {violated} (slack < 0)")
    else:
        print("\nAll reported slacks >= 0 (or N/A).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
