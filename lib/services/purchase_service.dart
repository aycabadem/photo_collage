import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Coordinates querying product metadata, launching purchases, and tracking
/// entitlement state for the app's premium unlock.
class PurchaseService extends ChangeNotifier {
  PurchaseService({Set<String>? productIds})
    : _productIds = productIds ?? _defaultProductIds {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        _errorMessage = error.toString();
        _isProcessing = false;
        notifyListeners();
      },
    );
  }

  static const Set<String> _defaultProductIds = {
    'collage_pro_weekly',
    'collage_pro_monthly',
    'collage_pro_yearly',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  List<ProductDetails> _products = <ProductDetails>[];
  Set<String> _notFoundIds = <String>{};
  final Set<String> _entitlements = <String>{};

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);
  Set<String> get notFoundProductIds => Set.unmodifiable(_notFoundIds);
  bool get hasActiveSubscription => _entitlements.isNotEmpty;
  String? get activePlanProductId =>
      _entitlements.isEmpty ? null : _entitlements.first;

  /// Returns the locally cached [ProductDetails] for the given [productId].
  ProductDetails? productForId(String productId) {
    for (final ProductDetails product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      _isLoading = false;
      _errorMessage ??= 'In-app purchases are not available on this device.';
      notifyListeners();
      return;
    }

    await _queryProducts();
    await _syncPastPurchases();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _queryProducts() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(
      _productIds,
    );

    if (response.error != null) {
      _errorMessage = response.error!.message;
    }

    _products = response.productDetails;
    _notFoundIds = response.notFoundIDs.toSet();
    notifyListeners();
  }

  Future<void> buy(String productId) async {
    final ProductDetails? product = productForId(productId);
    if (product == null) {
      _errorMessage = 'Product $productId is not configured in the store.';
      notifyListeners();
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    final bool launched = await _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    if (!launched) {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    if (!_isAvailable) return;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    if (kIsWeb) {
      _isProcessing = false;
      notifyListeners();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _queryAndroidPastPurchases();
      _isProcessing = false;
      notifyListeners();
      return;
    }

    await _iap.restorePurchases();
    _isProcessing = false;
    notifyListeners();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isProcessing = true;
          break;
        case PurchaseStatus.canceled:
          _isProcessing = false;
          break;
        case PurchaseStatus.error:
          _errorMessage =
              purchase.error?.message ?? 'An unknown purchase error occurred.';
          _isProcessing = false;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _entitlements.add(purchase.productID);
          _isProcessing = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }

    notifyListeners();
  }

  Future<void> _syncPastPurchases() async {
    if (!_isAvailable || kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _queryAndroidPastPurchases();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _iap.restorePurchases();
    }
  }

  Future<void> _queryAndroidPastPurchases() async {
    final InAppPurchaseAndroidPlatformAddition addition = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final QueryPurchaseDetailsResponse response = await addition
        .queryPastPurchases();

    if (response.error != null) {
      _errorMessage = response.error!.message;
    }

    for (final PurchaseDetails purchase in response.pastPurchases) {
      _entitlements.add(purchase.productID);
      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
