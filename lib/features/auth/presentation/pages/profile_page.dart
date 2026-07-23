import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/messenger_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image != null) {
      if (mounted) {
        context.read<AuthProvider>().updateProfile(photoUrl: image.path);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Column(
        children: [
          if (authProvider.isLoading)
            const LinearProgressIndicator(color: AppTheme.emeraldGreen, minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.secondaryBackground,
                            backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                                ? FileImage(File(user.photoUrl!))
                                : null,
                            child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.emeraldGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
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
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user?.email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: AppTheme.emeraldGreen),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordDialog,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    const Divider(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            
                            try {
                              await authProvider.updateProfile(displayName: _nameController.text);
                              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                              authProvider.notifyListeners();
                              
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  backgroundColor: AppTheme.emeraldGreen,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              navigator.pop();
                            } catch (e) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: ${e.toString()}'),
                                  backgroundColor: AppTheme.expenseColor,
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
      _strengthColor = Colors.red;
    } else if (value.length < 10) {
      _strength = 'Medium';
      _strengthColor = Colors.orange;
    } else {
      _strength = 'Strong';
      _strengthColor = AppTheme.emeraldGreen;
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
      title: Text(_isStep1 ? 'Verify Identity' : 'Set New Password'),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isStep1 ? _buildStep1() : _buildStep2(),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_isStep1)
          ElevatedButton(
            onPressed: _currentPasswordController.text.isEmpty || _isVerifying ? null : _verifyCurrentPassword,
            child: _isVerifying 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Verify'),
          )
        else
          ElevatedButton(
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
        const Text('Enter your current password to continue.', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        TextField(
          controller: _currentPasswordController,
          decoration: InputDecoration(
            labelText: 'Current Password',
            errorText: _step1Error,
            suffixIcon: IconButton(
              icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
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
          decoration: InputDecoration(
            labelText: 'New Password',
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
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
                Text('Strength: ', style: const TextStyle(fontSize: 12)),
                Text(_strength, style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            suffixIcon: matches
                ? const Icon(Icons.check_circle, color: AppTheme.emeraldGreen)
                : IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
          ),
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
        ),
        if (!matches && _confirmPasswordController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Passwords do not match', style: TextStyle(color: Colors.red, fontSize: 12)),
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
