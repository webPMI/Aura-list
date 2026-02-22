# 🚀 Inicio Rápido: Generación de Avatares con IA

## En 3 Pasos

### 1️⃣ Levantar Docker

```bash
docker-compose up -d
```

Espera 2-3 minutos. Verifica en: http://localhost:7860

### 2️⃣ Generar Avatares

```bash
# Opción A: Solo 19 avatares base (~5-10 min)
python generate_all_avatars.py

# Opción B: Todas las variaciones (~1-2 horas)
python generate_variations.py
```

### 3️⃣ Verificar Resultados

```bash
python verify_all_avatars.py
```

---

## 📁 Imágenes Generadas

- **Base**: `assets/guides/avatars/*.png` (19 imágenes)
- **Variaciones**: `assets/guides/avatars/variations/*_style{1-5}.png` (95 imágenes)

---

## 🛑 Detener Docker

```bash
docker-compose down
```

---

## 📖 Documentación Completa

Ver: [GUIA_GENERACION_AVATARES.md](GUIA_GENERACION_AVATARES.md)

---

## 🆘 Problemas Comunes

### "Cannot connect to API"
```bash
docker-compose logs -f
# Esperar hasta ver: "Running on http://0.0.0.0:7860"
```

### Out of Memory
Editar `docker-compose.yml`, cambiar:
```yaml
- CLI_ARGS=--api --listen --xformers --lowvram
```

### GPU no detectada
Solo en primera instalación, requiere NVIDIA Container Toolkit.
Ver guía completa.

---

## 📊 Scripts Disponibles

| Script | Qué Hace | Tiempo |
|--------|----------|--------|
| `generate_all_avatars.py` | 19 avatares base | 5-10 min |
| `generate_variations.py` | 95 variaciones (5×19) | 1-2 horas |
| `generate_variations.py --style 1` | 19 variaciones estilo 1 | 10-15 min |
| `verify_all_avatars.py` | Verifica imágenes | <1 min |

---

## 💡 Tips

- Usa `--skip-existing` para continuar si se interrumpe
- Primera vez descarga modelos (~4GB, 10-15 min)
- Genera variaciones por estilo para mejor control
- Prueba con 1 guía primero: `python generate_variations.py --guide luna-vacia`

---

¡Listo! 🎉
