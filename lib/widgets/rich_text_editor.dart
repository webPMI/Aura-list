import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../services/logger_service.dart';

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
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _initController();
  }

  void _initController() {
    Document document;

    if (widget.initialDelta != null && widget.initialDelta!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.initialDelta!);
        if (deltaJson is List) {
          document = Document.fromJson(deltaJson);
        } else if (deltaJson is Map && deltaJson.containsKey('ops')) {
          document = Document.fromJson(deltaJson['ops']);
        } else {
          document = Document();
        }
      } catch (e) {
        // Si falla el parsing, crear documento vacío
        document = Document();
      }
    } else if (widget.initialPlainText != null &&
        widget.initialPlainText!.isNotEmpty) {
      // Convertir texto plano a documento
      document = Document()..insert(0, widget.initialPlainText!);
    } else {
      document = Document();
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    try {
      final delta = _controller.document.toDelta();
      final deltaJson = jsonEncode(delta.toJson());
      widget.onChanged(deltaJson);
    } catch (e) {
      LoggerService().error('Widget', 'Error serializing delta: $e');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onContentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar de formato
        Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: widget.textColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QuillSimpleToolbar(
              controller: _controller,
              config: QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showListNumbers: true,
                showListBullets: true,
                showListCheck: true,
                showCodeBlock: false,
                showQuote: true,
                showLink: false,
                showIndent: true,
                showClearFormat: true,
                showFontFamily: false,
                showFontSize: false,
                showBackgroundColorButton: false,
                showColorButton: false,
                showHeaderStyle: true,
                showInlineCode: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showClipboardCut: false,
                showClipboardCopy: false,
                showClipboardPaste: false,
                showAlignmentButtons: false,
                showDirection: false,
                showDividers: true,
              ),
            ),
          ),
        ),
        // Editor de texto
        Expanded(
          child: Container(
            color: widget.backgroundColor,
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                placeholder: widget.placeholder,
                padding: const EdgeInsets.all(16),
                expands: true,
                autoFocus: widget.autoFocus,
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  h1: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(16, 8),
                    VerticalSpacing.zero,
                    null,
                  ),
                  h2: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(12, 6),
                    VerticalSpacing.zero,
                    null,
                  ),
                  h3: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(8, 4),
                    VerticalSpacing.zero,
                    null,
                  ),
                  bold: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  italic: TextStyle(
                    color: widget.textColor,
                    fontStyle: FontStyle.italic,
                  ),
                  underline: TextStyle(
                    color: widget.textColor,
                    decoration: TextDecoration.underline,
                  ),
                  strikeThrough: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.6),
                    decoration: TextDecoration.lineThrough,
                  ),
                  placeHolder: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor.withValues(alpha: 0.4),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                  ),
                  lists: DefaultListBlockStyle(
                    TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    HorizontalSpacing.zero,
                    VerticalSpacing.zero,
                    VerticalSpacing.zero,
                    null,
                    null,
                  ),
                  quote: DefaultTextBlockStyle(
                    TextStyle(
                      color: widget.textColor.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(8, 8),
                    VerticalSpacing.zero,
                    BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: widget.textColor.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Obtiene el texto plano del contenido actual
  String getPlainText() {
    return _controller.document.toPlainText().trim();
  }

  /// Obtiene el Delta JSON del contenido actual
  String getDeltaJson() {
    try {
      final delta = _controller.document.toDelta();
      return jsonEncode(delta.toJson());
    } catch (e) {
      return '[]';
    }
  }

  /// Verifica si el editor está vacío
  bool get isEmpty {
    final text = _controller.document.toPlainText().trim();
    return text.isEmpty;
  }
}
