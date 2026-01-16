#!/usr/bin/env python3
"""
Serene Background Generator for Living Devotional
Generates unique devotional backgrounds using Pollinations.ai (free, no API key needed)

Usage:
    python generate_serene_backgrounds.py [count]
    
Example:
    python generate_serene_backgrounds.py 3
"""

import os
import json
import random
import requests
import urllib.parse
from datetime import datetime
from pathlib import Path

# Configuration - Using Pollinations.ai (free, no API key required)
# Pollinations uses Flux model for high-quality image generation
POLLINATIONS_URL = "https://image.pollinations.ai/prompt/"
OUTPUT_DIR = Path(__file__).parent.parent / "generated_backgrounds"

# Style guide extracted from reference images (beach sunset, forest stream, mountains, etc.)
STYLE_GUIDE = {
    "color_palettes": [
        "soft teal and warm coral sunset tones with golden reflections",
        "golden hour warm amber light with soft blue sky gradients",
        "pastel pink and lavender twilight with gentle cloud formations",
        "misty blue and sage green morning light with soft diffusion",
        "soft peach and turquoise dawn with delicate cloud wisps"
    ],
    "mood_descriptors": [
        "serene", "contemplative", "peaceful", "tranquil", 
        "ethereal", "meditative", "calming", "spiritual"
    ],
    "quality_keywords": [
        "professional landscape photography",
        "soft natural lighting",
        "cinematic composition",
        "high resolution 4K detail",
        "dreamlike ethereal atmosphere",
        "shallow depth of field bokeh"
    ]
}

# Scene templates for devotional backgrounds - inspired by reference images
SCENE_TEMPLATES = [
    {
        "name": "ocean_pebble_beach",
        "base": "Calm turquoise ocean waves gently washing onto a smooth pebble beach at sunset, soft foam on rounded stones",
        "elements": ["polished beach pebbles in foreground", "gentle waves", "warm sunset glow on horizon"]
    },
    {
        "name": "forest_golden_stream",
        "base": "Peaceful forest stream with golden sunlight filtering through tree canopy, lush green vegetation along riverbank",
        "elements": ["dappled golden light rays", "soft green ferns and wildflowers", "gentle flowing water"]
    },
    {
        "name": "mountain_flower_meadow",
        "base": "Misty mountain valley at sunrise with pink cosmos flowers in foreground, layered blue mountain ridges fading into fog",
        "elements": ["delicate wildflowers silhouetted against sky", "soft morning mist between peaks", "warm sunrise glow"]
    },
    {
        "name": "boardwalk_to_sea",
        "base": "Weathered wooden boardwalk path leading to calm ocean beach, soft cloudy sky, peaceful and inviting atmosphere",
        "elements": ["rustic wooden planks with natural texture", "sea grass on sandy dunes", "distant calm water"]
    },
    {
        "name": "calm_water_reflection",
        "base": "Perfectly still water at twilight reflecting pastel pink and blue sky, tranquil and mirror-like surface",
        "elements": ["seamless horizon blend", "soft cloud reflections", "ethereal color gradient"]
    },
    {
        "name": "pier_pastel_sunset",
        "base": "Old wooden pier extending into calm pastel-colored water at sunset, soft pink and blue sky reflection",
        "elements": ["weathered wooden dock posts", "glassy water surface", "distant islands in haze"]
    },
    {
        "name": "misty_lake_tree",
        "base": "Single graceful tree on small island in misty blue lake, perfect reflection in still water, mountains in background",
        "elements": ["lone tree silhouette", "morning mist rising from water", "layered mountain backdrop"]
    }
]

# Fantasy and eccentric scene templates - more dramatic and otherworldly
FANTASY_SCENE_TEMPLATES = [
    {
        "name": "aurora_crystal_lake",
        "base": "Mystical crystal-clear lake beneath swirling aurora borealis in vivid greens and purples, glowing ethereal northern lights dancing across night sky",
        "elements": ["luminescent aurora ribbons", "crystalline ice formations", "starfield reflection in water", "bioluminescent glow"]
    },
    {
        "name": "floating_islands_clouds",
        "base": "Majestic floating islands suspended in golden sunset clouds, ancient trees growing on impossible floating rocks, waterfalls cascading into void",
        "elements": ["floating rock formations", "cascading waterfalls into clouds", "dramatic god rays", "ancient twisted trees"]
    },
    {
        "name": "bioluminescent_forest",
        "base": "Enchanted forest at night with glowing bioluminescent mushrooms and plants, ethereal blue and purple light illuminating magical pathway",
        "elements": ["glowing mushroom clusters", "luminescent flowers", "magical fireflies", "mysterious fog with inner glow"]
    },
    {
        "name": "cosmic_ocean_gateway",
        "base": "Surreal ocean scene where water meets the cosmos, galaxy and stars reflected in calm water, nebula colors swirling in sky above serene beach",
        "elements": ["milky way reflection", "cosmic nebula clouds", "glowing horizon line", "starlight on gentle waves"]
    },
    {
        "name": "crystal_cave_light",
        "base": "Magnificent crystal cave interior with giant amethyst and quartz formations, divine light beam streaming through opening, sacred ethereal atmosphere",
        "elements": ["massive crystal formations", "prismatic light refractions", "underground crystal pool", "heavenly light shaft"]
    },
    {
        "name": "cherry_blossom_realm",
        "base": "Otherworldly Japanese cherry blossom paradise with pink petals swirling in spiral patterns, glowing sakura trees over mirror-like pond, mystical atmosphere",
        "elements": ["swirling pink petal vortex", "luminescent sakura trees", "torii gate silhouette", "magical mist with sparkles"]
    },
    {
        "name": "double_sun_desert",
        "base": "Alien desert landscape with two suns setting on horizon, dramatic sand dunes in impossible colors of purple and gold, otherworldly serene beauty",
        "elements": ["binary sunset", "iridescent sand dunes", "exotic alien plants", "dramatic long shadows"]
    },
    {
        "name": "underwater_temple",
        "base": "Ancient submerged temple ruins with divine light streaming through water surface, peaceful underwater scene with gentle fish and coral",
        "elements": ["crumbling stone columns", "light rays through water", "sacred temple architecture", "bioluminescent sea life"]
    }
]

# Fantasy style guide additions
FANTASY_STYLE_GUIDE = {
    "color_palettes": [
        "vivid aurora greens and deep cosmic purples with starlight silver",
        "ethereal bioluminescent blues and mystical teals with soft glow",
        "dramatic sunset oranges bleeding into cosmic deep purples",
        "mystical pink sakura and soft lavender with golden sparkles",
        "crystalline ice blues and prismatic rainbow refractions",
        "otherworldly turquoise and rose gold with celestial white"
    ],
    "mood_descriptors": [
        "mystical", "ethereal", "enchanted", "cosmic", 
        "otherworldly", "magical", "transcendent", "divine"
    ],
    "quality_keywords": [
        "fantasy digital art masterpiece",
        "cinematic dramatic lighting",
        "hyper-detailed 8K resolution",
        "epic scale and composition",
        "magical atmosphere with volumetric lighting",
        "award-winning concept art quality"
    ]
}


def build_dalle_prompt(scene: dict, palette: str, mood: str, fantasy: bool = False) -> str:
    """Build a detailed prompt from scene template and style guide."""
    if fantasy:
        quality = ", ".join(random.sample(FANTASY_STYLE_GUIDE["quality_keywords"], 3))
        adjectives = ['breathtaking', 'stunning', 'magnificent', 'awe-inspiring', 'spectacular']
    else:
        quality = ", ".join(random.sample(STYLE_GUIDE["quality_keywords"], 3))
        adjectives = ['breathtaking', 'stunning', 'beautiful', 'majestic']
    
    if fantasy:
        prompt = f"""A {mood} and {random.choice(adjectives)} {scene['base']}, 
        color palette featuring {palette}, 
        with {', '.join(scene['elements'])}.
        Style: {quality}.
        Vertical composition perfectly framed for mobile phone wallpaper.
        Absolutely no text, no people.
        Epic fantasy art with magical atmosphere and extraordinary visual detail."""
    else:
        prompt = f"""A {mood} and {random.choice(adjectives)} {scene['base']}, 
        color palette featuring {palette}, 
        with {', '.join(scene['elements'])}.
        Style: {quality}.
        Vertical composition perfectly framed for mobile phone wallpaper.
        Absolutely no text, no people, no man-made objects except natural paths.
        Ultra high quality photorealistic nature photography with exceptional detail."""
    
    return " ".join(prompt.split())


def generate_image(prompt: str, filename: str) -> dict:
    """Generate an image using Pollinations.ai (free, no API key needed)."""
    
    # Pollinations.ai URL format: https://image.pollinations.ai/prompt/{prompt}?width=X&height=Y&seed=X&model=flux
    # Using 1024x1792 for iPhone portrait (9:16 ratio)
    seed = random.randint(1, 999999)  # Random seed for variety
    
    # URL encode the prompt
    encoded_prompt = urllib.parse.quote(prompt)
    
    # Build URL with parameters - using Flux model for best quality
    image_url = f"{POLLINATIONS_URL}{encoded_prompt}?width=1024&height=1792&seed={seed}&model=flux&nologo=true"
    
    print(f"  📤 Sending request to Pollinations.ai (Flux model)...")
    print(f"  🎲 Seed: {seed}")
    
    try:
        # Pollinations returns the image directly
        response = requests.get(image_url, timeout=180, stream=True)
        
        if response.status_code != 200:
            print(f"  ❌ Error: {response.status_code}")
            print(f"  Response: {response.text[:500] if response.text else 'No response body'}")
            return None
        
        # Check if we got an image
        content_type = response.headers.get('content-type', '')
        if 'image' not in content_type:
            print(f"  ❌ Unexpected content type: {content_type}")
            return None
        
        # Save the image
        OUTPUT_DIR.mkdir(exist_ok=True)
        filepath = OUTPUT_DIR / f"{filename}.png"
        
        print(f"  📥 Downloading image...")
        with open(filepath, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        # Verify file was created and has content
        if filepath.exists() and filepath.stat().st_size > 0:
            print(f"  ✅ Saved: {filepath}")
            print(f"  📊 Size: {filepath.stat().st_size / 1024:.1f} KB")
            
            return {
                "filename": f"{filename}.png",
                "filepath": str(filepath.absolute()),
                "prompt": prompt,
                "seed": seed,
                "size": "1024x1792",
                "model": "flux"
            }
        else:
            print(f"  ❌ File was not saved correctly")
            return None
            
    except requests.exceptions.Timeout:
        print(f"  ❌ Request timed out (image generation can take up to 2-3 minutes)")
        return None
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return None


def generate_batch(count: int = 3, fantasy: bool = False):
    """Generate a batch of serene or fantasy backgrounds."""
    results = []
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Choose templates and style based on mode
    if fantasy:
        templates = FANTASY_SCENE_TEMPLATES
        style_guide = FANTASY_STYLE_GUIDE
        prefix = "fantasy"
    else:
        templates = SCENE_TEMPLATES
        style_guide = STYLE_GUIDE
        prefix = "serene"
    
    # Shuffle scenes to get variety
    available_scenes = random.sample(templates, min(count, len(templates)))
    
    for i in range(count):
        scene = available_scenes[i % len(available_scenes)]
        palette = random.choice(style_guide["color_palettes"])
        mood = random.choice(style_guide["mood_descriptors"])
        
        prompt = build_dalle_prompt(scene, palette, mood, fantasy=fantasy)
        filename = f"{prefix}_{scene['name']}_{timestamp}_{i+1}"
        
        print(f"\n🎨 [{i+1}/{count}] Generating: {scene['name']}")
        print(f"  Mood: {mood}")
        print(f"  Palette: {palette[:50]}...")
        
        result = generate_image(prompt, filename)
        if result:
            results.append(result)
    
    # Save manifest with all generation details
    if results:
        manifest_path = OUTPUT_DIR / f"manifest_{prefix}_{timestamp}.json"
        with open(manifest_path, "w") as f:
            json.dump({
                "generated_at": timestamp,
                "count": len(results),
                "mode": "fantasy" if fantasy else "serene",
                "images": results
            }, f, indent=2)
        print(f"\n📋 Manifest saved: {manifest_path}")
    
    return results


def main():
    import sys
    
    count = 3
    fantasy = False
    
    # Parse arguments
    args = sys.argv[1:]
    for arg in args:
        if arg in ['--fantasy', '-f']:
            fantasy = True
        else:
            try:
                count = int(arg)
            except ValueError:
                print(f"Unknown argument: {arg}")
    
    mode_name = "Fantasy" if fantasy else "Serene"
    mode_emoji = "✨" if fantasy else "🌅"
    
    print(f"{mode_emoji} {mode_name} Background Generator for Living Devotional")
    print("=" * 60)
    print("🤖 Using: Pollinations.ai with Flux model (free, no API key)")
    print(f"📁 Output directory: {OUTPUT_DIR.absolute()}")
    print(f"🖼️  Generating {count} {mode_name.lower()} image(s) at 1024x1792 (iPhone portrait)")
    print(f"⏱️  Note: Each image may take 30-60 seconds to generate")
    
    results = generate_batch(count=count, fantasy=fantasy)
    
    print(f"\n{'='*60}")
    print(f"✨ Successfully generated {len(results)}/{count} {mode_name.lower()} backgrounds")
    
    if results:
        print("\n📸 Generated files:")
        for r in results:
            print(f"   • {r['filename']}")
        print(f"\n🎯 Open folder: open \"{OUTPUT_DIR.absolute()}\"")
    
    return results


if __name__ == "__main__":
    main()
