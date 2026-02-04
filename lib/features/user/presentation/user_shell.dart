import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_providers.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/core/network/api_client.dart';
import 'package:unila_helpdesk_frontend/core/network/token_storage.dart';
import 'package:unila_helpdesk_frontend/features/feedback/presentation/feedback_page.dart';
import 'package:unila_helpdesk_frontend/features/home/presentation/home_page.dart';
import 'package:unila_helpdesk_frontend/features/profile/presentation/profile_page.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/ticket_list_page.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/style_15_bottom_nav_bar.widget.dart';

final userShellIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

class UserShell extends ConsumerStatefulWidget {
  const UserShell({super.key});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSession());
  }

  Future<void> _restoreSession() async {
    if (_restoring) return;
    if (ref.read(currentUserProvider) != null) return;
    setState(() => _restoring = true);

    final token = await TokenStorage().readToken();
    final user = await TokenStorage().readUser();
    if (!mounted) return;

    if (token == null || token.isEmpty || user == null) {
      setState(() => _restoring = false);
      context.goNamed(AppRouteNames.login);
      return;
    }

    sharedApiClient.setAuthToken(token);
    ref.read(currentUserProvider.notifier).state = user;
    ref.read(adminUserProvider.notifier).state = null;
    setState(() => _restoring = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return _MissingUserPage(isLoading: _restoring);
    }
    final index = ref.watch(userShellIndexProvider);
    final pages = [
      HomePage(user: user),
      const TicketListPage(),
      const FeedbackPage(),
      ProfilePage(user: user),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Style15BottomNavBar(
        items: const [
          Style15NavItem(icon: Icons.home_outlined, label: 'Home'),
          Style15NavItem(icon: Icons.confirmation_number_outlined, label: 'Tiket'),
          Style15NavItem(icon: Icons.chat_bubble_outline, label: 'Feedback'),
          Style15NavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        currentIndex: index,
        onTap: (value) =>
            ref.read(userShellIndexProvider.notifier).state = value,
        middleItem: const Style15NavItem(icon: Icons.add, label: 'Tambah'),
        onMiddleTap: () => context.pushNamed(AppRouteNames.ticketForm),
      ),
    );
  }
}

class _MissingUserPage extends StatelessWidget {
  const _MissingUserPage({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Data user tidak ditemukan.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.goNamed(AppRouteNames.login),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}
