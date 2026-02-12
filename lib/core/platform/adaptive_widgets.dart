import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_detector.dart';

/// Creates an adaptive widget that uses Cupertino on iOS/macOS and Material on other platforms
///
/// Example:
/// ```dart
/// AdaptiveWidget(
///   cupertino: CupertinoButton(...),
///   material: ElevatedButton(...),
/// )
/// ```
class AdaptiveWidget extends StatelessWidget {
  final Widget cupertino;
  final Widget material;

  const AdaptiveWidget({
    super.key,
    required this.cupertino,
    required this.material,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return cupertino;
    }
    return material;
  }
}

/// Adaptive button that uses platform-specific styling
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDestructive;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        color: isDestructive ? CupertinoColors.destructiveRed : CupertinoColors.activeBlue,
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: isDestructive
          ? ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            )
          : null,
      child: child,
    );
  }
}

/// Adaptive text button
class AdaptiveTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const AdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoButton(
        onPressed: onPressed,
        child: child,
      );
    }
    return TextButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Adaptive dialog that uses showCupertinoDialog on iOS/macOS and showDialog on other platforms
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (PlatformCapabilities.prefersCupertino) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

/// Adaptive alert dialog with platform-specific styling
class AdaptiveAlertDialog extends StatelessWidget {
  final String? title;
  final String? content;
  final List<AdaptiveDialogAction> actions;

  const AdaptiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoAlertDialog(
        title: title != null ? Text(title!) : null,
        content: content != null ? Text(content!) : null,
        actions: actions.map((action) => action._buildCupertino(context)).toList(),
      );
    }
    return AlertDialog(
      title: title != null ? Text(title!) : null,
      content: content != null ? Text(content!) : null,
      actions: actions.map((action) => action._buildMaterial(context)).toList(),
    );
  }
}

/// Action for adaptive dialog
class AdaptiveDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefaultAction;

  const AdaptiveDialogAction({
    required this.text,
    this.onPressed,
    this.isDestructive = false,
    this.isDefaultAction = false,
  });

  Widget _buildCupertino(BuildContext context) {
    return CupertinoDialogAction(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      isDestructiveAction: isDestructive,
      isDefaultAction: isDefaultAction,
      child: Text(text),
    );
  }

  Widget _buildMaterial(BuildContext context) {
    if (isDestructive) {
      return TextButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(text),
      );
    }
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      child: Text(text),
    );
  }
}

/// Adaptive switch that uses platform-specific styling
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Adaptive slider that uses platform-specific styling
class AdaptiveSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;

  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        divisions: divisions,
      );
    }
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
    );
  }
}

/// Adaptive activity indicator (spinner)
class AdaptiveProgressIndicator extends StatelessWidget {
  final double? value;
  final Color? color;

  const AdaptiveProgressIndicator({
    super.key,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoActivityIndicator(
        color: color,
      );
    }
    return CircularProgressIndicator(
      value: value,
      color: color,
    );
  }
}

/// Adaptive text field with platform-specific styling
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final String? label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final TextCapitalization textCapitalization;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformCapabilities.prefersCupertino) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder ?? label,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        maxLines: maxLines,
        minLines: minLines,
        prefix: prefix,
        suffix: suffix,
        textCapitalization: textCapitalization,
      );
    }
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: placeholder,
        labelText: label,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      textCapitalization: textCapitalization,
    );
  }
}

/// Adaptive context menu (popup menu)
Future<T?> showAdaptiveContextMenu<T>({
  required BuildContext context,
  required List<AdaptiveMenuItem<T>> items,
  RelativeRect? position,
}) {
  if (PlatformCapabilities.prefersCupertino) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: items.where((item) => !item.isCancel).map((item) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop(item.value);
              item.onTap?.call();
            },
            isDestructiveAction: item.isDestructive,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item.icon != null) ...[
                  Icon(item.icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(item.label),
              ],
            ),
          );
        }).toList(),
        cancelButton: items.any((item) => item.isCancel)
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              )
            : null,
      ),
    );
  }

  return showMenu<T>(
    context: context,
    position: position ?? const RelativeRect.fromLTRB(0, 0, 0, 0),
    items: items.map((item) {
      return PopupMenuItem<T>(
        value: item.value,
        onTap: item.onTap,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 20,
                color: item.isDestructive ? Colors.red : null,
              ),
              const SizedBox(width: 12),
            ],
            Text(
              item.label,
              style: TextStyle(
                color: item.isDestructive ? Colors.red : null,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

/// Menu item for adaptive context menu
class AdaptiveMenuItem<T> {
  final String label;
  final T value;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isCancel;

  const AdaptiveMenuItem({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.isDestructive = false,
    this.isCancel = false,
  });
}

/// Adaptive modal bottom sheet that adapts to platform
Future<T?> showAdaptiveModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
}) {
  // On desktop/web with large screens, show as dialog instead
  if (PlatformDetector.isDesktop ||
      (PlatformDetector.isWeb && MediaQuery.of(context).size.width > 900)) {
    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: builder(context),
        ),
      ),
    );
  }

  // Mobile: use bottom sheet
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}
