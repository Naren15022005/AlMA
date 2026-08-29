import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';

// ─── Modelo unificado de entrada ──────────────────────────────────────────────

enum _EntryType { diary, thought, series }

class _TimelineEntry {
  final _EntryType type;
  final DateTime date;
  final Map<String, dynamic> data;
  const _TimelineEntry({required this.type, required this.date, required this.data});
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _diaryEntriesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (auth.coupleId != null && auth.uid != null) return svc.diaryStream(auth.coupleId!, auth.uid!);
  if (auth.uid != null) return svc.userDiaryStream(auth.uid!);
  return Stream.value([]);
});

final _thoughtsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.coupleId == null || auth.uid == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).thoughtsReceivedStream(auth.coupleId!, auth.uid!);
});

final _seriesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (auth.coupleId != null) return svc.seriesStream(auth.coupleId!);
  if (auth.uid != null) return svc.userSeriesStream(auth.uid!);
  return Stream.value([]);
});

// ─── Timeline combinado y agrupado por día ────────────────────────────────────

final _timelineProvider = Provider.autoDispose<Map<String, List<_TimelineEntry>>>((ref) {
  final diaryAsync = ref.watch(_diaryEntriesProvider);
  final thoughtsAsync = ref.watch(_thoughtsProvider);
  final seriesAsync = ref.watch(_seriesProvider);

  final all = <_TimelineEntry>[];

  diaryAsync.whenData((items) {
    for (final e in items) {
      DateTime? dt;
      final raw = e['entryDate'];
      if (raw is Timestamp) {
        dt = raw.toDate();
      } else if (raw is String) {
        dt = DateTime.tryParse(raw);
      }
      dt ??= DateTime.now();
      all.add(_TimelineEntry(type: _EntryType.diary, date: dt, data: e));
    }
  });

  thoughtsAsync.whenData((items) {
    for (final e in items) {
      DateTime? dt;
      final raw = e['createdAt'];
      if (raw is Timestamp) dt = raw.toDate();
      dt ??= DateTime.now();
      all.add(_TimelineEntry(type: _EntryType.thought, date: dt, data: e));
    }
  });

  seriesAsync.whenData((items) {
    for (final e in items) {
      DateTime? dt;
      final raw = e['createdAt'] ?? e['updatedAt'];
      if (raw is Timestamp) dt = raw.toDate();
      dt ??= DateTime.now();
      all.add(_TimelineEntry(type: _EntryType.series, date: dt, data: e));
    }
  });

  all.sort((a, b) => b.date.compareTo(a.date));

  final grouped = <String, List<_TimelineEntry>>{};
  for (final entry in all) {
    final key = DateFormat('yyyy-MM-dd').format(entry.date);
    grouped.putIfAbsent(key, () => []).add(entry);
  }
  return grouped;
});

// ─── Página principal ─────────────────────────────────────────────────────────

class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(gradientThemeProvider);
    final timeline = ref.watch(_timelineProvider);
    final auth = ref.watch(authProvider);
    final sortedKeys = timeline.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: t.darkest,
      body: Container(
        decoration: BoxDecoration(gradient: t.gradient),
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(child: _DiaryHeader(t: t)),

            // ── Vacío ────────────────────────────────────────────────────────
            if (sortedKeys.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        color: t.textSecondary.withAlpha(80), size: 64),
                    const SizedBox(height: 16),
                    Text('Aún no hay recuerdos',
                        style: TextStyle(color: t.textSecondary, fontSize: 16,
                            fontFamily: 'PlayfairDisplay')),
                    const SizedBox(height: 8),
                    Text('Todo lo que vivan juntos aparecerá aquí',
                        style: TextStyle(color: t.textSecondary.withAlpha(150), fontSize: 13)),
                  ],
                ),
              ),

            // ── Entradas agrupadas por día ───────────────────────────────────
            for (final dateKey in sortedKeys) ...[
              SliverToBoxAdapter(
                child: _DateDivider(dateKey: dateKey, t: t),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverList.builder(
                  itemCount: timeline[dateKey]!.length,
                  itemBuilder: (_, i) {
                    final entry = timeline[dateKey]![i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EntryCard(entry: entry, t: t, uid: auth.uid ?? ''),
                    );
                  },
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: t.accent,
        onPressed: () => _showWriteSheet(context, ref, t, auth.coupleId, auth.uid),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
    );
  }

  void _showWriteSheet(BuildContext context, WidgetRef ref, GradientTheme t, String? coupleId, String? uid) {
    final ctrl = TextEditingController();
    String mood = '🥰';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 28,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          decoration: BoxDecoration(
            color: Color.lerp(t.darkest, Colors.black, 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: t.accent.withAlpha(60), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text('Nueva entrada',
                    style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20,
                        color: t.textPrimary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: ['🥰', '😊', '😔', '😍', '😤', '😴', '😰', '😎'].map((e) =>
                  GestureDetector(
                    onTap: () => setSt(() => mood = e),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mood == e ? t.accent.withAlpha(60) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: mood == e ? t.accent : Colors.transparent, width: 1.5),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 5,
                style: TextStyle(color: t.textPrimary, height: 1.6),
                cursorColor: t.accent,
                decoration: InputDecoration(
                  hintText: 'Escribe lo que sientes...',
                  hintStyle: TextStyle(color: t.textSecondary),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: t.accent, width: 1.5)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  final svc = ref.read(firestoreServiceProvider);
                  final data = {
                    'content': ctrl.text.trim(),
                    'mood': mood,
                    'isPrivate': false,
                    'entryDate': DateTime.now().toIso8601String(),
                  };
                  if (coupleId != null) {
                    await svc.createDiaryEntry(coupleId, data);
                  } else if (uid != null) {
                    await svc.createUserDiaryEntry(uid, data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Guardar en el diario',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header del diario ────────────────────────────────────────────────────────

class _DiaryHeader extends StatelessWidget {
  final GradientTheme t;
  const _DiaryHeader({required this.t});

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('MMMM, yyyy', 'es').format(DateTime.now());
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: t.textPrimary.withAlpha(180), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Icon(Icons.auto_stories_rounded, color: t.accent, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text('Nuestro Diario',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary,
                )),
            const SizedBox(height: 4),
            Text(now,
                style: TextStyle(
                  fontSize: 13,
                  color: t.textSecondary,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 20),
            Divider(color: t.accent.withAlpha(50), thickness: 1),
          ],
        ),
      ),
    );
  }
}

// ─── Separador de fecha ───────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final String dateKey;
  final GradientTheme t;
  const _DateDivider({required this.dateKey, required this.t});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
    final label = isToday
        ? 'Hoy'
        : DateFormat('EEEE, d \'de\' MMMM', 'es').format(dt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: t.accent.withAlpha(40))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: t.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.accent.withAlpha(60)),
            ),
            child: Text(label,
                style: TextStyle(
                  color: t.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: t.accent.withAlpha(40))),
        ],
      ),
    );
  }
}

// ─── Tarjeta de entrada ───────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final _TimelineEntry entry;
  final GradientTheme t;
  final String uid;
  const _EntryCard({required this.entry, required this.t, required this.uid});

  @override
  Widget build(BuildContext context) {
    return switch (entry.type) {
      _EntryType.diary   => _DiaryCard(entry: entry, t: t, uid: uid),
      _EntryType.thought => _ThoughtCard(entry: entry, t: t, uid: uid),
      _EntryType.series  => _SeriesCard(entry: entry, t: t),
    };
  }
}

// ── Entrada de diario escrita ──────────────────────────────────────────────────

class _DiaryCard extends StatelessWidget {
  final _TimelineEntry entry;
  final GradientTheme t;
  final String uid;
  const _DiaryCard({required this.entry, required this.t, required this.uid});

  @override
  Widget build(BuildContext context) {
    final data = entry.data;
    final isMine = data['authorId'] == uid;
    final cardBg = t.isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: t.accent, width: 3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(data['mood'] ?? '📝', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(isMine ? 'Escribí' : 'Tu pareja escribió',
                    style: TextStyle(color: t.textSecondary, fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(DateFormat('HH:mm').format(entry.date),
                    style: TextStyle(color: t.textSecondary, fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              Text(data['content'] ?? '',
                  style: TextStyle(color: t.textPrimary, fontSize: 14,
                      height: 1.6, fontStyle: FontStyle.italic)),
              if (data['partnerReacted'] == true) ...[
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.favorite_rounded, size: 13, color: t.accent),
                  const SizedBox(width: 5),
                  Text('Le encantó a tu pareja',
                      style: TextStyle(fontSize: 12, color: t.textSecondary)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pensamiento ────────────────────────────────────────────────────────────────

class _ThoughtCard extends StatelessWidget {
  final _TimelineEntry entry;
  final GradientTheme t;
  final String uid;
  const _ThoughtCard({required this.entry, required this.t, required this.uid});

  @override
  Widget build(BuildContext context) {
    final data = entry.data;
    final accentColor = Color.lerp(t.accent, Colors.pink, 0.4)!;
    final cardBg = t.isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: accentColor, width: 3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pensamiento recibido',
                        style: TextStyle(color: t.textSecondary, fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(data['message'] ?? data['content'] ?? '♥',
                        style: TextStyle(color: t.textPrimary, fontSize: 14,
                            fontStyle: FontStyle.italic, height: 1.5)),
                  ],
                ),
              ),
              Text(DateFormat('HH:mm').format(entry.date),
                  style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Serie/Película ─────────────────────────────────────────────────────────────

class _SeriesCard extends StatelessWidget {
  final _TimelineEntry entry;
  final GradientTheme t;
  const _SeriesCard({required this.entry, required this.t});

  @override
  Widget build(BuildContext context) {
    final data = entry.data;
    final isCompleted = data['status'] == 'COMPLETED';
    final accentColor = isCompleted
        ? Color.lerp(t.accent, Colors.green, 0.4)!
        : Color.lerp(t.accent, Colors.blue, 0.3)!;
    final cardBg = t.isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: accentColor, width: 3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.play_circle_rounded,
                    color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isCompleted ? 'Completaron' : 'Empezaron a ver',
                        style: TextStyle(color: t.textSecondary, fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(data['title'] ?? 'Serie',
                        style: TextStyle(color: t.textPrimary, fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text(DateFormat('HH:mm').format(entry.date),
                  style: TextStyle(color: t.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
