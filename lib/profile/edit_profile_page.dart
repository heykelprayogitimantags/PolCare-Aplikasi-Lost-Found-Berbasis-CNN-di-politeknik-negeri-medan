import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  UserModel? _userProfile;
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (mounted && profile != null) {
        setState(() {
          _userProfile = profile;
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber ?? '';
          _emailController.text = profile.email;
          _uploadedImageUrl = profile.photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Gagal memuat profil: $e");
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() => _imageFile = File(image.path));
      await _uploadToCloudinary(_imageFile!);
    }
  }

  Future<void> _uploadToCloudinary(File image) async {
    setState(() => _isUploading = true);
    const cloudName = "doqsyiqaj";
    const uploadPreset = "polmedcare";
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        setState(() => _uploadedImageUrl = data['secure_url']);
        _showSuccessSnackBar("Foto berhasil diunggah!");
      } else {
        throw Exception("Upload gagal (${response.statusCode})");
      }
    } catch (e) {
      _showErrorSnackBar("Gagal upload: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploading) {
      _showErrorSnackBar("Harap tunggu upload foto selesai.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User tidak ditemukan");

      final updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'photoUrl': _uploadedImageUrl ?? _userProfile?.photoUrl,
      };

      await _firestoreService.updateUserProfile(user.uid, updatedData);

      if (mounted) {
        _showSuccessSnackBar("Profil berhasil diperbarui!");
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar("Gagal menyimpan profil: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blueAccent),
                title: const Text('Pilih dari Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orangeAccent),
                title: const Text('Ambil Foto'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.greenAccent.shade700),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.check_rounded),
                  tooltip: 'Simpan',
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildProfileImage(),
                    const SizedBox(height: 24),

                    // --- CARD FORM FIELD MODERN ---
                    _buildTextField(
                      controller: _nameController,
                      label: "Nama Lengkap",
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: "Nomor Telepon",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? "Nomor telepon tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("SIMPAN PERUBAHAN"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 65,
          backgroundColor: Colors.white,
          backgroundImage: _imageFile != null
              ? FileImage(_imageFile!)
              : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                  ? NetworkImage(_uploadedImageUrl!)
                  : null) as ImageProvider?,
          child: (_imageFile == null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty))
              ? const Icon(Icons.person, size: 70, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 8,
          child: FloatingActionButton.small(
            heroTag: "editPhoto",
            onPressed: _isUploading ? null : _showImageSourceSheet,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
