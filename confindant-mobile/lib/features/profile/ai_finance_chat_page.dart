import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/profile/presentation/widgets/profile_detail_scaffold.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiFinanceChatPage extends ConsumerStatefulWidget {
  const AiFinanceChatPage({super.key});

  @override
  ConsumerState<AiFinanceChatPage> createState() => _AiFinanceChatPageState();
}

class _AiFinanceChatPageState extends ConsumerState<AiFinanceChatPage> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final Map<String, List<_ChatMessage>> _pendingDeletedMessages = {};
  final Map<String, int> _pendingDeleteTokens = {};
  int _deleteTokenCounter = 0;
  bool _sending = false;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileDetailScaffold(
      title: l10n.aiChatTitle,
      subtitle: l10n.aiChatSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardContainer(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickAskChip(l10n.aiChatQuickAsk1),
                _quickAskChip(l10n.aiChatQuickAsk2),
                _quickAskChip(l10n.aiChatQuickAsk3),
                _quickAskChip(l10n.aiChatClearHistory, onPressed: _sending || _loadingHistory ? null : _clearHistory),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCardContainer(
            child: _loadingHistory
                ? Text(
                    l10n.aiChatHistoryLoading,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  )
                : _messages.isEmpty
                ? Text(
                    l10n.aiChatEmpty,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  )
                : Column(
                    children: [
                      for (final message in _messages) ...[
                        _MessageBubble(
                          message: message,
                          onRename: message.historyId != null && message.role == _ChatRole.assistant
                              ? () => _renameHistoryItem(message.historyId!)
                              : null,
                          onDelete: message.historyId != null && message.role == _ChatRole.assistant
                              ? () => _deleteHistoryItem(message.historyId!)
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCardContainer(
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.aiChatInputHint,
                  ),
                  onSubmitted: (_) => _send(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: l10n.aiChatClear,
                        onPressed: _sending
                            ? null
                            : () => setState(() {
                                  _messages.clear();
                                }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppPrimaryButton(
                        label: _sending ? l10n.processing : l10n.aiChatAsk,
                        icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 18),
                        onPressed: _sending ? null : _send,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAskChip(String text, {VoidCallback? onPressed}) {
    return ActionChip(
      label: Text(text),
      onPressed: onPressed ??
          (_sending
              ? null
              : () {
                  _controller.text = text;
                  _send();
                }),
    );
  }

  Future<void> _loadHistory() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _loadingHistory = true);
    try {
      final items = await ref.read(backendApiServiceProvider).aiFinanceQueryHistory(limit: 20);
      if (!mounted) return;
      final next = <_ChatMessage>[];
      for (final entry in items.reversed) {
        final query = entry['query']?.toString().trim() ?? '';
        final answer = entry['answer']?.toString().trim() ?? '';
        final insight = entry['insight']?.toString().trim() ?? '';
        final actions = (entry['suggested_actions'] as List? ?? const [])
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(3)
            .toList();

        if (query.isNotEmpty) {
          final historyId = entry['id']?.toString().trim();
          next.add(_ChatMessage(role: _ChatRole.user, text: query, historyId: historyId));
        }
        if (answer.isNotEmpty || insight.isNotEmpty || actions.isNotEmpty) {
          final buffer = StringBuffer();
          if (answer.isNotEmpty) {
            buffer.writeln(answer);
          }
          if (insight.isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            buffer.writeln('${l10n.aiChatInsightPrefix}: $insight');
          }
          if (actions.isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            for (var i = 0; i < actions.length; i++) {
              buffer.writeln('${i + 1}. ${actions[i]}');
            }
          }
          final historyId = entry['id']?.toString().trim();
          next.add(_ChatMessage(role: _ChatRole.assistant, text: buffer.toString().trim(), historyId: historyId));
        }
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(next);
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      await ref.read(backendApiServiceProvider).clearAiFinanceQueryHistory();
      if (!mounted) return;
      setState(() {
        _messages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatHistoryClearSuccess)),
      );
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: _ChatRole.user, text: query));
      _controller.clear();
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final data = await ref.read(backendApiServiceProvider).aiFinanceQuery(
            query: query,
            locale: locale == 'en' ? 'en' : 'id',
          );
      final historyId = data['history_id']?.toString().trim();
      if (historyId != null && historyId.isNotEmpty) {
        final latestUserIndex = _messages.lastIndexWhere(
          (m) => m.role == _ChatRole.user && m.historyId == null,
        );
        if (latestUserIndex != -1) {
          _messages[latestUserIndex] = _messages[latestUserIndex].copyWith(historyId: historyId);
        }
      }
      final answer = data['answer']?.toString().trim() ?? '';
      final insight = data['insight']?.toString().trim() ?? '';
      final actions = (data['suggested_actions'] as List? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();

      final buffer = StringBuffer();
      buffer.writeln(answer.isEmpty ? l10n.aiChatNoAnswer : answer);
      if (insight.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('${l10n.aiChatInsightPrefix}: $insight');
      }
      if (actions.isNotEmpty) {
        buffer.writeln();
        for (var i = 0; i < actions.length; i++) {
          buffer.writeln('${i + 1}. ${actions[i]}');
        }
      }

      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: buffer.toString().trim(),
            historyId: (historyId != null && historyId.isNotEmpty) ? historyId : null,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.assistant,
            text: '${l10n.aiChatError}\n\nDetail: $e',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _renameHistoryItem(String historyId) async {
    final l10n = AppLocalizations.of(context)!;
    final current = _messages
            .firstWhere(
              (m) => m.historyId == historyId && m.role == _ChatRole.user,
              orElse: () => const _ChatMessage(role: _ChatRole.user, text: ''),
            )
            .text
            .trim();
    final controller = TextEditingController(text: current);
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiChatRenameTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.aiChatRenameHint),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (renamed == null || renamed.trim().isEmpty || !mounted) return;

    try {
      await ref.read(backendApiServiceProvider).renameAiFinanceQueryHistoryItem(
            id: historyId,
            query: renamed.trim(),
          );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].historyId == historyId && _messages[i].role == _ChatRole.user) {
            _messages[i] = _messages[i].copyWith(text: renamed.trim());
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.aiChatRenameSuccess)));
    } catch (_) {}
  }

  Future<void> _deleteHistoryItem(String historyId) async {
    final l10n = AppLocalizations.of(context)!;
    final queryText = _messages
            .firstWhere(
              (m) => m.historyId == historyId && m.role == _ChatRole.user,
              orElse: () => const _ChatMessage(role: _ChatRole.user, text: ''),
            )
            .text
            .trim();
    final target = queryText.isEmpty ? '-' : queryText;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiChatDeleteConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiChatDeleteConfirmMessage),
            const SizedBox(height: 8),
            Text(
              l10n.aiChatDeleteConfirmTarget(target),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
            ),
            child: Text(l10n.aiChatDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final removed = _messages.where((m) => m.historyId == historyId).toList();
    if (removed.isEmpty) return;

    final token = ++_deleteTokenCounter;
    setState(() {
      _pendingDeletedMessages[historyId] = removed;
      _pendingDeleteTokens[historyId] = token;
      _messages.removeWhere((m) => m.historyId == historyId);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.aiChatDeleteQueued),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.aiChatUndo,
          onPressed: () => _undoDeleteHistoryItem(historyId),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    if (_pendingDeleteTokens[historyId] != token) {
      return;
    }

    try {
      await ref.read(backendApiServiceProvider).deleteAiFinanceQueryHistoryItem(historyId);
      if (!mounted) return;
      _pendingDeleteTokens.remove(historyId);
      _pendingDeletedMessages.remove(historyId);
    } catch (_) {
      if (!mounted) return;
      _undoDeleteHistoryItem(historyId, showSnack: false);
    }
  }

  void _undoDeleteHistoryItem(String historyId, {bool showSnack = true}) {
    final l10n = AppLocalizations.of(context)!;
    final removed = _pendingDeletedMessages.remove(historyId);
    _pendingDeleteTokens.remove(historyId);
    if (removed == null || !mounted) return;

    setState(() {
      _messages.addAll(removed);
    });
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiChatDeleteUndone)),
      );
    }
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text, this.historyId});

  final _ChatRole role;
  final String text;
  final String? historyId;

  _ChatMessage copyWith({
    _ChatRole? role,
    String? text,
    String? historyId,
  }) {
    return _ChatMessage(
      role: role ?? this.role,
      text: text ?? this.text,
      historyId: historyId ?? this.historyId,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.onRename,
    this.onDelete,
  });

  final _ChatMessage message;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0A2472) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                message.text,
                style: AppTextStyles.caption.copyWith(
                  color: isUser ? AppColors.white : AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            if (onRename != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isUser ? AppColors.white : AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return [
                    if (onRename != null)
                      PopupMenuItem(value: 'rename', child: Text(l10n.aiChatRename)),
                    if (onDelete != null)
                      PopupMenuItem(value: 'delete', child: Text(l10n.aiChatDelete)),
                  ];
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
