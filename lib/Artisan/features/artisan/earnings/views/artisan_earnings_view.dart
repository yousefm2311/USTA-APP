import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/features/artisan/earnings/controllers/earnings_controller.dart';

class ArtisanEarningsView extends StatefulWidget {
  const ArtisanEarningsView({super.key});

  @override
  State<ArtisanEarningsView> createState() => _ArtisanEarningsViewState();
}

class _ArtisanEarningsViewState extends State<ArtisanEarningsView> {
  final EarningsController controller = Get.find<EarningsController>();
  final Color primaryBlue = const Color(0xFF2563EB);
  static const String _currency = 'EGP';
  String _filter = 'all'; // all, earning, withdraw, recharge

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "الأرباح",
          style: TextStyle(fontFamily: "Cairo", fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final txs = controller.transactions;
        final filtered = txs.where((tx) {
          final type = (tx['type'] ?? '').toString().toLowerCase();
          if (_filter == 'withdraw') return type.contains('withdraw');
          if (_filter == 'recharge') {
            return type.contains('recharge') ||
                type.contains('deposit') ||
                type.contains('topup');
          }
          if (_filter == 'earning') {
            return !type.contains('withdraw') &&
                !type.contains('recharge') &&
                !type.contains('deposit') &&
                !type.contains('topup');
          }
          return true;
        }).toList();
        filtered.sort((a, b) {
          final da = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        final grouped = _groupByDate(filtered);

        return RefreshIndicator(
          onRefresh: controller.fetchEarnings,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 10),
              Text(
                'المعاملات',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('لا توجد معاملات حتى الآن')),
                )
              else
                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, top: 6),
                        child: Text(
                          entry.key,
                          style: AppTextStyles.body(context).copyWith(
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ),
                      ...entry.value.map(_transactionTile),
                    ],
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryCard() {
    final total = controller.total.value;
    final month = controller.month.value;
    final week = controller.week.value;
    final pendingWithdrawals = controller.transactions.where((tx) {
      final type = (tx['type'] ?? '').toString().toLowerCase();
      final status = (tx['status'] ?? '').toString().toLowerCase();
      return type.contains('withdraw') && status.contains('pending');
    }).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('الإجمالي', total),
          _summaryItem('هذا الشهر', month),
          _summaryItem('هذا الأسبوع', week),
          _summaryItem('سحوبات معلّقة', pendingWithdrawals.toDouble(),
              valueColor: Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, double value, {Color? valueColor}) {
    final display =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.body(context)),
        const SizedBox(height: 6),
        Text(
          '$display${title.contains('سحوبات') ? '' : ' $_currency'}',
          style: AppTextStyles.body(context).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _transactionTile(Map<String, dynamic> tx) {
    final credit = double.tryParse('${tx['credit'] ?? 0}') ?? 0;
    final debit = double.tryParse('${tx['debit'] ?? 0}') ?? 0;
    final amount =
        double.tryParse('${tx['finalAmount'] ?? tx['amount'] ?? 0}') ??
        (credit - debit);
    final type = tx['type']?.toString() ?? '';
    final status = (tx['status'] ?? 'done').toString().toLowerCase();
    final date = tx['createdAt']?.toString() ?? tx['date']?.toString() ?? '';
    final method = tx['method']?.toString() ?? '';
    final isWithdraw = type.toLowerCase().contains('withdraw');
    final isPending = status.contains('pending');
    final isRejected = status.contains('reject');
    final color = isWithdraw
        ? (isRejected
            ? Colors.redAccent
            : isPending
                ? Colors.orangeAccent
                : Colors.blueGrey)
        : Colors.green;
    final icon = isWithdraw
        ? (isRejected
            ? Icons.cancel
            : isPending
                ? Icons.hourglass_bottom
                : Icons.south_west)
        : Icons.north_east;
    final sign = amount >= 0 ? '+' : '-';
    final absAmount = amount.abs().toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.isEmpty ? 'عملية' : type,
                  style: AppTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(date, style: AppTextStyles.small(context)),
                if (method.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'طريقة الدفع: $method',
                    style: AppTextStyles.small(context).copyWith(color: Colors.grey),
                  ),
                ],
                if (isWithdraw) ...[
                  const SizedBox(height: 2),
                  Text(
                    'الحالة: $status',
                    style: AppTextStyles.small(context).copyWith(
                      color: isRejected
                          ? Colors.redAccent
                          : (isPending ? Colors.orangeAccent : Colors.green)),
                    ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$absAmount $_currency',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (tx['couponDiscount'] != null)
                Text(
                  'خصم: ${tx['couponDiscount']}',
                  style: AppTextStyles.small(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('الكل', 'all'),
          _filterChip('أرباح', 'earning'),
          _filterChip('سحوبات', 'withdraw'),
          _filterChip('شحن/إيداع', 'recharge'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          value == 'all'
              ? Icons.list
              : value == 'earning'
              ? Icons.trending_up
              : value == 'withdraw'
              ? Icons.south_west
              : Icons.account_balance_wallet,
          color: selected ? primaryBlue : Colors.grey,
          size: 18,
        ),
        label: Text(label),
        selected: selected,
        selectedColor: primaryBlue.withOpacity(0.15),
        onSelected: (_) {
          setState(() => _filter = value);
        },
        labelStyle: AppTextStyles.body(context).copyWith(
          color: selected ? primaryBlue : Colors.grey,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
        side: BorderSide(color: selected ? primaryBlue : Colors.white24),
        backgroundColor: Colors.white10,
      )


    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> txs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in txs) {
      final dt = DateTime.tryParse((tx['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final label = _dateLabel(dt);
      grouped.putIfAbsent(label, () => []).add(tx);
    }
    // Preserve order based on first item per group
    final entries = grouped.entries.toList()
      ..sort((a, b) {
        DateTime da = DateTime.fromMillisecondsSinceEpoch(0);
        DateTime db = DateTime.fromMillisecondsSinceEpoch(0);
        if (a.value.isNotEmpty) {
          da = DateTime.tryParse(
                  (a.value.first['createdAt'] ?? '').toString()) ??
              da;
        }
        if (b.value.isNotEmpty) {
          db = DateTime.tryParse(
                  (b.value.first['createdAt'] ?? '').toString()) ??
              db;
        }
        return db.compareTo(da);
      });
    return {for (final e in entries) e.key: e.value};
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(thatDay).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return '${thatDay.day.toString().padLeft(2, '0')}/${thatDay.month.toString().padLeft(2, '0')}/${thatDay.year}';
  }
}

