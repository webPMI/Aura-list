#!/usr/bin/env python3
"""
Generador automatizado de avatares para los 21 Guías Celestiales de AuraList
usando Stable Diffusion local vía API.
"""

import os
import json
import time
import requests
from pathlib import Path
from typing import Dict, List
from PIL import Image
import io

# Configuración
SD_API_URL = os.getenv('SD_API_URL', 'http://localhost:7860')
OUTPUT_DIR = Path(os.getenv('OUTPUT_DIR', './generated-avatars'))
GUIDES_DATA = Path(os.getenv('GUIDES_DATA_PATH', '../../../lib/features/guides/data/guide_catalog.dart'))

# Catálogo de guías extraído del código Dart
GUIDES_CATALOG = [
    {
        "id": "aethel",
        "name": "Aethel",
        "title": "El Primer Pulso del Sol",
        "archetype": "Guerrero de la Luz",
        "mythology": "Sol, Helios, Ra",
        "colors": ["#E65100", "#FFB300"],
        "keywords": "solar, warrior, fire, dawn, orange golden light"
    },
    {
        "id": "crono-velo",
        "name": "Crono-Velo",
        "title": "El Tejedor del Perpetuo",
        "archetype": "Sabio del Tiempo",
        "mythology": "Saturno, Cronos, Thoth, Norns",
        "colors": ["#1565C0", "#42A5F5"],
        "keywords": "time, clock, hourglass, cosmic blue, eternal wisdom"
    },
    {
        "id": "luna-vacia",
        "name": "Luna-Vacía",
        "title": "El Samurái del Silencio",
        "archetype": "Protector Silencioso",
        "mythology": "Luna, Tsuki no Usagi, Selene",
        "colors": ["#4A148C", "#B39DDB"],
        "keywords": "moon, samurai, silence, purple silver, zen warrior"
    },
    {
        "id": "helioforja",
        "name": "Helioforja",
        "title": "La Forja del Sol Rojo",
        "archetype": "Forjador",
        "mythology": "Marte, Ares, Horus, Tyr, Orión",
        "colors": ["#8B2500", "#E85D04"],
        "keywords": "forge, blacksmith, red sun, hammer, fire steel"
    },
    {
        "id": "leona-nova",
        "name": "Leona-Nova",
        "title": "La Soberana del Ritmo Solar",
        "archetype": "Soberana",
        "mythology": "Sol en Leo, Sekhmet, Regulus",
        "colors": ["#B8860B", "#FFD700"],
        "keywords": "lioness, queen, golden crown, solar majesty, regal"
    },
    {
        "id": "chispa-azul",
        "name": "Chispa-Azul",
        "title": "El Mensajero del Relámpago",
        "archetype": "Mensajero",
        "mythology": "Mercurio, Hermes, Thoth",
        "colors": ["#1E88E5", "#42A5F5"],
        "keywords": "lightning, messenger, wings, blue electric, speed"
    },
    {
        "id": "gloria-sincro",
        "name": "Gloria-Sincro",
        "title": "La Tejedora de Logros",
        "archetype": "Victoria Consciente",
        "mythology": "Nike, Corona Borealis",
        "colors": ["#FFD700", "#FFA000"],
        "keywords": "victory, laurel crown, golden, achievement, triumph"
    },
    {
        "id": "pacha-nexo",
        "name": "Pacha-Nexo",
        "title": "El Tejedor del Ecosistema Vital",
        "archetype": "Tejedor del Ecosistema",
        "mythology": "Pacha, Gaia",
        "colors": ["#2E7D32", "#81C784"],
        "keywords": "earth, nature, green web, ecosystem, connection"
    },
    {
        "id": "gea-metrica",
        "name": "Gea-Métrica",
        "title": "La Guardiana de los Hábitos que Dan Fruto",
        "archetype": "Guardiana que Nutre",
        "mythology": "Gea, Tellus",
        "colors": ["#388E3C", "#66BB6A"],
        "keywords": "earth mother, harvest, green growth, nurturing, fertile"
    },
    {
        "id": "selene-fase",
        "name": "Selene-Fase",
        "title": "La Danzante de las Mareas Internas",
        "archetype": "Danzante Lunar",
        "mythology": "Selene, Artemisa",
        "colors": ["#5E35B1", "#AB47BC"],
        "keywords": "moon phases, dance, purple silver, tides, mystical"
    },
    {
        "id": "viento-estacion",
        "name": "Viento-Estación",
        "title": "El Guardián de los Ciclos Naturales",
        "archetype": "Guardián Estacional",
        "mythology": "Anemoi, Shu",
        "colors": ["#0097A7", "#26C6DA"],
        "keywords": "wind, seasons, cyan, nature cycles, flowing air"
    },
    {
        "id": "atlas-orbital",
        "name": "Atlas-Orbital",
        "title": "El Cartógrafo de lo Complejo",
        "archetype": "Cartógrafo Mental",
        "mythology": "Atlas, Polaris",
        "colors": ["#37474F", "#78909C"],
        "keywords": "cosmic map, atlas, stars, navigation, gray blue"
    },
    {
        "id": "erebo-logica",
        "name": "Erebo-Lógica",
        "title": "El Arquitecto de la Sombra que Ordena",
        "archetype": "Arquitecto de Orden",
        "mythology": "Érebo, Nyx",
        "colors": ["#212121", "#616161"],
        "keywords": "shadow, logic, dark order, minimalist, structured"
    },
    {
        "id": "anima-suave",
        "name": "Anima-Suave",
        "title": "La Tejedora de la Compasión Interior",
        "archetype": "Tejedora Compasiva",
        "mythology": "Kuan Yin, Tara Verde",
        "colors": ["#4DD0E1", "#80DEEA"],
        "keywords": "compassion, gentle light, turquoise, healing, serene"
    },
    {
        "id": "morfeo-astral",
        "name": "Morfeo-Astral",
        "title": "El Maestro del Descanso que Restaura",
        "archetype": "Maestro del Sueño",
        "mythology": "Morfeo, Hypnos",
        "colors": ["#283593", "#5C6BC0"],
        "keywords": "dream, sleep, stars, indigo, peaceful rest"
    },
    {
        "id": "shiva-fluido",
        "name": "Shiva-Fluido",
        "title": "El Danzante de la Transformación",
        "archetype": "Transformador",
        "mythology": "Shiva Nataraja",
        "colors": ["#6A1B9A", "#AB47BC"],
        "keywords": "dance, transformation, cosmic purple, energy flow, dynamic"
    },
    {
        "id": "loki-error",
        "name": "Loki-Error",
        "title": "El Sabio del Caos Creativo",
        "archetype": "Sabio Caótico",
        "mythology": "Loki, Eshu, Coyote",
        "colors": ["#D32F2F", "#FF5252"],
        "keywords": "chaos, trickster, red fire, creative disruption, mischief"
    },
    {
        "id": "eris-nucleo",
        "name": "Eris-Núcleo",
        "title": "La Guardiana de la Fuerza que Derriba",
        "archetype": "Guardiana Disruptiva",
        "mythology": "Eris, Kali",
        "colors": ["#C62828", "#F44336"],
        "keywords": "disruption, power, red energy, breakthrough, fierce"
    },
    {
        "id": "anubis-vinculo",
        "name": "Anubis-Vínculo",
        "title": "El Guía del Umbral Compartido",
        "archetype": "Guardián del Umbral",
        "mythology": "Anubis, Psychopompos",
        "colors": ["#1A237E", "#3F51B5"],
        "keywords": "jackal, guardian, deep blue, threshold, guide"
    },
    {
        "id": "zenit-cero",
        "name": "Zenit-Cero",
        "title": "El Observador del Vacío Fértil",
        "archetype": "Observador del Vacío",
        "mythology": "Vacío Primordial, Ain Soph",
        "colors": ["#000000", "#424242"],
        "keywords": "void, emptiness, black space, potential, minimal"
    },
    {
        "id": "oceano-bit",
        "name": "Océano-Bit",
        "title": "El Navegante de las Conexiones Infinitas",
        "archetype": "Navegante Digital",
        "mythology": "Poseidón, Varuna",
        "colors": ["#006064", "#00ACC1"],
        "keywords": "ocean, digital waves, cyan data, network, flowing"
    }
]


def create_prompt_for_guide(guide: Dict) -> str:
    """
    Genera un prompt de Stable Diffusion optimizado para cada guía.
    """
    base_template = (
        "portrait of {name}, {archetype}, "
        "inspired by {mythology}, "
        "{keywords}, "
        "mystical avatar, spiritual guide, "
        "centered composition, "
        "digital art, highly detailed, "
        "fantasy character design, "
        "glowing aura, "
        "professional illustration, "
        "artstation quality, "
        "8k resolution"
    )

    negative_prompt = (
        "ugly, blurry, low quality, distorted, "
        "disfigured, bad anatomy, extra limbs, "
        "text, watermark, signature, "
        "photorealistic, photograph"
    )

    prompt = base_template.format(
        name=guide['name'],
        archetype=guide['archetype'].lower(),
        mythology=guide['mythology'],
        keywords=guide['keywords']
    )

    return prompt, negative_prompt


def generate_image_sd(prompt: str, negative_prompt: str, guide_id: str) -> Path:
    """
    Llama a la API de Stable Diffusion para generar una imagen.
    """
    payload = {
        "prompt": prompt,
        "negative_prompt": negative_prompt,
        "steps": 30,
        "width": 512,
        "height": 512,
        "cfg_scale": 7.5,
        "sampler_name": "DPM++ 2M Karras",
        "seed": -1,
        "batch_size": 1,
    }

    try:
        response = requests.post(
            f"{SD_API_URL}/sdapi/v1/txt2img",
            json=payload,
            timeout=120
        )
        response.raise_for_status()

        result = response.json()

        # Decodificar imagen base64
        import base64
        image_data = base64.b64decode(result['images'][0])
        image = Image.open(io.BytesIO(image_data))

        # Guardar
        output_path = OUTPUT_DIR / f"{guide_id}.png"
        image.save(output_path)

        print(f"✓ Generated: {guide_id}.png")
        return output_path

    except Exception as e:
        print(f"✗ Error generating {guide_id}: {e}")
        return None


def main():
    """
    Genera todos los avatares faltantes.
    """
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Verificar conexión con SD
    print(f"Conectando a Stable Diffusion en {SD_API_URL}...")
    try:
        response = requests.get(f"{SD_API_URL}/sdapi/v1/sd-models", timeout=10)
        response.raise_for_status()
        print("✓ Conexión exitosa con Stable Diffusion\n")
    except Exception as e:
        print(f"✗ Error: No se puede conectar a Stable Diffusion: {e}")
        print("Asegúrate de que el contenedor está corriendo con: docker-compose -f docker-compose-ai.yml up -d")
        return

    # Generar avatares
    existing_avatars = {'aethel', 'crono-velo'}  # Ya existen

    print(f"Generando {len(GUIDES_CATALOG) - len(existing_avatars)} avatares...\n")

    for i, guide in enumerate(GUIDES_CATALOG, 1):
        guide_id = guide['id']

        if guide_id in existing_avatars:
            print(f"[{i}/{len(GUIDES_CATALOG)}] Skipping {guide_id} (already exists)")
            continue

        print(f"[{i}/{len(GUIDES_CATALOG)}] Generating {guide['name']} ({guide_id})...")

        # Crear prompt
        prompt, negative_prompt = create_prompt_for_guide(guide)

        # Guardar prompt para revisión
        prompt_file = OUTPUT_DIR / f"{guide_id}_prompt.txt"
        with open(prompt_file, 'w', encoding='utf-8') as f:
            f.write(f"Positive:\n{prompt}\n\nNegative:\n{negative_prompt}")

        # Generar imagen
        generate_image_sd(prompt, negative_prompt, guide_id)

        # Delay para no saturar la API
        time.sleep(2)

    print("\n✓ Generación completada!")
    print(f"Los avatares están en: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
