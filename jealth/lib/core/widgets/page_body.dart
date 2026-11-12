import 'package:material_ui/material_ui.dart';

import '../utils/breakpoints.dart';

/// Scrollable page content: centred, width-limited and padded for the current
/// window size, safe areas and on-screen keyboard.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.controller,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;
  final double spacing;

  /// Horizontal page padding for the given window width.
  static double horizontalPadding(double width) => width < Breakpoints.medium
      ? 16
      : (width < Breakpoints.expanded ? 24 : 32);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = horizontalPadding(constraints.maxWidth);
        return Scrollbar(
          controller: controller,
          child: SingleChildScrollView(
            controller: controller,
            primary: controller == null ? true : null,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(side, 8, side, 32),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) SizedBox(height: spacing),
                        children[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Lays out [children] in [columns] equal columns on wide windows and in a
/// single column on narrow ones. Rows keep equal heights.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 260,
    this.maxColumns = 3,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor();
        final columns = fit.clamp(1, maxColumns);
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final rowChildren = <Widget>[];
          for (var c = 0; c < columns; c++) {
            if (c > 0) rowChildren.add(SizedBox(width: spacing));
            final index = start + c;
            rowChildren.add(
              Expanded(
                child: index < children.length
                    ? children[index]
                    : const SizedBox.shrink(),
              ),
            );
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rowChildren,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
