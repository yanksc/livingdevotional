import os
import math
from PIL import Image

source_path = "generated_icons/icon_candidate_20260125_004132_3.png"
dest_dir = "livingdevotional/Assets.xcassets/AppIcon.appiconset"

def color_distance(c1, c2):
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(c1, c2)))

def find_content_bounds(img, threshold=45):
    width, height = img.size
    pixels = img.load()
    
    # Sample corners to get "background" color
    corners = [
        pixels[0, 0],
        pixels[width-1, 0],
        pixels[0, height-1],
        pixels[width-1, height-1],
        pixels[10, 10], # Sample slightly inner too
        pixels[width-10, 10]
    ]
    
    # Average corner color
    bg_r = sum(c[0] for c in corners) // len(corners)
    bg_g = sum(c[1] for c in corners) // len(corners)
    bg_b = sum(c[2] for c in corners) // len(corners)
    bg_color = (bg_r, bg_g, bg_b)
    
    print(f"Estimated background color: {bg_color}")
    
    # Scan for top bound
    top = 0
    for y in range(height // 2):
        row_diff = 0
        for x in range(0, width, 5): # Sample more frequently
            if color_distance(pixels[x, y], bg_color) > threshold:
                row_diff += 1
        # Require a significant portion of the row to be different (e.g. 30%)
        # This avoids noise triggering the bound
        if row_diff > (width / 5) * 0.3: 
            top = y
            break
            
    # Scan for bottom bound
    bottom = height - 1
    for y in range(height - 1, height // 2, -1):
        row_diff = 0
        for x in range(0, width, 5):
            if color_distance(pixels[x, y], bg_color) > threshold:
                row_diff += 1
        if row_diff > (width / 5) * 0.3:
            bottom = y
            break
            
    # Scan for left bound
    left = 0
    for x in range(width // 2):
        col_diff = 0
        for y in range(0, height, 5):
            if color_distance(pixels[x, y], bg_color) > threshold:
                col_diff += 1
        if col_diff > (height / 5) * 0.3:
            left = x
            break
            
    # Scan for right bound
    right = width - 1
    for x in range(width - 1, width // 2, -1):
        col_diff = 0
        for y in range(0, height, 5):
            if color_distance(pixels[x, y], bg_color) > threshold:
                col_diff += 1
        if col_diff > (height / 5) * 0.3:
            right = x
            break
            
    return (left, top, right, bottom)

def smart_process_icon():
    if not os.path.exists(source_path):
        print(f"Error: Source file {source_path} not found.")
        return

    print(f"Processing {source_path}...")
    img = Image.open(source_path).convert("RGB")
    
    # Find bounds
    left, top, right, bottom = find_content_bounds(img)
    print(f"Detected bounds: Left={left}, Top={top}, Right={right}, Bottom={bottom}")
    
    width, height = img.size
    
    # Check if detection failed (returned full image)
    is_full_image = (left < 50 and top < 50 and right > width-50 and bottom > height-50)
    
    if is_full_image:
        print("⚠️ Detection returned full image. Falling back to fixed center crop (85%).")
        # Fallback: Crop to center 870x870 (approx 85% of 1024)
        # This removes the typical DALL-E border
        crop_size = 870
        left = (width - crop_size) // 2
        top = (height - crop_size) // 2
        right = left + crop_size
        bottom = top + crop_size
        print(f"Fallback bounds: Left={left}, Top={top}, Right={right}, Bottom={bottom}")
    else:
        # Add a small padding to the detected bounds to be safe?
        # Or maybe tighten it? 
        # Usually we want to tighten it to remove the rounded corners background
        # Let's trust the detection or maybe zoom in 5% more
        pass
    
    # Calculate width/height of content
    w = right - left
    h = bottom - top
    
    print(f"Detected content width: {w}, height: {h}")
    
    # DALL-E icons are usually centered and square.
    # Vertical detection often fails due to shadows/reflections at the bottom.
    # Horizontal detection is usually more reliable.
    # We will use the detected width to determine the crop size, 
    # but force the crop to be centered on the image.
    
    # Use the detected width as the crop size
    # But ensure we don't go beyond the image bounds
    crop_size = min(w, height)
    
    # If detection was weird (e.g. very small or full width), fallback to safe default
    if crop_size < 200 or crop_size > 950:
        print("⚠️ Detected size seems invalid. Using safe default (850px).")
        crop_size = 850
    else:
        # Add a small buffer? No, user wants to remove boundary.
        # Actually, if we detected the exact edge of the rounded rect, 
        # we might want to zoom in slightly (shrink crop) to ensure no background leaks in corners.
        # Or just use the detected width.
        pass

    print(f"Using crop size: {crop_size}x{crop_size}")
    
    # Center the crop on the original image
    img_center_x = width // 2
    img_center_y = height // 2
    
    half_size = crop_size // 2
    
    crop_box = (
        img_center_x - half_size,
        img_center_y - half_size,
        img_center_x + half_size,
        img_center_y + half_size
    )
    
    print(f"Final centered crop box: {crop_box}")
    
    # Crop
    cropped = img.crop(crop_box)
    
    # Resize to 1024x1024
    final = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # Save
    if not os.path.exists(dest_dir):
        os.makedirs(dest_dir)
        
    final.save(os.path.join(dest_dir, "AppIcon-1024.png"))
    final.save(os.path.join(dest_dir, "AppIcon-1024-dark.png"))
    final.convert("L").save(os.path.join(dest_dir, "AppIcon-1024-tinted.png"))
    
    print("✓ Saved processed icons")

if __name__ == "__main__":
    smart_process_icon()
