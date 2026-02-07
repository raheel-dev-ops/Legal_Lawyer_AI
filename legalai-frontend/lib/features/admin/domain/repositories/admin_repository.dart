import 'package:file_picker/file_picker.dart';
import 'package:legalai_frontend/features/directory/domain/models/lawyer_model.dart';
import '../models/admin_stats_model.dart';

abstract class AdminRepository {
  Future<List<Map<String, dynamic>>> getUsers({int page = 1, int? perPage});
  Future<int> getUsersTotal();
  Future<void> createUser(Map<String, dynamic> data);
  Future<void> updateUser(int id, Map<String, dynamic> data);
  Future<void> deleteUser(int id);

  Future<List<Lawyer>> getLawyers({int page = 1, int? perPage});
  Future<int> getLawyersTotal();
  Future<Lawyer> getLawyer(int id);
  Future<void> createLawyer(Map<String, dynamic> data, PlatformFile imageFile);
  Future<void> updateLawyer(int id, Map<String, dynamic> data, PlatformFile? imageFile);
  Future<void> deactivateLawyer(int id);
  Future<List<String>> getLawyerCategories();

  Future<List<KnowledgeSource>> getKnowledgeSources();
  Future<void> uploadKnowledge(PlatformFile file, String language);
  Future<void> ingestUrl(String title, String url, String language);
  Future<void> retrySource(int id);
  Future<void> deleteSource(int id);

  Future<RagMetrics> getRagMetrics({int days = 7});
  Future<List<Map<String, dynamic>>> getRagQueries({
    int page = 1,
    int days = 7,
    int? perPage,
    String? decision,
    bool? inDomain,
    bool? safeMode,
    bool? errorOnly,
    int? minTimeMs,
  });
  Future<Map<String, dynamic>> getRagQueriesPage({
    int page = 1,
    int days = 7,
    int? perPage,
    String? decision,
    bool? inDomain,
    bool? safeMode,
    bool? errorOnly,
    int? minTimeMs,
  });
  Future<Map<String, dynamic>> getRagQueryDetail(int id);

  Future<List<Map<String, dynamic>>> getContactMessages({int page = 1, int? perPage});
  Future<int> getContactMessagesTotal();
  Future<Map<String, dynamic>> getContactMessage(int id);
  Future<List<Map<String, dynamic>>> getFeedback({
    int page = 1,
    int? perPage,
    String? sort,
    bool? read,
    int? rating,
    int? minRating,
    int? maxRating,
  });
  Future<Map<String, dynamic>> getFeedbackPage({
    int page = 1,
    int? perPage,
    String? sort,
    bool? read,
    int? rating,
    int? minRating,
    int? maxRating,
  });
  Future<int> getFeedbackTotal();
  Future<Map<String, dynamic>> getFeedbackSummary();
  Future<Map<String, dynamic>> getFeedbackDetail(int id);
  Future<void> markFeedbackRead(int id, {required bool isRead});
}
