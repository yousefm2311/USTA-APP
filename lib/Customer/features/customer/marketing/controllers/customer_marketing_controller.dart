import 'package:get/get.dart';
import 'package:usta/Customer/data/repositories/customer_repository.dart';
import 'package:geolocator/geolocator.dart';

class CustomerMarketingController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();
  final RxString myReferralCode = ''.obs;

  final RxList<Map<String, dynamic>> coupons = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> rewards = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> recommendations =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> liveLocations =
      <Map<String, dynamic>>[].obs;

  final RxnString liveCenter = RxnString();
  final Rxn<num> liveRadiusKm = Rxn<num>();
  final RxnString aiMessage = RxnString();
  final RxMap<String, dynamic> aiStats = <String, dynamic>{}.obs;

  final RxString liveError = ''.obs;
  final RxString couponsError = ''.obs;
  final RxString rewardsError = ''.obs;
  final RxString referralError = ''.obs;
  final RxString applyError = ''.obs;

  final RxBool loadingCoupons = false.obs;
  final RxBool loadingRewards = false.obs;
  final RxBool loadingLiveMap = false.obs;
  final RxBool applying = false.obs;
  final RxBool sendingReferral = false.obs;
  final RxBool sendingFeedback = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCoupons();
    fetchRewards();
  }

  void setMyReferralCode(String? code) {
    final v = (code ?? '').trim();
    myReferralCode.value = v;
  }

  void syncReferralCodeFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return;

    final code =
        profile['referralCode'] ??
        profile['myReferralCode'] ??
        profile['refCode'] ??
        profile['referral'] ??
        '';

    if (code != null && code.toString().trim().isNotEmpty) {
      myReferralCode.value = code.toString().trim();
    }
  }

  Future<void> fetchCoupons() async {
    loadingCoupons.value = true;
    couponsError.value = '';
    try {
      final res = await _repo.api.coupons();
      final list = res['coupons'] ?? res['data'] ?? [];
      final rc = res['referralCode'] ?? res['myReferralCode'];
      if (rc != null && rc.toString().trim().isNotEmpty) {
        myReferralCode.value = rc.toString().trim();
      }
      if (list is List) {
        coupons.assignAll(
          list
              .map<Map<String, dynamic>>(
                (e) => e is Map<String, dynamic> ? e : {'label': e.toString()},
              )
              .toList(),
        );
      }
    } catch (e) {
      coupons.clear();
      couponsError.value = e.toString();
    } finally {
      loadingCoupons.value = false;
    }
  }

  Future<Map<String, dynamic>> applyCoupon(String code) async {
    applying.value = true;
    applyError.value = '';
    try {
      final res = await _repo.api.applyCoupon(code);
      await fetchCoupons();
      return res;
    } catch (e) {
      applyError.value = e.toString();
      rethrow;
    } finally {
      applying.value = false;
    }
  }

  Future<Map<String, dynamic>> sendReferral(String code) async {
    sendingReferral.value = true;
    referralError.value = '';
    try {
      final res = await _repo.api.referral(code);
      final rc = res['myReferralCode'] ?? res['referralCode'];
      if (rc != null && rc.toString().trim().isNotEmpty) {
        myReferralCode.value = rc.toString().trim();
      }
      return res;
    } catch (e) {
      referralError.value = e.toString();
      rethrow;
    } finally {
      sendingReferral.value = false;
    }
  }
  Future<void> fetchRewards() async {
    loadingRewards.value = true;
    rewardsError.value = '';
    try {
      final res = await _repo.api.rewards();
      final list = res['rewards'] ?? res['data'] ?? [];
      final rc = res['referralCode'] ?? res['myReferralCode'];
      if (rc != null && rc.toString().trim().isNotEmpty) {
        myReferralCode.value = rc.toString().trim();
      }
      if (list is List) {
        rewards.assignAll(
          list
              .map<Map<String, dynamic>>(
                (e) => e is Map<String, dynamic> ? e : {'title': e.toString()},
              )
              .toList(),
        );
      }
    } catch (e) {
      rewards.clear();
      rewardsError.value = e.toString();
    } finally {
      loadingRewards.value = false;
    }
  }
  Future<void> fetchRecommendations() async {
    final res = await _repo.api.recommendations();
    final list = res['recommendations'] ?? res['data'] ?? [];
    if (list is List) {
      recommendations.assignAll(
        list
            .map<Map<String, dynamic>>(
              (e) => e is Map<String, dynamic> ? e : {'title': e.toString()},
            )
            .toList(),
      );
    }
  }

  Future<void> fetchLiveMap({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    loadingLiveMap.value = true;
    liveError.value = '';
    try {
      final res = await _repo.api.liveMap(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      liveRadiusKm.value = data['radiusKm'] ?? data['radius'] ?? data['km'];
      if (data['center'] is Map<String, dynamic>) {
        final c = data['center'] as Map<String, dynamic>;
        final lat = c['lat'] ?? c['latitude'];
        final lng = c['lng'] ?? c['longitude'];
        liveCenter.value = (lat != null && lng != null) ? '$lat,$lng' : null;
      } else {
        liveCenter.value = null;
      }
      final list =
          data['artisans'] ?? data['locations'] ?? data['data'] ?? <dynamic>[];
      if (list is List) {
        liveLocations.assignAll(
          list
              .map<Map<String, dynamic>>(
                (e) => e is Map<String, dynamic> ? e : {},
              )
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      }
    } catch (e) {
      liveLocations.clear();
      liveCenter.value = null;
      liveRadiusKm.value = null;
      liveError.value = e.toString();
    } finally {
      loadingLiveMap.value = false;
    }
  }
  Future<Map<String, dynamic>> sendAiFeedback(String feedback) async {
    sendingFeedback.value = true;
    try {
      final res = await _repo.api.aiFeedback(feedback: feedback);
      final data = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : res;
      aiMessage.value = data['message']?.toString();
      if (data['stats'] is Map<String, dynamic>) {
        aiStats.assignAll(data['stats'] as Map<String, dynamic>);
      }
      return res;
    } finally {
      sendingFeedback.value = false;
    }
  }
  Future<Position?> getCurrentPositionSafely() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return null;
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

