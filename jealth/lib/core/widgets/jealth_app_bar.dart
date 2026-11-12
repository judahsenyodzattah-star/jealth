import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../utils/breakpoints.dart';
import 'jealth_logo.dart';

/// App bar for the five primary destinations: brand mark, page title and the
/// Settings shortcut.
class JealthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const JealthAppBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // The navigation rail already carries the logo on wider windows.
    final showLogo = Breakpoints.isCompact(context);
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (showLogo) ...[
            const JealthLogo(size: 34, semanticLabel: null),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Semantics(
              header: true,
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Back button that always leads somewhere: it pops when there is a previous
/// screen and otherwise goes to [fallbackLocation] (e.g. after a web refresh).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallbackLocation = AppRoutes.home});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
    );
  }
}
