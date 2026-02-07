// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/formatters.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/wallet/controllers/wallet_controller.dart';

class ArtisanWalletView extends StatefulWidget {
  const ArtisanWalletView({super.key});

  @override
  State<ArtisanWalletView> createState() => _ArtisanWalletViewState();
}

class _ArtisanWalletViewState extends State<ArtisanWalletView>
    with SingleTickerProviderStateMixin {
  Color get primaryBlue => const Color(0xFF2563EB);

  late AnimationController _controller;
  late Animation<double> _balanceScale;
  late Animation<double> _historyOpacity;

  final WalletController walletController = Get.find<WalletController>();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _balanceScale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _historyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletController.fetchWallet();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _withdrawDialog() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.walletTitle.tr,
                style: AppTextStyles.body(context).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.body(context),
                decoration: InputDecoration(
                  labelText: AppStrings.walletSubtitle.tr,
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      return ElevatedButton(
                        onPressed: walletController.withdrawing.value
                            ? null
                            : () {
                                final amount = int.tryParse(
                                  amountCtrl.text.trim(),
                                );
                                if (amount != null && amount > 0) {
                                  walletController.withdraw(amount);
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: walletController.withdrawing.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppStrings.confirm.tr,
                                style: const TextStyle(
                                  fontFamily: "Cairo",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.cancel.tr,
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.walletTitle.tr,
          style: const TextStyle(
            fontFamily: "Cairo",
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final txs = walletController.transactions;
          return Column(
            children: [
              if (walletController.loading.value)
                const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
              ScaleTransition(
                scale: _balanceScale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [primaryBlue, const Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.walletSubtitle.tr,
                                style: const TextStyle(
                                  fontFamily: "Cairo",
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${walletController.balance.value} EGP",
                                style: const TextStyle(
                                  fontFamily: "Cairo",
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.walletDetails.tr,
                                style: const TextStyle(
                                  fontFamily: "Cairo",
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _withdrawDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.withdraw.tr,
                            style: const TextStyle(
                              fontFamily: "Cairo",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppStrings.walletDetails.tr,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedBuilder(
                  animation: _historyOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _historyOpacity.value,
                      child: child,
                    );
                  },
                  child: txs.isEmpty
                      ? Center(child: Text(AppStrings.noData.tr))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: txs.length,
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            return _txItem(
                              type: tx["type"]?.toString() ?? 'in',
                              title:
                                  tx["title"]?.toString() ??
                                  tx['description']?.toString() ??
                                  '',
                              amount: int.tryParse('${tx["amount"] ?? 0}') ?? 0,
                              time:
                                  tx["time"]?.toString() ??
                                  tx['createdAt']?.toString() ??
                                  '',
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _txItem({
    required String type,
    required String title,
    required int amount,
    required String time,
  }) {
    final kind = _txKindFromType(type);
    final color = _txColorFromKind(kind);
    final icon = _txIconFromKind(kind);
    final label = _txLabelFromKind(kind, type);
    final sign = _txSign(kind);

    final parsed = DateTime.tryParse(time)?.toLocal();
    final formattedTime = parsed == null
        ? ""
        : Formatters.formatDateTime(parsed);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 12),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chip status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.body(context).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                if (formattedTime.isNotEmpty)
                  Text(
                    formattedTime,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 12,

                    ),
                  ),

                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Amount pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Text(
              "$sign$amount",
              style: TextStyle(
                fontFamily: "Cairo",
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TxKind { earning, withdraw, pending, rejected, cancelled, other }

_TxKind _txKindFromType(String type) {
  final t = type.toLowerCase().trim();

  if (t == 'in' ||
      t.contains('earn') ||
      t.contains('credit') ||
      t.contains('deposit')) {
    return _TxKind.earning;
  }
  if (t == 'out' || t.contains('withdraw') || t.contains('debit')) {
    return _TxKind.withdraw;
  }

  if (t.contains('pending') || t.contains('review')) return _TxKind.pending;
  if (t.contains('reject')) return _TxKind.rejected;
  if (t.contains('cancel')) return _TxKind.cancelled;

  return _TxKind.other;
}

String _txLabelFromKind(_TxKind k, String rawType) {
  switch (k) {
    case _TxKind.earning:
      return 'أرباح';
    case _TxKind.withdraw:
      return 'سحب';
    case _TxKind.pending:
      return 'قيد المراجعة';
    case _TxKind.rejected:
      return 'مرفوضة';
    case _TxKind.cancelled:
      return 'ملغاة';
    default:
      return rawType.isEmpty ? 'عملية' : rawType;
  }
}

Color _txColorFromKind(_TxKind k) {
  switch (k) {
    case _TxKind.earning:
      return Colors.greenAccent;
    case _TxKind.withdraw:
      return Colors.blueGrey;
    case _TxKind.pending:
      return Colors.orangeAccent;
    case _TxKind.rejected:
      return Colors.redAccent;
    case _TxKind.cancelled:
      return Colors.deepOrangeAccent;
    default:
      return Colors.grey;
  }
}

IconData _txIconFromKind(_TxKind k) {
  switch (k) {
    case _TxKind.earning:
      return Icons.arrow_downward;
    case _TxKind.withdraw:
      return Icons.arrow_upward;
    case _TxKind.pending:
      return Icons.hourglass_bottom;
    case _TxKind.rejected:
      return Icons.cancel;
    case _TxKind.cancelled:
      return Icons.block;
    default:
      return Icons.help_outline;
  }
}

String _txSign(_TxKind k) {
  if (k == _TxKind.earning) return '+';
  if (k == _TxKind.withdraw) return '-';
  return '-';
}

