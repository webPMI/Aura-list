import 'package:flutter/material.dart';

class TagsEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final Color? chipColor;

  const TagsEditor({
    super.key,
    required this.tags,
    required this.onChanged,
    this.chipColor,
  });

  @override
  State<TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<TagsEditor> {
  late List<String> _tags;
  final _controller = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  void _addTag(String tag) {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty || _tags.contains(normalized)) return;

    setState(() {
      _tags.add(normalized);
      _controller.clear();
      _isAdding = false;
    });
    widget.onChanged(_tags);
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Tags existentes
        ..._tags.map((tag) => Chip(
          label: Text(tag),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => _removeTag(tag),
          backgroundColor: widget.chipColor ?? colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: 12,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )),
        // Boton/campo para agregar
        if (_isAdding)
          SizedBox(
            width: 120,
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Nueva etiqueta',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check, size: 16),
                  onPressed: () => _addTag(_controller.text),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              onSubmitted: _addTag,
              onTapOutside: (_) {
                if (_controller.text.isEmpty) {
                  setState(() => _isAdding = false);
                }
              },
            ),
          )
        else
          ActionChip(
            label: const Text('+ Etiqueta'),
            onPressed: () => setState(() => _isAdding = true),
            backgroundColor: colorScheme.surface,
            labelStyle: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
