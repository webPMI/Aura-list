import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// URL oficial de Servicios Mallorca
const String kServiciosMallorcaUrl = 'https://serviciosmallorca.com';

/// Abre la web de Servicios Mallorca en el navegador
Future<bool> openServiciosMallorca({String? utmSource}) async {
  final urlString = utmSource != null
      ? '$kServiciosMallorcaUrl?utm_source=$utmSource&utm_medium=app_referral'
      : kServiciosMallorcaUrl;

  final uri = Uri.parse(urlString);
  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Error al abrir Servicios Mallorca: $e');
    return false;
  }
}

/// Banner promocional para la pantalla de bienvenida (WelcomeScreen)
class ServiciosMallorcaWelcomeBanner extends StatelessWidget {
  const ServiciosMallorcaWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Tienes una idea o proyecto web?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Diseño y desarrollo profesional con Servicios Mallorca',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => openServiciosMallorca(utmSource: 'auralist_welcome'),
              icon: const Icon(Icons.arrow_outward_rounded, size: 16),
              label: const Text('Visitar serviciosmallorca.com'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ListTile para Ajustes (SettingsScreen)
class ServiciosMallorcaSettingsTile extends StatelessWidget {
  const ServiciosMallorcaSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.code_rounded,
          color: colorScheme.primary,
        ),
      ),
      title: const Text('¿Quieres tu propia web o app?'),
      subtitle: const Text('Impulsa tu idea con Servicios Mallorca'),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => openServiciosMallorca(utmSource: 'auralist_settings'),
    );
  }
}

/// Elemento para el Drawer de navegación
class ServiciosMallorcaDrawerTile extends StatelessWidget {
  const ServiciosMallorcaDrawerTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openServiciosMallorca(utmSource: 'auralist_drawer'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.language_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicios Mallorca',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Desarrollo web & soluciones digitales',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
