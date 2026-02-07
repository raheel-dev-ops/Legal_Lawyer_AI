import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/theme/app_button_tokens.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../controllers/emergency_contacts_controller.dart';
import '../../domain/models/emergency_contact.dart';

class EmergencyServicesScreen extends ConsumerStatefulWidget {
  const EmergencyServicesScreen({super.key});

  @override
  ConsumerState<EmergencyServicesScreen> createState() => _EmergencyServicesScreenState();
}

class _EmergencyServicesScreenState extends ConsumerState<EmergencyServicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('emergency_services');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final padding = AppResponsive.pagePadding(context);
    final scheme = Theme.of(context).colorScheme;
    final cyberCrimeColor = scheme.tertiary;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            AppResponsive.spacing(context, 28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppResponsive.spacing(context, 44),
                    height: AppResponsive.spacing(context, 44),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        l10n.sosLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 12)),
                  Expanded(
                    child: Text(
                      l10n.emergencyServicesTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    width: AppResponsive.spacing(context, 40),
                    height: AppResponsive.spacing(context, 40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),
              _SosMessageButton(
                title: l10n.sendSosMessage,
                subtitle: l10n.sendSosSubtitle,
                onTap: () => _sendSmsToContacts(context, contactsAsync.value ?? []),
              ),
              SizedBox(height: AppResponsive.spacing(context, 18)),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppResponsive.spacing(context, 12),
                mainAxisSpacing: AppResponsive.spacing(context, 12),
                childAspectRatio: 1.1,
                children: [
                  _ServiceCard(
                    title: l10n.policeService(15),
                    subtitle: l10n.emergencyImmediateResponse,
                    icon: Icons.shield_outlined,
                    color: scheme.primary,
                    onTap: () => _dialNumber(context, '15'),
                  ),
                  _ServiceCard(
                    title: l10n.womenHelplineService(3333),
                    subtitle: l10n.emergencyProtectionServices,
                    icon: Icons.favorite_border,
                    color: scheme.secondary,
                    onTap: () => _dialNumber(context, '3333'),
                  ),
                  _ServiceCard(
                    title: l10n.cyberCrimeService(2255),
                    subtitle: l10n.emergencyDigitalSafety,
                    icon: Icons.fingerprint,
                    color: cyberCrimeColor,
                    onTap: () => _dialNumber(context, '2255'),
                  ),
                  _ServiceCard(
                    title: l10n.rescueService(1122),
                    subtitle: l10n.emergencyMedicalAssistance,
                    icon: Icons.local_hospital_outlined,
                    color: scheme.error,
                    onTap: () => _dialNumber(context, '1122'),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.personalEmergencyContacts,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.push('/emergency/contacts'),
                    child: Text(l10n.edit),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              contactsAsync.when(
                data: (contacts) {
                  if (contacts.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 12)),
                      child: Text(l10n.noContactsYet),
                    );
                  }
                  return Column(
                    children: contacts.map((c) => _ContactCard(contact: c)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Padding(
                  padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 12)),
                  child: Text(l10n.somethingWentWrong),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 20)),
              Text(
                l10n.emergencyTipsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: AppResponsive.spacing(context, 10)),
              _TipItem(text: l10n.emergencyTip1),
              _TipItem(text: l10n.emergencyTip2),
              _TipItem(text: l10n.emergencyTip3),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _dialNumber(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(AppLocalizations.of(context)!.somethingWentWrong)),
      );
    }
  }

  Future<void> _sendSmsToContacts(BuildContext context, List<EmergencyContact> contacts) async {
    if (contacts.isEmpty) {
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(AppLocalizations.of(context)!.sosNoContacts)),
      );
      return;
    }
    final numbers = contacts.map((c) => c.fullNumber).join(',');
    final uri = Uri.parse('sms:$numbers');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(AppLocalizations.of(context)!.somethingWentWrong)),
      );
    }
  }
}

class _SosMessageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SosMessageButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: EdgeInsets.all(AppResponsive.spacing(context, 18)),
        shape: AppButtonTokens.shape,
        textStyle: AppButtonTokens.textStyle,
      ),
      onPressed: onTap,
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering, size: 22),
          SizedBox(width: AppResponsive.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: AppResponsive.spacing(context, 4)),
                Text(subtitle, style: TextStyle(color: scheme.onPrimary.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppResponsive.spacing(context, 44),
                height: AppResponsive.spacing(context, 44),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(height: AppResponsive.spacing(context, 12)),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 6)),
              Flexible(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
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
            backgroundColor: scheme.primary.withOpacity(0.1),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: TextStyle(color: scheme.primary),
            ),
          ),
          SizedBox(width: AppResponsive.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${contact.name} (${contact.relation})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppResponsive.spacing(context, 4)),
                Text(
                  contact.displayNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri(scheme: 'tel', path: contact.fullNumber), mode: LaunchMode.externalApplication),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              minimumSize: const Size(0, AppButtonTokens.minHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(
                horizontal: AppResponsive.spacing(context, 14),
                vertical: AppResponsive.spacing(context, 10),
              ),
              shape: AppButtonTokens.shape,
              textStyle: AppButtonTokens.textStyle,
            ),
            icon: const Icon(Icons.call, size: 18),
            label: Text(AppLocalizations.of(context)!.call),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;

  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppResponsive.spacing(context, 8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: AppResponsive.spacing(context, 6)),
            width: AppResponsive.spacing(context, 6),
            height: AppResponsive.spacing(context, 6),
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          ),
          SizedBox(width: AppResponsive.spacing(context, 10)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
