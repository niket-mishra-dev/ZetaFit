import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();

  String gender = "male";
  String? avatarUrl;
  File? pickedImageFile;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ----------------------------------------------------------------------
  // LOAD USER DATA
  // ----------------------------------------------------------------------
  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      nameController.text =
          user.userMetadata?["full_name"] ?? user.email?.split("@").first ?? "";
      gender = user.userMetadata?["gender"] ?? "male";
      avatarUrl = user.userMetadata?["avatar_url"];
    }

    setState(() => loading = false);
  }

  // ----------------------------------------------------------------------
  // PICK IMAGE
  // ----------------------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (picked != null) {
      setState(() {
        pickedImageFile = File(picked.path);
      });
    }
  }

  // ----------------------------------------------------------------------
  // UPLOAD IMAGE TO SUPABASE
  // ----------------------------------------------------------------------
  Future<String?> _uploadProfileImage() async {
    if (pickedImageFile == null) return avatarUrl;

    try {
      final fileExt = pickedImageFile!.path.split(".").last;
      final fileName = "${const Uuid().v4()}.$fileExt";

      final fileBytes = await pickedImageFile!.readAsBytes();

      await supabase.storage.from("avatars").uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: "image/png"),
          );

      final publicUrl = supabase.storage.from("avatars").getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint("Upload error: $e");
      return avatarUrl;
    }
  }

  // ----------------------------------------------------------------------
  // SAVE PROFILE
  // ----------------------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Upload avatar image first if needed
    final uploadedAvatarUrl = await _uploadProfileImage();

    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            "full_name": nameController.text.trim(),
            "gender": gender,
            "avatar_url": uploadedAvatarUrl,
          },
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update error: $e")),
      );
    }

    setState(() => saving = false);
  }

  // ----------------------------------------------------------------------
  // UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)
            ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _avatarSection(theme),
                    const SizedBox(height: 30),

                    _inputField("Full Name", nameController, (v) {
                      if (v!.isEmpty) return "Name cannot be empty";
                      return null;
                    }),

                    const SizedBox(height: 20),
                    _genderSelector(theme),
                    const SizedBox(height: 40),

                    _saveButton(theme),
                  ],
                ),
              ),
            ),
    );
  }

  // ----------------------------------------------------------------------
  // AVATAR SECTION WITH UPLOAD
  // ----------------------------------------------------------------------
  Widget _avatarSection(ThemeData theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.6),
                  theme.colorScheme.secondary.withOpacity(0.6),
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: pickedImageFile != null
                  ? FileImage(pickedImageFile!)
                  : avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : null,
              child: (pickedImageFile == null && avatarUrl == null)
                  ? Icon(Icons.person,
                      size: 55,
                      color: theme.colorScheme.onSurface.withOpacity(0.6))
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap to change photo",
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: theme.colorScheme.primary,
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // INPUT FIELD
  // ----------------------------------------------------------------------
  Widget _inputField(
      String label, TextEditingController controller, FormFieldValidator<String> validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // GENDER SELECTOR
  // ----------------------------------------------------------------------
  Widget _genderSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Gender", style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        Row(
          children: [
            _genderOption(theme, "male", Icons.male),
            const SizedBox(width: 14),
            _genderOption(theme, "female", Icons.female),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(ThemeData theme, String value, IconData icon) {
    final selected = gender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface),
              const SizedBox(height: 6),
              Text(
                value.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SAVE BUTTON
  // ----------------------------------------------------------------------
  Widget _saveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: saving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "Save Changes",
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
