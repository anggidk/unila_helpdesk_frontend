import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unila_helpdesk_frontend/core/models/user_models.dart';
import 'package:unila_helpdesk_frontend/features/home/data/home_repository.dart';
import 'package:unila_helpdesk_frontend/features/home/domain/home_models.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

final homeSummaryProvider =
    FutureProvider.autoDispose.family<HomeSummary, UserProfile>((ref, user) async {
  final repository = ref.watch(homeRepositoryProvider);
  return repository.fetchHomeSummary(user: user);
});
