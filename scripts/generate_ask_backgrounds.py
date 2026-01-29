#!/usr/bin/env python3
"""
Generate background images for Ask Categories using OpenAI DALL-E 3
"""

import os
import json
import requests
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# OpenAI API Key
API_KEY = os.environ.get("OPENAI_API_KEY", "")

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "livingdevotional" / "Assets.xcassets"

# Common style for all Ask backgrounds
STYLE_PROMPT = """
Style: Soft abstract watercolor with a torn paper edge aesthetic. 
Light and airy atmosphere, predominantly white/cream background with soft watercolor washes.
Minimalist, clean, high quality, vertical composition.
NO text, NO people, NO realistic photos.
Artistic, gentle, and serene.
"""

# Ask category-specific prompts with distinct colors
ASK_CATEGORY_PROMPTS = [
    {
        "id": "bible-knowledge",
        "name": "AskBackground_BibleKnowledge",
        "prompt": "Abstract watercolor of an ancient scroll or open book. Color palette: Warm Gold, Amber, and Soft Cream. Theme: Wisdom and Light."
    },
    {
        "id": "spiritual-growth",
        "name": "AskBackground_SpiritualGrowth",
        "prompt": "Abstract watercolor of a young plant sprouting. Color palette: Soft Sage Green, Earthy Brown, and White. Theme: New Life and Growth."
    },
    {
        "id": "faith-doubt",
        "name": "AskBackground_FaithDoubt",
        "prompt": "Abstract watercolor of a flickering light or path in mist. Color palette: Muted Blue, Soft Grey, and Warm White. Theme: Contemplation and Hope."
    },
    {
        "id": "prayer-worship",
        "name": "AskBackground_PrayerWorship",
        "prompt": "Abstract watercolor of uplifting rays of light or hands. Color palette: Soft Lavender, Pale Purple, and Golden hues. Theme: Devotion and Peace."
    },
    {
        "id": "christian-living",
        "name": "AskBackground_ChristianLiving",
        "prompt": "Abstract watercolor of a peaceful path or garden walkway. Color palette: Warm Terracotta, Soft Peach, and Sand. Theme: Daily Journey."
    }
]

def generate_image(client: OpenAI, prompt_base: str, filename: str) -> dict:
    """Generate an image using OpenAI DALL-E 3."""
    full_prompt = f"{prompt_base} {STYLE_PROMPT}"
    print(f"\n🎨 Generating: {filename}")
    print(f"   Prompt: {full_prompt[:100]}...")
    
    try:
        # DALL-E 3 supports 1024x1024, 1024x1792 (portrait), or 1792x1024 (landscape)
        # Using portrait for card backgrounds
        response = client.images.generate(
            model="dall-e-3",
            prompt=full_prompt,
            size="1024x1792",  # Portrait orientation for cards
            quality="standard",
            n=1,
        )
        
        image_url = response.data[0].url
        
        # Download the image
        print(f"   📥 Downloading image...")
        img_response = requests.get(image_url)
        img_response.raise_for_status()
        
        # Create assets directory structure (must be .imageset folder)
        asset_dir = OUTPUT_DIR / f"{filename}.imageset"
        asset_dir.mkdir(parents=True, exist_ok=True)
        
        # Save image
        image_path = asset_dir / f"{filename}.png"
        with open(image_path, "wb") as f:
            f.write(img_response.content)
        
        print(f"   ✅ Saved: {image_path}")
        
        # Create Contents.json for the asset
        contents_json = {
            "images": [
                {
                    "filename": f"{filename}.png",
                    "idiom": "universal",
                    "scale": "1x"
                },
                {
                    "idiom": "universal",
                    "scale": "2x"
                },
                {
                    "idiom": "universal",
                    "scale": "3x"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            },
            "properties": {
                "preserves-vector-representation": True
            }
        }
        
        contents_path = asset_dir / "Contents.json"
        with open(contents_path, "w") as f:
            json.dump(contents_json, f, indent=2)
        
        print(f"   ✅ Created Contents.json")
        
        return {
            "filename": filename,
            "path": str(image_path),
            "url": image_url
        }
        
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return None

def main():
    print("🎨 Ask Category Background Generator")
    print("=" * 60)
    print(f"📁 Output: {OUTPUT_DIR.absolute()}")
    print(f"🖼️  Generating 5 images using DALL-E 3")
    print(f"⏱️  Note: Each image may take 10-20 seconds")
    
    # Initialize OpenAI client
    client = OpenAI(api_key=API_KEY)
    
    results = []
    for category in ASK_CATEGORY_PROMPTS:
        result = generate_image(client, category["prompt"], category["name"])
        if result:
            results.append({
                "category_id": category["id"],
                "asset_name": category["name"],
                **result
            })
    
    print(f"\n{'='*60}")
    print(f"✨ Successfully generated {len(results)}/5 backgrounds")
    
    if results:
        print("\n📸 Generated assets:")
        for r in results:
            print(f"   • {r['asset_name']} -> {r['category_id']}")
    
    return results

if __name__ == "__main__":
    main()
