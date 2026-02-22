# Avatar Generation System

Complete guide for generating avatar images for AuraList's 19 mystical guide characters.

## Overview

The avatar generation system creates consistent, high-quality character portraits for the Guides - personified AI assistants that help users with productivity and well-being.

### What Are Guides?

Guides are mystical celestial characters in AuraList with:
- Unique personalities and visual identities
- Specific expertise areas (task management, stress reduction, etc.)
- Avatar images representing them visually

### Avatar Specifications

- **Format:** PNG with transparency
- **Dimensions:** 512 × 512 pixels (exactly)
- **File Size:** 50 KB - 2 MB
- **Naming:** `{guide-id}.png` (lowercase, hyphenated)
- **Style:** Mystical celestial character portrait, fantasy art

## Quick Start

→ **See [QUICK_START.md](./QUICK_START.md)** for setup instructions

## Generation Options

### Option 1: Cloud API (Recommended)

**Best for:** Quick generation, no local setup

- **Replicate API:** ~$0.19 for 95 images (~30-45 min)
- **Stability AI API:** ~$0.20-0.40 for 95 images
- Requires API key (free tier available)
- No local GPU needed

### Option 2: Local with Docker + Stable Diffusion

**Best for:** Full control, offline generation, GPU available

```bash
# Start Stable Diffusion WebUI
docker-compose up -d stable-diffusion-webui

# Verify API at http://localhost:7860

# Generate images
python generate_variations.py
```

**Requirements:**
- Docker and Docker Compose
- NVIDIA GPU with CUDA (8GB+ VRAM recommended)
- ~10GB disk space for AI models

**Time:** ~15-20 min with GPU, ~8-10 hours with CPU

### Option 3: Local with ComfyUI

**Best for:** Advanced workflows, better GPU compatibility

- Supports newer GPUs (RTX 40xx/50xx series)
- Node-based workflow system
- Manual setup required

## File Structure

```
checklist-app/
├── docs/features/avatars/
│   ├── README.md (this file)
│   ├── QUICK_START.md
│   ├── SCRIPTS_REFERENCE.md
│   ├── PROMPTS_REFERENCE.md
│   └── es/ (Spanish documentation)
│
├── guide_prompts.json           # Base prompts (19 guides)
├── guide_prompts_variations.json # Style variations (95 prompts)
│
├── generate_all_avatars.py      # Generate base avatars
├── generate_variations.py       # Generate 5 styles per guide
├── verify_avatars.py           # Validate generated images
├── resize_avatars.py           # Batch resize utility
│
├── docker-compose.yml           # GPU config
├── docker-compose-cpu.yml      # CPU fallback
│
└── assets/guides/avatars/       # Output directory
    └── variations/             # Style variations
```

## The 19 Guides

| Guide | Color | Archetype | Purpose |
|-------|-------|-----------|---------|
| Luna-Vacía | #4A148C | Samurai of Silence | Rest/Wellness |
| Helioforja | #8B2500 | Cosmic Blacksmith | Physical Effort |
| Leona-Nova | #B8860B | Golden Lioness | Discipline |
| Chispa-Azul | #1E88E5 | Lightning Messenger | Quick Tasks |
| Gloria-Sincro | #FFD700 | Victory Weaver | Achievements |
| ... | ... | ... | ... |

→ **Full list:** See [PROMPTS_REFERENCE.md](./PROMPTS_REFERENCE.md)

## Style Variations

Each guide has 5 artistic style variations:

1. **Ethereal** - Fantasy art, soft glowing aura, mystical atmosphere
2. **Anime** - Bold anime style, vibrant colors, dynamic energy
3. **Minimal** - Geometric minimalist, clean lines, symbolic
4. **Watercolor** - Painterly, flowing brushstrokes, dreamy aesthetic
5. **Art Nouveau** - Digital art nouveau, ornate patterns, elegant

**Total:** 19 guides × 5 styles = **95 images**

## Workflow

```
1. Review prompts         → guide_prompts_variations.json
2. Choose generation method → Cloud API / Docker / ComfyUI
3. Run generation script   → generate_variations.py
4. Verify output          → verify_avatars.py
5. Resize if needed       → resize_avatars.py
6. Use in app             → assets/guides/avatars/
```

## Scripts Reference

→ **See [SCRIPTS_REFERENCE.md](./SCRIPTS_REFERENCE.md)** for detailed script documentation

## Troubleshooting

### GPU Not Detected

**Problem:** CUDA error or GPU not found

**Solutions:**
1. Verify GPU drivers: `nvidia-smi`
2. Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`
3. Use CPU fallback: `docker-compose -f docker-compose-cpu.yml up -d`
4. Try ComfyUI (better compatibility with newer GPUs)

### Out of Memory

**Problem:** Container killed (exit code 137)

**Solutions:**
1. Increase Docker memory limit in `docker-compose.yml`:
   ```yaml
   limits:
     memory: 16G  # Increase from 8G
   ```
2. Use `--medvram` or `--lowvram` flags
3. Generate fewer images at once

### API Connection Failed

**Problem:** Cannot connect to localhost:7860 or localhost:8188

**Solutions:**
1. Check container is running: `docker ps`
2. Wait for model download (first run takes 10-15 min)
3. Check logs: `docker logs auralist-sd-webui`
4. Verify port not in use: `netstat -an | findstr 7860`

## Related Documentation

- [Quick Start Guide](./QUICK_START.md) - Setup and first generation
- [Scripts Reference](./SCRIPTS_REFERENCE.md) - All script commands
- [Prompts Catalog](./PROMPTS_REFERENCE.md) - Complete prompt reference
- [Spanish Guide](./es/README.md) - Documentación en español

## Contributing

When adding new guides:

1. Add prompt to `guide_prompts.json`
2. Add 5 style variations to `guide_prompts_variations.json`
3. Generate images: `python generate_variations.py --guide new-guide-id`
4. Verify: `python verify_avatars.py`
5. Update character documentation in `docs/features/guides/personajes-misticos/`

---

**Generated with:** Stable Diffusion / ComfyUI / Cloud APIs
**Model:** DreamShaper / Realistic Vision / Anything V5 (or similar)
**Resolution:** 512×512 pixels
**Format:** PNG
