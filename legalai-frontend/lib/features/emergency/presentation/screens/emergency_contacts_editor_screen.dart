import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/emergency_contact.dart';
import '../controllers/emergency_contacts_controller.dart';

class EmergencyContactsEditorScreen extends ConsumerStatefulWidget {
  const EmergencyContactsEditorScreen({super.key});

  @override
  ConsumerState<EmergencyContactsEditorScreen> createState() => _EmergencyContactsEditorScreenState();
}

class _EmergencyContactsEditorScreenState extends ConsumerState<EmergencyContactsEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalEmergencyContacts)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final contacts = contactsAsync.value ?? [];
          if (contacts.length >= 5) {
            AppNotifications.showSnackBar(context,
              SnackBar(content: Text(l10n.maxContactsReached)),
            );
            return;
          }
          await _openForm(context);
        },
        child: const Icon(Icons.add),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          if (contacts.isEmpty) {
            return Center(child: Text(l10n.noContactsYet));
          }
          return ListView.separated(
            padding: AppResponsive.pagePadding(context),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Container(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 14)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppResponsive.spacing(context, 22),
                      backgroundColor: AppPalette.primary.withOpacity(0.1),
                      child: Text(
                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                        style: TextStyle(color: AppPalette.primary),
                      ),
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (contact.isPrimary)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppResponsive.spacing(context, 8),
                                    vertical: AppResponsive.spacing(context, 4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.primaryLabel,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppPalette.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppResponsive.spacing(context, 4)),
                          Text(
                            '${contact.relation} • ${contact.displayNumber}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openForm(context, contact: contact);
                        }
                        if (value == 'delete') {
                          await _confirmDelete(context, contact);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.somethingWentWrong)),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {EmergencyContact? contact}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<_ContactInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ContactFormSheet(contact: contact),
    );
    if (result == null) return;
    final controller = ref.read(emergencyContactsControllerProvider);
    try {
      if (contact == null) {
        await controller.create(
          name: result.name,
          relation: result.relation,
          phone: result.phone,
          countryCode: result.countryCode,
          isPrimary: result.isPrimary,
        );
      } else {
        await controller.update(
          id: contact.id,
          name: result.name,
          relation: result.relation,
          phone: result.phone,
          countryCode: result.countryCode,
          isPrimary: result.isPrimary,
        );
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, EmergencyContact contact) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteContactTitle),
        content: Text(l10n.deleteContactConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(emergencyContactsControllerProvider).delete(contact.id);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }
}

class _ContactInput {
  final String name;
  final String relation;
  final String phone;
  final String countryCode;
  final bool isPrimary;

  _ContactInput({
    required this.name,
    required this.relation,
    required this.phone,
    required this.countryCode,
    required this.isPrimary,
  });
}

class _ContactFormSheet extends StatefulWidget {
  final EmergencyContact? contact;

  const _ContactFormSheet({this.contact});

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _phoneController;
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _relationController = TextEditingController(text: widget.contact?.relation ?? '');
    _countryCodeController = TextEditingController(text: widget.contact?.countryCode ?? '+92');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _isPrimary = widget.contact?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final padding = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppResponsive.spacing(context, 16),
        right: AppResponsive.spacing(context, 16),
        bottom: padding.bottom + AppResponsive.spacing(context, 20),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppResponsive.spacing(context, 8)),
                Text(
                  widget.contact == null ? l10n.newContactTitle : l10n.editContactTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.name),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                ),
                SizedBox(height: AppResponsive.spacing(context, 12)),
                TextFormField(
                  controller: _relationController,
                  decoration: InputDecoration(labelText: l10n.relationLabel),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                ),
                SizedBox(height: AppResponsive.spacing(context, 12)),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _countryCodeController,
                        decoration: InputDecoration(labelText: l10n.countryCodeLabel),
                        validator: _validateCountryCode,
                      ),
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 12)),
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: l10n.phone),
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.spacing(context, 12)),
                SwitchListTile.adaptive(
                  value: _isPrimary,
                  onChanged: (v) => setState(() => _isPrimary = v),
                  title: Text(l10n.primaryLabel),
                  contentPadding: EdgeInsets.zero,
                ),
                SizedBox(height: AppResponsive.spacing(context, 12)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(l10n.saveContact),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateCountryCode(String? value) {
    final v = (value ?? '').replaceAll(' ', '');
    if (v == '+92' || v == '92') return null;
    return AppLocalizations.of(context)!.invalidCountryCode;
  }

  String? _validatePhone(String? value) {
    final normalized = _normalizePhone(value ?? '');
    if (normalized == null) return AppLocalizations.of(context)!.validNumber;
    return null;
  }

  String? _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\\D'), '');
    if (digits.startsWith('92')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length != 10) return null;
    if (!digits.startsWith('3')) return null;
    return digits;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final normalizedPhone = _normalizePhone(_phoneController.text.trim())!;
    final country = _countryCodeController.text.trim() == '92' ? '+92' : _countryCodeController.text.trim();
    Navigator.pop(
      context,
      _ContactInput(
        name: _nameController.text.trim(),
        relation: _relationController.text.trim(),
        phone: normalizedPhone,
        countryCode: country,
        isPrimary: _isPrimary,
      ),
    );
  }
}
