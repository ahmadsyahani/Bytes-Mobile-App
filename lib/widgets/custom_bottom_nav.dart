import 'package:flutter/material.dart';
import '../screens/classmate_screen.dart';
import '../screens/lecturer_screen.dart'; // Import screen baru

class CustomBottomNav extends StatelessWidget {
  final Color activeColor;
  final VoidCallback? onProfileTap;

  const CustomBottomNav({
    super.key,
    required this.activeColor,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: activeColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: activeColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. HOME
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            label: "Home",
            isActive: true,
            onTap: () {}, // Sudah di Home
          ),

          // 2. DOSEN (Menggantikan Tugas)
          _buildNavItem(
            context,
            icon: Icons.school_rounded, // Icon Topi Wisuda / Sekolah
            label: "Dosen",
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LecturerScreen()),
              );
            },
          ),

          // 3. TEMAN (Classmate)
          _buildNavItem(
            context,
            icon: Icons.people_alt_rounded,
            label: "Teman",
            isActive: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClassmateScreen(),
                ),
              );
            },
          ),

          // 4. PROFIL
          _buildNavItem(
            context,
            icon: Icons.person_rounded,
            label: "Profil",
            isActive: false,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
