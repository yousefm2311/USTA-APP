import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanNotificationDetailsView extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final String type;
  final VoidCallback? onOpenRequest;

  const ArtisanNotificationDetailsView({
    super.key,
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    this.onOpenRequest,
  });

  Color get primaryBlue => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.notifications.tr,
          style: const TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryBlue.withOpacity(0.15),
                    child: Icon(
                      type == "request"
                          ? Icons.assignment
                          : type == "chat"
                              ? Icons.chat
                              : Icons.notifications,
                      color: primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.title(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: "Cairo",
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (type.toLowerCase().contains("request") &&
                  onOpenRequest != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onOpenRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      AppStrings.open.tr,
                      style: const TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

