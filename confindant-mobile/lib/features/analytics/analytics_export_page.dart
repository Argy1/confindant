import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:confindant/features/analytics/presentation/view_models/advanced_analytics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsExportPage extends ConsumerWidget {
  const AnalyticsExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(advancedAnalyticsProvider);
    final resultState = ref.watch(exportProvider);
    final vm = ref.read(exportProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Text(
                      'Export Analytics',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Filter', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 8),
                      Text(
                        '${filter.fromDateLabel} - ${filter.toDateLabel}\n${filter.wallet} • ${filter.category}',
                        style: AppTextStyles.body.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppSecondaryButton(
                              label: 'Export CSV',
                              onPressed: () => vm.export(
                                ExportRequest(
                                  format: ExportFormat.csv,
                                  filter: filter,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Export PDF',
                              onPressed: () => vm.export(
                                ExportRequest(
                                  format: ExportFormat.pdf,
                                  filter: filter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      resultState.when(
                        data: (result) {
                          if (result == null) {
                            return Text(
                              'No export generated yet.',
                              style: AppTextStyles.caption,
                            );
                          }
                          return Text(
                            '${result.fileName}\n${result.message}',
                            style: AppTextStyles.caption,
                          );
                        },
                        error: (error, stackTrace) => Text(
                          'Export failed.',
                          style: AppTextStyles.caption,
                        ),
                        loading: () => const LinearProgressIndicator(),
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
}
