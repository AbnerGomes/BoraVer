import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/app_navigation.dart';
import '../screens/draw_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/cinema_decor.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = {
  AppSection.home: _Destination('Início', Icons.home_outlined, Icons.home),
  AppSection.library: _Destination(
    'Biblioteca',
    Icons.video_library_outlined,
    Icons.video_library,
  ),
  AppSection.draw: _Destination('Sortear', Icons.shuffle, Icons.shuffle),
  AppSection.settings: _Destination('Ajustes', Icons.tune_outlined, Icons.tune),
};

/// Estrutura principal: navegação inferior no celular e barra lateral em
/// telas largas (tablet/navegador).
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const railBreakpoint = 640.0;
  static const extendedRailBreakpoint = 1100.0;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<AppNavigation>();
    final width = MediaQuery.sizeOf(context).width;
    final index = nav.section.index;

    // IndexedStack preserva o estado de cada seção (busca, rolagem, sorteio).
    final pages = IndexedStack(
      index: index,
      children: const [
        HomeScreen(),
        LibraryScreen(),
        DrawScreen(),
        SettingsScreen(),
      ],
    );

    void select(int i) => nav.go(AppSection.values[i]);

    if (width < railBreakpoint) {
      return Scaffold(
        body: pages,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: select,
          destinations: [
            for (final d in _destinations.values)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= extendedRailBreakpoint;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: select,
            extended: extended,
            labelType: extended ? null : NavigationRailLabelType.all,
            minExtendedWidth: 220,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: BoraVerLogo(size: extended ? 30 : 34, showName: extended),
            ),
            destinations: [
              for (final d in _destinations.values)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages),
        ],
      ),
    );
  }
}
