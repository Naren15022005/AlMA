import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth  = ref.watch(authProvider);
    final t     = ref.watch(gradientThemeProvider);
    final cardBg = t.isLight ? Colors.black.withAlpha(6) : Colors.white.withAlpha(14);
    final border = t.isLight ? Colors.black.withAlpha(18) : Colors.white.withAlpha(22);

    return Scaffold(
      backgroundColor: t.darkest,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Avatar ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.4)!],
                    ),
                    boxShadow: [
                      BoxShadow(color: t.accent.withAlpha(45), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: t.darkest,
                    backgroundImage: auth.avatarUrl != null ? NetworkImage(auth.avatarUrl!) : null,
                    child: auth.avatarUrl == null
                        ? Icon(Icons.person_rounded, color: t.textSecondary, size: 44)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Nombre ───────────────────────────────────────────────
                Text(
                  auth.name.isNotEmpty
                      ? auth.name
                      : (auth.firebaseUser?.email?.split('@').first ?? 'Mi perfil'),
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.firebaseUser?.email ?? '',
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
                const SizedBox(height: 32),

                // ── Opciones ─────────────────────────────────────────────
                _Option(t: t, cardBg: cardBg, border: border,
                    icon: Icons.person_outline_rounded, label: 'Editar perfil', onTap: () {}),
                const SizedBox(height: 12),
                _Option(t: t, cardBg: cardBg, border: border,
                    icon: Icons.photo_camera_outlined, label: 'Cambiar foto', onTap: () {}),
                const SizedBox(height: 12),
                _Option(t: t, cardBg: cardBg, border: border,
                    icon: Icons.settings_outlined, label: 'Configuración',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()))),
                const SizedBox(height: 32),

                // ── Cerrar sesión ────────────────────────────────────────
                GestureDetector(
                  onTap: () => ref.read(authProvider.notifier).logout(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: t.accent.withAlpha(t.isLight ? 20 : 28),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.accent.withAlpha(80)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: t.accent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: t.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
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
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final GradientTheme t;
  final Color cardBg;
  final Color border;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Option({
    required this.t,
    required this.cardBg,
    required this.border,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(icon, color: t.textSecondary, size: 20),
                const SizedBox(width: 14),
                Expanded(child: Text(label,
                    style: TextStyle(color: t.textPrimary, fontSize: 15,
                        fontWeight: FontWeight.w500))),
                Icon(Icons.chevron_right_rounded, color: t.textSecondary.withAlpha(100), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
