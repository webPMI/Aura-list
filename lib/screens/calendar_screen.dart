import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../widgets/calendar_view.dart';
import '../widgets/navigation/drawer_menu_button.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _calendarKey = GlobalKey<CalendarViewState>();

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: const Text('Calendario'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              _calendarKey.currentState?.jumpToToday();
            },
            tooltip: 'Ir a hoy',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : Breakpoints.maxContentWidth,
          ),
          child: CalendarView(
            key: _calendarKey,
            onDateSelected: (date) {
              // Handle date selection
            },
            onTaskTap: (task) {
              _showTaskDetail(context, task);
            },
          ),
        ),
      ),
    );
  }

  void _showTaskDetail(BuildContext context, dynamic task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${task.typeLabel}'),
            if (task.dueDate != null) Text('Fecha: ${task.dueDate}'),
            if (task.motivation != null && task.motivation!.isNotEmpty)
              Text('Motivacion: ${task.motivation}'),
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
}
