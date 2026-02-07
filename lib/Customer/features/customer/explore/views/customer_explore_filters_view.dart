import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/filter_apply_button.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/filter_distance_slider.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/filter_rating_slider.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/filter_section_title.dart';
import 'package:usta/Customer/features/customer/explore/views/widgets/filter_sort_options.dart';

class CustomerExploreFiltersView extends StatefulWidget {
  const CustomerExploreFiltersView({super.key});

  @override
  State<CustomerExploreFiltersView> createState() =>
      _CustomerExploreFiltersViewState();
}

class _CustomerExploreFiltersViewState
    extends State<CustomerExploreFiltersView> {
  Color get blue => const Color(0xFF2563EB);

  double minRating = 3;
  double maxDistance = 15;
  String selectedSort = "الأقرب";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تصفية النتائج".tr,
          style: const TextStyle(fontFamily: "Cairo"),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ExploreFilterSectionTitle(text: "ترتيب حسب"),
          ExploreFilterSortOptions(
            items: const ["الأقرب", "الأعلى تقييماً", "الأقل سعراً"],
            selected: selectedSort,
            activeColor: blue,
            onChanged: (v) => setState(() => selectedSort = v),
          ),
          const SizedBox(height: 25),
          const ExploreFilterSectionTitle(text: "التقييم الأدنى"),
          const SizedBox(height: 12),
          ExploreFilterRatingSlider(
            value: minRating,
            activeColor: blue,
            onChanged: (v) => setState(() => minRating = v),
          ),
          const SizedBox(height: 25),
          const ExploreFilterSectionTitle(text: "أقصى مسافة"),
          const SizedBox(height: 12),
          ExploreFilterDistanceSlider(
            value: maxDistance,
            activeColor: blue,
            onChanged: (v) => setState(() => maxDistance = v),
          ),
          const SizedBox(height: 40),
          ExploreFilterApplyButton(
            color: blue,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

