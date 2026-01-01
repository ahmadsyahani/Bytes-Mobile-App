import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart'; // 1. JANGAN LUPA IMPORT INI
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // 1. INISIALISASI VARIABEL FTOAST
  late FToast fToast;

  bool _isUploading = false;
  bool _isLoadingData = true;

  // --- VARIABLE LOKAL ---
  String _fullName = "Mahasiswa";
  String _nickname = "";
  String _nrp = "...";
  String _email = "...";
  String _phone = "-";
  String _role = "member";
  String? _photoUrl;
  String _gender = "-";
  String _birthDateDisplay = "Belum Diatur";
  bool _isGenderSet = false;
  bool _isBirthDateSet = false;

  @override
  void initState() {
    super.initState();
    // 2. SETUP FTOAST DI INITSTATE
    fToast = FToast();
    fToast.init(context);

    _fetchProfileData();
  }

  // --- 3. FUNGSI TOAST CUSTOM (FIXED & AMAN) ---
  void _showCustomToast(String message, {bool isError = false}) {
    // Tentukan Warna Background
    final Color bgColor = isError
        ? const Color(0xFFFF5252)
        : const Color(0xFF4C6EF5);
    final IconData icon = isError
        ? Icons.cancel_rounded
        : Icons.check_circle_rounded;

    Widget toast = Container(
      // TRIK POSISI: Margin bawah biar "melayang" di atas, gak nempel dasar layar
      margin: const EdgeInsets.only(bottom: 80),

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), // Bentuk Kapsul
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Biar lebarnya menyesuaikan teks
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                // fontFamily: 'MonaSans', // Aktifkan kalau font custom udah dipasang
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Tampilkan Toast (Pake Gravity BOTTOM biasa, posisi diatur margin container)
    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 2),
    );
  }

  Future<void> _fetchProfileData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _fullName = data['full_name'] ?? "Mahasiswa";
          _nickname = data['nickname'] ?? "";
          _nrp = data['nrp'] ?? "-";
          _email = data['email'] ?? "-";
          _phone = data['phone'] ?? "-";
          _role = data['role'] ?? "member";
          _photoUrl = data['photo_url'];

          if (data['birth_date'] != null && data['birth_date'] != "") {
            _isBirthDateSet = true;
            _birthDateDisplay = _formatDate(data['birth_date']);
          }

          final gCode = data['gender'];
          if (gCode != null && gCode != "") {
            _isGenderSet = true;
            _gender = (gCode == 'L') ? "Laki-laki" : "Perempuan";
          } else {
            _gender = "Belum Diatur";
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

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

  // --- LOGIC UPDATE DENGAN CUSTOM TOAST ---

  Future<void> _updatePhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );
      if (image == null) return;

      setState(() => _isUploading = true);

      final userId = _supabase.auth.currentUser!.id;
      final fileExt = image.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from('profile_photos')
          .upload(
            fileName,
            File(image.path),
            fileOptions: const FileOptions(upsert: true),
          );

      final newUrl = _supabase.storage
          .from('profile_photos')
          .getPublicUrl(fileName);
      final urlWithTimestamp =
          "$newUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      await _supabase
          .from('profiles')
          .update({'photo_url': urlWithTimestamp})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          _photoUrl = urlWithTimestamp;
          _isUploading = false;
        });
        _showCustomToast("Foto Profil Berhasil Diganti!");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showCustomToast("Gagal upload foto: $e", isError: true);
      }
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
            final newVal = controller.text.trim();
            final userId = _supabase.auth.currentUser!.id;

            Navigator.pop(context);

            setState(() => _nickname = newVal);

            _showCustomToast("Nama berhasil diubah!");

            await _supabase
                .from('profiles')
                .update({'nickname': newVal})
                .eq('id', userId);
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
        hint: "Contoh: 0812...",
        controller: controller,
        inputType: TextInputType.phone,
        onSave: () async {
          if (controller.text.isNotEmpty) {
            final newVal = controller.text.trim();
            final userId = _supabase.auth.currentUser!.id;

            Navigator.pop(context);

            setState(() => _phone = newVal);

            _showCustomToast("Nomor HP berhasil disimpan!");

            await _supabase
                .from('profiles')
                .update({'phone': newVal})
                .eq('id', userId);
          }
        },
      ),
    );
  }

  Future<void> _updateGenderLogic(String code) async {
    final userId = _supabase.auth.currentUser!.id;

    setState(() {
      _isGenderSet = true;
      _gender = (code == 'L') ? "Laki-laki" : "Perempuan";
    });

    _showCustomToast("Jenis kelamin disimpan!");

    await _supabase.from('profiles').update({'gender': code}).eq('id', userId);
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
                      onTap: () {
                        Navigator.pop(context);
                        _updateGenderLogic('L');
                      },
                      child: _buildGenderOption(
                        Icons.male,
                        "Laki-laki",
                        Colors.blue,
                        const Color(0xFFE3F2FD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _updateGenderLogic('P');
                      },
                      child: _buildGenderOption(
                        Icons.female,
                        "Perempuan",
                        Colors.pink,
                        const Color(0xFFFCE4EC),
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

  Widget _buildGenderOption(
    IconData icon,
    String label,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
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
              Navigator.pop(context);

              setState(() {
                _isBirthDateSet = true;
                _birthDateDisplay = _formatDate(formattedDB);
              });

              _showCustomToast("Tanggal lahir disimpan!");

              await _supabase
                  .from('profiles')
                  .update({'birth_date': formattedDB})
                  .eq('id', userId);
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

  void _showLockedMsg() {
    _showCustomToast("Data ini tidak bisa diubah lagi", isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    String displayName = _nickname.isNotEmpty ? _nickname : _fullName;

    if (_isLoadingData) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 450,
            width: double.infinity,
            decoration: BoxDecoration(color: primaryBlue),
          ),
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
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
                              backgroundImage: _photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                              child: _photoUrl == null
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
                            onTap: () => _editNickname(_nickname),
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
                          _role.toUpperCase(),
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
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F8F4),
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
                      _buildInfoCard(
                        title: "NRP",
                        value: _nrp,
                        icon: Icons.badge_outlined,
                        primaryBlue: primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _editPhone(_phone),
                        child: _buildInfoCard(
                          title: "WhatsApp / No HP",
                          value: _phone,
                          icon: Icons.phone_android_rounded,
                          primaryBlue: primaryBlue,
                          showEditIcon: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: "Email",
                        value: _email,
                        icon: Icons.email_outlined,
                        primaryBlue: primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _isBirthDateSet
                            ? () => _showLockedMsg()
                            : _pickBirthDate,
                        child: _buildInfoCard(
                          title: "Tanggal Lahir",
                          value: _birthDateDisplay,
                          icon: Icons.cake_outlined,
                          primaryBlue: _isBirthDateSet
                              ? primaryBlue
                              : Colors.grey,
                          showEditIcon: !_isBirthDateSet,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _isGenderSet
                            ? () => _showLockedMsg()
                            : _editGender,
                        child: _buildInfoCard(
                          title: "Jenis Kelamin",
                          value: _gender,
                          icon: _gender == "Perempuan"
                              ? Icons.female
                              : Icons.male,
                          primaryBlue: _isGenderSet
                              ? (_gender == "Perempuan"
                                    ? Colors.pink
                                    : Colors.blue)
                              : Colors.grey,
                          showEditIcon: !_isGenderSet,
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
                      SizedBox(
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
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
