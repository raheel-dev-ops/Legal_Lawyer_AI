import '../models/emergency_contact.dart';

abstract class EmergencyContactsRepository {
  Future<List<EmergencyContact>> listContacts();
  Future<EmergencyContact> createContact({
    required String name,
    required String relation,
    required String phone,
    required String countryCode,
    required bool isPrimary,
  });
  Future<EmergencyContact> updateContact({
    required int id,
    String? name,
    String? relation,
    String? phone,
    String? countryCode,
    bool? isPrimary,
  });
  Future<void> deleteContact(int id);
}
