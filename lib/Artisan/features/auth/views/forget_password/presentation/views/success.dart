import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:usta/Artisan/core/services/helpers/app_mediaquery.dart';
import 'package:usta/Artisan/core/services/functions/navigator.dart';
import 'package:usta/Artisan/core/utils/constants/app_assets.dart';
import 'package:usta/Artisan/core/utils/constants/app_strings.dart';
import 'package:usta/Artisan/core/utils/constants/app_text_style.dart';
import 'package:usta/Artisan/core/utils/routes/routes.dart';
import 'package:usta/Artisan/core/utils/widgets/custom_material_button.dart';

class SuccessView extends StatelessWidget {
  const SuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = AppMediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AssetsData.success),
            const SizedBox(height: 20.0),
            Text(AppStrings.success.tr, style: AppTextStyles.title(context)),
            const SizedBox(height: 20.0),
            SizedBox(
              width: 200.0,
              child: Text(AppStrings.successbody.tr, style: AppTextStyles.body(context)),
            ),
            const SizedBox(height: 20.0),
            CustomMaterialButton(
              width: double.infinity,
              text: AppStrings.continue_.tr,
              onPressed: () {
                pushReplacementAllNamedRoute(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}


