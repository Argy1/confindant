import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/utils/image_picker_error.dart';
import 'package:camera/camera.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializingCamera = false;
  bool _isCapturing = false;
  String? _cameraError;
  FlashMode _flashMode = FlashMode.off;
  bool _isPickingImage = false;
  final _picker = ImagePicker();

  bool get _cameraReady => _cameraController?.value.isInitialized ?? false;

  bool get _isBusy => _isPickingImage || _isCapturing || _isInitializingCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              child: _buildCameraViewport(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 390;
                        final ultraCompact = constraints.maxWidth < 345;
                        return Row(
                          children: [
                            _RoundAction(
                              iconPath: 'assets/icons/scan/back.svg',
                              fallback: Icons.arrow_back_rounded,
                              onTap: context.pop,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ActionCapsuleButton(
                                      label: ultraCompact
                                          ? null
                                          : (_isPickingImage
                                              ? l10n.processing
                                              : (compact ? l10n.scanUploadShort : l10n.scanUploadFromGallery)),
                                      enabled: !_isBusy,
                                      tooltip: l10n.scanUploadFromGallery,
                                      onTap: () => _pickAndContinue(ImageSource.gallery),
                                      leading: const _SvgIcon(
                                        path: 'assets/icons/scan/upload.svg',
                                        fallback: Icons.upload_rounded,
                                        color: AppColors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ActionCapsuleButton(
                                      label: ultraCompact
                                          ? null
                                          : (compact ? l10n.scanInputManualShort : l10n.scanInputManual),
                                      enabled: !(_isPickingImage || _isCapturing),
                                      tooltip: l10n.scanInputManual,
                                      onTap: _openManualInput,
                                      leading: const Icon(
                                        Icons.edit_note_rounded,
                                        color: AppColors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RoundAction(
                              iconPath: 'assets/icons/scan/flash_vec.svg',
                              fallback: Icons.flash_on_rounded,
                              enabled: _cameraReady && !_isBusy,
                              onTap: _toggleFlash,
                              active: _flashMode == FlashMode.torch,
                            ),
                          ],
                        );
                      },
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
                          children: [
                            const TextSpan(
                              text: 'Tip:',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' ${l10n.scanTipText}'),
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

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception(l10n.scanCameraUnavailable);
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _flashMode = FlashMode.off;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = _cameraExceptionMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializingCamera = false);
      }
    }
  }

  String _cameraExceptionMessage(CameraException error) {
    final l10n = AppLocalizations.of(context)!;
    switch (error.code) {
      case 'CameraAccessDenied':
        return l10n.scanCameraPermissionDenied;
      case 'CameraAccessDeniedWithoutPrompt':
        return l10n.scanCameraPermissionDeniedPermanently;
      case 'CameraAccessRestricted':
        return l10n.scanCameraRestricted;
      case 'AudioAccessDenied':
      case 'AudioAccessDeniedWithoutPrompt':
      case 'AudioAccessRestricted':
        return l10n.scanAudioAccessDenied;
      default:
        return '${l10n.scanFailedToOpenCamera}: ${error.description ?? error.code}';
    }
  }

  Widget _buildCameraViewport() {
    if (_isInitializingCamera) {
      return Container(
        color: const Color(0xFF4A5565),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Colors.white),
      );
    }

    final error = _cameraError;
    if (error != null) {
      return GestureDetector(
        onTap: _initializeCamera,
        child: Container(
          color: const Color(0xFF4A5565),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 34),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.scanTapToRetry,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF4A5565),
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context)!.scanPreparingCamera,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _isBusy ? null : _captureAndContinue,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 1,
                  height: controller.value.previewSize?.width ?? 1,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.08)),
          const _FrameCorners(),
          if (_isCapturing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Text(
                AppLocalizations.of(context)!.scanTapToTakePhoto,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final next = _flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashMode = next);
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.scanFlashUnavailable}: ${error.description ?? error.code}',
          ),
        ),
      );
    }
  }

  Future<void> _captureAndContinue() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isBusy) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final selected = await controller.takePicture();
      if (!mounted) return;
      await context.push(RoutePaths.scanReceipt, extra: selected.path);
    } on CameraException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cameraExceptionMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
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

  Future<void> _openManualInput() async {
    await context.push(RoutePaths.scanReceipt);
  }
}

class _ActionCapsuleButton extends StatelessWidget {
  const _ActionCapsuleButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
    this.leading,
  });

  final String? label;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment(-0.96, -0.28),
                  end: Alignment(0.96, 0.28),
                  colors: [
                    Color(0xFF000314),
                    Color(0xFF0A2472),
                  ],
                )
              : null,
          color: enabled ? null : const Color(0xFF0A2472).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  if (label != null) const SizedBox(width: 6),
                ],
                if (label != null)
                  Flexible(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: tooltip, child: content);
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
