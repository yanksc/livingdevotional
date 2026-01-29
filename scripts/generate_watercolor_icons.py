#!/usr/bin/env python3
"""
Watercolor App Icon Generator
Generates app icon candidates using OpenAI DALL-E 3.
Style: Soft watercolor abstract with path and cross elements.

Usage:
    export OPENAI_API_KEY="your-key-here"
    python generate_watercolor_icons.py [count]
"""

import os
import sys
import json
import requests
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

try:
    from openai import OpenAI
except ImportError:
    print("Error: 'openai' package not found. Please install it:")
    print("pip install openai")
    sys.exit(1)

# Configuration
OUTPUT_DIR = Path(__file__).parent.parent / "generated_icons"
SIZE = "1024x1024"
QUALITY = "standard"  # "standard" or "hd"

def build_icon_prompt(variation_idx: int) -> str:
    """Build a prompt for the app icon."""
    
    # Core elements
    subject = "A simple, minimalist app icon design featuring a gentle path leading towards a simple cross."
    
    # Style definition based on the "watercolor" request
    style = """
    Art Style: Soft abstract watercolor with a torn paper edge aesthetic.
    Colors: Muted sage green, soft cream, and warm earth tones.
    Composition: Centered, balanced, suitable for an iOS app icon.
    Details: 
    - The path should be subtle, perhaps just a wash of color or negative space.
    - The cross should be simple and elegant, not ornate.
    - The background should have the texture of high-quality watercolor paper.
    - Use a 'squircle' shape or ensure the design works well within a square frame.
    - Minimalist, clean, no text, no clutter.
    """
    
    # Variations
    variations = [
        "Focus on a winding path through a soft watercolor landscape leading to a distant cross.",
        "Focus on a central cross with a path flowing from the bottom, stylized and abstract.",
        "Focus on the intersection of a path and a cross, very abstract and symbolic."
    ]
    
    specific_variation = variations[variation_idx % len(variations)]
    
    return f"{subject} {specific_variation} {style}"

def generate_icon(client, index: int):
    """Generate a single icon candidate."""
    prompt = build_icon_prompt(index)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"icon_candidate_{timestamp}_{index+1}.png"
    
    print(f"\n🎨 [{index+1}] Generating icon candidate...")
    print(f"  Prompt: {prompt[:100]}...")
    
    try:
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size=SIZE,
            quality=QUALITY,
            n=1,
        )
        
        image_url = response.data[0].url
        
        # Download the image
        print(f"  📥 Downloading...")
        img_response = requests.get(image_url)
        
        if img_response.status_code == 200:
            OUTPUT_DIR.mkdir(exist_ok=True)
            filepath = OUTPUT_DIR / filename
            
            with open(filepath, "wb") as f:
                f.write(img_response.content)
                
            print(f"  ✅ Saved: {filepath}")
            return {
                "filename": filename,
                "path": str(filepath),
                "prompt": prompt,
                "url": image_url
            }
        else:
            print(f"  ❌ Failed to download: {img_response.status_code}")
            return None
            
    except Exception as e:
        print(f"  ❌ Error: {str(e)}")
        return None

def main():
    # Check API Key
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("❌ Error: OPENAI_API_KEY environment variable not set.")
        print("Please ensure you have a .env file with OPENAI_API_KEY set.")
        return

    client = OpenAI(api_key=api_key)
    
    # Parse count
    count = 3
    if len(sys.argv) > 1:
        try:
            count = int(sys.argv[1])
        except ValueError:
            pass
            
    print("🎨 Watercolor App Icon Generator")
    print("=" * 50)
    print(f"Output: {OUTPUT_DIR}")
    print(f"Generating {count} candidates using DALL-E 3")
    
    results = []
    for i in range(count):
        result = generate_icon(client, i)
        if result:
            results.append(result)
            
    if results:
        print(f"\n✨ Successfully generated {len(results)} icons.")
        print(f"📂 Open folder: open {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
