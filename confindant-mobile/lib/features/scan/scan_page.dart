import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/utils/image_picker_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _flashEnabled = false;
  bool _isPickingImage = false;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 50,
              top: 72,
              right: 50,
              bottom: 214,
              child: Container(
                color: const Color(0xFF4A5565),
                child: const _FrameCorners(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(35, 11, 44, 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.49),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _RoundAction(
                          iconPath: 'assets/icons/scan/back.svg',
                          fallback: Icons.arrow_back_rounded,
                          onTap: context.pop,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment(-0.96, -0.28),
                                  end: Alignment(0.96, 0.28),
                                  colors: [
                                    Color(0xFF000314),
                                    Color(0xFF0A2472),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isPickingImage
                                    ? null
                                    : () => _pickAndContinue(ImageSource.gallery),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _SvgIcon(
                                      path: 'assets/icons/scan/upload.svg',
                                      fallback: Icons.upload_rounded,
                                      color: AppColors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPickingImage
                                          ? 'Processing...'
                                          : 'Upload from Gallery',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoundIconAction(
                          icon: Icons.photo_camera_outlined,
                          onTap: _isPickingImage
                              ? null
                              : () => _pickAndContinue(ImageSource.camera),
                        ),
                        const SizedBox(width: 10),
                        _RoundAction(
                          iconPath: 'assets/icons/scan/flash_vec.svg',
                          fallback: Icons.flash_on_rounded,
                          enabled: !_isPickingImage,
                          onTap: () =>
                              setState(() => _flashEnabled = !_flashEnabled),
                          active: _flashEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA6E1FA)),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.accentAction,
                            fontSize: 14,
                            height: 20 / 14,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Tip:',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(
                              text:
                                  ' Make sure the receipt is clearly visible and well-lit for best results. The app will automatically extract transaction details.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndContinue(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final selected = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (selected == null) return;
      await context.push(RoutePaths.scanReceipt, extra: selected.path);
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
        setState(() => _isPickingImage = false);
      }
    }
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.iconPath,
    required this.fallback,
    required this.onTap,
    this.active = false,
    this.enabled = true,
  });

  final String iconPath;
  final IconData fallback;
  final VoidCallback onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: enabled
            ? (active ? const Color(0xFF0A2472) : Colors.white)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Center(
            child: _SvgIcon(
              path: iconPath,
              fallback: fallback,
              color: active && enabled ? Colors.white : Colors.black,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconAction extends StatelessWidget {
  const _RoundIconAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrameCorners extends StatelessWidget {
  const _FrameCorners();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(
          top: 0,
          left: 0,
          child: _Corner(path: 'assets/icons/scan/corner_tl.svg'),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _Corner(path: 'assets/icons/scan/corner_tr.svg'),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(path: 'assets/icons/scan/corner_bl.svg'),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(path: 'assets/icons/scan/corner_br.svg'),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return _SvgIcon(
      path: path,
      fallback: Icons.crop_free_rounded,
      color: Colors.white,
      size: 49.289,
    );
  }
}

class _SvgIcon extends StatelessWidget {
  const _SvgIcon({
    required this.path,
    required this.fallback,
    required this.color,
    required this.size,
  });

  final String path;
  final IconData fallback;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(fallback, color: color, size: size),
    );
  }
}
