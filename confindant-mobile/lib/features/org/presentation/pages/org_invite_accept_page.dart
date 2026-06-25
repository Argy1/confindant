import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OrgInviteAcceptPage extends ConsumerStatefulWidget {
  const OrgInviteAcceptPage({super.key, required this.token});
  final String token;

  @override
  ConsumerState<OrgInviteAcceptPage> createState() =>
      _OrgInviteAcceptPageState();
}

class _OrgInviteAcceptPageState extends ConsumerState<OrgInviteAcceptPage> {
  Map<String, dynamic>? _info;
  bool _loading = true;
  bool _accepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(backendApiServiceProvider)
          .orgInviteInfo(widget.token);
      if (!mounted) return;
      setState(() => _info = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgInviteAccept(widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil bergabung ke organisasi!')),
      );
      context.go(RoutePaths.orgDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Undangan Organisasi'),
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 56, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text(
                'Link tidak valid atau sudah kadaluarsa.',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _loadInfo,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final orgName = _info?['organization']?['name']?.toString() ?? '';
    final email = _info?['email']?.toString() ?? '';
    final role = _info?['role']?.toString() ?? '';
    final inviterName = (_info?['invited_by'] as Map?)?['name']?.toString() ?? '';

    const roleLabel = {
      'admin': 'Admin',
      'bendahara': 'Bendahara',
      'auditor': 'Auditor',
      'viewer': 'Viewer',
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.blue900.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.business_rounded,
                  size: 40, color: AppColors.blue900),
            ),
            const SizedBox(height: 24),
            Text(
              orgName,
              style:
                  AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Anda diundang oleh $inviterName\nuntuk bergabung sebagai:',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.blue900.withAlpha(15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                roleLabel[role] ?? role,
                style: AppTextStyles.label.copyWith(
                    color: AppColors.blue900, fontWeight: FontWeight.w700),
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                email,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _accepting ? null : _accept,
                child: _accepting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Terima & Bergabung'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(RoutePaths.home),
                child: const Text('Tolak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
