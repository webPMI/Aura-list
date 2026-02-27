#!/usr/bin/env python3
"""
Verificador de avatares generados para AuraList.

Verifica que todas las imágenes existan, tengan el tamaño correcto,
y estén en formato PNG válido.

Uso:
    python verify_all_avatars.py              # Verifica avatares base
    python verify_all_avatars.py --variations # Verifica variaciones
    python verify_all_avatars.py --all        # Verifica todo
"""

import json
import argparse
from pathlib import Path
from typing import List, Dict, Tuple
from PIL import Image

# Configuración
BASE_PROMPTS_FILE = Path("guide_prompts.json")
VARIATIONS_PROMPTS_FILE = Path("guide_prompts_variations.json")
BASE_OUTPUT_DIR = Path("assets/guides/avatars")
VARIATIONS_OUTPUT_DIR = Path("assets/guides/avatars/variations")


class Colors:
    """Colores ANSI."""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


class AvatarVerifier:
    """Verificador de avatares."""

    def __init__(self, check_base: bool = True, check_variations: bool = False):
        self.check_base = check_base
        self.check_variations = check_variations
        self.results = {
            'base': {
                'total': 0,
                'found': 0,
                'missing': [],
                'invalid': [],
                'wrong_size': [],
                'valid': []
            },
            'variations': {
                'total': 0,
                'found': 0,
                'missing': [],
                'invalid': [],
                'wrong_size': [],
                'valid': []
            }
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

    def verify_image(self, image_path: Path, expected_size: Tuple[int, int] = (512, 512)) -> Dict:
        """
        Verifica una imagen individual.

        Returns:
            {
                'exists': bool,
                'valid': bool,
                'correct_size': bool,
                'actual_size': (width, height),
                'file_size_kb': float,
                'error': str | None
            }
        """
        result = {
            'exists': image_path.exists(),
            'valid': False,
            'correct_size': False,
            'actual_size': None,
            'file_size_kb': 0,
            'error': None
        }

        if not result['exists']:
            result['error'] = 'Archivo no existe'
            return result

        try:
            # Obtener tamaño de archivo
            result['file_size_kb'] = image_path.stat().st_size / 1024

            # Abrir imagen con PIL
            with Image.open(image_path) as img:
                result['valid'] = True
                result['actual_size'] = img.size
                result['correct_size'] = img.size == expected_size

                if not result['correct_size']:
                    result['error'] = f"Tamaño incorrecto: {img.size} (esperado {expected_size})"

        except Exception as e:
            result['error'] = f"Error abriendo imagen: {str(e)}"

        return result

    def verify_base_avatars(self):
        """Verifica avatares base (19 imágenes)."""
        self.print_header("Verificando Avatares Base")

        try:
            # Cargar prompts
            with open(BASE_PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)

            guides = data.get('guides', [])
            config = data.get('config', {})
            expected_size = (config.get('width', 512), config.get('height', 512))

            self.results['base']['total'] = len(guides)

            self.print_info(f"Verificando {len(guides)} avatares base en: {BASE_OUTPUT_DIR}")
            print()

            for guide in guides:
                guide_id = guide['id']
                guide_name = guide['name']
                image_path = BASE_OUTPUT_DIR / f"{guide_id}.png"

                # Verificar imagen
                verify_result = self.verify_image(image_path, expected_size)

                # Imprimir resultado
                if verify_result['exists']:
                    self.results['base']['found'] += 1

                    if verify_result['valid'] and verify_result['correct_size']:
                        self.results['base']['valid'].append(guide_id)
                        size_kb = verify_result['file_size_kb']
                        self.print_success(f"{guide_name}: {guide_id}.png ({size_kb:.1f} KB)")
                    elif verify_result['valid'] and not verify_result['correct_size']:
                        self.results['base']['wrong_size'].append({
                            'id': guide_id,
                            'name': guide_name,
                            'actual_size': verify_result['actual_size'],
                            'expected_size': expected_size
                        })
                        actual = verify_result['actual_size']
                        self.print_warning(f"{guide_name}: Tamaño {actual} (esperado {expected_size})")
                    else:
                        self.results['base']['invalid'].append({
                            'id': guide_id,
                            'name': guide_name,
                            'error': verify_result['error']
                        })
                        self.print_error(f"{guide_name}: {verify_result['error']}")
                else:
                    self.results['base']['missing'].append({
                        'id': guide_id,
                        'name': guide_name
                    })
                    self.print_error(f"{guide_name}: NO ENCONTRADO ({guide_id}.png)")

        except FileNotFoundError:
            self.print_error(f"No se encontró {BASE_PROMPTS_FILE}")
        except Exception as e:
            self.print_error(f"Error verificando avatares base: {e}")

    def verify_variation_avatars(self):
        """Verifica variaciones de avatares (95 imágenes)."""
        self.print_header("Verificando Variaciones de Estilo")

        try:
            # Cargar prompts
            with open(VARIATIONS_PROMPTS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)

            guides = data.get('guides', [])
            metadata = data.get('metadata', {})
            params = metadata.get('base_params', {})
            expected_size = (params.get('width', 512), params.get('height', 512))

            # Contar total de variaciones
            total_variations = sum(len(g.get('variations', [])) for g in guides)
            self.results['variations']['total'] = total_variations

            self.print_info(f"Verificando {total_variations} variaciones en: {VARIATIONS_OUTPUT_DIR}")
            print()

            for guide in guides:
                guide_id = guide['id']
                guide_name = guide['name']
                variations = guide.get('variations', [])

                print(f"{Colors.BOLD}{guide_name}:{Colors.ENDC}")

                for variation in variations:
                    style = variation['style']
                    style_name = variation['name']
                    filename = f"{guide_id}_style{style}.png"
                    image_path = VARIATIONS_OUTPUT_DIR / filename

                    # Verificar
                    verify_result = self.verify_image(image_path, expected_size)

                    if verify_result['exists']:
                        self.results['variations']['found'] += 1

                        if verify_result['valid'] and verify_result['correct_size']:
                            self.results['variations']['valid'].append(f"{guide_id}_style{style}")
                            size_kb = verify_result['file_size_kb']
                            self.print_success(f"  Style {style} ({style_name}): {size_kb:.1f} KB")
                        elif verify_result['valid']:
                            self.results['variations']['wrong_size'].append({
                                'id': guide_id,
                                'name': guide_name,
                                'style': style,
                                'actual_size': verify_result['actual_size']
                            })
                            actual = verify_result['actual_size']
                            self.print_warning(f"  Style {style}: Tamaño {actual}")
                        else:
                            self.results['variations']['invalid'].append({
                                'id': guide_id,
                                'name': guide_name,
                                'style': style,
                                'error': verify_result['error']
                            })
                            self.print_error(f"  Style {style}: {verify_result['error']}")
                    else:
                        self.results['variations']['missing'].append({
                            'id': guide_id,
                            'name': guide_name,
                            'style': style,
                            'filename': filename
                        })
                        self.print_error(f"  Style {style}: NO ENCONTRADO")

                print()  # Línea en blanco entre guías

        except FileNotFoundError:
            self.print_error(f"No se encontró {VARIATIONS_PROMPTS_FILE}")
        except Exception as e:
            self.print_error(f"Error verificando variaciones: {e}")

    def print_summary(self):
        """Imprime resumen completo."""
        self.print_header("RESUMEN DE VERIFICACIÓN")

        # Resumen base
        if self.check_base:
            base = self.results['base']
            print(f"{Colors.BOLD}Avatares Base:{Colors.ENDC}")
            print(f"  Total esperado:    {base['total']}")
            print(f"  {Colors.OKGREEN}✓ Encontrados:    {base['found']}{Colors.ENDC}")
            print(f"  {Colors.OKGREEN}✓ Válidos:        {len(base['valid'])}{Colors.ENDC}")
            print(f"  {Colors.WARNING}⚠ Tamaño incorrecto: {len(base['wrong_size'])}{Colors.ENDC}")
            print(f"  {Colors.FAIL}✗ Inválidos:      {len(base['invalid'])}{Colors.ENDC}")
            print(f"  {Colors.FAIL}✗ Faltantes:      {len(base['missing'])}{Colors.ENDC}")

            if base['missing']:
                print(f"\n  {Colors.FAIL}Faltantes ({len(base['missing'])}):{Colors.ENDC}")
                for item in base['missing']:
                    print(f"    • {item['name']} ({item['id']}.png)")

        # Resumen variaciones
        if self.check_variations:
            if self.check_base:
                print()  # Separador

            var = self.results['variations']
            print(f"{Colors.BOLD}Variaciones de Estilo:{Colors.ENDC}")
            print(f"  Total esperado:    {var['total']}")
            print(f"  {Colors.OKGREEN}✓ Encontradas:    {var['found']}{Colors.ENDC}")
            print(f"  {Colors.OKGREEN}✓ Válidas:        {len(var['valid'])}{Colors.ENDC}")
            print(f"  {Colors.WARNING}⚠ Tamaño incorrecto: {len(var['wrong_size'])}{Colors.ENDC}")
            print(f"  {Colors.FAIL}✗ Inválidas:      {len(var['invalid'])}{Colors.ENDC}")
            print(f"  {Colors.FAIL}✗ Faltantes:      {len(var['missing'])}{Colors.ENDC}")

            if var['missing']:
                print(f"\n  {Colors.FAIL}Faltantes ({len(var['missing'])}):{Colors.ENDC}")
                # Agrupar por guía
                by_guide = {}
                for item in var['missing']:
                    guide_name = item['name']
                    if guide_name not in by_guide:
                        by_guide[guide_name] = []
                    by_guide[guide_name].append(item['style'])

                for guide_name, styles in by_guide.items():
                    styles_str = ', '.join([f"S{s}" for s in sorted(styles)])
                    print(f"    • {guide_name}: {styles_str}")

        # Mensaje final
        print()
        total_expected = 0
        total_valid = 0

        if self.check_base:
            total_expected += self.results['base']['total']
            total_valid += len(self.results['base']['valid'])

        if self.check_variations:
            total_expected += self.results['variations']['total']
            total_valid += len(self.results['variations']['valid'])

        if total_valid == total_expected:
            print(f"{Colors.OKGREEN}{Colors.BOLD}🎉 ¡Todas las imágenes están presentes y válidas!{Colors.ENDC}\n")
        elif total_valid > 0:
            print(f"{Colors.WARNING}⚠ Progreso: {total_valid}/{total_expected} imágenes válidas{Colors.ENDC}\n")
        else:
            print(f"{Colors.FAIL}❌ No se encontraron imágenes válidas{Colors.ENDC}\n")

    def run(self) -> int:
        """Ejecución principal."""
        self.print_header("🔍 Verificador de Avatares AuraList")

        if self.check_base:
            self.verify_base_avatars()

        if self.check_variations:
            self.verify_variation_avatars()

        self.print_summary()

        # Código de salida
        total_missing = 0
        total_invalid = 0

        if self.check_base:
            total_missing += len(self.results['base']['missing'])
            total_invalid += len(self.results['base']['invalid'])

        if self.check_variations:
            total_missing += len(self.results['variations']['missing'])
            total_invalid += len(self.results['variations']['invalid'])

        return 0 if (total_missing == 0 and total_invalid == 0) else 1


def main():
    parser = argparse.ArgumentParser(
        description='Verifica avatares generados'
    )
    parser.add_argument(
        '--variations',
        action='store_true',
        help='Verifica variaciones de estilo'
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Verifica todo (base + variaciones)'
    )

    args = parser.parse_args()

    check_base = not args.variations or args.all
    check_variations = args.variations or args.all

    verifier = AvatarVerifier(
        check_base=check_base,
        check_variations=check_variations
    )

    exit_code = verifier.run()
    exit(exit_code)


if __name__ == "__main__":
    main()
