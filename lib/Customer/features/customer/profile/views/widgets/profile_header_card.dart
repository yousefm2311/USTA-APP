import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final bool online;
  final ImageProvider? imageProvider;
  final Color primaryColor;
  final Color cardColor;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.online,
    required this.imageProvider,
    required this.primaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim().characters.first : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.3), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: primaryColor.withOpacity(.15),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    initial,
                    style: TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontFamily: "Cairo",
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                _ProfileStatusChip(online: online),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusChip extends StatelessWidget {
  final bool online;

  const _ProfileStatusChip({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: online
            ? Colors.green.withOpacity(.15)
            : Colors.orange.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        online ? "متصل".tr : "غير متاح".tr,
        style: TextStyle(
          fontFamily: "Cairo",
          fontSize: 11,
          color: online ? Colors.greenAccent : Colors.orangeAccent,
        ),
      ),
    );
  }
}
