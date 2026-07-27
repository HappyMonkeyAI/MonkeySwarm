#!/usr/bin/env python3
"""Convert components.yaml → components.json (requires PyYAML)."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: yaml_to_json.py in.yaml out.json", file=sys.stderr)
        return 2
    src, dst = map(Path, sys.argv[1:])
    try:
        import yaml  # type: ignore
    except ImportError:
        print("PyYAML required: pip install pyyaml", file=sys.stderr)
        return 1
    data = yaml.safe_load(src.read_text(encoding="utf-8"))
    dst.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
