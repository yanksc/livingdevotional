#!/usr/bin/env python3
"""
Generate serene background images for Reading Plans using OpenAI DALL-E 3
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

# Plan-specific prompts - minimalist, serene style
PLAN_PROMPTS = [
    {
        "id": "gospel-of-john",
        "name": "PlanBackground_John",
        "prompt": "Minimalist serene light breaking through darkness, soft warm golden glow, abstract spiritual atmosphere, soft focus, peaceful, high quality, vertical composition, no text, no people, ethereal divine light"
    },
    {
        "id": "psalms-of-comfort",
        "name": "PlanBackground_Psalms",
        "prompt": "Minimalist calm water surface at dawn, gentle ripples, soft blue and gold hues, peaceful reflection, serene, high quality, vertical composition, no text, no people, tranquil water"
    },
    {
        "id": "sermon-on-the-mount",
        "name": "PlanBackground_Sermon",
        "prompt": "Minimalist mountain silhouette in mist, soft morning light, serene peaceful landscape, ethereal atmosphere, high quality, vertical composition, no text, no people, contemplative"
    },
    {
        "id": "finding-peace",
        "name": "PlanBackground_Peace",
        "prompt": "Minimalist green leaf close up with dew drop, soft focus, serene nature, peaceful, high quality, vertical composition, no text, no people, tranquil botanical"
    },
    {
        "id": "proverbs-wisdom",
        "name": "PlanBackground_Proverbs",
        "prompt": "Minimalist path in a quiet forest, soft sunlight filtering through trees, golden hour, serene peaceful walkway, high quality, vertical composition, no text, no people, contemplative nature"
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
    print("🎨 Reading Plan Background Generator")
    print("=" * 60)
    print(f"📁 Output: {OUTPUT_DIR.absolute()}")
    print(f"🖼️  Generating 5 images using DALL-E 3")
    print(f"⏱️  Note: Each image may take 10-20 seconds")
    
    # Initialize OpenAI client
    client = OpenAI(api_key=API_KEY)
    
    results = []
    for plan in PLAN_PROMPTS:
        result = generate_image(client, plan["prompt"], plan["name"])
        if result:
            results.append({
                "plan_id": plan["id"],
                "asset_name": plan["name"],
                **result
            })
    
    print(f"\n{'='*60}")
    print(f"✨ Successfully generated {len(results)}/5 backgrounds")
    
    if results:
        print("\n📸 Generated assets:")
        for r in results:
            print(f"   • {r['asset_name']} -> {r['plan_id']}")
    
    return results

if __name__ == "__main__":
    main()
