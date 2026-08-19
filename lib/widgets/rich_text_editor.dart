import 'dart:convert';
import 'package:flutter/material.dart';

/// TEMPORARY PLACEHOLDER - Rich text editor disabled due to flutter_quill incompatibility
/// Widget de editor de texto enriquecido para notas.
/// Usa flutter_quill para formato de texto (negrita, cursiva, listas, etc.)
class RichTextNoteEditor extends StatefulWidget {
  /// Delta JSON inicial (formato de flutter_quill)
  final String? initialDelta;

  /// Texto plano inicial (se convierte a Delta si initialDelta es null)
  final String? initialPlainText;

  /// Callback cuando el contenido cambia (retorna Delta JSON)
  final ValueChanged<String> onChanged;

  /// Color de fondo del editor
  final Color backgroundColor;

  /// Color del texto
  final Color textColor;

  /// Placeholder cuando el editor está vacío
  final String placeholder;

  /// Si el editor debe enfocarse automáticamente
  final bool autoFocus;

  const RichTextNoteEditor({
    super.key,
    this.initialDelta,
    this.initialPlainText,
    required this.onChanged,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.placeholder = 'Escribe tu nota aqui...',
    this.autoFocus = false,
  });

  @override
  State<RichTextNoteEditor> createState() => _RichTextNoteEditorState();
}

class _RichTextNoteEditorState extends State<RichTextNoteEditor> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(
      text: widget.initialPlainText ?? '',
    );
    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    widget.onChanged(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 16,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: TextStyle(
            color: widget.textColor.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// Obtiene el texto plano del contenido actual
  String getPlainText() {
    return _controller.text.trim();
  }

  /// Obtiene el Delta JSON del contenido actual (placeholder)
  String getDeltaJson() {
    return jsonEncode([{'insert': _controller.text}]);
  }

  /// Verifica si el editor está vacío
  bool get isEmpty {
    return _controller.text.trim().isEmpty;
  }
}



