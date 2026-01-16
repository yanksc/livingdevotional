#!/usr/bin/env python3
"""
Generate app icon for Living Devotional app
Creates icons with cross and book design elements
"""

from PIL import Image, ImageDraw, ImageFont
import os
import sys

# App color scheme (from AppTheme.swift)
WARM_SAND = (212, 165, 116)  # #D4A574
SOFT_BEIGE = (232, 213, 183)  # #E8D5B7
SAGE_GREEN = (168, 197, 184)  # #A8C5B8
WARM_CREAM = (250, 247, 242)  # #FAF7F2

# Dark mode colors
DARK_BG = (30, 30, 35)
DARK_SAND = (180, 140, 100)
DARK_BEIGE = (200, 180, 150)

SIZE = 1024
PADDING = 80

def draw_cross(draw, center_x, center_y, size, color, width=None):
    """Draw a cross centered at the given coordinates"""
    if width is None:
        width = size // 6
    
    # Vertical bar
    draw.rectangle(
        [center_x - width // 2, center_y - size // 2,
         center_x + width // 2, center_y + size // 2],
        fill=color
    )
    # Horizontal bar
    draw.rectangle(
        [center_x - size // 2, center_y - width // 2,
         center_x + size // 2, center_y + width // 2],
        fill=color
    )

def draw_book(draw, x, y, width, height, color, highlight_color):
    """Draw an open book"""
    # Book cover (left page)
    draw.rectangle(
        [x, y, x + width // 2, y + height],
        fill=color,
        outline=(0, 0, 0, 0),
        width=0
    )
    
    # Book cover (right page)
    draw.rectangle(
        [x + width // 2, y, x + width, y + height],
        fill=highlight_color,
        outline=(0, 0, 0, 0),
        width=0
    )
    
    # Book spine (center line)
    draw.line(
        [x + width // 2, y, x + width // 2, y + height],
        fill=(color[0] - 30, color[1] - 30, color[2] - 30),
        width=max(2, width // 40)
    )
    
    # Book pages (lines)
    line_spacing = height // 8
    for i in range(1, 8):
        line_y = y + i * line_spacing
        # Left page lines
        draw.line(
            [x + 10, line_y, x + width // 2 - 10, line_y],
            fill=(color[0] - 20, color[1] - 20, color[2] - 20),
            width=1
        )
        # Right page lines
        draw.line(
            [x + width // 2 + 10, line_y, x + width - 10, line_y],
            fill=(highlight_color[0] - 20, highlight_color[1] - 20, highlight_color[2] - 20),
            width=1
        )
    
    # Add some depth/shadow
    draw.rectangle(
        [x, y + height - 5, x + width, y + height],
        fill=(0, 0, 0, 30)
    )

def create_base_icon():
    """Create the base app icon (light mode)"""
    # Create image with gradient-like background
    img = Image.new('RGB', (SIZE, SIZE), WARM_CREAM)
    draw = ImageDraw.Draw(img)
    
    # Draw gradient background
    for i in range(SIZE):
        ratio = i / SIZE
        r = int(WARM_CREAM[0] * (1 - ratio * 0.1) + SOFT_BEIGE[0] * ratio * 0.1)
        g = int(WARM_CREAM[1] * (1 - ratio * 0.1) + SOFT_BEIGE[1] * ratio * 0.1)
        b = int(WARM_CREAM[2] * (1 - ratio * 0.1) + SOFT_BEIGE[2] * ratio * 0.1)
        draw.rectangle([0, i, SIZE, i + 1], fill=(r, g, b))
    
    # Draw book (positioned slightly left and down)
    book_x = SIZE // 2 - 180
    book_y = SIZE // 2 + 40
    book_width = 360
    book_height = 280
    draw_book(draw, book_x, book_y, book_width, book_height, WARM_SAND, SOFT_BEIGE)
    
    # Draw cross (positioned on top of book, slightly to the right)
    cross_x = SIZE // 2 + 60
    cross_y = SIZE // 2 - 20
    cross_size = 200
    draw_cross(draw, cross_x, cross_y, cross_size, SAGE_GREEN, width=28)
    
    # Add a subtle glow/shadow effect around cross
    for offset in range(5, 0, -1):
        alpha = int(30 * (1 - offset / 5))
        glow_color = (*SAGE_GREEN[:3], alpha)
        draw_cross(draw, cross_x, cross_y, cross_size + offset * 2, 
                  (SAGE_GREEN[0], SAGE_GREEN[1], SAGE_GREEN[2]), width=28 + offset)
    
    # Redraw cross on top
    draw_cross(draw, cross_x, cross_y, cross_size, SAGE_GREEN, width=28)
    
    return img

def create_dark_icon():
    """Create the dark mode app icon"""
    img = Image.new('RGB', (SIZE, SIZE), DARK_BG)
    draw = ImageDraw.Draw(img)
    
    # Draw subtle gradient background
    for i in range(SIZE):
        ratio = i / SIZE
        r = int(DARK_BG[0] * (1 - ratio * 0.15) + (DARK_BG[0] + 10) * ratio * 0.15)
        g = int(DARK_BG[1] * (1 - ratio * 0.15) + (DARK_BG[1] + 10) * ratio * 0.15)
        b = int(DARK_BG[2] * (1 - ratio * 0.15) + (DARK_BG[2] + 15) * ratio * 0.15)
        draw.rectangle([0, i, SIZE, i + 1], fill=(r, g, b))
    
    # Draw book with darker colors
    book_x = SIZE // 2 - 180
    book_y = SIZE // 2 + 40
    book_width = 360
    book_height = 280
    draw_book(draw, book_x, book_y, book_width, book_height, DARK_SAND, DARK_BEIGE)
    
    # Draw cross with lighter sage green for visibility
    cross_x = SIZE // 2 + 60
    cross_y = SIZE // 2 - 20
    cross_size = 200
    light_sage = (min(255, SAGE_GREEN[0] + 40), 
                  min(255, SAGE_GREEN[1] + 40), 
                  min(255, SAGE_GREEN[2] + 40))
    draw_cross(draw, cross_x, cross_y, cross_size, light_sage, width=28)
    
    # Add glow effect
    for offset in range(5, 0, -1):
        draw_cross(draw, cross_x, cross_y, cross_size + offset * 2, 
                  light_sage, width=28 + offset)
    
    # Redraw cross on top
    draw_cross(draw, cross_x, cross_y, cross_size, light_sage, width=28)
    
    return img

def create_tinted_icon():
    """Create the tinted app icon (for iOS tinted appearance)"""
    # Tinted icons typically use a monochrome design that iOS tints
    img = Image.new('RGB', (SIZE, SIZE), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Use a light gray that will be tinted by iOS
    tint_color = (180, 180, 180)
    book_color = (200, 200, 200)
    
    # Draw book
    book_x = SIZE // 2 - 180
    book_y = SIZE // 2 + 40
    book_width = 360
    book_height = 280
    draw_book(draw, book_x, book_y, book_width, book_height, book_color, (220, 220, 220))
    
    # Draw cross
    cross_x = SIZE // 2 + 60
    cross_y = SIZE // 2 - 20
    cross_size = 200
    draw_cross(draw, cross_x, cross_y, cross_size, tint_color, width=28)
    
    return img

def main():
    """Generate all app icon variants"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    icon_dir = os.path.join(project_root, 'livingdevotional', 'Assets.xcassets', 'AppIcon.appiconset')
    
    if not os.path.exists(icon_dir):
        print(f"Error: Icon directory not found at {icon_dir}")
        sys.exit(1)
    
    print("Generating app icons...")
    
    # Generate base icon
    base_icon = create_base_icon()
    base_path = os.path.join(icon_dir, 'AppIcon-1024.png')
    base_icon.save(base_path, 'PNG')
    print(f"✓ Created base icon: {base_path}")
    
    # Generate dark mode icon
    dark_icon = create_dark_icon()
    dark_path = os.path.join(icon_dir, 'AppIcon-1024-dark.png')
    dark_icon.save(dark_path, 'PNG')
    print(f"✓ Created dark icon: {dark_path}")
    
    # Generate tinted icon
    tinted_icon = create_tinted_icon()
    tinted_path = os.path.join(icon_dir, 'AppIcon-1024-tinted.png')
    tinted_icon.save(tinted_path, 'PNG')
    print(f"✓ Created tinted icon: {tinted_path}")
    
    # Update Contents.json
    update_contents_json(icon_dir)
    
    print("\n✓ All icons generated successfully!")
    print("\nNext steps:")
    print("1. Open Xcode")
    print("2. Navigate to Assets.xcassets > AppIcon")
    print("3. Drag the generated icons to their respective slots:")
    print("   - AppIcon-1024.png → Universal iOS 1024x1024")
    print("   - AppIcon-1024-dark.png → Dark Appearance")
    print("   - AppIcon-1024-tinted.png → Tinted Appearance")

def update_contents_json(icon_dir):
    """Update Contents.json to reference the generated icons"""
    contents_path = os.path.join(icon_dir, 'Contents.json')
    
    import json
    with open(contents_path, 'r') as f:
        contents = json.load(f)
    
    # Update image filenames
    contents['images'][0]['filename'] = 'AppIcon-1024.png'
    contents['images'][1]['filename'] = 'AppIcon-1024-dark.png'
    contents['images'][2]['filename'] = 'AppIcon-1024-tinted.png'
    
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"✓ Updated Contents.json")

if __name__ == '__main__':
    main()
