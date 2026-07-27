#!/usr/bin/env python3
"""Print one component metadata object as JSON."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def main() -> int:
    cid = os.environ.get("COMPONENT_ID") or ""
    path = Path(os.environ["CATALOGUE_JSON"])
    catalog = json.loads(path.read_text(encoding="utf-8"))
    comps = catalog.get("components") or {}
    if cid not in comps:
        print(f"unknown component: {cid}", file=sys.stderr)
        return 1
    meta = dict(comps[cid])
    meta["id"] = cid
    json.dump(meta, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
