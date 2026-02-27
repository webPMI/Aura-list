#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
List Avatar Generation Prompts

This helper script extracts and displays the avatar generation prompts
in various formats for easy use with AI image generation tools.
"""

import json
import sys
from pathlib import Path

if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

REPO_ROOT = Path(__file__).parent
PROMPTS_FILE = REPO_ROOT / "guide_prompts.json"


def load_prompts():
    """Load guide prompts from JSON file"""
    with open(PROMPTS_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def print_all_prompts(data):
    """Print all prompts in a readable format"""
    config = data['config']

    print("=" * 80)
    print("AVATAR GENERATION PROMPTS")
    print("=" * 80)
    print()
    print("Base Configuration:")
    print(f"  Size: {config['width']}x{config['height']}")
    print(f"  Steps: {config['steps']}")
    print(f"  CFG Scale: {config['cfg_scale']}")
    print(f"  Sampler: {config['sampler']}")
    print()
    print(f"Base Style: {config['base_style']}")
    print()
    print(f"Negative Prompt: {config['negative_prompt']}")
    print()
    print("=" * 80)
    print()

    for i, guide in enumerate(data['guides'], 1):
        print(f"{i:2d}. {guide['id']}")
        print(f"    Name: {guide['name']}")
        print(f"    File: {guide['id']}.png")
        print(f"    Prompt: {guide['prompt']}")
        print()


def print_batch_csv(data):
    """Print prompts in CSV format for batch generation"""
    print("filename,prompt")
    config = data['config']
    base_style = config['base_style']

    for guide in data['guides']:
        filename = f"{guide['id']}.png"
        full_prompt = f"{guide['prompt']}, {base_style}"
        # Escape quotes for CSV
        full_prompt = full_prompt.replace('"', '""')
        print(f'"{filename}","{full_prompt}"')


def print_batch_json(data):
    """Print prompts in JSON format for batch generation"""
    config = data['config']
    base_style = config['base_style']

    batch = []
    for guide in data['guides']:
        batch.append({
            "filename": f"{guide['id']}.png",
            "prompt": f"{guide['prompt']}, {base_style}",
            "negative_prompt": config['negative_prompt'],
            "width": config['width'],
            "height": config['height'],
            "steps": config['steps'],
            "cfg_scale": config['cfg_scale'],
            "sampler": config['sampler']
        })

    print(json.dumps(batch, indent=2, ensure_ascii=False))


def print_single_prompt(data, guide_id):
    """Print a single prompt for a specific guide"""
    config = data['config']

    guide = next((g for g in data['guides'] if g['id'] == guide_id), None)
    if not guide:
        print(f"Error: Guide '{guide_id}' not found")
        print()
        print("Available guide IDs:")
        for g in data['guides']:
            print(f"  - {g['id']}")
        return

    print(f"Guide: {guide['name']} ({guide['id']})")
    print(f"Filename: {guide['id']}.png")
    print()
    print("Full Prompt:")
    print(f"{guide['prompt']}, {config['base_style']}")
    print()
    print("Negative Prompt:")
    print(config['negative_prompt'])
    print()
    print("Settings:")
    print(f"  Size: {config['width']}x{config['height']}")
    print(f"  Steps: {config['steps']}")
    print(f"  CFG Scale: {config['cfg_scale']}")
    print(f"  Sampler: {config['sampler']}")


def print_missing_prompts(data):
    """Print prompts only for missing avatars"""
    avatars_dir = REPO_ROOT / "assets" / "guides" / "avatars"
    existing_files = {f.stem for f in avatars_dir.glob("*.png")}

    config = data['config']
    missing_guides = [g for g in data['guides'] if g['id'] not in existing_files]

    if not missing_guides:
        print("✓ All avatars exist! No missing prompts.")
        return

    print(f"Missing Avatars: {len(missing_guides)}")
    print("=" * 80)
    print()

    for i, guide in enumerate(missing_guides, 1):
        print(f"{i:2d}. {guide['id']}")
        print(f"    Name: {guide['name']}")
        print(f"    File: {guide['id']}.png")
        print(f"    Full Prompt: {guide['prompt']}, {config['base_style']}")
        print()


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description='List avatar generation prompts in various formats'
    )
    parser.add_argument(
        '--format',
        choices=['text', 'csv', 'json', 'missing'],
        default='text',
        help='Output format (default: text)'
    )
    parser.add_argument(
        '--guide',
        type=str,
        help='Show prompt for specific guide ID only'
    )

    args = parser.parse_args()

    try:
        data = load_prompts()

        if args.guide:
            print_single_prompt(data, args.guide)
        elif args.format == 'csv':
            print_batch_csv(data)
        elif args.format == 'json':
            print_batch_json(data)
        elif args.format == 'missing':
            print_missing_prompts(data)
        else:
            print_all_prompts(data)

    except FileNotFoundError:
        print(f"Error: {PROMPTS_FILE} not found")
        return 1
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 2

    return 0


if __name__ == "__main__":
    exit(main())
