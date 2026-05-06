import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/profile/presentation/widgets/widgets.dart';
import 'package:confindant/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiOcrHealthPage extends ConsumerStatefulWidget {
  const AiOcrHealthPage({super.key});

  @override
  ConsumerState<AiOcrHealthPage> createState() => _AiOcrHealthPageState();
}

class _AiOcrHealthPageState extends ConsumerState<AiOcrHealthPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(backendApiServiceProvider).aiOcrMetrics(days: _days);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final jobs = Map<String, dynamic>.from(_data['jobs'] as Map? ?? const {});
    final feedback = Map<String, dynamic>.from(_data['feedback'] as Map? ?? const {});
    final topChanged = (_data['top_changed_fields'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final errors = (_data['error_code_breakdown'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ProfileDetailScaffold(
      title: l10n.profileAiOcrHealth,
      subtitle: l10n.aiOcrHealthSubtitle,
      child: Column(
        children: [
          ProfileSettingsCard(
            title: l10n.aiOcrHealthWindow,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _days,
                    items: [
                      DropdownMenuItem(value: 7, child: Text(l10n.aiOcrHealthLast7Days)),
                      DropdownMenuItem(value: 30, child: Text(l10n.aiOcrHealthLast30Days)),
                      DropdownMenuItem(value: 90, child: Text(l10n.aiOcrHealthLast90Days)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _days = value);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.aiOcrHealthRefresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            ProfileSettingsCard(
              title: l10n.aiOcrHealthErrorTitle,
              child: Text(
                _error!,
                style: AppTextStyles.body,
              ),
            )
          else ...[
            ProfileSettingsCard(
              title: l10n.aiOcrHealthJobs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metricLine(l10n.aiOcrHealthTotal, '${jobs['total'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthSuccess, '${jobs['success'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthFailed, '${jobs['failed'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthPendingProcessing, '${jobs['pending_or_processing'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthSuccessRate, '${jobs['success_rate_percent'] ?? 0}%'),
                  _metricLine(l10n.aiOcrHealthAvgConfidence, '${jobs['avg_confidence'] ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ProfileSettingsCard(
              title: l10n.aiOcrHealthUserFeedback,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metricLine(l10n.aiOcrHealthTotalFeedback, '${feedback['total'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthAccepted, '${feedback['accepted'] ?? 0}'),
                  _metricLine(l10n.aiOcrHealthAcceptanceRate, '${feedback['acceptance_rate_percent'] ?? 0}%'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ProfileSettingsCard(
              title: l10n.aiOcrHealthTopEditedFields,
              child: topChanged.isEmpty
                  ? Text(l10n.aiOcrHealthNoFeedbackData)
                  : Column(
                      children: topChanged.map((item) {
                        final field = item['field']?.toString() ?? '-';
                        final count = item['count']?.toString() ?? '0';
                        return _metricLine(field, count);
                      }).toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            ProfileSettingsCard(
              title: l10n.aiOcrHealthErrorBreakdown,
              child: errors.isEmpty
                  ? Text(l10n.aiOcrHealthNoErrorsWindow)
                  : Column(
                      children: errors.map((item) {
                        final code = item['error_code']?.toString() ?? '-';
                        final count = item['count']?.toString() ?? '0';
                        return _metricLine(code, count);
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
