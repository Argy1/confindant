import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:flutter/material.dart';

const _typeLabels = {
  'asset': 'Aset',
  'liability': 'Kewajiban',
  'net_asset': 'Aset Bersih',
  'revenue': 'Pendapatan',
  'expense': 'Beban',
};

/// Opens a bottom sheet to pick an account, optionally restricted to types.
Future<OrgAccount?> pickAccount(
  BuildContext context, {
  required List<OrgAccount> accounts,
  List<String>? types,
  String title = 'Pilih Akun',
}) {
  final filtered = types == null
      ? accounts
      : accounts.where((a) => types.contains(a.type)).toList();

  // Group by type, preserving the canonical order.
  const order = ['asset', 'liability', 'net_asset', 'revenue', 'expense'];
  final grouped = <String, List<OrgAccount>>{};
  for (final a in filtered) {
    grouped.putIfAbsent(a.type, () => []).add(a);
  }

  return showModalBottomSheet<OrgAccount>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final type in order)
                      if (grouped[type] != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                          child: Text(
                            _typeLabels[type] ?? type,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        ...grouped[type]!.map(
                          (a) => ListTile(
                            dense: true,
                            title: Text(
                              a.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              a.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            onTap: () => Navigator.of(sheetContext).pop(a),
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// A tappable field that displays the selected account and opens the picker.
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint = 'Pilih akun',
  });

  final String label;
  final OrgAccount? selected;
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected?.name ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      color: selected == null
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
