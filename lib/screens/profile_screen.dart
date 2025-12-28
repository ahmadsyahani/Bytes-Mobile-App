import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // --- HELPER FORMAT TANGGAL ---
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "Belum Diatur";
    try {
      final date = DateTime.parse(dateString);
      const months = [
        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember",
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  // --- LOGIC DATABASE ---
  Future<void> _updatePhoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (image == null) return;
    setState(() => _isUploading = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = image.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '/$fileName';
      await _supabase.storage
          .from('profile_photos')
          .upload(
            filePath,
            File(image.path),
            fileOptions: const FileOptions(upsert: true),
          );
      final imageUrl = _supabase.storage
          .from('profile_photos')
          .getPublicUrl(filePath);
      await _supabase
          .from('profiles')
          .update({'photo_url': imageUrl})
          .eq('id', userId);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Foto berhasil diupdate!"),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal upload: $e"),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _editNickname(String currentName) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    await showDialog(
      context: context,
      builder: (context) => _buildEditDialog(
        title: "Ganti Nama Panggilan",
        hint: "Contoh: Alex",
        controller: controller,
        onSave: () async {
          if (controller.text.isNotEmpty) {
            final userId = _supabase.auth.currentUser!.id;
            await _supabase
                .from('profiles')
                .update({'nickname': controller.text.trim()})
                .eq('id', userId);
            if (mounted) Navigator.pop(context);
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _editPhone(String currentPhone) async {
    final TextEditingController controller = TextEditingController(
      text: currentPhone,
    );
    await showDialog(
      context: context,
      builder: (context) => _buildEditDialog(
        title: "Ganti Nomor HP",
        hint: "Contoh: 08123456789",
        controller: controller,
        inputType: TextInputType.phone,
        onSave: () async {
          if (controller.text.isNotEmpty) {
            final userId = _supabase.auth.currentUser!.id;
            await _supabase
                .from('profiles')
                .update({'phone': controller.text.trim()})
                .eq('id', userId);
            if (mounted) Navigator.pop(context);
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _updateGenderDB(String genderCode) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('profiles')
        .update({'gender': genderCode})
        .eq('id', userId);
    if (mounted) Navigator.pop(context);
    setState(() {});
  }

  Future<void> _editGender() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Jenis Kelamin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateGenderDB('L'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.male, size: 40, color: Colors.blue),
                            SizedBox(height: 8),
                            Text(
                              "Laki-laki",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateGenderDB('P'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.pink.withOpacity(0.3),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.female, size: 40, color: Colors.pink),
                            SizedBox(height: 8),
                            Text(
                              "Perempuan",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4C6EF5)),
        ),
        child: child!,
      ),
    );
    if (picked != null) _confirmBirthDate(picked);
  }

  Future<void> _confirmBirthDate(DateTime date) async {
    String formattedDB =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    String displayDate = "${date.day}/${date.month}/${date.year}";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Konfirmasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Simpan tanggal lahir: $displayDate?\nData tidak bisa diubah lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = _supabase.auth.currentUser!.id;
              await _supabase
                  .from('profiles')
                  .update({'birth_date': formattedDB})
                  .eq('id', userId);
              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C6EF5),
            ),
            child: const Text(
              "Ya, Simpan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;
    final Color primaryBlue = const Color(0xFF4C6EF5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      extendBodyBehindAppBar:
          true, // PENTING: Biar AppBar ngambang di atas background
      appBar: AppBar(
        backgroundColor:
            Colors.transparent, // Transparan biar background biru kelihatan
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ), // Tombol Back Putih
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ), // Judul Putih
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', userId),
        builder: (context, snapshot) {
          String fullName = "Mahasiswa";
          String nickname = "";
          String nrp = "...";
          String email = "...";
          String phone = "-";
          String role = "member";
          String? photoUrl;
          String gender = "-";
          String birthDateDisplay = "...";
          bool isGenderSet = false;
          bool isBirthDateSet = false;

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!.first;
            fullName = data['full_name'] ?? "Mahasiswa";
            nickname = data['nickname'] ?? "";
            nrp = data['nrp'] ?? "-";
            email = data['email'] ?? "-";
            phone = data['phone'] ?? "-";
            role = data['role'] ?? "member";
            photoUrl = data['photo_url'];

            if (data['birth_date'] != null && data['birth_date'] != "") {
              isBirthDateSet = true;
              birthDateDisplay = _formatDate(data['birth_date']);
            } else {
              birthDateDisplay = "Belum Diatur";
            }

            final gCode = data['gender'];
            if (gCode != null && gCode != "") {
              isGenderSet = true;
              gender = (gCode == 'L') ? "Laki-laki" : "Perempuan";
            } else {
              gender = "Belum Diatur";
            }
          }
          String displayName = nickname.isNotEmpty ? nickname : fullName;

          return Stack(
            children: [
              // --- LAYER 1: FIXED BACKGROUND (BIRU) ---
              Container(
                height: 420, // Tinggi area biru
                width: double.infinity,
                decoration: BoxDecoration(color: primaryBlue),
                child: SafeArea(
                  // Biar konten gak ketutup poni HP
                  child: Column(
                    children: [
                      const SizedBox(height: 50), // Jarak dari AppBar
                      // FOTO PROFIL
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 55,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showImageSourceModal,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF212121),
                                shape: BoxShape.circle,
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // NAMA & EDIT ICON
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _editNickname(nickname),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ROLE BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- LAYER 2: SCROLLABLE WHITE CARD ---
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Memberi jarak transparan agar header biru terlihat
                    const SizedBox(height: 360),

                    // KONTAINER PUTIH (CARD)
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F8F4), // Background agak abu
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 30,
                      ),
                      child: Column(
                        children: [
                          // LIST DATA
                          _buildInfoCard(
                            title: "NRP",
                            value: nrp,
                            icon: Icons.badge_outlined,
                            primaryBlue: primaryBlue,
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: () => _editPhone(phone),
                            child: _buildInfoCard(
                              title: "WhatsApp / No HP",
                              value: phone,
                              icon: Icons.phone_android_rounded,
                              primaryBlue: primaryBlue,
                              showEditIcon: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoCard(
                            title: "Email",
                            value: email,
                            icon: Icons.email_outlined,
                            primaryBlue: primaryBlue,
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: isBirthDateSet
                                ? () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tidak dapat diubah lagi.",
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      )
                                : _pickBirthDate,
                            child: _buildInfoCard(
                              title: "Tanggal Lahir",
                              value: birthDateDisplay,
                              icon: Icons.cake_outlined,
                              primaryBlue: isBirthDateSet
                                  ? primaryBlue
                                  : Colors.grey,
                              showEditIcon: !isBirthDateSet,
                            ),
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: isGenderSet
                                ? () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Tidak dapat diubah lagi.",
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      )
                                : _editGender,
                            child: _buildInfoCard(
                              title: "Jenis Kelamin",
                              value: gender,
                              icon: gender == "Perempuan"
                                  ? Icons.female
                                  : Icons.male,
                              primaryBlue: isGenderSet
                                  ? (gender == "Perempuan"
                                        ? Colors.pink
                                        : Colors.blue)
                                  : Colors.grey,
                              showEditIcon: !isGenderSet,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildInfoCard(
                            title: "Status Akademik",
                            value: "Mahasiswa Aktif",
                            icon: Icons.check_circle_outline,
                            primaryBlue: Colors.green,
                            isStatus: true,
                          ),

                          const SizedBox(height: 40),

                          // LOGOUT BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: OutlinedButton(
                              onPressed: _handleLogout,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFFF5252),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: const Color(
                                  0xFFFF5252,
                                ).withOpacity(0.05),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: Color(0xFFFF5252)),
                                  SizedBox(width: 8),
                                  Text(
                                    "Log Out",
                                    style: TextStyle(
                                      color: Color(0xFFFF5252),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color primaryBlue,
    bool isStatus = false,
    bool showEditIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isStatus ? primaryBlue : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (showEditIcon)
            const Icon(Icons.edit, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildEditDialog({
    required String title,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onSave,
    TextInputType inputType = TextInputType.text,
  }) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: controller,
                keyboardType: inputType,
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Batal",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6EF5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Simpan",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSourceButton(Icons.image, "Gallery", ImageSource.gallery),
                _buildSourceButton(
                  Icons.camera_alt,
                  "Camera",
                  ImageSource.camera,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceButton(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updatePhoto(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4C6EF5).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: const Color(0xFF4C6EF5)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
