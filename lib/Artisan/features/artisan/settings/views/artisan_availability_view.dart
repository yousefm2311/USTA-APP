import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/profile/controllers/profile_controller.dart';

class ArtisanAvailabilityView extends StatefulWidget {
  const ArtisanAvailabilityView({super.key});

  @override
  State<ArtisanAvailabilityView> createState() =>
      _ArtisanAvailabilityViewState();
}

class _ArtisanAvailabilityViewState extends State<ArtisanAvailabilityView> {
  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  String status = "available"; // available, busy, offline
  TimeOfDay? returnTime;
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    _syncStatusFromProfile();
    ever(profileController.profile, (_) {
      if (mounted) _syncStatusFromProfile();
    });
  }

  void _syncStatusFromProfile() {
    final online = profileController.profile['online'];
    final profStatus =
        (profileController.profile['status'] ?? '').toString().toLowerCase();
    String next = status;
    if (online == false) {
      next = 'offline';
    } else if (profStatus == 'busy') {
      next = 'busy';
    } else if (profStatus == 'available' || profStatus.isNotEmpty) {
      next = 'available';
    }
    if (next != status) {
      setState(() {
        status = next;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "حالة التوفر",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("حالتي الآن"),
          _statusSelector(),

          const SizedBox(height: 25),
          if (status == "busy") _returnTimeSelector(),

          const SizedBox(height: 25),
          _scheduleSection(),

          const SizedBox(height: 40),
          _saveButton(),
        ],
      ),
    );
  }

  // -------------------
  // Section Title
  // -------------------
  Widget _sectionTitle(String txt) {
    return Text(
      txt,
      style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
    );
  }

  // -------------------
  // Status Buttons
  // -------------------
  Widget _statusSelector() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _statusOption(
          "متاح للعمل",
          "available",
          Icons.check_circle,
          Colors.greenAccent,
        ),
        _statusOption(
          "مشغول حاليًا",
          "busy",
          Icons.timelapse,
          Colors.amberAccent,
        ),
        _statusOption(
          "غير متاح",
          "offline",
          Icons.do_not_disturb_on,
          Colors.redAccent,
        ),
      ],
    );
  }

  Widget _statusOption(String title, String value, IconData icon, Color color) {
    bool active = status == value;

    return InkWell(
      onTap: () => setState(() => status = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? primaryBlue : Colors.white10,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (active) Icon(Icons.check, color: primaryBlue, size: 22),
          ],
        ),
      ),
    );
  }

  // -------------------
  // Busy Return Time
  // -------------------
  Widget _returnTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("سأكون متاحًا مرة أخرى الساعة"),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) setState(() => returnTime = time);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: primaryBlue),
                const SizedBox(width: 12),
                Text(
                  returnTime == null
                      ? "اختر الوقت"
                      : "${returnTime!.hour}:${returnTime!.minute.toString().padLeft(2, '0')}",
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------
  // Schedule
  // -------------------
  Widget _scheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("أوقات العمل (اختياري)"),
        const SizedBox(height: 10),

        _daySchedule("السبت"),
        _daySchedule("الأحد"),
        _daySchedule("الاثنين"),
        _daySchedule("الثلاثاء"),
        _daySchedule("الأربعاء"),
        _daySchedule("الخميس"),
        _daySchedule("الجمعة"),
      ],
    );
  }

  Widget _daySchedule(String day) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            day,
            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Icon(Icons.schedule, color: primaryBlue),
          const SizedBox(width: 6),
          Text(
            "اضبط الوقت",
            style: AppTextStyles.small(context),
          ),
        ],
      ),
    );
  }

  // -------------------
  // Save Button
  // -------------------
  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          DateTime? unavailable;
          if (status == "busy" && returnTime != null) {
            final now = DateTime.now();
            unavailable = DateTime(
              now.year,
              now.month,
              now.day,
              returnTime!.hour,
              returnTime!.minute,
            );
          }

          final online = status != "offline";
          await profileController.toggleOnline(
            online,
            unavailableUntil: unavailable,
          );
          if (!online) {
            await profileController.setAvailability([]);
          }
          if (mounted) Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "حفظ الحالة",
          style: TextStyle(fontFamily: "Cairo", fontSize: 16),
        ),
      ),
    );
  }
}

