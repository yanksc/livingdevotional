#!/usr/bin/env python3
"""
Dark Serene Background Generator for Living Devotional
Generates unique dark, natural, and serene devotional backgrounds using OpenAI DALL-E 3
"""

import os
import json
import random
import base64
import requests
from datetime import datetime
from pathlib import Path

try:
    from openai import OpenAI
except ImportError:
    print("❌ Error: openai package not installed. Run: pip install openai")
    exit(1)

# Configuration
OUTPUT_DIR = Path(__file__).parent.parent / "livingdevotional" / "Assets.xcassets" / "PrayerBackgrounds"

# Get OpenAI API key from environment
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    print("❌ Error: OPENAI_API_KEY environment variable not set")
    print("   Set it with: export OPENAI_API_KEY='your-key-here'")
    exit(1)

# Ensure output directory exists
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

# Style guide for Dark Serene Natural backgrounds - Real Mother Nature Photography
STYLE_GUIDE = {
    "color_palettes": [
        "natural deep indigo and midnight blue with real moonlight",
        "authentic dark forest green and charcoal with natural ambient light",
        "real obsidian and slate grey with warm natural highlights",
        "genuine deep violet and navy with actual starlight",
        "natural rich espresso and dark moss with real golden hour light"
    ],
    "mood_descriptors": [
        "peaceful", "serene", "tranquil", "calm", 
        "contemplative", "meditative", "still", "natural"
    ],
    "quality_keywords": [
        "real nature photography",
        "authentic landscape photography",
        "natural lighting only",
        "photographed at dusk or dawn",
        "realistic depth of field",
        "high resolution nature photography",
        "minimal post-processing",
        "authentic natural scene",
        "no digital effects",
        "realistic textures"
    ]
}

# Scene templates - Real Mother Nature Photography
SCENE_TEMPLATES = [
    {
        "name": "moonlit_forest_path",
        "base": "Real forest path photographed at night, naturally illuminated by moonlight filtering through trees, authentic natural scene",
        "elements": ["real tree silhouettes", "natural moonlight", "authentic forest undergrowth", "photographed with long exposure"]
    },
    {
        "name": "mountain_lake_dusk",
        "base": "Real mountain lake photographed at dusk, naturally reflecting the sky and surrounding mountains, authentic landscape",
        "elements": ["real water reflection", "natural mountain silhouette", "authentic lake surface", "photographed at golden hour"]
    },
    {
        "name": "coastal_cave_dawn",
        "base": "Real coastal cave entrance photographed at dawn, looking out at the natural seascape, authentic natural framing",
        "elements": ["real rock formations", "natural dawn light", "authentic ocean view", "photographed at sunrise"]
    },
    {
        "name": "desert_night_sky",
        "base": "Real desert dunes photographed at night under natural starlight, authentic landscape photography",
        "elements": ["real sand textures", "natural starry sky", "authentic desert landscape", "photographed with astrophotography"]
    },
    {
        "name": "forest_stream_twilight",
        "base": "Real forest stream photographed at twilight, natural water flow with surrounding vegetation, authentic nature scene",
        "elements": ["real flowing water", "natural forest environment", "authentic plant life", "photographed at blue hour"]
    }
]

def build_prompt(scene: dict, palette: str, mood: str) -> str:
    """Build a detailed prompt emphasizing real photography."""
    quality = ", ".join(random.sample(STYLE_GUIDE["quality_keywords"], 4))
    
    prompt = f"""Real {mood} {scene['base']}, 
    natural colors featuring {palette}, 
    with {', '.join(scene['elements'])}.
    Style: {quality}.
    Vertical composition for mobile wallpaper.
    Authentic nature photography, not digital art or illustration.
    Realistic textures, natural lighting, genuine depth of field.
    No text, no people, no artificial elements.
    Photographed by a professional nature photographer.
    High quality real photography, not AI-generated or stylized."""
    
    return " ".join(prompt.split())

def generate_image(prompt: str, filename: str) -> bool:
    """Generate and save an image using OpenAI DALL-E 3."""
    print(f"  Generating: {filename}...")
    print(f"  Prompt: {prompt[:100]}...")
    
    try:
        client = OpenAI(api_key=OPENAI_API_KEY)
        
        # DALL-E 3 supports 1024x1024, 1024x1792, or 1792x1024
        # Using 1024x1792 for vertical mobile wallpaper
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1792",
            quality="standard",
            n=1,
        )
        
        # Get the image URL
        image_url = response.data[0].url
        
        # Download the image
        print(f"  📥 Downloading image from OpenAI...")
        img_response = requests.get(image_url, timeout=60)
        if img_response.status_code != 200:
            print(f"  ❌ Error downloading image: {img_response.status_code}")
            return False
        
        # Create imageset folder structure
        imageset_dir = OUTPUT_DIR / f"{filename}.imageset"
        imageset_dir.mkdir(exist_ok=True)
        
        # Save image
        image_path = imageset_dir / f"{filename}.png"
        with open(image_path, "wb") as f:
            f.write(img_response.content)
        
        # Create Contents.json
        contents = {
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
            }
        }
        
        with open(imageset_dir / "Contents.json", "w") as f:
            json.dump(contents, f, indent=2)
            
        print(f"  ✅ Saved to {imageset_dir}")
        return True
        
    except Exception as e:
        print(f"  ❌ Exception: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("🌑 Generating Dark Serene Backgrounds using OpenAI DALL-E 3...")
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    
    # Create the main group Contents.json if it doesn't exist
    if not (OUTPUT_DIR / "Contents.json").exists():
        with open(OUTPUT_DIR / "Contents.json", "w") as f:
            json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

    count = 5
    generated_count = 0
    
    # Shuffle scenes
    scenes = random.sample(SCENE_TEMPLATES, len(SCENE_TEMPLATES))
    
    for i in range(count):
        scene = scenes[i % len(scenes)]
        palette = random.choice(STYLE_GUIDE["color_palettes"])
        mood = random.choice(STYLE_GUIDE["mood_descriptors"])
        
        prompt = build_prompt(scene, palette, mood)
        filename = f"dark_serene_{i+1}"
        
        print(f"\n[{i+1}/{count}] Processing: {scene['name']}")
        if generate_image(prompt, filename):
            generated_count += 1
        else:
            print(f"  ⚠️  Failed to generate {filename}")
        
        # Add a small delay to avoid rate limiting
        if i < count - 1:
            import time
            time.sleep(2)
            
    print(f"\n✨ Finished! Generated {generated_count}/{count} backgrounds in {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
