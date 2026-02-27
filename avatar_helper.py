#!/usr/bin/env python3
"""
Helper script para gestión de generación de avatares.

Comandos:
    python avatar_helper.py start          # Inicia Docker
    python avatar_helper.py stop           # Detiene Docker
    python avatar_helper.py status         # Estado de Docker y API
    python avatar_helper.py generate       # Genera avatares base (menú interactivo)
    python avatar_helper.py verify         # Verifica avatares
    python avatar_helper.py clean          # Limpia logs antiguos
"""

import subprocess
import sys
import json
import requests
from pathlib import Path
import argparse


class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(70)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}\n")


def print_success(text):
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")


def print_error(text):
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")


def print_warning(text):
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")


def print_info(text):
    print(f"{Colors.OKCYAN}→ {text}{Colors.ENDC}")


def run_command(cmd, description=None):
    """Ejecuta comando shell."""
    if description:
        print_info(description)

    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.returncode == 0, result.stdout, result.stderr


def check_docker_running():
    """Verifica si Docker está corriendo."""
    success, stdout, _ = run_command("docker ps", "Verificando Docker...")
    if success and "auralist-sd-webui" in stdout:
        print_success("Docker container corriendo")
        return True
    else:
        print_warning("Docker container no está corriendo")
        return False


def check_api_ready():
    """Verifica si API está lista."""
    try:
        print_info("Verificando API...")
        response = requests.get("http://localhost:7860/sdapi/v1/sd-models", timeout=5)
        if response.status_code == 200:
            models = response.json()
            if models:
                model_name = models[0].get('model_name', 'unknown')
                print_success(f"API lista - Modelo: {model_name}")
            else:
                print_success("API lista")
            return True
        else:
            print_warning("API no responde correctamente")
            return False
    except requests.exceptions.ConnectionError:
        print_warning("API no accesible")
        return False
    except Exception as e:
        print_error(f"Error verificando API: {e}")
        return False


def start_docker():
    """Inicia Docker compose."""
    print_header("Iniciando Stable Diffusion WebUI")

    success, stdout, stderr = run_command(
        "docker-compose up -d",
        "Levantando containers..."
    )

    if success:
        print_success("Container iniciado")
        print_info("Esperando a que API esté lista...")
        print_info("Esto puede tardar 2-3 minutos...")
        print_info("WebUI disponible en: http://localhost:7860")
        return True
    else:
        print_error("Error iniciando container")
        print(stderr)
        return False


def stop_docker():
    """Detiene Docker compose."""
    print_header("Deteniendo Stable Diffusion WebUI")

    success, stdout, stderr = run_command(
        "docker-compose down",
        "Deteniendo containers..."
    )

    if success:
        print_success("Container detenido")
        return True
    else:
        print_error("Error deteniendo container")
        print(stderr)
        return False


def show_status():
    """Muestra estado completo del sistema."""
    print_header("Estado del Sistema")

    # Docker
    print(f"{Colors.BOLD}Docker:{Colors.ENDC}")
    docker_running = check_docker_running()

    # API
    print(f"\n{Colors.BOLD}API:{Colors.ENDC}")
    api_ready = False
    if docker_running:
        api_ready = check_api_ready()
    else:
        print_warning("API no disponible (Docker no corriendo)")

    # Archivos
    print(f"\n{Colors.BOLD}Archivos:{Colors.ENDC}")

    base_prompts = Path("guide_prompts.json")
    var_prompts = Path("guide_prompts_variations.json")

    if base_prompts.exists():
        print_success(f"Prompts base: {base_prompts}")
    else:
        print_error(f"Falta: {base_prompts}")

    if var_prompts.exists():
        print_success(f"Prompts variaciones: {var_prompts}")
    else:
        print_error(f"Falta: {var_prompts}")

    # Avatares generados
    print(f"\n{Colors.BOLD}Avatares Generados:{Colors.ENDC}")

    base_dir = Path("assets/guides/avatars")
    var_dir = Path("assets/guides/avatars/variations")

    if base_dir.exists():
        base_count = len(list(base_dir.glob("*.png")))
        print_info(f"Base: {base_count}/19 imágenes")
    else:
        print_warning("Directorio base no existe")

    if var_dir.exists():
        var_count = len(list(var_dir.glob("*.png")))
        print_info(f"Variaciones: {var_count}/95 imágenes")
    else:
        print_warning("Directorio variaciones no existe")

    # Resumen
    print()
    if docker_running and api_ready:
        print_success("Sistema listo para generar avatares")
    elif docker_running:
        print_warning("Docker corriendo pero API no lista (espera 1-2 min)")
    else:
        print_warning("Ejecuta: python avatar_helper.py start")
    print()


def interactive_generate():
    """Menú interactivo para generar avatares."""
    print_header("Generador de Avatares")

    # Verificar sistema
    if not check_docker_running():
        print_error("Docker no está corriendo")
        response = input("¿Iniciar Docker ahora? (s/n): ")
        if response.lower() == 's':
            start_docker()
            print_info("Espera 2-3 minutos antes de generar...")
            return
        else:
            return

    if not check_api_ready():
        print_error("API no está lista")
        print_warning("Espera 1-2 minutos y vuelve a intentar")
        return

    # Menú
    print(f"{Colors.BOLD}¿Qué deseas generar?{Colors.ENDC}\n")
    print("1. Avatares base (19 imágenes, ~5-10 min)")
    print("2. Todas las variaciones (95 imágenes, ~1-2 horas)")
    print("3. Variaciones - Solo estilo 1 (19 imágenes)")
    print("4. Variaciones - Solo estilo 2 (19 imágenes)")
    print("5. Variaciones - Solo estilo 3 (19 imágenes)")
    print("6. Variaciones - Solo estilo 4 (19 imágenes)")
    print("7. Variaciones - Solo estilo 5 (19 imágenes)")
    print("8. Prueba - Solo una guía (5 variaciones)")
    print("0. Cancelar")

    choice = input("\nOpción: ").strip()

    commands = {
        "1": "python generate_all_avatars.py --skip-existing",
        "2": "python generate_variations.py --skip-existing",
        "3": "python generate_variations.py --style 1 --skip-existing",
        "4": "python generate_variations.py --style 2 --skip-existing",
        "5": "python generate_variations.py --style 3 --skip-existing",
        "6": "python generate_variations.py --style 4 --skip-existing",
        "7": "python generate_variations.py --style 5 --skip-existing",
        "8": "python generate_variations.py --guide luna-vacia --skip-existing",
    }

    if choice == "0":
        print_info("Cancelado")
        return

    if choice not in commands:
        print_error("Opción inválida")
        return

    cmd = commands[choice]
    print(f"\n{Colors.BOLD}Ejecutando:{Colors.ENDC} {cmd}\n")

    subprocess.run(cmd, shell=True)


def verify_avatars():
    """Ejecuta verificación."""
    print_header("Verificando Avatares")

    print("¿Qué verificar?\n")
    print("1. Solo base")
    print("2. Solo variaciones")
    print("3. Todo")

    choice = input("\nOpción (default=3): ").strip() or "3"

    commands = {
        "1": "python verify_all_avatars.py",
        "2": "python verify_all_avatars.py --variations",
        "3": "python verify_all_avatars.py --all",
    }

    if choice in commands:
        subprocess.run(commands[choice], shell=True)
    else:
        print_error("Opción inválida")


def clean_logs():
    """Limpia logs antiguos."""
    print_header("Limpiando Logs Antiguos")

    base_dir = Path("assets/guides/avatars")
    var_dir = Path("assets/guides/avatars/variations")

    count = 0

    for log_file in base_dir.glob("generation_log_*.json"):
        log_file.unlink()
        count += 1
        print_info(f"Eliminado: {log_file.name}")

    for log_file in var_dir.glob("variations_log_*.json"):
        log_file.unlink()
        count += 1
        print_info(f"Eliminado: {log_file.name}")

    if count > 0:
        print_success(f"Eliminados {count} logs")
    else:
        print_info("No hay logs para eliminar")


def main():
    parser = argparse.ArgumentParser(
        description='Helper para gestión de avatares',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  python avatar_helper.py start      # Inicia Docker
  python avatar_helper.py generate   # Menú de generación
  python avatar_helper.py status     # Ver estado
        """
    )

    parser.add_argument(
        'command',
        choices=['start', 'stop', 'status', 'generate', 'verify', 'clean'],
        help='Comando a ejecutar'
    )

    args = parser.parse_args()

    commands = {
        'start': start_docker,
        'stop': stop_docker,
        'status': show_status,
        'generate': interactive_generate,
        'verify': verify_avatars,
        'clean': clean_logs,
    }

    commands[args.command]()


if __name__ == "__main__":
    main()
