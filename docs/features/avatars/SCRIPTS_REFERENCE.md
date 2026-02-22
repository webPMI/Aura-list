# Avatar Scripts Reference

Complete reference for all Python scripts used in avatar generation, verification, and management.

## Available Scripts

| Script | Purpose | Time | Use When |
|--------|---------|------|----------|
| `verify_avatars.py` | Validate existing images | ~1 sec | After generation, before deployment |
| `list_avatar_prompts.py` | Export prompts for tools | ~1 sec | Need prompts in CSV/JSON format |
| `resize_avatars.py` | Batch resize to 512×512 | ~5 sec | Images are wrong size |
| `generate_all_avatars.py` | Generate 19 base avatars | ~15-20 min (GPU) | First-time generation |
| `generate_variations.py` | Generate 95 style variations | ~60-90 min (GPU) | Need multiple styles |
| `generate_first_5.py` | Generate first 5 guides only | ~5-8 min (GPU) | Testing/demo |
| `monitor_progress.py` | Real-time generation monitor | Continuous | Long-running generation |

---

## 1. verify_avatars.py

Validates all avatar images against specifications.

### Usage

```bash
# Basic verification
python verify_avatars.py

# Verbose output
python verify_avatars.py --verbose
```

### What It Checks

- ✅ File exists in `assets/guides/avatars/`
- ✅ Dimensions are exactly 512 × 512 pixels
- ✅ Format is PNG
- ✅ File size is between 50 KB and 2 MB
- ✅ Filename matches `{guide-id}.png` pattern

### Output

**Console:**
```
Avatar Verification Report
==========================

Total Guides: 19
Valid Avatars: 15 (79%)
Invalid Avatars: 2 (11%)
Missing Avatars: 2 (11%)

✓ luna-vacia.png (512x512, 245 KB)
✓ helioforja.png (512x512, 312 KB)
✗ leona-nova.png (1024x1024, 890 KB) - Wrong dimensions
...
```

**Generated File:** `AVATAR_GENERATION_REPORT.md`

### Exit Codes

- `0` - All avatars valid
- `1` - Some avatars invalid or missing

### Integration Example

```bash
# In CI/CD pipeline
python verify_avatars.py || {
  echo "Avatar verification failed!"
  cat AVATAR_GENERATION_REPORT.md
  exit 1
}
```

---

## 2. list_avatar_prompts.py

Extracts and exports prompts in various formats.

### Usage

```bash
# List all prompts (full)
python list_avatar_prompts.py

# List only missing avatars
python list_avatar_prompts.py --format missing

# Get specific guide
python list_avatar_prompts.py --guide luna-vacia

# Export to CSV
python list_avatar_prompts.py --format csv > prompts.csv

# Export to JSON
python list_avatar_prompts.py --format json > prompts.json

# Show table format
python list_avatar_prompts.py --format table
```

### Output Formats

**Full (default):**
```
Guide: luna-vacia
Name: Luna-Vacía
Prompt: Purple ethereal samurai warrior...
Negative: ugly, deformed, noisy...

---
```

**Missing:**
```
luna-vacia - Luna-Vacía (Purple samurai warrior...)
helioforja - Helioforja (Blacksmith deity...)
```

**CSV:**
```csv
id,name,prompt,negative_prompt
luna-vacia,"Luna-Vacía","Purple ethereal...","ugly, deformed..."
```

**JSON:**
```json
{
  "config": {...},
  "guides": [
    {
      "id": "luna-vacia",
      "name": "Luna-Vacía",
      "prompt": "...",
      ...
    }
  ]
}
```

### Use Cases

- Export prompts for batch processing in external tools
- Generate spreadsheet for project management
- Get individual prompts for manual generation
- Identify which avatars still need creation

---

## 3. resize_avatars.py

Batch resize avatars to correct dimensions with backups.

### Usage

```bash
# Preview what will be resized (dry-run)
python resize_avatars.py --dry-run

# Resize all oversized images
python resize_avatars.py

# Process specific directory
python resize_avatars.py --input-dir custom/path --output-dir output/path

# Skip backup creation
python resize_avatars.py --no-backup
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--dry-run` | Show what would be resized without doing it | Off |
| `--input-dir PATH` | Input directory | `assets/guides/avatars` |
| `--output-dir PATH` | Output directory | Same as input |
| `--backup-dir PATH` | Backup directory | `assets/guides/avatars/backups` |
| `--no-backup` | Skip backup creation | Off (creates backups) |

### Process

1. Scans input directory for PNG files
2. Checks dimensions of each image
3. Creates backup of original (unless `--no-backup`)
4. Resizes using high-quality Lanczos resampling
5. Overwrites original with resized version
6. Reports results

### Output Example

```
Resizing Avatar Images
======================

Processing: assets/guides/avatars/

✓ Backed up leona-nova.png (1024x1024)
  → Resized to 512x512 (245 KB → 156 KB)

✓ Backed up atlas-orbital.png (2048x2048)
  → Resized to 512x512 (892 KB → 178 KB)

✗ luna-vacia.png - Already 512x512, skipping

Summary
-------
Total processed: 19
Resized: 2
Skipped: 17
Backups created: 2 (in assets/guides/avatars/backups/)
```

### Quality Settings

- **Resampling:** Lanczos (highest quality)
- **Aspect ratio:** Preserved
- **Format:** PNG (no quality loss)

---

## 4. generate_all_avatars.py

Generate 19 base avatars using Stable Diffusion API.

### Usage

```bash
# Generate all 19 avatars
python generate_all_avatars.py

# Resume from interruption
python generate_all_avatars.py --resume

# Skip existing images
python generate_all_avatars.py --skip-existing
```

### Options

| Flag | Description |
|------|-------------|
| `--resume` | Continue from last generated avatar |
| `--skip-existing` | Don't regenerate existing files |

### Requirements

- Stable Diffusion WebUI running on `localhost:7860`
- Model loaded (automatic on first run)
- `guide_prompts.json` in project root

### Process

1. Loads prompts from `guide_prompts.json`
2. Connects to SD WebUI API
3. Generates each avatar sequentially
4. Saves to `assets/guides/avatars/`
5. Shows progress and statistics

### Output Example

```
=================================================================
          Avatar Generation for AuraList (19 Guides)
=================================================================

Loaded 19 prompts from guide_prompts.json
Connected to Stable Diffusion API at http://localhost:7860

[1/19] Generating luna-vacia.png...
✓ Generated in 45.2s (512x512, 234 KB)

[2/19] Generating helioforja.png...
✓ Generated in 43.8s (512x512, 298 KB)

...

=================================================================
                    Generation Complete!
=================================================================

Total Time: 14m 32s
Success: 19/19 (100%)
Failed: 0
Average: 45.9s per image

Images saved to: assets/guides/avatars/
```

### Troubleshooting

**Error: Cannot connect to API**
```bash
# Check if SD WebUI is running
docker ps
curl http://localhost:7860/sdapi/v1/sd-models

# Restart if needed
docker-compose restart
```

**Error: Out of memory**
```bash
# Use lower resolution temporarily
# Edit guide_prompts.json: "width": 512, "height": 512

# OR increase Docker memory
# Edit docker-compose.yml: memory: 16G
```

---

## 5. generate_variations.py

Generate 95 style variations (5 per guide).

### Usage

```bash
# Generate all 95 variations
python generate_variations.py

# Generate only one style for all guides
python generate_variations.py --style 1

# Generate all styles for one guide
python generate_variations.py --guide luna-vacia

# Skip existing files
python generate_variations.py --skip-existing
```

### Options

| Flag | Description | Output |
|------|-------------|--------|
| `--style N` | Generate only style N (1-5) | 19 images |
| `--guide ID` | Generate only guide ID | 5 images |
| `--skip-existing` | Don't regenerate existing | Varies |

### Style Breakdown

1. **Style 1 - Ethereal:** Soft glowing aura, mystical atmosphere
2. **Style 2 - Anime:** Bold colors, dynamic energy
3. **Style 3 - Minimal:** Clean lines, geometric, symbolic
4. **Style 4 - Watercolor:** Flowing brushstrokes, dreamy
5. **Style 5 - Art Nouveau:** Ornate patterns, elegant

### Output Structure

```
assets/guides/avatars/variations/
├── luna-vacia-style1-ethereal.png
├── luna-vacia-style2-anime.png
├── luna-vacia-style3-minimal.png
├── luna-vacia-style4-watercolor.png
├── luna-vacia-style5-artnouv eau.png
├── helioforja-style1-ethereal.png
...
```

### Performance

| Mode | Time | Notes |
|------|------|-------|
| GPU (RTX 3060 Ti) | ~60-90 min | ~45s per image |
| GPU (RTX 4090) | ~30-45 min | ~20s per image |
| CPU | ~8-10 hours | ~5-8 min per image |

---

## 6. generate_first_5.py

Generate only the first 5 guides (testing/demo).

### Usage

```bash
# Generate first 5 guides (all styles = 25 images)
python generate_first_5.py

# Generate first 5 guides (base only = 5 images)
python generate_first_5.py --base-only
```

### First 5 Guides

1. luna-vacia - Purple samurai
2. helioforja - Cosmic blacksmith
3. leona-nova - Golden lioness
4. chispa-azul - Lightning messenger
5. gloria-sincro - Victory weaver

**Use for:** Testing setup, demo, or partial generation.

---

## 7. monitor_progress.py

Real-time monitoring of generation progress.

### Usage

```bash
# Monitor current generation
python monitor_progress.py

# Monitor with custom interval
python monitor_progress.py --interval 5
```

### Output

```
Avatar Generation Monitor
=========================

Time Elapsed: 12m 34s
Images Generated: 42/95 (44%)
Success Rate: 100%
Avg Time: 17.9s per image
Est. Remaining: 15m 46s

Current: helioforja-style3-minimal.png
Last 5:
  ✓ luna-vacia-style5-artnouv eau.png (18.2s)
  ✓ luna-vacia-style4-watercolor.png (17.5s)
  ✓ luna-vacia-style3-minimal.png (16.8s)
  ✓ luna-vacia-style2-anime.png (19.1s)
  ✓ luna-vacia-style1-ethereal.png (18.4s)

[Press Ctrl+C to exit]
```

---

## Common Workflows

### Workflow 1: First-Time Generation

```bash
# 1. Verify current status
python verify_avatars.py

# 2. Generate base avatars
python generate_all_avatars.py

# 3. Verify results
python verify_avatars.py

# 4. Generate variations (optional)
python generate_variations.py
```

### Workflow 2: Fix Invalid Images

```bash
# 1. Find issues
python verify_avatars.py

# 2. Check if it's a size issue
python resize_avatars.py --dry-run

# 3. Resize if needed
python resize_avatars.py

# 4. Re-verify
python verify_avatars.py
```

### Workflow 3: Export for External Tool

```bash
# Export to CSV for spreadsheet
python list_avatar_prompts.py --format csv > prompts.csv

# Open in Excel/Google Sheets
# Generate images with external tool (Midjourney, DALL-E, etc.)
# Save as {guide-id}.png in assets/guides/avatars/

# Verify
python verify_avatars.py
```

---

## Configuration Files

### guide_prompts.json

Base prompts for 19 guides (one style per guide).

```json
{
  "config": {
    "base_style": "mystical celestial character portrait...",
    "negative_prompt": "ugly, deformed, noisy...",
    "steps": 30,
    "cfg_scale": 7.5,
    "width": 512,
    "height": 512,
    "sampler": "DPM++ 2M Karras"
  },
  "guides": [...]
}
```

### guide_prompts_variations.json

Style variations (5 per guide = 95 total).

```json
{
  "metadata": {
    "total_guides": 19,
    "variations_per_guide": 5,
    "total_prompts": 95
  },
  "guides": [
    {
      "id": "luna-vacia",
      "variations": [
        {"style": 1, "name": "Ethereal Samurai", "prompt": "..."},
        {"style": 2, "name": "Anime Warrior", "prompt": "..."},
        ...
      ]
    }
  ]
}
```

---

## Exit Codes

All scripts follow this convention:

- `0` - Success
- `1` - Validation failed / Some images invalid
- `2` - Critical error (missing files, API down, etc.)

Use in scripts:
```bash
python verify_avatars.py
if [ $? -eq 0 ]; then
  echo "All avatars valid!"
else
  echo "Validation failed, check AVATAR_GENERATION_REPORT.md"
fi
```

---

## Related Documentation

- [Main Guide](./README.md) - Overview and setup
- [Quick Start](./QUICK_START.md) - Getting started
- [Prompts Catalog](./PROMPTS_REFERENCE.md) - All prompts reference
- [Spanish Guide](./es/README.md) - Documentación en español
