#!/usr/bin/env python3
"""Validate generated pages and agent-facing website indexes."""
from __future__ import annotations

from html.parser import HTMLParser
import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
PUBLIC = ROOT / "public"


def source_digest() -> str:
    paths = [ROOT / ".nift" / "config.json", ROOT / ".nift" / "tracked.json", ROOT / "llms.txt", ROOT / "robots.txt", ROOT / "sitemap.xml"]
    paths.extend(sorted((ROOT / "content").rglob("*.html")))
    paths.extend(sorted((ROOT / "templates").rglob("*.html")))
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(ROOT).as_posix().encode("utf-8") + b"\0")
        digest.update(path.read_bytes())
    return digest.hexdigest()


class Links(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.values: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        for name, value in attrs:
            if name in {"href", "src"} and value:
                self.values.append(value)


def output_path(name: str) -> Path:
    return PUBLIC / ("index.html" if name == "/" else f"{name}.html")


def main() -> int:
    if "--print-source-digest" in sys.argv:
        print(source_digest())
        return 0
    failures: list[str] = []
    tracked = json.loads((ROOT / ".nift" / "tracked.json").read_text(encoding="utf-8"))["tracked"]
    names = {entry["name"] for entry in tracked}
    for name in sorted(names):
        page = output_path(name)
        if not page.exists():
            failures.append(f"missing generated page: {page.relative_to(ROOT)}")

    expected_urls = {
        "https://strut-labs.github.io/" if name == "/" else f"https://strut-labs.github.io/{name}.html"
        for name in names if name != "404"
    }
    sitemap = ET.parse(ROOT / "sitemap.xml")
    actual_urls = {element.text for element in sitemap.findall("{http://www.sitemaps.org/schemas/sitemap/0.9}url/{http://www.sitemaps.org/schemas/sitemap/0.9}loc")}
    if actual_urls != expected_urls:
        failures.append(f"sitemap mismatch: missing={sorted(expected_urls - actual_urls)}, extra={sorted(actual_urls - expected_urls)}")

    for filename in ("llms.txt", "robots.txt", "sitemap.xml"):
        source = ROOT / filename
        deployed = PUBLIC / filename
        if not deployed.exists() or source.read_bytes() != deployed.read_bytes():
            failures.append(f"source/deployment mismatch: {filename}")

    digest_file = PUBLIC / "SOURCE_DIGEST"
    expected_digest = source_digest()
    if not digest_file.exists() or digest_file.read_text(encoding="ascii").strip() != expected_digest:
        failures.append(f"generated site source digest mismatch; expected {expected_digest}")

    for page in sorted(PUBLIC.rglob("*.html")):
        parser = Links()
        parser.feed(page.read_text(encoding="utf-8"))
        for value in parser.values:
            parsed = urlsplit(value)
            if parsed.scheme or parsed.netloc or value.startswith(("mailto:", "#")):
                continue
            path = parsed.path
            if not path:
                continue
            target = PUBLIC / path.lstrip("/") if path.startswith("/") else page.parent / path
            if path.endswith("/"):
                target /= "index.html"
            if not target.exists():
                failures.append(f"broken local link: {page.relative_to(PUBLIC)} -> {value}")

    if failures:
        for failure in failures:
            print(f"FAIL {failure}", file=sys.stderr)
        return 1
    print(f"site certified: {len(names)} generated pages, {len(expected_urls)} sitemap URLs, local links resolved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
