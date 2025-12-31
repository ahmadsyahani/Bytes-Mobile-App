import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Pastikan import Login Screen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Data Onboarding sesuai gambar kamu
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/Vector1.png",
      "title": "Selamat Datang di\nBytes Mobile.",
      "desc":
          "Cara baru dan lebih seru untuk mengatur jadwal\nkuliahmu jadi lebih gampang.",
    },
    {
      "image": "assets/images/Vector2.png",
      "title": "Semua dalam\nGenggamanmu",
      "desc":
          "Dari ngatur jadwal kelas sampai ngecek uang kas,\nsemua bisa kamu pantau di satu tempat.",
    },
    {
      "image": "assets/images/Vector3.png",
      "title": "Siap memulai\nPetualanganmu?",
      "desc":
          "Buat akun atau login untuk merasakan kemudahannya.\nYuk gabung dengan Sobat Byte's yang lain.",
    },
  ];

  // Fungsi simpan status "Sudah Onboarding" & Pindah ke Login
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true); // Tandai sudah dilihat

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warna Utama
    const Color primaryBlue = Color(0xFF4C6EF5);
    const Color bgColor = Color(0xFFF9F8F4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. PAGE VIEW (GAMBAR & TEKS)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Gambar
                        Image.asset(
                          _onboardingData[index]['image']!,
                          height: 300, // Sesuaikan tinggi gambar
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),

                        // Judul
                        Text(
                          _onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800, // Bold tebal
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        Text(
                          _onboardingData[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. BAGIAN BAWAH (DOTS & BUTTON)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 8 : 8, // Bulat
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? primaryBlue
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol Lanjut / Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex == _onboardingData.length - 1) {
                          // Halaman Terakhir -> Masuk Login
                          _finishOnboarding();
                        } else {
                          // Halaman Belum Terakhir -> Slide Selanjutnya
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentIndex == _onboardingData.length - 1
                            ? "Sign In"
                            : "Lanjut",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
