#!/usr/bin/env python3
"""
Copy CU1 (Chinese Union Version with New Punctuation) data from bible_api/cmn_cu1 
and convert to app format
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

def process_cu1_files():
    """Copy and convert CU1 files from bible_api to BibleData.bundle/cu1"""
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    source_dir = project_root / "bible_api" / "cmn_cu1"
    
    # Try to find BibleData.bundle in common locations (prioritize parent folder)
    possible_locations = [
        project_root.parent / "BibleData.bundle",  # Parent folder (preferred)
        project_root / "BibleData.bundle",
        project_root / "livingdevotional" / "Resources" / "BibleData.bundle",
        project_root / "livingdevotional" / "BibleData.bundle",
    ]
    
    target_bundle = None
    for location in possible_locations:
        if location.exists():
            target_bundle = location
            break
    
    if not target_bundle:
        # Create BibleData.bundle in parent folder if it doesn't exist
        target_bundle = project_root.parent / "BibleData.bundle"
        target_bundle.mkdir(parents=True, exist_ok=True)
        print(f"📦 Created BibleData.bundle at: {target_bundle}")
    
    target_dir = target_bundle / "cu1"
    
    if not source_dir.exists():
        print(f"❌ Source directory not found: {source_dir}")
        return
    
    print(f"📖 Copying CU1 files from: {source_dir}")
    print(f"📁 Target directory: {target_dir}")
    
    # Create target directory
    target_dir.mkdir(parents=True, exist_ok=True)
    
    # Get all book directories
    book_dirs = [d for d in source_dir.iterdir() if d.is_dir() and d.name != "books.json"]
    
    total_files = 0
    converted_files = 0
    
    for book_dir in sorted(book_dirs):
        book_id = book_dir.name
        print(f"\n  📚 Processing {book_id}...")
        
        # Create target book directory
        target_book_dir = target_dir / book_id
        target_book_dir.mkdir(exist_ok=True)
        
        # Process all JSON files in this book
        json_files = sorted(book_dir.glob("*.json"), key=lambda x: int(x.stem))
        
        for json_file in json_files:
            total_files += 1
            chapter_num = json_file.stem
            
            try:
                # Read and parse the API format file
                with open(json_file, 'r', encoding='utf-8') as f:
                    api_data = json.load(f)
                
                # Convert to app format
                verses = convert_to_app_format(api_data)
                
                if verses:
                    # Write converted format to target
                    target_file = target_book_dir / f"{chapter_num}.json"
                    with open(target_file, 'w', encoding='utf-8') as f:
                        json.dump(verses, f, ensure_ascii=False, indent=2)
                    converted_files += 1
                else:
                    print(f"    ⚠️  {book_id}/{chapter_num}.json: No verses found")
                    
            except Exception as e:
                print(f"    ❌ Error processing {book_id}/{chapter_num}.json: {e}")
    
    print(f"\n✅ Conversion complete!")
    print(f"   Processed: {total_files} files")
    print(f"   Converted: {converted_files} files")
    print(f"   Target: {target_dir}")
    print(f"\n📝 Next steps:")
    print(f"   1. Make sure BibleData.bundle is added to your Xcode project")
    print(f"   2. Verify the cu1 folder is inside BibleData.bundle")
    print(f"   3. Build and test the app")

if __name__ == "__main__":
    process_cu1_files()

