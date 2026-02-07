import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/core/network/dio_provider.dart';
import 'package:legalai_frontend/core/errors/error_mapper.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:legalai_frontend/core/layout/app_responsive.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';

const List<String> _chatProviders = [
  'openai',
  'openrouter',
  'groq',
  'deepseek',
  'grok',
  'anthropic',
];

const Map<String, List<String>> _voiceModelsByProvider = {
  'openai': ['whisper-1'],
  'openrouter': ['openai/gpt-4o-mini-transcribe'],
  'groq': ['whisper-large-v3-turbo', 'whisper-large-v3'],
};

const Map<String, List<String>> _chatModelsByProvider = {
  'openai': [
    'gpt-5.2',
    'gpt-5.2-pro',
    'gpt-5.1',
    'gpt-5',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4.1-mini',
    'gpt-4.1-nano',
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-4-turbo',
    'gpt-3.5-turbo',
    'o1',
    'o1-mini',
    'o1-pro',
    'o3',
    'o3-mini',
    'o3-pro',
    'o4-mini',
  ],
  'openrouter': [
    'anthropic/claude-sonnet-4.5',
    'google/gemini-3-flash-preview',
    'deepseek/deepseek-v3.2',
    'x-ai/grok-code-fast-1',
    'google/gemini-2.5-flash',
    'anthropic/claude-opus-4.5',
    'moonshotai/kimi-k2.5',
    'x-ai/grok-4.1-fast',
    'openai/gpt-oss-120b',
    'google/gemini-2.5-flash-lite-preview-09-2025',
  ],
  'groq': [
    'groq/compound',
    'groq/compound-mini',
    'openai/gpt-oss-120b',
    'openai/gpt-oss-20b',
    'llama-3.1-8b-instant',
    'llama-3.3-70b-versatile',
  ],
  'deepseek': [
    'deepseek-chat',
    'deepseek-reasoner',
  ],
  'grok': [
    'grok-4-1-fast-reasoning',
    'grok-4-1-fast-non-reasoning',
    'grok-4-fast-reasoning',
    'grok-4-fast-non-reasoning',
    'grok-code-fast-1',
    'grok-4',
    'grok-3',
    'grok-3-mini',
    'grok-2-vision-1212',
    'grok-2-image-1212',
    'grok-2-1212',
    'grok-vision-beta',
    'grok-beta',
    'grok-4-0709',
  ],
  'anthropic': [
    'claude-sonnet-4-5-20250929',
    'claude-haiku-4-5-20251001',
    'claude-opus-4-5-20251101',
  ],
};

class LlmSettingsScreen extends ConsumerStatefulWidget {
  const LlmSettingsScreen({super.key});

  @override
  ConsumerState<LlmSettingsScreen> createState() => _LlmSettingsScreenState();
}

class _LlmSettingsScreenState extends ConsumerState<LlmSettingsScreen> with WidgetsBindingObserver {
  static const double _keyboardFallbackRatio = 0.38;
  final _scrollController = ScrollController();
  final _voiceKeyFieldKey = GlobalKey();
  final _chatKeyFieldKey = GlobalKey();
  final _voiceKeyFocusNode = FocusNode();
  final _chatKeyFocusNode = FocusNode();
  final _openaiController = TextEditingController();
  final _openrouterController = TextEditingController();
  final _groqController = TextEditingController();
  final _deepseekController = TextEditingController();
  final _grokController = TextEditingController();
  final _anthropicController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _voiceProvider = 'openai';
  String _voiceModel = '';
  String _chatProvider = 'openai';
  String _chatModel = '';

  bool _showOpenai = false;
  bool _showOpenrouter = false;
  bool _showGroq = false;
  bool _showDeepseek = false;
  bool _showGrok = false;
  bool _showAnthropic = false;
  bool _openaiConfigured = false;
  bool _openrouterConfigured = false;
  bool _groqConfigured = false;
  bool _deepseekConfigured = false;
  bool _grokConfigured = false;
  bool _anthropicConfigured = false;
  double _keyboardInset = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voiceKeyFocusNode.addListener(_handleFocusChange);
    _chatKeyFocusNode.addListener(_handleFocusChange);
    _load();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateKeyboardInset();
    _scrollToFocusedField();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _voiceKeyFocusNode.dispose();
    _chatKeyFocusNode.dispose();
    _openaiController.dispose();
    _openrouterController.dispose();
    _groqController.dispose();
    _deepseekController.dispose();
    _grokController.dispose();
    _anthropicController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    var voiceProvider = 'openai';
    var voiceModel = '';
    var chatProvider = 'openai';
    var chatModel = '';
    var keyStatus = <String, dynamic>{};

    try {
      final response = await dio.get('/users/me/llm-settings');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        voiceProvider = (data['voiceProvider'] as String?) ?? voiceProvider;
        voiceModel = (data['voiceModel'] as String?) ?? '';
        chatProvider = (data['chatProvider'] as String?) ?? chatProvider;
        chatModel = (data['chatModel'] as String?) ?? '';
        final rawKeys = data['keys'];
        if (rawKeys is Map<String, dynamic>) {
          keyStatus = rawKeys;
        }
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      AppNotifications.showSnackBar(
        context,
        SnackBar(content: Text(err.userMessage)),
      );
    }

    final voiceModels = _modelsForVoice(voiceProvider);
    if (voiceProvider == 'auto') {
      voiceModel = '';
    } else if (voiceModel.isEmpty || !voiceModels.contains(voiceModel)) {
      voiceModel = _defaultVoiceModelFor(voiceProvider);
    }
    final models = _modelsFor(chatProvider);
    if (chatModel.isEmpty || !models.contains(chatModel)) {
      chatModel = _defaultModelFor(chatProvider);
    }

    setState(() {
      _voiceProvider = voiceProvider;
      _voiceModel = voiceModel;
      _chatProvider = chatProvider;
      _chatModel = chatModel;
      _openaiConfigured = _isConfigured(keyStatus, 'openai');
      _openrouterConfigured = _isConfigured(keyStatus, 'openrouter');
      _groqConfigured = _isConfigured(keyStatus, 'groq');
      _deepseekConfigured = _isConfigured(keyStatus, 'deepseek');
      _grokConfigured = _isConfigured(keyStatus, 'grok');
      _anthropicConfigured = _isConfigured(keyStatus, 'anthropic');
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final dio = ref.read(dioProvider);
    final keys = _buildKeysPayload();

    if (mounted) {
      try {
        await dio.put('/users/me/llm-settings', data: {
          'voiceProvider': _voiceProvider,
          'voiceModel': _voiceModel,
          'chatProvider': _chatProvider,
          'chatModel': _chatModel,
          if (keys.isNotEmpty) 'keys': keys,
        });
        _openaiController.clear();
        _openrouterController.clear();
        _groqController.clear();
        _deepseekController.clear();
        _grokController.clear();
        _anthropicController.clear();
        await _load();
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(
          context,
          SnackBar(content: Text(l10n.voiceSettingsSaved)),
        );
      } catch (e) {
        final err = ErrorMapper.from(e);
        AppNotifications.showSnackBar(
          context,
          SnackBar(content: Text(err.userMessage)),
        );
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final chatModels = _modelsFor(_chatProvider);
    final keyboardInset = _effectiveKeyboardInset(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.voiceInputSettingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: AppResponsive.pagePadding(context).copyWith(
                bottom: AppResponsive.pagePadding(context).bottom + keyboardInset,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  l10n.voiceInputSettingsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                _sectionCard(
                  context,
                  title: l10n.llmVoiceSectionTitle,
                  subtitle: l10n.voiceProviderAutoNote,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _voiceProvider,
                      decoration: InputDecoration(
                        labelText: l10n.voiceProviderLabel,
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'openai',
                          child: Text(_voiceProviderLabel(l10n, 'openai'), overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'openrouter',
                          child: Text(_voiceProviderLabel(l10n, 'openrouter'), overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'groq',
                          child: Text(_voiceProviderLabel(l10n, 'groq'), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _voiceProvider = value;
                          final models = _modelsForVoice(value);
                          if (!models.contains(_voiceModel)) {
                            _voiceModel = _defaultVoiceModelFor(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    DropdownButtonFormField<String>(
                      value: _voiceModel.isEmpty ? null : _voiceModel,
                      decoration: InputDecoration(
                        labelText: l10n.voiceModelLabel,
                      ),
                      isExpanded: true,
                      items: _modelsForVoice(_voiceProvider)
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _voiceModel = value);
                      },
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    _providerKeyField(
                      context,
                      _voiceProvider,
                      fieldKey: _voiceKeyFieldKey,
                      focusNode: _voiceKeyFocusNode,
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                _sectionCard(
                  context,
                  title: l10n.llmChatSectionTitle,
                  subtitle: '',
                  children: [
                    DropdownButtonFormField<String>(
                      value: _chatProvider,
                      decoration: InputDecoration(
                        labelText: l10n.chatProviderLabel,
                      ),
                      isExpanded: true,
                      items: _chatProviders
                          .map(
                            (provider) => DropdownMenuItem(
                              value: provider,
                              child: Text(_providerLabel(l10n, provider), overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _chatProvider = value;
                          final models = _modelsFor(value);
                          if (!models.contains(_chatModel)) {
                            _chatModel = _defaultModelFor(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    DropdownButtonFormField<String>(
                      value: chatModels.contains(_chatModel) ? _chatModel : (chatModels.isNotEmpty ? chatModels.first : null),
                      decoration: InputDecoration(
                        labelText: l10n.chatModelLabel,
                      ),
                      isExpanded: true,
                      items: chatModels
                          .map(
                            (model) => DropdownMenuItem(
                              value: model,
                              child: Text(model, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: chatModels.isEmpty
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _chatModel = value);
                            },
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 12)),
                    _providerKeyField(
                      context,
                      _chatProvider,
                      fieldKey: _chatKeyFieldKey,
                      focusNode: _chatKeyFocusNode,
                    ),
                  ],
                ),
                SizedBox(height: AppResponsive.spacing(context, 20)),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? l10n.saving : l10n.save),
                ),
              ],
            ),
    );
  }

  List<String> _modelsFor(String provider) {
    return _chatModelsByProvider[provider] ?? const [];
  }

  List<String> _modelsForVoice(String provider) {
    return _voiceModelsByProvider[provider] ?? const [];
  }

  String _defaultModelFor(String provider) {
    final models = _modelsFor(provider);
    return models.isNotEmpty ? models.first : '';
  }

  String _defaultVoiceModelFor(String provider) {
    final models = _modelsForVoice(provider);
    return models.isNotEmpty ? models.first : '';
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final hasSubtitle = subtitle.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, title),
          if (hasSubtitle) ...[
            SizedBox(height: AppResponsive.spacing(context, 6)),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          SizedBox(height: AppResponsive.spacing(context, 14)),
          ...children,
        ],
      ),
    );
  }

  String _voiceProviderLabel(AppLocalizations l10n, String provider) {
    final base = _providerLabel(l10n, provider);
    return provider == 'openai' ? '$base (Default)' : base;
  }

  String _providerLabel(AppLocalizations l10n, String provider) {
    switch (provider) {
      case 'openai':
        return l10n.voiceProviderOpenai;
      case 'openrouter':
        return l10n.voiceProviderOpenrouter;
      case 'groq':
        return l10n.voiceProviderGroq;
      case 'deepseek':
        return l10n.providerDeepseek;
      case 'grok':
        return l10n.providerGrok;
      case 'anthropic':
        return l10n.providerAnthropic;
      default:
        return provider;
    }
  }

  Widget _providerKeyField(
    BuildContext context,
    String provider, {
    GlobalKey? fieldKey,
    FocusNode? focusNode,
  }) {
    switch (provider) {
      case 'openai':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.openaiApiKeyLabel,
          controller: _openaiController,
          showValue: _showOpenai,
          onToggle: () => setState(() => _showOpenai = !_showOpenai),
          configured: _openaiConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      case 'openrouter':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.openrouterApiKeyLabel,
          controller: _openrouterController,
          showValue: _showOpenrouter,
          onToggle: () => setState(() => _showOpenrouter = !_showOpenrouter),
          configured: _openrouterConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      case 'groq':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.groqApiKeyLabel,
          controller: _groqController,
          showValue: _showGroq,
          onToggle: () => setState(() => _showGroq = !_showGroq),
          configured: _groqConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      case 'deepseek':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.deepseekApiKeyLabel,
          controller: _deepseekController,
          showValue: _showDeepseek,
          onToggle: () => setState(() => _showDeepseek = !_showDeepseek),
          configured: _deepseekConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      case 'grok':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.grokApiKeyLabel,
          controller: _grokController,
          showValue: _showGrok,
          onToggle: () => setState(() => _showGrok = !_showGrok),
          configured: _grokConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      case 'anthropic':
        return _keyField(
          context,
          label: AppLocalizations.of(context)!.anthropicApiKeyLabel,
          controller: _anthropicController,
          showValue: _showAnthropic,
          onToggle: () => setState(() => _showAnthropic = !_showAnthropic),
          configured: _anthropicConfigured,
          fieldKey: fieldKey,
          focusNode: focusNode,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _keyField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required bool showValue,
    required VoidCallback onToggle,
    required bool configured,
    GlobalKey? fieldKey,
    FocusNode? focusNode,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      key: fieldKey,
      focusNode: focusNode,
      obscureText: !showValue,
      scrollPadding: EdgeInsets.only(
        bottom: _effectiveKeyboardInset(context) + AppResponsive.spacing(context, 24),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: configured ? l10n.voiceSettingsSaved : l10n.voiceApiKeyHint,
        suffixIcon: IconButton(
          icon: Icon(showValue ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
      ),
      onTap: () => _scrollToField(fieldKey),
    );
  }

  bool _isConfigured(Map<String, dynamic> keys, String provider) {
    final entry = keys[provider];
    if (entry is Map<String, dynamic>) {
      return entry['configured'] == true;
    }
    return false;
  }

  Map<String, String> _buildKeysPayload() {
    final keys = <String, String>{};
    final openai = _openaiController.text.trim();
    final openrouter = _openrouterController.text.trim();
    final groq = _groqController.text.trim();
    final deepseek = _deepseekController.text.trim();
    final grok = _grokController.text.trim();
    final anthropic = _anthropicController.text.trim();
    if (openai.isNotEmpty) keys['openai'] = openai;
    if (openrouter.isNotEmpty) keys['openrouter'] = openrouter;
    if (groq.isNotEmpty) keys['groq'] = groq;
    if (deepseek.isNotEmpty) keys['deepseek'] = deepseek;
    if (grok.isNotEmpty) keys['grok'] = grok;
    if (anthropic.isNotEmpty) keys['anthropic'] = anthropic;
    return keys;
  }

  void _scrollToField(GlobalKey? key) {
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final renderObject = ctx.findRenderObject();
      if (renderObject is! RenderBox) return;

      final fieldOffset = renderObject.localToGlobal(Offset.zero);
      final fieldBottom = fieldOffset.dy + renderObject.size.height;
      final media = MediaQuery.of(context);
      final keyboardTop = media.size.height - media.viewInsets.bottom;
      final safePadding = AppResponsive.spacing(context, 16);
      final overlap = fieldBottom + safePadding - keyboardTop;

      if (overlap <= 0) return;
      final position = _scrollController.position;
      final target = (_scrollController.offset + overlap).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {});
    _scrollToFocusedField();
  }

  void _scrollToFocusedField() {
    if (_chatKeyFocusNode.hasFocus) {
      _scrollToField(_chatKeyFieldKey);
    } else if (_voiceKeyFocusNode.hasFocus) {
      _scrollToField(_voiceKeyFieldKey);
    }
  }

  void _updateKeyboardInset() {
    if (!mounted) return;
    final view = View.of(context);
    final inset = view.viewInsets.bottom / view.devicePixelRatio;
    if (inset == _keyboardInset) return;
    setState(() => _keyboardInset = inset);
  }

  bool get _isKeyFieldFocused => _voiceKeyFocusNode.hasFocus || _chatKeyFocusNode.hasFocus;

  double _effectiveKeyboardInset(BuildContext context) {
    if (_keyboardInset > 0) return _keyboardInset;
    if (_isKeyFieldFocused) {
      return MediaQuery.of(context).size.height * _keyboardFallbackRatio;
    }
    return 0;
  }
}
