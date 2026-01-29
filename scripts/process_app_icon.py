import os
from PIL import Image, ImageChops

source_path = "generated_icons/icon_candidate_20260125_004132_3.png"
dest_dir = "livingdevotional/Assets.xcassets/AppIcon.appiconset"

def autocrop_icon(image_path, tolerance=30):
    img = Image.open(image_path)
    img = img.convert("RGBA")
    
    # Get the background color from the top-left pixel
    bg = img.getpixel((0, 0))
    
    # Create a background image of the same color
    bg_img = Image.new("RGBA", img.size, bg)
    
    # Find the difference between the input image and the background
    diff = ImageChops.difference(img, bg_img)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    
    # Get the bounding box of the non-background area
    bbox = diff.getbbox()
    
    if bbox:
        print(f"Original size: {img.size}")
        print(f"Detected content bounding box: {bbox}")
        
        # Crop to the bounding box
        cropped = img.crop(bbox)
        
        # Resize back to 1024x1024 with high quality
        resized = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
        
        # Convert back to RGB (drop alpha if any)
        final = resized.convert("RGB")
        return final
    else:
        print("Could not detect bounding box. Returning original.")
        return img.convert("RGB")

def main():
    if not os.path.exists(source_path):
        print(f"Error: Source file {source_path} not found.")
        return

    print(f"Processing {source_path}...")
    
    # Process the image
    final_icon = autocrop_icon(source_path)
    
    # Save to assets
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
        
    # Save Universal
    save_path = os.path.join(dest_dir, "AppIcon-1024.png")
    final_icon.save(save_path)
    print(f"Saved processed icon to {save_path}")
    
    # Save Dark (same for now)
    dark_path = os.path.join(dest_dir, "AppIcon-1024-dark.png")
    final_icon.save(dark_path)
    print(f"Saved dark icon to {dark_path}")
    
    # Save Tinted (grayscale)
    tinted = final_icon.convert("L")
    tinted_path = os.path.join(dest_dir, "AppIcon-1024-tinted.png")
    tinted.save(tinted_path)
    print(f"Saved tinted icon to {tinted_path}")

if __name__ == "__main__":
    main()
