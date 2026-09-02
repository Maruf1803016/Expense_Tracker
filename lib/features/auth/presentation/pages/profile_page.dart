import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/messenger_utils.dart';
import 'package:expense_tracker/core/utils/haptics_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _selectedPhotoPath = user?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    
    if (image != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
        
        if (mounted) {
          setState(() {
            _selectedPhotoPath = savedImage.path;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _selectedPhotoPath = image.path;
          });
        }
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final effectivePhotoUrl = _selectedPhotoPath ?? user?.photoUrl;
    ImageProvider? avatarImg;
    if (effectivePhotoUrl != null && effectivePhotoUrl.isNotEmpty) {
      if (effectivePhotoUrl.startsWith('http')) {
        avatarImg = NetworkImage(effectivePhotoUrl);
      } else if (File(effectivePhotoUrl).existsSync()) {
        avatarImg = FileImage(File(effectivePhotoUrl));
      }
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text('Edit Profile', style: GoogleFonts.fraunces(fontWeight: FontWeight.bold, color: context.textPrimary)),
      ),
      body: Column(
        children: [
          if (authProvider.isLoading)
            LinearProgressIndicator(color: context.emerald, minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticsService.selection();
                        _pickImage();
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: context.cardBg,
                            backgroundImage: avatarImg,
                            child: avatarImg == null
                                ? Icon(Icons.person, size: 60, color: context.textMuted)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.gold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: GoogleFonts.inter(color: context.textMuted),
                        prefixIcon: Icon(Icons.person_outline, color: context.textMuted),
                        filled: true,
                        fillColor: context.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user?.email,
                      readOnly: true,
                      style: GoogleFonts.inter(color: context.textMuted),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: GoogleFonts.inter(color: context.textMuted),
                        prefixIcon: Icon(Icons.email_outlined, color: context.textMuted),
                        filled: true,
                        fillColor: context.surface2,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.line)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: context.emerald,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (user?.email.toLowerCase().endsWith('@gmail.com') == true)
                                  ? 'Authenticated via Gmail'
                                  : 'Authenticated via Email',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: context.gold),
                      title: Text('Change Password', style: TextStyle(color: context.textPrimary)),
                      trailing: Icon(Icons.chevron_right, color: context.textMuted),
                      onTap: () {
                        HapticsService.selection();
                        _showChangePasswordDialog();
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: context.cardBg,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.gold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          HapticsService.lightImpact();
                          if (_formKey.currentState!.validate()) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            
                            try {
                              await authProvider.updateProfile(
                                displayName: _nameController.text.trim(),
                                photoUrl: _selectedPhotoPath,
                              );
                              
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Profile updated successfully'),
                                  backgroundColor: context.emerald,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              navigator.pop();
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: ${e.toString()}'),
                                  backgroundColor: context.brick,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isStep1 = true;
  bool _isVerifying = false;
  String? _step1Error;

  String _strength = '';
  Color _strengthColor = Colors.grey;

  void _checkStrength(String value) {
    if (value.isEmpty) {
      _strength = '';
    } else if (value.length < 6) {
      _strength = 'Weak';
      _strengthColor = context.brick;
    } else if (value.length < 10) {
      _strength = 'Medium';
      _strengthColor = context.gold;
    } else {
      _strength = 'Strong';
      _strengthColor = context.emerald;
    }
    setState(() {});
  }

  bool get _isNewValid {
    return _newPasswordController.text.length >= 8 &&
           _newPasswordController.text == _confirmPasswordController.text;
  }

  Future<void> _verifyCurrentPassword() async {
    setState(() {
      _isVerifying = true;
      _step1Error = null;
    });

    try {
      await context.read<AuthProvider>().verifyPassword(_currentPasswordController.text);
      if (mounted) {
        setState(() {
          _isStep1 = false;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _step1Error = 'Incorrect password';
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      title: Text(_isStep1 ? 'Verify Identity' : 'Set New Password', style: TextStyle(color: context.textPrimary)),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isStep1 ? _buildStep1() : _buildStep2(),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: context.textMuted)),
        ),
        if (_isStep1)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.gold, foregroundColor: Colors.white),
            onPressed: _currentPasswordController.text.isEmpty || _isVerifying ? null : _verifyCurrentPassword,
            child: _isVerifying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify'),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.gold, foregroundColor: Colors.white),
            onPressed: _isNewValid ? () async {
              try {
                await context.read<AuthProvider>().changePassword(
                  _currentPasswordController.text,
                  _newPasswordController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                // Error already shown by provider
              }
            } : null,
            child: const Text('Change Password'),
          ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your current password to continue.', style: TextStyle(fontSize: 14, color: context.textMuted)),
        const SizedBox(height: 16),
        TextField(
          controller: _currentPasswordController,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: 'Current Password',
            labelStyle: TextStyle(color: context.textMuted),
            errorText: _step1Error,
            filled: true,
            fillColor: context.surface2,
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: context.textMuted),
              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
          obscureText: _obscureCurrent,
          onChanged: (_) => setState(() => _step1Error = null),
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final matches = _newPasswordController.text == _confirmPasswordController.text && _confirmPasswordController.text.isNotEmpty;
    
    return Column(
      key: const ValueKey('step2'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _newPasswordController,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: 'New Password',
            labelStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.surface2,
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: context.textMuted),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          obscureText: _obscureNew,
          onChanged: _checkStrength,
          autofocus: true,
        ),
        if (_strength.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Text('Strength: ', style: TextStyle(fontSize: 12, color: context.textMuted)),
                Text(_strength, style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            labelStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.surface2,
            suffixIcon: matches
                ? Icon(Icons.check_circle, color: context.emerald)
                : IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: context.textMuted),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
          ),
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
        ),
        if (!matches && _confirmPasswordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Passwords do not match', style: TextStyle(color: context.brick, fontSize: 12)),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
