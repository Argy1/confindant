import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:confindant/core/constants/app_providers.dart';
import 'package:confindant/features/org/models/management_models.dart';
import 'package:confindant/features/org/models/org_models.dart';
import 'package:confindant/features/org/data/org_data_source.dart';
import 'package:confindant/features/org/presentation/widgets/org_scaffold.dart';
import 'package:confindant/features/org/presentation/workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _roleLabel = {
  'admin': 'Admin',
  'bendahara': 'Bendahara',
  'auditor': 'Auditor',
  'viewer': 'Viewer',
};

const _roleColor = {
  'admin': Color(0xFF7C3AED),
  'bendahara': Color(0xFF2563EB),
  'auditor': Color(0xFF059669),
  'viewer': Color(0xFF6B7280),
};

class OrgMembersPage extends ConsumerStatefulWidget {
  const OrgMembersPage({super.key});

  @override
  ConsumerState<OrgMembersPage> createState() => _OrgMembersPageState();
}

class _OrgMembersPageState extends ConsumerState<OrgMembersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<OrgMemberData> _members = const [];
  List<OrgInvitationData> _invitations = const [];
  bool _loadingMembers = true;
  bool _loadingInvites = false; // loaded lazily when tab 1 is first opened

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) _reloadCurrent();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isAdmin(String? orgId) {
    if (orgId == null) return false;
    final orgs = ref.read(myOrganizationsProvider).valueOrNull ?? const [];
    for (final Organization o in orgs) {
      if (o.id == orgId) return o.role == 'admin';
    }
    return false;
  }

  Future<void> _reloadCurrent() async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    if (_tabs.index == 0) {
      await _loadMembers();
    } else {
      await _loadInvites(orgId);
    }
  }

  Future<void> _loadMembers() async {
    final orgId = ref.read(activeOrgIdProvider);
    if (orgId == null) return;
    setState(() => _loadingMembers = true);
    try {
      final raw = await ref
          .read(backendApiServiceProvider)
          .orgMemberList(orgId);
      if (!mounted) return;
      setState(() {
        _members = raw.map(OrgMemberData.fromJson).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat anggota: $e')));
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _loadInvites(String orgId) async {
    setState(() => _loadingInvites = true);
    try {
      final raw = await ref
          .read(backendApiServiceProvider)
          .orgInvitationList(orgId);
      if (!mounted) return;
      setState(
          () => _invitations = raw.map(OrgInvitationData.fromJson).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal memuat undangan: $e')));
    } finally {
      if (mounted) setState(() => _loadingInvites = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = ref.watch(activeOrgIdProvider);
    final isAdmin = _isAdmin(orgId);

    return OrgScaffold(
      title: 'Anggota',
      current: OrgNavItem.more,
      actions: isAdmin && orgId != null
          ? [
              IconButton(
                icon: const Icon(Icons.person_add_rounded),
                tooltip: 'Undang anggota',
                onPressed: () => _openInviteDialog(orgId),
              ),
            ]
          : null,
      child: orgId == null
          ? const Center(child: Text('Pilih organisasi terlebih dahulu.'))
          : Column(
              children: [
                TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: 'Anggota (${_members.length})'),
                    Tab(text: 'Undangan (${_invitations.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _MembersTab(
                        members: _members,
                        loading: _loadingMembers,
                        isAdmin: isAdmin,
                        onChangeRole: (m, role) =>
                            _changeRole(orgId, m, role),
                        onRemove: (m) => _removeMember(orgId, m),
                        onRefresh: _loadMembers,
                      ),
                      _InvitationsTab(
                        invitations: _invitations,
                        loading: _loadingInvites,
                        isAdmin: isAdmin,
                        onCancel: (inv) => _cancelInvite(orgId, inv),
                        onRefresh: () => _loadInvites(orgId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openInviteDialog(String orgId) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _InviteDialog(),
    );
    if (result == null || !mounted) return;

    try {
      final data = await ref
          .read(backendApiServiceProvider)
          .orgInviteCreate(orgId, result['email']!, result['role']!);
      if (!mounted) return;
      final inviteUrl = data['invite_url']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (ctx) => _InviteLinkDialog(inviteUrl: inviteUrl),
      );
      await _loadInvites(orgId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat undangan: $e')));
    }
  }

  Future<void> _changeRole(
    String orgId,
    OrgMemberData member,
    String newRole,
  ) async {
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgMemberUpdateRole(orgId, member.id, newRole);
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _removeMember(String orgId, OrgMemberData member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan anggota?'),
        content: Text('${member.name} akan dikeluarkan dari organisasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgMemberRemove(orgId, member.id);
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _cancelInvite(String orgId, OrgInvitationData inv) async {
    try {
      await ref
          .read(backendApiServiceProvider)
          .orgInviteCancel(orgId, inv.token);
      await _loadInvites(orgId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}

// ---- Members tab -----------------------------------------------------------

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.members,
    required this.loading,
    required this.isAdmin,
    required this.onChangeRole,
    required this.onRemove,
    required this.onRefresh,
  });

  final List<OrgMemberData> members;
  final bool loading;
  final bool isAdmin;
  final void Function(OrgMemberData, String) onChangeRole;
  final void Function(OrgMemberData) onRemove;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (members.isEmpty) {
      return Center(
        child: Text('Tidak ada anggota.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: members.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final m = members[i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.blue900.withAlpha(30),
              child: Text(
                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.blue900, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(m.name,
                style:
                    AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(m.email,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary, fontSize: 11)),
            trailing: isAdmin
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoleDropdown(
                        role: m.role,
                        onChanged: (r) => onChangeRole(m, r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_remove_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        tooltip: 'Keluarkan',
                        onPressed: () => onRemove(m),
                      ),
                    ],
                  )
                : _RoleBadge(role: m.role),
          );
        },
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.role, required this.onChanged});
  final String role;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: role,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: ['admin', 'bendahara', 'auditor', 'viewer']
          .map((r) => DropdownMenuItem(
              value: r,
              child: Text(_roleLabel[r] ?? r,
                  style: AppTextStyles.caption.copyWith(fontSize: 11))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor[role] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        _roleLabel[role] ?? role,
        style: AppTextStyles.caption
            .copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ---- Invitations tab -------------------------------------------------------

class _InvitationsTab extends StatelessWidget {
  const _InvitationsTab({
    required this.invitations,
    required this.loading,
    required this.isAdmin,
    required this.onCancel,
    required this.onRefresh,
  });

  final List<OrgInvitationData> invitations;
  final bool loading;
  final bool isAdmin;
  final void Function(OrgInvitationData) onCancel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (invitations.isEmpty) {
      return Center(
        child: Text('Tidak ada undangan tertunda.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: invitations.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final inv = invitations[i];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(inv.email,
                style:
                    AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              'Sebagai ${_roleLabel[inv.role] ?? inv.role} · oleh ${inv.inviterName}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
            trailing: isAdmin
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFDC2626)),
                    tooltip: 'Batalkan',
                    onPressed: () => onCancel(inv),
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ---- Invite dialog ---------------------------------------------------------

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  String _role = 'viewer';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Undang Anggota'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', hintText: 'email@contoh.com'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              DropdownMenuItem(
                  value: 'admin',
                  child: const Text('Admin — kelola org & anggota')),
              DropdownMenuItem(
                  value: 'bendahara',
                  child: const Text('Bendahara — input & posting')),
              DropdownMenuItem(
                  value: 'auditor',
                  child: const Text('Auditor — baca & review')),
              DropdownMenuItem(
                  value: 'viewer', child: const Text('Viewer — hanya baca')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = _emailCtrl.text.trim();
            if (email.isEmpty) return;
            Navigator.of(context).pop({'email': email, 'role': _role});
          },
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}

// ---- Invite link dialog ----------------------------------------------------

class _InviteLinkDialog extends StatefulWidget {
  const _InviteLinkDialog({required this.inviteUrl});
  final String inviteUrl;

  @override
  State<_InviteLinkDialog> createState() => _InviteLinkDialogState();
}

class _InviteLinkDialogState extends State<_InviteLinkDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Undangan Dibuat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'Salin link berikut dan bagikan ke calon anggota. Link berlaku 48 jam.'),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.inviteUrl,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 11, fontFamily: 'monospace'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: _copied
                        ? const Color(0xFF16A34A)
                        : AppColors.textSecondary,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: widget.inviteUrl));
                    if (!mounted) return;
                    setState(() => _copied = true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
