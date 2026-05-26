import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseNotifier {
  PurchaseNotifier._();

  static const String _endpoint =
      'https://smartfactura.ro/api-iap-notify.php';
  static const String _secret =
      'sf_iap_3c8a1d92_b7f64e25_a019';

  static Future<void> notifyPurchase({
    required String packageName,
    required PurchaseDetails purchase,
  }) async {
    if (purchase.status != PurchaseStatus.purchased) return;
    final body = <String, dynamic>{
      'source':        'app',
      'platform':       Platform.isIOS ? 'ios' : 'android',
      'package':        packageName,
      'product_id':     purchase.productID,
      'order_id':       purchase.purchaseID ?? '',
      'purchase_token': purchase.verificationData.serverVerificationData,
      'transaction_ts': purchase.transactionDate ?? '',
    };
    try {
      await http
          .post(
            Uri.parse('$_endpoint?token=$_secret'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[PurchaseNotifier] notify failed: $e');
    }
  }
}
