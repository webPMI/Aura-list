#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Avatar Generation Verification Script

This script verifies that all avatar images have been generated correctly
for the AuraList guides system.

Requirements:
- All images should be 512x512 PNG format
- File sizes should be reasonable (50KB - 2MB)
- All guides from guide_prompts.json should have corresponding images
"""

import json
import os
import sys
from pathlib import Path
from PIL import Image
from typing import Dict, List, Tuple
from datetime import datetime

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Configuration
REPO_ROOT = Path(__file__).parent
AVATARS_DIR = REPO_ROOT / "assets" / "guides" / "avatars"
PROMPTS_FILE = REPO_ROOT / "guide_prompts.json"
REPORT_FILE = REPO_ROOT / "AVATAR_GENERATION_REPORT.md"

EXPECTED_WIDTH = 512
EXPECTED_HEIGHT = 512
MIN_FILE_SIZE = 50 * 1024  # 50 KB
MAX_FILE_SIZE = 2 * 1024 * 1024  # 2 MB

# Existing manually created avatars
EXISTING_AVATARS = ["aethel.png", "crono-velo.png"]


class AvatarVerifier:
    def __init__(self):
        self.guide_ids: List[str] = []
        self.found_images: Dict[str, dict] = {}
        self.missing_images: List[str] = []
        self.invalid_images: Dict[str, List[str]] = {}

    def load_guide_prompts(self) -> bool:
        """Load guide IDs from guide_prompts.json"""
        try:
            with open(PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                self.guide_ids = [guide['id'] for guide in data.get('guides', [])]
                print(f"✓ Loaded {len(self.guide_ids)} guide IDs from guide_prompts.json")
                return True
        except FileNotFoundError:
            print(f"✗ Error: {PROMPTS_FILE} not found")
            return False
        except json.JSONDecodeError as e:
            print(f"✗ Error parsing JSON: {e}")
            return False

    def verify_avatars_directory(self) -> bool:
        """Check if avatars directory exists"""
        if not AVATARS_DIR.exists():
            print(f"✗ Error: Avatars directory not found: {AVATARS_DIR}")
            return False
        print(f"✓ Avatars directory exists: {AVATARS_DIR}")
        return True

    def scan_avatar_images(self) -> None:
        """Scan all PNG files in avatars directory"""
        png_files = list(AVATARS_DIR.glob("*.png"))
        print(f"\n{'='*60}")
        print(f"Found {len(png_files)} PNG files in avatars directory")
        print(f"{'='*60}\n")

        for png_file in png_files:
            filename = png_file.name
            guide_id = png_file.stem

            issues = []

            # Check file size
            file_size = png_file.stat().st_size
            if file_size < MIN_FILE_SIZE:
                issues.append(f"File too small: {file_size:,} bytes (min: {MIN_FILE_SIZE:,})")
            elif file_size > MAX_FILE_SIZE:
                issues.append(f"File too large: {file_size:,} bytes (max: {MAX_FILE_SIZE:,})")

            # Check image dimensions
            try:
                with Image.open(png_file) as img:
                    width, height = img.size
                    if width != EXPECTED_WIDTH or height != EXPECTED_HEIGHT:
                        issues.append(f"Incorrect dimensions: {width}x{height} (expected: {EXPECTED_WIDTH}x{EXPECTED_HEIGHT})")

                    # Store image info
                    self.found_images[guide_id] = {
                        'filename': filename,
                        'path': str(png_file),
                        'size': file_size,
                        'dimensions': f"{width}x{height}",
                        'format': img.format,
                        'mode': img.mode,
                        'issues': issues
                    }

                    if issues:
                        self.invalid_images[guide_id] = issues
                        print(f"⚠ {filename}: {', '.join(issues)}")
                    else:
                        print(f"✓ {filename}: {width}x{height}, {file_size:,} bytes")

            except Exception as e:
                issues.append(f"Failed to read image: {str(e)}")
                self.invalid_images[guide_id] = issues
                print(f"✗ {filename}: {str(e)}")

    def check_missing_images(self) -> None:
        """Check which guides are missing avatar images"""
        print(f"\n{'='*60}")
        print("Checking for missing avatars")
        print(f"{'='*60}\n")

        # Add existing avatars to found images if not already scanned
        for existing in EXISTING_AVATARS:
            guide_id = Path(existing).stem
            if guide_id not in self.found_images:
                avatar_path = AVATARS_DIR / existing
                if avatar_path.exists():
                    print(f"ℹ Including existing avatar: {existing}")

        for guide_id in self.guide_ids:
            if guide_id not in self.found_images:
                self.missing_images.append(guide_id)
                print(f"✗ Missing: {guide_id}.png")

        if not self.missing_images:
            print("✓ All guide avatars are present!")

    def generate_report(self) -> None:
        """Generate markdown report"""
        total_guides = len(self.guide_ids)
        total_found = len(self.found_images)
        total_missing = len(self.missing_images)
        total_invalid = len(self.invalid_images)
        total_valid = total_found - total_invalid

        report_lines = [
            "# Avatar Generation Verification Report",
            "",
            f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            "",
            "## Summary",
            "",
            f"- **Total Guides:** {total_guides}",
            f"- **Images Found:** {total_found}",
            f"- **Valid Images:** {total_valid}",
            f"- **Invalid Images:** {total_invalid}",
            f"- **Missing Images:** {total_missing}",
            "",
        ]

        # Overall status
        if total_missing == 0 and total_invalid == 0:
            report_lines.append("### ✅ Status: ALL AVATARS VERIFIED")
            report_lines.append("")
            report_lines.append("All guide avatars have been successfully generated and verified!")
        elif total_missing > 0:
            report_lines.append(f"### ⚠️ Status: {total_missing} IMAGES MISSING")
        else:
            report_lines.append(f"### ⚠️ Status: {total_invalid} INVALID IMAGES")

        report_lines.append("")

        # Valid images section
        if total_valid > 0:
            report_lines.extend([
                "## ✅ Valid Images",
                "",
                f"{total_valid} images passed all verification checks:",
                "",
                "| Guide ID | Filename | Dimensions | File Size |",
                "|----------|----------|------------|-----------|"
            ])

            for guide_id, info in sorted(self.found_images.items()):
                if not info['issues']:
                    size_kb = info['size'] / 1024
                    report_lines.append(
                        f"| `{guide_id}` | {info['filename']} | {info['dimensions']} | {size_kb:.1f} KB |"
                    )

            report_lines.append("")

        # Invalid images section
        if total_invalid > 0:
            report_lines.extend([
                "## ⚠️ Invalid Images",
                "",
                f"{total_invalid} images have issues:",
                ""
            ])

            for guide_id, issues in sorted(self.invalid_images.items()):
                info = self.found_images[guide_id]
                report_lines.append(f"### `{guide_id}` ({info['filename']})")
                for issue in issues:
                    report_lines.append(f"- ❌ {issue}")
                report_lines.append("")

        # Missing images section
        if total_missing > 0:
            report_lines.extend([
                "## ❌ Missing Images",
                "",
                f"{total_missing} guides do not have avatar images:",
                ""
            ])

            for guide_id in sorted(self.missing_images):
                report_lines.append(f"- `{guide_id}.png`")

            report_lines.append("")

        # Image quality metrics
        if total_found > 0:
            sizes = [info['size'] for info in self.found_images.values()]
            avg_size = sum(sizes) / len(sizes)
            min_size = min(sizes)
            max_size = max(sizes)

            report_lines.extend([
                "## 📊 Image Quality Metrics",
                "",
                "### File Size Statistics",
                "",
                f"- **Average:** {avg_size/1024:.1f} KB",
                f"- **Minimum:** {min_size/1024:.1f} KB",
                f"- **Maximum:** {max_size/1024:.1f} KB",
                f"- **Total Storage:** {sum(sizes)/1024/1024:.2f} MB",
                ""
            ])

        # Next steps
        report_lines.extend([
            "## 🎯 Next Steps",
            ""
        ])

        if total_missing == 0 and total_invalid == 0:
            report_lines.extend([
                "✅ **All avatars verified successfully!**",
                "",
                "You can now:",
                "1. Review the generated images visually",
                "2. Commit the avatars to the repository",
                "3. Test the guides UI with the new avatars",
                "4. Deploy the updated app",
                ""
            ])
        else:
            if total_missing > 0:
                report_lines.extend([
                    "### Missing Images",
                    "",
                    "1. Review the missing guide IDs listed above",
                    "2. Generate the missing avatars using the prompts from `guide_prompts.json`",
                    "3. Save them to `assets/guides/avatars/` with the correct guide ID as filename",
                    "4. Re-run this verification script",
                    ""
                ])

            if total_invalid > 0:
                report_lines.extend([
                    "### Invalid Images",
                    "",
                    "1. Review the issues listed above for each invalid image",
                    "2. Regenerate or fix the problematic images",
                    "3. Ensure all images are 512x512 PNG format",
                    "4. Re-run this verification script",
                    ""
                ])

        # Write report
        report_content = "\n".join(report_lines)
        with open(REPORT_FILE, 'w', encoding='utf-8') as f:
            f.write(report_content)

        print(f"\n{'='*60}")
        print(f"✓ Report generated: {REPORT_FILE}")
        print(f"{'='*60}\n")

    def print_summary(self) -> None:
        """Print summary to console"""
        total_guides = len(self.guide_ids)
        total_found = len(self.found_images)
        total_missing = len(self.missing_images)
        total_invalid = len(self.invalid_images)
        total_valid = total_found - total_invalid

        print("\n" + "="*60)
        print("VERIFICATION SUMMARY")
        print("="*60)
        print(f"Total Guides:    {total_guides}")
        print(f"Images Found:    {total_found}")
        print(f"Valid Images:    {total_valid}")
        print(f"Invalid Images:  {total_invalid}")
        print(f"Missing Images:  {total_missing}")
        print("="*60)

        if total_missing == 0 and total_invalid == 0:
            print("✅ ALL AVATARS VERIFIED SUCCESSFULLY!")
        else:
            print("⚠️  ISSUES FOUND - See report for details")
        print("="*60 + "\n")

    def run(self) -> bool:
        """Run full verification process"""
        print("\n" + "="*60)
        print("AVATAR GENERATION VERIFICATION")
        print("="*60 + "\n")

        # Load guide prompts
        if not self.load_guide_prompts():
            return False

        # Verify directory
        if not self.verify_avatars_directory():
            return False

        # Scan images
        self.scan_avatar_images()

        # Check for missing
        self.check_missing_images()

        # Generate report
        self.generate_report()

        # Print summary
        self.print_summary()

        return len(self.missing_images) == 0 and len(self.invalid_images) == 0


def main():
    try:
        verifier = AvatarVerifier()
        success = verifier.run()

        if success:
            print("✅ Verification completed successfully!")
            return 0
        else:
            print("⚠️  Verification completed with issues. Check the report for details.")
            return 1

    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        return 2


if __name__ == "__main__":
    exit(main())
