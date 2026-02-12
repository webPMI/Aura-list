import 'package:flutter/material.dart';
import '../../core/responsive/breakpoints.dart';

/// Muestra un documento legal completo con resumen y contenido scrolleable
///
/// Mejoras de UX/A11y:
/// - Resumen visible en la parte superior para lectura rapida
/// - Contenido completo scrolleable con buen contraste
/// - Texto seleccionable para copiar informacion
/// - Tamano de fuente legible (no menor a 14px)
/// - Buen espaciado entre lineas para mejor legibilidad
/// - Boton flotante para cerrar siempre visible
Future<void> showLegalDocumentDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? summary,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _LegalDocumentDialog(
      title: title,
      content: content,
      summary: summary,
    ),
  );
}

class _LegalDocumentDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? summary;

  const _LegalDocumentDialog({
    required this.title,
    required this.content,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final horizontalPadding = context.horizontalPadding;

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Breakpoints.maxFormWidth + (horizontalPadding * 2),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Resumen destacado si existe
                    if (summary != null && summary!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.summarize_rounded,
                                  color: colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Resumen Ejecutivo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              summary!.trim(),
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: colorScheme.onSurface.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Divider con label
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.outlineVariant,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'DOCUMENTO COMPLETO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outlineVariant,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Contenido completo con mejor legibilidad
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: SelectableText(
                        content.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.8,
                              color: colorScheme.onSurface.withValues(alpha: 0.87),
                            ),
                        // Mejora de accesibilidad para seleccion de texto
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Informacion de contacto al final
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Preguntas o inquietudes?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'Contactanos en servicioweb.pmi@gmail.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Boton flotante para cerrar (siempre visible)
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Entendido'),
          tooltip: 'Cerrar documento',
        ),
      ),
    );
  }
}
