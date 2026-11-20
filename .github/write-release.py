#!/usr/bin/env python3
"""Writes a release of marqius-wkhtmltopdf into the package: src/release.php and src/release.sh.

    python3 .github/write-release.py VERSION BUILDS

BUILDS is the folder `.github/release.py fetch VERSION BUILDS` filled, after checking each build
against the SHA-256 published beside it; its SHA256SUMS gives the checksums the package carries.
Nothing else in the package changes. Only the standard library is used.
"""
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "src"
BUILDS = ["linux-x86_64", "linux-arm64", "macos-arm64", "windows-x86_64.exe"]


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    version, builds = sys.argv[1], Path(sys.argv[2])
    if not re.fullmatch(r"\d+(\.\d+)+", version):
        sys.exit(f"not a version: {version!r}")
    sums = {name: sha for sha, name in (line.split() for line in (builds / "SHA256SUMS").read_text().splitlines())}
    lines = []
    for build in BUILDS:
        sha = sums.get(f"marqius-wkhtmltopdf-{build}", "")
        if not re.fullmatch(r"[0-9a-f]{64}", sha):
            sys.exit(f"{builds}/SHA256SUMS has no checksum for {build}")
        lines.append(f"        '{build}' => '{sha}',\n")
    (SRC / "release.php").write_text(
        "<?php\n"
        "// Written by .github/write-release.py from https://marqius.com/download/marqius-wkhtmltopdf/latest\n"
        "// and the SHA-256 published beside each build. Do not edit by hand.\n"
        "return [\n"
        f"    'version' => '{version}',\n"
        "    'sha256' => [\n" + "".join(lines) + "    ],\n"
        "];\n", encoding="utf-8")
    (SRC / "release.sh").write_text(
        "# Written by .github/write-release.py with release.php. Do not edit by hand.\n"
        f"version={version}\n", encoding="utf-8")
    print(f"src/release.php and src/release.sh: marqius-wkhtmltopdf {version}")


if __name__ == "__main__":
    main()
