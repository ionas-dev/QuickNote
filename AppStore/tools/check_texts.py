#!/usr/bin/env python3
"""Check App Store Connect text files against Apple's limits.

Usage: python3 -I AppStore/tools/check_texts.py AppStore/texts/*.md
Each file has `## Name`, `## Subtitle`, `## Promotional Text`, `## Keywords`,
`## Description`, `## Categories` sections; the body is pasted verbatim.
"""
import re
import sys

LIMITS = {"Name": 30, "Subtitle": 30, "Promotional Text": 170, "Keywords": 100}
REQUIRED = ["Name", "Subtitle", "Promotional Text", "Keywords", "Description", "Categories"]


def sections(text):
    out, current = {}, None
    for line in text.splitlines():
        m = re.match(r"^## (.+?)\s*$", line)
        if m:
            current = m.group(1)
            out[current] = []
        elif current:
            out[current].append(line)
    return {k: "\n".join(v).strip() for k, v in out.items()}


def words(s):
    return {w for w in re.split(r"[^\wäöüß]+", s.lower()) if w}


def check(path):
    errors = []
    s = sections(open(path, encoding="utf-8").read())
    for name in REQUIRED:
        if not s.get(name):
            errors.append(f"missing or empty section: {name}")
    for name, limit in LIMITS.items():
        n = len(s.get(name, ""))
        if n > limit:
            errors.append(f"{name}: {n} > {limit} characters")
    kw = s.get("Keywords", "")
    if "\n" in kw:
        errors.append("Keywords: must be one line")
    if ", " in kw:
        errors.append("Keywords: space after comma wastes characters")
    reused = words(kw) & (words(s.get("Name", "")) | words(s.get("Subtitle", "")))
    if reused:
        errors.append(f"Keywords: already indexed via name/subtitle: {sorted(reused)}")
    return errors


def main(paths):
    failed = False
    for p in paths:
        errs = check(p)
        if errs:
            failed = True
            for e in errs:
                print(f"FAIL {p}: {e}")
        else:
            print(f"OK {p}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
