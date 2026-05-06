import 'dart:async';
import 'dart:io';

import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/analytics/presentation/view_models/analytics_view_model.dart';
import 'package:confindant/features/home/presentation/view_models/home_view_model.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScanReceiptPage extends ConsumerStatefulWidget {
  const ScanReceiptPage({super.key, this.initialImagePath});

  final String? initialImagePath;

  @override
  ConsumerState<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends ConsumerState<ScanReceiptPage> {
  static const int _maxOcrPollAttempts = 20;
  static const Duration _ocrPollDelay = Duration(seconds: 2);

  final _merchantController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _amountController = TextEditingController(text: '0');
  final _taxAmountController = TextEditingController(text: '0');
  final _serviceAmountController = TextEditingController(text: '0');
  final _notesController = TextEditingController(
    text: 'Uploaded from scan page',
  );
  bool _isSaving = false;
  bool _isLoadingOcr = false;
  String? _ocrJobId;
  String? _ocrStatus;
  double? _ocrConfidence;
  String? _ocrErrorCode;
  String? _ocrErrorMessage;
  bool _ocrPollingTimedOut = false;
  String _type = 'expense';
  String _needWant = 'unknown';
  DateTime _transactionDate = DateTime.now();
  List<Map<String, dynamic>> _ocrItems = const [];
  List<Map<String, dynamic>> _ocrTransactions = const [];
  Set<int> _selectedOcrTransactions = <int>{};
  Map<String, double> _fieldConfidence = const {};
  static const double _lowConfidenceThreshold = 0.65;
  Map<String, dynamic>? _ocrExtractedSnapshot;
  bool get _isManualMode {
    final path = widget.initialImagePath;
    return path == null || path.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (!_isManualMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapOcr());
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _categoryController.dispose();
    _amountController.dispose();
    _taxAmountController.dispose();
    _serviceAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 28),
            child: Column(
              children: [
                AppCardContainer(
                  radius: AppRadius.lg,
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildReceiptPreview(),
                  ),
                ),
                const SizedBox(height: 18),
                if (!_isManualMode && _isLoadingOcr)
                  const LinearProgressIndicator(minHeight: 4),
                if (!_isManualMode && _ocrStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.scanOcrStatusPrefix}: ${_statusLabel(context, _ocrStatus)}'
                    '${_ocrConfidence != null ? ' (${(_ocrConfidence! * 100).toStringAsFixed(0)}%)' : ''}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                  ),
                  if (_ocrStatus == 'failed') ...[
                    const SizedBox(height: 6),
                    Text(
                      _humanizeOcrError(context, _ocrErrorCode, _ocrErrorMessage),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFFE3E3),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _continueManual,
                            child: Text(l10n.scanContinueManual),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isLoadingOcr ? null : _retryOcr,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(l10n.scanRetryOcr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                if (!_isManualMode &&
                    _ocrStatus == 'success' &&
                    _lowConfidenceLabels(l10n).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AppCardContainer(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFC10007), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${l10n.scanLowConfidenceHint} (${_lowConfidenceLabels(l10n).join(', ')})',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF7A1B1B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AppCardContainer(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scanReceiptReview,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 20,
                          height: 28 / 20,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _merchantController,
                        decoration: InputDecoration(
                          labelText: l10n.scanMerchant,
                          suffixIcon: _lowConfidenceIcon('merchant_name'),
                        ),
                      ),
                      if (_isLowConfidence('merchant_name'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        items: [
                          DropdownMenuItem(value: 'expense', child: Text(l10n.scanExpense)),
                          DropdownMenuItem(value: 'income', child: Text(l10n.scanIncome)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _type = value);
                        },
                        decoration: InputDecoration(labelText: l10n.scanType),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: l10n.scanCategory,
                          suffixIcon: _lowConfidenceIcon('category'),
                        ),
                      ),
                      if (_isLowConfidence('category'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.scanTotalAmount,
                          suffixIcon: _lowConfidenceIcon('total_amount'),
                        ),
                      ),
                      if (_isLowConfidence('total_amount'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _taxAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.scanTaxAmount,
                          suffixIcon: _lowConfidenceIcon('tax_amount'),
                        ),
                      ),
                      if (_isLowConfidence('tax_amount'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _serviceAmountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.scanServiceAmount,
                          suffixIcon: _lowConfidenceIcon('service_amount'),
                        ),
                      ),
                      if (_isLowConfidence('service_amount'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<String>(
                        initialValue: _needWant,
                        items: [
                          DropdownMenuItem(
                            value: 'needs',
                            child: Text(l10n.scanNeedTypeNeeds),
                          ),
                          DropdownMenuItem(
                            value: 'wants',
                            child: Text(l10n.scanNeedTypeWants),
                          ),
                          DropdownMenuItem(
                            value: 'mixed',
                            child: Text(l10n.scanNeedTypeMixed),
                          ),
                          DropdownMenuItem(
                            value: 'unknown',
                            child: Text(l10n.scanNeedTypeUnknown),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _needWant = value);
                        },
                        decoration: InputDecoration(
                          labelText: l10n.scanNeedType,
                          suffixIcon: _lowConfidenceIcon('need_want'),
                        ),
                      ),
                      if (_isLowConfidence('need_want'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.scanDate,
                            suffixIcon: _isLowConfidence('date')
                                ? const Icon(Icons.warning_amber_rounded, color: Color(0xFFC10007), size: 18)
                                : const Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(_formatDate(_transactionDate)),
                        ),
                      ),
                      if (_isLowConfidence('date'))
                        _buildFieldHint(l10n),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(labelText: l10n.scanNotes),
                      ),
                      if (_ocrItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.scanItemsFound(_ocrItems.length),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 160),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _ocrItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _ocrItems[index];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  item['name']?.toString().isNotEmpty == true
                                      ? item['name'].toString()
                                      : '-',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item['qty'] ?? 0} x ${item['price'] ?? 0}',
                                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                                ),
                                trailing: Text(
                                  '${item['subtotal'] ?? 0}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (_ocrTransactions.length > 1) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.scanDetectedTransactions(_ocrTransactions.length),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _ocrTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _ocrTransactions[index];
                              final selected = _selectedOcrTransactions.contains(index);
                              return CheckboxListTile(
                                value: selected,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: Text(
                                  tx['merchant_name']?.toString().isNotEmpty == true
                                      ? tx['merchant_name'].toString()
                                      : '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '${tx['date_label'] ?? '-'} • ${tx['category'] ?? 'General'}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                secondary: Text(
                                  '${tx['type'] == 'income' ? '+' : '-'} ${tx['amount_label'] ?? tx['total_amount'] ?? 0}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: tx['type'] == 'income'
                                        ? const Color(0xFF0A7A34)
                                        : const Color(0xFFC10007),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedOcrTransactions.add(index);
                                    } else {
                                      _selectedOcrTransactions.remove(index);
                                    }
                                    if (_selectedOcrTransactions.length == 1) {
                                      _applyOcrTransactionToForm(
                                        _selectedOcrTransactions.first,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedOcrTransactions = {
                                    for (var i = 0; i < _ocrTransactions.length; i++) i,
                                  };
                                  _applyOcrTransactionToForm(
                                    _selectedOcrTransactions.first,
                                  );
                                });
                              },
                              child: Text(l10n.scanSelectAll),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedOcrTransactions = <int>{0};
                                  _applyOcrTransactionToForm(0);
                                });
                              },
                              child: Text(l10n.scanUseFirstOnly),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: l10n.cancel,
                              backgroundColor: const Color(0xFFE5E7EB),
                              foregroundColor: const Color(0xFF364153),
                              onPressed: context.pop,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppPrimaryButton(
                              label: _isSaving ? l10n.processing : l10n.save,
                              icon: const Icon(
                                Icons.check_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                              onPressed: _isSaving ? null : () => _saveReceipt(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final path = widget.initialImagePath;
    if (path != null && path.isNotEmpty) {
      return Image.file(File(path), height: 280, width: 310, fit: BoxFit.cover);
    }
    return Container(
      height: 280,
      width: 310,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2472),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              AppLocalizations.of(context)!.scanManualEntry,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.description_outlined, size: 48, color: Color(0xFF0A2472)),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.scanNoReceiptImage,
            style: AppTextStyles.label.copyWith(
              color: const Color(0xFF0A2472),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bootstrapOcr() async {
    final imagePath = widget.initialImagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    setState(() => _isLoadingOcr = true);
    try {
      setState(() {
        _ocrStatus = 'pending';
        _ocrErrorCode = null;
        _ocrErrorMessage = null;
        _ocrPollingTimedOut = false;
      });
      final job = await ref
          .read(backendApiServiceProvider)
          .submitScanOcr(filePath: imagePath);
      _ocrJobId = job['id']?.toString() ?? job['_id']?.toString();
      await _pollOcrResult();
    } catch (e) {
      if (!mounted) return;
      final message = _extractApiErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.scanFailedStartOcr}'
            '${message.isEmpty ? '' : ' ($message)'}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingOcr = false);
      }
    }
  }

  Future<void> _pollOcrResult() async {
    final jobId = _ocrJobId;
    if (jobId == null || jobId.isEmpty) return;

    for (var i = 0; i < _maxOcrPollAttempts; i++) {
      final job = await ref.read(backendApiServiceProvider).getScanOcr(jobId);
      final status = job['status']?.toString() ?? 'pending';
      final errorCode = job['error_code']?.toString();
      final errorMessage = job['error_message']?.toString();
      setState(() {
        _ocrStatus = status;
        _ocrConfidence = double.tryParse('${job['confidence'] ?? ''}');
        _ocrErrorCode = errorCode;
        _ocrErrorMessage = errorMessage;
        _ocrPollingTimedOut = false;
      });

      if (status == 'success') {
        final extracted = Map<String, dynamic>.from(
          job['extracted'] as Map? ?? const {},
        );
        final extractedTransactions = (extracted['transactions'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (mounted) {
          setState(() {
            _ocrTransactions = extractedTransactions;
            if (_ocrTransactions.isEmpty) {
              _ocrTransactions = [
                {
                  'merchant_name': extracted['merchant_name']?.toString() ?? '',
                  'date': extracted['date']?.toString(),
                  'total_amount': extracted['total_amount'] ?? 0,
                  'category': extracted['category']?.toString() ?? 'General',
                  'type': extracted['type']?.toString() == 'income' ? 'income' : 'expense',
                  'notes': '',
                },
              ];
            }
            _selectedOcrTransactions = {
              for (var index = 0; index < _ocrTransactions.length; index++) index,
            };
            _applyOcrTransactionToForm(0, extracted: extracted);
            _ocrExtractedSnapshot = {
              'merchant_name': _merchantController.text.trim(),
              'category': _categoryController.text.trim(),
              'total_amount': _parseAmount(_amountController.text),
              'tax_amount': _parseAmount(_taxAmountController.text),
              'service_amount': _parseAmount(_serviceAmountController.text),
              'need_want': _needWant,
              'type': _type,
              'date': _transactionDate.toIso8601String(),
              'items': _ocrItems,
            };
            _fieldConfidence = _parseFieldConfidence(
              extracted['field_confidence'],
              _ocrConfidence ?? 0.72,
            );
          });
        }
        return;
      }

      if (status == 'failed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _humanizeOcrError(context, errorCode, errorMessage),
              ),
            ),
          );
        }
        return;
      }

      await Future<void>.delayed(_ocrPollDelay);
      if (!mounted) return;
    }

    if (!mounted) return;
    setState(() {
      _ocrStatus = 'failed';
      _ocrErrorCode = 'timeout';
      _ocrErrorMessage = null;
      _ocrPollingTimedOut = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.scanOcrTimeout)),
    );
  }

  Future<void> _saveReceipt(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final walletState = ref.read(walletViewModelProvider);
    final walletId = walletState.wallets.isNotEmpty
        ? (walletState.wallets.first['id']?.toString() ??
              walletState.wallets.first['_id']?.toString() ??
              '')
        : '';

    if (walletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homePleaseCreateWalletFirst)),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    final taxAmount = _parseAmount(_taxAmountController.text);
    final serviceAmount = _parseAmount(_serviceAmountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanInvalidAmount)),
      );
      return;
    }
    if (_ocrTransactions.length > 1 && _selectedOcrTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanSelectAtLeastOneTransaction)),
      );
      return;
    }

    final payload = {
      'wallet_id': walletId,
      'type': _type,
      'category': _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      'total_amount': amount,
      'tax_amount': taxAmount,
      'service_amount': serviceAmount,
      'need_want': _needWant,
      'date': _transactionDate.toIso8601String(),
      'merchant_name': _merchantController.text.trim(),
      'notes': _notesController.text.trim(),
      'is_verified': true,
      'items': _ocrItems,
    };

    setState(() => _isSaving = true);
    try {
      Map<String, dynamic>? savedTransaction;
      String sourceMode = 'manual';
      if (_isManualMode) {
        savedTransaction = await ref.read(backendApiServiceProvider).createTransaction(payload);
      } else {
        final jobId = _ocrJobId;
        if (jobId != null && jobId.isNotEmpty && _ocrStatus == 'success') {
          if (_ocrTransactions.length > 1 && _selectedOcrTransactions.length > 1) {
            final bulkPayload = {
              ...payload,
              'transactions': _selectedOcrTransactions
                  .map((index) => _buildPayloadFromOcrTransaction(index, walletId))
                  .toList(),
            };
            savedTransaction = await ref
                .read(backendApiServiceProvider)
                .commitScanOcr(jobId, bulkPayload);
          } else {
            savedTransaction = await ref
                .read(backendApiServiceProvider)
                .commitScanOcr(jobId, payload);
          }
          sourceMode = 'ocr_commit';
        } else {
          savedTransaction = await ref.read(backendApiServiceProvider).uploadReceipt(
                filePath: widget.initialImagePath,
                fields: payload,
              );
          sourceMode = 'ocr_upload_fallback';
        }

        if (jobId != null && jobId.isNotEmpty) {
          await _submitOcrFeedback(
            jobId: jobId,
            payload: payload,
            savedTransaction: savedTransaction,
            sourceMode: sourceMode,
          );
        }
      }
      await ref.read(walletViewModelProvider.notifier).load();
      await ref.read(homeViewModelProvider.notifier).load();
      ref.read(analyticsViewModelProvider.notifier).retry();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isManualMode
                ? l10n.scanManualSaved
                : l10n.scanReceiptSaved,
          ),
        ),
      );
      if (Navigator.of(context).canPop()) {
        context.pop();
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scanFailedSaveReceipt)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _humanizeOcrError(
    BuildContext context,
    String? errorCode,
    String? fallbackMessage,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (errorCode) {
      case 'quota_exhausted':
        return l10n.scanOcrQuotaExceeded;
      case 'auth_failed':
        return l10n.scanOcrAuthFailed;
      case 'timeout':
        return l10n.scanOcrTimeout;
      case 'invalid_response':
        return l10n.scanOcrInvalidResponse;
      case 'provider_error':
        return l10n.scanOcrProviderError;
      default:
        if (_ocrPollingTimedOut) {
          return l10n.scanOcrTimeout;
        }
        return fallbackMessage?.trim().isNotEmpty == true
            ? fallbackMessage!.trim()
            : l10n.scanOcrFailedGeneric;
    }
  }

  String _statusLabel(BuildContext context, String? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.scanOcrStatusPending;
      case 'processing':
        return l10n.scanOcrStatusProcessing;
      case 'success':
        return l10n.scanOcrStatusSuccess;
      case 'failed':
        return l10n.scanOcrStatusFailed;
      default:
        return status ?? l10n.scanOcrStatusPending;
    }
  }

  Map<String, double> _parseFieldConfidence(dynamic raw, double overall) {
    final fallback = overall <= 0 ? 0.72 : overall;
    final source = raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};
    final keys = ['merchant_name', 'date', 'total_amount', 'tax_amount', 'service_amount', 'need_want', 'category'];
    return {
      for (final key in keys)
        key: _clampConfidence(double.tryParse('${source[key] ?? fallback}') ?? fallback),
    };
  }

  double _clampConfidence(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  bool _isLowConfidence(String fieldKey) =>
      (_fieldConfidence[fieldKey] ?? 1) < _lowConfidenceThreshold;

  Widget? _lowConfidenceIcon(String fieldKey) {
    if (!_isLowConfidence(fieldKey)) return null;
    return const Icon(Icons.warning_amber_rounded, color: Color(0xFFC10007), size: 18);
  }

  Widget _buildFieldHint(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        l10n.scanLowConfidenceHint,
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF7A1B1B),
          fontSize: 11,
        ),
      ),
    );
  }

  List<String> _lowConfidenceLabels(AppLocalizations l10n) {
    final labels = <String>[];
    if (_isLowConfidence('merchant_name')) labels.add(l10n.scanMerchant);
    if (_isLowConfidence('total_amount')) labels.add(l10n.scanTotalAmount);
    if (_isLowConfidence('tax_amount')) labels.add(l10n.scanTaxAmount);
    if (_isLowConfidence('service_amount')) labels.add(l10n.scanServiceAmount);
    if (_isLowConfidence('need_want')) labels.add(l10n.scanNeedType);
    if (_isLowConfidence('category')) labels.add(l10n.scanCategory);
    if (_isLowConfidence('date')) labels.add(l10n.scanDate);
    return labels;
  }

  void _continueManual() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.scanManualModeHint)),
    );
  }

  Future<void> _retryOcr() async {
    if (_isLoadingOcr || _isManualMode) return;
    await _bootstrapOcr();
  }

  double _parseAmount(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _submitOcrFeedback({
    required String jobId,
    required Map<String, dynamic> payload,
    required Map<String, dynamic>? savedTransaction,
    required String sourceMode,
  }) async {
    final snapshot = _ocrExtractedSnapshot ?? const <String, dynamic>{};
    final changed = <String>[];

    bool changedText(String key) =>
        (snapshot[key]?.toString().trim() ?? '') !=
        ((payload[key]?.toString().trim()) ?? '');

    if (changedText('merchant_name')) changed.add('merchant_name');
    if (changedText('category')) changed.add('category');
    if (changedText('type')) changed.add('type');

    final snapshotAmount = double.tryParse('${snapshot['total_amount'] ?? 0}') ?? 0;
    final payloadAmount = double.tryParse('${payload['total_amount'] ?? 0}') ?? 0;
    if ((snapshotAmount - payloadAmount).abs() > 0.01) {
      changed.add('total_amount');
    }
    final snapshotTax = double.tryParse('${snapshot['tax_amount'] ?? 0}') ?? 0;
    final payloadTax = double.tryParse('${payload['tax_amount'] ?? 0}') ?? 0;
    if ((snapshotTax - payloadTax).abs() > 0.01) {
      changed.add('tax_amount');
    }
    final snapshotService = double.tryParse('${snapshot['service_amount'] ?? 0}') ?? 0;
    final payloadService = double.tryParse('${payload['service_amount'] ?? 0}') ?? 0;
    if ((snapshotService - payloadService).abs() > 0.01) {
      changed.add('service_amount');
    }
    if ((snapshot['need_want']?.toString() ?? 'unknown') != (payload['need_want']?.toString() ?? 'unknown')) {
      changed.add('need_want');
    }

    final snapshotDate = DateTime.tryParse(snapshot['date']?.toString() ?? '');
    final payloadDate = DateTime.tryParse(payload['date']?.toString() ?? '');
    final snapshotDay = snapshotDate == null
        ? ''
        : '${snapshotDate.year}-${snapshotDate.month}-${snapshotDate.day}';
    final payloadDay = payloadDate == null
        ? ''
        : '${payloadDate.year}-${payloadDate.month}-${payloadDate.day}';
    if (snapshotDay != payloadDay) {
      changed.add('date');
    }

    await ref.read(backendApiServiceProvider).submitScanOcrFeedback(jobId, {
      'transaction_id': savedTransaction?['id']?.toString(),
      'accepted': changed.isEmpty,
      'source_mode': sourceMode,
      'changed_fields': changed,
      'edited_field_count': changed.length,
      'field_confidence': _fieldConfidence,
      'meta': {
        'ocr_status': _ocrStatus,
        'ocr_confidence': _ocrConfidence,
      },
      'created_at_client': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _transactionDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _transactionDate.hour,
        _transactionDate.minute,
      );
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  void _applyOcrTransactionToForm(
    int index, {
    Map<String, dynamic>? extracted,
  }) {
    if (index < 0 || index >= _ocrTransactions.length) return;
    final tx = _ocrTransactions[index];
    _merchantController.text = tx['merchant_name']?.toString() ?? '';
    _categoryController.text = tx['category']?.toString().isNotEmpty == true
        ? tx['category'].toString()
        : 'General';
    _amountController.text = '${tx['total_amount'] ?? 0}';
    if (extracted != null) {
      _taxAmountController.text = '${extracted['tax_amount'] ?? 0}';
      _serviceAmountController.text = '${extracted['service_amount'] ?? 0}';
      final rawNeedWant = extracted['need_want']?.toString().trim().toLowerCase() ?? 'unknown';
      _needWant = ['needs', 'wants', 'mixed', 'unknown'].contains(rawNeedWant)
          ? rawNeedWant
          : 'unknown';
      _ocrItems = (extracted['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else {
      _taxAmountController.text = '0';
      _serviceAmountController.text = '0';
      _needWant = 'unknown';
      _ocrItems = const [];
    }

    _type = tx['type']?.toString() == 'income' ? 'income' : 'expense';
    _notesController.text = tx['notes']?.toString().isNotEmpty == true
        ? tx['notes'].toString()
        : _notesController.text;
    _transactionDate = DateTime.tryParse(tx['date']?.toString() ?? '') ?? DateTime.now();

    for (var i = 0; i < _ocrTransactions.length; i++) {
      final item = _ocrTransactions[i];
      final dt = DateTime.tryParse(item['date']?.toString() ?? '');
      item['date_label'] = dt == null ? '-' : _formatDate(dt);
      item['amount_label'] = item['total_amount']?.toString() ?? '0';
    }
  }

  Map<String, dynamic> _buildPayloadFromOcrTransaction(int index, String walletId) {
    final tx = _ocrTransactions[index];
    final type = tx['type']?.toString() == 'income' ? 'income' : 'expense';
    final amount = double.tryParse('${tx['total_amount'] ?? 0}') ?? 0;
    return {
      'wallet_id': walletId,
      'type': type,
      'category': tx['category']?.toString().isNotEmpty == true ? tx['category'] : 'General',
      'total_amount': amount,
      'tax_amount': 0,
      'service_amount': 0,
      'need_want': 'unknown',
      'date': DateTime.tryParse(tx['date']?.toString() ?? '')?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'merchant_name': tx['merchant_name']?.toString() ?? '',
      'notes': tx['notes']?.toString() ?? '',
      'is_verified': true,
      'items': const [],
    };
  }

  String _extractApiErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return '';

    final marker = 'message:';
    final markerIndex = raw.indexOf(marker);
    if (markerIndex >= 0) {
      final start = markerIndex + marker.length;
      final end = raw.indexOf(')', start);
      final picked = (end > start ? raw.substring(start, end) : raw.substring(start)).trim();
      if (picked.isNotEmpty) return picked;
    }

    return raw;
  }
}
