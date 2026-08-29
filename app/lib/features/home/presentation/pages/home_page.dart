import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';

// ─── Módulos ──────────────────────────────────────────────────────────────────

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
  const _ModuleItem(this.title, this.subtitle, this.icon, this.route, this.color);
}

const _modules = [
  _ModuleItem('Cronograma',    'Fechas y eventos',       Icons.calendar_today_rounded,       '/home/schedule',  Color(0xFF7BAAD4)),
  _ModuleItem('Diario',        'Momentos especiales',    Icons.auto_stories_rounded,         '/home/diary',     Color(0xFF5BAA80)),
  _ModuleItem('Pensamientos',  'Lo que sientes',         Icons.favorite_rounded,             '/home/thoughts',  Color(0xFFD47090)),
];

// ─── Home page ────────────────────────────────────────────────────────────────

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final t = ref.watch(gradientThemeProvider);

    return Scaffold(
      backgroundColor: t.darkest,
      body: Container(
        decoration: BoxDecoration(gradient: t.gradient),
        child: Stack(
          children: [
            _BackgroundOrbs(t: t),
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _CoupleHero(authState: authState, t: t)),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(child: _DistanceCard(t: t)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList.separated(
                    itemCount: _modules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ModuleCard(item: _modules[i], t: t),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Orbes de fondo ───────────────────────────────────────────────────────────

class _BackgroundOrbs extends StatelessWidget {
  final GradientTheme t;
  const _BackgroundOrbs({required this.t});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final orbColor = Color.lerp(t.accent, t.isLight ? Colors.white : Colors.black, 0.3)!;
    return Stack(children: [
      Positioned(top: h * 0.05, left: -w * 0.2,
          child: _Orb(size: w * 0.7, color: orbColor, opacity: t.isLight ? 0.18 : 0.14)),
      Positioned(top: h * 0.35, right: -w * 0.25,
          child: _Orb(size: w * 0.65, color: t.darkest, opacity: t.isLight ? 0.10 : 0.12)),
      Positioned(bottom: h * 0.1, left: w * 0.05,
          child: _Orb(size: w * 0.55, color: orbColor, opacity: t.isLight ? 0.12 : 0.10)),
    ]);
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        color.withAlpha((opacity * 255).round()),
        color.withAlpha(0),
      ]),
    ),
  );
}

// ─── Hero de pareja ───────────────────────────────────────────────────────────

class _CoupleHero extends ConsumerWidget {
  final AuthState authState;
  final GradientTheme t;
  const _CoupleHero({required this.authState, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Text('ALMA',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: const Alignment(0.5, 0),
                    child: _AvatarCircle(imageUrl: authState.avatarUrl, t: t, isMe: true),
                  ),
                ),
                _PulsingHeart(t: t),
                Expanded(
                  child: Align(
                    alignment: const Alignment(-0.5, 0),
                    child: _AvatarCircle(imageUrl: null, t: t, isMe: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final bool isMe;
  final GradientTheme t;

  const _AvatarCircle({
    required this.imageUrl,
    required this.isMe,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.4)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: t.accent.withAlpha(50), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: t.darkest,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Icon(isMe ? Icons.person_rounded : Icons.favorite_border_rounded,
                color: t.textSecondary, size: 30)
            : null,
      ),
    );
  }
}

// ─── Corazón pulsante ─────────────────────────────────────────────────────────

class _PulsingHeart extends StatefulWidget {
  final GradientTheme t;
  const _PulsingHeart({required this.t});

  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.35)!],
            ),
            boxShadow: [BoxShadow(color: t.accent.withAlpha(70), blurRadius: 16, spreadRadius: 1)],
          ),
          child: Icon(Icons.favorite_rounded,
              color: t.isLight ? Colors.white : Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ─── Provider de distancia (demo) ────────────────────────────────────────────

class _DistanceState {
  final bool active;
  final double? km;
  const _DistanceState({this.active = false, this.km});
}

class _DistanceNotifier extends Notifier<_DistanceState> {
  @override
  _DistanceState build() => const _DistanceState();
  void activate() => state = const _DistanceState(active: true, km: 3.128);
  void deactivate() => state = const _DistanceState();
}

final _distanceProvider =
    NotifierProvider<_DistanceNotifier, _DistanceState>(_DistanceNotifier.new);

// ─── Tarjeta de distancia ─────────────────────────────────────────────────────

class _DistanceCard extends ConsumerWidget {
  final GradientTheme t;
  const _DistanceCard({required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dist = ref.watch(_distanceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: dist.active && dist.km != null
          ? _ActiveDistance(t: t, km: dist.km!)
          : _InactiveDistance(
              t: t,
              onActivate: () => ref.read(_distanceProvider.notifier).activate(),
            ),
    );
  }
}

// ── Estado inactivo ────────────────────────────────────────────────────────

class _InactiveDistance extends StatelessWidget {
  final GradientTheme t;
  final VoidCallback onActivate;
  const _InactiveDistance({required this.t, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.35)!],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distancia entre vosotros',
                style: TextStyle(fontSize: 12, color: t.textSecondary,
                    fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('Activa la ubicación',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: t.textPrimary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onActivate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.25)!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Activar',
              style: TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ── Estado activo ──────────────────────────────────────────────────────────

class _ActiveDistance extends ConsumerWidget {
  final GradientTheme t;
  final double km;
  const _ActiveDistance({required this.t, required this.km});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final myInitial = (auth.name.isNotEmpty ? auth.name[0] : 'A').toUpperCase();
    const partnerInitial = 'M';

    return Column(
      children: [
        // Texto de distancia
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, color: t.accent, size: 13),
            const SizedBox(width: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: t.textSecondary,
                    fontWeight: FontWeight.w500),
                children: [
                  const TextSpan(text: 'Our distance: '),
                  TextSpan(
                    text: '${km.toStringAsFixed(3)} km',
                    style: TextStyle(color: t.accent, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Círculos + línea
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _InitialCircle(initial: myInitial, t: t),
            Expanded(child: SizedBox(height: 48, child: _HeartLine(t: t))),
            _InitialCircle(initial: partnerInitial, t: t),
          ],
        ),
      ],
    );
  }
}

class _InitialCircle extends StatelessWidget {
  final String initial;
  final GradientTheme t;
  const _InitialCircle({required this.initial, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: t.accent, width: 2),
      ),
      child: Center(
        child: Text(initial,
          style: TextStyle(color: t.accent, fontSize: 20,
              fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _HeartLine extends StatelessWidget {
  final GradientTheme t;
  const _HeartLine({required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 2),
            painter: _DashPainter(color: t.accent),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(-7, 0),
              child: Icon(Icons.favorite_rounded, color: t.accent, size: 24),
            ),
            Transform.translate(
              offset: const Offset(7, 3),
              child: Icon(Icons.favorite_rounded, color: t.accent.withAlpha(180), size: 18),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomPaint(
            size: const Size(double.infinity, 2),
            painter: _DashPainter(color: t.accent),
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(110)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashLen = 5.0;
    const gap = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dashLen).clamp(0, size.width), y), paint);
      x += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// ─── Tarjeta de módulo ────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final _ModuleItem item;
  final GradientTheme t;
  const _ModuleCard({required this.item, required this.t});

  @override
  Widget build(BuildContext context) {
    final cardBg = t.isLight ? Colors.white.withAlpha(210) : Colors.white.withAlpha(12);
    final cardBorder = t.isLight ? Colors.black.withAlpha(12) : Colors.white.withAlpha(18);

    return GestureDetector(
      onTap: () => context.push(item.route),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icono
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.color.withAlpha(t.isLight ? 70 : 55),
                          item.color.withAlpha(t.isLight ? 30 : 20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flecha
                  Icon(Icons.chevron_right_rounded,
                      color: t.textSecondary.withAlpha(100), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ring ──────────────────────────────────────────────────────────────

class _RingAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final GradientTheme t;
  final VoidCallback onTap;
  const _RingAvatar({required this.imageUrl, required this.radius,
      required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [t.accent, Color.lerp(t.accent, Colors.black, 0.4)!],
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: t.darkest,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Icon(Icons.person_rounded, color: t.textSecondary, size: radius)
              : null,
        ),
      ),
    );
  }
}
