import 'package:flutter/material.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color primaryColor;
  final int? badgeCount;

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.primaryColor,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final leadingIcon = Icon(icon, color: primaryColor);
    final leading = (badgeCount != null && badgeCount! > 0)
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              leadingIcon,
              Positioned(
                top: -6,
                right: -6,
                child: _ProfileBadge(count: badgeCount!),
              ),
            ],
          )
        : leadingIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final int count;

  const _ProfileBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
