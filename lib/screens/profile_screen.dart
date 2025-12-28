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

  // --- HELPER: FORMAT TANGGAL ---
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

  // --- LOGIC DATABASE UTAMA ---
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
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ganti Nama Panggilan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: "Contoh: Alex",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      onPressed: () async {
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6EF5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
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

  // --- FUNGSI BARU: PILIH TANGGAL LAHIR ---
  Future<void> _pickBirthDate() async {
    // 1. Buka Kalender
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005), // Default tahun 2005 (Umur Mahasiswa)
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4C6EF5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // 2. Tampilkan Konfirmasi (Alert)
      _confirmBirthDate(picked);
    }
  }

  // --- FUNGSI BARU: KONFIRMASI DAN SIMPAN TANGGAL ---
  Future<void> _confirmBirthDate(DateTime date) async {
    // Format tanggal buat ditampilkan di dialog (biar user yakin)
    String displayDate = "${date.day}/${date.month}/${date.year}";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Konfirmasi Tanggal Lahir",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Anda memilih: $displayDate",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Perhatian: Data ini hanya dapat diisi SATU KALI dan tidak bisa diubah lagi.",
                      style: TextStyle(fontSize: 12, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 3. Simpan ke Database
              final userId = _supabase.auth.currentUser!.id;
              // Format ke String "YYYY-MM-DD" untuk Supabase
              String formattedDate =
                  "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

              await _supabase
                  .from('profiles')
                  .update({'birth_date': formattedDate})
                  .eq('id', userId);

              if (mounted) Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C6EF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Simpan Permanen",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser!.id;
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('profiles')
            .stream(primaryKey: ['id'])
            .eq('id', userId),
        builder: (context, snapshot) {
          String fullName = "Mahasiswa";
          String nickname = "";
          String nrp = "Loading...";
          String email = "Loading...";
          String? photoUrl;
          String gender = "-";
          String birthDateDisplay = "Loading..."; // Tampilan di UI

          bool isGenderSet = false;
          bool isBirthDateSet = false; // Flag cek status tanggal lahir

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!.first;
            fullName = data['full_name'] ?? "Mahasiswa";
            nickname = data['nickname'] ?? "";
            nrp = data['nrp'] ?? "-";
            email = data['email'] ?? "-";
            photoUrl = data['photo_url'];

            // LOGIC TANGGAL LAHIR
            if (data['birth_date'] != null && data['birth_date'] != "") {
              isBirthDateSet = true;
              birthDateDisplay = _formatDate(data['birth_date']);
            } else {
              birthDateDisplay = "Belum Diatur";
            }

            // LOGIC GENDER
            final gCode = data['gender'];
            if (gCode != null && gCode != "") {
              isGenderSet = true;
              if (gCode == 'L')
                gender = "Laki-laki";
              else if (gCode == 'P')
                gender = "Perempuan";
            } else {
              gender = "Belum Diatur";
            }
          }
          String displayName = nickname.isNotEmpty ? nickname : fullName;

          return Stack(
            children: [
              // HEADER (Sama)
              Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, const Color(0xFF6C88F7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.elliptical(screenWidth, 100),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),

              // KONTEN
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 180),
                    // FOTO PROFIL (Sama)
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8F4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 65,
                                      color: Colors.grey[300],
                                    )
                                  : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showImageSourceModal,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF212121),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // NAMA (Sama)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _editNickname(nickname),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nickname.isNotEmpty
                              ? fullName
                              : "Mahasiswa Teknik Informatika",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // --- INFO CARDS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            title: "NRP",
                            value: nrp,
                            icon: Icons.badge_outlined,
                            primaryBlue: primaryBlue,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            title: "Email",
                            value: email,
                            icon: Icons.email_outlined,
                            primaryBlue: primaryBlue,
                          ),
                          const SizedBox(height: 16),

                          // --- KARTU TANGGAL LAHIR (LOGIC BARU) ---
                          GestureDetector(
                            onTap: isBirthDateSet
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Tanggal lahir sudah diatur dan tidak dapat diubah.",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                : _pickBirthDate, // Buka Kalender kalau belum diset
                            child: _buildInfoCard(
                              title: "Tanggal Lahir",
                              value: birthDateDisplay,
                              icon: Icons.cake_outlined,
                              primaryBlue: isBirthDateSet
                                  ? primaryBlue
                                  : Colors.grey,
                              showEditIcon:
                                  !isBirthDateSet, // Hilang kalau udah diset
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- KARTU GENDER ---
                          GestureDetector(
                            onTap: isGenderSet
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Jenis kelamin sudah diatur dan tidak dapat diubah.",
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // LOGOUT
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: _handleLogout,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF5252)),
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // BACK BUTTON (Sama)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "My Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER (Sama) ---
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
}
