#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate Placeholder Avatars for Missing Guide Characters

This script creates simple placeholder avatar images for guides that don't have
custom artwork yet. Each placeholder uses the guide's primary color and initial.
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

REPO_ROOT = Path(__file__).parent
AVATARS_DIR = REPO_ROOT / "assets" / "guides" / "avatars"
IMAGE_SIZE = (512, 512)

# Guide data with colors and names
GUIDES = [
    {"id": "luna-vacia", "name": "Luna-Vacía", "color": "#4A148C"},
    {"id": "helioforja", "name": "Helioforja", "color": "#8B2500"},
    {"id": "leona-nova", "name": "Leona-Nova", "color": "#B8860B"},
    {"id": "chispa-azul", "name": "Chispa-Azul", "color": "#1E88E5"},
    {"id": "gloria-sincro", "name": "Gloria-Sincro", "color": "#FFD700"},
    {"id": "pacha-nexo", "name": "Pacha-Nexo", "color": "#2E7D32"},
    {"id": "gea-metrica", "name": "Gea-Métrica", "color": "#388E3C"},
    {"id": "selene-fase", "name": "Selene-Fase", "color": "#B0BEC5"},
    {"id": "viento-estacion", "name": "Viento-Estación", "color": "#0288D1"},
    {"id": "atlas-orbital", "name": "Atlas-Orbital", "color": "#37474F"},
    {"id": "erebo-logica", "name": "Érebo-Lógica", "color": "#455A64"},
    {"id": "anima-suave", "name": "Ánima-Suave", "color": "#F8BBD9"},
    {"id": "morfeo-astral", "name": "Morfeo-Astral", "color": "#7E57C2"},
    {"id": "shiva-fluido", "name": "Shiva-Fluido", "color": "#5E35B1"},
    {"id": "loki-error", "name": "Loki-Error", "color": "#FF8F00"},
    {"id": "eris-nucleo", "name": "Eris-Núcleo", "color": "#C2185B"},
    {"id": "anubis-vinculo", "name": "Anubis-Vínculo", "color": "#212121"},
    {"id": "zenit-cero", "name": "Zenit-Cero", "color": "#0277BD"},
    {"id": "oceano-bit", "name": "Océano-Bit", "color": "#00838F"},
]


def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))


def get_text_color(bg_color):
    """Determine if text should be white or black based on background luminance"""
    r, g, b = bg_color
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return (255, 255, 255) if luminance < 0.5 else (0, 0, 0)


def create_placeholder_avatar(guide_id, name, color_hex, output_path):
    """
    Create a simple placeholder avatar with colored background and initial

    Args:
        guide_id: Guide identifier (e.g., 'luna-vacia')
        name: Guide name (e.g., 'Luna-Vacía')
        color_hex: Primary color in hex format (e.g., '#4A148C')
        output_path: Path where to save the image
    """
    # Create image with colored background
    bg_color = hex_to_rgb(color_hex)
    img = Image.new('RGB', IMAGE_SIZE, bg_color)
    draw = ImageDraw.Draw(img)

    # Get initial letter
    initial = name[0].upper()

    # Determine text color
    text_color = get_text_color(bg_color)

    # Try to use a nice font, fallback to default if not available
    font_size = 280
    try:
        # Try common font locations
        font_paths = [
            "C:\\Windows\\Fonts\\arial.ttf",
            "C:\\Windows\\Fonts\\segoeui.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
        ]
        font = None
        for font_path in font_paths:
            if Path(font_path).exists():
                font = ImageFont.truetype(font_path, font_size)
                break
        if font is None:
            font = ImageFont.load_default()
    except Exception:
        font = ImageFont.load_default()

    # Draw initial in center
    bbox = draw.textbbox((0, 0), initial, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    x = (IMAGE_SIZE[0] - text_width) // 2 - bbox[0]
    y = (IMAGE_SIZE[1] - text_height) // 2 - bbox[1]

    draw.text((x, y), initial, font=font, fill=text_color)

    # Add subtle gradient effect with circle
    circle_color = (*bg_color[:3], int(255 * 0.15))
    circle_img = Image.new('RGBA', IMAGE_SIZE, (0, 0, 0, 0))
    circle_draw = ImageDraw.Draw(circle_img)

    # Draw outer circle (darker)
    margin = 40
    circle_draw.ellipse([margin, margin, IMAGE_SIZE[0] - margin, IMAGE_SIZE[1] - margin],
                        outline=(*text_color, 60), width=3)

    # Composite the circle onto the main image
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, circle_img)
    img = img.convert('RGB')

    # Save
    img.save(output_path, 'PNG', optimize=True)

    return output_path


def generate_all_placeholders(force=False):
    """
    Generate placeholder avatars for all missing guides

    Args:
        force: If True, overwrite existing files
    """
    if not AVATARS_DIR.exists():
        print(f"✗ Error: Avatars directory not found: {AVATARS_DIR}")
        return False

    print("=" * 80)
    print("GENERATE PLACEHOLDER AVATARS")
    print("=" * 80)
    print(f"Directory: {AVATARS_DIR}")
    print(f"Total guides: {len(GUIDES)}")
    print(f"Force overwrite: {force}")
    print("=" * 80)
    print()

    created = 0
    skipped = 0
    errors = 0

    for guide in GUIDES:
        guide_id = guide['id']
        name = guide['name']
        color = guide['color']
        output_path = AVATARS_DIR / f"{guide_id}.png"

        # Skip if file exists and not forcing
        if output_path.exists() and not force:
            print(f"⊙ {guide_id}.png: Already exists, skipping")
            skipped += 1
            continue

        try:
            create_placeholder_avatar(guide_id, name, color, output_path)
            size_kb = output_path.stat().st_size / 1024
            print(f"✓ {guide_id}.png: Created ({IMAGE_SIZE[0]}x{IMAGE_SIZE[1]}, {size_kb:.1f} KB)")
            created += 1
        except Exception as e:
            print(f"✗ {guide_id}.png: Error - {str(e)}")
            errors += 1

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total guides: {len(GUIDES)}")
    print(f"Created: {created}")
    print(f"Skipped: {skipped}")
    print(f"Errors: {errors}")
    print("=" * 80)

    if errors == 0:
        print("\n✅ All placeholder avatars generated successfully!")
        return True
    else:
        print(f"\n⚠️ {errors} error(s) occurred")
        return False


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Generate placeholder avatars for missing guide characters'
    )
    parser.add_argument(
        '--force',
        action='store_true',
        help='Overwrite existing avatar files'
    )

    args = parser.parse_args()

    try:
        success = generate_all_placeholders(force=args.force)
        return 0 if success else 1
    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        return 2


if __name__ == "__main__":
    exit(main())
