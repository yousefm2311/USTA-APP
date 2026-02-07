import 'package:flutter/material.dart';

class SettingsSegOption {
  final String value;
  final String label;

  const SettingsSegOption({required this.value, required this.label});
}

class SettingsSegmentedRow extends StatelessWidget {
  final String title;
  final List<SettingsSegOption> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const SettingsSegmentedRow({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = scheme.surface;
    final border = scheme.outlineVariant.withOpacity(0.55);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final itemW = (w - ((options.length - 1) * 8)) / options.length;

              return Row(
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    _SegmentItem(
                      width: itemW,
                      label: options[i].label,
                      selected: options[i].value == selected,
                      onTap: () => onSelect(options[i].value),
                      isDark: isDark,
                    ),
                    if (i != options.length - 1) const SizedBox(width: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _SegmentItem({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final selBg = scheme.primary.withOpacity(isDark ? 0.22 : 0.14);
    final selBorder = scheme.primary.withOpacity(isDark ? 0.35 : 0.30);
    final selText = scheme.primary;

    final unBg = scheme.surface;
    final unBorder = scheme.outlineVariant.withOpacity(0.55);
    final unText = scheme.onSurface.withOpacity(0.78);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selBg : unBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? selBorder : unBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: selected ? selText : unText,
            ),
          ),
        ),
      ),
    );
  }
}
