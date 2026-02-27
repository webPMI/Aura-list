#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Resize Avatar Images

This script resizes avatar images to the standard 512x512 size.
Useful for converting existing 1024x1024 images or other sizes.
"""

import sys
from pathlib import Path
from PIL import Image

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

REPO_ROOT = Path(__file__).parent
AVATARS_DIR = REPO_ROOT / "assets" / "guides" / "avatars"
TARGET_SIZE = (512, 512)


def resize_image(image_path: Path, target_size: tuple = TARGET_SIZE, backup: bool = True):
    """
    Resize an image to the target size

    Args:
        image_path: Path to the image file
        target_size: Tuple of (width, height)
        backup: If True, create a backup of the original
    """
    try:
        # Open image
        with Image.open(image_path) as img:
            original_size = img.size

            # Check if already correct size
            if original_size == target_size:
                print(f"⊙ {image_path.name}: Already {target_size[0]}x{target_size[1]}, skipping")
                return True

            # Create backup if requested
            if backup:
                backup_path = image_path.with_suffix('.png.backup')
                if not backup_path.exists():
                    img.save(backup_path, 'PNG')
                    print(f"  ✓ Backup created: {backup_path.name}")

            # Resize using high-quality Lanczos resampling
            resized = img.resize(target_size, Image.Resampling.LANCZOS)

            # Save resized image
            resized.save(image_path, 'PNG', optimize=True)

            # Get new file size
            new_size_kb = image_path.stat().st_size / 1024

            print(f"✓ {image_path.name}: {original_size[0]}x{original_size[1]} → {target_size[0]}x{target_size[1]} ({new_size_kb:.1f} KB)")
            return True

    except Exception as e:
        print(f"✗ {image_path.name}: Error - {str(e)}")
        return False


def resize_all_avatars(dry_run: bool = False, backup: bool = True):
    """
    Resize all avatar images in the avatars directory

    Args:
        dry_run: If True, only show what would be done
        backup: If True, create backups before resizing
    """
    if not AVATARS_DIR.exists():
        print(f"✗ Error: Avatars directory not found: {AVATARS_DIR}")
        return False

    png_files = list(AVATARS_DIR.glob("*.png"))
    # Exclude backup files
    png_files = [f for f in png_files if not f.name.endswith('.backup')]

    if not png_files:
        print("No PNG files found in avatars directory")
        return True

    print("=" * 80)
    print(f"RESIZE AVATAR IMAGES TO {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")
    print("=" * 80)
    print(f"Directory: {AVATARS_DIR}")
    print(f"Images found: {len(png_files)}")
    print(f"Backup enabled: {backup}")
    print(f"Dry run: {dry_run}")
    print("=" * 80)
    print()

    if dry_run:
        print("DRY RUN MODE - No changes will be made")
        print()

    success_count = 0
    error_count = 0
    skip_count = 0

    for image_path in sorted(png_files):
        try:
            with Image.open(image_path) as img:
                original_size = img.size

                if original_size == TARGET_SIZE:
                    print(f"⊙ {image_path.name}: Already {TARGET_SIZE[0]}x{TARGET_SIZE[1]}, skipping")
                    skip_count += 1
                    continue

                if dry_run:
                    size_kb = image_path.stat().st_size / 1024
                    print(f"Would resize: {image_path.name} ({original_size[0]}x{original_size[1]}, {size_kb:.1f} KB)")
                    success_count += 1
                else:
                    if resize_image(image_path, TARGET_SIZE, backup):
                        success_count += 1
                    else:
                        error_count += 1

        except Exception as e:
            print(f"✗ {image_path.name}: Error reading - {str(e)}")
            error_count += 1

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total images: {len(png_files)}")
    print(f"Resized: {success_count}")
    print(f"Skipped: {skip_count}")
    print(f"Errors: {error_count}")
    print("=" * 80)

    return error_count == 0


def resize_specific_images(filenames: list, dry_run: bool = False, backup: bool = True):
    """
    Resize specific avatar images

    Args:
        filenames: List of filenames to resize
        dry_run: If True, only show what would be done
        backup: If True, create backups before resizing
    """
    print("=" * 80)
    print(f"RESIZE SPECIFIC IMAGES TO {TARGET_SIZE[0]}x{TARGET_SIZE[1]}")
    print("=" * 80)
    print(f"Images to process: {len(filenames)}")
    print("=" * 80)
    print()

    success_count = 0
    error_count = 0

    for filename in filenames:
        image_path = AVATARS_DIR / filename

        if not image_path.exists():
            print(f"✗ {filename}: File not found")
            error_count += 1
            continue

        if dry_run:
            try:
                with Image.open(image_path) as img:
                    size = img.size
                    size_kb = image_path.stat().st_size / 1024
                    print(f"Would resize: {filename} ({size[0]}x{size[1]}, {size_kb:.1f} KB)")
                    success_count += 1
            except Exception as e:
                print(f"✗ {filename}: Error - {str(e)}")
                error_count += 1
        else:
            if resize_image(image_path, TARGET_SIZE, backup):
                success_count += 1
            else:
                error_count += 1

    print()
    print("=" * 80)
    print(f"Resized: {success_count}")
    print(f"Errors: {error_count}")
    print("=" * 80)

    return error_count == 0


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='Resize avatar images to standard 512x512 size'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be done without making changes'
    )
    parser.add_argument(
        '--no-backup',
        action='store_true',
        help='Do not create backup files'
    )
    parser.add_argument(
        '--files',
        nargs='+',
        help='Specific files to resize (e.g., aethel.png crono-velo.png)'
    )
    parser.add_argument(
        '--size',
        type=int,
        nargs=2,
        metavar=('WIDTH', 'HEIGHT'),
        help='Custom target size (default: 512 512)'
    )

    args = parser.parse_args()

    # Update target size if specified
    if args.size:
        global TARGET_SIZE
        TARGET_SIZE = tuple(args.size)

    backup = not args.no_backup

    try:
        if args.files:
            # Resize specific files
            success = resize_specific_images(args.files, args.dry_run, backup)
        else:
            # Resize all files
            success = resize_all_avatars(args.dry_run, backup)

        if args.dry_run:
            print("\nDry run completed. Run without --dry-run to apply changes.")
            return 0

        if success:
            print("\n✅ All operations completed successfully!")
            print("\nNext step: Run python verify_avatars.py to verify changes")
            return 0
        else:
            print("\n⚠️ Some operations failed. Check the output above.")
            return 1

    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        return 2


if __name__ == "__main__":
    exit(main())
