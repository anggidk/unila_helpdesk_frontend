import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_cohort_page.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_dashboard_page.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_reports_page.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_survey_page.dart';
import 'package:unila_helpdesk_frontend/features/admin/presentation/admin_tickets_page.dart';

final adminShellIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final adminSidebarExpandedProvider = StateProvider.autoDispose<bool>(
  (ref) => true,
);
final adminProfileMenuOpenProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(adminShellIndexProvider);
    final isExpanded = ref.watch(adminSidebarExpandedProvider);
    final showProfileMenu = ref.watch(adminProfileMenuOpenProvider);
    final adminUser = ref.watch(adminUserProvider);
    final pages = [
      const AdminDashboardPage(),
      const AdminTicketsPage(),
      const AdminReportsPage(),
      const AdminCohortPage(),
      const AdminSurveyPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: isExpanded ? 240 : 84,
            decoration: const BoxDecoration(
              color: AppTheme.deepBlue,
            ),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 180;
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          height: 56,
                          child: isCompact
                              ? Center(
                                  child: Image.asset(
                                    'assets/logo/Logo_unila.png',
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/logo/Logo_unila.png',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'UNILA Admin',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                          Text(
                                            'Helpdesk System',
                                            style: TextStyle(color: Colors.white70),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard',
                        selected: index == 0,
                        showLabel: !isCompact,
                        onTap: () => ref
                            .read(adminShellIndexProvider.notifier)
                            .state = 0,
                      ),
                      _NavItem(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Ticket',
                        selected: index == 1,
                        showLabel: !isCompact,
                        onTap: () => ref
                            .read(adminShellIndexProvider.notifier)
                            .state = 1,
                      ),
                      _NavItem(
                        icon: Icons.assessment_outlined,
                        label: 'Laporan',
                        selected: index == 2,
                        showLabel: !isCompact,
                        onTap: () => ref
                            .read(adminShellIndexProvider.notifier)
                            .state = 2,
                      ),
                      _NavItem(
                        icon: Icons.group_work_outlined,
                        label: 'Cohort',
                        selected: index == 3,
                        showLabel: !isCompact,
                        onTap: () => ref
                            .read(adminShellIndexProvider.notifier)
                            .state = 3,
                      ),
                      _NavItem(
                        icon: Icons.quiz_outlined,
                        label: 'Survey',
                        selected: index == 4,
                        showLabel: !isCompact,
                        onTap: () => ref
                            .read(adminShellIndexProvider.notifier)
                            .state = 4,
                      ),
                      const Spacer(),
                      _ProfileSection(
                        isExpanded: !isCompact,
                        showMenu: showProfileMenu,
                        adminUser: adminUser,
                        onToggleMenu: () => ref
                            .read(adminProfileMenuOpenProvider.notifier)
                            .state = !showProfileMenu,
                        onLogout: () async {
                          await TokenStorage().clearToken();
                          sharedApiClient.setAuthToken(null);
                          ref.read(adminUserProvider.notifier).state = null;
                          ref.invalidate(ticketsProvider);
                          ref.invalidate(notificationsProvider);
                          if (!context.mounted) return;
                          context.goNamed(AppRouteNames.login);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppTheme.outline)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ref
                                .read(adminSidebarExpandedProvider.notifier)
                                .state = !isExpanded,
                            icon: const Icon(Icons.menu),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _titleForIndex(index),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: pages[index]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Manajemen Tiket';
      case 2:
        return 'Laporan Survey Kepuasan';
      case 3:
        return 'Cohort Analysis';
      case 4:
        return 'Pengaturan Survey';
      default:
        return 'Dashboard';
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Tooltip(
          message: label,
          child: InkResponse(
            onTap: onTap,
            radius: 28,
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppTheme.accentYellow : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading:
          Icon(icon, color: selected ? AppTheme.accentYellow : Colors.white70),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.isExpanded,
    required this.showMenu,
    required this.adminUser,
    required this.onToggleMenu,
    required this.onLogout,
  });

  final bool isExpanded;
  final bool showMenu;
  final UserProfile? adminUser;
  final VoidCallback onToggleMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: PopupMenuButton<String>(
          tooltip: 'Akun',
          offset: const Offset(0, -8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'logout') onLogout();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: onToggleMenu,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminUser?.name ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        adminUser?.email ?? 'admin@unila.ac.id',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(
                  showMenu ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
        if (showMenu)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ),
      ],
    );
  }
}

