import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'homepage.dart'; // Pastikan nama file ini sesuai (home_screen.dart)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. SETUP VARIABEL & CONTROLLER
  final AuthService _authService = AuthService();

  final TextEditingController _nrpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isChecked = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nrpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. LOGIC PENDAFTARAN (SUPABASE VERSION)
  void _handleRegister() async {
    // A. Validasi Input
    if (!_isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap setujui peraturan penggunaan.")),
      );
      return;
    }

    if (_nrpController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua kolom harus diisi.")));
      return;
    }

    // B. Mulai Loading
    setState(() => _isLoading = true);

    try {
      // C. Panggil AuthService Supabase
      // Note: Menggunakan method signUp yang ada di auth_service.dart
      String? result = await _authService.signUp(
        nrp: _nrpController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // D. Stop Loading
      if (mounted) setState(() => _isLoading = false);

      // E. Cek Hasil
      if (result == null) {
        // SUKSES (Result null artinya tidak ada error)
        if (!mounted) return;

        // Pindah ke HomeScreen & Hapus history login/register
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // GAGAL (Tampilkan pesan error dari Supabase)
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result,
            ), // Pesan error spesifik (misal: NRP tidak terdaftar)
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ERROR CRASH
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan sistem: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: Stack(
        children: [
          // Reuse Painter agar konsisten
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
                            Icons.add,
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

                    // TITLE
                    Text(
                      "Sign Up",
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // FORM INPUTS
                    _buildTextField(hint: "NRP", controller: _nrpController),
                    const SizedBox(height: 15),
                    _buildTextField(
                      hint: "Email",
                      controller: _emailController,
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      hint: "Password",
                      isPassword: true,
                      isObscure: _isObscure,
                      controller: _passwordController,
                      onToggle: () => setState(() => _isObscure = !_isObscure),
                    ),

                    const SizedBox(height: 20),

                    // CHECKBOX AGREEMENT
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _isChecked,
                            activeColor: primaryBlue,
                            onChanged: (val) =>
                                setState(() => _isChecked = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Saya menyetujui Peraturan penggunaan Aplikasi ITByte Mobile",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // BUTTON SIGN UP
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
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
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Kembali ke Login
                          },
                          child: Text(
                            "Sign In",
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

  // WIDGET TEXTFIELD
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
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
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}

// Custom Painter
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

    // Kurva Atas
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

    // Kurva Bawah
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
