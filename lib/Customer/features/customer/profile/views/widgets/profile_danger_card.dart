import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileDangerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const ProfileDangerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = Colors.orangeAccent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? color.withOpacity(.1) : color.withOpacity(.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: "Cairo",
                color: isDark ? color : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
