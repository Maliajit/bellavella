import 'package:razorpay_flutter/razorpay_flutter.dart';

abstract class RazorpayService {
  void init(
    Function(PaymentSuccessResponse) onSuccess,
    Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse) onExternalWallet,
  );
  void open(Map<String, dynamic> options);
  void clear();
  
  factory RazorpayService() => throw UnsupportedError('Cannot create a RazorpayService');
}
