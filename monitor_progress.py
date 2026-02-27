#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Monitor del progreso de descarga de Stable Diffusion."""

import subprocess
import time
import re
import sys

def get_download_progress():
    """Obtiene el progreso de descarga de los logs."""
    result = subprocess.run(
        ["docker-compose", "logs", "--tail=10", "stable-diffusion-webui"],
        capture_output=True,
        text=True
    )

    # Buscar líneas con porcentaje
    for line in result.stdout.split('\n'):
        # Buscar patrón tipo: "2%|▏         | 77.5M/3.97G"
        match = re.search(r'(\d+)%\|.*?\|\s*([\d.]+[MG])\/([\d.]+G)', line)
        if match:
            percent = match.group(1)
            current = match.group(2)
            total = match.group(3)
            return percent, current, total

    return None, None, None

def check_if_ready():
    """Verifica si la API está lista."""
    import requests
    try:
        response = requests.get("http://localhost:7860/sdapi/v1/sd-models", timeout=2)
        return response.status_code == 200
    except:
        return False

def main():
    print("Monitoreando descarga de Stable Diffusion WebUI...\n")
    print("Esto puede tardar 10-15 minutos en la primera ejecución.")
    print("Presiona Ctrl+C para salir\n")

    last_percent = None

    try:
        while True:
            # Verificar si ya está listo
            if check_if_ready():
                print("\n✓ API lista!")
                print("Ya puedes generar imágenes.")
                break

            # Obtener progreso
            percent, current, total = get_download_progress()

            if percent and percent != last_percent:
                print(f"Progreso: {percent}% ({current} / {total})")
                last_percent = percent
            elif last_percent is None:
                print("Iniciando descarga...")

            time.sleep(5)

    except KeyboardInterrupt:
        print("\n\nMonitoreo detenido.")
        print("Docker sigue corriendo en segundo plano.")
        print("Verifica manualmente: http://localhost:7860")

if __name__ == "__main__":
    main()
