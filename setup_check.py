#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Verificador de setup para generación de avatares.
Comprueba que todo esté listo antes de generar imágenes.
"""

import sys
import subprocess
import shutil
from pathlib import Path
import io

# Fix encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


class Colors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def check(name, condition, fix_hint=None):
    """Verifica una condición."""
    status = "✓" if condition else "✗"
    color = Colors.OKGREEN if condition else Colors.FAIL

    print(f"{color}{status}{Colors.ENDC} {name}")

    if not condition and fix_hint:
        print(f"  {Colors.WARNING}→ {fix_hint}{Colors.ENDC}")

    return condition


def main():
    print(f"\n{Colors.BOLD}=== Verificación de Setup para Generación de Avatares ==={Colors.ENDC}\n")

    all_ok = True

    # Python
    print(f"{Colors.BOLD}Python:{Colors.ENDC}")
    python_version = sys.version_info
    python_ok = python_version.major == 3 and python_version.minor >= 8
    all_ok &= check(
        f"Python {python_version.major}.{python_version.minor}.{python_version.micro}",
        python_ok,
        "Requiere Python 3.8 o superior"
    )

    # Módulos Python
    print(f"\n{Colors.BOLD}Módulos Python:{Colors.ENDC}")

    try:
        import requests
        all_ok &= check("requests", True)
    except ImportError:
        all_ok &= check("requests", False, "pip install requests")

    try:
        from PIL import Image
        all_ok &= check("pillow", True)
    except ImportError:
        all_ok &= check("pillow", False, "pip install pillow")

    # Docker
    print(f"\n{Colors.BOLD}Docker:{Colors.ENDC}")

    docker_cmd = shutil.which("docker")
    all_ok &= check(
        "docker",
        docker_cmd is not None,
        "Instala Docker Desktop: https://www.docker.com/products/docker-desktop"
    )

    if docker_cmd:
        result = subprocess.run(
            ["docker", "--version"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            version = result.stdout.strip()
            print(f"  {Colors.WARNING}→ {version}{Colors.ENDC}")

    compose_cmd = shutil.which("docker-compose")
    all_ok &= check(
        "docker-compose",
        compose_cmd is not None,
        "Incluido con Docker Desktop"
    )

    # Archivos necesarios
    print(f"\n{Colors.BOLD}Archivos de Configuración:{Colors.ENDC}")

    files_to_check = [
        ("docker-compose.yml", "Configuración Docker"),
        ("guide_prompts.json", "Prompts base (19 guías)"),
        ("guide_prompts_variations.json", "Prompts variaciones (95)"),
        ("generate_all_avatars.py", "Script generación base"),
        ("generate_variations.py", "Script generación variaciones"),
        ("verify_all_avatars.py", "Script verificación"),
    ]

    for filename, description in files_to_check:
        exists = Path(filename).exists()
        all_ok &= check(
            f"{filename} - {description}",
            exists,
            f"Archivo faltante: {filename}"
        )

    # Directorios
    print(f"\n{Colors.BOLD}Directorios:{Colors.ENDC}")

    assets_dir = Path("assets/guides/avatars")
    check("assets/guides/avatars/", assets_dir.exists())
    if not assets_dir.exists():
        print(f"  {Colors.WARNING}→ Se creará automáticamente al generar{Colors.ENDC}")

    # Espacio en disco
    print(f"\n{Colors.BOLD}Espacio en Disco:{Colors.ENDC}")

    if sys.platform == "win32":
        import ctypes
        free_bytes = ctypes.c_ulonglong(0)
        ctypes.windll.kernel32.GetDiskFreeSpaceExW(
            ctypes.c_wchar_p("."),
            None,
            None,
            ctypes.pointer(free_bytes)
        )
        free_gb = free_bytes.value / (1024**3)
    else:
        stat = shutil.disk_usage(".")
        free_gb = stat.free / (1024**3)

    disk_ok = free_gb >= 10
    all_ok &= check(
        f"Espacio disponible: {free_gb:.1f} GB",
        disk_ok,
        "Necesitas al menos 10GB libres (modelos SD + imágenes)"
    )

    # GPU (opcional)
    print(f"\n{Colors.BOLD}GPU (Opcional):{Colors.ENDC}")

    if docker_cmd:
        try:
            result = subprocess.run(
                ["docker", "run", "--rm", "--gpus", "all", "nvidia/cuda:11.8.0-base-ubuntu22.04", "nvidia-smi"],
                capture_output=True,
                text=True,
                timeout=5
            )
            gpu_ok = result.returncode == 0

            if gpu_ok:
                check("GPU NVIDIA detectada", True)
                print(f"  {Colors.WARNING}→ Generación será rápida (~30s por imagen){Colors.ENDC}")
            else:
                check("GPU NVIDIA", False)
                print(f"  {Colors.WARNING}→ Sin GPU, usará CPU (más lento: ~5-10 min por imagen){Colors.ENDC}")
                print(f"  {Colors.WARNING}→ La generación seguirá funcionando, solo será más lenta{Colors.ENDC}")
        except subprocess.TimeoutExpired:
            check("GPU NVIDIA", False)
            print(f"  {Colors.WARNING}→ No se pudo verificar GPU (timeout){Colors.ENDC}")
            print(f"  {Colors.WARNING}→ Si tienes GPU, se usará automáticamente al iniciar Docker{Colors.ENDC}")
    else:
        check("GPU (Docker no disponible)", False)

    # Resumen
    print(f"\n{Colors.BOLD}{'=' * 60}{Colors.ENDC}")

    if all_ok:
        print(f"{Colors.OKGREEN}{Colors.BOLD}✓ Sistema listo para generar avatares{Colors.ENDC}\n")
        print("Siguiente paso:")
        print("  python avatar_helper.py start    # Inicia Docker")
        print("  python avatar_helper.py generate # Genera avatares")
    else:
        print(f"{Colors.FAIL}{Colors.BOLD}✗ Hay problemas que resolver{Colors.ENDC}\n")
        print("Revisa los errores arriba y sigue las sugerencias de solución.")

    print(f"{Colors.BOLD}{'=' * 60}{Colors.ENDC}\n")

    return 0 if all_ok else 1


if __name__ == "__main__":
    exit(main())
