import 'package:flutter/material.dart';
import 'package:usta/Customer/core/utils/constants/app_colors.dart';

class CustomMaterialButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final Color? splashColor;
  final IconData? icon;
  final double elevation;
  final double borderRadius;
  final double? width;
  final double? height;
  final bool isOutlined;
  final Color? borderColor;
  final FontWeight fontWeight;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  final AnimatedSwitcher? textWidget;

  const CustomMaterialButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.splashColor,
    this.icon,
    this.elevation = 2.0,
    this.borderRadius = 12,
    this.width,
    this.height,
    this.isOutlined = false,
    this.borderColor,
    this.fontWeight = FontWeight.bold,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.textWidget,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      color: isOutlined ? Colors.transparent : buttonColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: splashColor ?? Colors.white24,
        onTap: onPressed,
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: isOutlined
                ? Border.all(color: borderColor ?? buttonColor, width: 1.8)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: txtColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: txtColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

