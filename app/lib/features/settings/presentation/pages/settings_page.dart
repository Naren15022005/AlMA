import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import 'themes_page.dart';

// ─── Provider de configuración ────────────────────────────────────────────────

class _SettingsState {
  final bool notificationsEnabled;
  final bool thoughtsNotifs;
  final bool distanceNotifs;
  const _SettingsState({
    this.notificationsEnabled = true,
    this.thoughtsNotifs = true,
    this.distanceNotifs = false,
  });
  _SettingsState copyWith({bool? notificationsEnabled, bool? thoughtsNotifs,
      bool? distanceNotifs}) =>
      _SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        thoughtsNotifs: thoughtsNotifs ?? this.thoughtsNotifs,
        distanceNotifs: distanceNotifs ?? this.distanceNotifs,
      );
}

class _SettingsNotifier extends Notifier<_SettingsState> {
  @override
  _SettingsState build() => const _SettingsState();
  void toggle(String key) {
    state = switch (key) {
      'notifications' => state.copyWith(notificationsEnabled: !state.notificationsEnabled),
      'thoughts'      => state.copyWith(thoughtsNotifs: !state.thoughtsNotifs),
      'distance'      => state.copyWith(distanceNotifs: !state.distanceNotifs),
      _               => state,
    };
  }
}

final _settingsProvider = NotifierProvider<_SettingsNotifier, _SettingsState>(_SettingsNotifier.new);

// ─── Settings page ────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s     = ref.watch(_settingsProvider);
    final auth  = ref.watch(authProvider);
    final t     = ref.watch(gradientThemeProvider);

    return Scaffold(
      backgroundColor: t.darkest,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: t.gradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: t.textPrimary.withAlpha(180), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Configuración',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cuenta ──
                      _Label('Cuenta', t),
                      _Card(t: t, children: [
                        _Tile(t: t, icon: Icons.person_outline_rounded,
                            label: 'Nombre de usuario',
                            value: auth.name.isNotEmpty ? auth.name
                                : (auth.firebaseUser?.email?.split('@').first ?? ''),
                            onTap: () => _editName(context, ref, t)),
                        _Div(t),
                        _Tile(t: t, icon: Icons.email_outlined,
                            label: 'Correo electrónico',
                            value: auth.firebaseUser?.email ?? '',
                            onTap: null),
                        _Div(t),
                        _Tile(t: t, icon: Icons.lock_outline_rounded,
                            label: 'Cambiar contraseña',
                            onTap: () => _changePassword(context, t)),
                      ]),

                      const SizedBox(height: 20),

                      // ── Personalización ──
                      _Label('Personalización', t),
                      _Card(t: t, children: [
                        _Tile(t: t, icon: Icons.palette_outlined,
                            label: 'Temas de color',
                            subtitle: t.name,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ThemesPage()))),
                      ]),

                      const SizedBox(height: 20),

                      // ── Notificaciones ──
                      _Label('Notificaciones', t),
                      _Card(t: t, children: [
                        _Switch(t: t, icon: Icons.notifications_outlined,
                            label: 'Notificaciones generales',
                            value: s.notificationsEnabled,
                            onChanged: (_) => ref.read(_settingsProvider.notifier).toggle('notifications')),
                        _Div(t),
                        _Switch(t: t, icon: Icons.favorite_border_rounded,
                            label: 'Pensamientos de tu pareja',
                            value: s.thoughtsNotifs, enabled: s.notificationsEnabled,
                            onChanged: (_) => ref.read(_settingsProvider.notifier).toggle('thoughts')),
                        _Div(t),
                        _Switch(t: t, icon: Icons.location_on_outlined,
                            label: 'Actualizaciones de distancia',
                            value: s.distanceNotifs, enabled: s.notificationsEnabled,
                            onChanged: (_) => ref.read(_settingsProvider.notifier).toggle('distance')),
                      ]),

                      const SizedBox(height: 20),

                      // ── Pareja ──
                      _Label('Pareja', t),
                      _Card(t: t, children: [
                        _Tile(t: t, icon: Icons.link_rounded,
                            label: 'Vincular pareja',
                            subtitle: 'Conecta tu cuenta con la de tu pareja',
                            onTap: () {}),
                        _Div(t),
                        _Tile(t: t, icon: Icons.favorite_border_rounded,
                            label: 'Fecha de aniversario',
                            subtitle: 'Establece vuestra fecha especial',
                            onTap: () {}),
                      ]),

                      const SizedBox(height: 20),

                      // ── Privacidad ──
                      _Label('Privacidad', t),
                      _Card(t: t, children: [
                        _Tile(t: t, icon: Icons.shield_outlined,
                            label: 'Privacidad de datos', onTap: () {}),
                        _Div(t),
                        _Tile(t: t, icon: Icons.visibility_off_outlined,
                            label: 'Entradas privadas del diario',
                            subtitle: 'Solo tú puedes ver tus entradas privadas',
                            trailing: Icon(Icons.check_circle_rounded, color: t.accent, size: 18),
                            onTap: null),
                      ]),

                      const SizedBox(height: 20),

                      // ── Acerca de ──
                      _Label('Acerca de', t),
                      _Card(t: t, children: [
                        _Tile(t: t, icon: Icons.info_outline_rounded,
                            label: 'Versión de la app', value: '1.0.0', onTap: null),
                        _Div(t),
                        _Tile(t: t, icon: Icons.description_outlined,
                            label: 'Términos y condiciones', onTap: () {}),
                        _Div(t),
                        _Tile(t: t, icon: Icons.privacy_tip_outlined,
                            label: 'Política de privacidad', onTap: () {}),
                      ]),

                      const SizedBox(height: 20),

                      // ── Zona de peligro ──
                      _Label('Zona de peligro', t),
                      _Card(t: t,
                        borderColor: const Color(0xFFE05060).withAlpha(70),
                        children: [
                          _Tile(t: t, icon: Icons.logout_rounded,
                              label: 'Cerrar sesión', labelColor: t.accent,
                              onTap: () => ref.read(authProvider.notifier).logout()),
                          _Div(t),
                          _Tile(t: t, icon: Icons.delete_outline_rounded,
                              label: 'Eliminar cuenta', labelColor: const Color(0xFFFF6B6B),
                              onTap: () => _deleteDialog(context, ref, t)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editName(BuildContext ctx, WidgetRef ref, GradientTheme t) {
    final ctrl = TextEditingController(text: ref.read(authProvider).name);
    showDialog(context: ctx, builder: (_) => _Dialog(t: t,
      title: 'Cambiar nombre',
      onConfirm: () => Navigator.pop(ctx),
      child: TextField(controller: ctrl, autofocus: true,
        style: TextStyle(color: t.textPrimary),
        cursorColor: t.accent,
        decoration: _deco(t, 'Tu nombre')),
    ));
  }

  void _changePassword(BuildContext ctx, GradientTheme t) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => _Dialog(t: t,
      title: 'Nueva contraseña',
      onConfirm: () => Navigator.pop(ctx),
      child: TextField(controller: ctrl, obscureText: true, autofocus: true,
        style: TextStyle(color: t.textPrimary),
        cursorColor: t.accent,
        decoration: _deco(t, 'Mínimo 6 caracteres')),
    ));
  }

  void _deleteDialog(BuildContext ctx, WidgetRef ref, GradientTheme t) {
    showDialog(context: ctx, builder: (_) => _Dialog(t: t,
      title: '¿Eliminar cuenta?',
      confirmLabel: 'Eliminar',
      confirmColor: const Color(0xFFE05060),
      onConfirm: () => Navigator.pop(ctx),
      child: Text(
        'Esta acción es irreversible. Se borrarán todos tus datos y los de tu pareja.',
        style: TextStyle(color: t.textSecondary, height: 1.5)),
    ));
  }

  InputDecoration _deco(GradientTheme t, String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: t.textSecondary),
    filled: true,
    fillColor: t.isLight ? Colors.black.withAlpha(8) : Colors.white.withAlpha(15),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─── Widgets adaptativos ──────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final GradientTheme t;
  const _Label(this.text, this.t);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text.toUpperCase(),
      style: TextStyle(color: t.accent, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.3)),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final GradientTheme t;
  final Color? borderColor;
  const _Card({required this.children, required this.t, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final bg = t.isLight ? Colors.black.withAlpha(6) : Colors.white.withAlpha(14);
    final border = borderColor ?? (t.isLight ? Colors.black.withAlpha(18) : Colors.white.withAlpha(22));
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  final GradientTheme t;
  const _Div(this.t);
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: t.divider,
  );
}

class _Tile extends StatelessWidget {
  final GradientTheme t;
  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _Tile({
    required this.t,
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
    this.labelColor,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final fg = labelColor ?? t.textPrimary;
    final secondary = t.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: secondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(color: secondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(value!, style: TextStyle(color: secondary, fontSize: 13)),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null && value == null)
              Icon(Icons.chevron_right_rounded, color: secondary.withAlpha(100), size: 18),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final GradientTheme t;
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _Switch({
    required this.t,
    required this.icon,
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? t.textPrimary : t.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: t.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500))),
          Switch.adaptive(
            value: enabled && value,
            onChanged: enabled ? onChanged : null,
            activeColor: t.accent,
            activeTrackColor: t.accentSoft,
            inactiveThumbColor: t.textSecondary.withAlpha(80),
            inactiveTrackColor: t.divider,
          ),
        ],
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  final GradientTheme t;
  final String title;
  final Widget child;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final Color? confirmColor;

  const _Dialog({
    required this.t,
    required this.title,
    required this.child,
    required this.onConfirm,
    this.confirmLabel = 'Guardar',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgDialog = t.isLight ? const Color(0xFFFFF0F8) : const Color(0xFF1E0818);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: TextStyle(
            fontFamily: 'PlayfairDisplay', fontSize: 18, color: t.textPrimary)),
        content: child,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: t.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? t.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onConfirm,
            child: Text(confirmLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Selector de gradiente (usado desde ThemesPage) ───────────────────────────

class GradientPicker extends ConsumerWidget {
  const GradientPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(gradientThemeProvider);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: gradientThemes.map((theme) {
        final selected = current.id == theme.id;
        return GestureDetector(
          onTap: () => ref.read(gradientThemeProvider.notifier).select(theme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: theme.gradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: selected
                ? const Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 22))
                : null,
          ),
        );
      }).toList(),
    );
  }
}
