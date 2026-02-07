import 'package:flutter/material.dart';

class ProfileQuickActionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileQuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class ProfileQuickActions extends StatelessWidget {
  final List<ProfileQuickActionItem> actions;
  final Color primaryColor;

  const ProfileQuickActions({
    super.key,
    required this.actions,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: _ProfileQuickButton(
                icon: a.icon,
                title: a.title,
                onTap: a.onTap,
                primaryColor: primaryColor,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProfileQuickButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ProfileQuickButton({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontFamily: "Cairo",
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
