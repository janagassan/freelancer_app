// lib/screens/subscription/subscription_success_screen.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  const SubscriptionSuccessScreen({super.key});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool _isLoading = true;
  String _message = 'Processing your subscription...';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      _extractAndConfirm();
    });
  }

  Future<void> _extractAndConfirm() async {
    try {
      print('🔍 ===== SUBSCRIPTION SUCCESS SCREEN =====');
      
      final fullUrl = html.window.location.href;
      print('🔍 Full URL: $fullUrl');
      
      String? sessionId;
      
      if (fullUrl.contains('session_id=')) {
        final startIndex = fullUrl.indexOf('session_id=') + 11;
        String remaining = fullUrl.substring(startIndex);
        final endIndex = remaining.indexOf('&');
        if (endIndex != -1) {
          sessionId = remaining.substring(0, endIndex);
        } else {
          sessionId = remaining;
        }
      }
      
      print('🔍 Extracted session_id: $sessionId');
      
      if (sessionId != null && sessionId.isNotEmpty) {
        await _confirmSubscription(sessionId);
      } else {
        print('❌ No session_id found');
        setState(() {
          _isLoading = false;
          _message = 'No session ID found. URL: $fullUrl';
          _success = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
        _success = false;
      });
    }
  }

  Future<void> _confirmSubscription(String sessionId) async {
    try {
      print('📡 Calling confirmCheckoutSession...');
      
      final response = await ApiService.confirmCheckoutSession(sessionId);
      
      print('📡 Response: $response');
      
      if (response['success'] == true) {
        print('✅ Subscription activated!');
        
        await ApiService.refreshUserData();
        await ApiService.refreshUserSubscription();
        
        setState(() {
          _isLoading = false;
          _message = response['message'] ?? '✅ Subscription activated successfully!';
          _success = true;
        });
        
        Fluttertoast.showToast(msg: 'Subscription activated!');
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/subscription/my');
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _message = response['message'] ?? 'Failed to activate subscription';
          _success = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
        _success = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    )
                  : Icon(
                      _success ? Icons.check_circle : Icons.error,
                      size: 80,
                      color: _success ? Colors.green : Colors.red,
                    ),
              const SizedBox(height: 24),
              Text(
                _success ? 'Subscription Successful!' : 'Subscription Failed',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _message,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isLoading)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/subscription/my');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'View Subscription',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}