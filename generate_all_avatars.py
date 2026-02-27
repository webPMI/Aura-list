#!/usr/bin/env python3
"""
Generación automatizada de avatares para AuraList usando Stable Diffusion WebUI API.

Genera las 19 imágenes de avatares base usando guide_prompts.json.
Para generar variaciones de estilo (95 imágenes), usa generate_variations.py

Uso:
    python generate_all_avatars.py
    python generate_all_avatars.py --resume  # Continúa desde donde se detuvo
    python generate_all_avatars.py --skip-existing  # Salta imágenes ya generadas
"""

import json
import base64
import time
import requests
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime

# Configuración
API_URL = "http://localhost:7860/sdapi/v1/txt2img"
PROMPTS_FILE = Path("guide_prompts.json")
OUTPUT_DIR = Path("assets/guides/avatars")
DELAY_BETWEEN_REQUESTS = 3.0  # segundos entre cada generación
MAX_RETRIES = 3  # Intentos por imagen en caso de fallo


class Colors:
    """Colores ANSI para output en terminal."""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


class AvatarGenerator:
    """Generador de avatares usando Stable Diffusion WebUI API."""

    def __init__(self, skip_existing: bool = False, resume: bool = False):
        self.config = {}
        self.guides = []
        self.skip_existing = skip_existing
        self.resume = resume
        self.results = {
            'success': [],
            'failed': [],
            'skipped': [],
            'total': 0,
            'start_time': None,
            'end_time': None
        }

    def print_header(self, text: str):
        """Imprime encabezado con estilo."""
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{text.center(70)}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}\n")

    def print_success(self, text: str):
        """Imprime mensaje de éxito."""
        print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

    def print_error(self, text: str):
        """Imprime mensaje de error."""
        print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

    def print_warning(self, text: str):
        """Imprime mensaje de advertencia."""
        print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

    def print_info(self, text: str):
        """Imprime mensaje informativo."""
        print(f"{Colors.OKCYAN}→ {text}{Colors.ENDC}")

    def load_prompts(self) -> bool:
        """Carga prompts desde guide_prompts.json."""
        try:
            self.print_info(f"Cargando prompts desde: {PROMPTS_FILE}")

            if not PROMPTS_FILE.exists():
                self.print_error(f"Archivo no encontrado: {PROMPTS_FILE}")
                return False

            with open(PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)

            self.config = data.get('config', {})
            self.guides = data.get('guides', [])
            self.results['total'] = len(self.guides)

            if not self.guides:
                self.print_error("No se encontraron guías en el archivo JSON")
                return False

            self.print_success(f"Cargadas {len(self.guides)} guías")
            self.print_info(f"Configuración: {self.config.get('steps', 30)} steps, CFG {self.config.get('cfg_scale', 7.5)}, {self.config.get('sampler', 'DPM++ 2M Karras')}")
            return True

        except json.JSONDecodeError as e:
            self.print_error(f"Error en formato JSON: {e}")
            return False
        except Exception as e:
            self.print_error(f"Error cargando prompts: {e}")
            return False

    def check_api_connection(self) -> bool:
        """Verifica que la API de SD WebUI esté disponible."""
        try:
            self.print_info(f"Verificando conexión con API...")

            # Ping al endpoint de modelos
            response = requests.get(
                "http://localhost:7860/sdapi/v1/sd-models",
                timeout=10
            )

            if response.status_code == 200:
                models = response.json()
                if models:
                    model_name = models[0].get('model_name', 'unknown')
                    self.print_success(f"API conectada - Modelo: {model_name}")
                else:
                    self.print_success("API conectada")
                return True
            else:
                self.print_error(f"API retornó código: {response.status_code}")
                return False

        except requests.exceptions.ConnectionError:
            self.print_error("No se puede conectar a la API")
            self.print_warning("Asegúrate de que Stable Diffusion WebUI esté corriendo:")
            self.print_warning("  docker-compose up -d")
            self.print_warning("  O inicia manualmente: webui.bat --api")
            return False
        except Exception as e:
            self.print_error(f"Error verificando API: {e}")
            return False

    def image_exists(self, guide_id: str) -> bool:
        """Verifica si la imagen ya existe."""
        output_path = OUTPUT_DIR / f"{guide_id}.png"
        return output_path.exists()

    def construct_payload(self, guide: Dict) -> Dict:
        """Construye el payload para la API request."""
        # Combinar prompt del guide con estilo base
        full_prompt = f"{guide['prompt']}, {self.config.get('base_style', '')}"

        payload = {
            "prompt": full_prompt,
            "negative_prompt": self.config.get('negative_prompt', ''),
            "steps": self.config.get('steps', 30),
            "cfg_scale": self.config.get('cfg_scale', 7.5),
            "width": self.config.get('width', 512),
            "height": self.config.get('height', 512),
            "sampler_name": self.config.get('sampler', 'DPM++ 2M Karras'),
            "save_images": False,
            "send_images": True,
            "alwayson_scripts": {}
        }

        return payload

    def generate_image(self, guide: Dict, index: int, retry: int = 0) -> Tuple[bool, str]:
        """
        Genera una imagen individual.

        Returns:
            (success: bool, message: str)
        """
        guide_id = guide['id']
        guide_name = guide['name']

        retry_text = f" (intento {retry + 1}/{MAX_RETRIES})" if retry > 0 else ""
        print(f"\n{Colors.BOLD}[{index + 1}/{self.results['total']}] {guide_name}{retry_text}{Colors.ENDC}")
        self.print_info(f"ID: {guide_id}")

        try:
            # Construir payload
            payload = self.construct_payload(guide)

            # Enviar request a la API
            self.print_info("Enviando request a API...")
            start_time = time.time()

            response = requests.post(
                API_URL,
                json=payload,
                timeout=180  # 3 minutos timeout
            )

            if response.status_code != 200:
                error_msg = f"API retornó código {response.status_code}"

                # Reintentar en ciertos casos
                if retry < MAX_RETRIES - 1 and response.status_code >= 500:
                    self.print_warning(f"{error_msg} - Reintentando en 5s...")
                    time.sleep(5)
                    return self.generate_image(guide, index, retry + 1)

                self.print_error(error_msg)
                return False, error_msg

            # Parsear respuesta
            result = response.json()

            if 'images' not in result or len(result['images']) == 0:
                error_msg = "No hay imágenes en la respuesta"
                self.print_error(error_msg)
                return False, error_msg

            # Decodificar imagen base64
            image_data = base64.b64decode(result['images'][0])

            # Guardar imagen
            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            output_path = OUTPUT_DIR / f"{guide_id}.png"

            with open(output_path, 'wb') as f:
                f.write(image_data)

            duration = time.time() - start_time
            self.print_success(f"Guardado: {output_path.name} ({duration:.1f}s)")

            return True, str(output_path)

        except requests.exceptions.Timeout:
            error_msg = "Timeout (>180s)"

            # Reintentar
            if retry < MAX_RETRIES - 1:
                self.print_warning(f"{error_msg} - Reintentando...")
                time.sleep(5)
                return self.generate_image(guide, index, retry + 1)

            self.print_error(error_msg)
            return False, error_msg

        except requests.exceptions.RequestException as e:
            error_msg = f"Error de red: {e}"
            self.print_error(error_msg)
            return False, error_msg

        except Exception as e:
            error_msg = f"Error inesperado: {e}"
            self.print_error(error_msg)
            return False, error_msg

    def generate_all(self):
        """Genera todas las imágenes de avatares."""
        self.print_header(f"Generando {self.results['total']} avatares")

        self.results['start_time'] = time.time()

        for index, guide in enumerate(self.guides):
            guide_id = guide['id']

            # Skip si ya existe y está habilitado
            if self.skip_existing and self.image_exists(guide_id):
                self.print_warning(f"[{index + 1}/{self.results['total']}] Saltando {guide['name']} (ya existe)")
                self.results['skipped'].append({
                    'id': guide_id,
                    'name': guide['name']
                })
                continue

            # Generar imagen
            success, message = self.generate_image(guide, index)

            # Registrar resultado
            if success:
                self.results['success'].append({
                    'id': guide_id,
                    'name': guide['name'],
                    'path': message
                })
            else:
                self.results['failed'].append({
                    'id': guide_id,
                    'name': guide['name'],
                    'error': message
                })

            # Delay entre requests (excepto en el último)
            if index < len(self.guides) - 1:
                print(f"{Colors.OKCYAN}⏱ Esperando {DELAY_BETWEEN_REQUESTS}s...{Colors.ENDC}")
                time.sleep(DELAY_BETWEEN_REQUESTS)

        self.results['end_time'] = time.time()

    def print_summary(self):
        """Imprime resumen de generación."""
        duration = self.results['end_time'] - self.results['start_time']
        success_count = len(self.results['success'])
        failed_count = len(self.results['failed'])
        skipped_count = len(self.results['skipped'])

        self.print_header("RESUMEN DE GENERACIÓN")

        print(f"Total de guías:        {self.results['total']}")
        print(f"{Colors.OKGREEN}✓ Generadas:          {success_count}{Colors.ENDC}")
        print(f"{Colors.FAIL}✗ Fallidas:           {failed_count}{Colors.ENDC}")
        print(f"{Colors.WARNING}⊘ Saltadas:           {skipped_count}{Colors.ENDC}")
        print(f"⏱ Duración:            {duration:.1f}s ({duration/60:.1f} min)")
        print(f"📁 Directorio salida:  {OUTPUT_DIR}")

        if self.results['success']:
            print(f"\n{Colors.OKGREEN}✓ Generadas exitosamente ({success_count}):{Colors.ENDC}")
            for item in self.results['success']:
                print(f"  • {item['name']} ({item['id']}.png)")

        if self.results['skipped']:
            print(f"\n{Colors.WARNING}⊘ Saltadas ({skipped_count}):{Colors.ENDC}")
            for item in self.results['skipped']:
                print(f"  • {item['name']} ({item['id']})")

        if self.results['failed']:
            print(f"\n{Colors.FAIL}✗ Fallidas ({failed_count}):{Colors.ENDC}")
            for item in self.results['failed']:
                print(f"  • {item['name']} ({item['id']})")
                print(f"    Error: {item['error']}")

        print()

        # Mensaje final
        if failed_count == 0 and success_count > 0:
            print(f"{Colors.OKGREEN}{Colors.BOLD}🎉 ¡Todas las imágenes generadas exitosamente!{Colors.ENDC}\n")
        elif success_count > 0:
            print(f"{Colors.WARNING}⚠ Éxito parcial: {success_count}/{self.results['total']} completadas{Colors.ENDC}\n")
        else:
            print(f"{Colors.FAIL}❌ Todas las generaciones fallaron{Colors.ENDC}\n")

    def save_log(self):
        """Guarda log de generación."""
        log_file = OUTPUT_DIR / f"generation_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
            self.print_success(f"Log guardado: {log_file}")
        except Exception as e:
            self.print_warning(f"No se pudo guardar log: {e}")

    def run(self) -> int:
        """Flujo principal de ejecución."""
        self.print_header("🎨 Generador de Avatares AuraList")
        print(f"{Colors.OKCYAN}Usando Stable Diffusion WebUI API{Colors.ENDC}\n")

        # Crear directorio de salida
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

        # Cargar prompts
        if not self.load_prompts():
            return 1

        # Verificar API
        if not self.check_api_connection():
            return 1

        # Generar todas las imágenes
        self.generate_all()

        # Imprimir resumen
        self.print_summary()

        # Guardar log
        self.save_log()

        # Retornar código de salida
        return 0 if len(self.results['failed']) == 0 else 1


def main():
    """Punto de entrada."""
    parser = argparse.ArgumentParser(
        description='Genera avatares de guías usando Stable Diffusion'
    )
    parser.add_argument(
        '--skip-existing',
        action='store_true',
        help='Salta imágenes que ya existen'
    )
    parser.add_argument(
        '--resume',
        action='store_true',
        help='Continúa desde donde se detuvo (alias de --skip-existing)'
    )

    args = parser.parse_args()

    # Resume es alias de skip-existing
    skip = args.skip_existing or args.resume

    generator = AvatarGenerator(skip_existing=skip)
    exit_code = generator.run()
    exit(exit_code)


if __name__ == "__main__":
    main()
