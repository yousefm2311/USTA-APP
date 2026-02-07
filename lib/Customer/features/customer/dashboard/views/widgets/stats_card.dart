import 'package:flutter/material.dart';

Widget statCard(
  String title,
  String value,
  IconData icon,
  Color color,
  bool loading,
  context,
) {
  final schema = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: schema.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white12),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.05),
          blurRadius: 7,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        if (loading)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontFamily: "Cairo",
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontFamily: "Cairo"),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
