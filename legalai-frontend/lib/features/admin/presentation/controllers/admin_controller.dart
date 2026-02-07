import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/admin_stats_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../../../core/utils/ttl_cache.dart';

part 'admin_controller.g.dart';

final ragDaysProvider = legacy.StateProvider<int>((ref) => 30);
final adminDashboardRefreshProvider = legacy.StateProvider<int>((ref) => 0);

const Duration _dashboardCacheTtl = Duration(seconds: 30);
const Duration _ragMetricsCacheTtl = Duration(seconds: 15);
final TtlCache _dashboardCache = TtlCache(defaultTtl: _dashboardCacheTtl);

String _refreshKey(String base, int tick) => '$base:$tick';

@riverpod
Future<RagMetrics> ragMetrics(Ref ref, {int days = 7}) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  final base = 'ragMetrics:$days';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<RagMetrics>(key, ttl: _ragMetricsCacheTtl);
  if (cached != null) {
    return cached;
  }
  final metrics = await ref.watch(adminRepositoryProvider).getRagMetrics(days: days);
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, metrics);
  return metrics;
}

@riverpod
Future<List<KnowledgeSource>> knowledgeSources(Ref ref) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  const base = 'knowledgeSources';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<List<KnowledgeSource>>(key);
  if (cached != null) {
    return cached;
  }
  final sources = await ref.watch(adminRepositoryProvider).getKnowledgeSources();
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, sources);
  return sources;
}

@riverpod
Future<int> usersTotal(Ref ref) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  const base = 'usersTotal';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<int>(key);
  if (cached != null) {
    return cached;
  }
  final total = await ref.watch(adminRepositoryProvider).getUsersTotal();
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, total);
  return total;
}

@riverpod
Future<int> lawyersTotal(Ref ref) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  const base = 'lawyersTotal';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<int>(key);
  if (cached != null) {
    return cached;
  }
  final total = await ref.watch(adminRepositoryProvider).getLawyersTotal();
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, total);
  return total;
}

@riverpod
Future<int> contactMessagesTotal(Ref ref) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  const base = 'contactMessagesTotal';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<int>(key);
  if (cached != null) {
    return cached;
  }
  final total = await ref.watch(adminRepositoryProvider).getContactMessagesTotal();
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, total);
  return total;
}

@riverpod
Future<int> feedbackTotal(Ref ref) async {
  final refreshTick = ref.watch(adminDashboardRefreshProvider);
  const base = 'feedbackTotal';
  final key = _refreshKey(base, refreshTick);
  final cached = _dashboardCache.get<int>(key);
  if (cached != null) {
    return cached;
  }
  final total = await ref.watch(adminRepositoryProvider).getFeedbackTotal();
  _dashboardCache.invalidatePrefix('$base:');
  _dashboardCache.set(key, total);
  return total;
}

@Riverpod(keepAlive: true)
class AdminActions extends _$AdminActions {
  @override
  void build() {
    ref.keepAlive();
  }

  Future<void> ingestUrl(String title, String url, String language) async {
    final repo = ref.read(adminRepositoryProvider);
    await repo.ingestUrl(title, url, language);
    _dashboardCache.invalidatePrefix('knowledgeSources:');
    ref.read(adminDashboardRefreshProvider.notifier).state++;
    if (ref.mounted) {
      ref.invalidate(knowledgeSourcesProvider);
    }
  }

  Future<void> deleteSource(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    await repo.deleteSource(id);
    _dashboardCache.invalidatePrefix('knowledgeSources:');
    ref.read(adminDashboardRefreshProvider.notifier).state++;
    if (ref.mounted) {
      ref.invalidate(knowledgeSourcesProvider);
    }
  }

  Future<void> retrySource(int id) async {
    final repo = ref.read(adminRepositoryProvider);
    await repo.retrySource(id);
    _dashboardCache.invalidatePrefix('knowledgeSources:');
    ref.read(adminDashboardRefreshProvider.notifier).state++;
    if (ref.mounted) {
      ref.invalidate(knowledgeSourcesProvider);
    }
  }

  Future<void> uploadFile(PlatformFile file, String language) async {
    final repo = ref.read(adminRepositoryProvider);
    await repo.uploadKnowledge(file, language);
    _dashboardCache.invalidatePrefix('knowledgeSources:');
    ref.read(adminDashboardRefreshProvider.notifier).state++;
    if (ref.mounted) {
      ref.invalidate(knowledgeSourcesProvider);
    }
  }
}
