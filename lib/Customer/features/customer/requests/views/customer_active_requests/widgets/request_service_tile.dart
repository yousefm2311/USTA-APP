import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestServiceTile extends StatelessWidget {
  const RequestServiceTile({
    super.key,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.cardColor,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color cardColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(
              name.tr,
              style: const TextStyle(
                fontFamily: "Cairo",
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
