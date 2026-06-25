import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/models/report_models.dart';
import 'package:confindant/features/org/presentation/widgets/org_formatters.dart';
import 'package:flutter/material.dart';

/// A balance/status banner (green when balanced, amber otherwise).
class OrgStatusBanner extends StatelessWidget {
  const OrgStatusBanner({
    super.key,
    required this.ok,
    required this.okText,
    required this.warnText,
  });

  final bool ok;
  final String okText;
  final String warnText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ok ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: ok ? const Color(0xFF047857) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ok ? okText : warnText,
              style: TextStyle(
                fontSize: 12.5,
                color: ok ? const Color(0xFF065F46) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A collapsible grouped report section rendered as a stacked vertical card.
/// Each account row is tappable to drill into its general ledger.
class OrgReportSectionCard extends StatelessWidget {
  const OrgReportSectionCard({
    super.key,
    required this.title,
    required this.section,
    required this.total,
    required this.totalLabel,
    this.accent = AppColors.blue900,
    this.onAccountTap,
  });

  final String title;
  final ReportSection section;
  final double total;
  final String totalLabel;
  final Color accent;
  final void Function(String code, String name)? onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (section.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data',
                  style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...section.groups.map((g) => _GroupTile(group: g, onAccountTap: onAccountTap)),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    totalLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Text(
                  formatOrgRupiah(total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatefulWidget {
  const _GroupTile({required this.group, this.onAccountTap});

  final ReportGroup group;
  final void Function(String code, String name)? onAccountTap;

  @override
  State<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<_GroupTile> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _open ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    orgSubtypeLabel(g.subtype),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  formatOrgRupiah(g.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          ...g.accounts.map(
            (a) => InkWell(
              onTap: widget.onAccountTap == null
                  ? null
                  : () => widget.onAccountTap!(a.code, a.name),
              child: Container(
                color: const Color(0xFFFAFBFC),
                padding: const EdgeInsets.fromLTRB(34, 9, 14, 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            a.code,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatOrgRupiah(a.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact year selector dropdown for report app bars.
class OrgYearSelector extends StatelessWidget {
  const OrgYearSelector({
    super.key,
    required this.year,
    required this.onChanged,
    this.fromYear = 2023,
  });

  final int year;
  final ValueChanged<int> onChanged;
  final int fromYear;

  @override
  Widget build(BuildContext context) {
    final current = DateTime.now().year;
    final years = <int>[for (var y = current; y >= fromYear; y--) y];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
