import 'dart:async';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/error_mapper.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_stats_model.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

const int _maxUploadBytes = 30 * 1024 * 1024;
const List<String> _allowedExts = [
  'txt',
  'csv',
  'tsv',
  'json',
  'pdf',
  'docx',
  'xlsx',
  'png',
  'jpg',
  'jpeg',
  'svg',
];

class AdminKnowledgeScreen extends ConsumerStatefulWidget {
  const AdminKnowledgeScreen({super.key});

  @override
  ConsumerState<AdminKnowledgeScreen> createState() => _AdminKnowledgeScreenState();
}

class _AdminKnowledgeScreenState extends ConsumerState<AdminKnowledgeScreen> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _updatePolling(List<KnowledgeSource> sources) {
    final needsPolling = sources.any((s) => s.status == 'processing' || s.status == 'queued');
    if (needsPolling && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        ref.invalidate(knowledgeSourcesProvider);
      });
      return;
    }
    if (!needsPolling && _pollTimer != null) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(knowledgeSourcesProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminKnowledgeBase,
      subtitle: l10n.adminKnowledgeSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAddSourceDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminAddSource),
        ),
      ],
      body: sourcesAsync.when(
        data: (sources) {
          _updatePolling(sources);
          if (sources.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoSourcesTitle,
                message: l10n.adminNoSourcesMessage,
                icon: Icons.auto_awesome_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final source = sources[index];
              final languageLabel = _languageLabel(l10n, source.language);
              final statusLabel = _statusLabel(l10n, source.status);
              final statusColor = source.status == 'done'
                  ? AdminColors.success
                  : source.status == 'failed'
                      ? AdminColors.error
                      : AdminColors.warning;
              return AdminCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        source.type == 'url' ? Icons.link : Icons.description_outlined,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$languageLabel - $statusLabel',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (source.status == 'failed')
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: AdminColors.primary,
                        onPressed: () => ref.read(adminActionsProvider.notifier).retrySource(source.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AdminColors.error,
                      onPressed: () => ref.read(adminActionsProvider.notifier).deleteSource(source.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }

  void _showAddSourceDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    String language = 'en';
    bool isUrl = true;
    PlatformFile? file;
    bool isSubmitting = false;
    String? formError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => PopScope(
          canPop: !isSubmitting,
          child: AlertDialog(
            title: Text(l10n.adminAddKnowledgeSource),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSubmitting) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                if (formError != null) ...[
                  Text(
                    formError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                ],
                SwitchListTile(
                  value: isUrl,
                  title: Text(isUrl ? l10n.adminUrlSource : l10n.adminFileUpload),
                  onChanged: isSubmitting ? null : (value) => setState(() => isUrl = value),
                ),
                DropdownButtonFormField<String>(
                  value: language,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu)),
                  ],
                  onChanged: isSubmitting ? null : (value) => setState(() => language = value ?? 'en'),
                ),
                const SizedBox(height: 8),
                if (isUrl) ...[
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: l10n.title),
                    enabled: !isSubmitting,
                  ),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(labelText: l10n.adminUrl),
                    enabled: !isSubmitting,
                  ),
                ] else ...[
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: _allowedExts,
                              withData: kIsWeb,
                            );
                            if (result == null || result.files.isEmpty) {
                              return;
                            }
                            final selected = result.files.single;
                            final error = _validateKnowledgeFile(selected, l10n);
                            if (error != null) {
                              if (context.mounted) {
                                AppNotifications.showSnackBar(context, SnackBar(content: Text(error)));
                              }
                              return;
                            }
                            setState(() => file = selected);
                          },
                    child: Text(file == null ? l10n.adminSelectFile : l10n.adminChangeFile),
                  ),
                  if (file != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        file!.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() {
                          isSubmitting = true;
                          formError = null;
                        });
                        try {
                          if (isUrl) {
                            final title = titleController.text.trim();
                            final url = urlController.text.trim();
                            if (title.isEmpty || url.isEmpty) {
                              if (context.mounted) {
                                formError = l10n.adminTitleUrlRequired;
                                AppNotifications.showSnackBar(
                                  context,
                                  SnackBar(content: Text(formError!)),
                                );
                                setState(() {});
                              }
                              return;
                            }
                            if (!_isValidUrl(url)) {
                              if (context.mounted) {
                                formError = l10n.adminInvalidUrl;
                                AppNotifications.showSnackBar(
                                  context,
                                  SnackBar(content: Text(formError!)),
                                );
                                setState(() {});
                              }
                              return;
                            }
                            await ref.read(adminActionsProvider.notifier).ingestUrl(
                                  title,
                                  url,
                                  language,
                                );
                          } else {
                            if (file == null) {
                              if (context.mounted) {
                                formError = l10n.adminFileRequired;
                                AppNotifications.showSnackBar(
                                  context,
                                  SnackBar(content: Text(formError!)),
                                );
                                setState(() {});
                              }
                              return;
                            }
                            final error = _validateKnowledgeFile(file!, l10n);
                            if (error != null) {
                              if (context.mounted) {
                                formError = error;
                                AppNotifications.showSnackBar(context, SnackBar(content: Text(formError!)));
                                setState(() {});
                              }
                              return;
                            }
                          await ref.read(adminActionsProvider.notifier).uploadFile(file!, language);
                        }
                        try {
                          await ref.refresh(knowledgeSourcesProvider.future);
                        } catch (_) {
                          ref.invalidate(knowledgeSourcesProvider);
                        }
                        if (context.mounted) {
                          final navigator = Navigator.of(dialogContext);
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                        }
                        } catch (e) {
                          final err = ErrorMapper.from(e);
                          formError = err.userMessage == l10n.somethingWentWrong
                              ? e.toString()
                              : err.userMessage;
                          if (context.mounted) {
                            AppNotifications.showSnackBar(
                              context,
                              SnackBar(content: Text(formError!)),
                            );
                            setState(() {});
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.adminIngest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _languageLabel(AppLocalizations l10n, String language) {
  switch (language.toLowerCase()) {
    case 'en':
      return l10n.languageEnglish;
    case 'ur':
      return l10n.languageUrdu;
    default:
      return language;
  }
}

String _statusLabel(AppLocalizations l10n, String status) {
  switch (status.toLowerCase()) {
    case 'done':
      return l10n.adminStatusDone;
    case 'failed':
      return l10n.adminStatusFailed;
    case 'processing':
      return l10n.adminStatusProcessing;
    default:
      return status;
  }
}

String _fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String? _validateKnowledgeFile(PlatformFile file, AppLocalizations l10n) {
  final ext = _fileExtension(file.name);
  if (ext.isEmpty || !_allowedExts.contains(ext)) {
    return l10n.adminFileTypeNotAllowed;
  }
  if (file.size > _maxUploadBytes) {
    return l10n.adminFileTooLarge;
  }
  if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
    return l10n.adminFileDataMissing;
  }
  return null;
}

bool _isValidUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  return uri.host.isNotEmpty;
}
