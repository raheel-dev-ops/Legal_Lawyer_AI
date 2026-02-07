import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/layout/app_responsive.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(l10n);
    final query = _normalize(_query);
    final scored = query.isEmpty
        ? items.map((item) => _ScoredItem(item, 0)).toList()
        : items
            .map((item) => _ScoredItem(item, _scoreItem(query, item)))
            .where((item) => item.score > 0)
            .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
      ),
      body: SafeArea(
        child: scored.isEmpty
            ? Center(
                child: Text(
                  l10n.searchNoResults,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: scored.length,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  final item = scored[index].item;
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.push(item.route),
                      child: Padding(
                        padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                        child: Row(
                          children: [
                            Container(
                              width: AppResponsive.spacing(context, 48),
                              height: AppResponsive.spacing(context, 48),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(item.icon, color: item.color),
                            ),
                            SizedBox(width: AppResponsive.spacing(context, 14)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: AppResponsive.spacing(context, 4)),
                                  Text(
                                    item.subtitle,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class SearchItem {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  SearchItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

class _ScoredItem {
  final SearchItem item;
  final int score;

  _ScoredItem(this.item, this.score);
}

List<SearchItem> _buildItems(AppLocalizations l10n) {
  return [
    SearchItem(
      title: l10n.legalRights,
      subtitle: l10n.rights,
      route: '/browse?tab=rights',
      icon: Icons.gavel,
      color: AppPalette.secondary,
      keywords: [l10n.legalRights, l10n.rights, 'rights', 'legal rights'],
    ),
    SearchItem(
      title: l10n.templates,
      subtitle: l10n.selectTemplate,
      route: '/browse?tab=templates',
      icon: Icons.description,
      color: AppPalette.info,
      keywords: [l10n.templates, 'templates', 'template'],
    ),
    SearchItem(
      title: l10n.pathways,
      subtitle: l10n.legalPathway,
      route: '/browse?tab=pathways',
      icon: Icons.timeline,
      color: AppPalette.success,
      keywords: [l10n.pathways, 'pathways', 'pathway'],
    ),
    SearchItem(
      title: l10n.lawyers,
      subtitle: l10n.findLawyer,
      route: '/directory',
      icon: Icons.people_alt_outlined,
      color: AppPalette.primary,
      keywords: [l10n.lawyers, 'lawyers', 'lawyer'],
    ),
    SearchItem(
      title: l10n.myDrafts,
      subtitle: l10n.draftsSubtitle,
      route: '/drafts',
      icon: Icons.description_outlined,
      color: AppPalette.tertiary,
      keywords: [l10n.myDrafts, l10n.drafts, 'drafts'],
    ),
    SearchItem(
      title: l10n.checklists,
      subtitle: l10n.legalChecklists,
      route: '/checklists',
      icon: Icons.checklist_outlined,
      color: AppPalette.warning,
      keywords: [l10n.checklists, 'checklists', 'checklist'],
    ),
    SearchItem(
      title: l10n.reminders,
      subtitle: l10n.remindersSubtitle,
      route: '/reminders',
      icon: Icons.notifications_outlined,
      color: AppPalette.info,
      keywords: [l10n.reminders, 'reminders', 'reminder'],
    ),
    SearchItem(
      title: l10n.bookmarks,
      subtitle: l10n.bookmarksSubtitle,
      route: '/bookmarks',
      icon: Icons.bookmark_border,
      color: AppPalette.secondary,
      keywords: [l10n.bookmarks, 'bookmarks', 'bookmark'],
    ),
    SearchItem(
      title: l10n.support,
      subtitle: l10n.helpSupport,
      route: '/support',
      icon: Icons.support_agent_outlined,
      color: AppPalette.primary,
      keywords: [l10n.support, l10n.helpSupport, 'support'],
    ),
    SearchItem(
      title: l10n.emergencyServices,
      subtitle: l10n.emergencyServicesSubtitle,
      route: '/emergency',
      icon: Icons.warning_amber_rounded,
      color: AppPalette.error,
      keywords: [l10n.emergencyServices, 'emergency', 'sos'],
    ),
    SearchItem(
      title: l10n.activityHistory,
      subtitle: l10n.activityLog,
      route: '/activity',
      icon: Icons.history,
      color: AppPalette.tertiary,
      keywords: [l10n.activityHistory, l10n.activityLog, 'activity', 'history'],
    ),
    SearchItem(
      title: l10n.chat,
      subtitle: l10n.conversations,
      route: '/chat',
      icon: Icons.chat_bubble_outline,
      color: AppPalette.primary,
      keywords: [l10n.chat, 'chat', 'ai'],
    ),
    SearchItem(
      title: l10n.profile,
      subtitle: l10n.settingsTitle,
      route: '/profile',
      icon: Icons.settings_outlined,
      color: AppPalette.tertiary,
      keywords: [l10n.profile, l10n.settingsTitle, 'settings'],
    ),
  ];
}

int _scoreItem(String query, SearchItem item) {
  if (query.isEmpty) return 1;
  final targets = <String>[
    item.title,
    item.subtitle,
    ...item.keywords,
  ].map(_normalize).toList();

  var best = 0;
  for (final t in targets) {
    if (t.isEmpty) continue;
    if (t.contains(query)) {
      final score = 100 - t.indexOf(query);
      if (score > best) best = score;
      continue;
    }
    if (_tokensMatch(query, t)) {
      if (80 > best) best = 80;
      continue;
    }
    if (_isSubsequence(query, t)) {
      if (60 > best) best = 60;
    }
  }
  return best;
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _tokensMatch(String query, String text) {
  final q = query.split(' ');
  for (final token in q) {
    if (token.isEmpty) continue;
    if (!text.contains(token)) return false;
  }
  return true;
}

bool _isSubsequence(String query, String text) {
  var qi = 0;
  for (var i = 0; i < text.length && qi < query.length; i++) {
    if (text[i] == query[qi]) {
      qi++;
    }
  }
  return qi == query.length;
}
