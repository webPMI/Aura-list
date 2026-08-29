import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/encryption/encryption_service.dart';

class MasterPassphraseSheet extends StatefulWidget {
  const MasterPassphraseSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const MasterPassphraseSheet(),
    );
  }

  @override
  State<MasterPassphraseSheet> createState() => _MasterPassphraseSheetState();
}

class _MasterPassphraseSheetState extends State<MasterPassphraseSheet> {
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureText = true;
  bool _isSettingNew = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePassphrase() async {
    final pass = _passphraseController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Por favor escribe una contraseña o frase');
      return;
    }

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Debe tener al menos 6 caracteres');
      return;
    }

    if (pass != confirm) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _errorMessage = null);

    final encryption = EncryptionService();
    await encryption.setMasterPassphrase(pass);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña maestra configurada con éxito'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final encryption = EncryptionService();
    final hasCustom = encryption.hasCustomPassphrase;
    final exportKey = encryption.exportableKey;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tus Notas Bajo Llave',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tus notas privadas y finanzas se guardan dentro de una caja fuerte digital. Solo tú tienes la llave: ni los creadores de la app ni nadie en internet puede ver lo que escribes.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Estado actual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    hasCustom ? Icons.key_rounded : Icons.lock_outline_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasCustom
                          ? 'Caja fuerte protegida con tu Llave Secreta personal'
                          : 'Protegido automáticamente con cerradura digital en este dispositivo',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!_isSettingNew) ...[
              // Botón para definir o cambiar contraseña
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.key_rounded, color: Colors.indigoAccent),
                title: Text(hasCustom ? 'Cambiar mi Llave Secreta' : 'Crear mi Llave Secreta Personal'),
                subtitle: const Text('Elegir una frase o contraseña que solo tú conozcas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    _isSettingNew = true;
                    _errorMessage = null;
                  });
                },
              ),
              const Divider(height: 16),

              // Clave de emergencia
              const Text(
                'Clave de Emergencia (256 bits):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: SelectableText(
                  exportKey,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: exportKey));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clave de emergencia copiada'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar Clave'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Formulario para crear/cambiar contraseña
              const Text(
                'Elige tu Contraseña Maestra Personal',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Recuerda bien esta contraseña. Si cambias de dispositivo, la necesitarás para desbloquear tus datos cifrados.',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passphraseController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña o Frase Secreta',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _confirmController,
                obscureText: _obscureText,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isSettingNew = false),
                    child: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _handleSavePassphrase,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Guardar Contraseña'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
