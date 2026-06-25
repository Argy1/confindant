import 'dart:async';
import 'dart:io';

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/account_picker.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class OrgScanPage extends ConsumerStatefulWidget {
  const OrgScanPage({super.key});

  @override
  ConsumerState<OrgScanPage> createState() => _OrgScanPageState();
}

class _OrgScanPageState extends ConsumerState<OrgScanPage> {
  static const int _maxPollAttempts = 20;
  static const Duration _pollDelay = Duration(seconds: 2);

  // Image
  XFile? _image;

  // OCR state
  bool _isLoadingOcr = false;
  String? _ocrJobId;
  String? _ocrStatus;

  // Form fields (populated from OCR result)
  final _descController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  OrgAccount? _debitAccount;
  OrgAccount? _creditAccount;

  bool _isSaving = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);

    return OrgScaffold(
      title: 'Scan Struk',
      current: OrgNavItem.more,
      child: orgId == null
          ? const Center(child: Text('Pilih organisasi terlebih dahulu.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image picker card
                  AppCardContainer(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _image != null
                              ? Image.file(
                                  File(_image!.path),
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 220,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 48,
                                        color: Color(0xFF0A2472),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Belum ada foto',
                                        style: TextStyle(
                                          color: Color(0xFF0A2472),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingOcr
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Kamera'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoadingOcr
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Galeri'),
                              ),
                            ),
                          ],
                        ),
                        if (_isLoadingOcr) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(minHeight: 3),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(_ocrStatus),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        if (!_isLoadingOcr && _ocrStatus == 'failed') ...[
                          const SizedBox(height: 8),
                          Text(
                            'OCR gagal. Isi form secara manual atau coba lagi.',
                            style: AppTextStyles.caption
                                .copyWith(color: const Color(0xFFC10007)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Form card
                  AppCardContainer(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Jurnal',
                          style: AppTextStyles.sectionTitle
                              .copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah (Rp)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal',
                              suffixIcon: Icon(Icons.calendar_today_rounded),
                            ),
                            child: Text(_formatDate(_date)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Debit account picker
                        _buildAccountField(
                          label: 'Akun Debit',
                          account: _debitAccount,
                          orgId: orgId,
                          onPicked: (a) => setState(() => _debitAccount = a),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Credit account picker
                        _buildAccountField(
                          label: 'Akun Kredit',
                          account: _creditAccount,
                          orgId: orgId,
                          onPicked: (a) => setState(() => _creditAccount = a),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        AppPrimaryButton(
                          label: _isSaving ? 'Menyimpan...' : 'Catat ke Jurnal',
                          icon: const Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                          onPressed: (_isSaving || _isLoadingOcr)
                              ? null
                              : () => _commit(orgId),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAccountField({
    required String label,
    required OrgAccount? account,
    required String orgId,
    required ValueChanged<OrgAccount?> onPicked,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openAccountPicker(
        orgId: orgId,
        title: label,
        onPicked: onPicked,
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
        ),
        child: account == null
            ? Text(
                'Pilih akun...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Text(
                '${account.code} · ${account.name}',
                style: AppTextStyles.caption,
              ),
      ),
    );
  }

  Future<void> _openAccountPicker({
    required String orgId,
    required String title,
    required ValueChanged<OrgAccount?> onPicked,
  }) async {
    final accounts = await ref
        .read(orgDataSourceProvider)
        .accounts(orgId);
    if (!mounted) return;
    final picked = await pickAccount(
      context,
      accounts: accounts,
      title: title,
    );
    onPicked(picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() {
      _image = file;
      _ocrStatus = null;
    });
    await _runOcr(file.path);
  }

  Future<void> _runOcr(String filePath) async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;

    setState(() {
      _isLoadingOcr = true;
      _ocrStatus = 'pending';
    });
    try {
      final job = await ref
          .read(backendApiServiceProvider)
          .orgSubmitScanOcr(orgId, filePath: filePath);
      _ocrJobId = job['id']?.toString() ?? job['_id']?.toString();
      await _pollOcr();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai OCR: $e')),
      );
      setState(() => _ocrStatus = 'failed');
    } finally {
      if (mounted) setState(() => _isLoadingOcr = false);
    }
  }

  Future<void> _pollOcr() async {
    final jobId = _ocrJobId;
    if (jobId == null || jobId.isEmpty) return;

    for (var i = 0; i < _maxPollAttempts; i++) {
      final job = await ref
          .read(backendApiServiceProvider)
          .orgGetScanOcr(jobId);
      final status = job['status']?.toString() ?? 'pending';
      if (mounted) setState(() => _ocrStatus = status);

      if (status == 'success') {
        _applyOcrResult(job);
        return;
      }
      if (status == 'failed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OCR gagal. Isi form secara manual.')),
          );
        }
        return;
      }
      await Future<void>.delayed(_pollDelay);
      if (!mounted) return;
    }

    if (mounted) {
      setState(() => _ocrStatus = 'failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR timeout. Isi form secara manual.')),
      );
    }
  }

  void _applyOcrResult(Map<String, dynamic> job) {
    final extracted = Map<String, dynamic>.from(
      job['extracted'] as Map? ?? const {},
    );

    // Pick the first transaction if available, fallback to root fields.
    final txList = (extracted['transactions'] as List? ?? const []);
    final tx = txList.isNotEmpty
        ? Map<String, dynamic>.from(txList.first as Map)
        : extracted;

    final merchant = tx['merchant_name']?.toString().trim() ?? '';
    final amount = tx['total_amount'];
    final rawDate = tx['date']?.toString().trim() ?? '';

    if (merchant.isNotEmpty) {
      _descController.text = 'Pembelian di $merchant';
    }
    if (amount != null) {
      _amountController.text =
          double.tryParse(amount.toString())?.toStringAsFixed(0) ?? '0';
    }
    if (rawDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        setState(() => _date = parsed);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _commit(String orgId) async {
    final desc = _descController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong.')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0.')),
      );
      return;
    }
    if (_debitAccount == null || _creditAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun debit dan kredit.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final jobId = _ocrJobId;
      if (jobId != null && jobId.isNotEmpty && _ocrStatus == 'success') {
        await ref.read(backendApiServiceProvider).orgCommitScanOcrToJournal(
          orgId,
          jobId,
          {
            'debit_account_id': _debitAccount!.id,
            'credit_account_id': _creditAccount!.id,
            'amount': amount,
            'date': _date.toIso8601String().substring(0, 10),
            'description': desc,
          },
        );
      } else {
        // No OCR job: create journal directly via journal create endpoint.
        await ref.read(backendApiServiceProvider).orgJournalCreate(
          orgId,
          {
            'date': _date.toIso8601String().substring(0, 10),
            'description': desc,
            'source': 'scan',
            'lines': [
              {
                'account_id': _debitAccount!.id,
                'debit': amount,
                'credit': 0,
              },
              {
                'account_id': _creditAccount!.id,
                'debit': 0,
                'credit': amount,
              },
            ],
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal berhasil dicatat.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Mengirim gambar...';
      case 'processing':
        return 'AI sedang membaca struk...';
      case 'success':
        return 'Berhasil dibaca!';
      case 'failed':
        return 'Gagal.';
      default:
        return 'Memproses...';
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
