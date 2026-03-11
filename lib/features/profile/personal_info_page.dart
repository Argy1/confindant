import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/widgets/app_primary_button.dart';
import 'package:confindant/app/widgets/app_text_field.dart';
import 'package:confindant/core/utils/image_picker_error.dart';
import 'package:confindant/features/profile/models/profile_models.dart';
import 'package:confindant/features/profile/presentation/view_models/profile_settings_view_model.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  final _imagePicker = ImagePicker();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currencyController = TextEditingController();
  bool _initialized = false;
  bool _isUploadingAvatar = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(profileSettingsProvider).userData;
    if (!_initialized) {
      _initialized = true;
      _fullNameController.text = data.fullName;
      _usernameController.text = data.username;
      _emailController.text = data.email;
      _phoneController.text = data.phone;
      _currencyController.text = data.currency;
    }

    return ProfileDetailScaffold(
      title: 'Personal Information',
      subtitle: 'Manage your account identity',
      child: Column(
        children: [
          ProfileSettingsCard(
            title: 'Profile Details',
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.blue600,
                  child: CircleAvatar(
                    radius: 41,
                    backgroundImage: _avatarImageProvider(data.avatarPath),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: _isUploadingAvatar
                      ? null
                      : () => _pickAndUploadAvatar(context),
                  icon: _isUploadingAvatar
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    _isUploadingAvatar ? 'Processing...' : 'Change Profile Photo',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  hintText: 'Enter full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                  hintText: 'Enter username',
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Phone',
                  hintText: 'Enter phone',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _currencyController,
                  labelText: 'Preferred Currency',
                  hintText: 'IDR (Rp)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: 'Save Changes',
                  onPressed: () => _save(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final source = await _showImageSourcePicker(context);
    if (source == null) return;
    await _pickAndUploadAvatarFromSource(source);
  }

  Future<ImageSource?> _showImageSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatarFromSource(ImageSource source) async {
    setState(() => _isUploadingAvatar = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (image == null) {
        return;
      }

      final success = await ref
          .read(profileSettingsProvider.notifier)
          .uploadAvatar(image.path);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated.'
                : 'Failed to upload profile photo.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imagePickerErrorMessage(error, forCamera: source == ImageSource.camera),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final currency = _currencyController.text.trim();

    final valid =
        fullName.isNotEmpty &&
        username.isNotEmpty &&
        phone.isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    final current = ref.read(profileSettingsProvider).userData;
    await ref
        .read(profileSettingsProvider.notifier)
        .updateUser(
          ProfileUserData(
            fullName: fullName,
            username: username,
            email: email,
            phone: phone,
            currency: currency,
            avatarPath: current.avatarPath,
          ),
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }
}

ImageProvider _avatarImageProvider(String avatarPath) {
  if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
    return NetworkImage(avatarPath);
  }
  return AssetImage(avatarPath);
}
