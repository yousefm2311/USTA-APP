import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanNotificationSettingsView extends StatefulWidget {
  const ArtisanNotificationSettingsView({super.key});

  @override
  State<ArtisanNotificationSettingsView> createState() =>
      _ArtisanNotificationSettingsViewState();
}

class _ArtisanNotificationSettingsViewState
    extends State<ArtisanNotificationSettingsView> {
  Color get primaryBlue => const Color(0xFF2563EB);
  Color get cardDark => const Color(0xFF0B1020);
  Color get darkBg => const Color(0xFF050816);

  bool newRequests = true;
  bool chatMessages = true;
  bool appUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "إعدادات الإشعارات",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _switchTile(
            title: "إشعارات الطلبات الجديدة",
            value: newRequests,
            onChanged: (v) => setState(() => newRequests = v),
          ),
          _switchTile(
            title: "رسائل الشات",
            value: chatMessages,
            onChanged: (v) => setState(() => chatMessages = v),
          ),
          _switchTile(
            title: "تحديثات التطبيق",
            value: appUpdates,
            onChanged: (v) => setState(() => appUpdates = v),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.body(context),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

