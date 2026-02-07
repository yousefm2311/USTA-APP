import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/app_snackbar.dart';

class ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final int maxLines;
  final Color primaryColor;
  final VoidCallback? onTap;

  const ProfileInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
    this.maxLines = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value?.toString().isNotEmpty == true ? value.toString() : "-";

    final tile = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(onTap: onTap, child: tile);
  }
}

class ProfileCopyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color primaryColor;

  const ProfileCopyTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = value?.toString().isNotEmpty == true ? value.toString() : "-";
    return ProfileInfoTile(
      icon: icon,
      label: label,
      value: text,
      primaryColor: primaryColor,
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        AppSnackBar.show(
          "تم النسخ".tr,
          label,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }
}


