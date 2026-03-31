import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/app_card_container.dart';
import 'package:confindant/features/home/models/home_models.dart';
import 'package:confindant/features/home/presentation/widgets/home_formatters.dart';
import 'package:confindant/features/home/presentation/widgets/home_section_header.dart';
import 'package:flutter/material.dart';

class HomeRecentTransactionsCard extends StatelessWidget {
  const HomeRecentTransactionsCard({
    super.key,
    required this.items,
    this.onSeeAllTap,
    this.onDeleteTap,
  });

  final List<HomeTransactionItem> items;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<HomeTransactionItem>? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return AppCardContainer(
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(
            title: 'Recent Transactions',
            trailingText: 'See all',
            onTrailingTap: onSeeAllTap,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < items.length; i++) ...[
            _TransactionRow(item: items[i], onDeleteTap: onDeleteTap),
            if (i != items.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, this.onDeleteTap});

  final HomeTransactionItem item;
  final ValueChanged<HomeTransactionItem>? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final amountColor = item.isExpense
        ? const Color(0xFFC10007)
        : const Color(0xFF008236);
    final amountPrefix = item.isExpense ? '- ' : '+ ';

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(item.icon, color: AppColors.accentAction, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                item.subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$amountPrefix${formatHomeRupiah(item.amount)}',
            style: AppTextStyles.label.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Delete transaction',
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: const Color(0xFFC10007),
          onPressed: onDeleteTap == null ? null : () => onDeleteTap!(item),
        ),
      ],
    );
  }
}
