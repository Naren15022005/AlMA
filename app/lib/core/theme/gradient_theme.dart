import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modelo ───────────────────────────────────────────────────────────────────

class GradientTheme {
  final String id;
  final String name;
  final String category;
  final List<Color> colors;
  final List<double> stops;
  final bool isLight;
  final Color accent;

  const GradientTheme({
    required this.id,
    required this.name,
    required this.category,
    required this.colors,
    required this.accent,
    this.stops = const [0.0, 0.25, 0.55, 0.8, 1.0],
    this.isLight = false,
  });

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: stops,
    colors: colors,
  );

  // ── Colores semánticos — todos derivados del accent y el gradiente ─────────

  Color get darkest => colors.first;

  /// Texto principal — tintado con el accent de cada tema
  Color get textPrimary => isLight
      ? Color.lerp(const Color(0xFF100810), accent, 0.07)!
      : Color.lerp(Colors.white, accent, 0.14)!;

  /// Texto secundario — más suave, sigue siendo coherente con el accent
  Color get textSecondary => isLight
      ? Color.lerp(const Color(0xFF6B5070), accent, 0.22)!.withAlpha(195)
      : Color.lerp(const Color(0xFF907090), accent, 0.28)!.withAlpha(205);

  /// Iconos inactivos — gris tintado con el accent, siempre legible
  Color get iconInactive => isLight
      ? Color.lerp(const Color(0xFF808090), accent, 0.35)!
      : Color.lerp(const Color(0xFF504560), accent, 0.30)!;

  /// Divisores
  Color get divider => accent.withAlpha(isLight ? 28 : 22);

  /// Fondo de tarjetas — tintado con el accent
  Color get cardBg => isLight
      ? Color.lerp(Colors.white, accent, 0.045)!.withAlpha(235)
      : Color.lerp(colors.first, accent, 0.10)!.withAlpha(145);

  /// Borde de tarjetas
  Color get cardBorder => accent.withAlpha(isLight ? 38 : 30);

  /// Fondo de superficies secundarias (inputs, modals)
  Color get surfaceBg => isLight
      ? Color.lerp(Colors.white, accent, 0.03)!.withAlpha(225)
      : Color.lerp(colors.first, accent, 0.12)!.withAlpha(110);

  /// Accent semitransparente para fondos de chips y badges
  Color get accentSoft => accent.withAlpha(isLight ? 28 : 35);

  /// NavBar — siempre más oscuro/claro que el fondo
  Color get navBg => isLight
      ? Color.lerp(colors.first, Colors.white, 0.65)!
      : Color.lerp(colors.first, Colors.black, 0.30)!;
}

// ─── Temas ────────────────────────────────────────────────────────────────────

const List<GradientTheme> gradientThemes = [

  // ── Oscuros profundos ────────────────────────────────────────────────────
  GradientTheme(
    id: 'obsidiana', name: 'Obsidiana', category: 'Oscuros',
    colors: [Color(0xFF09060C), Color(0xFF140E1C), Color(0xFF1F162C), Color(0xFF2A1E3C), Color(0xFF35264C)],
    accent: Color(0xFFB888D8),
  ),
  GradientTheme(
    id: 'onix', name: 'Ónix', category: 'Oscuros',
    colors: [Color(0xFF07080C), Color(0xFF0F1018), Color(0xFF171824), Color(0xFF1F2030), Color(0xFF27283C)],
    accent: Color(0xFF8888CC),
  ),
  GradientTheme(
    id: 'carbon', name: 'Carbón', category: 'Oscuros',
    colors: [Color(0xFF080810), Color(0xFF10101E), Color(0xFF18182C), Color(0xFF20203A), Color(0xFF282848)],
    accent: Color(0xFF7899CC),
  ),

  // ── Vinos ────────────────────────────────────────────────────────────────
  GradientTheme(
    id: 'vino_tinto', name: 'Vino Tinto', category: 'Vinos',
    colors: [Color(0xFF0A0408), Color(0xFF1C0812), Color(0xFF2E0C1C), Color(0xFF421026), Color(0xFF541430)],
    accent: Color(0xFFCC7090),
  ),
  GradientTheme(
    id: 'burdeos', name: 'Burdeos', category: 'Vinos',
    colors: [Color(0xFF0C0408), Color(0xFF200A14), Color(0xFF361020), Color(0xFF4C162C), Color(0xFF601C36)],
    accent: Color(0xFFD08090),
  ),
  GradientTheme(
    id: 'granate', name: 'Granate', category: 'Vinos',
    colors: [Color(0xFF0E0406), Color(0xFF22080C), Color(0xFF380C12), Color(0xFF500E18), Color(0xFF66101E)],
    accent: Color(0xFFE08080),
  ),

  // ── Violetas ─────────────────────────────────────────────────────────────
  GradientTheme(
    id: 'violeta_noche', name: 'Violeta Noche', category: 'Violetas',
    colors: [Color(0xFF080614), Color(0xFF120E26), Color(0xFF1C1638), Color(0xFF261E4A), Color(0xFF30265C)],
    accent: Color(0xFFA070D8),
  ),
  GradientTheme(
    id: 'indigo', name: 'Índigo', category: 'Violetas',
    colors: [Color(0xFF06060E), Color(0xFF0C0C20), Color(0xFF121232), Color(0xFF181844), Color(0xFF1E1E56)],
    accent: Color(0xFF7888E8),
  ),
  GradientTheme(
    id: 'mauve', name: 'Mauve', category: 'Violetas',
    colors: [Color(0xFF0E0A14), Color(0xFF1C1628), Color(0xFF2A223C), Color(0xFF382E50), Color(0xFF463A64)],
    accent: Color(0xFF9A80C8),
  ),

  // ── Rosados ──────────────────────────────────────────────────────────────
  GradientTheme(
    id: 'malva_noche', name: 'Malva Noche', category: 'Rosados',
    colors: [Color(0xFF0E080E), Color(0xFF1C1020), Color(0xFF2A1832), Color(0xFF382044), Color(0xFF462856)],
    accent: Color(0xFFB870B8),
  ),
  GradientTheme(
    id: 'rose_night', name: 'Rose Night', category: 'Rosados',
    colors: [Color(0xFF100808), Color(0xFF201016), Color(0xFF301824), Color(0xFF402032), Color(0xFF502840)],
    accent: Color(0xFFCC80A0),
  ),
  GradientTheme(
    id: 'cobre', name: 'Cobre', category: 'Rosados',
    colors: [Color(0xFF100A08), Color(0xFF201410), Color(0xFF301E18), Color(0xFF402820), Color(0xFF503228)],
    accent: Color(0xFFCC9878),
  ),

  // ── Claros ───────────────────────────────────────────────────────────────
  GradientTheme(
    id: 'nieve', name: 'Nieve', category: 'Claros', isLight: true,
    colors: [Color(0xFFFCFAFF), Color(0xFFF4EEF8), Color(0xFFECE2F0), Color(0xFFE4D6E8), Color(0xFFDCCAE0)],
    accent: Color(0xFF8855BB),
  ),
  GradientTheme(
    id: 'lino', name: 'Lino', category: 'Claros', isLight: true,
    colors: [Color(0xFFFFF9F4), Color(0xFFF8EEE6), Color(0xFFF0E3D8), Color(0xFFE8D8CA), Color(0xFFE0CDBC)],
    accent: Color(0xFFAA6644),
  ),
  GradientTheme(
    id: 'niebla', name: 'Niebla', category: 'Claros', isLight: true,
    colors: [Color(0xFFF8F8FC), Color(0xFFEEEAF8), Color(0xFFE4DCF4), Color(0xFFDAD0EE), Color(0xFFD0C4E8)],
    accent: Color(0xFF6655AA),
  ),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

const _kThemeKey = 'gradient_theme_id';

class GradientThemeNotifier extends Notifier<GradientTheme> {
  @override
  GradientTheme build() => gradientThemes.first;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kThemeKey);
    if (id != null) {
      final match = gradientThemes.where((t) => t.id == id);
      if (match.isNotEmpty) state = match.first;
    }
  }

  Future<void> select(GradientTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, theme.id);
  }
}

final gradientThemeProvider =
    NotifierProvider<GradientThemeNotifier, GradientTheme>(GradientThemeNotifier.new);
