// lib/screens/payment/subscription_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'dart:html' as html;

class SubscriptionPaymentScreen extends StatefulWidget {
  final String planSlug;
  final Map<String, dynamic> paymentIntent;
  final String planName;
  final String planPrice;

  const SubscriptionPaymentScreen({
    super.key,
    required this.planSlug,
    required this.paymentIntent,
    required this.planName,
    required this.planPrice,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  bool _isProcessing = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPaymentSheet();
    }
  }

  Future<void> _confirmSubscriptionManually() async {
    final t = AppLocalizations.of(context)!;
    setState(() => _confirming = true);

    try {
      final result = await ApiService.manualConfirmSubscriptionPayment(
        widget.planSlug,
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(msg: t.subscriptionPaymentConfirmed);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/subscription/my');
        }
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? t.failedToConfirmSubscriptionPayment,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '${t.error}: $e');
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _initPaymentSheet() async {
    if (kIsWeb) return;
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: widget.paymentIntent['clientSecret'],
          merchantDisplayName: 'Freelancer Platform',
          style: ThemeMode.light,
        ),
      );
    } catch (e) {
      print('❌ Error initializing payment sheet: $e');
    }
  }

  Future<void> _presentPaymentSheet() async {
    final t = AppLocalizations.of(context)!;
    if (kIsWeb) {
      await _openStripeCheckout();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await Stripe.instance.presentPaymentSheet();

      final result = await ApiService.confirmSubscriptionPayment(
        planSlug: widget.planSlug,
        paymentIntentId: widget.paymentIntent['paymentIntentId'],
      );

      if (result['message'] != null) {
        Fluttertoast.showToast(msg: t.subscriptionPaymentSuccessful);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/subscription/my');
        }
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '${t.subscriptionPaymentFailed}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openStripeCheckout() async {
  final t = AppLocalizations.of(context)!;
  setState(() => _isProcessing = true);

  try {
    print('🔍 Creating checkout session for: ${widget.planSlug}');
    
    final checkoutUrl = await ApiService.createSubscriptionCheckoutSessionDirect(
      widget.planSlug,
    );

    if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
      print('🔍 Opening checkout URL: $checkoutUrl');
      
      if (kIsWeb) {
        html.window.open(checkoutUrl, '_blank');
        
        Fluttertoast.showToast(
          msg: 'Complete payment in the new tab. You will be redirected automatically.',
          timeInSecForIosWeb: 5,
          gravity: ToastGravity.BOTTOM,
        );
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      throw Exception('No checkout URL returned');
    }
  } catch (e) {
    print('❌ Error: $e');
    if (mounted) {
      Fluttertoast.showToast(msg: '${t.subscriptionPaymentFailed}: $e');
    }
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double amount = 0.0;
    if (widget.paymentIntent['amount'] != null) {
      final amountValue = widget.paymentIntent['amount'];
      if (amountValue is double) {
        amount = amountValue;
      } else if (amountValue is int) {
        amount = amountValue.toDouble();
      } else if (amountValue is String) {
        amount = double.tryParse(amountValue) ?? 0.0;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.completeSubscriptionPayment),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.subscriptions, size: 64, color: AppColors.info),
            ),
            const SizedBox(height: 24),

            Text(
              t.subscriptionPayment,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              widget.planName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              t.subscriptionActivatedImmediately,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.subscriptionPrice,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.planPrice,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.subscriptionSecureDescription,
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: kIsWeb ? AppColors.warningBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    kIsWeb ? Icons.web : Icons.phone_android,
                    color: kIsWeb ? AppColors.warning : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kIsWeb ? t.stripeWebRedirect : t.stripeInAppPayment,
                      style: TextStyle(
                        color: kIsWeb ? AppColors.warning : AppColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _presentPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        kIsWeb ? t.payWithStripe : t.subscribeNow,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _confirming
                        ? null
                        : _confirmSubscriptionManually,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.info),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _confirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            t.confirmPaymentManual,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.info,
                            ),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            Text(
              t.agreeToTermsBySubscribing,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
