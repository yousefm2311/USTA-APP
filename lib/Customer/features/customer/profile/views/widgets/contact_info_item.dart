import 'package:flutter/material.dart';

class ContactInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const ContactInfoItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontFamily: "Cairo", color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(fontFamily: "Cairo", color: Colors.white),
          ),
        ],
      ),
    );
  }
}
