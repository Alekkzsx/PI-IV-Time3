// Design system modular para o AVA Docente (alinhado ao ecossistema institucional AGMRM).

import 'package:flutter/material.dart';
import 'package:pi_iv_time3/core/theme/jakarta_text.dart';

enum CourseHubBadgeTone { neutral, success, warning, danger, info }

enum CourseHubButtonVariant { primary, secondary, danger }

class CourseHubBadge extends StatelessWidget {
  final String label;
  final CourseHubBadgeTone tone;
  final IconData? icon;

  const CourseHubBadge({
    super.key,
    required this.label,
    this.tone = CourseHubBadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg) = switch (tone) {
      CourseHubBadgeTone.success => (
        const Color(0xFFDCFCE7),
        const Color(0xFFBBF7D0),
        const Color(0xFF166534),
      ),
      CourseHubBadgeTone.warning => (
        const Color(0xFFFEF3C7),
        const Color(0xFFFDE68A),
        const Color(0xFFB45309),
      ),
      CourseHubBadgeTone.danger => (
        const Color(0xFFFEE2E2),
        const Color(0xFFFECACA),
        const Color(0xFFB91C1C),
      ),
      CourseHubBadgeTone.info => (
        const Color(0xFFEFF6FF),
        const Color(0xFFBFDBFE),
        const Color(0xFF1D4ED8),
      ),
      CourseHubBadgeTone.neutral => (
        const Color(0xFFF4F4F5),
        const Color(0xFFE4E4E7),
        const Color(0xFF52525B),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: jakarta(size: 11, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

class CourseHubPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final CourseHubButtonVariant variant;
  final bool isLoading;
  final bool compact;

  const CourseHubPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = CourseHubButtonVariant.primary,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 7 : 10,
    );

    if (variant == CourseHubButtonVariant.primary) {
      return ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF18181B),
          disabledBackgroundColor: const Color(0xFFE4E4E7),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF71717A),
          elevation: 0,
          padding: padding,
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _buildContent(
          isDisabled ? const Color(0xFF71717A) : Colors.white,
        ),
      );
    }

    final borderColor = variant == CourseHubButtonVariant.danger
        ? const Color(0xFFFECACA)
        : const Color(0xFFE5E7EB);
    final textColor = variant == CourseHubButtonVariant.danger
        ? const Color(0xFFB91C1C)
        : const Color(0xFF18181B);

    return OutlinedButton(
      onPressed: isDisabled ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        elevation: 0,
        padding: padding,
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: _buildContent(isDisabled ? const Color(0xFFA1A1AA) : textColor),
    );
  }

  Widget _buildContent(Color fg) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: 7),
        ] else if (icon != null) ...[
          Icon(icon, size: compact ? 14 : 15, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: jakarta(
            size: compact ? 11.5 : 12.5,
            weight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );
  }
}

class CourseHubSectionHeader extends StatelessWidget {
  final String? overline;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const CourseHubSectionHeader({
    super.key,
    this.overline,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overline != null && overline!.isNotEmpty) ...[
              Text(
                overline!.toUpperCase(),
                style: jakarta(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFF71717A),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              title,
              style: jakarta(
                size: 16.5,
                weight: FontWeight.w700,
                color: const Color(0xFF18181B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: jakarta(
                size: 12.5,
                weight: FontWeight.w400,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        );

        if (trailing == null) return heading;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 12),
              trailing!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            trailing!,
          ],
        );
      },
    );
  }
}

class CourseHubSurfaceCard extends StatelessWidget {
  final String? overlineTag;
  final String? title;
  final String? subtitle;
  final Widget? headerTrailing;
  final Widget child;
  final EdgeInsetsGeometry bodyPadding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const CourseHubSurfaceCard({
    super.key,
    this.overlineTag,
    this.title,
    this.subtitle,
    this.headerTrailing,
    required this.child,
    this.bodyPadding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBannerHeader =
        (overlineTag != null && overlineTag!.isNotEmpty) ||
        (title != null && title!.isNotEmpty) ||
        headerTrailing != null;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasBannerHeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overlineTag != null && overlineTag!.isNotEmpty) ...[
                          Text(
                            overlineTag!.toUpperCase(),
                            style: jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: const Color(0xFF71717A),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        if (title != null && title!.isNotEmpty)
                          Text(
                            title!,
                            style: jakarta(
                              size: 14.5,
                              weight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: jakarta(
                              size: 12,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerTrailing != null) ...[
                    const SizedBox(width: 12),
                    headerTrailing!,
                  ],
                ],
              ),
            ),
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );

    final wrapped = onTap == null
        ? cardContent
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: cardContent,
          );

    return margin == null ? wrapped : Container(margin: margin, child: wrapped);
  }
}

class CourseHubKpiSpec {
  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;

  const CourseHubKpiSpec({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueColor = const Color(0xFF18181B),
  });
}

class CourseHubKpiRow extends StatelessWidget {
  final List<CourseHubKpiSpec> items;

  const CourseHubKpiRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: _buildKpiCard(items[i])),
                ],
              ],
            ),
          );
        }

        final columns = constraints.maxWidth >= 460 ? 2 : 1;
        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += columns) {
          if (i > 0) rows.add(const SizedBox(height: 12));
          final rowItems = items.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: 12),
                    Expanded(
                      child: c < rowItems.length
                          ? _buildKpiCard(rowItems[c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }

  Widget _buildKpiCard(CourseHubKpiSpec item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.label,
            style: jakarta(
              size: 11.5,
              weight: FontWeight.w500,
              color: const Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              maxLines: 1,
              style: jakarta(
                size: 20,
                weight: FontWeight.w700,
                color: item.valueColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: jakarta(size: 11, color: const Color(0xFF71717A)),
          ),
        ],
      ),
    );
  }
}

class CourseHubFilterBar extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Map<String, int>? counts;
  final ValueChanged<String> onSelected;

  const CourseHubFilterBar({
    super.key,
    required this.options,
    required this.selected,
    this.counts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        final count = counts?[opt];
        final text = count == null ? opt : '$opt ($count)';
        return InkWell(
          onTap: () => onSelected(opt),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF18181B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF18181B)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              text,
              style: jakarta(
                size: 12,
                weight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF52525B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CourseHubSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final double width;
  final ValueChanged<String> onChanged;

  const CourseHubSearchField({
    super.key,
    this.controller,
    required this.hintText,
    this.width = 240,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: jakarta(size: 12.5, color: const Color(0xFF18181B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: jakarta(size: 12, color: const Color(0xFFA1A1AA)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 16,
            color: Color(0xFF71717A),
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF18181B)),
          ),
        ),
      ),
    );
  }
}

class CourseHubEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CourseHubEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFAF8F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF71717A)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: jakarta(
              size: 14,
              weight: FontWeight.w700,
              color: const Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: jakarta(size: 12.5, color: const Color(0xFF71717A)),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            CourseHubPillButton(
              label: actionLabel!,
              icon: Icons.add_rounded,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class CourseHubModal extends StatefulWidget {
  final String? overlineTag;
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;
  final EdgeInsetsGeometry bodyPadding;
  final List<ChangeNotifier> disposeOnClose;

  const CourseHubModal({
    super.key,
    this.overlineTag,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.maxWidth = 600,
    this.bodyPadding = const EdgeInsets.all(20),
    this.disposeOnClose = const [],
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? overlineTag,
    required String title,
    String? subtitle,
    required WidgetBuilder builder,
    List<Widget>? Function(BuildContext dialogContext)? actionsBuilder,
    double maxWidth = 600,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.all(20),
    List<ChangeNotifier> disposeOnClose = const [],
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogCtx) => CourseHubModal(
        overlineTag: overlineTag,
        title: title,
        subtitle: subtitle,
        maxWidth: maxWidth,
        bodyPadding: bodyPadding,
        disposeOnClose: disposeOnClose,
        actions: actionsBuilder?.call(dialogCtx),
        child: builder(dialogCtx),
      ),
    );
  }

  @override
  State<CourseHubModal> createState() => _CourseHubModalState();
}

class _CourseHubModalState extends State<CourseHubModal> {
  @override
  void dispose() {
    for (final notifier in widget.disposeOnClose) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 520;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: isCompact ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.overlineTag != null &&
                            widget.overlineTag!.isNotEmpty) ...[
                          Text(
                            widget.overlineTag!.toUpperCase(),
                            style: jakarta(
                              size: 10,
                              weight: FontWeight.w700,
                              color: const Color(0xFF71717A),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          widget.title,
                          style: jakarta(
                            size: 16.5,
                            weight: FontWeight.w700,
                            color: const Color(0xFF18181B),
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle!,
                            style: jakarta(
                              size: 12.5,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF71717A),
                    ),
                    tooltip: 'Fechar',
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: widget.bodyPadding,
                child: widget.child,
              ),
            ),
            if (widget.actions != null && widget.actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: widget.actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

InputDecoration courseHubInputDecoration({
  String? hintText,
  String? labelText,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: jakarta(size: 12.5, color: const Color(0xFFA1A1AA)),
    labelStyle: jakarta(
      size: 12,
      weight: FontWeight.w500,
      color: const Color(0xFF52525B),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF18181B), width: 1.5),
    ),
  );
}
