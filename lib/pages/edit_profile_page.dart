import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _weightKgController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightLbsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _profilePhoto;
  File? _coverPhoto;
  String? _existingAvatarPath;
  String? _existingCoverPath;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _heightUnitIsCm = true; // true = cm, false = feet/inches
  bool _weightUnitIsKg = true; // true = kg, false = lbs
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _firstNameController.text = response['first_name'] ?? '';
          _lastNameController.text = response['last_name'] ?? '';
          _userIdController.text = response['user_id'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          
          // Height and weight
          final heightCm = response['height_cm'];
          final weightKg = response['weight_kg'];
          
          if (heightCm != null) {
            _heightCmController.text = (heightCm as num).toString();
            _updateHeightFromCm(heightCm.toDouble());
          }
          
          if (weightKg != null) {
            _weightKgController.text = (weightKg as num).toString();
            _updateWeightFromKg(weightKg.toDouble());
          }
          
          _existingAvatarPath = response['avatar_path'];
          _existingCoverPath = response['cover_path'];
          _selectedGender = response['gender'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateHeightFromCm(double cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    _heightFeetController.text = feet.toString();
    _heightInchesController.text = inches.toString();
  }

  void _updateHeightFromFeetInches(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    final cm = totalInches * 2.54;
    _heightCmController.text = cm.round().toString();
  }

  void _updateWeightFromKg(double kg) {
    final lbs = kg * 2.20462;
    _weightLbsController.text = lbs.round().toString();
  }

  void _updateWeightFromLbs(double lbs) {
    final kg = lbs / 2.20462;
    _weightKgController.text = kg.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightCmController.dispose();
    _weightKgController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightLbsController.dispose();
    super.dispose();
  }

  Future<bool> _requestPhotoPermission() async {
    final status = await Permission.photos.status;
    if (status.isGranted) return true;
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Please enable photo access in settings'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    
    return false;
  }

  Future<void> _pickProfilePhoto() async {
    HapticFeedback.lightImpact();
    
    if (!await _requestPhotoPermission()) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() => _profilePhoto = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickCoverPhoto() async {
    HapticFeedback.lightImpact();
    
    if (!await _requestPhotoPermission()) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _picker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() => _coverPhoto = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile, String bucket, String? existingPath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final fileName = '$userId/$timestamp.$extension';

      // Delete old image if exists
      if (existingPath != null) {
        try {
          await supabase.storage.from(bucket).remove([existingPath]);
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      // Upload new image
      await supabase.storage.from(bucket).upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );

      return fileName;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isUploading = true);
    HapticFeedback.mediumImpact();

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      String? avatarPath = _existingAvatarPath;
      String? coverPath = _existingCoverPath;

      // Upload profile photo if changed
      if (_profilePhoto != null) {
        avatarPath = await _uploadImage(_profilePhoto!, 'avatars', _existingAvatarPath);
      }

      // Upload cover photo if changed
      if (_coverPhoto != null) {
        coverPath = await _uploadImage(_coverPhoto!, 'covers', _existingCoverPath);
      }

      // Get height and weight values
      double? heightCm;
      double? weightKg;

      if (_heightUnitIsCm) {
        final cm = double.tryParse(_heightCmController.text);
        if (cm != null) heightCm = cm;
      } else {
        final feet = int.tryParse(_heightFeetController.text) ?? 0;
        final inches = int.tryParse(_heightInchesController.text) ?? 0;
        if (feet > 0 || inches > 0) {
          _updateHeightFromFeetInches(feet, inches);
          heightCm = double.tryParse(_heightCmController.text);
        }
      }

      if (_weightUnitIsKg) {
        final kg = double.tryParse(_weightKgController.text);
        if (kg != null) weightKg = kg;
      } else {
        final lbs = double.tryParse(_weightLbsController.text);
        if (lbs != null) {
          _updateWeightFromLbs(lbs);
          weightKg = double.tryParse(_weightKgController.text);
        }
      }

      // Update profile in Supabase
      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'user_id': _userIdController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone': _phoneController.text.trim(),
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
        if (_selectedGender != null) 'gender': _selectedGender,
        if (avatarPath != null) 'avatar_path': avatarPath,
        if (coverPath != null) 'cover_path': coverPath,
      };

      await supabase.from('profiles').update(updateData).eq('id', userId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _saveProfile,
            child: _isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profilePhoto != null
                                  ? Image.file(_profilePhoto!, fit: BoxFit.cover)
                                  : _existingAvatarPath != null
                                      ? Image.network(
                                          Supabase.instance.client.storage.from('avatars').getPublicUrl(_existingAvatarPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: colorScheme.primary.withValues(alpha: 0.1),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 60,
                                                color: colorScheme.primary,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: colorScheme.primary.withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Change Profile Photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Cover Photo Section
              Text(
                'Cover Photo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickCoverPhoto,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _coverPhoto != null
                        ? Image.file(_coverPhoto!, fit: BoxFit.cover)
                        : _existingCoverPath != null
                            ? Image.network(
                                Supabase.instance.client.storage.from('covers').getPublicUrl(_existingCoverPath!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_rounded,
                                            size: 48,
                                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to add cover photo',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_rounded,
                                        size: 48,
                                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add cover photo',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Basic Info Section
              Text(
                'Basic Info',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'First Name',
                controller: _firstNameController,
                type: TextInputType.name,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildFormField(
                label: 'Last Name',
                controller: _lastNameController,
                type: TextInputType.name,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildFormField(
                label: 'User ID',
                controller: _userIdController,
                type: TextInputType.text,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Required';
                  if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(s)) {
                    return 'Use a-z, 0-9, underscore, 3 to 20 chars';
                  }
                  return null;
                },
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Contact Section
              Text(
                'Contact',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormField(
                label: 'Email',
                controller: _emailController,
                type: TextInputType.emailAddress,
                validator: (v) => (v != null && v.contains('@')) ? null : 'Enter valid email',
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              _buildFormField(
                label: 'Phone Number',
                controller: _phoneController,
                type: TextInputType.phone,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Body Metrics Section
              Text(
                'Body Metrics',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Height with unit toggle
              Row(
                children: [
                  Expanded(
                    child: _heightUnitIsCm
                        ? _buildFormField(
                            label: 'Height (cm)',
                            controller: _heightCmController,
                            type: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final h = int.tryParse(v);
                              if (h == null || h < 80 || h > 250) return '80-250 cm';
                              return null;
                            },
                            colorScheme: colorScheme,
                            isDark: isDark,
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildFormField(
                                  label: 'Feet',
                                  controller: _heightFeetController,
                                  type: TextInputType.number,
                                  formatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final f = int.tryParse(v);
                                    if (f == null || f < 2 || f > 8) return '2-8 ft';
                                    return null;
                                  },
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildFormField(
                                  label: 'Inches',
                                  controller: _heightInchesController,
                                  type: TextInputType.number,
                                  formatters: [FilteringTextInputFormatter.digitsOnly],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    final i = int.tryParse(v);
                                    if (i == null || i < 0 || i > 11) return '0-11 in';
                                    return null;
                                  },
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ToggleButtons(
                      isSelected: [_heightUnitIsCm, !_heightUnitIsCm],
                      onPressed: (index) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _heightUnitIsCm = index == 0;
                          if (_heightUnitIsCm) {
                            // Convert from feet/inches to cm
                            final feet = int.tryParse(_heightFeetController.text) ?? 0;
                            final inches = int.tryParse(_heightInchesController.text) ?? 0;
                            if (feet > 0 || inches > 0) {
                              _updateHeightFromFeetInches(feet, inches);
                            }
                          } else {
                            // Convert from cm to feet/inches
                            final cm = double.tryParse(_heightCmController.text);
                            if (cm != null) {
                              _updateHeightFromCm(cm);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                      children: const [
                        Text('cm'),
                        Text('ft/in'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Weight with unit toggle
              Row(
                children: [
                  Expanded(
                    child: _weightUnitIsKg
                        ? _buildFormField(
                            label: 'Weight (kg)',
                            controller: _weightKgController,
                            type: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final w = double.tryParse(v);
                              if (w == null || w < 25 || w > 300) return '25-300 kg';
                              return null;
                            },
                            colorScheme: colorScheme,
                            isDark: isDark,
                          )
                        : _buildFormField(
                            label: 'Weight (lbs)',
                            controller: _weightLbsController,
                            type: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final w = double.tryParse(v);
                              if (w == null || w < 55 || w > 660) return '55-660 lbs';
                              return null;
                            },
                            colorScheme: colorScheme,
                            isDark: isDark,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ToggleButtons(
                      isSelected: [_weightUnitIsKg, !_weightUnitIsKg],
                      onPressed: (index) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _weightUnitIsKg = index == 0;
                          if (_weightUnitIsKg) {
                            // Convert from lbs to kg
                            final lbs = double.tryParse(_weightLbsController.text);
                            if (lbs != null) {
                              _updateWeightFromLbs(lbs);
                            }
                          } else {
                            // Convert from kg to lbs
                            final kg = double.tryParse(_weightKgController.text);
                            if (kg != null) {
                              _updateWeightFromKg(kg);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                      children: const [
                        Text('kg'),
                        Text('lbs'),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Gender Selection
              Text(
                'Gender',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildGenderChip('male', 'Male', colorScheme, isDark),
                  _buildGenderChip('female', 'Female', colorScheme, isDark),
                  _buildGenderChip('other', 'Other', colorScheme, isDark),
                  _buildGenderChip('prefer_not_to_say', 'Prefer not to say', colorScheme, isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGenderChip(String value, String label, ColorScheme colorScheme, bool isDark) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedGender = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? type,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        inputFormatters: formatters,
        validator: validator,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
