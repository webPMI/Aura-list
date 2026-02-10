import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../core/responsive/breakpoints.dart';
import 'note_card.dart';

class NotesList extends ConsumerWidget {
  final void Function(Note note)? onNoteEdit;
  final void Function(String message)? onFeedback;

  const NotesList({super.key, this.onNoteEdit, this.onFeedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(independentNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.note_add_outlined,
                  size: 64,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tus notas apareceran aqui',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Guarda ideas, listas, recordatorios\ny todo lo que necesites.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Toca "Nueva nota" para empezar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Determine grid columns based on screen size
    final columns = context.gridColumns.clamp(1, 3);
    final horizontalPadding = context.horizontalPadding;
    final itemSpacing = context.itemSpacing;

    return GridView.builder(
      padding: EdgeInsets.all(horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: itemSpacing,
        mainAxisSpacing: itemSpacing,
        childAspectRatio: columns == 1 ? 1.8 : (columns == 2 ? 1.0 : 0.85),
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => onNoteEdit?.call(note),
          onDelete: () async {
            await ref.read(independentNotesProvider.notifier).deleteNote(note);
            onFeedback?.call('Nota eliminada');
          },
          onTogglePin: () async {
            await ref.read(independentNotesProvider.notifier).togglePin(note);
            onFeedback?.call(note.isPinned ? 'Nota desanclada' : 'Nota anclada');
          },
          onLongPress: () => _showNoteOptions(context, ref, note),
        );
      },
    );
  }

  void _showNoteOptions(BuildContext context, WidgetRef ref, Note note) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.isPinned ? 'Desanclar' : 'Anclar'),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(independentNotesProvider.notifier)
                    .togglePin(note);
                onFeedback
                    ?.call(note.isPinned ? 'Nota desanclada' : 'Nota anclada');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Cambiar color'),
              onTap: () {
                Navigator.pop(context);
                _showColorPicker(context, ref, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                onNoteEdit?.call(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
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
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(independentNotesProvider.notifier)
                      .deleteNote(note);
                  onFeedback?.call('Nota eliminada');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: Note.colorOptions.entries.map((entry) {
            final color =
                Color(int.parse(entry.value.replaceFirst('#', '0xFF')));
            final isSelected = note.color == entry.value;

            return GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(independentNotesProvider.notifier)
                    .changeColor(note, entry.value);
                onFeedback?.call('Color actualizado');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
