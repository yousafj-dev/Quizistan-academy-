import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quizistan_academy/services/auth_service.dart';

/// Premium/Pro (non-consumable) purchase handling.
/// Billing unavailable ho to stub-safe: koi crash nahi, bas false/no-op.
class PurchaseService extends ChangeNotifier {
  static const String premiumProductId = 'quizistan_premium';
  static const String proProductId = 'quizistan_pro';

  bool _isPremium = false;
  bool _isPro = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;

  bool get isPro => _isPro;

  /// Koi bhi paid plan.
  bool get isPaid => _isPremium || _isPro;

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
  Future<bool> buyPremium() => _buy(premiumProductId);

  /// Pro khareedna. true = purchase flow start hua.
  Future<bool> buyPro() => _buy(proProductId);

  Future<bool> _buy(String productId) async {
    if (!_isAvailable) return false;
    try {
      final response = await InAppPurchase.instance
          .queryProductDetails({productId});
      if (response.productDetails.isEmpty) {
        debugPrint('Product not found in store: $productId');
        return false;
      }
      final productDetails = response.productDetails.first;
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
      );
      return true;
    } catch (e) {
      debugPrint('_buy failed: $e');
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
          } else if (details.productID == proProductId) {
            _grantPro();
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

  void _grantPro() {
    if (_isPro) return;
    _isPro = true;
    AuthService.instance.updatePro(true);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
