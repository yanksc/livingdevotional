#!/usr/bin/env python3
"""
Serene Background Generator for Living Devotional - Using OpenAI DALL-E 3
Generates light serene real nature backgrounds for Path Journey feature

Usage:
    python generate_serene_backgrounds_openai.py [count]
    
Example:
    python generate_serene_backgrounds_openai.py 6
"""

import os
import json
import random
import requests
from datetime import datetime
from pathlib import Path
from openai import OpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# OpenAI API Key
API_KEY = os.environ.get("OPENAI_API_KEY", "")

# Output directory
OUTPUT_DIR = Path(__file__).parent.parent / "livingdevotional" / "Assets.xcassets" / "SereneBackgrounds"

# Light serene real nature scene templates
SCENE_TEMPLATES = [
    {
        "name": "serene_meadow_sunrise",
        "base": "Peaceful meadow at sunrise with wildflowers, soft morning mist, golden hour light filtering through",
        "elements": ["delicate wildflowers", "gentle morning mist", "warm golden sunlight", "rolling green hills"]
    },
    {
        "name": "calm_forest_path",
        "base": "Tranquil forest path with dappled sunlight, lush green ferns, peaceful woodland atmosphere",
        "elements": ["dappled golden light rays", "soft green ferns", "moss-covered trees", "serene forest path"]
    },
    {
        "name": "serene_lake_morning",
        "base": "Calm mountain lake at dawn, perfectly still water reflecting mountains, soft pink and blue sky",
        "elements": ["mirror-like water surface", "distant mountain peaks", "soft dawn colors", "peaceful atmosphere"]
    },
    {
        "name": "gentle_stream_nature",
        "base": "Gentle stream flowing through a peaceful forest clearing, sunlight filtering through leaves, natural serenity",
        "elements": ["clear flowing water", "sunlit forest clearing", "natural rocks and pebbles", "tranquil setting"]
    },
    {
        "name": "serene_beach_dawn",
        "base": "Peaceful beach at dawn, calm turquoise water, soft sand, pastel sky colors, serene coastal scene",
        "elements": ["calm turquoise water", "soft sandy beach", "pastel sky gradient", "peaceful coastal atmosphere"]
    },
    {
        "name": "mountain_valley_mist",
        "base": "Misty mountain valley at sunrise, layers of blue mountains fading into fog, warm light breaking through",
        "elements": ["layered mountain ridges", "soft morning mist", "warm sunrise glow", "peaceful valley"]
    }
]

# Style guide for light serene nature backgrounds
STYLE_GUIDE = {
    "color_palettes": [
        "soft pastel blues and warm golden sunrise tones",
        "gentle greens and soft cream with natural earth tones",
        "light lavender and pale pink with soft white clouds",
        "warm amber and soft teal with natural lighting",
        "soft peach and light blue with golden hour glow"
    ],
    "mood_descriptors": [
        "serene", "peaceful", "tranquil", "calming", 
        "gentle", "soft", "light", "natural"
    ],
    "quality_keywords": [
        "professional nature photography",
        "soft natural lighting",
        "cinematic composition",
        "high resolution detail",
        "dreamlike serene atmosphere",
        "realistic natural beauty"
    ]
}

def build_prompt(scene: dict, palette: str, mood: str) -> str:
    """Build a detailed prompt for DALL-E 3."""
    quality = ", ".join(random.sample(STYLE_GUIDE["quality_keywords"], 3))
    adjectives = ['breathtaking', 'stunning', 'beautiful', 'majestic', 'peaceful']
    
    prompt = f"""A {mood} and {random.choice(adjectives)} {scene['base']}, 
    color palette featuring {palette}, 
    with {', '.join(scene['elements'])}.
    Style: {quality}.
    Vertical composition perfectly framed for mobile phone wallpaper (9:16 aspect ratio).
    Absolutely no text, no people, no man-made objects except natural paths.
    Ultra high quality photorealistic nature photography with exceptional detail.
    Light and serene atmosphere, real nature scene."""
    
    return " ".join(prompt.split())


def generate_image(client: OpenAI, prompt: str, filename: str) -> dict:
    """Generate an image using OpenAI DALL-E 3."""
    print(f"\n🎨 Generating: {filename}")
    print(f"   Prompt: {prompt[:150]}...")
    
    try:
        # DALL-E 3 supports 1024x1792 for portrait orientation
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1792",  # Portrait orientation for mobile
            quality="standard",
            n=1,
        )
        
        image_url = response.data[0].url
        
        # Download the image
        print(f"   📥 Downloading image...")
        img_response = requests.get(image_url)
        img_response.raise_for_status()
        
        # Create assets directory structure
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        asset_dir = OUTPUT_DIR / f"{filename}.imageset"
        asset_dir.mkdir(parents=True, exist_ok=True)
        
        # Save image
        image_path = asset_dir / "image.png"
        with open(image_path, "wb") as f:
            f.write(img_response.content)
        
        print(f"   ✅ Saved: {image_path}")
        print(f"   📊 Size: {image_path.stat().st_size / 1024:.1f} KB")
        
        # Create Contents.json for the asset
        contents_json = {
            "images": [
                {
                    "filename": "image.png",
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
            }
        }
        
        contents_path = asset_dir / "Contents.json"
        with open(contents_path, "w") as f:
            json.dump(contents_json, f, indent=2)
        
        print(f"   ✅ Created Contents.json")
        
        return {
            "filename": filename,
            "path": str(image_path),
            "url": image_url,
            "prompt": prompt
        }
        
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return None


def generate_batch(count: int = 6):
    """Generate a batch of serene backgrounds."""
    if not API_KEY:
        print("❌ Error: OPENAI_API_KEY not found in environment variables")
        print("   Please set it in your .env file or export it")
        return []
    
    results = []
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Initialize OpenAI client
    client = OpenAI(api_key=API_KEY)
    
    # Shuffle scenes to get variety
    available_scenes = random.sample(SCENE_TEMPLATES, min(count, len(SCENE_TEMPLATES)))
    
    for i in range(count):
        scene = available_scenes[i % len(available_scenes)]
        palette = random.choice(STYLE_GUIDE["color_palettes"])
        mood = random.choice(STYLE_GUIDE["mood_descriptors"])
        
        prompt = build_prompt(scene, palette, mood)
        filename = f"SereneBackground{i+1}"
        
        print(f"\n🎨 [{i+1}/{count}] Generating: {scene['name']}")
        print(f"   Mood: {mood}")
        print(f"   Palette: {palette[:50]}...")
        
        result = generate_image(client, prompt, filename)
        if result:
            results.append({
                "scene": scene['name'],
                **result
            })
    
    # Save manifest with all generation details
    if results:
        manifest_path = OUTPUT_DIR.parent / f"manifest_serene_openai_{timestamp}.json"
        with open(manifest_path, "w") as f:
            json.dump({
                "generated_at": timestamp,
                "count": len(results),
                "provider": "openai-dall-e-3",
                "images": results
            }, f, indent=2)
        print(f"\n📋 Manifest saved: {manifest_path}")
    
    return results


def main():
    import sys
    
    count = 6  # Default to 6 backgrounds
    
    # Parse arguments
    if len(sys.argv) > 1:
        try:
            count = int(sys.argv[1])
        except ValueError:
            print(f"Unknown argument: {sys.argv[1]}")
    
    print("🌅 Serene Background Generator for Living Devotional")
    print("=" * 60)
    print("🤖 Using: OpenAI DALL-E 3")
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    print(f"🖼️  Generating {count} serene nature image(s) at 1024x1792 (iPhone portrait)")
    print(f"⏱️  Note: Each image may take 10-20 seconds to generate")
    
    results = generate_batch(count=count)
    
    print(f"\n{'='*60}")
    print(f"✨ Successfully generated {len(results)}/{count} serene backgrounds")
    
    if results:
        print("\n📸 Generated assets:")
        for r in results:
            print(f"   • {r['filename']} -> {r['scene']}")
        print(f"\n🎯 Assets saved to: {OUTPUT_DIR.absolute()}")
    
    return results


if __name__ == "__main__":
    main()
