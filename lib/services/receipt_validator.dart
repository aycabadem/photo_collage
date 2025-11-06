import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_store_secrets.dart';

/// High level state describing the result of receipt validation.
enum ReceiptValidationState { active, inactive, unknown }

/// Outcome information produced by a [ReceiptValidator].
class ReceiptValidationResult {
  const ReceiptValidationResult._({
    required this.state,
    this.expirationDate,
    this.reason,
  });

  /// Indicates the purchase is currently considered active.
  const ReceiptValidationResult.active({DateTime? expiration})
    : this._(
        state: ReceiptValidationState.active,
        expirationDate: expiration,
      );

  /// Indicates the purchase is not active (expired, refunded, or revoked).
  const ReceiptValidationResult.inactive({String? reason})
    : this._(state: ReceiptValidationState.inactive, reason: reason);

  /// Indicates that validation could not reach a definitive conclusion.
  const ReceiptValidationResult.unknown({String? reason})
    : this._(state: ReceiptValidationState.unknown, reason: reason);

  /// High-level state.
  final ReceiptValidationState state;

  /// Optional expiration timestamp returned by the store.
  final DateTime? expirationDate;

  /// Diagnostic message, when available.
  final String? reason;

  bool get isActive => state == ReceiptValidationState.active;
  bool get isInactive => state == ReceiptValidationState.inactive;
  bool get isUnknown => state == ReceiptValidationState.unknown;
}

/// Contract for verifying purchase receipts (Apple, Google etc).
abstract class ReceiptValidator {
  Future<ReceiptValidationResult> validate(PurchaseDetails purchase);
}

/// Receipt validator for App Store purchases using the verifyReceipt endpoint.
///
/// The App Store shared secret must be supplied via
/// [appStoreSharedSecret] (`--dart-define=APP_STORE_SHARED_SECRET=...`).
class AppStoreReceiptValidator implements ReceiptValidator {
  AppStoreReceiptValidator({
    http.Client? client,
    String? sharedSecret,
  }) : _client = client ?? http.Client(),
       _sharedSecret = sharedSecret ?? appStoreSharedSecret;

  static const String _productionEndpoint =
      'https://buy.itunes.apple.com/verifyReceipt';
  static const String _sandboxEndpoint =
      'https://sandbox.itunes.apple.com/verifyReceipt';

  final http.Client _client;
  final String _sharedSecret;

  @override
  Future<ReceiptValidationResult> validate(PurchaseDetails purchase) async {
    if (_sharedSecret.isEmpty) {
      debugPrint(
        '[AppStoreReceiptValidator] Shared secret missing; skipping validation.',
      );
      return const ReceiptValidationResult.unknown(
        reason: 'Missing shared secret',
      );
    }

    if (purchase.verificationData.serverVerificationData.isEmpty) {
      return const ReceiptValidationResult.unknown(
        reason: 'Receipt payload empty',
      );
    }

    final Map<String, Object?> payload = <String, Object?>{
      'receipt-data': purchase.verificationData.serverVerificationData,
      'password': _sharedSecret,
      'exclude-old-transactions': true,
    };

    Map<String, dynamic>? jsonResponse = await _postReceipt(
      Uri.parse(_productionEndpoint),
      payload,
    );

    if (jsonResponse == null) {
      return const ReceiptValidationResult.unknown(
        reason: 'Unreachable verifyReceipt service',
      );
    }

    // If we mistakenly hit production with a sandbox receipt (21007), retry.
    final int status = jsonResponse['status'] is int
        ? jsonResponse['status'] as int
        : -1;
    if (status == 21007) {
      jsonResponse = await _postReceipt(
        Uri.parse(_sandboxEndpoint),
        payload,
      );
    } else if (status == 21008) {
      // Sandbox receipt sent to production endpoint.
      jsonResponse = await _postReceipt(
        Uri.parse(_productionEndpoint),
        payload,
      );
    }

    if (jsonResponse == null) {
      return const ReceiptValidationResult.unknown(
        reason: 'No response from verifyReceipt',
      );
    }

    final int finalStatus = jsonResponse['status'] is int
        ? jsonResponse['status'] as int
        : -1;
    if (finalStatus != 0) {
      return ReceiptValidationResult.inactive(
        reason: 'Non-success status $finalStatus',
      );
    }

    final List<Map<String, dynamic>> receipts = _extractReceiptCandidates(
      jsonResponse,
      purchase.productID,
    );
    if (receipts.isEmpty) {
      return const ReceiptValidationResult.inactive(
        reason: 'No matching receipt entries',
      );
    }

    final Map<String, dynamic> latestReceipt = _selectLatestReceipt(receipts);

    if (_hasCancellation(latestReceipt)) {
      return const ReceiptValidationResult.inactive(
        reason: 'Receipt reports cancellation/refund',
      );
    }

    final DateTime? expiration = _parseExpiration(latestReceipt);
    if (expiration == null) {
      // Non-renewing (lifetime) purchase.
      return const ReceiptValidationResult.active();
    }

    if (DateTime.now().isBefore(expiration)) {
      return ReceiptValidationResult.active(expiration: expiration);
    }
    return ReceiptValidationResult.inactive(
      reason: 'Subscription expired ${expiration.toIso8601String()}',
    );
  }

  Future<Map<String, dynamic>?> _postReceipt(
    Uri endpoint,
    Map<String, Object?> payload,
  ) async {
    try {
      final http.Response response = await _client.post(
        endpoint,
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        debugPrint(
          '[AppStoreReceiptValidator] HTTP ${response.statusCode} from $endpoint',
        );
        return null;
      }
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (error, stackTrace) {
      debugPrint(
        '[AppStoreReceiptValidator] Request to $endpoint failed: $error\n$stackTrace',
      );
      return null;
    }
  }

  List<Map<String, dynamic>> _extractReceiptCandidates(
    Map<String, dynamic> response,
    String productId,
  ) {
    final List<Map<String, dynamic>> receipts = <Map<String, dynamic>>[];

    void collect(dynamic candidate) {
      if (candidate is List) {
        for (final dynamic entry in candidate) {
          collect(entry);
        }
      } else if (candidate is Map<String, dynamic>) {
        if (candidate['product_id'] == productId) {
          receipts.add(candidate);
        }
      }
    }

    collect(response['latest_receipt_info']);
    final dynamic receipt = response['receipt'];
    if (receipt is Map<String, dynamic>) {
      collect(receipt['in_app']);
    }

    return receipts;
  }

  Map<String, dynamic> _selectLatestReceipt(
    List<Map<String, dynamic>> receipts,
  ) {
    receipts.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final DateTime timeA = _parseReceiptDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime timeB = _parseReceiptDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });
    return receipts.first;
  }

  DateTime? _parseReceiptDate(Map<String, dynamic> receipt) {
    final String? expiresMs = receipt['expires_date_ms'] as String?;
    if (expiresMs != null) {
      final int? millis = int.tryParse(expiresMs);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
      }
    }
    final String? purchaseDateMs = receipt['purchase_date_ms'] as String?;
    if (purchaseDateMs != null) {
      final int? millis = int.tryParse(purchaseDateMs);
      if (millis != null) {
        return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
      }
    }
    return null;
  }

  bool _hasCancellation(Map<String, dynamic> receipt) {
    return receipt['cancellation_date'] != null ||
        receipt['cancellation_date_ms'] != null ||
        receipt['cancellation_reason'] != null;
  }

  DateTime? _parseExpiration(Map<String, dynamic> receipt) {
    final String? expiresMs = receipt['expires_date_ms'] as String?;
    if (expiresMs == null) return null;
    final int? millis = int.tryParse(expiresMs);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
  }
}
