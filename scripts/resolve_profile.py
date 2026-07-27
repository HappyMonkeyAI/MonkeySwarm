#!/usr/bin/env python3
"""Resolve component ids for a profile or --only list."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def expand_profile(catalog: dict, name: str, seen: set[str] | None = None) -> list[str]:
    if seen is None:
        seen = set()
    if name in seen:
        return []
    seen.add(name)
    profiles = catalog.get("profiles") or {}
    if name not in profiles:
        raise SystemExit(f"unknown profile: {name}")
    prof = profiles[name]
    ids: list[str] = []
    ext = prof.get("extends")
    if isinstance(ext, str):
        ids.extend(expand_profile(catalog, ext, seen))
    elif isinstance(ext, list):
        for e in ext:
            ids.extend(expand_profile(catalog, e, seen))
    for c in prof.get("components") or []:
        if c not in ids:
            ids.append(c)
    return ids


def main() -> int:
    path = Path(os.environ["CATALOGUE_JSON"])
    catalog = json.loads(path.read_text(encoding="utf-8"))
    only = (os.environ.get("ONLY") or "").strip()
    if only:
        ids = [x.strip() for x in only.split(",") if x.strip()]
    else:
        profile = os.environ.get("PROFILE") or catalog.get("default_profile") or "core"
        ids = expand_profile(catalog, profile)
    comps = catalog.get("components") or {}
    missing = [i for i in ids if i not in comps]
    if missing:
        raise SystemExit(f"unknown component ids: {', '.join(missing)}")
    for i in ids:
        print(i)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
