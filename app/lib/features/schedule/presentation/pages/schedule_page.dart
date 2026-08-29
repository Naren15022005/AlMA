import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/tvmaze_service.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _seriesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth     = ref.watch(authProvider);
  final svc      = ref.read(firestoreServiceProvider);
  final coupleId = auth.coupleId;
  final uid      = auth.firebaseUser?.uid;

  if (coupleId != null) return svc.seriesStream(coupleId);
  if (uid != null)      return svc.userSeriesStream(uid);
  return Stream.value([]);
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t        = ref.watch(gradientThemeProvider);
    final async    = ref.watch(_seriesProvider);
    final coupleId = ref.watch(authProvider).coupleId;
    final all      = async.asData?.value ?? [];

    final watching  = all.where((s) => s['status'] == 'WATCHING').toList();
    final pending   = all.where((s) => s['status'] == 'PENDING').toList();
    final completed = all.where((s) => s['status'] == 'COMPLETED').toList();

    return Scaffold(
      backgroundColor: t.darkest,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddForm(context, t, coupleId),
        backgroundColor: t.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: t.gradient),
        child: SafeArea(
          child: Column(
            children: [

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back_ios_rounded,
                              color: t.textPrimary, size: 20),
                        ),
                        Icon(Icons.movie_rounded,
                            color: t.accent, size: 24),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Cronograma', style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 32, fontWeight: FontWeight.w700,
                      color: t.textPrimary, letterSpacing: -0.8)),
                    const SizedBox(height: 6),
                    Text('Sigue juntos las series y películas que aman',
                      style: TextStyle(fontSize: 14, color: t.textSecondary, height: 1.4)),
                  ],
                ),
              ),

              // ── Tabs ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TabsBar(
                  ctrl: _tabs, t: t,
                  counts: [watching.length, pending.length, completed.length],
                ),
              ),
              const SizedBox(height: 14),

              // ── Contenido ─────────────────────────────────────────────
              Expanded(
                child: async.isLoading
                    ? Center(child: CircularProgressIndicator(color: t.accent, strokeWidth: 2))
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _SeriesList(
                            items: watching, t: t, coupleId: coupleId,
                            emptyIcon: Icons.play_circle_outline_rounded,
                            emptyTitle: 'Nada en reproducción',
                            emptySubtitle: 'Agrega algo para ver juntos',
                          ),
                          _SeriesList(
                            items: pending, t: t, coupleId: coupleId,
                            emptyIcon: Icons.bookmark_outline_rounded,
                            emptyTitle: 'Lista vacía',
                            emptySubtitle: 'Guarda algo para ver después',
                          ),
                          _SeriesList(
                            items: completed, t: t, coupleId: coupleId,
                            emptyIcon: Icons.check_circle_outline_rounded,
                            emptyTitle: 'Ninguna completada',
                            emptySubtitle: 'Las completadas aparecerán aquí',
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddForm(BuildContext ctx, GradientTheme t, String? coupleId) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeriesForm(coupleId: coupleId),
    );
  }
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _TabsBar extends StatelessWidget {
  final TabController ctrl;
  final GradientTheme t;
  final List<int> counts;
  const _TabsBar({required this.ctrl, required this.t, required this.counts});

  @override
  Widget build(BuildContext context) {
    final labels = ['Viendo', 'Por ver', 'Completadas'];
    final icons  = [Icons.play_arrow_rounded, Icons.turned_in_not_rounded, Icons.check_circle_rounded];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.cardBorder),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(3, (i) {
              final active = ctrl.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.animateTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? t.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[i],
                            color: active ? Colors.white : t.textSecondary,
                            size: 18),
                        const SizedBox(width: 6),
                        Text(labels[i], style: TextStyle(
                          color: active ? Colors.white : t.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w700)),
                        if (counts[i] > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withAlpha(50)
                                  : t.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${counts[i]}', style: TextStyle(
                              color: active ? Colors.white : t.accent,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Lista de series ──────────────────────────────────────────────────────────

class _SeriesList extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  final GradientTheme t;
  final String? coupleId;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _SeriesList({
    required this.items, required this.t, required this.coupleId,
    required this.emptyIcon, required this.emptyTitle, required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(emptyIcon, size: 48, color: t.accent),
              ),
              const SizedBox(height: 24),
              Text(emptyTitle, style: TextStyle(
                color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
              const SizedBox(height: 8),
              Text(emptySubtitle, style: TextStyle(
                color: t.textSecondary, fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _SeriesCard(
        item: items[i], t: t, coupleId: coupleId, ref: ref),
    );
  }
}

// ─── Tarjeta de serie ─────────────────────────────────────────────────────────

class _SeriesCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final GradientTheme t;
  final String? coupleId;
  final WidgetRef ref;

  const _SeriesCard({
    required this.item, required this.t,
    required this.coupleId, required this.ref,
  });

  bool get _isSeries => item['type'] == 'SERIES';
  bool get _isWatching  => item['status'] == 'WATCHING';
  bool get _isPending   => item['status'] == 'PENDING';

  double get _progress {
    if (!_isSeries) return 1.0;
    final ep  = (item['currentEpisode'] as num?)?.toInt() ?? 1;
    final tot = (item['totalEpisodes'] as num?)?.toInt() ?? 1;
    return (ep / tot).clamp(0.0, 1.0);
  }

  String get _progressLabel {
    if (!_isSeries) return '';
    final s  = (item['currentSeason'] as num?)?.toInt() ?? 1;
    final ep = (item['currentEpisode'] as num?)?.toInt() ?? 1;
    final ts = (item['totalSeasons'] as num?)?.toInt();
    final te = (item['totalEpisodes'] as num?)?.toInt();
    final current = 'T${s}E$ep';
    final total   = (ts != null && te != null) ? 'de T${ts}E$te' : '';
    return '$current $total'.trim();
  }

  Color get _typeColor => _isSeries ? const Color(0xFF7BAAD4) : const Color(0xFFD4A847);
  IconData get _typeIcon => _isSeries ? Icons.tv_rounded : Icons.movie_rounded;
  String get _typeLabel => _isSeries ? 'Serie' : 'Película';

  @override
  Widget build(BuildContext context) {
    final pct = (_progress * 100).round();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: t.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top accent bar ───────────────────────────────────────
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [t.accent, t.accent.withAlpha(80)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Póster + título + badge ───────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Póster o ícono fallback
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item['posterUrl'] != null
                              ? CachedNetworkImage(
                                  imageUrl: item['posterUrl'] as String,
                                  width: 54, height: 78,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => _PosterPlaceholder(
                                      color: _typeColor, icon: _typeIcon),
                                  errorWidget: (_, __, ___) => _PosterPlaceholder(
                                      color: _typeColor, icon: _typeIcon),
                                )
                              : _PosterPlaceholder(color: _typeColor, icon: _typeIcon),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] ?? '', style: TextStyle(
                                color: t.textPrimary, fontSize: 15,
                                fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _Badge(label: _typeLabel, color: _typeColor),
                                  if (_isWatching && _progressLabel.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(_progressLabel,
                                      style: TextStyle(color: t.textSecondary, fontSize: 11)),
                                  ],
                                ],
                              ),
                              if ((item['overview'] as String?)?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(item['overview'] as String,
                                  style: TextStyle(color: t.textSecondary, fontSize: 11, height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Barra de progreso (solo si viendo y es serie) ──
                    if (_isWatching && _isSeries) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: t.divider,
                                valueColor: AlwaysStoppedAnimation(t.accent),
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('$pct%', style: TextStyle(
                            color: t.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ── Acciones ───────────────────────────────────────
                    Row(
                      children: [
                        if (_isWatching) ...[
                          Expanded(child: _ActionBtn(
                            label: 'Capítulos',
                            icon: Icons.list_rounded,
                            color: t.accent,
                            filled: true,
                            onTap: () => _showEpisodesModal(context),
                          )),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            label: 'Pausar',
                            icon: Icons.pause_rounded,
                            color: t.textSecondary,
                            onTap: () => _setStatus('PENDING'),
                          ),
                        ] else if (_isPending) ...[
                          Expanded(child: _ActionBtn(
                            label: 'Empezar',
                            icon: Icons.play_arrow_rounded,
                            color: t.accent,
                            filled: true,
                            onTap: () => _setStatus('WATCHING'),
                          )),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            label: 'Eliminar',
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFE05060),
                            onTap: () => _delete(context),
                          ),
                        ] else ...[
                          Expanded(child: _ActionBtn(
                            label: 'Ver de nuevo',
                            icon: Icons.replay_rounded,
                            color: t.accent,
                            filled: true,
                            onTap: () => _setStatus('WATCHING'),
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _uid => ref.read(authProvider).firebaseUser?.uid;

  void _update(Map<String, dynamic> data) {
    final svc = ref.read(firestoreServiceProvider);
    final id  = item['id'] as String;
    // Fire and forget: actualización optimista sin esperar Firestore
    if (coupleId != null) {
      svc.updateSeries(coupleId!, id, data);
    } else if (_uid != null) {
      svc.updateUserSeries(_uid!, id, data);
    }
  }

  void _next(BuildContext context) {
    Map<String, dynamic> update;
    if (!_isSeries) {
      update = {'status': 'COMPLETED'};
    } else {
      final ep = (item['currentEpisode'] as num?)?.toInt() ?? 1;
      final tot = (item['totalEpisodes'] as num?)?.toInt() ?? 1;
      final s  = (item['currentSeason']  as num?)?.toInt() ?? 1;
      final ts = (item['totalSeasons']   as num?)?.toInt() ?? 1;
      if (ep < tot)     update = {'currentEpisode': ep + 1};
      else if (s < ts)  update = {'currentSeason': s + 1, 'currentEpisode': 1};
      else              update = {'status': 'COMPLETED'};
    }
    _update(update);
  }

  void _setStatus(String status) {
    final update = <String, dynamic>{'status': status};
    if (status == 'WATCHING' && item['currentSeason'] == null && _isSeries) {
      update['currentSeason']  = 1;
      update['currentEpisode'] = 1;
    }
    _update(update);
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar?'),
        content: Text('Se eliminará "${item['title']}" de vuestra lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE05060)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final svc = ref.read(firestoreServiceProvider);
      final id  = item['id'] as String;
      // Borrado optimista: no espera respuesta, el Stream se actualiza automáticamente
      if (coupleId != null) {
        svc.deleteSeries(coupleId!, id).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')));
        });
      } else if (_uid != null) {
        svc.deleteUserSeries(_uid!, id).catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')));
        });
      }
    }
  }

  void _showEpisodesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EpisodesModal(
        title: item['title'] as String,
        totalSeasons: item['totalSeasons'] as int? ?? 1,
        totalEpisodes: item['totalEpisodes'] as int? ?? 10,
        watched: (item['watchedEpisodes'] as Map<String, dynamic>?) ?? {},
        onWatchedChange: (watched) {
          _update({'watchedEpisodes': watched});
        },
        t: t,
      ),
    );
  }
}

// ─── Modal de capítulos ───────────────────────────────────────────────────────

class _EpisodesModal extends StatefulWidget {
  final String title;
  final int totalSeasons;
  final int totalEpisodes;
  final Map<String, dynamic> watched;
  final Function(Map<String, dynamic>) onWatchedChange;
  final GradientTheme t;

  const _EpisodesModal({
    required this.title,
    required this.totalSeasons,
    required this.totalEpisodes,
    required this.watched,
    required this.onWatchedChange,
    required this.t,
  });

  @override
  State<_EpisodesModal> createState() => _EpisodesModalState();
}

class _EpisodesModalState extends State<_EpisodesModal> {
  late Map<String, List<int>> _watched;

  @override
  void initState() {
    super.initState();
    _watched = {};
    for (int s = 1; s <= widget.totalSeasons; s++) {
      final key = s.toString();
      _watched[key] = List.from((widget.watched[key] as List<dynamic>?) ?? []);
    }
  }

  void _toggleEpisode(int season, int ep) {
    final key = season.toString();
    final list = _watched[key]!;
    if (list.contains(ep)) {
      list.remove(ep);
    } else {
      list.add(ep);
    }
    setState(() {});
    widget.onWatchedChange(_watched);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final bg = t.isLight ? const Color(0xFFFAF6FF) : Color.lerp(t.darkest, Colors.black, 0.3)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.accent.withAlpha(60), width: 1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.accent.withAlpha(80),
                  borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.list_rounded, color: t.accent, size: 18),
                      const SizedBox(width: 8),
                      Text('Capítulos vistos', style: TextStyle(
                        fontFamily: 'PlayfairDisplay', fontSize: 18,
                        fontWeight: FontWeight.w700, color: t.textPrimary)),
                      Spacer(),
                      Text(widget.title, style: TextStyle(
                        color: t.textSecondary, fontSize: 12)),
                    ]),
                    const SizedBox(height: 20),

                    ...List.generate(widget.totalSeasons, (idx) {
                      final s = idx + 1;
                      final watched = _watched[s.toString()] ?? [];
                      final epsInSeason = widget.totalEpisodes;
                      final progress = watched.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('Temporada $s', style: TextStyle(
                              color: t.textPrimary, fontSize: 14,
                              fontWeight: FontWeight.w600)),
                            Spacer(),
                            Text('$progress/$epsInSeason', style: TextStyle(
                              color: t.accent, fontSize: 12,
                              fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: List.generate(epsInSeason, (epIdx) {
                              final ep = epIdx + 1;
                              final isWatched = watched.contains(ep);
                              return GestureDetector(
                                onTap: () => _toggleEpisode(s, ep),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: isWatched ? t.accent : t.cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isWatched ? t.accent : t.cardBorder),
                                  ),
                                  child: Center(child: Text('$ep', style: TextStyle(
                                    color: isWatched ? Colors.white : t.textPrimary,
                                    fontWeight: FontWeight.w600, fontSize: 12))),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),

                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Listo',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Poster placeholder ───────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _PosterPlaceholder({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    width: 54, height: 78,
    decoration: BoxDecoration(
      color: color.withAlpha(40),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 26),
  );
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(35),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(
        color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

// ─── Botón de acción ──────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: filled ? Colors.white : color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: filled ? Colors.white : color,
            fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

// ─── Formulario para agregar ──────────────────────────────────────────────────

class _SeriesForm extends ConsumerStatefulWidget {
  final String? coupleId;
  const _SeriesForm({required this.coupleId});

  @override
  ConsumerState<_SeriesForm> createState() => _SeriesFormState();
}

class _SeriesFormState extends ConsumerState<_SeriesForm> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<TVResult>  _results   = [];
  bool            _searching = false;
  TVDetails?      _selectedTV;
  String?         _manualTitle; // para películas sin API

  String _type   = 'SERIES';
  String _status = 'PENDING';
  bool   _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    if (_type == 'MOVIE') return; // películas: entrada manual
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await ref.read(tvMazeServiceProvider).search(q);
      if (mounted) setState(() { _results = results; _searching = false; });
    });
  }

  Future<void> _selectResult(TVResult r) async {
    setState(() { _searching = true; _results = []; });
    final details = await ref.read(tvMazeServiceProvider).getDetails(r.id);
    if (!mounted) return;
    setState(() {
      _selectedTV = details;
      _searching  = false;
      _searchCtrl.text = r.title;
    });
  }

  void _clearSelection() => setState(() {
    _selectedTV  = null;
    _manualTitle = null;
    _results     = [];
    _searchCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    final t  = ref.watch(gradientThemeProvider);
    final bg = t.isLight ? const Color(0xFFFAF6FF) : Color.lerp(t.darkest, Colors.black, 0.3)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: t.accent.withAlpha(60), width: 1)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: t.accent.withAlpha(80),
                  borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: t.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add_rounded, color: t.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('Agregar título', style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: t.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _type == 'SERIES'
                          ? 'Búsqueda automática con imagen y datos reales'
                          : 'Ingresa el nombre de la película',
                      style: TextStyle(color: t.textSecondary, fontSize: 12)),
                    const SizedBox(height: 18),

                    // ── Tipo primero ──────────────────────────────────
                    Row(children: [
                      _ToggleBtn(
                        label: 'Serie', icon: Icons.tv_rounded,
                        active: _type == 'SERIES',
                        activeColor: t.accent, inactiveColor: t.textSecondary,
                        cardBg: t.cardBg, cardBorder: t.cardBorder,
                        onTap: () => setState(() {
                          _type = 'SERIES';
                          _clearSelection();
                        })),
                      const SizedBox(width: 10),
                      _ToggleBtn(
                        label: 'Película', icon: Icons.movie_rounded,
                        active: _type == 'MOVIE',
                        activeColor: t.accent, inactiveColor: t.textSecondary,
                        cardBg: t.cardBg, cardBorder: t.cardBorder,
                        onTap: () => setState(() {
                          _type = 'MOVIE';
                          _clearSelection();
                        })),
                    ]),
                    const SizedBox(height: 14),

                    // ── Búsqueda / input ──────────────────────────────
                    if (_selectedTV == null) ...[
                      TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: TextStyle(color: t.textPrimary),
                        cursorColor: t.accent,
                        decoration: _deco(t,
                          _type == 'SERIES' ? 'Breaking Bad, Stranger Things…' : 'Dune, Inception…'
                        ).copyWith(
                          prefixIcon: Icon(
                            _type == 'SERIES' ? Icons.search_rounded : Icons.edit_rounded,
                            color: t.textSecondary, size: 20),
                          suffixIcon: _searching
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        color: t.accent, strokeWidth: 2)))
                              : null,
                        ),
                      ),
                      // Resultados de búsqueda
                      if (_results.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: t.surfaceBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.cardBorder),
                          ),
                          child: Column(
                            children: _results.asMap().entries.map((e) {
                              final r      = e.value;
                              final isLast = e.key == _results.length - 1;
                              return Column(children: [
                                InkWell(
                                  onTap: () => _selectResult(r),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(children: [
                                      // Mini póster
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: r.posterUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: r.posterUrl!,
                                                width: 36, height: 52,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) =>
                                                    _miniPosterFallback(t))
                                            : _miniPosterFallback(t),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.title, style: TextStyle(
                                            color: t.textPrimary, fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          Row(children: [
                                            if ((r.rating ?? 0) > 0) ...[
                                              Icon(Icons.star_rounded,
                                                  color: const Color(0xFFD4A847), size: 12),
                                              const SizedBox(width: 3),
                                              Text(r.rating!.toStringAsFixed(1),
                                                  style: TextStyle(
                                                      color: t.textSecondary, fontSize: 11)),
                                              const SizedBox(width: 8),
                                            ],
                                            if (r.premiered?.isNotEmpty == true)
                                              Text(r.premiered!.substring(0, 4),
                                                  style: TextStyle(
                                                      color: t.textSecondary, fontSize: 11)),
                                            if (r.status?.isNotEmpty == true) ...[
                                              Text('  ·  ${r.status}',
                                                  style: TextStyle(
                                                      color: t.textSecondary, fontSize: 11)),
                                            ],
                                          ]),
                                        ],
                                      )),
                                      Icon(Icons.add_rounded, color: t.accent, size: 20),
                                    ]),
                                  ),
                                ),
                                if (!isLast) Divider(height: 1,
                                    color: t.divider, indent: 14, endIndent: 14),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ] else ...[
                      // Serie seleccionada — vista previa
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: t.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.accent.withAlpha(70)),
                        ),
                        child: Row(children: [
                          if (_selectedTV!.posterUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                  imageUrl: _selectedTV!.posterUrl!,
                                  width: 44, height: 64, fit: BoxFit.cover),
                            ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedTV!.title, style: TextStyle(
                                color: t.textPrimary, fontSize: 14,
                                fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedTV!.totalSeasons} temporadas · ${_selectedTV!.totalEpisodes} ep.',
                                style: TextStyle(color: t.textSecondary, fontSize: 12)),
                            ],
                          )),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: t.textSecondary, size: 20),
                            onPressed: _clearSelection),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 14),
                    _Label(t: t, text: 'Estado inicial'),
                    const SizedBox(height: 8),
                    Row(children: [
                      _ToggleBtn(
                        label: 'Viendo', icon: Icons.play_arrow_rounded,
                        active: _status == 'WATCHING',
                        activeColor: t.accent, inactiveColor: t.textSecondary,
                        cardBg: t.cardBg, cardBorder: t.cardBorder,
                        onTap: () => setState(() => _status = 'WATCHING')),
                      const SizedBox(width: 10),
                      _ToggleBtn(
                        label: 'Por ver', icon: Icons.bookmark_rounded,
                        active: _status == 'PENDING',
                        activeColor: t.accent, inactiveColor: t.textSecondary,
                        cardBg: t.cardBg, cardBorder: t.cardBorder,
                        onTap: () => setState(() => _status = 'PENDING')),
                    ]),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: (_loading || (_selectedTV == null && _searchCtrl.text.trim().isEmpty))
                          ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Agregar a la lista',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _selectedTV?.title ?? _searchCtrl.text.trim();
    if (title.isEmpty) return;

    final auth     = ref.read(authProvider);
    final coupleId = auth.coupleId;
    final uid      = auth.firebaseUser?.uid;

    if (coupleId == null && uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No hay sesión')));
      }
      return;
    }

    setState(() => _loading = true);

    final data = <String, dynamic>{
      'title':     title,
      'type':      _type,
      'status':    _status,
      'posterUrl': _selectedTV?.posterUrl,
      'overview':  _selectedTV?.summary,
      'tvmazeId':  _selectedTV?.id,
    };

    if (_type == 'SERIES' && _selectedTV != null) {
      data['totalSeasons']  = _selectedTV!.totalSeasons;
      data['totalEpisodes'] = _selectedTV!.totalEpisodes;
      if (_status == 'WATCHING') {
        data['currentSeason']  = 1;
        data['currentEpisode'] = 1;
      }
    }

    try {
      final svc = ref.read(firestoreServiceProvider);
      if (coupleId != null) {
        await svc.createSeries(coupleId, data);
      } else if (uid != null) {
        await svc.createUserSeries(uid, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('DEBUG _save error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: ${e.toString().substring(0, 100)}')));
      }
    }
  }

  Widget _miniPosterFallback(GradientTheme t) => Container(
    width: 36, height: 52,
    decoration: BoxDecoration(
      color: t.accentSoft, borderRadius: BorderRadius.circular(6)),
    child: Icon(Icons.tv_rounded, color: t.accent, size: 18),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final GradientTheme t;
  final String text;
  const _Label({required this.t, required this.text});
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(
    color: t.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label, required this.icon,
    required this.active, required this.activeColor,
    required this.inactiveColor, required this.cardBg,
    required this.cardBorder, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: active ? activeColor : cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? activeColor : cardBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? Colors.white : inactiveColor, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          color: active ? Colors.white : inactiveColor,
          fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

InputDecoration _deco(GradientTheme t, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: t.textSecondary),
  filled: true,
  fillColor: t.isLight ? Colors.black.withAlpha(6) : Colors.white.withAlpha(12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.accent, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);
