#!/usr/bin/env python3
"""
Automated guide avatar generation using Stable Diffusion WebUI API.

This script reads guide prompts from guide_prompts.json and generates
512x512 PNG avatar images for each guide using the SD WebUI API.

Requirements:
- Stable Diffusion WebUI running at http://localhost:7860
- requests library: pip install requests

Usage:
    python generate_avatars.py
"""

import json
import base64
import time
import requests
from pathlib import Path
from typing import Dict, List, Tuple


# Configuration
API_URL = "http://localhost:7860/sdapi/v1/txt2img"
PROMPTS_FILE = Path(__file__).parent / "guide_prompts.json"
OUTPUT_DIR = Path(__file__).parent / "assets" / "guides" / "avatars"
DELAY_BETWEEN_REQUESTS = 2.5  # seconds


class AvatarGenerator:
    """Handles avatar generation using Stable Diffusion WebUI API."""

    def __init__(self):
        self.config = {}
        self.guides = []
        self.results = {
            'success': [],
            'failed': [],
            'total': 0,
            'start_time': None,
            'end_time': None
        }

    def load_prompts(self) -> bool:
        """Load guide prompts from JSON file."""
        try:
            print(f"Loading prompts from: {PROMPTS_FILE}")
            with open(PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)

            self.config = data['config']
            self.guides = data['guides']
            self.results['total'] = len(self.guides)

            print(f"✓ Loaded {len(self.guides)} guide prompts")
            print(f"✓ Base style: {self.config['base_style'][:50]}...")
            return True

        except FileNotFoundError:
            print(f"✗ Error: {PROMPTS_FILE} not found!")
            return False
        except json.JSONDecodeError as e:
            print(f"✗ Error: Invalid JSON format - {e}")
            return False
        except Exception as e:
            print(f"✗ Error loading prompts: {e}")
            return False

    def check_api_connection(self) -> bool:
        """Verify SD WebUI API is accessible."""
        try:
            print(f"\nChecking API connection to {API_URL}...")
            # Try to ping the API endpoint
            response = requests.get("http://localhost:7860/sdapi/v1/sd-models", timeout=5)
            if response.status_code == 200:
                print("✓ API connection successful")
                return True
            else:
                print(f"✗ API returned status code: {response.status_code}")
                return False
        except requests.exceptions.ConnectionError:
            print("✗ Cannot connect to API. Is Stable Diffusion WebUI running?")
            print("  Start it with: webui.bat --api")
            return False
        except Exception as e:
            print(f"✗ Error checking API: {e}")
            return False

    def construct_payload(self, guide: Dict) -> Dict:
        """Construct API request payload for a guide."""
        # Combine guide prompt with base style
        full_prompt = f"{guide['prompt']}, {self.config['base_style']}"

        payload = {
            "prompt": full_prompt,
            "negative_prompt": self.config['negative_prompt'],
            "steps": self.config['steps'],
            "cfg_scale": self.config['cfg_scale'],
            "width": self.config['width'],
            "height": self.config['height'],
            "sampler_name": self.config['sampler'],
            "save_images": False,  # We'll save manually
            "send_images": True,
            "alwayson_scripts": {}
        }

        return payload

    def generate_image(self, guide: Dict, index: int) -> Tuple[bool, str]:
        """
        Generate a single avatar image.

        Returns:
            Tuple of (success: bool, message: str)
        """
        guide_id = guide['id']
        guide_name = guide['name']

        print(f"\n[{index + 1}/{self.results['total']}] Generating: {guide_name}")
        print(f"  ID: {guide_id}")

        try:
            # Construct request payload
            payload = self.construct_payload(guide)

            # Send API request
            print(f"  → Sending request to API...")
            response = requests.post(API_URL, json=payload, timeout=120)

            if response.status_code != 200:
                error_msg = f"API returned status {response.status_code}"
                print(f"  ✗ {error_msg}")
                return False, error_msg

            # Parse response
            result = response.json()

            if 'images' not in result or len(result['images']) == 0:
                error_msg = "No images in API response"
                print(f"  ✗ {error_msg}")
                return False, error_msg

            # Decode base64 image
            image_data = base64.b64decode(result['images'][0])

            # Save image
            output_path = OUTPUT_DIR / f"{guide_id}.png"
            with open(output_path, 'wb') as f:
                f.write(image_data)

            print(f"  ✓ Saved to: {output_path.name}")
            return True, str(output_path)

        except requests.exceptions.Timeout:
            error_msg = "Request timeout (>120s)"
            print(f"  ✗ {error_msg}")
            return False, error_msg
        except requests.exceptions.RequestException as e:
            error_msg = f"Network error: {e}"
            print(f"  ✗ {error_msg}")
            return False, error_msg
        except Exception as e:
            error_msg = f"Unexpected error: {e}"
            print(f"  ✗ {error_msg}")
            return False, error_msg

    def generate_all(self):
        """Generate all avatar images."""
        print(f"\n{'=' * 60}")
        print(f"Starting generation of {self.results['total']} avatars")
        print(f"{'=' * 60}")

        self.results['start_time'] = time.time()

        for index, guide in enumerate(self.guides):
            success, message = self.generate_image(guide, index)

            if success:
                self.results['success'].append({
                    'id': guide['id'],
                    'name': guide['name'],
                    'path': message
                })
            else:
                self.results['failed'].append({
                    'id': guide['id'],
                    'name': guide['name'],
                    'error': message
                })

            # Add delay between requests (except after last one)
            if index < len(self.guides) - 1:
                print(f"  ⏱ Waiting {DELAY_BETWEEN_REQUESTS}s before next request...")
                time.sleep(DELAY_BETWEEN_REQUESTS)

        self.results['end_time'] = time.time()

    def print_summary(self):
        """Print generation summary report."""
        duration = self.results['end_time'] - self.results['start_time']
        success_count = len(self.results['success'])
        failed_count = len(self.results['failed'])

        print(f"\n{'=' * 60}")
        print(f"GENERATION SUMMARY")
        print(f"{'=' * 60}")
        print(f"Total guides:     {self.results['total']}")
        print(f"✓ Successful:     {success_count}")
        print(f"✗ Failed:         {failed_count}")
        print(f"⏱ Duration:       {duration:.1f}s ({duration/60:.1f} minutes)")
        print(f"📁 Output dir:     {OUTPUT_DIR}")

        if self.results['success']:
            print(f"\n✓ Successfully generated ({success_count}):")
            for item in self.results['success']:
                print(f"  • {item['name']} ({item['id']}.png)")

        if self.results['failed']:
            print(f"\n✗ Failed generations ({failed_count}):")
            for item in self.results['failed']:
                print(f"  • {item['name']} ({item['id']})")
                print(f"    Error: {item['error']}")

        print(f"\n{'=' * 60}")

        if failed_count == 0:
            print("🎉 All avatars generated successfully!")
        elif success_count > 0:
            print(f"⚠ Partial success: {success_count}/{self.results['total']} completed")
        else:
            print("❌ Generation failed for all avatars")

        print(f"{'=' * 60}\n")

    def run(self):
        """Main execution flow."""
        print("\n🎨 Guide Avatar Generator for AuraList")
        print("Using Stable Diffusion WebUI API\n")

        # Ensure output directory exists
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

        # Load prompts
        if not self.load_prompts():
            return 1

        # Check API connection
        if not self.check_api_connection():
            return 1

        # Generate all images
        self.generate_all()

        # Print summary
        self.print_summary()

        # Return exit code
        return 0 if len(self.results['failed']) == 0 else 1


def main():
    """Entry point."""
    generator = AvatarGenerator()
    exit_code = generator.run()
    exit(exit_code)


if __name__ == "__main__":
    main()
