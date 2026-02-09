import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';

class QuickNoteInput extends ConsumerStatefulWidget {
  final String? taskId;
  final void Function(String message)? onFeedback;
  final VoidCallback? onExpand;

  const QuickNoteInput({
    super.key,
    this.taskId,
    this.onFeedback,
    this.onExpand,
  });

  @override
  ConsumerState<QuickNoteInput> createState() => _QuickNoteInputState();
}

class _QuickNoteInputState extends ConsumerState<QuickNoteInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isExpanded) {
      setState(() => _isExpanded = true);
      widget.onExpand?.call();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      if (widget.taskId != null) {
        await ref
            .read(taskNotesProvider(widget.taskId!).notifier)
            .addQuickNote(content);
      } else {
        await ref.read(independentNotesProvider.notifier).addQuickNote(content);
      }

      _controller.clear();
      setState(() => _isExpanded = false);
      _focusNode.unfocus();
      HapticFeedback.lightImpact();
      widget.onFeedback?.call('Nota guardada');
    } catch (e) {
      widget.onFeedback?.call('Error al guardar nota');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _cancel() {
    _controller.clear();
    setState(() => _isExpanded = false);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: (_) => _saveNote(),
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: widget.taskId != null
                  ? 'Agregar nota a esta tarea...'
                  : 'Agregar nota rapida...',
              prefixIcon: Icon(
                Icons.edit_note,
                color: colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _isExpanded && _controller.text.isNotEmpty
                  ? IconButton(
                      icon: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(Icons.send, color: colorScheme.primary),
                      onPressed: _isSaving ? null : _saveNote,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            maxLines: _isExpanded ? 4 : 1,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : _cancel,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed:
                        _isSaving || _controller.text.trim().isEmpty
                            ? null
                            : _saveNote,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
