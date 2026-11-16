import 'dart:math' as math;
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
    return _ChipLabelLayout(
      label: label,
      labelStyle: labelStyle,
      selected: selected,
      showCheckmark:
          (showCheckmark ??
          Theme.of(context).chipTheme.showCheckmark ??
          Theme.of(context).useMaterial3),
      builder: (chipLabel, wraps) => Theme(
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
            label: chipLabel,
            selected: selected,
            onSelected: onSelected,
            showCheckmark: wraps ? false : showCheckmark,
            checkmarkColor: colors.onPrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: outline,
            side: outline.side,
            selectedColor: enabledSelection ? Colors.transparent : null,
            backgroundColor:
                backgroundColor ?? AppColors.settingsCardBackground,
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
    return _ChipLabelLayout(
      label: label,
      labelStyle: null,
      selected: false,
      showCheckmark: false,
      builder: (chipLabel, wraps) => Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: outline,
            gradient: onPressed == null
                ? null
                : AppGradients.primaryBanner(colors),
          ),
          child: ActionChip(
            label: chipLabel,
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
      ),
    );
  }
}

/// RawChip defaults to a single non-wrapping line. Keep its themed text style
/// while allowing a constrained label to determine the chip's required height.
class _WrappingChipLabel extends StatelessWidget {
  const _WrappingChipLabel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: defaults.style,
      textAlign: defaults.textAlign,
      textWidthBasis: defaults.textWidthBasis,
      textHeightBehavior: defaults.textHeightBehavior,
      softWrap: true,
      overflow: TextOverflow.clip,
      child: child,
    );
  }
}

/// RawChip measures a label before subtracting padding and the checkmark. Bound
/// long labels first so both of its layout passes use the same available width.
class _ChipLabelLayout extends StatelessWidget {
  const _ChipLabelLayout({
    required this.label,
    required this.labelStyle,
    required this.selected,
    required this.showCheckmark,
    required this.builder,
  });
  final Widget label;
  final TextStyle? labelStyle;
  final bool selected;
  final bool showCheckmark;
  final Widget Function(Widget label, bool wraps) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final text = label;
      if (text is! Text || !constraints.maxWidth.isFinite) {
        return builder(label, false);
      }
      final theme = Theme.of(context);
      var style =
          (theme.textTheme.labelLarge ?? DefaultTextStyle.of(context).style)
              .merge(theme.chipTheme.labelStyle)
              .merge(labelStyle)
              .merge(text.style);
      if (MediaQuery.boldTextOf(context)) {
        style = style.copyWith(fontWeight: FontWeight.bold);
      }
      final painter = TextPainter(
        text: TextSpan(
          style: style,
          text: text.data,
          children: text.textSpan == null ? null : [text.textSpan!],
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout();
      final checkWidth = selected && showCheckmark
          ? math.max(24.0, painter.height)
          : 0.0;
      // Reserve the existing Material padding before constraining the label.
      final horizontalPadding =
          (theme.chipTheme.padding?.horizontal ?? 16.0) +
          (theme.chipTheme.labelPadding?.horizontal ?? 16.0);
      final needsWrap =
          painter.width > constraints.maxWidth - horizontalPadding - checkWidth;
      painter.dispose();
      if (!needsWrap) return builder(label, false);
      return builder(
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.max(1.0, constraints.maxWidth - horizontalPadding),
          ),
          child: _WrappingChipLabel(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected && showCheckmark) ...[
                  ExcludeSemantics(
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(child: label),
              ],
            ),
          ),
        ),
        true,
      );
    },
  );
}
