import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/features/artisan/notifications/controllers/notifications_controller.dart';

class ArtisanNotificationsSettingsView extends StatefulWidget {
  const ArtisanNotificationsSettingsView({super.key});

  @override
  State<ArtisanNotificationsSettingsView> createState() =>
      _ArtisanNotificationsSettingsViewState();
}

class _ArtisanNotificationsSettingsViewState
    extends State<ArtisanNotificationsSettingsView> {
  late final NotificationsController controller;

  bool marketing = true;
  bool requests = true;
  bool chat = true;
  bool saving = false;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    if (controller.settings.isNotEmpty) {
      marketing = controller.settings['marketing'] ?? marketing;
      requests = controller.settings['requests'] ?? requests;
      chat = controller.settings['chat'] ?? chat;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    final fetched = await controller.fetchSettings();
    if (!mounted) return;
    setState(() {
      loaded = true;
      marketing = fetched['marketing'] ?? marketing;
      requests = fetched['requests'] ?? requests;
      chat = fetched['chat'] ?? chat;
    });
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await controller.updateSettings({
      'marketing': marketing,
      'requests': requests,
      'chat': chat,
    });
    setState(() => saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.notifications.tr),
      ),
      body: loaded
          ? ListView(
              children: [
                _tile(
                  title: AppStrings.notifMarketing.tr,
                  value: marketing,
                  onChanged: (v) => setState(() => marketing = v),
                ),
                _tile(
                  title: AppStrings.notifRequests.tr,
                  value: requests,
                  onChanged: (v) => setState(() => requests = v),
                ),
                _tile(
                  title: AppStrings.notifChat.tr,
                  value: chat,
                  onChanged: (v) => setState(() => chat = v),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ElevatedButton(
                    onPressed: saving ? null : _save,
                    child: saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.save.tr),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _tile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

