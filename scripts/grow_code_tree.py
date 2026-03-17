#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import math
import random
from dataclasses import dataclass


@dataclass
class SeasonProfile:
    leaf_density: float
    flower_density: float
    trunk_char: str


def date_seed(d: dt.date) -> int:
    return d.year * 10000 + d.month * 100 + d.day


def season_profile(d: dt.date) -> SeasonProfile:
    # Northern hemisphere milestones.
    spring_equinox = dt.date(d.year, 3, 20)
    winter_solstice = dt.date(d.year, 12, 21)
    dist_to_spring = abs((d - spring_equinox).days)
    dist_to_winter = abs((d - winter_solstice).days)

    if dist_to_winter <= 10:
        return SeasonProfile(leaf_density=0.0, flower_density=0.0, trunk_char='|')

    flower_density = 0.0
    if dist_to_spring <= 20:
        # Strong bloom around the equinox.
        flower_density = max(0.15, 0.75 - (dist_to_spring * 0.03))

    # Mildly seasonal foliage curve using day-of-year cosine.
    doy = d.timetuple().tm_yday
    # Peak around mid-summer, low near winter.
    seasonal = 0.45 + 0.35 * math.cos((doy - 172) / 365 * 2 * math.pi)
    leaf_density = max(0.0, min(0.85, seasonal))

    return SeasonProfile(leaf_density=leaf_density, flower_density=flower_density, trunk_char='|')


def draw_line(canvas: list[list[str]], x0: int, y0: int, x1: int, y1: int, char: str) -> tuple[int, int]:
    dx = abs(x1 - x0)
    sx = 1 if x0 < x1 else -1
    dy = -abs(y1 - y0)
    sy = 1 if y0 < y1 else -1
    err = dx + dy

    x, y = x0, y0
    while True:
        if 0 <= y < len(canvas) and 0 <= x < len(canvas[0]):
            if canvas[y][x] == ' ':
                canvas[y][x] = char
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x += sx
        if e2 <= dx:
            err += dx
            y += sy

    return x1, y1


def pick_branch_char(dx: int) -> str:
    if dx < 0:
        return '/'
    if dx > 0:
        return '\\'
    return '|'


def grow(
    canvas: list[list[str]],
    rng: random.Random,
    profile: SeasonProfile,
    tips: list[tuple[int, int]],
    x: int,
    y: int,
    length: float,
    angle: float,
    depth: int,
) -> None:
    if depth <= 0 or length < 1.5:
        if 0 <= y < len(canvas) and 0 <= x < len(canvas[0]):
            tips.append((x, y))
        return

    x2 = int(round(x + length * math.cos(angle)))
    y2 = int(round(y - length * math.sin(angle)))
    x2 = max(0, min(len(canvas[0]) - 1, x2))
    y2 = max(0, min(len(canvas) - 1, y2))
    dx = x2 - x
    branch_char = pick_branch_char(dx)
    tx, ty = draw_line(canvas, x, y, x2, y2, branch_char if depth < 7 else profile.trunk_char)

    terminal = depth <= 2
    if terminal:
        if 0 <= ty < len(canvas) and 0 <= tx < len(canvas[0]):
            tips.append((tx, ty))
        return

    shrink = 0.67 + rng.uniform(-0.05, 0.04)
    next_len = length * shrink

    # Main bifurcation.
    split = math.radians(22 + rng.uniform(-8, 10))
    grow(canvas, rng, profile, tips, tx, ty, next_len, angle + split, depth - 1)
    grow(canvas, rng, profile, tips, tx, ty, next_len, angle - split, depth - 1)

    # Occasional third branch for richer fractal shape.
    if rng.random() < 0.35:
        twist = math.radians(rng.uniform(-12, 12))
        grow(canvas, rng, profile, tips, tx, ty, next_len * 0.9, angle + twist, depth - 1)


def decorate_tips(
    canvas: list[list[str]],
    rng: random.Random,
    profile: SeasonProfile,
    tips: list[tuple[int, int]],
) -> None:
    if not tips:
        return

    unique_tips = sorted(set(tips))
    rng.shuffle(unique_tips)

    if profile.flower_density <= 0 and profile.leaf_density <= 0:
        return

    flower_count = 0
    if profile.flower_density > 0:
        target = int(len(unique_tips) * profile.flower_density)
        flower_count = max(5, min(len(unique_tips), target))

    leaf_count = 0
    if profile.leaf_density > 0:
        leaf_count = int(len(unique_tips) * profile.leaf_density * 0.5)
        leaf_count = min(len(unique_tips) - flower_count, max(1, leaf_count))

    idx = 0
    while idx < flower_count:
        x, y = unique_tips[idx]
        canvas[y][x] = '*' if rng.random() < 0.7 else 'o'
        idx += 1

    end = idx + leaf_count
    while idx < end:
        x, y = unique_tips[idx]
        if canvas[y][x] in {' ', '/', '\\', '|'}:
            canvas[y][x] = '+'
        idx += 1


def build_tree(d: dt.date, width: int = 81, height: int = 36) -> str:
    rng = random.Random(date_seed(d))
    profile = season_profile(d)

    canvas = [[' ' for _ in range(width)] for _ in range(height)]
    root_x = width // 2 + rng.randint(-2, 2)
    root_y = height - 2
    tips: list[tuple[int, int]] = []

    base_len = 9.5 + rng.uniform(-1.2, 1.2)
    grow(canvas, rng, profile, tips, root_x, root_y, base_len, math.pi / 2, depth=8)
    decorate_tips(canvas, rng, profile, tips)

    # Ground line.
    for x in range(width):
        if canvas[height - 1][x] == ' ':
            canvas[height - 1][x] = '.'

    header = f"# Code Tree for {d.isoformat()}"
    legend = "# *=flower o=flower +=leaf (winter solstice window becomes bare)"
    body = '\n'.join(''.join(row).rstrip() for row in canvas)
    return f"{header}\n{legend}\n{body}\n"


def parse_date(s: str | None) -> dt.date:
    if not s:
        return dt.date.today()
    return dt.date.fromisoformat(s)


def main() -> None:
    parser = argparse.ArgumentParser(description="Grow a date-seeded fractal ASCII code tree.")
    parser.add_argument("--date", help="Date in YYYY-MM-DD, defaults to today.")
    parser.add_argument("--out", help="Output file path.")
    args = parser.parse_args()

    d = parse_date(args.date)
    output = args.out or f"garden/{d.isoformat()}.txt"
    content = build_tree(d)

    with open(output, "w", encoding="utf-8") as f:
        f.write(content)

    print(output)


if __name__ == "__main__":
    main()
