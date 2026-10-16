import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quizistan_academy/services/auth_service.dart';

/// Premium (non-consumable) purchase handling.
/// Billing unavailable ho to stub-safe: koi crash nahi, bas false/no-op.
class PurchaseService extends ChangeNotifier {
  static const String premiumProductId = 'quizistan_premium';

  bool _isPremium = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;

  bool get isAvailable => _isAvailable;

  bool get isLoading => _isLoading;

  /// Billing availability check + purchase stream listen.
  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      _isAvailable = await InAppPurchase.instance.isAvailable();

      _subscription?.cancel();
      _subscription =
          InAppPurchase.instance.purchaseStream.listen(_onPurchases);
    } catch (e) {
      debugPrint('Purchase init failed: $e');
      _isAvailable = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Premium khareedna. true = purchase flow start hua.
  Future<bool> buyPremium() async {
    if (!_isAvailable) return false;
    try {
      final response = await InAppPurchase.instance
          .queryProductDetails({premiumProductId});
      if (response.productDetails.isEmpty) {
        debugPrint('Premium product not found in store.');
        return false;
      }
      final productDetails = response.productDetails.first;
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
      );
      return true;
    } catch (e) {
      debugPrint('buyPremium failed: $e');
      return false;
    }
  }

  /// Pehle ki khareedain restore karna.
  Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      debugPrint('restore failed: $e');
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final details in purchases) {
      switch (details.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (details.productID == premiumProductId) {
            _grantPremium();
          }
          if (details.pendingCompletePurchase) {
            InAppPurchase.instance.completePurchase(details);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${details.error}');
          break;
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          break;
      }
    }
  }

  void _grantPremium() {
    if (_isPremium) return;
    _isPremium = true;
    AuthService.instance.updatePremium(true);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
