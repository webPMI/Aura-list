import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../core/responsive/breakpoints.dart';
import 'note_card.dart';
import 'color_picker_sheet.dart';

class NotesList extends ConsumerStatefulWidget {
  final void Function(Note note)? onNoteEdit;
  final void Function(String message)? onFeedback;
  final String? searchQuery;
  final bool isGridView;

  const NotesList({
    super.key,
    this.onNoteEdit,
    this.onFeedback,
    this.searchQuery,
    this.isGridView = true,
  });

  @override
  ConsumerState<NotesList> createState() => _NotesListState();
}

class _NotesListState extends ConsumerState<NotesList> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(independentNotesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (allNotes.isEmpty) {
      return _buildEmptyState(context, colorScheme);
    }

    // Extraer todos los tags disponibles
    final allTags = <String>{};
    for (final n in allNotes) {
      allTags.addAll(n.tags);
    }

    // Filtrar por búsqueda de texto
    List<Note> filteredNotes = allNotes;
    if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase().trim();
      filteredNotes = filteredNotes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(query);
        final contentMatch = note.content.toLowerCase().contains(query);
        final tagMatch = note.tags.any((t) => t.toLowerCase().contains(query));
        return titleMatch || contentMatch || tagMatch;
      }).toList();
    }

    // Filtrar por tag si hay uno seleccionado
    if (_selectedTag != null) {
      filteredNotes =
          filteredNotes.where((n) => n.tags.contains(_selectedTag)).toList();
    }

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Sin notas con estos criterios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_selectedTag != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _selectedTag = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar filtro de etiqueta'),
              ),
            ],
          ],
        ),
      );
    }

    final pinnedNotes = filteredNotes.where((n) => n.isPinned).toList();
    final otherNotes = filteredNotes.where((n) => !n.isPinned).toList();

    final horizontalPadding = context.horizontalPadding;
    final columns = widget.isGridView ? context.gridColumns.clamp(1, 3) : 1;
    final itemSpacing = context.itemSpacing;

    return Column(
      children: [
        // Barra de Etiquetas (Tags) si existen
        if (allTags.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedTag == null,
                    onSelected: (_) => setState(() => _selectedTag = null),
                  ),
                  const SizedBox(width: 8),
                  ...allTags.map((tag) {
                    final isSelected = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          Icons.tag,
                          size: 14,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = isSelected ? null : tag;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Lista / Cuadrícula de Notas
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sección de Notas Fijadas (si hay)
              if (pinnedNotes.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 8),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          'FIJADAS (${pinnedNotes.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildNotesSliver(pinnedNotes, columns, itemSpacing, horizontalPadding),
                if (otherNotes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 8),
                      child: Text(
                        'OTRAS NOTAS (${otherNotes.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],

              // Sección de Otras Notas
              if (otherNotes.isNotEmpty)
                _buildNotesSliver(otherNotes, columns, itemSpacing, horizontalPadding),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSliver(
    List<Note> notes,
    int columns,
    double itemSpacing,
    double horizontalPadding,
  ) {
    if (columns == 1) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final note = notes[index];
              return Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: NoteCard(
                  key: ValueKey('note_${note.key}'),
                  note: note,
                  onTap: () => widget.onNoteEdit?.call(note),
                  onDelete: () => _handleNoteDelete(ref, note),
                  onTogglePin: () => _handleTogglePin(ref, note),
                  onLongPress: () => _showNoteOptions(context, ref, note),
                ),
              );
            },
            childCount: notes.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: itemSpacing,
          mainAxisSpacing: itemSpacing,
          childAspectRatio: columns == 2 ? 1.0 : 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = notes[index];
            return NoteCard(
              key: ValueKey('note_${note.key}'),
              note: note,
              onTap: () => widget.onNoteEdit?.call(note),
              onDelete: () => _handleNoteDelete(ref, note),
              onTogglePin: () => _handleTogglePin(ref, note),
              onLongPress: () => _showNoteOptions(context, ref, note),
            );
          },
          childCount: notes.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
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
              'Tus notas aparecerán aquí',
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

  void _handleNoteDelete(WidgetRef ref, Note note) async {
    await ref.read(independentNotesProvider.notifier).deleteNote(note);
    widget.onFeedback?.call('Nota eliminada');
  }

  void _handleTogglePin(WidgetRef ref, Note note) async {
    await ref.read(independentNotesProvider.notifier).togglePin(note);
    widget.onFeedback?.call(note.isPinned ? 'Nota desanclada' : 'Nota anclada');
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
                widget.onFeedback
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
                widget.onNoteEdit?.call(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archivar'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(independentNotesProvider.notifier).archiveNote(note);
                widget.onFeedback?.call('Nota archivada');
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
                  widget.onFeedback?.call('Nota eliminada');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Note note) async {
    final newColor = await ColorPickerSheet.show(context, note.color);
    if (newColor != null && context.mounted) {
      await ref.read(independentNotesProvider.notifier).changeColor(note, newColor);
      widget.onFeedback?.call('Color actualizado');
    }
  }
}
