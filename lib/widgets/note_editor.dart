import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NoteEditor extends StatefulWidget {
  final Note? note; // null for new note
  final String? taskId; // for task-linked notes
  final Function(String title, String content, String color, List<String> tags)
      onSave;

  const NoteEditor({
    super.key,
    this.note,
    this.taskId,
    required this.onSave,
  });

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColor;
  late List<String> _tags;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? '#FFFFFF';
    _tags = widget.note?.tags ?? [];

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambios?'),
        content:
            const Text('Tienes cambios sin guardar. Deseas descartarlos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    widget.onSave(
      title.isNotEmpty ? title : 'Sin titulo',
      content,
      _selectedColor,
      _tags,
    );
    Navigator.pop(context);
  }

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
    final backgroundColor = _parseColor(_selectedColor);
    final isDark =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          title: Text(
            widget.note == null ? 'Nueva Nota' : 'Editar Nota',
            style: TextStyle(color: textColor),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.check, color: textColor),
              onPressed: _saveNote,
              tooltip: 'Guardar',
            ),
          ],
        ),
        body: Column(
          children: [
            // Color picker bar
            Container(
              color: colorScheme.surface,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: Note.colorOptions.entries.map((entry) {
                  final color =
                      Color(int.parse(entry.value.replaceFirst('#', '0xFF')));
                  final isSelected = _selectedColor == entry.value;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = entry.value;
                          _hasChanges = true;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(Icons.check,
                                size: 18, color: colorScheme.primary)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Content area
            Expanded(
              child: Container(
                color: backgroundColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Titulo',
                          hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Escribe tu nota aqui...',
                          hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        minLines: 10,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
