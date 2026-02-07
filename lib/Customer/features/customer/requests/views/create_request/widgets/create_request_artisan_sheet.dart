import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateRequestArtisanSheet extends StatelessWidget {
  const CreateRequestArtisanSheet({
    super.key,
    required this.artisans,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> artisans;
  final void Function(Map<String, dynamic> artisan, String name) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: artisans.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
      itemBuilder: (_, index) {
        final art = artisans[index];
        final name = art['name']?.toString() ?? 'بدون اسم'.tr;
        final profession = art['profession']?.toString() ?? 'حرفي'.tr;
        final photo = art['photo']?.toString();
        final email = art['email']?.toString() ?? '';
        final phone = art['phone']?.toString() ?? '';
        final desc = art['description']?.toString() ?? '';
        double? ratingValue;
        int? ratingCount;
        if (art['rating'] is Map) {
          final r = art['rating'] as Map;
          ratingValue =
              (r['avgRating'] ?? r['rating'] ?? r['value']) is num
                  ? (r['avgRating'] ?? r['rating'] ?? r['value']).toDouble()
                  : double.tryParse(
                      (r['avgRating'] ?? r['rating'] ?? r['value'] ?? '')
                          .toString(),
                    );
          if (r['count'] is num) {
            ratingCount = (r['count'] as num).toInt();
          }
        } else if (art['rating'] is num) {
          ratingValue = (art['rating'] as num).toDouble();
        }
        final portfolio = (art['portfolio'] is List)
            ? (art['portfolio'] as List)
                .where(
                  (e) =>
                      e is Map &&
                      (e['path'] ?? '').toString().isNotEmpty,
                )
                .take(6)
                .map((e) => (e as Map)['path'].toString())
                .toList()
            : <String>[];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white10,
                    backgroundImage: photo != null && photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profession,
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [email, phone].where((e) => e.isNotEmpty).join(' : '),
                          style: const TextStyle(
                            fontFamily: "Cairo",
                            fontSize: 12,
                          ),
                        ),
                        if (ratingValue != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              ratingCount != null
                                  ? 'التقييم: @value / 5 (@count تقييم)'
                                      .trParams(
                                        {
                                          'value':
                                              ratingValue.toStringAsFixed(1),
                                          'count': ratingCount.toString(),
                                        },
                                      )
                                  : 'التقييم: @value / 5'.trParams(
                                      {
                                        'value':
                                            ratingValue.toStringAsFixed(1),
                                      },
                                    ),
                              style: const TextStyle(
                                color: Colors.amber,
                                fontFamily: "Cairo",
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                        ),
                        onPressed: () {
                          onSelect(art, name);
                          Navigator.of(context).pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showDetails(
                          context,
                          name: name,
                          profession: profession,
                          email: email,
                          phone: phone,
                          desc: desc,
                          ratingValue: ratingValue,
                          ratingCount: ratingCount,
                          portfolio: portfolio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4, right: 4),
                  child: Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 13,
                    ),
                  ),
                ),
              if (portfolio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: portfolio.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final url = portfolio[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 100,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => SizedBox(
                              width: 100,
                              height: 80,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDetails(
    BuildContext context, {
    required String name,
    required String profession,
    required String email,
    required String phone,
    required String desc,
    required double? ratingValue,
    required int? ratingCount,
    required List<String> portfolio,
  }) {
    final maxW = MediaQuery.of(context).size.width * 0.9;
    final maxH = MediaQuery.of(context).size.height * 0.6;
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: "Cairo",
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoRow('المهنة', profession),
                  _infoRow('البريد', email.isEmpty ? 'غير متوفر'.tr : email),
                  _infoRow('الهاتف', phone.isEmpty ? 'غير متوفر'.tr : phone),
                  if (ratingValue != null)
                    _infoRow(
                      'التقييم',
                      ratingCount != null
                          ? '@value / 5 (@count تقييم)'.trParams(
                              {
                                'value': ratingValue.toStringAsFixed(1),
                                'count': ratingCount.toString(),
                              },
                            )
                          : '@value / 5'.trParams(
                              {'value': ratingValue.toStringAsFixed(1)},
                            ),
                    ),
                  if (desc.isNotEmpty) _infoRow('الوصف', desc),
                  if (portfolio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'صور الأعمال'.tr,
                      style: const TextStyle(fontFamily: "Cairo", fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: portfolio.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final url = portfolio[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox(
                                width: 120,
                                height: 90,
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'إغلاق'.tr,
                        style: const TextStyle(fontFamily: "Cairo"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${title.tr}: ',
            style: const TextStyle(fontFamily: "Cairo", fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: "Cairo", fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
