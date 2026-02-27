#!/usr/bin/env python3
"""
Generate First 5 Guide Avatars
Quick test script for initial avatar generation
"""

import json
import requests
import base64
import time
from pathlib import Path

API_URL = "http://localhost:7860/sdapi/v1/txt2img"
OUTPUT_DIR = Path("assets/guides/avatars")

def load_prompts():
    """Load the first 5 prompts from JSON"""
    with open('prompts_for_tools.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data['config'], data['negative_prompt'], data['prompts'][:5]

def check_api():
    """Check if SD WebUI API is available"""
    try:
        response = requests.get("http://localhost:7860/", timeout=5)
        return response.status_code == 200
    except:
        return False

def generate_image(prompt_data, config, negative_prompt):
    """Generate a single image"""
    payload = {
        "prompt": prompt_data['prompt'],
        "negative_prompt": negative_prompt,
        "steps": config['steps'],
        "cfg_scale": config['cfg_scale'],
        "width": config['width'],
        "height": config['height'],
        "sampler_name": config['sampler'],
        "batch_size": 1,
        "n_iter": 1,
    }

    response = requests.post(API_URL, json=payload, timeout=120)
    response.raise_for_status()

    result = response.json()
    return result['images'][0]

def save_image(base64_image, filename):
    """Decode and save base64 image"""
    image_data = base64.b64decode(base64_image)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    filepath = OUTPUT_DIR / filename
    with open(filepath, 'wb') as f:
        f.write(image_data)

    return filepath

def main():
    """Generate first 5 avatars"""
    print("\n" + "=" * 60)
    print("  Generating First 5 Guide Avatars")
    print("=" * 60 + "\n")

    # Check API
    print("Checking Stable Diffusion API...")
    if not check_api():
        print("❌ ERROR: Stable Diffusion WebUI is not running!")
        print("\nPlease start it with:")
        print("  docker compose up -d")
        print("\nThen wait for it to be ready (check: http://localhost:7860)")
        return 1

    print("✓ API is accessible\n")

    # Load prompts
    print("Loading prompts...")
    config, negative_prompt, prompts = load_prompts()
    print(f"✓ Loaded {len(prompts)} prompts\n")

    # Generate images
    print("Starting generation...\n")
    success_count = 0
    failed = []

    for i, prompt_data in enumerate(prompts, 1):
        print(f"[{i}/5] Generating: {prompt_data['guide_name']} - {prompt_data['style_name']}")
        print(f"    File: {prompt_data['filename']}")

        try:
            # Generate
            base64_img = generate_image(prompt_data, config, negative_prompt)

            # Save
            filepath = save_image(base64_img, prompt_data['filename'])

            print(f"    ✓ Saved to: {filepath}")
            success_count += 1

            # Delay between requests
            if i < len(prompts):
                time.sleep(2.5)

        except Exception as e:
            print(f"    ❌ Failed: {str(e)}")
            failed.append({
                'guide': prompt_data['guide_name'],
                'style': prompt_data['style_name'],
                'error': str(e)
            })

    # Summary
    print("\n" + "=" * 60)
    print("  Generation Complete!")
    print("=" * 60 + "\n")

    print(f"Success: {success_count}/5")
    print(f"Failed:  {len(failed)}/5")

    if failed:
        print("\nFailed generations:")
        for fail in failed:
            print(f"  - {fail['guide']} ({fail['style']}): {fail['error']}")

    print(f"\nImages saved to: {OUTPUT_DIR.absolute()}")

    return 0 if len(failed) == 0 else 1

if __name__ == "__main__":
    exit(main())
