import 'package:flutter/material.dart';
import '../models/note_model.dart';

class ChecklistEditor extends StatefulWidget {
  final List<ChecklistItem> items;
  final ValueChanged<List<ChecklistItem>> onChanged;
  final Color textColor;

  const ChecklistEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.textColor = Colors.black87,
  });

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  late List<ChecklistItem> _items;
  final _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(ChecklistEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.from(widget.items);
    }
  }

  void _addItem(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _items.add(ChecklistItem(text: text.trim(), order: _items.length));
      _newItemController.clear();
    });
    widget.onChanged(_items);
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
    });
    widget.onChanged(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      // Reorder remaining items
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
    });
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de items existentes
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return CheckboxListTile(
            value: item.isCompleted,
            onChanged: (_) => _toggleItem(index),
            title: Text(
              item.text,
              style: TextStyle(
                color: widget.textColor,
                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            secondary: IconButton(
              icon: Icon(Icons.close, size: 18, color: widget.textColor.withValues(alpha: 0.5)),
              onPressed: () => _removeItem(index),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }),
        // Campo para nuevo item
        TextField(
          controller: _newItemController,
          style: TextStyle(color: widget.textColor),
          decoration: InputDecoration(
            hintText: 'Agregar item...',
            hintStyle: TextStyle(color: widget.textColor.withValues(alpha: 0.4)),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.add, color: widget.textColor.withValues(alpha: 0.5)),
          ),
          onSubmitted: _addItem,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }
}
