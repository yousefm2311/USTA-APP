import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CustomFilePickerField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? fillColor;
  final double borderRadius;
  final FormFieldValidator<String>? validator;
  final ValueChanged<PlatformFile>? onFileSelected;
  final bool enabled;

  const CustomFilePickerField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon = Icons.attach_file,
    this.fillColor,
    this.borderRadius = 12,
    this.validator,
    this.onFileSelected,
    this.enabled = true,
  });

  @override
  State<CustomFilePickerField> createState() => _CustomFilePickerFieldState();
}

class _CustomFilePickerFieldState extends State<CustomFilePickerField> {
  PlatformFile? selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // أو FileType.custom لو عايز أنواع محددة
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => selectedFile = result.files.first);
      widget.onFileSelected?.call(selectedFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: widget.enabled ? _pickFile : null,
          child: AbsorbPointer(
            child: TextFormField(
              readOnly: true,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText:
                    selectedFile?.name ?? widget.hint ?? 'اضغط للرفع ....',
                // hintStyle: const TextStyle(color: Colors.black54),
                filled: true,
                fillColor: widget.fillColor ?? Colors.grey,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: Colors.grey[700])
                    : null,
                suffixIcon: IconButton(
                  onPressed: widget.enabled ? _pickFile : null,
                  icon: Icon(widget.suffixIcon, color: Colors.grey[700]),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.red, width: 1.2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
