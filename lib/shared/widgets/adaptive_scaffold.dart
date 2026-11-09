import 'package:flutter/material.dart';

/// Navigation destination data for [AdaptiveScaffold].
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.semanticLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String semanticLabel;
}

/// Adaptive layout scaffold that provides:
/// - A bottom [NavigationBar] for compact screens (phones < 600dp)
/// - A side [NavigationRail] for expanded screens (tablets, foldables >= 600dp)
/// - Minimum touch targets >= 48dp
/// - Text scale factor clamped up to 2.0
/// - Full TalkBack semantic accessibility support
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    required this.body,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.destinations,
    super.key,
    this.appBar,
    this.floatingActionButton,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final List<AdaptiveDestination> destinations;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  static const double tabletBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Clamp system font scaling to max 2.0 to preserve UI layout
    final clampedMediaQuery = mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 2),
    );

    final isExpanded = mediaQuery.size.width >= tabletBreakpoint;

    return MediaQuery(
      data: clampedMediaQuery,
      child: Scaffold(
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: isExpanded
            ? Row(
                children: [
                  Semantics(
                    label: 'Navigation rail',
                    child: NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onNavigationIndexChanged,
                      labelType: NavigationRailLabelType.all,
                      minWidth: 72,
                      destinations: destinations.map((d) {
                        return NavigationRailDestination(
                          icon: Semantics(
                            label: d.semanticLabel,
                            child: Icon(d.icon),
                          ),
                          selectedIcon: Semantics(
                            label: d.semanticLabel,
                            child: Icon(d.selectedIcon),
                          ),
                          label: Text(d.label),
                        );
                      }).toList(),
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
        bottomNavigationBar: isExpanded
            ? null
            : Semantics(
                label: 'Bottom navigation bar',
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: onNavigationIndexChanged,
                  destinations: destinations.map((d) {
                    return NavigationDestination(
                      icon: Semantics(
                        label: d.semanticLabel,
                        child: Icon(d.icon),
                      ),
                      selectedIcon: Semantics(
                        label: d.semanticLabel,
                        child: Icon(d.selectedIcon),
                      ),
                      label: d.label,
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
