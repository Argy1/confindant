import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class TransactionFormResult {
  const TransactionFormResult({
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    required this.source,
    required this.merchantName,
    required this.notes,
    required this.tags,
    required this.date,
    required this.isVerified,
    this.aiSuggestedCategory,
    this.aiConfidence,
    this.aiProvider,
    this.aiInputContext,
  });

  final String walletId;
  final String type;
  final double amount;
  final String category;
  final String source;
  final String merchantName;
  final String notes;
  final List<String> tags;
  final DateTime date;
  final bool isVerified;
  final String? aiSuggestedCategory;
  final double? aiConfidence;
  final String? aiProvider;
  final Map<String, dynamic>? aiInputContext;
}

Future<TransactionFormResult?> showTransactionFormDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> wallets,
  required bool defaultIncome,
  TransactionFormResult? initial,
  String? lockedType,
  bool aiCategorizationEnabled = true,
  Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)? onAiSuggestCategory,
  Future<Map<String, dynamic>> Function(String transcript, String locale)?
      onAiParseVoiceTransaction,
}) async {
  if (wallets.isEmpty) return null;
  return showDialog<TransactionFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _TransactionFormDialog(
      wallets: wallets,
      defaultIncome: defaultIncome,
      initial: initial,
      lockedType: lockedType,
      aiCategorizationEnabled: aiCategorizationEnabled,
      onAiSuggestCategory: onAiSuggestCategory,
      onAiParseVoiceTransaction: onAiParseVoiceTransaction,
    ),
  );
}

class _TransactionFormDialog extends StatefulWidget {
  const _TransactionFormDialog({
    required this.wallets,
    required this.defaultIncome,
    this.initial,
    this.lockedType,
    required this.aiCategorizationEnabled,
    this.onAiSuggestCategory,
    this.onAiParseVoiceTransaction,
  });

  final List<Map<String, dynamic>> wallets;
  final bool defaultIncome;
  final TransactionFormResult? initial;
  final String? lockedType;
  final bool aiCategorizationEnabled;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
      onAiSuggestCategory;
  final Future<Map<String, dynamic>> Function(String transcript, String locale)?
      onAiParseVoiceTransaction;

  @override
  State<_TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<_TransactionFormDialog> {
  late String _walletId;
  late String _type;
  late bool _isVerified;
  late DateTime _selectedDate;

  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _sourceController;
  late final TextEditingController _merchantController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  final SpeechToText _speech = SpeechToText();
  Timer? _aiDebounce;
  bool _isApplyingAiCategory = false;
  bool _isSuggestingCategory = false;
  bool _isListeningVoice = false;
  bool _isParsingVoice = false;
  String _voiceTranscript = '';
  bool _categoryEditedByUser = false;
  String? _aiSuggestedCategory;
  double? _aiConfidence;
  String? _aiProvider;

  bool get _typeLocked => widget.lockedType == 'income' || widget.lockedType == 'expense';

  @override
  void initState() {
    super.initState();
    _walletId = _resolveWalletId();
    _type =
        widget.lockedType ?? widget.initial?.type ?? (widget.defaultIncome ? 'income' : 'expense');
    _isVerified = widget.initial?.isVerified ?? true;
    _selectedDate = widget.initial?.date ?? DateTime.now();

    _amountController = TextEditingController(
      text: widget.initial == null ? '' : widget.initial!.amount.toStringAsFixed(0),
    );
    _categoryController = TextEditingController(
      text: widget.initial?.category ?? (widget.defaultIncome ? 'Salary' : 'General Expense'),
    );
    _sourceController = TextEditingController(
      text: widget.initial?.source ?? (widget.defaultIncome ? 'Salary' : ''),
    );
    _merchantController = TextEditingController(
      text: widget.initial?.merchantName ??
          (widget.defaultIncome ? 'Income Entry' : 'Expense Entry'),
    );
    _notesController = TextEditingController(
      text: widget.initial?.notes ?? 'Created from app form',
    );
    _tagsController = TextEditingController(
      text: (widget.initial?.tags ?? const <String>[]).join(', '),
    );
    _categoryController.addListener(_handleCategoryEdited);
    _merchantController.addListener(_triggerAiSuggestDebounced);
    _sourceController.addListener(_triggerAiSuggestDebounced);
    _notesController.addListener(_triggerAiSuggestDebounced);

    if (widget.aiCategorizationEnabled) {
      _triggerAiSuggestDebounced();
    }
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _speech.stop();
    _categoryController.removeListener(_handleCategoryEdited);
    _merchantController.removeListener(_triggerAiSuggestDebounced);
    _sourceController.removeListener(_triggerAiSuggestDebounced);
    _notesController.removeListener(_triggerAiSuggestDebounced);
    _amountController.dispose();
    _categoryController.dispose();
    _sourceController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _resolveWalletId() {
    final initialWallet = widget.initial?.walletId;
    if (initialWallet != null && initialWallet.isNotEmpty) {
      final exists = widget.wallets.any((wallet) {
        final id = wallet['id']?.toString() ?? wallet['_id']?.toString() ?? '';
        return id == initialWallet;
      });
      if (exists) return initialWallet;
    }

    return widget.wallets.first['id']?.toString() ??
        widget.wallets.first['_id']?.toString() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        _type == 'income' ? l10n.transactionFormAddIncome : l10n.transactionFormAddExpense,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.onAiParseVoiceTransaction != null)
                OutlinedButton.icon(
                  onPressed: _isParsingVoice ? null : _toggleVoiceInput,
                  icon: Icon(
                    _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                  ),
                  label: Text(
                    _isParsingVoice
                        ? l10n.processing
                        : (_isListeningVoice
                              ? l10n.transactionFormListening
                              : l10n.transactionFormVoiceInput),
                  ),
                ),
              if (widget.onAiParseVoiceTransaction != null) const SizedBox(height: 12),
              if (_voiceTranscript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _voiceTranscript,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: InputDecoration(labelText: l10n.transactionFormWallet),
                items: widget.wallets.map((wallet) {
                  final id = wallet['id']?.toString() ?? wallet['_id']?.toString() ?? '';
                  final name = wallet['wallet_name']?.toString() ?? 'Wallet';
                  return DropdownMenuItem<String>(value: id, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _walletId = value);
                },
              ),
              const SizedBox(height: 14),
              if (_typeLocked)
                TextFormField(
                  initialValue: _type == 'income' ? 'Income' : 'Expense',
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(labelText: l10n.transactionFormType),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: InputDecoration(labelText: l10n.transactionFormType),
                  items: [
                    DropdownMenuItem(value: 'income', child: Text(l10n.scanIncome)),
                    DropdownMenuItem(value: 'expense', child: Text(l10n.scanExpense)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                      if (_type == 'income' && _sourceController.text.trim().isEmpty) {
                        _sourceController.text = 'Salary';
                      }
                    });
                    _triggerAiSuggestDebounced();
                  },
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.transactionFormAmount),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: l10n.scanCategory),
              ),
              if (_isSuggestingCategory)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (_aiSuggestedCategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'AI suggestion: $_aiSuggestedCategory'
                    '${_aiConfidence == null ? '' : ' (${(_aiConfidence! * 100).toStringAsFixed(0)}%)'}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _sourceController,
                decoration: InputDecoration(labelText: l10n.transactionFormSource),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _merchantController,
                decoration: InputDecoration(labelText: l10n.transactionFormMerchantRef),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: l10n.scanNotes),
                minLines: 2,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(labelText: l10n.transactionFormTags),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(l10n.transactionFormVerified),
                  const Spacer(),
                  Switch(
                    value: _isVerified,
                    onChanged: (value) => setState(() => _isVerified = value),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(l10n.transactionFormDate),
                  const Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _selectedDate,
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _toggleVoiceInput() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isListeningVoice) {
      await _speech.stop();
      await HapticFeedback.selectionClick();
      if (!mounted) return;
      setState(() => _isListeningVoice = false);
      await _parseVoiceTranscriptIfAny();
      return;
    }

    final micGranted = await _ensureMicrophonePermission(l10n);
    if (!micGranted || !mounted) return;

    final available = await _speech.initialize(
      onError: _onVoiceError,
      onStatus: (status) async {
        if (!mounted) return;
        if (status == 'notListening' && _isListeningVoice) {
          await HapticFeedback.selectionClick();
          setState(() => _isListeningVoice = false);
          await _parseVoiceTranscriptIfAny();
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceUnavailable)),
      );
      return;
    }

    final locale = Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'id_ID';
    _voiceTranscript = '';
    await _speech.listen(
      localeId: locale,
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (!mounted) return;
        setState(() => _voiceTranscript = result.recognizedWords.trim());
      },
    );
    if (!mounted) return;
    setState(() => _isListeningVoice = true);
    await HapticFeedback.lightImpact();
  }

  Future<bool> _ensureMicrophonePermission(AppLocalizations l10n) async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;

    status = await Permission.microphone.request();
    if (status.isGranted) return true;

    final message = status.isPermanentlyDenied
        ? l10n.transactionFormVoicePermissionDenied
        : l10n.transactionFormVoiceUnavailable;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  void _onVoiceError(SpeechRecognitionError error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isListeningVoice = false);
    final message = error.permanent
        ? l10n.transactionFormVoicePermissionDenied
        : l10n.transactionFormVoiceUnavailable;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _parseVoiceTranscriptIfAny() async {
    final callback = widget.onAiParseVoiceTransaction;
    if (callback == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final transcript = _voiceTranscript.trim();
    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceNoSpeech)),
      );
      return;
    }

    setState(() => _isParsingVoice = true);
    try {
      final locale = Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'id';
      final parsed = await callback(transcript, locale);
      if (!mounted) return;
      final parsedType = parsed['type']?.toString();
      final parsedAmount = double.tryParse(parsed['amount']?.toString() ?? '');
      final parsedCategory = parsed['category']?.toString().trim() ?? '';
      final parsedSource = parsed['source']?.toString().trim() ?? '';
      final parsedMerchant = parsed['merchant_name']?.toString().trim() ?? '';
      final parsedNotes = parsed['notes']?.toString().trim() ?? '';
      final parsedDate = DateTime.tryParse(parsed['date']?.toString() ?? '');

      setState(() {
        if (!_typeLocked && (parsedType == 'income' || parsedType == 'expense')) {
          _type = parsedType!;
        }
        if (parsedAmount != null && parsedAmount > 0) {
          _amountController.text = parsedAmount.toStringAsFixed(0);
        }
        if (parsedCategory.isNotEmpty) {
          _isApplyingAiCategory = true;
          _categoryController.text = parsedCategory;
          _categoryEditedByUser = false;
          _isApplyingAiCategory = false;
        }
        if (parsedSource.isNotEmpty) {
          _sourceController.text = parsedSource;
        }
        if (parsedMerchant.isNotEmpty) {
          _merchantController.text = parsedMerchant;
        }
        if (parsedNotes.isNotEmpty) {
          _notesController.text = parsedNotes;
        }
        if (parsedDate != null) {
          _selectedDate = parsedDate;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceApplySuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormVoiceParseFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isParsingVoice = false);
      }
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.trim());
    if (_walletId.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transactionFormInvalidInput)),
      );
      return;
    }

    final finalCategory = _categoryController.text.trim().isEmpty
        ? (_type == 'income' ? 'Salary' : 'General Expense')
        : _categoryController.text.trim();
    final result = TransactionFormResult(
      walletId: _walletId,
      type: _type,
      amount: amount,
      category: finalCategory,
      source: _sourceController.text.trim().isEmpty
          ? (_type == 'income' ? 'Other' : '')
          : _sourceController.text.trim(),
      merchantName: _merchantController.text.trim(),
      notes: _notesController.text.trim(),
      tags: _parseTags(_tagsController.text),
      date: _selectedDate,
      isVerified: _isVerified,
      aiSuggestedCategory: _aiSuggestedCategory,
      aiConfidence: _aiConfidence,
      aiProvider: _aiProvider,
      aiInputContext: {
        'type': _type,
        'merchant_name': _merchantController.text.trim(),
        'source': _sourceController.text.trim(),
        'notes': _notesController.text.trim(),
        'total_amount': amount,
      },
    );

    Navigator.of(context).pop(result);
  }

  List<String> _parseTags(String input) {
    return input
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  void _handleCategoryEdited() {
    if (_isApplyingAiCategory) return;
    _categoryEditedByUser = true;
  }

  void _triggerAiSuggestDebounced() {
    if (!widget.aiCategorizationEnabled || widget.onAiSuggestCategory == null) {
      return;
    }
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 450), _suggestCategoryByAi);
  }

  Future<void> _suggestCategoryByAi() async {
    final suggest = widget.onAiSuggestCategory;
    if (suggest == null || !mounted) return;

    final merchant = _merchantController.text.trim();
    final source = _sourceController.text.trim();
    final notes = _notesController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (merchant.isEmpty && source.isEmpty && notes.isEmpty) {
      return;
    }

    setState(() => _isSuggestingCategory = true);
    try {
      final response = await suggest({
        'type': _type,
        'merchant_name': merchant,
        'source': source,
        'notes': notes,
        'total_amount': amount,
      });
      final category = response['category']?.toString().trim() ?? '';
      final confidence = double.tryParse(response['confidence']?.toString() ?? '');
      final provider = response['provider']?.toString();
      if (!mounted || category.isEmpty) return;

      setState(() {
        _aiSuggestedCategory = category;
        _aiConfidence = confidence;
        _aiProvider = provider;
        if (!_categoryEditedByUser || _categoryController.text.trim().isEmpty) {
          _isApplyingAiCategory = true;
          _categoryController.text = category;
          _categoryController.selection = TextSelection.collapsed(
            offset: category.length,
          );
          _isApplyingAiCategory = false;
        }
      });
    } catch (_) {
      // Silent fallback to manual entry.
    } finally {
      if (mounted) {
        setState(() => _isSuggestingCategory = false);
      }
    }
  }
}
