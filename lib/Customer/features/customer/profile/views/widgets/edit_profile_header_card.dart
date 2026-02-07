import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileHeaderCard extends StatelessWidget {
  final ImageProvider? imageProvider;
  final bool uploading;
  final VoidCallback onPick;
  final Color primaryColor;

  const EditProfileHeaderCard({
    super.key,
    required this.imageProvider,
    required this.uploading,
    required this.onPick,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _EditProfileAvatar(
            imageProvider: imageProvider,
            uploading: uploading,
            onTap: onPick,
            primaryColor: primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الصورة الشخصية'.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اضغط على الصورة لتغييرها.'.tr,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: uploading ? null : onPick,
                    icon: const Icon(
                      Icons.photo_camera_back_outlined,
                      size: 18,
                    ),
                    label: Text(
                      uploading ? 'جارٍ الرفع...'.tr : 'تغيير الصورة'.tr,
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileAvatar extends StatelessWidget {
  final ImageProvider? imageProvider;
  final bool uploading;
  final VoidCallback onTap;
  final Color primaryColor;

  const _EditProfileAvatar({
    required this.imageProvider,
    required this.uploading,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: isDark ? Colors.white10 : Colors.black38,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          if (uploading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}
