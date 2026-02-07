extension StringExtension on String {
  bool get isValidEmail =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
