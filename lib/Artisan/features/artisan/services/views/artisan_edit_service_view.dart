import 'package:flutter/material.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';

class ArtisanEditServiceView extends StatefulWidget {
  final String initialName;
  final String initialPrice;
  final String initialDesc;

  const ArtisanEditServiceView({
    super.key,
    required this.initialName,
    required this.initialPrice,
    required this.initialDesc,
  });

  @override
  State<ArtisanEditServiceView> createState() => _ArtisanEditServiceViewState();
}

class _ArtisanEditServiceViewState extends State<ArtisanEditServiceView> {
  Color get darkBg => const Color(0xFF050816);
  Color get cardDark => const Color(0xFF0B1020);
  Color get primaryBlue => const Color(0xFF2563EB);

  late TextEditingController nameCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName);
    priceCtrl = TextEditingController(text: widget.initialPrice);
    descCtrl = TextEditingController(text: widget.initialDesc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "تعديل الخدمة",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label("اسم الخدمة"),
          _inputField(nameCtrl),

          const SizedBox(height: 18),
          _label("السعر (جنيه)"),
          _inputField(priceCtrl, keyboard: TextInputType.number),

          const SizedBox(height: 18),
          _label("وصف الخدمة"),
          _inputField(descCtrl, maxLines: 4),

          const SizedBox(height: 25),
          _saveButton(),

          const SizedBox(height: 16),
          _deleteButton(),
        ],
      ),
    );
  }

  Widget _label(String txt) {
    return Text(
      txt,
      style: AppTextStyles.body(context).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      )
    );
  }

  Widget _inputField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),

      child: TextField(
        
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: AppTextStyles.body(context),
        decoration:  InputDecoration(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white30),
          labelStyle: AppTextStyles.body(context),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlueAccent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "حفظ التعديلات",
          style: TextStyle(
            fontFamily: "Cairo",
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "حذف الخدمة",
          style: TextStyle(
            fontFamily: "Cairo",
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

