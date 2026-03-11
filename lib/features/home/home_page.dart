import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/goals/models/goals_models.dart';
import 'package:confindant/features/goals/presentation/view_models/goals_view_model.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/view_models/home_view_model.dart';
import 'package:confindant/features/home/presentation/widgets/widgets.dart';
import 'package:confindant/features/wallet/presentation/view_models/wallet_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    final goals = ref.watch(goalsViewModelProvider);
    final summary =
        state.data?.summary ??
        const HomeSummaryData(
          balance: 0,
          income: 0,
          expense: 0,
          lastUpdatedLabel: 'Updated just now',
        );

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.appBackground),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(31, 62, 31, 140),
          child: Column(
            children: [
              _TopGreetingRow(name: 'Kennedy', onNotificationTap: () {}),
              const SizedBox(height: AppSpacing.xl),
              _BalanceHeroCard(
                summary: summary,
                balanceVisible: _balanceVisible,
                onToggleVisibility: () {
                  setState(() => _balanceVisible = !_balanceVisible);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.uiState == HomeUiState.loaded && state.data != null)
                _LoadedSections(
                  data: state.data!,
                  onQuickActionTap: (type) => _onQuickActionTap(type),
                  onDeleteTransaction: (id) => _deleteTransaction(id),
                  goals: goals,
                ),
              if (state.uiState == HomeUiState.empty) const _EmptySections(),
              if (state.uiState == HomeUiState.error)
                _ErrorSections(
                  message: state.errorMessage ?? 'Unable to load dashboard.',
                  onRetry: () => vm.load(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onQuickActionTap(HomeQuickActionType type) async {
    switch (type) {
      case HomeQuickActionType.scan:
        context.push(RoutePaths.scan);
        return;
      case HomeQuickActionType.addWallet:
        context.push(RoutePaths.addWallet);
        return;
      case HomeQuickActionType.addExpense:
        await _createQuickTransaction(isExpense: true);
        return;
      case HomeQuickActionType.addIncome:
        await _createQuickTransaction(isExpense: false);
        return;
    }
  }

  Future<void> _createQuickTransaction({required bool isExpense}) async {
    final walletState = ref.read(walletViewModelProvider);
    final walletId = walletState.wallets.isNotEmpty
        ? (walletState.wallets.first['id']?.toString() ??
              walletState.wallets.first['_id']?.toString() ??
              '')
        : '';

    if (walletId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create wallet first.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(backendApiServiceProvider).createTransaction({
      'wallet_id': walletId,
      'type': isExpense ? 'expense' : 'income',
      'category': isExpense ? 'General Expense' : 'General Income',
      'total_amount': isExpense ? 50000 : 150000,
      'date': DateTime.now().toIso8601String(),
      'merchant_name': isExpense ? 'Quick Expense' : 'Quick Income',
      'notes': 'Created from Home quick action',
      'is_verified': true,
      'items': [],
    });

    await ref.read(homeViewModelProvider.notifier).load();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(isExpense ? 'Expense added.' : 'Income added.')),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction id is invalid.')),
      );
      return;
    }

    await ref.read(backendApiServiceProvider).deleteTransaction(id);
    await ref.read(homeViewModelProvider.notifier).load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
  }
}

class _LoadedSections extends StatelessWidget {
  const _LoadedSections({
    required this.data,
    required this.onQuickActionTap,
    required this.onDeleteTransaction,
    required this.goals,
  });

  final HomeDashboardData data;
  final ValueChanged<HomeQuickActionType> onQuickActionTap;
  final ValueChanged<String> onDeleteTransaction;
  final List<GoalData> goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('home_loaded_view'),
      children: [
        HomeQuickActionsCard(
          actions: data.quickActions,
          onActionTap: onQuickActionTap,
        ),
        const SizedBox(height: AppSpacing.md),
        _GoalsSummaryCard(goalCount: goals.length),
        const SizedBox(height: AppSpacing.md),
        HomeBudgetSnapshotCard(items: data.budgetItems),
        const SizedBox(height: AppSpacing.md),
        HomeRecentTransactionsCard(
          items: data.recentTransactions,
          onSeeAllTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('See all tapped (mock)')),
            );
          },
          onDeleteTap: (item) => onDeleteTransaction(item.id),
        ),
        const SizedBox(height: AppSpacing.md),
        HomeInsightCard(text: data.insightText),
      ],
    );
  }
}

class _GoalsSummaryCard extends StatelessWidget {
  const _GoalsSummaryCard({required this.goalCount});

  final int goalCount;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Savings Goals',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(RoutePaths.goals),
                child: Text(
                  'Open',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentAction,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$goalCount active goal(s) • track your progress and top-up routinely.',
            style: AppTextStyles.caption.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      key: const ValueKey('home_empty_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const AppEmptyAssetPlaceholder(
            label: 'Belum ada transaksi',
            icon: Icons.receipt_long_rounded,
            height: 80,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mulai tambah transaksi agar dashboard Home lebih informatif.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorSections extends StatelessWidget {
  const _ErrorSections({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      key: const ValueKey('home_error_view'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC10007),
            size: 34,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({
    required this.summary,
    required this.balanceVisible,
    required this.onToggleVisibility,
  });

  final HomeSummaryData summary;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your Balance',
                style: AppTextStyles.body.copyWith(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 17,
                  height: 22 / 17,
                ),
              ),
              const SizedBox(width: 12),
              AppIconButtonCircle(
                icon: balanceVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 30,
                backgroundColor: Colors.transparent,
                iconColor: AppColors.textSecondary,
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              balanceVisible
                  ? formatHomeRupiah(summary.balance)
                  : 'Rp. **********',
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle.copyWith(
                fontSize: 32,
                height: 1.05,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.lastUpdatedLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _IncomeExpenseCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Income',
                  value: formatHomeRupiah(summary.income),
                  gradient: const [Color(0xFF005B22), Color(0xFF0A2472)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _IncomeExpenseCard(
                  icon: Icons.trending_down_rounded,
                  label: 'Expense',
                  value: formatHomeRupiah(summary.expense),
                  gradient: const [Color(0xFFA20003), Color(0xFF0A2472)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopGreetingRow extends StatelessWidget {
  const _TopGreetingRow({required this.name, required this.onNotificationTap});

  final String name;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage('assets/avatars/home_avatar.png'),
          backgroundColor: Colors.transparent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                  fontSize: 17,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.white,
                  fontSize: 32 / 1.46,
                ),
              ),
            ],
          ),
        ),
        AppGlassContainer(
          radius: 15,
          blurSigma: 13.2,
          padding: const EdgeInsets.all(2),
          child: AppIconButtonCircle(
            icon: Icons.notifications_none_rounded,
            size: 30,
            backgroundColor: Colors.transparent,
            iconColor: AppColors.white,
            onPressed: onNotificationTap,
          ),
        ),
      ],
    );
  }
}

class _IncomeExpenseCard extends StatelessWidget {
  const _IncomeExpenseCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.white,
                fontSize: 18,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
