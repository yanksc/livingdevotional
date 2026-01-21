#!/usr/bin/env python3
"""
Generate background images for Ask Categories using OpenAI DALL-E 3
"""

import os
import json
import requests
from pathlib import Path
from openai import OpenAI

# OpenAI API Key - set via environment variable
API_KEY = os.environ.get("OPENAI_API_KEY", "")

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "livingdevotional" / "Assets.xcassets"

# Ask category-specific prompts - minimalist, serene style matching the topic
ASK_CATEGORY_PROMPTS = [
    {
        "id": "bible-knowledge",
        "name": "AskBackground_BibleKnowledge",
        "prompt": "Minimalist ancient scroll or open book with soft warm light, knowledge and wisdom theme, serene scholarly atmosphere, soft focus, peaceful, high quality, vertical composition, no text, no people, ethereal divine light illuminating pages"
    },
    {
        "id": "spiritual-growth",
        "name": "AskBackground_SpiritualGrowth",
        "prompt": "Minimalist young plant sprouting from soil with gentle sunlight, growth and transformation theme, serene nature, soft focus, peaceful, high quality, vertical composition, no text, no people, hopeful new life"
    },
    {
        "id": "faith-doubt",
        "name": "AskBackground_FaithDoubt",
        "prompt": "Minimalist candle flame in soft darkness, flickering light representing faith, contemplative atmosphere, serene peaceful, soft focus, high quality, vertical composition, no text, no people, warm gentle glow"
    },
    {
        "id": "prayer-worship",
        "name": "AskBackground_PrayerWorship",
        "prompt": "Minimalist hands in prayer position with soft golden light, worship and devotion theme, serene spiritual atmosphere, soft focus, peaceful, high quality, vertical composition, no text, no people, ethereal divine connection"
    },
    {
        "id": "christian-living",
        "name": "AskBackground_ChristianLiving",
        "prompt": "Minimalist path through peaceful garden, daily life and journey theme, serene walkway with soft morning light, contemplative, high quality, vertical composition, no text, no people, tranquil everyday path"
    }
]

def generate_image(client: OpenAI, prompt: str, filename: str) -> dict:
    """Generate an image using OpenAI DALL-E 3."""
    print(f"\n🎨 Generating: {filename}")
    print(f"   Prompt: {prompt[:80]}...")
    
    try:
        # DALL-E 3 supports 1024x1024, 1024x1792 (portrait), or 1792x1024 (landscape)
        # Using portrait for card backgrounds
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
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
