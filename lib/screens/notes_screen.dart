import 'package:flutter/material.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _showNoteEditor([Note? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          onSave: (
            title,
            content,
            color,
            tags,
            checklist, {
            String? richContent,
            String contentType = 'plain',
          }) async {
            try {
              if (note == null) {
                await ref.read(independentNotesProvider.notifier).addNote(
                      title: title,
                      content: content,
                      color: color,
                      tags: tags,
                      checklist: checklist,
                      richContent: richContent,
                      contentType: contentType,
                    );
                _showSnackBar('Nota creada');
              } else {
                final updatedNote = note.copyWith(
                  title: title,
                  content: content,
                  color: color,
                  tags: tags,
                  checklist: checklist,
                  richContent: richContent,
                  contentType: contentType,
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

  PreferredSizeWidget _buildAppBar(BuildContext context, int noteCount, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isSearchActive) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
          tooltip: 'Cerrar búsqueda',
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar notas y etiquetas...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              tooltip: 'Limpiar',
            ),
        ],
      );
    }

    return DrawerAwareAppBar(
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
          if (noteCount > 0)
            Text(
              '$noteCount nota${noteCount > 1 ? 's' : ''}',
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
          icon: Icon(_isGridView ? Icons.view_agenda_outlined : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: _isGridView ? 'Vista en lista' : 'Vista en cuadrícula',
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
          tooltip: 'Buscar notas',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(independentNotesProvider);
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: _buildAppBar(context, notes.length, isMobile),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: NotesList(
            searchQuery: _isSearchActive ? _searchController.text : null,
            isGridView: _isGridView,
            onNoteEdit: _showNoteEditor,
            onFeedback: _showSnackBar,
          ),
        ),
      ),
    );
  }
}
