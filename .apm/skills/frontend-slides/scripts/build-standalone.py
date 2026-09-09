#!/usr/bin/env python3
"""Package an HTML deck into one standalone file.

Inlines local assets referenced by src="..." attributes and CSS url(...)
values as base64 data URIs, fetches Google Fonts css2 stylesheets and
inlines the font files, and rewrites the deck's FILE_NAME constant so
in-browser saves download under the standalone name.

Scope: src attributes and CSS url() in style blocks and style attributes.
No srcset, JS-loaded assets, SVG href, or other linked stylesheet handling.

Usage:
    python3 build-standalone.py <deck.html> [-o output.html] [--skip-fonts]

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import base64
import json
from html import escape, unescape
from html.parser import HTMLParser
import mimetypes
import re
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.error import URLError
from urllib.parse import unquote, urlsplit

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

MIME_MAP = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".webp": "image/webp",
    ".svg": "image/svg+xml",
    ".woff2": "font/woff2",
    ".woff": "font/woff",
    ".ttf": "font/ttf",
    ".otf": "font/otf",
}

ATTRIBUTE_PATTERN = re.compile(
    r"""(?P<name>[^\s=/>]+)(?:\s*=\s*(?:"(?P<double>[^"]*)"|'(?P<single>[^']*)'|(?P<bare>[^\s>]+)))?"""
)
CSS_URL_PATTERN = re.compile(
    r"""url\(\s*(?:(["'])(.*?)\1|([^"'()]*?))\s*\)""",
    re.IGNORECASE,
)
REMOTE_FONT_URL_PATTERN = re.compile(r"""url\(["']?(https://[^)"']+)["']?\)""")
FILE_NAME_PATTERN = re.compile(
    r"""(const\s+FILE_NAME\s*=\s*)(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')(\s*;)"""
)


def rewrite_html(html: str, rewrite_tag, rewrite_style=lambda text: text) -> str:
    """Patch parser-identified spans without reserializing the document."""
    offsets = [0] + [match.end() for match in re.finditer("\n", html)]
    edits = []

    class Rewriter(HTMLParser):
        def __init__(self):
            super().__init__(convert_charrefs=False)
            self.in_style = False

        def patch(self, original, replacement):
            if original != replacement:
                line, column = self.getpos()
                start = offsets[line - 1] + column
                edits.append((start, start + len(original), replacement))

        def handle_starttag(self, tag, attrs):
            raw = self.get_starttag_text()
            self.patch(raw, rewrite_tag(tag, dict(attrs), raw))
            self.in_style = tag == "style"

        def handle_startendtag(self, tag, attrs):
            raw = self.get_starttag_text()
            self.patch(raw, rewrite_tag(tag, dict(attrs), raw))

        def handle_endtag(self, tag):
            if tag == "style":
                self.in_style = False

        def handle_data(self, data):
            if self.in_style:
                self.patch(data, rewrite_style(data))

    parser = Rewriter()
    parser.feed(html)
    parser.close()
    for start, end, replacement in reversed(edits):
        html = html[:start] + replacement + html[end:]
    return html


def get_mime_type(path_or_url: str) -> str:
    suffix = Path(path_or_url).suffix.lower()
    if suffix in MIME_MAP:
        return MIME_MAP[suffix]
    mime, _ = mimetypes.guess_type(path_or_url)
    return mime or "application/octet-stream"


def file_to_data_uri(file_path: Path) -> str:
    data = file_path.read_bytes()
    encoded = base64.b64encode(data).decode("ascii")
    return f"data:{get_mime_type(file_path.name)};base64,{encoded}"


def is_external(value: str) -> bool:
    value = value.strip()
    parsed = urlsplit(value)
    return bool(parsed.scheme) or value.startswith(("//", "#"))


def inline_local_assets(html: str, base_dir: Path) -> tuple[str, int, list[str]]:
    """Inline local src= and CSS url() assets. Returns (html, count, missing)."""
    inlined: set[str] = set()
    missing: list[str] = []
    confinement_root = base_dir.resolve()

    def resolve(raw: str) -> str | None:
        value = raw.strip()
        if not value or is_external(value):
            return None
        path = unquote(urlsplit(value).path)
        if not path:
            return None
        local_path = Path(path)
        if local_path.is_absolute() or ".." in local_path.parts:
            if value not in missing:
                missing.append(value)
            return None
        asset = (confinement_root / local_path).resolve()
        try:
            asset.relative_to(confinement_root)
        except ValueError:
            if value not in missing:
                missing.append(value)
            return None
        if not asset.is_file():
            if value not in missing:
                missing.append(value)
            return None
        inlined.add(value)
        fragment = urlsplit(value).fragment
        return file_to_data_uri(asset) + (f"#{fragment}" if fragment else "")

    def replace_css_url(match: re.Match[str]) -> str:
        raw = match.group(2) if match.group(1) else match.group(3)
        data_uri = resolve(raw)
        if data_uri is None:
            return match.group(0)
        return f"url('{data_uri}')"

    def rewrite_css(css: str) -> str:
        # Skip comments and string literals; only actual url() tokens are assets.
        tokens = re.compile(
            r"""/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|"""
            + CSS_URL_PATTERN.pattern,
            re.IGNORECASE | re.DOTALL,
        )
        def replace(match):
            url = CSS_URL_PATTERN.fullmatch(match.group(0))
            return replace_css_url(url) if url else match.group(0)
        return tokens.sub(replace, css)

    def rewrite_tag(tag, attrs, raw):
        def replace(match):
            name = match.group("name").lower()
            if name not in {"src", "style"}:
                return match.group(0)
            value = next((match.group(key) for key in ("double", "single", "bare")
                          if match.group(key) is not None), None)
            if value is None:
                return match.group(0)
            decoded = unescape(value)
            replacement = resolve(decoded) if name == "src" else rewrite_css(decoded)
            if replacement is None or replacement == decoded:
                return match.group(0)
            return f'{match.group("name")}="{escape(replacement, quote=True)}"'
        return ATTRIBUTE_PATTERN.sub(replace, raw)

    html = rewrite_html(html, rewrite_tag, rewrite_css)
    return html, len(inlined), missing


def fetch_url(url: str, timeout: float = 15.0) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def inline_google_fonts_css(css_url: str) -> tuple[str | None, str | None]:
    """Fetch a css2 stylesheet and inline every referenced font file.

    Returns (inlined CSS, error detail).
    """
    try:
        css = fetch_url(css_url).decode("utf-8")
    except (URLError, TimeoutError, OSError) as exc:
        return None, f"could not fetch stylesheet {css_url}: {exc}"

    font_urls = sorted(set(REMOTE_FONT_URL_PATTERN.findall(css)))

    def download(url: str) -> tuple[str, str | None, str | None]:
        try:
            data = fetch_url(url)
        except (URLError, TimeoutError, OSError) as exc:
            return url, None, f"failed downloading font {url}: {exc}"
        encoded = base64.b64encode(data).decode("ascii")
        return url, f"data:{get_mime_type(url)};base64,{encoded}", None

    with ThreadPoolExecutor(max_workers=8) as executor:
        downloads = list(executor.map(download, font_urls))

    failures = [error for _, _, error in downloads if error]
    if failures:
        return None, "; ".join(failures)
    url_to_data = {url: data for url, data, _ in downloads}

    def replace(match: re.Match[str]) -> str:
        return f"url('{url_to_data[match.group(1)]}')"

    return REMOTE_FONT_URL_PATTERN.sub(replace, css), None


def inline_google_fonts(html: str) -> tuple[str, int]:
    """Replace Google Fonts link tags with inlined <style> blocks.

    Returns (html, number of stylesheets inlined). On failure the original
    tags stay in place so the deck still works online.
    """
    inlined = 0
    links = 0

    def rewrite_link(tag, attrs, raw):
        nonlocal inlined, links
        css_url = attrs.get("href") or ""
        if tag != "link" or not css_url.startswith("https://fonts.googleapis.com/css2?"):
            return raw
        links += 1
        css, error = inline_google_fonts_css(css_url)
        if css is None:
            print(
                f"Warning: {error}; keeping original font link for {css_url}",
                file=sys.stderr,
            )
            return raw
        inlined += 1
        return f"<style>\n{css}\n</style>"

    html = rewrite_html(html, rewrite_link)
    if links and inlined == links:
        def remove_preconnect(tag, attrs, raw):
            href = (attrs.get("href") or "").rstrip("/")
            if (tag == "link" and (attrs.get("rel") or "").lower() == "preconnect"
                    and href in {"https://fonts.googleapis.com", "https://fonts.gstatic.com"}):
                return ""
            return raw
        html = rewrite_html(html, remove_preconnect)
    return html, inlined


def build(source: Path, output: Path, skip_fonts: bool) -> int:
    if not source.is_file():
        print(f"Error: source file not found: {source}", file=sys.stderr)
        return 1
    if output == source:
        print(
            f"Error: output path must differ from source: {source}",
            file=sys.stderr,
        )
        return 1

    html = source.read_text(encoding="utf-8")

    html, asset_count, missing = inline_local_assets(html, source.parent)
    if missing:
        print("Error: missing local assets:", file=sys.stderr)
        for path in missing:
            print(f"  {path}", file=sys.stderr)
        return 1

    if skip_fonts:
        fonts_note = "fonts skipped"
    else:
        html, font_count = inline_google_fonts(html)
        fonts_note = f"{font_count} font stylesheet(s) inlined"

    html = FILE_NAME_PATTERN.sub(
        lambda match: f"{match.group(1)}{json.dumps(output.name)}{match.group(2)}",
        html,
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html, encoding="utf-8")
    size_mb = output.stat().st_size / (1024 * 1024)
    print(f"Inlined {asset_count} local asset reference(s), {fonts_note}.")
    print(f"Wrote {output} ({size_mb:.2f} MB)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Package an HTML deck into one standalone file."
    )
    parser.add_argument("source", type=Path, help="Source HTML deck")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Output path (default: <source-stem>-standalone.html beside the source)",
    )
    parser.add_argument(
        "--skip-fonts",
        action="store_true",
        help="Skip fetching and inlining Google Fonts",
    )
    args = parser.parse_args()

    source = args.source.resolve()
    output = (
        args.output.resolve()
        if args.output
        else source.with_name(f"{source.stem}-standalone.html")
    )
    return build(source, output, args.skip_fonts)


if __name__ == "__main__":
    sys.exit(main())
