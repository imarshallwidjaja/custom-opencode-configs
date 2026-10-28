"""Compose a transition storyboard: a generated frame grid plus exact, script-drawn text.

The image model supplies only the frames (one grid image, frames numbered, no captions).
This script adds the title, subtitle, one caption per frame, a timing bar per animated
element on a shared millisecond scale, and a footer, so every word and number is exact.

Usage:
  uv run --with pillow --with numpy python compose_storyboard.py \
      --grid frames.png --spec storyboard.json --out transition-name.png \
      [--font-regular Regular.ttf --font-semibold SemiBold.ttf]

Spec (JSON):
{
  "title": "Select a product",
  "subtitle": "One line on what the storyboard shows.",
  "frames": [
    {"caption": "Hover tints the row.", "tracks": [["Row tint", "100 ms · ease", 0, 100]]},
    {"caption": "Selection changes at once.", "tracks": [["Selection", "instant", 0, 0]]}
  ],
  "footer": "Keyboard and reduced-motion behaviour.",
  "notes": "Curve definitions or other second footer line (optional).",
  "scale_ms": 500,
  "width": 1920,
  "colors": {"ink": "#18181B", "secondary": "#52525B", "accent": "#2563EB", "track": "#D4D4D8"}
}

A track is [label, timing text, start ms, end ms]. Equal start and end draws a dot: an
instant change. Captions sit in one row under the grid, one column per frame, numbered
in the grid's reading order. Without font flags the script asks fc-match for the system
sans-serif.
"""
import argparse
import json
import subprocess

import numpy as np
from PIL import Image, ImageDraw, ImageFont

DEFAULT_COLORS = {"ink": "#18181B", "secondary": "#52525B", "accent": "#2563EB", "track": "#D4D4D8"}  # neutral; pass the product palette in "colors"


def system_font(weight):
    pattern = "sans-serif:weight=" + ("bold" if weight == "semibold" else "regular")
    path = subprocess.run(["fc-match", "-f", "%{file}", pattern], capture_output=True, text=True, check=True).stdout
    if not path:
        raise SystemExit(f"fc-match returned no {weight} sans-serif font; pass --font-{weight}")
    return path


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def wrap(draw, text, font, width):
    lines, current = [], ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if draw.textlength(candidate, font=font) <= width:
            current = candidate
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def compose(grid_path, spec, out_path, regular, semibold):
    colors = {k: hex_rgb(v) for k, v in {**DEFAULT_COLORS, **spec.get("colors", {})}.items()}
    font = lambda path, size: ImageFont.truetype(path, size)
    scale_ms = spec.get("scale_ms", 500)
    frames = spec["frames"]

    grid = Image.open(grid_path).convert("RGB")
    gw, gh = grid.size
    width = max(spec.get("width", 1920), gw + 96)
    edges = np.asarray(grid)
    background = tuple(int(v) for v in np.median(np.concatenate([edges[:6].reshape(-1, 3), edges[-6:].reshape(-1, 3)]), axis=0))

    margin = (width - gw) // 2
    gap = 32
    column = (gw - (len(frames) - 1) * gap) // len(frames)
    caption_font, label_font, timing_font = font(semibold, 17), font(regular, 15), font(regular, 14)

    probe = ImageDraw.Draw(Image.new("RGB", (8, 8)))
    needed = 0
    for frame in frames:
        lines = len(wrap(probe, frame["caption"], caption_font, column - 44))
        needed = max(needed, max(lines * 23, 30) + 16 + len(frame.get("tracks", [])) * 44)

    top = 136
    captions_y = top + gh + 28
    footer_lines = [line for line in (spec.get("footer"), spec.get("notes")) if line]
    height = captions_y + needed + 40 + 26 * len(footer_lines) + 24
    image = Image.new("RGB", (width, height), background)
    draw = ImageDraw.Draw(image)

    draw.text((margin, 40), spec["title"], font=font(semibold, 34), fill=colors["ink"])
    if spec.get("subtitle"):
        draw.text((margin, 88), spec["subtitle"], font=font(regular, 19), fill=colors["secondary"])
    image.paste(grid, (margin, top))

    for index, frame in enumerate(frames):
        x = margin + index * (column + gap)
        draw.ellipse((x, captions_y, x + 30, captions_y + 30), fill=(255, 255, 255), outline=colors["track"])
        number = str(index + 1)
        number_font = font(semibold, 17)
        draw.text((x + 15 - draw.textlength(number, font=number_font) / 2, captions_y + 4), number, font=number_font, fill=colors["ink"])
        y = captions_y
        for line in wrap(draw, frame["caption"], caption_font, column - 44):
            draw.text((x + 42, y + 3), line, font=caption_font, fill=colors["ink"])
            y += 23
        y = max(y, captions_y + 30) + 16
        for label, timing, start, end in frame.get("tracks", []):
            draw.text((x, y), label, font=label_font, fill=colors["ink"])
            draw.text((x + column - draw.textlength(timing, font=timing_font), y + 1), timing, font=timing_font, fill=colors["secondary"])
            bar_y = y + 25
            draw.rounded_rectangle((x, bar_y, x + column, bar_y + 4), 2, fill=colors["track"])
            start_x = x + column * min(start, scale_ms) / scale_ms
            if end > start:
                draw.rounded_rectangle((start_x, bar_y, x + column * min(end, scale_ms) / scale_ms, bar_y + 4), 2, fill=colors["accent"])
            else:
                draw.ellipse((start_x - 1, bar_y - 3, start_x + 9, bar_y + 7), fill=colors["accent"])
            y += 44

    footer_y = height - 24 - 26 * len(footer_lines)
    draw.line((margin, footer_y - 14, margin + gw, footer_y - 14), fill=colors["track"])
    for i, line in enumerate(footer_lines):
        draw.text((margin, footer_y + i * 26), line, font=font(regular, 16 if i == 0 else 15), fill=colors["ink"] if i == 0 else colors["secondary"])

    image.save(out_path, optimize=True)
    print(f"{out_path}: {image.size[0]}x{image.size[1]} (grid {gw}x{gh}, scale 0-{scale_ms} ms)")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--grid", required=True)
    parser.add_argument("--spec", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--font-regular")
    parser.add_argument("--font-semibold")
    args = parser.parse_args()
    with open(args.spec) as handle:
        spec = json.load(handle)
    if not spec.get("title") or not spec.get("frames"):
        raise SystemExit("spec needs a non-empty 'title' and at least one entry in 'frames'")
    compose(args.grid, spec, args.out, args.font_regular or system_font("regular"), args.font_semibold or system_font("semibold"))


if __name__ == "__main__":
    main()
