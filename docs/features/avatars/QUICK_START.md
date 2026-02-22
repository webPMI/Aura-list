# Avatar Generation - Quick Start Guide

Get started generating avatar images for AuraList's 19 mystical guides in under 15 minutes.

## Choose Your Method

### Method 1: Cloud API (Fastest) ⭐

**Best for:** Quick results, no local setup

**Time:** 5 min setup + 30-45 min generation
**Cost:** ~$0.19-0.40 for all 95 images
**Requirements:** API key only (no GPU needed)

```bash
# 1. Get API key from Replicate (replicate.com)
export REPLICATE_API_TOKEN="your-token-here"

# 2. Install Python client
pip install replicate

# 3. Generate images
python generate_with_replicate.py

# Done! Images in: assets/guides/avatars/
```

---

### Method 2: Docker + Stable Diffusion (Local GPU)

**Best for:** Full control, offline generation

**Time:** 15 min setup + 15-20 min generation (GPU) / 8-10 hours (CPU)
**Cost:** Free
**Requirements:** Docker, NVIDIA GPU (8GB+ VRAM recommended)

#### Step 1: Prerequisites

```bash
# Verify Docker
docker --version

# Verify GPU (optional but recommended)
nvidia-smi

# Should show your GPU: RTX 3060 Ti, RTX 4090, etc.
```

#### Step 2: Start Stable Diffusion

```bash
# GPU mode (recommended)
docker-compose up -d

# OR CPU mode (slower)
docker-compose -f docker-compose-cpu.yml up -d

# Wait 5-10 min for first-time model download (~4GB)
# Check: http://localhost:7860
```

#### Step 3: Generate Images

```bash
# Generate all 19 base avatars
python generate_all_avatars.py

# OR generate 95 style variations (5 per guide)
python generate_variations.py

# Images appear in: assets/guides/avatars/
```

#### Step 4: Verify

```bash
python verify_avatars.py

# Should show all images valid
```

---

### Method 3: ComfyUI (Best GPU Compatibility)

**Best for:** Newer GPUs (RTX 40xx/50xx series), advanced users

**Time:** 20 min setup + 15-20 min generation
**Cost:** Free
**Requirements:** ComfyUI installed locally

```bash
# 1. Start ComfyUI (adjust path to your installation)
cd C:\ComfyUI
python main.py

# 2. Load workflow in browser
# Open: http://localhost:8188
# Import: workflows/avatar-generation-basic.json

# 3. Run generation script
python generate_with_comfyui.py

# Images in: assets/guides/avatars/
```

---

## Verification Checklist

After generation, verify your avatars:

```bash
# Run verification script
python verify_avatars.py

# Check report
cat AVATAR_GENERATION_REPORT.md
```

### Expected Results

✅ **All valid avatars should have:**
- Dimensions: exactly 512 × 512 pixels
- Format: PNG
- File size: 50 KB - 2 MB
- Naming: `{guide-id}.png` (e.g., `luna-vacia.png`)

### Batch Generation Strategy

If generating all 95 variations at once:

**Batch 1: Core Guides (5 guides × 5 styles = 25 images)**
- luna-vacia, helioforja, leona-nova, chispa-azul, gloria-sincro

```bash
python generate_variations.py --style 1  # Ethereal style for all 19
```

**Batch 2: All Styles for One Guide (test)**

```bash
python generate_variations.py --guide luna-vacia  # 5 images
```

**Batch 3: Full Generation (all 95 images)**

```bash
python generate_variations.py  # ~60-90 min with GPU
```

---

## Troubleshooting

### "Cannot connect to API"

**Docker method:**
```bash
# Check if container is running
docker ps

# Check logs
docker logs auralist-sd-webui

# Restart if needed
docker-compose restart
```

**ComfyUI method:**
```bash
# Verify ComfyUI is running
curl http://localhost:8188/system_stats

# Should return JSON with system info
```

### "Out of memory" / Container killed

**Solution:** Increase memory limit

Edit `docker-compose.yml`:
```yaml
limits:
  memory: 16G  # Increase from 8G
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

### "CUDA error: no kernel image available"

**Problem:** GPU too new for current PyTorch version

**Solutions:**
1. Use ComfyUI instead (better GPU support)
2. Use CPU mode (slower): `docker-compose -f docker-compose-cpu.yml up -d`
3. Use cloud API (fastest): Replicate or Stability AI

### Images have wrong dimensions

**Solution:** Use resize script

```bash
# Preview what will be resized
python resize_avatars.py --dry-run

# Resize all oversized images
python resize_avatars.py

# Creates backups in: assets/guides/avatars/backups/
```

---

## Next Steps

Once you have generated and verified your avatars:

1. **Review quality** - Check that images match guide personalities
2. **Test in app** - Verify avatars display correctly in Flutter app
3. **Generate variations** - Create alternative styles if needed
4. **Update documentation** - Add any new guides to character docs

## Related Guides

- [Main Avatar Documentation](./README.md) - Complete system overview
- [Scripts Reference](./SCRIPTS_REFERENCE.md) - Detailed script documentation
- [Prompts Catalog](./PROMPTS_REFERENCE.md) - All AI prompts
- [Spanish Guide](./es/GUIA_RAPIDA.md) - Guía rápida en español

---

**Need help?** Check the main [README.md](./README.md) for detailed troubleshooting.
