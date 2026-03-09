"""
Cleanse por_blj Bible JSON files by removing footnote objects from verse content arrays.

The raw API data contains mixed-type content arrays like:
    ["Ai da suja", {"noteId": 4}, "e contaminada"]

This script strips the non-string elements so each verse's content is a clean list of strings,
keeping the data consistent and safe for simple [String] decoding in future.
"""

import json
import os
import sys
from pathlib import Path

BUNDLE_PATH = Path(__file__).parent.parent / "livingdevotional" / "Resources" / "BibleData.bundle" / "por_blj"


def cleanse_chapter(data: dict) -> tuple[dict, int]:
    """Remove footnote objects from all verse content arrays. Returns (modified_data, count_removed)."""
    removed = 0
    chapter = data.get("chapter", {})
    for item in chapter.get("content", []):
        if item.get("type") == "verse":
            original = item["content"]
            cleaned = [el for el in original if isinstance(el, str)]
            removed += len(original) - len(cleaned)
            item["content"] = cleaned
    return data, removed


def main():
    if not BUNDLE_PATH.exists():
        print(f"ERROR: Bundle path not found: {BUNDLE_PATH}", file=sys.stderr)
        sys.exit(1)

    total_files = 0
    total_removed = 0
    affected_files = 0

    for json_file in sorted(BUNDLE_PATH.rglob("*.json")):
        if json_file.name == "books.json":
            continue

        with open(json_file, "r", encoding="utf-8") as f:
            data = json.load(f)

        cleaned, removed = cleanse_chapter(data)

        if removed > 0:
            with open(json_file, "w", encoding="utf-8") as f:
                json.dump(cleaned, f, ensure_ascii=False, separators=(",", ":"))
            affected_files += 1
            total_removed += removed
            rel = json_file.relative_to(BUNDLE_PATH)
            print(f"  Cleaned {rel}: removed {removed} footnote reference(s)")

        total_files += 1

    print(f"\nDone. Scanned {total_files} files, cleansed {affected_files} files, removed {total_removed} footnote objects.")


if __name__ == "__main__":
    main()
