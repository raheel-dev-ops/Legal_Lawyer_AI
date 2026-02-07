import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';

final emergencyContactsRepositoryProvider = Provider<EmergencyContactsRepository>((ref) {
  return EmergencyContactsRemoteDataSource(ref.watch(dioProvider));
});

class EmergencyContactsRemoteDataSource implements EmergencyContactsRepository {
  final Dio _dio;

  EmergencyContactsRemoteDataSource(this._dio);

  @override
  Future<List<EmergencyContact>> listContacts() async {
    final response = await _dio.get('/users/me/emergency-contacts');
    return (response.data as List)
        .map((e) => EmergencyContact.fromApi(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<EmergencyContact> createContact({
    required String name,
    required String relation,
    required String phone,
    required String countryCode,
    required bool isPrimary,
  }) async {
    final response = await _dio.post('/users/me/emergency-contacts', data: {
      'name': name,
      'relation': relation,
      'phone': phone,
      'countryCode': countryCode,
      'isPrimary': isPrimary,
    });
    return EmergencyContact.fromApi(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<EmergencyContact> updateContact({
    required int id,
    String? name,
    String? relation,
    String? phone,
    String? countryCode,
    bool? isPrimary,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (relation != null) data['relation'] = relation;
    if (phone != null) data['phone'] = phone;
    if (countryCode != null) data['countryCode'] = countryCode;
    if (isPrimary != null) data['isPrimary'] = isPrimary;
    final response = await _dio.put('/users/me/emergency-contacts/$id', data: data);
    return EmergencyContact.fromApi(Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<void> deleteContact(int id) async {
    await _dio.delete('/users/me/emergency-contacts/$id');
  }
}
