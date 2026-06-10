import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelancer_platform/services/socket_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/token_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;

  static const Color primaryPurple = Color(0xFF5B5BD6);
  static const Color loginButtonColor = Color(0xFF122543);

  void login() async {
    setState(() => loading = true);

    final res = await ApiService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() => loading = false);

    if (res['token'] != null) {
      ApiService.token = res['token'];

      final userData = res['user'];
      final userId = userData?['id'];

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📦 LOGIN RESPONSE:');
      print('📦 Token: ${res['token']?.substring(0, 20)}...');
      print('📦 User data: $userData');
      print('📦 User ID from API: $userId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      await TokenStorage.saveToken(res['token']);
      await TokenStorage.saveUserRole(res['user']?['role']);

      if (userId != null) {
        await TokenStorage.saveUserId(userId);
        print('✅ User ID saved: $userId');
      }

      if (userData != null) {
        await TokenStorage.saveUser(Map<String, dynamic>.from(userData));
        print('✅ User data saved: ${userData['name']}');
      }

      try {
        SocketService.instance.disconnect();
        print('🔌 Old socket disconnected');
      } catch (e) {
        print('⚠️ Error disconnecting: $e');
      }

      await Future.delayed(Duration(milliseconds: 500));

      print('🔄 Initializing new socket connection...');
      await SocketService.instance.init();

      await Future.delayed(Duration(milliseconds: 1000));

      if (userData != null) {
        await SocketService.instance.updateUserData(userData);
      }

      final savedUserId = await TokenStorage.getUserId();
      final savedUser = await TokenStorage.getUser();
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ AFTER SAVE:');
      print('✅ Saved UserId: $savedUserId');
      print('✅ Saved User: ${savedUser?['name']}');
      print('✅ Socket connected: ${SocketService.instance.isConnected}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      Fluttertoast.showToast(msg: res['message']);

      final userRole = res['user']?['role'];

      if (userRole == 'freelancer') {
        Navigator.pushReplacementNamed(context, '/freelancer/home');
      } else if (userRole == 'client') {
        Navigator.pushReplacementNamed(context, '/client/dashboard');
      } else if (userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Fluttertoast.showToast(msg: res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1C33), Color(0xFF122543), Color(0xFF3A5A8C)],
          ),
        ),
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildLeftPanel()),

        _buildRightCard(width: 420),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildLogo(),
            ),
            _buildRightCard(width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(alignment: Alignment.centerLeft, child: _buildLogo()),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Continue your freelancing journey',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect with top clients, manage your projects, and grow your career on iPal - the leading freelancing platform.',
            style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logoo.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(75),
          ),
        );
      },
    );
  }

  Widget _buildRightCard({required double width}) {
    return Container(
      width: width == double.infinity ? null : width,
      margin: const EdgeInsets.fromLTRB(20, 50, 50, 0),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            "Let's get started with your 30 days free trail.",
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 28),

          _buildTextField(
            controller: emailController,
            hint: 'Username',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),

          _buildTextField(
            controller: passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/forgot'),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF122543),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3A5A8C),
                disabledBackgroundColor: Color(0xFF122543).withOpacity(0.7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),

          _buildOrDivider(),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSocialButton(label: 'Google', icon: _googleIcon()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  label: 'Facebook',
                  icon: _facebookIcon(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/signup'),
            child: RichText(
              text: const TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: Colors.black45),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF122543),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscurePassword : false,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFFBBBBBB), size: 20),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () => setState(() => obscurePassword = !obscurePassword),
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFFBBBBBB),
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: primaryPurple, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFEEEEEE), thickness: 1)),
      ],
    );
  }

  Widget _buildSocialButton({required String label, required Widget icon}) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: icon,
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 11),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }

  Widget _facebookIcon() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    final bluePath = Path()
      ..moveTo(w, h * 0.5)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), -0.25, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    final greenPath = Path()
      ..moveTo(w * 0.5, h)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), 0.75, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    final yellowPath = Path()
      ..moveTo(0, h * 0.5)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), 1.75, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    final redPath = Path()
      ..moveTo(w * 0.5, 0)
      ..arcTo(Rect.fromLTWH(0, 0, w, h), -1.25, 1.0, false)
      ..lineTo(w * 0.5, h * 0.5)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.5),
      w * 0.3,
      Paint()..color = Colors.white,
    );

    final gRect = Rect.fromLTWH(w * 0.5, h * 0.38, w * 0.42, h * 0.24);
    canvas.drawRect(gRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
