import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/content_models.dart';
import '../../domain/repositories/content_repository.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/content/content_sync_provider.dart';

part 'content_controller.g.dart';

@riverpod
Future<List<LegalRight>> rights(Ref ref, {String? category}) async {
  final appLanguage = ref.watch(appLanguageProvider);
  final user = ref.watch(authControllerProvider).value;
  final language = appLanguage.isNotEmpty ? appLanguage : (user?.language ?? 'en');
  await ref.watch(contentSyncProvider.future);
  return ref.watch(contentRepositoryProvider).getRights(category: category, language: language);
}

@riverpod
Future<List<LegalTemplate>> templates(Ref ref, {String? category}) async {
  final appLanguage = ref.watch(appLanguageProvider);
  final user = ref.watch(authControllerProvider).value;
  final language = appLanguage.isNotEmpty ? appLanguage : (user?.language ?? 'en');
  await ref.watch(contentSyncProvider.future);
  return ref.watch(contentRepositoryProvider).getTemplates(category: category, language: language);
}

@riverpod
Future<List<LegalPathway>> pathways(Ref ref, {String? category}) async {
  final appLanguage = ref.watch(appLanguageProvider);
  final user = ref.watch(authControllerProvider).value;
  final language = appLanguage.isNotEmpty ? appLanguage : (user?.language ?? 'en');
  await ref.watch(contentSyncProvider.future);
  return ref.watch(contentRepositoryProvider).getPathways(category: category, language: language);
}
