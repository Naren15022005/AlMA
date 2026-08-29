import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/gradient_theme.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _pages = [HomePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final t = ref.watch(gradientThemeProvider);
        return Scaffold(
          backgroundColor: t.darkest,
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: _NavBar(
            currentIndex: _index,
            t: t,
            onTap: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}

// ─── Nav bar profesional ──────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final GradientTheme t;
  final ValueChanged<int> onTap;

  const _NavBar({required this.currentIndex, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topBorder = t.isLight
        ? const Color(0x14000000)
        : const Color(0x14FFFFFF);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: t.navBg,
        border: Border(top: BorderSide(color: topBorder, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(t.isLight ? 20 : 50),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tab: Inicio
          Expanded(
            child: _Tab(
              icon: Icons.home_rounded,
              label: 'Inicio',
              selected: currentIndex == 0,
              t: t,
              onTap: () => onTap(0),
            ),
          ),
          // Tab: Perfil
          Expanded(
            child: _Tab(
              icon: Icons.person_rounded,
              label: 'Perfil',
              selected: currentIndex == 1,
              t: t,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final GradientTheme t;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(icon,
                color: selected ? t.accent : t.iconInactive,
                size: 22),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? t.accent : t.iconInactive,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  final GradientTheme t;
  const _CenterButton({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                t.accent,
                Color.lerp(t.accent, t.isLight ? Colors.black : Colors.black, 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: t.accent.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
