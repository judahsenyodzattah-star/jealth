import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/service_status.dart';
import '../../../services/prediction_service.dart';
import '../providers/api_settings_controller.dart';

/// Lets the user point the app at a running prediction service and test the
/// connection. This is how the FastAPI address is configured at runtime.
class ServiceSettingsCard extends ConsumerStatefulWidget {
  const ServiceSettingsCard({super.key});

  @override
  ConsumerState<ServiceSettingsCard> createState() =>
      _ServiceSettingsCardState();
}

class _ServiceSettingsCardState extends ConsumerState<ServiceSettingsCard> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(apiSettingsControllerProvider) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    final problem = await ref
        .read(apiSettingsControllerProvider.notifier)
        .setBaseUrl(_controller.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = problem;
    });
    if (problem != null) return;
    final saved = ref.read(apiSettingsControllerProvider);
    _controller.text = saved ?? '';
    ref.invalidate(serviceHealthProvider);
    showAppSnackBar(
      context,
      saved == null
          ? 'Service address removed.'
          : 'Assessment service saved. Checking availability…',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final config = ref.watch(apiConfigProvider);
    final saved = ref.watch(apiSettingsControllerProvider);
    final health = ref.watch(serviceHealthProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final usingBuildDefault = saved == null && config.isConfigured;
    final cleartext = config.baseUrl?.startsWith('http://') ?? false;

    final String statusText;
    if (!config.isConfigured) {
      statusText = 'No assessment service is configured yet.';
    } else if (health.isLoading) {
      statusText = 'Checking assessment service availability…';
    } else {
      final value = health.value;
      if (value != null && value.isConnected) {
        statusText = 'Assessment service is available.';
      } else {
        statusText = 'Assessment service unavailable. Please try again or check Settings.';
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Assessment service',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const ServiceStatusPill(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Connect J\'ealth to the service that processes assessments. '
            'Save a custom address to override the configured default.',
            style: muted,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('service-url-field'),
            controller: _controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _save(),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              labelText: 'Service address',
              hintText: 'http://localhost:8000',
              prefixIcon: const Icon(Icons.link_rounded),
              errorText: _error,
              helperText: usingBuildDefault
                  ? 'Using the address set when the app was built: '
                        '${config.baseUrl}'
                  : 'This address is used only when you request an assessment.',
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('service-url-save'),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save address'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('service-test'),
                onPressed: config.isConfigured && !health.isLoading
                    ? () => ref.invalidate(serviceHealthProvider)
                    : null,
                icon: const Icon(Icons.network_check_rounded),
                label: const Text('Test connection'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              statusText,
              key: const ValueKey('service-status-text'),
              style: muted,
            ),
          ),
          if (cleartext) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.lock_open_rounded,
                    size: 18,
                    color: status.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This address uses http, so measurements are sent '
                    'unencrypted. Use it only for a service on your own '
                    'computer or network; use https anywhere else.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
