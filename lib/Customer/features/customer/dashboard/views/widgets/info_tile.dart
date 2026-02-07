import 'package:flutter/material.dart';

Widget infoTile(String title, String value, context) {
  final schema = Theme.of(context).colorScheme;
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: schema.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontFamily: "Cairo", fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
