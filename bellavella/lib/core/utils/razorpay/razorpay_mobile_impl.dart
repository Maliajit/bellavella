import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_service.dart';

class RazorpayMobileServiceImpl implements RazorpayService {
  late Razorpay _razorpay;

  @override
  void init(
    Function(PaymentSuccessResponse) onSuccess,
    Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse) onExternalWallet,
  ) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  @override
  void open(Map<String, dynamic> options) {
    _razorpay.open(options);
  }

  @override
  void clear() {
    _razorpay.clear();
  }
}

RazorpayService getService() => RazorpayMobileServiceImpl();
