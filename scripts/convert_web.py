#!/usr/bin/env python3
"""
Convert downloaded ENGWEBP (World English Bible) files to app format
"""

import json
import shutil
from pathlib import Path

def flatten_content(content_item):
    """Recursively flatten content array that may contain strings or dicts"""
    if isinstance(content_item, str):
        return content_item
    elif isinstance(content_item, dict):
        if "content" in content_item:
            return flatten_content(content_item["content"])
        elif "text" in content_item:
            return content_item["text"]
        else:
            return ""
    elif isinstance(content_item, list):
        parts = []
        for item in content_item:
            flattened = flatten_content(item)
            if flattened:
                parts.append(flattened)
        return " ".join(parts)
    else:
        return str(content_item)

def convert_to_app_format(data: dict) -> list:
    """Convert API response to app format: [{"verse": 1, "text": "..."}, ...]"""
    verses = []
    
    # Handle the structure found in ENGWEBP files
    if isinstance(data, dict) and "chapter" in data:
        chapter_data = data["chapter"]
        if "content" in chapter_data:
            for item in chapter_data["content"]:
                if isinstance(item, dict) and item.get("type") == "verse":
                    verse_num = item.get("number", 0)
                    content = item.get("content", [])
                    text = flatten_content(content)
                    if verse_num and text:
                        verses.append({"verse": int(verse_num), "text": text})
    
    return sorted(verses, key=lambda x: x["verse"])

def process_web_files():
    """Convert ENGWEBP files to BibleData.bundle/web"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Source: livingdevotional/Resources/BibleData.bundle/ENGWEBP
    bundle_dir = project_root / "livingdevotional" / "Resources" / "BibleData.bundle"
    source_dir = bundle_dir / "ENGWEBP"
    
    # Target: livingdevotional/Resources/BibleData.bundle/web
    target_dir = bundle_dir / "web"
    
    if not source_dir.exists():
        print(f"❌ Source directory not found: {source_dir}")
        return
    
    print(f"📖 Converting WEB files from: {source_dir}")
    print(f"📁 Target directory: {target_dir}")
    
    # Create target directory
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Get all book directories
    book_dirs = [d for d in source_dir.iterdir() if d.is_dir()]
    
    total_files = 0
    converted_files = 0
    
    for book_dir in sorted(book_dirs):
        book_id = book_dir.name
        print(f"  Processing {book_id}...", end="\r")
        
        # Create target book directory
        target_book_dir = target_dir / book_id
        target_book_dir.mkdir(exist_ok=True)
        
        # Process all JSON files in this book
        json_files = sorted(book_dir.glob("*.json"), key=lambda x: int(x.stem))
        
        for json_file in json_files:
            total_files += 1
            chapter_num = json_file.stem
            
            try:
                with open(json_file, 'r', encoding='utf-8') as f:
                    api_data = json.load(f)
                
                verses = convert_to_app_format(api_data)
                
                if verses:
                    target_file = target_book_dir / f"{chapter_num}.json"
                    with open(target_file, 'w', encoding='utf-8') as f:
                        json.dump(verses, f, ensure_ascii=False, indent=2)
                    converted_files += 1
                else:
                    print(f"\n    ⚠️  {book_id}/{chapter_num}.json: No verses found")
                    
            except Exception as e:
                print(f"\n    ❌ Error processing {book_id}/{chapter_num}.json: {e}")
    
    print(f"\n\n✅ Conversion complete!")
    print(f"   Processed: {total_files} files")
    print(f"   Converted: {converted_files} files")
    print(f"   Target: {target_dir}")

if __name__ == "__main__":
    process_web_files()
