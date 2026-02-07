import 'package:flutter/material.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final double borderRadius;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool hasBorder;
  final Color? borderColor;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius = 8,
    this.fontWeight = FontWeight.bold,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    this.elevation = 0,
    this.hasBorder = false,
    this.borderColor,
    this.icon,
    this.iconSize = 20,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            border: hasBorder
                ? Border.all(color: borderColor ?? Colors.blue, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? textColor ?? Colors.white,
                  size: iconSize,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: AppTextStyles.whiteBold.copyWith(
                  color: textColor,
                  fontSize: fontSize ?? 16,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

