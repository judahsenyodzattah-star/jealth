import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../services/prediction_service.dart';

/// What the app currently knows about the assessment service.
enum ServiceStatus {
  notConnected('Not connected', Icons.cloud_off_outlined),
  checking('Checking…', Icons.cloud_sync_outlined),
  connected('Connected', Icons.cloud_done_outlined),
  unreachable('Unreachable', Icons.cloud_off_outlined);

  const ServiceStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Current assessment-service status, derived from the configuration and the
/// most recent connectivity check.
final serviceStatusProvider = Provider<ServiceStatus>((ref) {
  if (!ref.watch(predictionServiceProvider).isConfigured) {
    return ServiceStatus.notConnected;
  }
  final health = ref.watch(serviceHealthProvider);
  if (health.isLoading) return ServiceStatus.checking;
  final value = health.value;
  if (value == null) return ServiceStatus.unreachable;
  return switch (value.connection) {
    ServiceConnection.connected => ServiceStatus.connected,
    ServiceConnection.notConfigured => ServiceStatus.notConnected,
    ServiceConnection.unreachable => ServiceStatus.unreachable,
  };
});

/// Small pill showing the assessment-service status.
class ServiceStatusPill extends ConsumerWidget {
  const ServiceStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serviceStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    final colors = StatusColors.of(context);
    final (Color background, Color foreground) = switch (status) {
      ServiceStatus.notConnected => (
        colors.warningContainer,
        colors.onWarningContainer,
      ),
      ServiceStatus.checking => (scheme.surfaceContainerHigh, scheme.onSurface),
      ServiceStatus.connected => (
        colors.successContainer,
        colors.onSuccessContainer,
      ),
      ServiceStatus.unreachable => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };

    return Semantics(
    label: 'Assessment service: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
