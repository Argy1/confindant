import 'package:confindant/app/router/route_paths.dart';
import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A compact pill button for the app bar that shows the active workspace and
/// opens the workspace picker bottom sheet on tap.
class WorkspaceSwitcherButton extends ConsumerWidget {
  const WorkspaceSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(workspaceControllerProvider);
    final orgs = ref.watch(myOrganizationsProvider).valueOrNull ?? const [];

    final isOrg = ws.isOrg;
    Organization? activeOrg;
    for (final o in orgs) {
      if (o.id == ws.activeOrgId) {
        activeOrg = o;
        break;
      }
    }
    final label = isOrg ? (activeOrg?.name ?? 'Organisasi') : 'Personal';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showWorkspacePicker(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isOrg ? AppColors.blue900 : const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  isOrg ? Icons.account_balance_rounded : Icons.person_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.unfold_more_rounded,
                  size: 16, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the bottom sheet to switch between Personal and the user's orgs.
Future<void> showWorkspacePicker(BuildContext context, WidgetRef ref) async {
  final orgsAsync = ref.read(myOrganizationsProvider);
  final orgs = orgsAsync.valueOrNull ?? const [];
  final ws = ref.read(workspaceControllerProvider);
  final controller = ref.read(workspaceControllerProvider.notifier);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Workspace',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _WorkspaceTile(
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Personal',
                subtitle: 'Keuangan pribadi',
                selected: !ws.isOrg,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  controller.switchToPersonal();
                  context.go(RoutePaths.home);
                },
              ),
              if (orgs.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Organisasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...orgs.map(
                  (org) => _WorkspaceTile(
                    icon: Icons.account_balance_rounded,
                    iconColor: AppColors.blue900,
                    title: org.name,
                    subtitle: org.roleLabel,
                    selected: ws.isOrg && ws.activeOrgId == org.id,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      controller.switchToOrg(org.id);
                      context.go(RoutePaths.orgDashboard);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.infoBg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.blue900),
            ],
          ),
        ),
      ),
    );
  }
}
