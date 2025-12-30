#!/usr/bin/env python3
"""
Download Bible data from https://bible.helloao.org/api/
Downloads BSB, cmn_cuv, and ENGWEBP translations
Organizes files for iOS app bundle structure
"""

import os
import json
import urllib.request
import urllib.error
from pathlib import Path
from typing import Dict, List, Tuple
import time

# Bible API base URL
API_BASE = "https://bible.helloao.org/api"

# Translations to download
TRANSLATIONS = {
    "BSB": "bsb",      # Map BSB to bsb folder
    # "cmn_cuv": "cuv",  # CUV copied from bible_api folder - skip download
    "ENGWEBP": "engwebp"  # Keep as ENGWEBP for future use
}

# Book ID mapping (from BibleData.swift)
BOOK_ID_MAP = {
    "Genesis": "GEN", "Exodus": "EXO", "Leviticus": "LEV", "Numbers": "NUM",
    "Deuteronomy": "DEU", "Joshua": "JOS", "Judges": "JDG", "Ruth": "RUT",
    "1 Samuel": "1SA", "2 Samuel": "2SA", "1 Kings": "1KI", "2 Kings": "2KI",
    "1 Chronicles": "1CH", "2 Chronicles": "2CH", "Ezra": "EZR", "Nehemiah": "NEH",
    "Esther": "EST", "Job": "JOB", "Psalms": "PSA", "Proverbs": "PRO",
    "Ecclesiastes": "ECC", "Song of Solomon": "SNG", "Isaiah": "ISA", "Jeremiah": "JER",
    "Lamentations": "LAM", "Ezekiel": "EZK", "Daniel": "DAN", "Hosea": "HOS",
    "Joel": "JOL", "Amos": "AMO", "Obadiah": "OBA", "Jonah": "JON",
    "Micah": "MIC", "Nahum": "NAM", "Habakkuk": "HAB", "Zephaniah": "ZEP",
    "Haggai": "HAG", "Zechariah": "ZEC", "Malachi": "MAL", "Matthew": "MAT",
    "Mark": "MRK", "Luke": "LUK", "John": "JHN", "Acts": "ACT", "Romans": "ROM",
    "1 Corinthians": "1CO", "2 Corinthians": "2CO", "Galatians": "GAL", "Ephesians": "EPH",
    "Philippians": "PHP", "Colossians": "COL", "1 Thessalonians": "1TH", "2 Thessalonians": "2TH",
    "1 Timothy": "1TI", "2 Timothy": "2TI", "Titus": "TIT", "Philemon": "PHM",
    "Hebrews": "HEB", "James": "JAS", "1 Peter": "1PE", "2 Peter": "2PE",
    "1 John": "1JN", "2 John": "2JN", "3 John": "3JN", "Jude": "JUD", "Revelation": "REV"
}

# Books with chapter counts
BIBLE_BOOKS = [
    ("Genesis", 50), ("Exodus", 40), ("Leviticus", 27), ("Numbers", 36), ("Deuteronomy", 34),
    ("Joshua", 24), ("Judges", 21), ("Ruth", 4), ("1 Samuel", 31), ("2 Samuel", 24),
    ("1 Kings", 22), ("2 Kings", 25), ("1 Chronicles", 29), ("2 Chronicles", 36),
    ("Ezra", 10), ("Nehemiah", 13), ("Esther", 10), ("Job", 42), ("Psalms", 150),
    ("Proverbs", 31), ("Ecclesiastes", 12), ("Song of Solomon", 8), ("Isaiah", 66),
    ("Jeremiah", 52), ("Lamentations", 5), ("Ezekiel", 48), ("Daniel", 12), ("Hosea", 14),
    ("Joel", 3), ("Amos", 9), ("Obadiah", 1), ("Jonah", 4), ("Micah", 7), ("Nahum", 3),
    ("Habakkuk", 3), ("Zephaniah", 3), ("Haggai", 2), ("Zechariah", 14), ("Malachi", 4),
    ("Matthew", 28), ("Mark", 16), ("Luke", 24), ("John", 21), ("Acts", 28), ("Romans", 16),
    ("1 Corinthians", 16), ("2 Corinthians", 13), ("Galatians", 6), ("Ephesians", 6),
    ("Philippians", 4), ("Colossians", 4), ("1 Thessalonians", 5), ("2 Thessalonians", 3),
    ("1 Timothy", 6), ("2 Timothy", 4), ("Titus", 3), ("Philemon", 1), ("Hebrews", 13),
    ("James", 5), ("1 Peter", 5), ("2 Peter", 3), ("1 John", 5), ("2 John", 1),
    ("3 John", 1), ("Jude", 1), ("Revelation", 22)
]

def download_chapter(translation: str, book_id: str, chapter: int) -> Tuple[bool, dict]:
    """Download a single chapter from the API"""
    url = f"{API_BASE}/{translation}/{book_id}/{chapter}.json"
    
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0')
        with urllib.request.urlopen(req, timeout=30) as response:
            data = json.loads(response.read().decode('utf-8'))
            return True, data
    except urllib.error.HTTPError as e:
        print(f"  HTTP Error {e.code} downloading {url}: {e.reason}")
        return False, {}
    except urllib.error.URLError as e:
        print(f"  URL Error downloading {url}: {e.reason}")
        return False, {}
    except json.JSONDecodeError as e:
        print(f"  Error parsing JSON from {url}: {e}")
        return False, {}
    except Exception as e:
        print(f"  Error downloading {url}: {e}")
        return False, {}

def flatten_content(content_item):
    """Recursively flatten content array that may contain strings or dicts"""
    if isinstance(content_item, str):
        return content_item
    elif isinstance(content_item, dict):
        # If it's a dict, try to extract text from it
        if "content" in content_item:
            return flatten_content(content_item["content"])
        elif "text" in content_item:
            return content_item["text"]
        else:
            return ""
    elif isinstance(content_item, list):
        # Recursively process list items
        parts = []
        for item in content_item:
            flattened = flatten_content(item)
            if flattened:
                parts.append(flattened)
        return " ".join(parts)
    else:
        return str(content_item)

def convert_to_app_format(data: dict, book: str, chapter: int) -> List[dict]:
    """Convert API response to app format: [{"verse": 1, "text": "..."}, ...]"""
    verses = []
    
    # Handle bible.helloao.org API format
    if isinstance(data, dict) and "chapter" in data:
        chapter_data = data["chapter"]
        if "content" in chapter_data:
            # Content is an array of items with type "verse"
            for item in chapter_data["content"]:
                if isinstance(item, dict) and item.get("type") == "verse":
                    verse_num = item.get("number", 0)
                    content = item.get("content", [])
                    # Flatten nested content structure
                    text = flatten_content(content)
                    if verse_num and text:
                        verses.append({"verse": int(verse_num), "text": text})
    
    # Fallback: Try other formats
    elif isinstance(data, list):
        # Already a list of verses
        for item in data:
            if isinstance(item, dict):
                verse_num = item.get("verse", item.get("verse_number", item.get("v", 0)))
                text = item.get("text", item.get("content", ""))
                if isinstance(text, list):
                    text = " ".join(text)
                if verse_num and text:
                    verses.append({"verse": int(verse_num), "text": str(text)})
    elif isinstance(data, dict):
        # Check for "verses" key
        if "verses" in data:
            for item in data["verses"]:
                verse_num = item.get("verse", item.get("verse_number", item.get("v", 0)))
                text = item.get("text", item.get("content", ""))
                if isinstance(text, list):
                    text = " ".join(text)
                if verse_num and text:
                    verses.append({"verse": int(verse_num), "text": str(text)})
    
    return sorted(verses, key=lambda x: x["verse"])

def save_chapter(output_dir: Path, translation_folder: str, book_id: str, chapter: int, verses: List[dict]):
    """Save chapter data to JSON file"""
    chapter_dir = output_dir / translation_folder / book_id
    chapter_dir.mkdir(parents=True, exist_ok=True)
    
    output_file = chapter_dir / f"{chapter}.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(verses, f, ensure_ascii=False, indent=2)
    print(f"  ✓ Saved {output_file}")

def download_translation(translation: str, folder_name: str, output_dir: Path):
    """Download all books and chapters for a translation"""
    print(f"\n📖 Downloading {translation} -> {folder_name}/")
    
    total_chapters = sum(chapters for _, chapters in BIBLE_BOOKS)
    downloaded = 0
    failed = 0
    
    for book_name, num_chapters in BIBLE_BOOKS:
        book_id = BOOK_ID_MAP.get(book_name)
        if not book_id:
            print(f"⚠️  No book ID found for {book_name}")
            continue
        
        print(f"\n  📚 {book_name} ({book_id}) - {num_chapters} chapters")
        
        for chapter in range(1, num_chapters + 1):
            success, data = download_chapter(translation, book_id, chapter)
            
            if success:
                verses = convert_to_app_format(data, book_name, chapter)
                if verses:
                    save_chapter(output_dir, folder_name, book_id, chapter, verses)
                    downloaded += 1
                else:
                    print(f"    ⚠️  Chapter {chapter}: No verses found in response")
                    failed += 1
            else:
                failed += 1
            
            # Rate limiting - small delay between requests
            time.sleep(0.1)
    
    print(f"\n✅ {translation} complete: {downloaded} chapters downloaded, {failed} failed")

def main():
    """Main download function"""
    # Output directory (will be in livingdevotional/Resources/BibleData)
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    output_dir = project_root / "livingdevotional" / "Resources" / "BibleData"
    
    print(f"📥 Downloading Bible data to: {output_dir}")
    print(f"🌐 API: {API_BASE}")
    print(f"📚 Translations: {', '.join(TRANSLATIONS.keys())}")
    
    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Download each translation
    for api_translation, folder_name in TRANSLATIONS.items():
        download_translation(api_translation, folder_name, output_dir)
    
    print(f"\n🎉 All downloads complete!")
    print(f"\n📁 Files saved to: {output_dir}")
    print(f"\n💡 Next steps:")
    print(f"   1. Add the BibleData folder to your Xcode project")
    print(f"   2. Make sure it's included in the app bundle (Target Membership)")

if __name__ == "__main__":
    main()

