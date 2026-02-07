// ignore_for_file: unused_local_variable

import 'dart:ui';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/core/utils/constants/app_text_style.dart';
import 'package:usta/Customer/features/customer/payments/add_card/customer_card_added_success_view.dart';

class CustomerAddBankCardView extends StatefulWidget {
  const CustomerAddBankCardView({super.key});

  @override
  State<CustomerAddBankCardView> createState() =>
      _CustomerAddBankCardViewState();
}

class _CustomerAddBankCardViewState extends State<CustomerAddBankCardView> {
  Color get bg => const Color(0xFF050816);
  Color get cardBg => const Color(0x40101625);
  Color get blue => const Color(0xFF2563EB);
  Color get accent => const Color(0xFF22D3EE);

  String cardNumber = "";
  String cardHolder = "";
  String expiry = "";
  String cvv = "";

  final cardNumberCtrl = TextEditingController();
  final holderCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  final flipKey = GlobalKey<FlipCardState>();

  final FocusNode cardNumberFocus = FocusNode();
  final FocusNode holderFocus = FocusNode();
  final FocusNode expiryFocus = FocusNode();
  final FocusNode cvvFocus = FocusNode();

  bool showBack = false;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();

    cardNumberFocus.addListener(() {
      if (cardNumberFocus.hasFocus) {
        _showFront();
        _setTyping(true);
      } else {
        _setTyping(false);
      }
    });

    holderFocus.addListener(() {
      if (holderFocus.hasFocus) {
        _showFront();
        _setTyping(true);
      } else {
        _setTyping(false);
      }
    });

    expiryFocus.addListener(() {
      if (expiryFocus.hasFocus) {
        _showFront();
        _setTyping(true);
      } else {
        _setTyping(false);
      }
    });

    cvvFocus.addListener(() {
      if (cvvFocus.hasFocus) {
        _showBack();
        _setTyping(true);
      } else {
        _setTyping(false);
      }
    });
  }

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    holderCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    cardNumberFocus.dispose();
    holderFocus.dispose();
    expiryFocus.dispose();
    cvvFocus.dispose();
    super.dispose();
  }

  void _setTyping(bool value) {
    setState(() => isTyping = value);
  }

  void _showFront() {
    if (showBack) {
      flipKey.currentState?.toggleCard();
      showBack = false;
    }
  }

  void _showBack() {
    if (!showBack) {
      flipKey.currentState?.toggleCard();
      showBack = true;
    }
  }

  bool _isValidCardNumber(String number) {
    final digits = number.replaceAll(' ', '');
    if (digits.length < 13) return false;

    int sum = 0;
    bool doubleIt = false;

    for (int i = digits.length - 1; i >= 0; i--) {
      int d = int.tryParse(digits[i]) ?? 0;
      if (doubleIt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      doubleIt = !doubleIt;
    }

    return sum % 10 == 0;
  }

  String _formatCardNumber(String input) {
    final digits = input.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i != digits.length - 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "إضافة بطاقة بنكية".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: AnimatedScale(
              scale: isTyping ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  boxShadow: isTyping
                      ? [
                          BoxShadow(
                            color: blue.withOpacity(0.6),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: FlipCard(
                  key: flipKey,
                  flipOnTouch: false,
                  front: _frontCard(),
                  back: _backCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          _fields(),

          const SizedBox(height: 24),
          _googleAppleButtons(),

          const SizedBox(height: 24),
          _saveButton(context),
        ],
      ),
    );
  }

  Widget _frontCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "USTA PAY",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontFamily: "Cairo",
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.wifi, color: Colors.white.withOpacity(0.8), size: 24),
            ],
          ),
          const Spacer(),
          Text(
            cardNumber.isEmpty ? "XXXX XXXX XXXX XXXX" : cardNumber,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 1.5,
              fontFamily: "Cairo",
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "EXP",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: "Cairo",
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry.isEmpty ? "MM/YY" : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: "Cairo",
                    ),
                  ),
                ],
              ),
              _cardBrand(),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            cardHolder.isEmpty ? "CARD HOLDER" : cardHolder,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: "Cairo",
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 42, color: Colors.black87),
          const SizedBox(height: 20),
          const Text(
            "CVV",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: "Cairo",
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 90,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cvv.isEmpty ? "***" : cvv,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: "Cairo",
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0x66101625),
                  const Color(0x6618253A),
                  const Color(0x663B1C32),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              height: 210,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBrand() {
    final digits = cardNumber.replaceAll(' ', '');
    String label = "VISA";
    Color color1 = const Color(0xFF1A1F71);
    Color color2 = const Color(0xFFEFC75E);

    if (digits.startsWith('5')) {
      label = "MasterCard";
      color1 = const Color(0xFFF79E1B);
      color2 = const Color(0xFFEB001B);
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color1),
        ),
        Transform.translate(
          offset: const Offset(-10, 0),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color2),
          ),
        ),
      ],
    );
  }

  Widget _fields() {
    return Column(
      children: [
        _input(
          label: "رقم البطاقة",
          hint: "xxxx xxxx xxxx xxxx",
          controller: cardNumberCtrl,
          focusNode: cardNumberFocus,
          keyboard: TextInputType.number,
          onTap: () {
            _showFront();
          },
          onChange: (v) {
            String digits = v.replaceAll(' ', '');
            if (digits.length > 16) digits = digits.substring(0, 16);
            final formatted = _formatCardNumber(digits);
            cardNumberCtrl.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
            setState(() => cardNumber = formatted);
            if (showBack) _showFront();
          },
        ),

        const SizedBox(height: 14),
        _input(
          label: "اسم صاحب البطاقة",
          hint: "كما يظهر على البطاقة",
                    onTap: () {
            _showFront();
          },
          controller: holderCtrl,
          focusNode: holderFocus,
          onChange: (v) { 
            if (showBack) _showFront();
            setState(() => cardHolder = v);},
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _input(
                label: "تاريخ الانتهاء",
                hint: "MM/YY",
                controller: expiryCtrl,
                focusNode: expiryFocus,
                keyboard: TextInputType.number,
                onTap: () {
                  _showFront();
                },
                onChange: (v) {
                  String digits = v.replaceAll('/', '');
                  if (digits.length > 4) {
                    digits = digits.substring(0, 4);
                  }
                  String formatted = digits;
                  if (digits.length >= 3) {
                    formatted =
                        "${digits.substring(0, 2)}/${digits.substring(2)}";
                  }
                  expiryCtrl.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                  setState(() => expiry = formatted);
                  if (showBack) _showFront();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _input(
                label: "CVV",
                hint: "***",
                controller: cvvCtrl,
                focusNode: cvvFocus,
                keyboard: TextInputType.number,
                onTap: () {
                  _showBack();
                },
                onChange: (v) {
                  setState(() => cvv = v);
                  if (v.length == 3) {
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _input({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChange,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChange,
      onTap: onTap,
      keyboardType: keyboard,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label.tr,
        hintText: hint.tr,
        hintStyle: AppTextStyles.body,
        labelStyle: AppTextStyles.body,
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
    );
  }


  Widget _googleAppleButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  "Google Pay",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Cairo",
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.phone_iphone, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  "Apple Pay",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Cairo",
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final number = cardNumberCtrl.text.replaceAll(' ', '');
          if (!_isValidCardNumber(number)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "رقم البطاقة غير صالح، تأكد من صحته.".tr,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            );
            return;
          }
          Get.to(() => CustomerCardAddedSuccessView(last4: '',));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "تم حفظ البطاقة بنجاح (Mock).".tr,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "إضافة البطاقة".tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

