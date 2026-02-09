import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_card.dart';
import 'quick_note_input.dart';
import 'note_editor.dart';

class TaskNotesSection extends ConsumerWidget {
  final String taskId;
  final void Function(String message)? onFeedback;

  const TaskNotesSection({
    super.key,
    required this.taskId,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(taskNotesProvider(taskId));
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.note, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Notas (${notes.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (notes.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showAllNotes(context, ref, notes),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Ver todas'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        // Quick note input
        QuickNoteInput(taskId: taskId, onFeedback: onFeedback),
        // Notes list (show max 3)
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...notes.take(3).map((note) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: CompactNoteCard(
                  note: note,
                  onTap: () => _editNote(context, ref, note),
                  onDelete: () async {
                    await ref
                        .read(taskNotesProvider(taskId).notifier)
                        .deleteNote(note);
                    onFeedback?.call('Nota eliminada');
                  },
                ),
              )),
          if (notes.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '+ ${notes.length - 3} notas mas',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _editNote(BuildContext context, WidgetRef ref, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          taskId: taskId,
          onSave: (title, content, color, tags) async {
            final updatedNote = note.copyWith(
              title: title,
              content: content,
              color: color,
              tags: tags,
            );
            await ref
                .read(taskNotesProvider(taskId).notifier)
                .updateNote(updatedNote);
            onFeedback?.call('Nota actualizada');
          },
        ),
      ),
    );
  }

  void _showAllNotes(BuildContext context, WidgetRef ref, List<Note> notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Notas de la tarea',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addNewNote(context, ref);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CompactNoteCard(
                      note: note,
                      onTap: () {
                        Navigator.pop(context);
                        _editNote(context, ref, note);
                      },
                      onDelete: () async {
                        await ref
                            .read(taskNotesProvider(taskId).notifier)
                            .deleteNote(note);
                        onFeedback?.call('Nota eliminada');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewNote(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          taskId: taskId,
          onSave: (title, content, color, tags) async {
            await ref.read(taskNotesProvider(taskId).notifier).addNote(
                  title: title,
                  content: content,
                  color: color,
                );
            onFeedback?.call('Nota agregada');
          },
        ),
      ),
    );
  }
}
