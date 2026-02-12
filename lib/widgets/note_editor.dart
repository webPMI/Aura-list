import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../core/utils/color_utils.dart';
import 'color_picker_sheet.dart';
import 'tags_editor.dart';
import 'checklist_editor.dart';
import 'rich_text_editor.dart';

/// Tipo de contenido para las notas
enum NoteContentType {
  plain,
  checklist,
  rich,
}

class NoteEditor extends StatefulWidget {
  final Note? note; // null for new note
  final String? taskId; // for task-linked notes
  final Function(
    String title,
    String content,
    String color,
    List<String> tags,
    List<ChecklistItem> checklist, {
    String? richContent,
    String contentType,
  }) onSave;

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
  late List<ChecklistItem> _checklist;
  bool _hasChanges = false;
  late NoteContentType _contentType;
  String? _richContent;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedColor = widget.note?.color ?? '#FFFFFF';
    _tags = List.from(widget.note?.tags ?? []);
    _checklist = List.from(widget.note?.checklist ?? []);
    _richContent = widget.note?.richContent;

    // Determinar el tipo de contenido inicial
    if (widget.note != null) {
      if (widget.note!.isRichText) {
        _contentType = NoteContentType.rich;
      } else if (widget.note!.checklist.isNotEmpty) {
        _contentType = NoteContentType.checklist;
      } else {
        _contentType = NoteContentType.plain;
      }
    } else {
      _contentType = NoteContentType.plain;
    }

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

    // Verificar si la nota está vacía
    final bool isEmpty = title.isEmpty &&
        content.isEmpty &&
        _checklist.isEmpty &&
        (_richContent == null || _richContent!.isEmpty);

    if (isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Determinar el contentType string
    String contentTypeStr;
    switch (_contentType) {
      case NoteContentType.rich:
        contentTypeStr = 'rich';
      case NoteContentType.checklist:
        contentTypeStr = 'checklist';
      case NoteContentType.plain:
        contentTypeStr = 'plain';
    }

    widget.onSave(
      title.isNotEmpty ? title : 'Sin titulo',
      content,
      _selectedColor,
      _tags,
      _checklist,
      richContent: _contentType == NoteContentType.rich ? _richContent : null,
      contentType: contentTypeStr,
    );
    Navigator.pop(context);
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de nota',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.text_fields,
                    color: _contentType == NoteContentType.plain
                        ? colorScheme.primary
                        : null,
                  ),
                  title: const Text('Texto simple'),
                  subtitle: const Text('Notas de texto plano'),
                  selected: _contentType == NoteContentType.plain,
                  onTap: () {
                    Navigator.pop(context);
                    if (_contentType != NoteContentType.plain) {
                      setState(() {
                        _contentType = NoteContentType.plain;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.checklist,
                    color: _contentType == NoteContentType.checklist
                        ? colorScheme.primary
                        : null,
                  ),
                  title: const Text('Lista de tareas'),
                  subtitle: const Text('Checklist con items'),
                  selected: _contentType == NoteContentType.checklist,
                  onTap: () {
                    Navigator.pop(context);
                    if (_contentType != NoteContentType.checklist) {
                      setState(() {
                        _contentType = NoteContentType.checklist;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.format_bold,
                    color: _contentType == NoteContentType.rich
                        ? colorScheme.primary
                        : null,
                  ),
                  title: const Text('Texto enriquecido'),
                  subtitle: const Text('Con formato: negrita, listas, etc.'),
                  selected: _contentType == NoteContentType.rich,
                  onTap: () {
                    Navigator.pop(context);
                    if (_contentType != NoteContentType.rich) {
                      _convertToRichText();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _convertToRichText() {
    // Si hay contenido plano, se convertirá automáticamente en el editor
    setState(() {
      _contentType = NoteContentType.rich;
      _hasChanges = true;
    });
  }

  IconData _getModeIcon() {
    switch (_contentType) {
      case NoteContentType.plain:
        return Icons.text_fields;
      case NoteContentType.checklist:
        return Icons.checklist;
      case NoteContentType.rich:
        return Icons.format_bold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = parseHexColor(_selectedColor) ?? Colors.grey;
    final textColor = ColorUtils.getTextColorFor(backgroundColor);

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
            // Boton de modo (plain/checklist/rich)
            IconButton(
              icon: Icon(_getModeIcon(), color: textColor),
              onPressed: _showModeSelector,
              tooltip: 'Cambiar tipo de nota',
            ),
            // Boton de color
            IconButton(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: parseHexColor(_selectedColor) ?? Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              onPressed: () async {
                final newColor =
                    await ColorPickerSheet.show(context, _selectedColor);
                if (newColor != null) {
                  setState(() {
                    _selectedColor = newColor;
                    _hasChanges = true;
                  });
                }
              },
              tooltip: 'Cambiar color',
            ),
            // Boton guardar
            IconButton(
              icon: Icon(Icons.check, color: textColor),
              onPressed: _saveNote,
              tooltip: 'Guardar',
            ),
          ],
        ),
        body: Container(
          color: backgroundColor,
          child: _contentType == NoteContentType.rich
              ? _buildRichTextEditor(textColor, backgroundColor)
              : _buildStandardEditor(textColor, backgroundColor),
        ),
      ),
    );
  }

  Widget _buildRichTextEditor(Color textColor, Color backgroundColor) {
    return Column(
      children: [
        // Titulo
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
            decoration: InputDecoration(
              hintText: 'Titulo',
              hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.4),
                  ),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
          ),
        ),
        // Editor de texto enriquecido
        Expanded(
          child: RichTextNoteEditor(
            initialDelta: _richContent,
            initialPlainText: _contentController.text,
            onChanged: (deltaJson) {
              _richContent = deltaJson;
              if (!_hasChanges) {
                setState(() => _hasChanges = true);
              }
            },
            backgroundColor: backgroundColor,
            textColor: textColor,
            placeholder: 'Escribe tu nota aqui...',
          ),
        ),
        // Tags section
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildTagsSection(textColor),
        ),
      ],
    );
  }

  Widget _buildStandardEditor(Color textColor, Color backgroundColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
            decoration: InputDecoration(
              hintText: 'Titulo',
              hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor.withValues(alpha: 0.4),
                  ),
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: null,
          ),
          const SizedBox(height: 8),
          // Contenido o checklist
          if (_contentType == NoteContentType.checklist)
            ChecklistEditor(
              items: _checklist,
              onChanged: (items) {
                setState(() {
                  _checklist = items;
                  _hasChanges = true;
                });
              },
              textColor: textColor,
            )
          else
            TextField(
              controller: _contentController,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor,
                  ),
              decoration: InputDecoration(
                hintText: 'Escribe tu nota aqui...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.4),
                    ),
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 10,
              textCapitalization: TextCapitalization.sentences,
            ),
          const SizedBox(height: 16),
          // Tags section
          _buildTagsSection(textColor),
        ],
      ),
    );
  }

  Widget _buildTagsSection(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_outline,
                  size: 16, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                'Etiquetas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TagsEditor(
            tags: _tags,
            onChanged: (newTags) {
              setState(() {
                _tags = newTags;
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
