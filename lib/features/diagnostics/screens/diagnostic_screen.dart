import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth_manager.dart';
import '../../../services/logger_service.dart';

class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authManager = ref.watch(authManagerProvider);
    final status = authManager.getInitializationStatus();
    final logs = LoggerService().getRecentLogs(count: 50);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico del Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Trigger a refresh of the UI
              (context as Element).markNeedsBuild();
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final report = LoggerService().exportLogs(count: 100);
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte copiado al portapapeles'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusSection(status),
          const SizedBox(height: 24),
          _buildLogsSection(logs),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> status) {
    final isInitialized = status['isInitialized'] as bool? ?? false;
    final firebaseAvailable = status['firebaseAvailable'] as bool? ?? false;
    final lastError = status['lastError'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado de Firebase',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: firebaseAvailable ? Colors.green : Colors.red,
          ),
        ),
        const Divider(),
        _buildInfoRow('Inicializado', isInitialized ? '✅ SÍ' : '❌ NO'),
        _buildInfoRow('Disponible', firebaseAvailable ? '✅ SÍ' : '❌ NO'),
        _buildInfoRow(
          'Autenticación',
          status['authAvailable'] == true ? '✅ SÍ' : '❌ NO',
        ),
        _buildInfoRow(
          'Plataforma',
          (status['isWeb'] as bool? ?? false) ? '🌐 Web' : '💻 Desktop/Mobile',
        ),
        _buildInfoRow('Proyecto ID', status['projectId']?.toString() ?? 'N/A'),
        _buildInfoRow(
          'Apps Activas',
          (status['activeApps'] as List?)?.join(', ') ?? 'Ninguna',
        ),
        if (lastError != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Último Error:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              lastError,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogsSection(List<LogEntry> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logs Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        if (logs.isEmpty)
          const Center(child: Text('No hay logs disponibles'))
        else
          ...logs.map((log) => _buildLogTile(log)),
      ],
    );
  }

  Widget _buildLogTile(LogEntry log) {
    Color color;
    switch (log.level) {
      case LogLevel.error:
      case LogLevel.critical:
        color = Colors.red;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${log.levelPrefix} [${log.tag}]',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                log.timestamp.toString().substring(11, 19),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(log.message, style: const TextStyle(fontSize: 13)),
          if (log.error != null)
            Text(
              'Error: ${log.error}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
