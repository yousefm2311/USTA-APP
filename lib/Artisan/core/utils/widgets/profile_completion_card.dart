import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ProfileCompletionItem {
  final String key;
  final String label;
  final VoidCallback? onTap;
  final List<String> aliases;

  const ProfileCompletionItem({
    required this.key,
    required this.label,
    this.onTap,
    this.aliases = const [],
  });
}

class ProfileCompletionChecklist extends StatelessWidget {
  final List<ProfileCompletionItem> items;
  final List<String> missingFields;
  final String missingCtaLabel;
  final String emptyLabel;

  const ProfileCompletionChecklist({
    super.key,
    required this.items,
    required this.missingFields,
    required this.missingCtaLabel,
    this.emptyLabel = 'No checklist items available.',
  });

  @override
  Widget build(BuildContext context) {
    final missing = normalizeMissing(missingFields);
    if (items.isEmpty) {
      return Text(emptyLabel, style: AppTextStyles.caption(context));
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isMissing = isMissingItem(item, missing);
        final row = _buildChecklistRow(context, item, isMissing);
        if (index == items.length - 1) return row;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: row,
        );
      }),
    );
  }

  static Set<String> normalizeMissing(List<String> raw) {
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static bool isMissingItem(ProfileCompletionItem item, Set<String> missing) {
    final key = item.key.trim().toLowerCase();
    if (key.isNotEmpty && missing.contains(key)) return true;
    for (final alias in item.aliases) {
      final normalized = alias.trim().toLowerCase();
      if (normalized.isNotEmpty && missing.contains(normalized)) return true;
    }
    return false;
  }

  Widget _buildChecklistRow(
    BuildContext context,
    ProfileCompletionItem item,
    bool isMissing,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = isMissing ? Colors.orangeAccent : Colors.green;
    final borderColor = isMissing
        ? Colors.orangeAccent.withOpacity(0.35)
        : scheme.outline.withOpacity(0.12);
    final bgColor = isMissing
        ? Colors.orangeAccent.withOpacity(0.10)
        : scheme.surfaceVariant.withOpacity(0.25);
    final textColor =
        isMissing ? scheme.onSurface : scheme.onSurface.withOpacity(0.7);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            isMissing ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: AppTextStyles.small(context).copyWith(
                fontWeight: isMissing ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          if (isMissing && item.onTap != null) ...[
            Text(
              missingCtaLabel,
              style: AppTextStyles.caption(context).copyWith(
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: iconColor,
            ),
          ],
        ],
      ),
    );

    if (isMissing && item.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14),
          child: content,
        ),
      );
    }

    return content;
  }
}

class ProfileCompletionCard extends StatelessWidget {
  final int completionPercent;
  final List<String> missingFields;
  final List<ProfileCompletionItem> items;
  final String title;
  final String? subtitle;
  final bool showSuccessOnComplete;
  final String successMessage;
  final String missingCtaLabel;
  final String Function(int percent)? percentLabelBuilder;
  final Color Function(int percent, ColorScheme scheme)? colorResolver;
  final EdgeInsetsGeometry padding;
  final String emptyChecklistLabel;

  const ProfileCompletionCard({
    super.key,
    required this.completionPercent,
    required this.missingFields,
    required this.items,
    this.title = 'Complete your profile',
    this.subtitle,
    this.showSuccessOnComplete = false,
    this.successMessage = 'Profile complete. You are ready to go.',
    this.missingCtaLabel = 'Update',
    this.percentLabelBuilder,
    this.colorResolver,
    this.padding = const EdgeInsets.all(16),
    this.emptyChecklistLabel = 'No checklist items available.',
  });

  @override
  Widget build(BuildContext context) {
    final int percent = completionPercent.clamp(0, 100).toInt();
    if (percent >= 100 && !showSuccessOnComplete) {
      return const SizedBox.shrink();
    }
    if (percent >= 100) {
      return _successCard(context);
    }

    final scheme = Theme.of(context).colorScheme;
    final accent = (colorResolver ?? _defaultColorResolver)(percent, scheme);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              scheme.brightness == Brightness.dark ? 0.20 : 0.06,
            ),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_turned_in_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body(context).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.small(context).copyWith(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  color: accent,
                  backgroundColor: accent.withOpacity(0.18),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              percentLabelBuilder?.call(percent) ?? '$percent% completed',
              style: AppTextStyles.caption(context).copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ProfileCompletionChecklist(
            items: items,
            missingFields: missingFields,
            missingCtaLabel: missingCtaLabel,
            emptyLabel: emptyChecklistLabel,
          ),
        ],
      ),
    );
  }

  Color _defaultColorResolver(int percent, ColorScheme scheme) {
    if (percent >= 100) return Colors.green;
    if (percent < 50) return Colors.redAccent;
    if (percent < 80) return Colors.orangeAccent;
    return Colors.orangeAccent;
  }

  Widget _successCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                scheme.brightness == Brightness.dark ? 0.20 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                successMessage,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileCompletionBottomSheet extends StatefulWidget {
  final int completionPercent;
  final List<String> missingFields;
  final List<ProfileCompletionItem> items;
  final String title;
  final String? subtitle;
  final String missingCtaLabel;
  final String primaryCtaLabel;
  final VoidCallback? onPrimaryCta;
  final VoidCallback? onHide;
  final String hideLabel;
  final String expandLabel;
  final String collapseLabel;
  final String emptyChecklistLabel;
  final int collapsedItemCount;
  final double minHeight;
  final double maxHeightFactor;
  final String Function(int percent)? percentLabelBuilder;
  final Color Function(int percent, ColorScheme scheme)? colorResolver;

  const ProfileCompletionBottomSheet({
    super.key,
    required this.completionPercent,
    required this.missingFields,
    required this.items,
    this.title = 'Complete your profile',
    this.subtitle,
    this.missingCtaLabel = 'Update',
    this.primaryCtaLabel = 'Complete missing',
    this.onPrimaryCta,
    this.onHide,
    this.hideLabel = 'Hide',
    this.expandLabel = 'View details',
    this.collapseLabel = 'Hide details',
    this.emptyChecklistLabel = 'No checklist items available.',
    this.collapsedItemCount = 2,
    this.minHeight = 200,
    this.maxHeightFactor = 0.6,
    this.percentLabelBuilder,
    this.colorResolver,
  });

  @override
  State<ProfileCompletionBottomSheet> createState() =>
      _ProfileCompletionBottomSheetState();
}

class _ProfileCompletionBottomSheetState
    extends State<ProfileCompletionBottomSheet> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final int percent = widget.completionPercent.clamp(0, 100).toInt();
    if (percent >= 100) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final accent =
        (widget.colorResolver ?? _defaultColorResolver)(percent, scheme);
    final percentLabel =
        widget.percentLabelBuilder?.call(percent) ?? '$percent% completed';

    final missing = ProfileCompletionChecklist.normalizeMissing(
      widget.missingFields,
    );
    final missingItems = widget.items
        .where((item) => ProfileCompletionChecklist.isMissingItem(item, missing))
        .toList();
    final collapsedSource = missingItems.isNotEmpty ? missingItems : widget.items;
    final collapsedItems =
        collapsedSource.take(widget.collapsedItemCount).toList();
    final displayItems = _expanded ? widget.items : collapsedItems;

    final showToggle = widget.items.length > widget.collapsedItemCount;
    final actionButtons = <Widget>[];
    if (widget.onHide != null) {
      actionButtons.add(
        TextButton.icon(
          onPressed: widget.onHide,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurface.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            backgroundColor: scheme.surfaceVariant.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: Text(
            widget.hideLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (widget.onPrimaryCta != null) {
      actionButtons.add(
        ElevatedButton.icon(
          onPressed: widget.onPrimaryCta,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.task_alt_rounded, size: 18),
          label: Text(
            widget.primaryCtaLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (showToggle) {
      actionButtons.add(
        TextButton(
          onPressed: _toggleExpanded,
          style: TextButton.styleFrom(
            foregroundColor: accent,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            backgroundColor: accent.withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? widget.collapseLabel : widget.expandLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    final maxHeight = MediaQuery.of(context).size.height * widget.maxHeightFactor;
    final height = _expanded ? maxHeight : widget.minHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: height,
      child: Material(
        color: scheme.surface,
        elevation: 16,
        shadowColor: Colors.black.withOpacity(
          scheme.brightness == Brightness.dark ? 0.28 : 0.12,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: showToggle ? _toggleExpanded : null,
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: _expanded
                    ? const BouncingScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTextStyles.body(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  percentLabel,
                                  style: AppTextStyles.caption(context).copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (actionButtons.isNotEmpty)
                            Flexible(
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.end,
                                  children: actionButtons,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 8,
                          color: accent,
                          backgroundColor: accent.withOpacity(0.18),
                        ),
                      ),
                      if (_expanded && widget.subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle!,
                          style: AppTextStyles.small(context).copyWith(
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ProfileCompletionChecklist(
                        items: displayItems,
                        missingFields: widget.missingFields,
                        missingCtaLabel: widget.missingCtaLabel,
                        emptyLabel: widget.emptyChecklistLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _defaultColorResolver(int percent, ColorScheme scheme) {
    if (percent >= 100) return Colors.green;
    if (percent < 50) return Colors.redAccent;
    if (percent < 80) return Colors.orangeAccent;
    return Colors.orangeAccent;
  }
}

