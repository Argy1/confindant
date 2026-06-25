import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrgAiChatPage extends ConsumerStatefulWidget {
  const OrgAiChatPage({super.key});

  @override
  ConsumerState<OrgAiChatPage> createState() => _OrgAiChatPageState();
}

class _OrgAiChatPageState extends ConsumerState<OrgAiChatPage> {
  final _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final Map<String, List<_ChatMessage>> _pendingDeletedMessages = {};
  final Map<String, int> _pendingDeleteTokens = {};
  int _deleteTokenCounter = 0;
  bool _sending = false;
  bool _loadingHistory = false;

  static const _quickAsk = [
    'Berapa total pendapatan bulan ini?',
    'Akun mana yang paling besar pengeluarannya?',
    'Apakah neraca kami sudah seimbang?',
  ];

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
    final orgId = ref.watch(activeOrgIdProvider);

    return OrgScaffold(
      title: 'AI Konsultan',
      current: OrgNavItem.more,
      child: orgId == null
          ? const Center(child: Text('Pilih organisasi terlebih dahulu.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCardContainer(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final q in _quickAsk) _quickAskChip(q, orgId: orgId),
                        ActionChip(
                          label: const Text('Hapus Riwayat'),
                          onPressed: _sending || _loadingHistory
                              ? null
                              : () => _clearHistory(orgId),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCardContainer(
                    child: _loadingHistory
                        ? Text(
                            'Memuat riwayat...',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          )
                        : _messages.isEmpty
                            ? Text(
                                'Belum ada percakapan. Ajukan pertanyaan terkait keuangan organisasi Anda.',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textSecondary),
                              )
                            : Column(
                                children: [
                                  for (final msg in _messages) ...[
                                    _MessageBubble(
                                      message: msg,
                                      onDelete: msg.historyId != null &&
                                              msg.role == _ChatRole.assistant
                                          ? () => _deleteHistoryItem(
                                                msg.historyId!,
                                                orgId: orgId,
                                              )
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
                          decoration: const InputDecoration(
                            hintText: 'Tanyakan sesuatu tentang keuangan organisasi...',
                          ),
                          onSubmitted: (_) => _send(orgId),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppSecondaryButton(
                                label: 'Bersihkan',
                                onPressed: _sending
                                    ? null
                                    : () => setState(() => _messages.clear()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppPrimaryButton(
                                label: _sending ? 'Memproses...' : 'Tanya',
                                icon: const Icon(
                                  Icons.send_rounded,
                                  color: AppColors.white,
                                  size: 18,
                                ),
                                onPressed: _sending ? null : () => _send(orgId),
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
    );
  }

  Widget _quickAskChip(String text, {required String orgId}) {
    return ActionChip(
      label: Text(text),
      onPressed: _sending
          ? null
          : () {
              _controller.text = text;
              _send(orgId);
            },
    );
  }

  Future<void> _loadHistory() async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    setState(() => _loadingHistory = true);
    try {
      final items = await ref
          .read(backendApiServiceProvider)
          .orgAiFinanceQueryHistory(orgId, limit: 20);
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
        final historyId = entry['id']?.toString().trim();

        if (query.isNotEmpty) {
          next.add(_ChatMessage(
            role: _ChatRole.user,
            text: query,
            historyId: historyId,
          ));
        }
        if (answer.isNotEmpty || insight.isNotEmpty || actions.isNotEmpty) {
          final buffer = StringBuffer();
          if (answer.isNotEmpty) buffer.writeln(answer);
          if (insight.isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            buffer.writeln('Insight: $insight');
          }
          if (actions.isNotEmpty) {
            if (buffer.isNotEmpty) buffer.writeln();
            for (var i = 0; i < actions.length; i++) {
              buffer.writeln('${i + 1}. ${actions[i]}');
            }
          }
          next.add(_ChatMessage(
            role: _ChatRole.assistant,
            text: buffer.toString().trim(),
            historyId: historyId,
          ));
        }
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(next);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _clearHistory(String orgId) async {
    setState(() => _sending = true);
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgClearAiFinanceQueryHistory(orgId);
      if (!mounted) return;
      setState(() => _messages.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Riwayat dihapus.')),
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _send(String? orgId) async {
    if (orgId == null) return;
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(role: _ChatRole.user, text: query));
      _controller.clear();
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final data = await ref
          .read(backendApiServiceProvider)
          .orgAiFinanceQuery(
            orgId,
            query: query,
            locale: locale == 'en' ? 'en' : 'id',
          );
      final historyId = data['history_id']?.toString().trim();
      if (historyId != null && historyId.isNotEmpty) {
        final idx = _messages.lastIndexWhere(
          (m) => m.role == _ChatRole.user && m.historyId == null,
        );
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(historyId: historyId);
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
      buffer.writeln(answer.isEmpty ? 'Maaf, tidak ada jawaban.' : answer);
      if (insight.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Insight: $insight');
      }
      if (actions.isNotEmpty) {
        buffer.writeln();
        for (var i = 0; i < actions.length; i++) {
          buffer.writeln('${i + 1}. ${actions[i]}');
        }
      }

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: _ChatRole.assistant,
          text: buffer.toString().trim(),
          historyId: historyId?.isNotEmpty == true ? historyId : null,
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          role: _ChatRole.assistant,
          text: 'Terjadi kesalahan.\n\nDetail: $e',
        ));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteHistoryItem(
    String historyId, {
    required String orgId,
  }) async {
    final removed =
        _messages.where((m) => m.historyId == historyId).toList();
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
        content: const Text('Riwayat dihapus.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _undoDelete(historyId),
        ),
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    if (_pendingDeleteTokens[historyId] != token) return;

    try {
      await ref
          .read(backendApiServiceProvider)
          .deleteAiFinanceQueryHistoryItem(historyId);
      if (!mounted) return;
      _pendingDeleteTokens.remove(historyId);
      _pendingDeletedMessages.remove(historyId);
    } catch (_) {
      if (!mounted) return;
      _undoDelete(historyId, showSnack: false);
    }
  }

  void _undoDelete(String historyId, {bool showSnack = true}) {
    final removed = _pendingDeletedMessages.remove(historyId);
    _pendingDeleteTokens.remove(historyId);
    if (removed == null || !mounted) return;
    setState(() => _messages.addAll(removed));
    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penghapusan dibatalkan.')),
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

  _ChatMessage copyWith({_ChatRole? role, String? text, String? historyId}) {
    return _ChatMessage(
      role: role ?? this.role,
      text: text ?? this.text,
      historyId: historyId ?? this.historyId,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onDelete});

  final _ChatMessage message;
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
          color: isUser
              ? const Color(0xFF0A2472)
              : const Color(0xFFF3F4F6),
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
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isUser ? AppColors.white : AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
