import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/utils/breakpoints.dart';
import '../core/widgets/jealth_logo.dart';

/// A primary destination shown in the navigation bar / rail.
class AppDestination {
  const AppDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;

  /// Display order matches the branch order in the router.
  static const List<AppDestination> all = [
    AppDestination(
      id: 'home',
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      tooltip: 'Home dashboard',
    ),
    AppDestination(
      id: 'classify',
      label: 'Assess',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart_rounded,
      tooltip: 'Health assessment form',
    ),
    AppDestination(
      id: 'history',
      label: 'History',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
      tooltip: 'Saved assessment history',
    ),
    AppDestination(
      id: 'analytics',
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      tooltip: 'Personal assessment insights',
    ),
    AppDestination(
      id: 'learn',
      label: 'Health education',
      icon: Icons.health_and_safety_outlined,
      selectedIcon: Icons.health_and_safety_rounded,
      tooltip: 'Health education',
    ),
  ];
}

/// Responsive frame around the five primary destinations:
/// a bottom navigation bar on narrow windows, a navigation rail on wider
/// ones and an extended, labelled rail on large windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    // Re-selecting the current destination returns to its first screen.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final index = navigationShell.currentIndex;

    final body = _BranchTransition(index: index, child: navigationShell);

    // System back on a secondary destination returns to Home before leaving
    // the app; nested screens are popped by their own navigators first.
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: width < Breakpoints.medium
          ? Scaffold(
              body: body,
              bottomNavigationBar: NavigationBar(
                selectedIndex: index,
                onDestinationSelected: _select,
                destinations: [
                  for (final d in AppDestination.all)
                    NavigationDestination(
                      key: ValueKey('navigation-${d.id}'),
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                      tooltip: d.tooltip,
                    ),
                ],
              ),
            )
          : Scaffold(
              body: Row(
                children: [
                  _SideNavigation(
                    index: index,
                    extended: width >= Breakpoints.large,
                    onSelect: _select,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              ),
            ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.index,
    required this.extended,
    required this.onSelect,
  });

  final int index;
  final bool extended;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        right: false,
        child: NavigationRail(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          extended: extended,
          scrollable: true,
          minExtendedWidth: 220,
          labelType: extended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
            child: JealthWordmark(logoSize: 40, showName: extended),
          ),
          destinations: [
            for (final d in AppDestination.all)
              NavigationRailDestination(
                icon: Tooltip(
                  message: d.tooltip,
                  child: Icon(d.icon, key: ValueKey('navigation-${d.id}')),
                ),
                selectedIcon: Icon(d.selectedIcon),
                label: Text(d.label),
                padding: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
      ),
    );
  }
}

/// Replays a short fade whenever the selected destination changes.
class _BranchTransition extends StatefulWidget {
  const _BranchTransition({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_BranchTransition> createState() => _BranchTransitionState();
}

class _BranchTransitionState extends State<_BranchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(_BranchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0.35);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: widget.child,
    );
  }
}
