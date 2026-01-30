import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unila_helpdesk_frontend/app/app_router.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/feedback/presentation/feedback_page.dart';
import 'package:unila_helpdesk_frontend/features/home/presentation/home_page.dart';
import 'package:unila_helpdesk_frontend/features/profile/presentation/profile_page.dart';
import 'package:unila_helpdesk_frontend/features/tickets/presentation/ticket_list_page.dart';
import 'package:unila_helpdesk_frontend/features/user/presentation/style_15_bottom_nav_bar.widget.dart';

final userShellIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

class UserShell extends ConsumerWidget {
  const UserShell({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(userShellIndexProvider);
    final pages = [
      HomePage(user: user),
      TicketListPage(user: user),
      FeedbackPage(user: user),
      ProfilePage(user: user),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Style15BottomNavBar(
        items: const [
          Style15NavItem(icon: Icons.home_outlined, label: 'Home'),
          Style15NavItem(icon: Icons.confirmation_number_outlined, label: 'Tiket'),
          Style15NavItem(icon: Icons.chat_bubble_outline, label: 'Feedback'),
          Style15NavItem(icon: Icons.person_outline, label: 'Profil'),
        ],
        currentIndex: currentIndex,
        onTap: (index) => ref.read(userShellIndexProvider.notifier).state = index,
        middleItem: const Style15NavItem(icon: Icons.add, label: 'Tambah'),
        onMiddleTap: () => context.pushNamed(AppRouteNames.ticketForm),
      ),
    );
  }
}
