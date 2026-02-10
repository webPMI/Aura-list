import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/responsive/breakpoints.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/notes_list.dart';
import '../widgets/note_editor.dart';
import '../widgets/navigation/drawer_menu_button.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showNoteEditor([Note? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          onSave: (title, content, color, tags) async {
            try {
              if (note == null) {
                await ref
                    .read(independentNotesProvider.notifier)
                    .addNote(
                      title: title,
                      content: content,
                      color: color,
                      tags: tags,
                    );
                _showSnackBar('Nota creada');
              } else {
                final updatedNote = note.copyWith(
                  title: title,
                  content: content,
                  color: color,
                  tags: tags,
                );
                await ref
                    .read(independentNotesProvider.notifier)
                    .updateNote(updatedNote);
                _showSnackBar('Nota actualizada');
              }
            } catch (e) {
              _showSnackBar('Error al guardar nota');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = ref.watch(independentNotesProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: DrawerAwareAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis Notas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            if (notes.isNotEmpty)
              Text(
                '${notes.length} nota${notes.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: NotesList(
            onNoteEdit: _showNoteEditor,
            onFeedback: _showSnackBar,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showNoteEditor();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NoteSearchSheet(
        onNoteSelected: (note) {
          Navigator.pop(context);
          _showNoteEditor(note);
        },
      ),
    );
  }
}

class _NoteSearchSheet extends ConsumerStatefulWidget {
  final void Function(Note note) onNoteSelected;

  const _NoteSearchSheet({required this.onNoteSelected});

  @override
  ConsumerState<_NoteSearchSheet> createState() => _NoteSearchSheetState();
}

class _NoteSearchSheetState extends ConsumerState<_NoteSearchSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchResults = ref.watch(noteSearchProvider(_query));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar notas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: searchResults.when(
              data: (notes) {
                if (_query.isEmpty) {
                  return Center(
                    child: Text(
                      'Escribe para buscar',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin resultados para "$_query"',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(note.color.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.outline),
                        ),
                      ),
                      title: Text(note.title),
                      subtitle: note.content.isNotEmpty
                          ? Text(
                              note.contentPreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: note.isPinned
                          ? Icon(
                              Icons.push_pin,
                              size: 16,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: () => widget.onNoteSelected(note),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Text(
                  'Error al buscar',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
