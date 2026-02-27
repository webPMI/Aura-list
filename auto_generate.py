#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto-generador: Espera a que SD esté listo y genera automáticamente.
"""

import subprocess
import time
import requests
import sys
import io

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def check_api_ready():
    """Verifica si la API está lista."""
    try:
        response = requests.get("http://localhost:7860/sdapi/v1/sd-models", timeout=5)
        return response.status_code == 200
    except:
        return False

def wait_for_api(max_wait_minutes=30):
    """Espera a que la API esté lista."""
    print("⏳ Esperando a que Stable Diffusion WebUI esté listo...")
    print(f"   Máximo de espera: {max_wait_minutes} minutos")
    print("   (Primera vez descarga modelos ~4GB, puede tardar)\n")

    start_time = time.time()
    max_wait_seconds = max_wait_minutes * 60
    check_interval = 10  # segundos

    while True:
        elapsed = time.time() - start_time

        if elapsed > max_wait_seconds:
            print("\n✗ Timeout esperando a la API")
            print("  El contenedor sigue corriendo, verifica manualmente:")
            print("  docker-compose logs -f")
            return False

        if check_api_ready():
            print("\n✓ API lista!")
            return True

        minutes_elapsed = int(elapsed / 60)
        seconds_elapsed = int(elapsed % 60)
        print(f"⏱  Esperando... ({minutes_elapsed}m {seconds_elapsed}s)", end='\r')

        time.sleep(check_interval)

def generate_images(guide_id=None):
    """Genera imágenes."""
    print("\n🎨 Iniciando generación de imágenes...\n")

    if guide_id:
        # Generar solo una guía (5 variaciones)
        cmd = f"python generate_variations.py --guide {guide_id}"
        print(f"Generando variaciones para: {guide_id}")
    else:
        # Generar todas las base (19 imágenes)
        cmd = "python generate_all_avatars.py --skip-existing"
        print("Generando 19 avatares base")

    print(f"Comando: {cmd}\n")

    # Ejecutar generación
    result = subprocess.run(cmd, shell=True)

    if result.returncode == 0:
        print("\n✓ Generación completada")
        return True
    else:
        print("\n✗ Error en la generación")
        return False

def main():
    import argparse

    parser = argparse.ArgumentParser(description='Espera a SD y genera automáticamente')
    parser.add_argument('--guide', type=str, help='ID de guía específica (ej: luna-vacia)')
    parser.add_argument('--wait', type=int, default=30, help='Minutos máximos de espera (default: 30)')

    args = parser.parse_args()

    print("=" * 70)
    print("🤖 Auto-Generador de Avatares")
    print("=" * 70)

    # Esperar a que API esté lista
    if not wait_for_api(max_wait_minutes=args.wait):
        sys.exit(1)

    # Generar imágenes
    time.sleep(2)  # Pequeña pausa
    success = generate_images(guide_id=args.guide)

    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
