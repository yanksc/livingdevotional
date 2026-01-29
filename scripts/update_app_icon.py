import shutil
import os
from PIL import Image

source_path = "generated_icons/icon_candidate_20260125_004132_3.png"
dest_dir = "livingdevotional/Assets.xcassets/AppIcon.appiconset"

# Ensure source exists
if not os.path.exists(source_path):
    print(f"Error: Source file {source_path} not found.")
    exit(1)

# Ensure destination exists
if not os.path.exists(dest_dir):
    print(f"Error: Destination directory {dest_dir} not found.")
    exit(1)

# Open source image
img = Image.open(source_path)
print(f"Source image size: {img.size}")

# Resize if necessary (though DALL-E is usually 1024x1024)
if img.size != (1024, 1024):
    print("Resizing to 1024x1024...")
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)

# Save as AppIcon-1024.png (Light/Universal)
light_path = os.path.join(dest_dir, "AppIcon-1024.png")
img.save(light_path)
print(f"Saved {light_path}")

# Save as AppIcon-1024-dark.png (Dark)
# Ideally this would be darker, but for now we use the same one
dark_path = os.path.join(dest_dir, "AppIcon-1024-dark.png")
img.save(dark_path)
print(f"Saved {dark_path}")

# Save as AppIcon-1024-tinted.png (Tinted)
# For tinted, we usually need a grayscale mask. 
# Converting to grayscale for now to be slightly more correct than full color, 
# though a proper tinted icon needs manual design.
tinted_img = img.convert("L")
tinted_path = os.path.join(dest_dir, "AppIcon-1024-tinted.png")
tinted_img.save(tinted_path)
print(f"Saved {tinted_path}")

print("App icon updated successfully!")
