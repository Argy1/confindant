import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_gradients.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_spacing.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/app/widgets/widgets.dart';
import 'package:flutter/material.dart';

class CategoryModalShell extends StatelessWidget {
  const CategoryModalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.appBackground),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AppCardContainer(
                radius: AppRadius.md,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 250.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 24,
                                  height: 32 / 24,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF99A1AF),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryLimitFormCard extends StatelessWidget {
  const CategoryLimitFormCard({
    super.key,
    required this.categoryController,
    required this.limitController,
    this.onAddTap,
  });

  final TextEditingController categoryController;
  final TextEditingController limitController;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Limit',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 12),
          CategoryLiteInput(
            controller: categoryController,
            hint: 'Category (e.g., Food)',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CategoryLiteInput(
                  controller: limitController,
                  hint: 'Limit (Rp)',
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 42,
                child: Material(
                  color: AppColors.accentAction,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onAddTap,
                    borderRadius: BorderRadius.circular(10),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryLiteInput extends StatelessWidget {
  const CategoryLiteInput({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
