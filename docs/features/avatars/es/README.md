# Sistema de Generación de Avatares

Guía completa para generar imágenes de avatar de los 19 personajes guía místicos de AuraList.

## Resumen

El sistema de generación de avatares crea retratos de personajes consistentes y de alta calidad para los Guías - asistentes de IA personificados que ayudan a los usuarios con productividad y bienestar.

### ¿Qué son los Guías?

Los Guías son personajes celestiales místicos en AuraList con:
- Personalidades e identidades visuales únicas
- Áreas de especialización específicas (gestión de tareas, reducción de estrés, etc.)
- Imágenes de avatar que los representan visualmente

### Especificaciones de Avatares

- **Formato:** PNG con transparencia
- **Dimensiones:** 512 × 512 píxeles (exactamente)
- **Tamaño de archivo:** 50 KB - 2 MB
- **Nomenclatura:** `{guide-id}.png` (minúsculas, con guiones)
- **Estilo:** Retrato de personaje celestial místico, arte fantástico

## Inicio Rápido

→ **Ver [GUIA_RAPIDA.md](./GUIA_RAPIDA.md)** para instrucciones de configuración

## Opciones de Generación

### Opción 1: API en la Nube (Recomendado)

**Mejor para:** Generación rápida, sin configuración local

- **Replicate API:** ~$0.19 para 95 imágenes (~30-45 min)
- **Stability AI API:** ~$0.20-0.40 para 95 imágenes
- Requiere API key (nivel gratuito disponible)
- No necesita GPU local

### Opción 2: Local con Docker + Stable Diffusion

**Mejor para:** Control total, generación offline, GPU disponible

```bash
# Iniciar Stable Diffusion WebUI
docker-compose up -d

# Verificar API en http://localhost:7860

# Generar imágenes
python generate_variations.py
```

**Requisitos:**
- Docker y Docker Compose
- GPU NVIDIA con CUDA (8GB+ VRAM recomendado)
- ~10GB espacio en disco para modelos de IA

**Tiempo:** ~15-20 min con GPU, ~8-10 horas con CPU

### Opción 3: Local con ComfyUI

**Mejor para:** Flujos de trabajo avanzados, mejor compatibilidad GPU

- Soporta GPUs más nuevas (series RTX 40xx/50xx)
- Sistema de flujo de trabajo basado en nodos
- Requiere configuración manual

## Estructura de Archivos

```
checklist-app/
├── docs/features/avatars/
│   ├── README.md
│   ├── QUICK_START.md
│   ├── SCRIPTS_REFERENCE.md
│   ├── PROMPTS_REFERENCE.md
│   └── es/ (documentación en español)
│       ├── README.md (este archivo)
│       └── GUIA_RAPIDA.md
│
├── guide_prompts.json           # Prompts base (19 guías)
├── guide_prompts_variations.json # Variaciones de estilo (95 prompts)
│
├── generate_all_avatars.py      # Generar avatares base
├── generate_variations.py       # Generar 5 estilos por guía
├── verify_avatars.py           # Validar imágenes generadas
├── resize_avatars.py           # Utilidad de redimensionamiento
│
├── docker-compose.yml           # Configuración GPU
├── docker-compose-cpu.yml      # Fallback CPU
│
└── assets/guides/avatars/       # Directorio de salida
    └── variations/             # Variaciones de estilo
```

## Los 19 Guías

| Guía | Color | Arquetipo | Propósito |
|------|-------|-----------|-----------|
| Luna-Vacía | #4A148C | Samurái del Silencio | Descanso/Bienestar |
| Helioforja | #8B2500 | Herrero Cósmico | Esfuerzo Físico |
| Leona-Nova | #B8860B | Leona Dorada | Disciplina |
| Chispa-Azul | #1E88E5 | Mensajero Relámpago | Tareas Rápidas |
| Gloria-Sincro | #FFD700 | Tejedora de Victoria | Logros |
| ... | ... | ... | ... |

→ **Lista completa:** Ver [PROMPTS_REFERENCE.md](../PROMPTS_REFERENCE.md)

## Variaciones de Estilo

Cada guía tiene 5 variaciones de estilo artístico:

1. **Etéreo** - Arte fantástico, aura brillante suave, atmósfera mística
2. **Anime** - Estilo anime audaz, colores vibrantes, energía dinámica
3. **Minimalista** - Geométrico minimalista, líneas limpias, simbólico
4. **Acuarela** - Pictórico, pinceladas fluidas, estética onírica
5. **Art Nouveau** - Art nouveau digital, patrones ornamentados, elegante

**Total:** 19 guías × 5 estilos = **95 imágenes**

## Flujo de Trabajo

```
1. Revisar prompts         → guide_prompts_variations.json
2. Elegir método generación → API Cloud / Docker / ComfyUI
3. Ejecutar script         → generate_variations.py
4. Verificar resultado     → verify_avatars.py
5. Redimensionar si necesario → resize_avatars.py
6. Usar en la app          → assets/guides/avatars/
```

## Referencia de Scripts

→ **Ver [SCRIPTS_REFERENCE.md](../SCRIPTS_REFERENCE.md)** para documentación detallada de scripts (en inglés)

## Resolución de Problemas

### GPU No Detectada

**Problema:** Error CUDA o GPU no encontrada

**Soluciones:**
1. Verificar drivers GPU: `nvidia-smi`
2. Verificar soporte GPU Docker: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`
3. Usar fallback CPU: `docker-compose -f docker-compose-cpu.yml up -d`
4. Probar ComfyUI (mejor compatibilidad con GPUs nuevas)

### Sin Memoria

**Problema:** Contenedor terminado (código de salida 137)

**Soluciones:**
1. Aumentar límite de memoria Docker en `docker-compose.yml`:
   ```yaml
   limits:
     memory: 16G  # Aumentar de 8G
   ```
2. Usar flags `--medvram` o `--lowvram`
3. Generar menos imágenes a la vez

### Fallo de Conexión API

**Problema:** No se puede conectar a localhost:7860 o localhost:8188

**Soluciones:**
1. Verificar que el contenedor está corriendo: `docker ps`
2. Esperar descarga del modelo (primera ejecución toma 10-15 min)
3. Verificar logs: `docker logs auralist-sd-webui`
4. Verificar que el puerto no esté en uso: `netstat -an | findstr 7860`

## Documentación Relacionada

- [Guía Rápida](./GUIA_RAPIDA.md) - Configuración y primera generación
- [Referencia de Scripts](../SCRIPTS_REFERENCE.md) - Todos los comandos de scripts
- [Catálogo de Prompts](../PROMPTS_REFERENCE.md) - Referencia completa de prompts
- [English Guide](../README.md) - Documentación en inglés

## Contribuir

Al agregar nuevos guías:

1. Agregar prompt a `guide_prompts.json`
2. Agregar 5 variaciones de estilo a `guide_prompts_variations.json`
3. Generar imágenes: `python generate_variations.py --guide nuevo-guia-id`
4. Verificar: `python verify_avatars.py`
5. Actualizar documentación del personaje en `docs/features/guides/personajes-misticos/`

---

**Generado con:** Stable Diffusion / ComfyUI / APIs Cloud
**Modelo:** DreamShaper / Realistic Vision / Anything V5 (o similar)
**Resolución:** 512×512 píxeles
**Formato:** PNG
