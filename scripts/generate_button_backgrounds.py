#!/usr/bin/env python3
"""
Button Background Generator for Living Devotional
Generates serene backgrounds for Pray and Search buttons on ExploreView

Usage:
    python generate_button_backgrounds.py
"""

import os
import json
import random
import requests
import urllib.parse
from datetime import datetime
from pathlib import Path

# Configuration - Using Pollinations.ai (free, no API key required)
POLLINATIONS_URL = "https://image.pollinations.ai/prompt/"
OUTPUT_DIR = Path(__file__).parent.parent / "livingdevotional" / "Assets.xcassets" / "ButtonBackgrounds"

# Button-specific scene templates - SERENE natural colors only (no purple/pink)
BUTTON_SCENES = {
    "pray": [
        {
            "name": "pray_golden_light",
            "base": "Ethereal golden light rays streaming through soft white clouds at dawn, peaceful heavenly atmosphere, divine warm light beaming down",
            "elements": ["warm golden sunbeams", "soft white fluffy clouds", "gentle light diffusion", "soft cream and gold sky gradient"]
        },
        {
            "name": "pray_misty_morning",
            "base": "Serene misty morning sky with soft golden and cream tones, gentle fog with warm sunlight breaking through, peaceful contemplative mood",
            "elements": ["soft morning mist", "warm golden light rays", "gentle cream white clouds", "ethereal soft glow"]
        },
        {
            "name": "pray_calm_waters",
            "base": "Peaceful still lake at golden hour reflecting soft warm light, calm serene water surface with gentle sky, tranquil spiritual atmosphere",
            "elements": ["mirror-like calm water", "warm golden reflections", "soft sky tones", "peaceful horizon"]
        }
    ],
    "search": [
        {
            "name": "search_forest_light",
            "base": "Soft golden light rays streaming through lush green forest canopy, peaceful morning discovery, gentle warm illumination through trees",
            "elements": ["dappled golden light rays", "soft green foliage", "natural woodland pathway", "warm morning sunbeams"]
        },
        {
            "name": "search_meadow_path",
            "base": "Beautiful sunlit meadow path with soft green grass and warm golden light, inviting journey of discovery, peaceful nature scene",
            "elements": ["golden sunlit grass", "gentle winding path", "soft green meadow", "warm inviting light"]
        },
        {
            "name": "search_calm_lake",
            "base": "Serene teal lake with soft morning mist, gentle light on calm water surface, peaceful discovery atmosphere with natural beauty",
            "elements": ["soft teal water", "gentle morning mist", "warm light on horizon", "peaceful natural scene"]
        }
    ]
}

# Style settings for button backgrounds - SERENE natural colors only (no purple/pink)
STYLE_GUIDE = {
    "color_palettes": {
        "pray": [
            "warm golden and soft cream with gentle white light",
            "soft amber and warm ivory with divine golden rays",
            "gentle warm gold and soft white with spiritual glow"
        ],
        "search": [
            "soft teal and warm golden with hopeful light",
            "gentle sage green and warm amber with discovery tones",
            "peaceful soft blue-green and warm gold with guiding light"
        ]
    },
    "mood_descriptors": ["serene", "peaceful", "contemplative", "hopeful", "tranquil", "calming"],
    "quality_keywords": [
        "professional photography",
        "soft natural lighting",
        "cinematic composition",
        "high resolution detail",
        "dreamlike ethereal atmosphere",
        "soft focus bokeh"
    ]
}


def build_prompt(scene: dict, palette: str, mood: str, button_type: str) -> str:
    """Build a detailed prompt for button background."""
    quality = ", ".join(random.sample(STYLE_GUIDE["quality_keywords"], 3))
    
    prompt = f"""A {mood} and beautiful {scene['base']}, 
    color palette featuring {palette}, 
    with {', '.join(scene['elements'])}.
    Style: {quality}.
    Horizontal composition suitable for app button background.
    Absolutely no text, no people.
    Soft blurred edges for overlay text readability.
    Ultra high quality nature photography with serene spiritual atmosphere."""
    
    return " ".join(prompt.split())


def generate_image(prompt: str, filename: str, output_dir: Path) -> dict:
    """Generate an image using Pollinations.ai."""
    
    # Using 512x256 for button background (2:1 ratio, suitable for button)
    seed = random.randint(1, 999999)
    
    # URL encode the prompt
    encoded_prompt = urllib.parse.quote(prompt)
    
    # Build URL - using wider aspect ratio for button
    image_url = f"{POLLINATIONS_URL}{encoded_prompt}?width=512&height=256&seed={seed}&model=flux&nologo=true"
    
    print(f"  📤 Sending request to Pollinations.ai...")
    print(f"  🎲 Seed: {seed}")
    
    try:
        response = requests.get(image_url, timeout=180, stream=True)
        
        if response.status_code != 200:
            print(f"  ❌ Error: {response.status_code}")
            return None
        
        content_type = response.headers.get('content-type', '')
        if 'image' not in content_type:
            print(f"  ❌ Unexpected content type: {content_type}")
            return None
        
        # Save the image
        output_dir.mkdir(parents=True, exist_ok=True)
        filepath = output_dir / f"{filename}.png"
        
        print(f"  📥 Downloading image...")
        with open(filepath, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        if filepath.exists() and filepath.stat().st_size > 0:
            print(f"  ✅ Saved: {filepath}")
            print(f"  📊 Size: {filepath.stat().st_size / 1024:.1f} KB")
            
            return {
                "filename": f"{filename}.png",
                "filepath": str(filepath.absolute()),
                "prompt": prompt,
                "seed": seed,
                "size": "512x256",
                "model": "flux"
            }
        else:
            print(f"  ❌ File was not saved correctly")
            return None
            
    except requests.exceptions.Timeout:
        print(f"  ❌ Request timed out")
        return None
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return None


def create_xcassets_contents(filename: str, imageset_dir: Path):
    """Create Contents.json for Xcode asset catalog."""
    contents = {
        "images": [
            {
                "filename": f"{filename}.png",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(imageset_dir / "Contents.json", "w") as f:
        json.dump(contents, f, indent=2)


def generate_button_backgrounds():
    """Generate backgrounds for Pray and Search buttons."""
    results = []
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Create main output directory
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create Contents.json for the ButtonBackgrounds folder
    folder_contents = {
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    with open(OUTPUT_DIR / "Contents.json", "w") as f:
        json.dump(folder_contents, f, indent=2)
    
    for button_type in ["pray", "search"]:
        print(f"\n{'='*60}")
        print(f"🎨 Generating {button_type.upper()} button background...")
        print(f"{'='*60}")
        
        # Select a random scene for this button type
        scene = random.choice(BUTTON_SCENES[button_type])
        palette = random.choice(STYLE_GUIDE["color_palettes"][button_type])
        mood = random.choice(STYLE_GUIDE["mood_descriptors"])
        
        prompt = build_prompt(scene, palette, mood, button_type)
        filename = f"{button_type}_background_{timestamp}"
        
        print(f"  Scene: {scene['name']}")
        print(f"  Mood: {mood}")
        print(f"  Palette: {palette[:50]}...")
        
        # Create imageset directory for Xcode
        imageset_name = f"{button_type.capitalize()}ButtonBackground"
        imageset_dir = OUTPUT_DIR / f"{imageset_name}.imageset"
        imageset_dir.mkdir(exist_ok=True)
        
        result = generate_image(prompt, f"{button_type}_background", imageset_dir)
        
        if result:
            # Create Contents.json for the imageset
            create_xcassets_contents(f"{button_type}_background", imageset_dir)
            result["imageset_name"] = imageset_name
            results.append(result)
    
    # Save manifest
    if results:
        manifest_path = OUTPUT_DIR / f"manifest_{timestamp}.json"
        with open(manifest_path, "w") as f:
            json.dump({
                "generated_at": timestamp,
                "count": len(results),
                "type": "button_backgrounds",
                "images": results
            }, f, indent=2)
        print(f"\n📋 Manifest saved: {manifest_path}")
    
    return results


def main():
    print("🎨 Button Background Generator for Living Devotional")
    print("=" * 60)
    print("🤖 Using: Pollinations.ai with Flux model (free, no API key)")
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    print("🖼️  Generating backgrounds at 512x256 (button ratio)")
    print("⏱️  Note: Each image may take 30-60 seconds to generate")
    
    results = generate_button_backgrounds()
    
    print(f"\n{'='*60}")
    print(f"✨ Successfully generated {len(results)}/2 button backgrounds")
    
    if results:
        print("\n📸 Generated assets:")
        for r in results:
            print(f"   • {r['imageset_name']}")
        print(f"\n🎯 Asset location: {OUTPUT_DIR.absolute()}")
        print("\n📝 To use in SwiftUI:")
        print('   Image("PrayButtonBackground")')
        print('   Image("SearchButtonBackground")')
    
    return results


if __name__ == "__main__":
    main()
