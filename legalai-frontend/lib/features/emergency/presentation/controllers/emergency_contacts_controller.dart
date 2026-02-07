import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/datasources/emergency_contacts_remote_data_source.dart';
import '../../domain/models/emergency_contact.dart';
import '../../domain/repositories/emergency_contacts_repository.dart';

final emergencyContactsProvider = FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
  return ref.watch(emergencyContactsRepositoryProvider).listContacts();
});

class EmergencyContactsController {
  final Ref _ref;

  EmergencyContactsController(this._ref);

  Future<EmergencyContact> create({
    required String name,
    required String relation,
    required String phone,
    required String countryCode,
    required bool isPrimary,
  }) async {
    _logger().info('emergency.contact.create.start');
    final contact = await _repo().createContact(
      name: name,
      relation: relation,
      phone: phone,
      countryCode: countryCode,
      isPrimary: isPrimary,
    );
    _ref.invalidate(emergencyContactsProvider);
    _logger().info('emergency.contact.create.success');
    return contact;
  }

  Future<EmergencyContact> update({
    required int id,
    String? name,
    String? relation,
    String? phone,
    String? countryCode,
    bool? isPrimary,
  }) async {
    _logger().info('emergency.contact.update.start');
    final contact = await _repo().updateContact(
      id: id,
      name: name,
      relation: relation,
      phone: phone,
      countryCode: countryCode,
      isPrimary: isPrimary,
    );
    _ref.invalidate(emergencyContactsProvider);
    _logger().info('emergency.contact.update.success');
    return contact;
  }

  Future<void> delete(int id) async {
    _logger().info('emergency.contact.delete.start');
    await _repo().deleteContact(id);
    _ref.invalidate(emergencyContactsProvider);
    _logger().info('emergency.contact.delete.success');
  }

  AppLogger _logger() => _ref.read(appLoggerProvider);
  EmergencyContactsRepository _repo() => _ref.read(emergencyContactsRepositoryProvider);
}

final emergencyContactsControllerProvider = Provider<EmergencyContactsController>((ref) {
  return EmergencyContactsController(ref);
});
