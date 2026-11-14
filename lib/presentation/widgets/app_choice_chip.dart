import 'package:flutter/material.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_gradients.dart';

/// Native chip semantics and selection with the shared home-banner fill.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.labelStyle,
    this.backgroundColor,
    this.shape,
    this.side,
    this.showCheckmark,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final TextStyle? labelStyle;
  final Color? backgroundColor;
  final OutlinedBorder? shape;
  final BorderSide? side;
  final bool? showCheckmark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabledSelection = selected && onSelected != null;
    final outline = (shape ?? const StadiumBorder()).copyWith(
      side: enabledSelection
          ? BorderSide.none
          : side ?? const BorderSide(color: AppColors.settingsCardBorder),
    );
    return Theme(
      // RawChip owns a canvas Material beneath its Ink. Make that canvas
      // transparent as well so it cannot obscure the shared gradient.
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: outline,
          gradient: enabledSelection
              ? AppGradients.primaryBanner(colors)
              : null,
        ),
        child: ChoiceChip(
          label: label,
          selected: selected,
          onSelected: onSelected,
          showCheckmark: showCheckmark,
          checkmarkColor: colors.onPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: outline,
          side: outline.side,
          selectedColor: enabledSelection ? Colors.transparent : null,
          backgroundColor: backgroundColor ?? AppColors.settingsCardBackground,
          color: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Theme.of(context).disabledColor.withValues(alpha: 0.12);
            }
            return selected
                ? Colors.transparent
                : backgroundColor ?? AppColors.settingsCardBackground;
          }),
          surfaceTintColor: Colors.transparent,
          labelStyle: (labelStyle ?? const TextStyle()).copyWith(
            color: enabledSelection ? colors.onPrimary : labelStyle?.color,
          ),
        ),
      ),
    );
  }
}

class AppActionChip extends StatelessWidget {
  const AppActionChip({
    super.key,
    required this.label,
    this.onPressed,
    this.shape,
  });

  final Widget label;
  final VoidCallback? onPressed;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outline = (shape ?? const StadiumBorder()).copyWith(
      side: BorderSide.none,
    );
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: outline,
          gradient: onPressed == null
              ? null
              : AppGradients.primaryBanner(colors),
        ),
        child: ActionChip(
          label: label,
          onPressed: onPressed,
          shape: outline,
          side: BorderSide.none,
          backgroundColor: Colors.transparent,
          color: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: Colors.transparent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          labelStyle: TextStyle(color: colors.onPrimary),
        ),
      ),
    );
  }
}
