import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> initStripe() async {
  try {
    Stripe.publishableKey = 'pk_live_51TgJMfF0Dhlez29FgEpqqLZHN1gBT5cgCAA5oiPsP1ekikYpiHw4inWDmH5Z7JR3UwYY4Nm7TqZucnZuWCUOSCsy00urkU5UMp';
    await Stripe.instance.applySettings();
  } catch (e) {
    // Stripe init failed — app continues without card payments
    print('Stripe init error: $e');
  }
}