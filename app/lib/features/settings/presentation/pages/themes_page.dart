import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/gradient_theme.dart';

class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(gradientThemeProvider);

    // Categorías únicas en orden
    final categories = ['Oscuros', 'Vinos', 'Violetas', 'Rosados', 'Claros'];

    return Scaffold(
      backgroundColor: current.darkest,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: current.gradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: current.textPrimary.withAlpha(180), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Temas de color',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: current.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: Text(
                  'Personaliza el aspecto de ALMA',
                  style: TextStyle(color: current.textSecondary, fontSize: 13),
                ),
              ),

              // ── Lista por categorías ─────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final themes = gradientThemes.where((t) => t.category == cat).toList();
                    return _CategorySection(
                      label: cat,
                      themes: themes,
                      current: current,
                      onSelect: (t) => ref.read(gradientThemeProvider.notifier).select(t),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sección de categoría ─────────────────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final String label;
  final List<GradientTheme> themes;
  final GradientTheme current;
  final ValueChanged<GradientTheme> onSelect;

  const _CategorySection({
    required this.label,
    required this.themes,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: current.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: themes.length,
          itemBuilder: (_, i) => _ThemeCard(
            theme: themes[i],
            isSelected: current.id == themes[i].id,
            onTap: () => onSelect(themes[i]),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Tarjeta de tema ──────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final GradientTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(20),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.white.withAlpha(30), blurRadius: 12, spreadRadius: 1)]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Gradiente de fondo
              Container(
                decoration: BoxDecoration(gradient: theme.gradient),
              ),

              // Vista previa mini
              Positioned.fill(
                child: _MiniPreview(theme: theme),
              ),

              // Overlay nombre
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(theme.isLight ? 30 : 60),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              theme.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.isLight ? Colors.white : Colors.white,
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mini vista previa de la app ──────────────────────────────────────────────

class _MiniPreview extends StatelessWidget {
  final GradientTheme theme;
  const _MiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final accent = theme.isLight ? const Color(0xFFC4556E) : const Color(0xFFE8A0B0);
    final cardColor = theme.isLight
        ? Colors.white.withAlpha(80)
        : Colors.white.withAlpha(20);
    final textColor = theme.isLight ? const Color(0xFF3A1028) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatares mini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniAvatar(accent: accent),
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withAlpha(180),
                ),
              ),
              _MiniAvatar(accent: accent),
            ],
          ),
          const SizedBox(height: 6),
          // Mini tarjeta
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(180),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Mini grid
          Row(
            children: [
              _MiniCard(accent: accent, cardColor: cardColor),
              const SizedBox(width: 3),
              _MiniCard(accent: accent, cardColor: cardColor),
              const SizedBox(width: 3),
              _MiniCard(accent: accent, cardColor: cardColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final Color accent;
  const _MiniAvatar({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
        color: accent.withAlpha(30),
      ),
      child: Icon(Icons.person_rounded, color: accent.withAlpha(150), size: 12),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Color accent;
  final Color cardColor;
  const _MiniCard({required this.accent, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(Icons.favorite_rounded, color: accent.withAlpha(160), size: 10),
        ),
      ),
    );
  }
}
