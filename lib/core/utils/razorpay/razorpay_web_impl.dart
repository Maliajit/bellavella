import 'dart:js' as js;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_service.dart';

class RazorpayWebServiceImpl implements RazorpayService {
  late Function(PaymentSuccessResponse) _onSuccess;
  late Function(PaymentFailureResponse) _onError;

  @override
  void init(
    Function(PaymentSuccessResponse) onSuccess,
    Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse) onExternalWallet,
  ) {
    _onSuccess = onSuccess;
    _onError = onError;
  }

  @override
  void open(Map<String, dynamic> options) {
    // Modify options for Web (handler instead of events)
    final webOptions = Map<String, dynamic>.from(options);
    webOptions['handler'] = js.allowInterop((response) {
      // Create data map from JS object if possible, or just pass an empty map/null
      // The 4th argument 'data' is expected to be a Map.
      _onSuccess(PaymentSuccessResponse(
        response['razorpay_payment_id'],
        response['razorpay_order_id'],
        response['razorpay_signature'],
        null, // Passing null for the data argument
      ));
    });

    final rzp = js.JsObject(js.context['Razorpay'], [js.JsObject.jsify(webOptions)]);
    rzp.callMethod('open');
  }

  @override
  void clear() {
    // Cleanup if needed
  }
}

RazorpayService getService() => RazorpayWebServiceImpl();
