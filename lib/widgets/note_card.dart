import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';

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

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteColor = _parseColor(note.color);
    final isDark =
        ThemeData.estimateBrightnessForColor(noteColor) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
                        child: Icon(
                          Icons.push_pin,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTogglePin != null)
                      GestureDetector(
                        onTap: onTogglePin,
                        child: Icon(
                          note.isPinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 16,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content preview
                Expanded(
                  child: Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Footer with date and link indicator
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('dd MMM', 'es').format(note.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isLinkedToTask || note.tags.isNotEmpty)
                      const Spacer(),
                    if (note.isLinkedToTask) ...[
                      Icon(
                        Icons.link,
                        size: 12,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      if (note.tags.isNotEmpty)
                        const SizedBox(width: 6),
                    ],
                    if (note.tags.isNotEmpty) ...[
                      Icon(
                        Icons.label_outline,
                        size: 12,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${note.tags.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor.withValues(alpha: 0.5),
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

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final noteColor = _parseColor(note.color);

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
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                style: TextStyle(
                  fontSize: 12,
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
