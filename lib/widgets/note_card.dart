import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../core/utils/color_utils.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
    this.onTogglePin,
    this.onLongPress,
  });

  Widget _buildContentPreview(BuildContext context, Color textColor, int maxLines) {
    // Para notas con checklist, mostrar progreso
    if (note.hasChecklist) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                note.checklistProgressText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textColor.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Show first few checklist items
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: note.checklist.take(maxLines - 1).map((item) {
                return Row(
                  children: [
                    Icon(
                      item.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 14,
                      color: textColor.withValues(alpha: item.isCompleted ? 0.5 : 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textColor.withValues(
                                  alpha: item.isCompleted ? 0.5 : 0.8),
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Para notas con texto enriquecido o plano, mostrar displayContent
    final content = note.displayContent;
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de tipo de nota
        if (note.isRichText)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.format_bold,
                  size: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 2),
                Text(
                  'Texto enriquecido',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                ),
            maxLines: note.isRichText ? maxLines - 1 : maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteColor = parseHexColor(note.color) ?? Colors.grey;
    final textColor = ColorUtils.getTextColorFor(noteColor);

    // Adjust maxLines based on text scale for accessibility
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    final maxContentLines = textScaleFactor > 1.3 ? 4 : 6;

    return Dismissible(
      key: Key('note_${note.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Eliminar nota'),
                content: Text('Eliminar "${note.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        },
        child: Card(
          elevation: note.isPinned ? 4 : 1,
          color: noteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: note.isPinned
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with pin icon
                Row(
                  children: [
                    if (note.isPinned)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Semantics(
                          label: 'Nota anclada',
                          child: Icon(
                            Icons.push_pin,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTogglePin != null)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 20,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                          onPressed: onTogglePin,
                          tooltip: note.isPinned ? 'Desanclar' : 'Anclar',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content preview (supports rich text)
                Expanded(
                  child: _buildContentPreview(context, textColor, maxContentLines),
                ),
                // Footer with date and link indicator
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('dd MMM', 'es').format(note.updatedAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isLinkedToTask || note.tags.isNotEmpty)
                      const Spacer(),
                    if (note.isLinkedToTask) ...[
                      Semantics(
                        label: 'Nota vinculada a tarea',
                        excludeSemantics: true,
                        child: Icon(
                          Icons.link,
                          size: 12,
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                      if (note.tags.isNotEmpty)
                        const SizedBox(width: 6),
                    ],
                    if (note.tags.isNotEmpty) ...[
                      Flexible(
                        child: Semantics(
                          label: '${note.tags.length} etiquetas: ${note.tags.join(", ")}',
                          child: Text(
                            note.tags.take(2).join(', ') + (note.tags.length > 2 ? ' +${note.tags.length - 2}' : ''),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact note card for task detail view
class CompactNoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CompactNoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteColor = parseHexColor(note.color) ?? Colors.grey;

    return Dismissible(
      key: Key('compact_note_${note.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        tileColor: noteColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: noteColor == Colors.white ? colorScheme.primary : noteColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          note.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.displayContent.isNotEmpty
            ? Text(
                note.displayContent,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
