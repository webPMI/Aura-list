import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';

/// Widget para configurar el dia de descanso semanal
class RestDayTile extends ConsumerStatefulWidget {
  const RestDayTile({super.key});

  @override
  ConsumerState<RestDayTile> createState() => _RestDayTileState();
}

class _RestDayTileState extends ConsumerState<RestDayTile> {
  bool _isLoading = true;
  int? _selectedRestDay;

  @override
  void initState() {
    super.initState();
    _loadRestDayPreference();
  }

  Future<void> _loadRestDayPreference() async {
    final dbService = ref.read(databaseServiceProvider);
    final prefs = await dbService.getUserPreferences();
    if (mounted) {
      setState(() {
        _selectedRestDay = prefs?.restDayOfWeek;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRestDay(int? dayOfWeek) async {
    final dbService = ref.read(databaseServiceProvider);
    final prefs = await dbService.getUserPreferences();

    if (prefs != null) {
      final updated = prefs.copyWith(restDayOfWeek: dayOfWeek);
      updated.touch();
      await updated.save();

      if (mounted) {
        setState(() {
          _selectedRestDay = dayOfWeek;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dayOfWeek == null
                  ? 'Dia de descanso desactivado'
                  : 'Dia de descanso configurado: ${_getDayName(dayOfWeek)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _getDayName(int dayOfWeek) {
    return switch (dayOfWeek) {
      1 => 'Lunes',
      2 => 'Martes',
      3 => 'Miércoles',
      4 => 'Jueves',
      5 => 'Viernes',
      6 => 'Sábado',
      7 => 'Domingo',
      _ => 'Ninguno',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return ListTile(
        leading: const Icon(Icons.self_improvement_outlined),
        title: const Text('Día de descanso'),
        subtitle: const Text('Cargando...'),
      );
    }

    return ListTile(
      leading: Icon(
        Icons.self_improvement_outlined,
        color: colorScheme.primary,
      ),
      title: const Text('Día de descanso semanal'),
      subtitle: Text(
        _selectedRestDay == null
            ? 'Sin día de descanso configurado'
            : '${_getDayName(_selectedRestDay!)} - Las rachas no se rompen en este día',
      ),
      trailing: DropdownButton<int?>(
        value: _selectedRestDay,
        underline: const SizedBox(),
        onChanged: (value) => _updateRestDay(value),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Ninguno'),
          ),
          ...List.generate(7, (index) {
            final day = index + 1;
            return DropdownMenuItem<int?>(
              value: day,
              child: Text(_getDayName(day)),
            );
          }),
        ],
      ),
      onTap: () => _showRestDayDialog(context),
    );
  }

  void _showRestDayDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.self_improvement,
          color: colorScheme.primary,
          size: 48,
        ),
        title: const Text('Día de descanso semanal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configura un día de la semana como tu día de descanso. '
              'En este día:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              Icons.check_circle_outline,
              'Las tareas son opcionales',
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              Icons.favorite_outline,
              'Tu racha no se rompe si no completas nada',
              colorScheme,
            ),
            const SizedBox(height: 8),
            _buildBenefitItem(
              Icons.spa_outlined,
              'Celebramos tu descanso: "El descanso también es productivo"',
              colorScheme,
            ),
            const SizedBox(height: 16),
            Text(
              'Elige tu día de descanso:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
