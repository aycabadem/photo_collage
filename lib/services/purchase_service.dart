import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'receipt_validator.dart';

/// Coordinates querying product metadata, launching purchases, and tracking
/// entitlement state for the app's premium unlock.
class PurchaseService extends ChangeNotifier {
  PurchaseService({Set<String>? productIds, ReceiptValidator? receiptValidator})
    : _productIds = productIds ?? _defaultProductIds,
      _receiptValidator = receiptValidator ?? _createDefaultValidator() {
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
    'com.framelabs.customcollage.premium.weekly',
    'com.framelabs.customcollage.premium.monthly',
    'com.framelabs.customcollage.premium.yearly',
  };
  static final Uri _appStoreSubscriptionsUri = Uri.https(
    'apps.apple.com',
    'account/subscriptions',
  );
  static const String _androidPackageId = 'com.cemergin.photocollage';

  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds;
  final ReceiptValidator? _receiptValidator;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  List<ProductDetails> _products = <ProductDetails>[];
  Set<String> _notFoundIds = <String>{};
  final Set<String> _entitlements = <String>{};
  final Map<String, DateTime?> _entitlementExpirations = <String, DateTime?>{};

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => List.unmodifiable(_products);
  Set<String> get notFoundProductIds => Set.unmodifiable(_notFoundIds);
  bool get hasActiveSubscription => _entitlements.isNotEmpty;
  String? get activePlanProductId =>
      _entitlements.isEmpty ? null : _entitlements.first;
  DateTime? expirationForProduct(String productId) =>
      _entitlementExpirations[productId];
  Uri? get subscriptionManagementUri {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildPlayStoreSubscriptionsUri(
          _androidPackageId,
          activePlanProductId,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _appStoreSubscriptionsUri;
      default:
        return null;
    }
  }

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
    bool shouldNotify = false;
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isProcessing = true;
          shouldNotify = true;
          break;
        case PurchaseStatus.canceled:
          _isProcessing = false;
          shouldNotify = _revokeEntitlement(purchase.productID) || shouldNotify;
          break;
        case PurchaseStatus.error:
          _errorMessage =
              purchase.error?.message ?? 'An unknown purchase error occurred.';
          _isProcessing = false;
          shouldNotify = _revokeEntitlement(purchase.productID) || shouldNotify;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _isProcessing = false;
          unawaited(_verifyAndApplyPurchase(purchase));
          break;
      }

      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }

    if (shouldNotify) {
      _cleanStaleEntitlements();
      notifyListeners();
    }
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

    bool changed = false;
    final Set<String> observedProductIds = <String>{};
    for (final PurchaseDetails purchase in response.pastPurchases) {
      observedProductIds.add(purchase.productID);
      if (_shouldKeepPurchase(purchase)) {
        changed =
            await _verifyAndApplyPurchase(purchase, notifyOnChange: false) ||
            changed;
      } else {
        changed = _revokeEntitlement(purchase.productID) || changed;
      }
      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }

    changed = _pruneEntitlementsNotIn(observedProductIds) || changed;

    if (changed) {
      _cleanStaleEntitlements();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static Uri _buildPlayStoreSubscriptionsUri(
    String packageId,
    String? productId,
  ) {
    final Map<String, String> query = <String, String>{};
    if (packageId.isNotEmpty) {
      query['package'] = packageId;
    }
    if (productId != null && productId.isNotEmpty) {
      query['sku'] = productId;
    }
    return Uri.https(
      'play.google.com',
      'store/account/subscriptions',
      query.isEmpty ? null : query,
    );
  }

  bool _grantEntitlement(String productId) {
    if (productId.isEmpty) return false;
    final bool added = _entitlements.add(productId);
    if (added) {
      _entitlementExpirations.remove(productId);
    }
    return added;
  }

  bool _revokeEntitlement(String productId) {
    if (productId.isEmpty) return false;
    final bool removed = _entitlements.remove(productId);
    if (removed) {
      _entitlementExpirations.remove(productId);
    }
    return removed;
  }

  /// Drops product ids that no longer match any configured SKU.
  void _cleanStaleEntitlements() {
    final Set<String> validProductIds = _productIds;
    _entitlements.removeWhere(
      (String productId) => !validProductIds.contains(productId),
    );
  }

  bool _shouldKeepPurchase(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        return true;
      case PurchaseStatus.pending:
      case PurchaseStatus.canceled:
      case PurchaseStatus.error:
        return false;
    }
  }

  static ReceiptValidator? _createDefaultValidator() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppStoreReceiptValidator();
      default:
        return null;
    }
  }

  Future<bool> _verifyAndApplyPurchase(
    PurchaseDetails purchase, {
    bool notifyOnChange = true,
  }) async {
    final ReceiptValidator? validator = _receiptValidator;
    ReceiptValidationResult result;
    if (validator == null) {
      result = const ReceiptValidationResult.active();
    } else {
      try {
        result = await validator.validate(purchase);
      } catch (error, stackTrace) {
        debugPrint(
          '[PurchaseService] Receipt validation failed for ${purchase.productID}: $error\n$stackTrace',
        );
        result = const ReceiptValidationResult.unknown(
          reason: 'Validation threw',
        );
      }
    }

    bool changed = false;
    switch (result.state) {
      case ReceiptValidationState.active:
        changed = _grantEntitlement(purchase.productID) || changed;
        _entitlementExpirations[purchase.productID] = result.expirationDate;
        break;
      case ReceiptValidationState.inactive:
        changed = _revokeEntitlement(purchase.productID) || changed;
        break;
      case ReceiptValidationState.unknown:
        if (!_entitlements.contains(purchase.productID)) {
          changed = _grantEntitlement(purchase.productID) || changed;
        }
        if (result.expirationDate != null) {
          _entitlementExpirations[purchase.productID] = result.expirationDate;
        }
        break;
    }

    if (changed) {
      _cleanStaleEntitlements();
      if (notifyOnChange) {
        notifyListeners();
      }
    }
    return changed;
  }

  bool _pruneEntitlementsNotIn(Set<String> productIds) {
    final List<String> toRemove = <String>[];
    for (final String entitlement in _entitlements) {
      if (!productIds.contains(entitlement)) {
        toRemove.add(entitlement);
      }
    }
    bool changed = false;
    for (final String productId in toRemove) {
      changed = _revokeEntitlement(productId) || changed;
    }
    return changed;
  }
}
