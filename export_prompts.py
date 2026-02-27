#!/usr/bin/env python3
"""
Export Guide Prompts to Multiple Formats
Generates ready-to-use prompt files in various formats.
"""

import json
import csv
from pathlib import Path

def load_prompts():
    """Load prompts from JSON file"""
    with open('guide_prompts_variations.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def export_to_text(data, output_file='PROMPTS_TEXT.txt'):
    """Export all prompts to a plain text file"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("AURALIST GUIDE AVATARS - IMAGE GENERATION PROMPTS\n")
        f.write(f"Total: {data['metadata']['total_prompts']} prompts ")
        f.write(f"({data['metadata']['total_guides']} guides × {data['metadata']['variations_per_guide']} styles)\n")
        f.write("=" * 80 + "\n\n")

        f.write("BASE SETTINGS:\n")
        f.write("-" * 40 + "\n")
        params = data['metadata']['base_params']
        f.write(f"Size: {params['width']}x{params['height']}\n")
        f.write(f"Steps: {params['steps']}\n")
        f.write(f"CFG Scale: {params['cfg_scale']}\n")
        f.write(f"Sampler: {params['sampler']}\n\n")

        f.write("NEGATIVE PROMPT (use for all):\n")
        f.write("-" * 40 + "\n")
        f.write(f"{data['metadata']['base_negative']}\n\n")

        f.write("=" * 80 + "\n\n")

        for guide in data['guides']:
            f.write(f"\n{'=' * 80}\n")
            f.write(f"GUIDE: {guide['name']} ({guide['id']})\n")
            f.write(f"Color: {guide['color']} | Archetype: {guide['archetype']}\n")
            f.write(f"{'=' * 80}\n\n")

            for i, variation in enumerate(guide['variations'], 1):
                f.write(f"--- Style {variation['style']}: {variation['name']} ---\n\n")
                f.write(f"{variation['prompt']}\n\n")
                f.write(f"Negative: {data['metadata']['base_negative']}\n")
                f.write("\n" + "-" * 80 + "\n\n")

    print(f"✓ Text export complete: {output_file}")

def export_to_csv(data, output_file='PROMPTS_SPREADSHEET.csv'):
    """Export prompts to CSV for spreadsheets"""
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)

        # Header
        writer.writerow([
            'Guide ID', 'Guide Name', 'Color', 'Archetype',
            'Style Number', 'Style Name', 'Full Prompt', 'Negative Prompt',
            'Width', 'Height', 'Steps', 'CFG', 'Sampler'
        ])

        params = data['metadata']['base_params']
        neg = data['metadata']['base_negative']

        # Data rows
        for guide in data['guides']:
            for var in guide['variations']:
                writer.writerow([
                    guide['id'],
                    guide['name'],
                    guide['color'],
                    guide['archetype'],
                    var['style'],
                    var['name'],
                    var['prompt'],
                    neg,
                    params['width'],
                    params['height'],
                    params['steps'],
                    params['cfg_scale'],
                    params['sampler']
                ])

    print(f"✓ CSV export complete: {output_file}")

def export_to_markdown(data, output_file='PROMPTS_REFERENCE.md'):
    """Export prompts to Markdown with tables"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# AuraList Guide Avatars - Prompt Reference\n\n")
        f.write(f"**Total Prompts:** {data['metadata']['total_prompts']} ")
        f.write(f"({data['metadata']['total_guides']} guides × {data['metadata']['variations_per_guide']} style variations)\n\n")

        f.write("## Base Configuration\n\n")
        f.write("Use these settings for all generations:\n\n")
        params = data['metadata']['base_params']
        f.write(f"- **Size:** {params['width']}×{params['height']}\n")
        f.write(f"- **Steps:** {params['steps']}\n")
        f.write(f"- **CFG Scale:** {params['cfg_scale']}\n")
        f.write(f"- **Sampler:** {params['sampler']}\n\n")

        f.write("## Universal Negative Prompt\n\n")
        f.write("```\n")
        f.write(data['metadata']['base_negative'])
        f.write("\n```\n\n")

        f.write("## Style Descriptions\n\n")
        for style_id, desc in data['metadata']['style_descriptions'].items():
            f.write(f"- **Style {style_id.split('_')[1]}:** {desc}\n")
        f.write("\n---\n\n")

        for guide in data['guides']:
            f.write(f"## {guide['name']} (`{guide['id']}`)\n\n")
            f.write(f"**Color:** {guide['color']} | **Archetype:** {guide['archetype']}\n\n")

            f.write("| Style | Name | Prompt |\n")
            f.write("|-------|------|--------|\n")

            for var in guide['variations']:
                # Truncate prompt for table readability
                prompt_short = var['prompt'][:80] + "..." if len(var['prompt']) > 80 else var['prompt']
                f.write(f"| {var['style']} | {var['name']} | {prompt_short} |\n")

            f.write("\n### Full Prompts\n\n")
            for var in guide['variations']:
                f.write(f"#### Style {var['style']}: {var['name']}\n\n")
                f.write(f"```\n{var['prompt']}\n```\n\n")

            f.write("---\n\n")

    print(f"✓ Markdown export complete: {output_file}")

def export_individual_files(data, output_dir='prompts_individual'):
    """Export each guide's prompts to separate files"""
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)

    for guide in data['guides']:
        filename = output_path / f"{guide['id']}_prompts.txt"

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"{guide['name']} - Image Generation Prompts\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"ID: {guide['id']}\n")
            f.write(f"Color: {guide['color']}\n")
            f.write(f"Archetype: {guide['archetype']}\n\n")
            f.write("=" * 60 + "\n\n")

            for i, var in enumerate(guide['variations'], 1):
                f.write(f"VARIATION {i}: {var['name']}\n")
                f.write("-" * 60 + "\n\n")
                f.write(f"PROMPT:\n{var['prompt']}\n\n")
                f.write(f"NEGATIVE:\n{data['metadata']['base_negative']}\n\n")
                f.write("=" * 60 + "\n\n")

    print(f"✓ Individual files exported to: {output_dir}/")

def export_for_image_gen_tools(data, output_file='prompts_for_tools.json'):
    """Export in a format optimized for automation tools"""
    export_data = {
        "config": data['metadata']['base_params'],
        "negative_prompt": data['metadata']['base_negative'],
        "prompts": []
    }

    for guide in data['guides']:
        for var in guide['variations']:
            export_data["prompts"].append({
                "id": f"{guide['id']}_style{var['style']}",
                "filename": f"{guide['id']}_style{var['style']}.png",
                "guide_id": guide['id'],
                "guide_name": guide['name'],
                "style": var['style'],
                "style_name": var['name'],
                "prompt": var['prompt'],
                "color": guide['color']
            })

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(export_data, f, indent=2, ensure_ascii=False)

    print(f"✓ Tool-ready JSON export complete: {output_file}")

def main():
    """Export prompts to all formats"""
    print("\n" + "=" * 60)
    print("  AuraList Guide Prompts - Multi-Format Exporter")
    print("=" * 60 + "\n")

    print("Loading prompts...")
    data = load_prompts()

    print(f"Found {data['metadata']['total_guides']} guides with ")
    print(f"{data['metadata']['variations_per_guide']} variations each\n")

    print("Exporting to multiple formats...\n")

    # Export to all formats
    export_to_text(data)
    export_to_csv(data)
    export_to_markdown(data)
    export_individual_files(data)
    export_for_image_gen_tools(data)

    print("\n" + "=" * 60)
    print("  Export Complete!")
    print("=" * 60 + "\n")

    print("Generated files:")
    print("  📄 PROMPTS_TEXT.txt           - All prompts in plain text")
    print("  📊 PROMPTS_SPREADSHEET.csv    - Import to Excel/Sheets")
    print("  📝 PROMPTS_REFERENCE.md       - Markdown documentation")
    print("  📁 prompts_individual/        - One file per guide")
    print("  🤖 prompts_for_tools.json     - Automation-ready format")
    print("\nReady to use with any AI image generator!")

if __name__ == "__main__":
    main()
