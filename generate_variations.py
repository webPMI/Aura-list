#!/usr/bin/env python3
"""
Generación de variaciones de estilo para avatares de AuraList.

Genera 95 imágenes (5 variaciones por cada una de las 19 guías).
Las variaciones incluyen: Ethereal, Anime, Minimal, Watercolor, Art Nouveau

Uso:
    python generate_variations.py                    # Genera todas (95 imágenes)
    python generate_variations.py --style 1          # Solo estilo 1 (19 imágenes)
    python generate_variations.py --guide luna-vacia # Solo una guía (5 imágenes)
    python generate_variations.py --skip-existing    # Salta existentes
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
PROMPTS_FILE = Path("guide_prompts_variations.json")
OUTPUT_DIR = Path("assets/guides/avatars/variations")
DELAY_BETWEEN_REQUESTS = 3.0
MAX_RETRIES = 3


class Colors:
    """Colores ANSI para terminal."""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


class VariationsGenerator:
    """Generador de variaciones de estilo."""

    def __init__(self, style_filter: Optional[int] = None,
                 guide_filter: Optional[str] = None,
                 skip_existing: bool = False):
        self.metadata = {}
        self.guides = []
        self.style_filter = style_filter
        self.guide_filter = guide_filter
        self.skip_existing = skip_existing
        self.results = {
            'success': [],
            'failed': [],
            'skipped': [],
            'total': 0,
            'start_time': None,
            'end_time': None
        }

    def print_header(self, text: str):
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{text.center(70)}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'=' * 70}{Colors.ENDC}\n")

    def print_success(self, text: str):
        print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

    def print_error(self, text: str):
        print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

    def print_warning(self, text: str):
        print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

    def print_info(self, text: str):
        print(f"{Colors.OKCYAN}→ {text}{Colors.ENDC}")

    def load_prompts(self) -> bool:
        """Carga prompts de variaciones."""
        try:
            self.print_info(f"Cargando variaciones desde: {PROMPTS_FILE}")

            if not PROMPTS_FILE.exists():
                self.print_error(f"Archivo no encontrado: {PROMPTS_FILE}")
                return False

            with open(PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)

            self.metadata = data.get('metadata', {})
            self.guides = data.get('guides', [])

            # Aplicar filtros
            if self.guide_filter:
                self.guides = [g for g in self.guides if g['id'] == self.guide_filter]
                if not self.guides:
                    self.print_error(f"No se encontró guía: {self.guide_filter}")
                    return False

            # Calcular total
            total_variations = 0
            for guide in self.guides:
                variations = guide.get('variations', [])
                if self.style_filter:
                    variations = [v for v in variations if v['style'] == self.style_filter]
                total_variations += len(variations)

            self.results['total'] = total_variations

            if total_variations == 0:
                self.print_error("No hay variaciones para generar con los filtros aplicados")
                return False

            self.print_success(f"Cargadas {len(self.guides)} guías, {total_variations} variaciones")

            if self.guide_filter:
                self.print_info(f"Filtro de guía: {self.guide_filter}")
            if self.style_filter:
                style_name = self.metadata['style_descriptions'][f'style_{self.style_filter}']
                self.print_info(f"Filtro de estilo: {self.style_filter} ({style_name})")

            return True

        except json.JSONDecodeError as e:
            self.print_error(f"Error en formato JSON: {e}")
            return False
        except Exception as e:
            self.print_error(f"Error cargando prompts: {e}")
            return False

    def check_api_connection(self) -> bool:
        """Verifica API."""
        try:
            self.print_info("Verificando API...")
            response = requests.get(
                "http://localhost:7860/sdapi/v1/sd-models",
                timeout=10
            )

            if response.status_code == 200:
                self.print_success("API conectada")
                return True
            else:
                self.print_error(f"API error: código {response.status_code}")
                return False

        except requests.exceptions.ConnectionError:
            self.print_error("No se puede conectar a la API")
            self.print_warning("Ejecuta: docker-compose up -d")
            return False
        except Exception as e:
            self.print_error(f"Error: {e}")
            return False

    def image_exists(self, guide_id: str, style: int) -> bool:
        """Verifica si imagen existe."""
        filename = f"{guide_id}_style{style}.png"
        return (OUTPUT_DIR / filename).exists()

    def construct_payload(self, variation: Dict) -> Dict:
        """Construye payload de API."""
        params = self.metadata.get('base_params', {})

        payload = {
            "prompt": variation['prompt'],
            "negative_prompt": self.metadata.get('base_negative', ''),
            "steps": params.get('steps', 30),
            "cfg_scale": params.get('cfg_scale', 7.5),
            "width": params.get('width', 512),
            "height": params.get('height', 512),
            "sampler_name": params.get('sampler', 'DPM++ 2M Karras'),
            "save_images": False,
            "send_images": True,
            "alwayson_scripts": {}
        }

        return payload

    def generate_variation(self, guide: Dict, variation: Dict,
                          current: int, retry: int = 0) -> Tuple[bool, str]:
        """Genera una variación individual."""
        guide_id = guide['id']
        guide_name = guide['name']
        style = variation['style']
        style_name = variation['name']

        retry_text = f" (intento {retry + 1}/{MAX_RETRIES})" if retry > 0 else ""
        print(f"\n{Colors.BOLD}[{current}/{self.results['total']}] {guide_name} - {style_name}{retry_text}{Colors.ENDC}")
        self.print_info(f"Guía: {guide_id} | Estilo: {style}")

        try:
            payload = self.construct_payload(variation)

            self.print_info("Generando...")
            start_time = time.time()

            response = requests.post(API_URL, json=payload, timeout=180)

            if response.status_code != 200:
                error_msg = f"API código {response.status_code}"

                if retry < MAX_RETRIES - 1 and response.status_code >= 500:
                    self.print_warning(f"{error_msg} - Reintentando en 5s...")
                    time.sleep(5)
                    return self.generate_variation(guide, variation, current, retry + 1)

                self.print_error(error_msg)
                return False, error_msg

            result = response.json()

            if 'images' not in result or len(result['images']) == 0:
                error_msg = "Sin imágenes en respuesta"
                self.print_error(error_msg)
                return False, error_msg

            image_data = base64.b64decode(result['images'][0])

            # Guardar con nombre style{N}
            OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
            filename = f"{guide_id}_style{style}.png"
            output_path = OUTPUT_DIR / filename

            with open(output_path, 'wb') as f:
                f.write(image_data)

            duration = time.time() - start_time
            self.print_success(f"Guardado: {filename} ({duration:.1f}s)")

            return True, str(output_path)

        except requests.exceptions.Timeout:
            error_msg = "Timeout"

            if retry < MAX_RETRIES - 1:
                self.print_warning(f"{error_msg} - Reintentando...")
                time.sleep(5)
                return self.generate_variation(guide, variation, current, retry + 1)

            self.print_error(error_msg)
            return False, error_msg

        except Exception as e:
            error_msg = f"Error: {e}"
            self.print_error(error_msg)
            return False, error_msg

    def generate_all(self):
        """Genera todas las variaciones."""
        filter_text = ""
        if self.guide_filter:
            filter_text = f" - Guía: {self.guide_filter}"
        if self.style_filter:
            filter_text += f" - Estilo: {self.style_filter}"

        self.print_header(f"Generando {self.results['total']} variaciones{filter_text}")

        self.results['start_time'] = time.time()
        current = 0

        for guide in self.guides:
            guide_id = guide['id']
            variations = guide.get('variations', [])

            # Filtrar por estilo si aplica
            if self.style_filter:
                variations = [v for v in variations if v['style'] == self.style_filter]

            for variation in variations:
                current += 1
                style = variation['style']

                # Skip si existe
                if self.skip_existing and self.image_exists(guide_id, style):
                    self.print_warning(f"[{current}/{self.results['total']}] Saltando {guide['name']} Style {style}")
                    self.results['skipped'].append({
                        'id': guide_id,
                        'name': guide['name'],
                        'style': style
                    })
                    continue

                # Generar
                success, message = self.generate_variation(guide, variation, current)

                # Registrar
                if success:
                    self.results['success'].append({
                        'id': guide_id,
                        'name': guide['name'],
                        'style': style,
                        'path': message
                    })
                else:
                    self.results['failed'].append({
                        'id': guide_id,
                        'name': guide['name'],
                        'style': style,
                        'error': message
                    })

                # Delay
                if current < self.results['total']:
                    print(f"{Colors.OKCYAN}⏱ Esperando {DELAY_BETWEEN_REQUESTS}s...{Colors.ENDC}")
                    time.sleep(DELAY_BETWEEN_REQUESTS)

        self.results['end_time'] = time.time()

    def print_summary(self):
        """Imprime resumen."""
        duration = self.results['end_time'] - self.results['start_time']
        success_count = len(self.results['success'])
        failed_count = len(self.results['failed'])
        skipped_count = len(self.results['skipped'])

        self.print_header("RESUMEN DE GENERACIÓN")

        print(f"Total variaciones:     {self.results['total']}")
        print(f"{Colors.OKGREEN}✓ Generadas:          {success_count}{Colors.ENDC}")
        print(f"{Colors.FAIL}✗ Fallidas:           {failed_count}{Colors.ENDC}")
        print(f"{Colors.WARNING}⊘ Saltadas:           {skipped_count}{Colors.ENDC}")
        print(f"⏱ Duración:            {duration:.1f}s ({duration/60:.1f} min)")
        print(f"📁 Directorio:         {OUTPUT_DIR}")

        if self.results['success']:
            print(f"\n{Colors.OKGREEN}✓ Generadas ({success_count}):{Colors.ENDC}")
            # Agrupar por guía
            by_guide = {}
            for item in self.results['success']:
                guide_key = item['name']
                if guide_key not in by_guide:
                    by_guide[guide_key] = []
                by_guide[guide_key].append(item['style'])

            for guide_name, styles in by_guide.items():
                styles_str = ', '.join([f"S{s}" for s in sorted(styles)])
                print(f"  • {guide_name}: {styles_str}")

        if self.results['failed']:
            print(f"\n{Colors.FAIL}✗ Fallidas ({failed_count}):{Colors.ENDC}")
            for item in self.results['failed']:
                print(f"  • {item['name']} Style {item['style']}")
                print(f"    Error: {item['error']}")

        print()

        if failed_count == 0 and success_count > 0:
            print(f"{Colors.OKGREEN}{Colors.BOLD}🎉 ¡Todas las variaciones generadas!{Colors.ENDC}\n")
        elif success_count > 0:
            print(f"{Colors.WARNING}⚠ Éxito parcial: {success_count}/{self.results['total']}{Colors.ENDC}\n")
        else:
            print(f"{Colors.FAIL}❌ Todas fallaron{Colors.ENDC}\n")

    def save_log(self):
        """Guarda log."""
        log_file = OUTPUT_DIR / f"variations_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        try:
            with open(log_file, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, indent=2, ensure_ascii=False)
            self.print_success(f"Log: {log_file}")
        except Exception as e:
            self.print_warning(f"No se pudo guardar log: {e}")

    def run(self) -> int:
        """Ejecución principal."""
        self.print_header("🎨 Generador de Variaciones de Estilo")

        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

        if not self.load_prompts():
            return 1

        if not self.check_api_connection():
            return 1

        self.generate_all()
        self.print_summary()
        self.save_log()

        return 0 if len(self.results['failed']) == 0 else 1


def main():
    parser = argparse.ArgumentParser(
        description='Genera variaciones de estilo para avatares'
    )
    parser.add_argument(
        '--style',
        type=int,
        choices=[1, 2, 3, 4, 5],
        help='Genera solo un estilo específico (1-5)'
    )
    parser.add_argument(
        '--guide',
        type=str,
        help='Genera solo una guía específica (ej: luna-vacia)'
    )
    parser.add_argument(
        '--skip-existing',
        action='store_true',
        help='Salta imágenes existentes'
    )

    args = parser.parse_args()

    generator = VariationsGenerator(
        style_filter=args.style,
        guide_filter=args.guide,
        skip_existing=args.skip_existing
    )

    exit_code = generator.run()
    exit(exit_code)


if __name__ == "__main__":
    main()
