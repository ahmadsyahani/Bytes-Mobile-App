import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'homepage.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart'; // Pastikan file ini ada

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Panggil Auth Service
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. LOGIC LOGIN (Supabase)
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password harus diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Panggil fungsi signIn dari auth_service.dart
    String? error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      // SUKSES
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // GAGAL
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: Stack(
        children: [
          // Background Painter
          Positioned.fill(
            child: CustomPaint(
              painter: AuthBackgroundPainter(color: primaryBlue),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO AREA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.code,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "INFORMATICS",
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "ENGINEERING.",
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontWeight: FontWeight.w900,
                                color: primaryBlue,
                                fontSize: 18,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    Text(
                      "Sign In",
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Welcome back, Student!",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    // INPUT EMAIL
                    _buildTextField(
                      hint: "Email",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),

                    // INPUT PASSWORD
                    _buildTextField(
                      hint: "Password",
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      isPassword: true,
                      isObscure: _isObscure,
                      onToggle: () => setState(() => _isObscure = !_isObscure),
                    ),

                    // --- TOMBOL LUPA PASSWORD (BARU) ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "Lupa Password?",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Jarak disesuaikan
                    // BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // KE HALAMAN REGISTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum punya akun? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF4C6EF5),
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}

// Background Painter
class AuthBackgroundPainter extends CustomPainter {
  final Color color;
  AuthBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (double i = 0; i < 50; i += 5) {
      path.reset();
      path.moveTo(0, size.height * 0.15 - i);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.25 - i,
        size.width * 0.5,
        size.height * 0.15 - i,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.05 - i,
        size.width,
        size.height * 0.2 - i,
      );
      canvas.drawPath(path, paint..color = color.withOpacity(0.5));
    }
    for (double i = 0; i < 50; i += 5) {
      path.reset();
      path.moveTo(0, size.height * 0.9 + i);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.8 + i,
        size.width * 0.5,
        size.height * 0.9 + i,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 1.0 + i,
        size.width,
        size.height * 0.85 + i,
      );
      canvas.drawPath(path, paint..color = color.withOpacity(0.5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
