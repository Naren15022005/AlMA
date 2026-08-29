import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/gradient_theme.dart';
import '../../../auth/providers/auth_provider.dart';

// ─── Modelos y servicios de música ───────────────────────────────────────────

class MusicResult {
  final String title;
  final String artist;
  final String? album;
  final String? artworkUrl;
  const MusicResult({required this.title, required this.artist,
      this.album, this.artworkUrl});

  factory MusicResult.fromItunes(Map<String, dynamic> j) => MusicResult(
    title:      j['trackName'] as String? ?? '',
    artist:     j['artistName'] as String? ?? '',
    album:      j['collectionName'] as String?,
    artworkUrl: (j['artworkUrl100'] as String?)
        ?.replaceAll('100x100', '300x300'),
  );
}

class _MusicService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<List<MusicResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': query.trim(),
        'media': 'music',
        'limit': '12',
        'country': 'US',
      });
      final res = await _dio.getUri(
        uri,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = res.data is String
          ? jsonDecode(res.data as String) as Map<String, dynamic>
          : res.data as Map<String, dynamic>;
      final list = (data['results'] as List<dynamic>);
      return list
          .map((r) => MusicResult.fromItunes(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Music search error: $e');
      return [];
    }
  }

  static Future<String?> fetchLyrics(String artist, String track) async {
    for (final a in [artist, _titleCase(artist), artist.toLowerCase()]) {
      for (final t in [track, _titleCase(track), track.toLowerCase()]) {
        try {
          final uri = Uri.https('api.lyrics.ovh', '/v1/$a/$t');
          final res = await _dio.getUri(uri);
          if (res.statusCode == 200) {
            final lyrics = res.data['lyrics'] as String?;
            if (lyrics != null && lyrics.isNotEmpty) {
              return lyrics.split('\n').take(20).join('\n').trim();
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static String _titleCase(String s) => s.split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _receivedProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.coupleId == null || auth.uid == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).thoughtsReceivedStream(auth.coupleId!, auth.uid!);
});

final _sentProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.coupleId == null || auth.uid == null) return Stream.value([]);
  return ref.read(firestoreServiceProvider).thoughtsSentStream(auth.coupleId!, auth.uid!);
});

// ─── Página ───────────────────────────────────────────────────────────────────

class ThoughtsPage extends ConsumerStatefulWidget {
  const ThoughtsPage({super.key});

  @override
  ConsumerState<ThoughtsPage> createState() => _ThoughtsPageState();
}

class _ThoughtsPageState extends ConsumerState<ThoughtsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(gradientThemeProvider);

    return Scaffold(
      backgroundColor: t.darkest,
      body: Container(
        decoration: BoxDecoration(gradient: t.gradient),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nav row
                    Row(children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_rounded,
                            color: t.textPrimary.withAlpha(180), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: t.accent.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(color: t.accent.withAlpha(60)),
                        ),
                        child: Icon(Icons.favorite_rounded, color: t.accent, size: 16),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pensamientos',
                              style: TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary,
                                letterSpacing: -0.5,
                              )),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(width: 4, height: 4,
                                decoration: BoxDecoration(
                                    color: t.accent, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('Lo que sientes por tu pareja',
                                style: TextStyle(fontSize: 13, color: t.textSecondary,
                                    letterSpacing: 0.2)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Tabs integrados en el header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(12)),
                        ),
                        child: TabBar(
                          controller: _tabs,
                          indicator: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              t.accent,
                              Color.lerp(t.accent, Colors.black, 0.2)!,
                            ]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: t.textSecondary,
                          labelStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          unselectedLabelStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w400),
                          tabs: const [
                            Tab(text: 'Recibidos'),
                            Tab(text: 'Enviados'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            // ── Lista ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ThoughtList(isReceived: true, t: t),
                  _ThoughtList(isReceived: false, t: t),
                ],
              ),
            ),
            // ── Footer: solo en Enviados ──────────────────────────────────
            AnimatedBuilder(
              animation: _tabs,
              builder: (_, __) => _tabs.index == 1
                  ? _ComposeFooter(t: t, ref: ref)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer de composición ────────────────────────────────────────────────────

class _ComposeFooter extends StatefulWidget {
  final GradientTheme t;
  final WidgetRef ref;
  const _ComposeFooter({required this.t, required this.ref});

  @override
  State<_ComposeFooter> createState() => _ComposeFooterState();
}

class _ComposeFooterState extends State<_ComposeFooter> {
  final _textCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _hasText = false;

  _AttachType _attach = _AttachType.none;
  Uint8List? _imageBytes;
  String?   _imageName;
  bool _sending = false;

  List<MusicResult> _musicResults = [];
  bool _searchingMusic = false;
  MusicResult? _selectedMusic;
  DateTime? _lastSearch;

  GradientTheme get t => widget.t;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final has = _textCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMusic(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _musicResults = []; _searchingMusic = false; });
      return;
    }
    if (q.trim().length < 2) return;
    final now = DateTime.now();
    _lastSearch = now;
    await Future.delayed(const Duration(milliseconds: 400));
    if (_lastSearch != now || !mounted) return;
    setState(() => _searchingMusic = true);
    final results = await _MusicService.search(q);
    if (mounted) setState(() { _musicResults = results; _searchingMusic = false; });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _musicResults = []; _searchingMusic = false; });
  }

  void _selectMusic(MusicResult r) {
    setState(() {
      _selectedMusic = r;
      _attach = _AttachType.music;
      _musicResults = [];
      _searchCtrl.text = '${r.title} — ${r.artist}';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _imageBytes = bytes; _imageName = xfile.name; });
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageBytes == null) return null;
    final ext = _imageName?.split('.').last ?? 'jpg';
    final ref = FirebaseStorage.instance
        .ref('users/$uid/thoughts/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/$ext'));
    return ref.getDownloadURL();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    debugPrint('_send (footer) started: text="$text", attach=$_attach, music=$_selectedMusic');
    if (text.isEmpty && _attach == _AttachType.none) return;
    setState(() => _sending = true);
    try {
      final auth = widget.ref.read(authProvider);
      debugPrint('Auth: coupleId=${auth.coupleId}, uid=${auth.uid}');
      if (auth.uid == null) return;

      late final String coupleId;
      late final String recipientId;

      if (auth.coupleId != null) {
        coupleId = auth.coupleId!;
        final coupleDoc = await FirebaseFirestore.instance
            .collection('couples').doc(coupleId).get();
        debugPrint('Couple doc retrieved');
        final coupleData = coupleDoc.data()!;
        recipientId = coupleData['user1Id'] == auth.uid
            ? coupleData['user2Id'] as String
            : coupleData['user1Id'] as String;
        debugPrint('Recipient: $recipientId');
      } else {
        coupleId = 'test_couple';
        recipientId = 'test_recipient';
        debugPrint('No couple linked, using test values');
      }
      final data = <String, dynamic>{
        'content': text, 'tone': 'ROMANTIC',
        'type': _attach.name.toUpperCase(),
      };
      if (_attach == _AttachType.image && _imageBytes != null) {
        final url = await _uploadImage(auth.uid!);
        if (url != null) data['imageUrl'] = url;
      }
      if (_attach == _AttachType.music && _selectedMusic != null) {
        data['music'] = {
          'title': _selectedMusic!.title,
          'artist': _selectedMusic!.artist,
          'album': _selectedMusic!.album ?? '',
          'artworkUrl': _selectedMusic!.artworkUrl ?? '',
        };
      }
      debugPrint('About to create thought: $data');
      await widget.ref.read(firestoreServiceProvider)
          .createThought(coupleId, recipientId, data);
      debugPrint('Thought created successfully');
      _textCtrl.clear();
      setState(() { _attach = _AttachType.none; _imageBytes = null;
        _selectedMusic = null; _searchCtrl.clear(); });
    } catch (e) {
      debugPrint('Error in _send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _buildAttachMenu() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _InlineAttachBtn(icon: Icons.image_rounded, active: _attach == _AttachType.image,
          color: const Color(0xFF7BAAD4), t: t,
          onTap: () async {
            if (_attach == _AttachType.image) {
              setState(() { _attach = _AttachType.none; _imageBytes = null; });
            } else {
              setState(() => _attach = _AttachType.image);
              await _pickImage();
            }
          }),
      const SizedBox(width: 4),
      _InlineAttachBtn(icon: Icons.music_note_rounded, active: _attach == _AttachType.music,
          color: const Color(0xFFD47090), t: t,
          onTap: () => setState(() => _attach =
              _attach == _AttachType.music ? _AttachType.none : _AttachType.music)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen preview
            if (_attach == _AttachType.image && _imageBytes != null) ...[
              Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_imageBytes!, height: 140,
                        width: double.infinity, fit: BoxFit.cover)),
                Positioned(top: 6, right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _imageBytes = null),
                    child: Container(padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: Colors.black54,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 15)),
                  )),
              ]),
              const SizedBox(height: 8),
            ],
            // Canción seleccionada
            if (_attach == _AttachType.music && _selectedMusic != null) ...[
              _SelectedMusicCard(
                music: _selectedMusic!, t: t,
                onClear: () => setState(() {
                  _selectedMusic = null; _searchCtrl.clear();
                }),
              ),
              const SizedBox(height: 8),
            ],
            // Input row
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _buildAttachMenu(),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const SizedBox(width: 12),
                    Icon(Icons.sentiment_satisfied_alt_rounded,
                        color: t.textSecondary.withAlpha(160), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _attach == _AttachType.music && _selectedMusic == null
                          ? TextField(
                              controller: _searchCtrl, autofocus: false,
                              style: TextStyle(color: t.textPrimary, fontSize: 14),
                              cursorColor: t.accent,
                              onChanged: _searchMusic, onSubmitted: _searchMusic,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Busca una canción…',
                                hintStyle: TextStyle(color: t.textSecondary.withAlpha(120)),
                                counterText: '', isDense: true,
                                filled: true, fillColor: Colors.transparent,
                                border: InputBorder.none, enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
                              ))
                          : TextField(
                              controller: _textCtrl, maxLines: 1, maxLength: 500,
                              style: TextStyle(color: t.textPrimary, fontSize: 14),
                              cursorColor: t.accent,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje',
                                hintStyle: TextStyle(color: t.textSecondary.withAlpha(120)),
                                counterText: '', isDense: true,
                                filled: true, fillColor: Colors.transparent,
                                border: InputBorder.none, enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
                              )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _searchingMusic
                          ? SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: t.accent, strokeWidth: 2))
                          : _attach == _AttachType.music && _searchCtrl.text.isNotEmpty
                              ? GestureDetector(onTap: _clearSearch,
                                  child: Icon(Icons.close_rounded, color: t.textSecondary, size: 18))
                              : Icon(Icons.mic_rounded, color: t.textSecondary.withAlpha(160), size: 22),
                    ),
                  ]),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: (_hasText || _selectedMusic != null ||
                        _imageBytes != null || _sending)
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _sending ? null : () {
                            debugPrint('Send button tapped (footer), attach=$_attach, music=$_selectedMusic');
                            _send();
                          },
                          child: Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [t.accent,
                                  Color.lerp(t.accent, Colors.black, 0.25)!]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: t.accent.withAlpha(70),
                                  blurRadius: 12, offset: const Offset(0, 3))],
                            ),
                            child: _sending
                                ? const Padding(padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ))
                    : const SizedBox.shrink(),
              ),
            ]),
            // Resultados de música
            if (_attach == _AttachType.music && _musicResults.isNotEmpty && _selectedMusic == null) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(color: Colors.white.withAlpha(6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(12))),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _musicResults.length,
                    itemBuilder: (_, i) {
                      final r = _musicResults[i];
                      return Material(color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectMusic(r),
                          splashColor: t.accent.withAlpha(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(8),
                                child: r.artworkUrl != null
                                    ? CachedNetworkImage(imageUrl: r.artworkUrl!,
                                        width: 44, height: 44, fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => _artworkPlaceholder(t))
                                    : _artworkPlaceholder(t)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: TextStyle(color: t.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(r.artist, style: TextStyle(color: t.accent, fontSize: 11),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                              Icon(Icons.add_rounded, color: t.accent, size: 18),
                            ]),
                          ),
                        ));
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Compose sheet (mantenido por compatibilidad) ─────────────────────────────

enum _AttachType { none, image, music }

class _ComposeSheet extends StatefulWidget {
  final GradientTheme t;
  final WidgetRef ref;
  const _ComposeSheet({required this.t, required this.ref});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _textCtrl   = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _hasText = false;

  _AttachType _attach = _AttachType.none;
  String _tone = 'ROMANTIC';
  Uint8List? _imageBytes;
  String?   _imageName;
  bool _sending = false;

  // Música
  List<MusicResult> _musicResults = [];
  bool _searchingMusic = false;
  MusicResult? _selectedMusic;
  String? _lyrics;
  bool _fetchingLyrics = false;
  DateTime? _lastSearch;

  GradientTheme get t => widget.t;

  static const _tones = [
    ('ROMANTIC',  '🌹', 'Romántico',  Color(0xFFE879A0)),
    ('FUNNY',     '😂', 'Gracioso',   Color(0xFFFFB347)),
    ('NOSTALGIC', '🌅', 'Nostálgico', Color(0xFF87CEEB)),
    ('TENDER',    '🥰', 'Tierno',     Color(0xFFB39DDB)),
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      final has = _textCtrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMusic(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _musicResults = []; _searchingMusic = false; });
      return;
    }
    if (q.trim().length < 2) return;

    // Debounce 400ms
    final now = DateTime.now();
    _lastSearch = now;
    await Future.delayed(const Duration(milliseconds: 400));
    if (_lastSearch != now || !mounted) return;

    setState(() => _searchingMusic = true);
    final results = await _MusicService.search(q);
    if (mounted) setState(() { _musicResults = results; _searchingMusic = false; });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() { _musicResults = []; _searchingMusic = false; });
  }

  void _selectMusic(MusicResult r) {
    setState(() {
      _selectedMusic = r;
      _attach = _AttachType.music;
      _musicResults = [];
      _searchCtrl.text = '${r.title} — ${r.artist}';
    });
  }

  Widget _buildAttachMenu(GradientTheme t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InlineAttachBtn(
          icon: Icons.image_rounded,
          active: _attach == _AttachType.image,
          color: const Color(0xFF7BAAD4),
          t: t,
          onTap: () async {
            if (_attach == _AttachType.image) {
              setState(() { _attach = _AttachType.none; _imageBytes = null; });
            } else {
              setState(() => _attach = _AttachType.image);
              await _pickImage();
            }
          },
        ),
        const SizedBox(width: 6),
        _InlineAttachBtn(
          icon: Icons.music_note_rounded,
          active: _attach == _AttachType.music,
          color: const Color(0xFFD47090),
          t: t,
          onTap: () => setState(() => _attach =
              _attach == _AttachType.music ? _AttachType.none : _AttachType.music),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _imageBytes = bytes; _imageName = xfile.name; });
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageBytes == null) return null;
    final ext  = _imageName?.split('.').last ?? 'jpg';
    final ref  = FirebaseStorage.instance
        .ref('users/$uid/thoughts/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putData(_imageBytes!, SettableMetadata(contentType: 'image/$ext'));
    return ref.getDownloadURL();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _attach == _AttachType.none) return;

    setState(() => _sending = true);
    try {
      final auth = widget.ref.read(authProvider);
      debugPrint('Send: auth.coupleId=${auth.coupleId}, uid=${auth.uid}, attach=$_attach, music=$_selectedMusic');
      if (auth.uid == null) return;

      late final String coupleId;
      late final String recipientId;

      if (auth.coupleId != null) {
        coupleId = auth.coupleId!;
        final coupleDoc = await FirebaseFirestore.instance
            .collection('couples').doc(coupleId).get();
        final coupleData = coupleDoc.data()!;
        recipientId = coupleData['user1Id'] == auth.uid
            ? coupleData['user2Id'] as String
            : coupleData['user1Id'] as String;
      } else {
        coupleId = 'test_couple';
        recipientId = 'test_recipient';
        debugPrint('No couple linked, using test values');
      }

      final data = <String, dynamic>{
        'content': text,
        'tone': _tone,
        'type': _attach.name.toUpperCase(),
      };

      if (_attach == _AttachType.image && _imageBytes != null) {
        final url = await _uploadImage(auth.uid!);
        if (url != null) data['imageUrl'] = url;
      }

      if (_attach == _AttachType.music && _selectedMusic != null) {
        data['music'] = {
          'title':      _selectedMusic!.title,
          'artist':     _selectedMusic!.artist,
          'album':      _selectedMusic!.album ?? '',
          'artworkUrl': _selectedMusic!.artworkUrl ?? '',
          'lyrics':     _lyrics ?? '',
        };
      }

      await widget.ref.read(firestoreServiceProvider)
          .createThought(coupleId, recipientId, data);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = Color.lerp(t.darkest, Colors.black, 0.3)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header row
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nuevo pensamiento',
                          style: TextStyle(fontFamily: 'PlayfairDisplay',
                              fontSize: 22, color: t.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('¿Qué quieres compartir hoy?',
                          style: TextStyle(color: t.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: t.textSecondary, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withAlpha(12), height: 1),
              const SizedBox(height: 16),

              // ── Imagen preview (solo cuando está activa) ──────────────────
              if (_attach == _AttachType.image) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _imageBytes != null
                      ? Stack(children: [
                          Image.memory(_imageBytes!, height: 160,
                              width: double.infinity, fit: BoxFit.cover),
                          Positioned(top: 6, right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageBytes = null),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                    color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 15),
                              ),
                            )),
                        ])
                      : Container(height: 0),
                ),
              ],

              // ── Canción seleccionada (solo cuando está activa) ────────────
              if (_attach == _AttachType.music && _selectedMusic != null) ...[
                const SizedBox(height: 8),
                _SelectedMusicCard(
                  music: _selectedMusic!, t: t,
                  onClear: () => setState(() {
                    _selectedMusic = null; _searchCtrl.clear();
                  }),
                ),
              ],

              const SizedBox(height: 8),

              // ── Chat input ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "+" adjuntar — fuera del pill
                  _buildAttachMenu(t),
                  const SizedBox(width: 8),
                  // Pill principal
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(width: 12),
                          // Emoji
                          Icon(Icons.sentiment_satisfied_alt_rounded,
                              color: t.textSecondary.withAlpha(160), size: 22),
                          const SizedBox(width: 8),
                          // Campo de texto
                          Expanded(
                            child: _attach == _AttachType.music && _selectedMusic == null
                                ? TextField(
                                    controller: _searchCtrl,
                                    autofocus: true,
                                    style: TextStyle(color: t.textPrimary, fontSize: 14),
                                    cursorColor: t.accent,
                                    onChanged: _searchMusic,
                                    onSubmitted: _searchMusic,
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      hintText: 'Busca una canción…',
                                      hintStyle: TextStyle(
                                          color: t.textSecondary.withAlpha(120)),
                                      counterText: '',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  )
                                : TextField(
                                    controller: _textCtrl,
                                    maxLines: 1,
                                    maxLength: 500,
                                    style: TextStyle(color: t.textPrimary, fontSize: 14),
                                    cursorColor: t.accent,
                                    decoration: InputDecoration(
                                      hintText: 'Escribe un mensaje',
                                      hintStyle: TextStyle(
                                          color: t.textSecondary.withAlpha(120)),
                                      counterText: '',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                          ),
                          // Ícono derecho: loading, X, o mic
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _searchingMusic
                                ? SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        color: t.accent, strokeWidth: 2))
                                : _attach == _AttachType.music && _searchCtrl.text.isNotEmpty
                                    ? GestureDetector(
                                        onTap: _clearSearch,
                                        child: Icon(Icons.close_rounded,
                                            color: t.textSecondary, size: 18))
                                    : Icon(Icons.mic_rounded,
                                        color: t.textSecondary.withAlpha(160), size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botón enviar — aparece solo con contenido
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: (_hasText || (_attach == _AttachType.music && _selectedMusic != null) ||
                            (_attach == _AttachType.image && _imageBytes != null) || _sending)
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _sending ? null : () {
                                debugPrint('Send button tapped, attach=$_attach, music=$_selectedMusic');
                                _send();
                              },
                              child: Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    t.accent,
                                    Color.lerp(t.accent, Colors.black, 0.25)!,
                                  ]),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                      color: t.accent.withAlpha(70),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3))],
                                ),
                                child: _sending
                                    ? const Padding(padding: EdgeInsets.all(13),
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 20),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),

              // ── Resultados de música (debajo del input) ───────────────────
              if (_attach == _AttachType.music && _musicResults.isNotEmpty &&
                  _selectedMusic == null) ...[
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _musicResults.length,
                      itemBuilder: (_, i) {
                        final r = _musicResults[i];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectMusic(r),
                            splashColor: t.accent.withAlpha(30),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: r.artworkUrl != null
                                      ? CachedNetworkImage(imageUrl: r.artworkUrl!,
                                          width: 44, height: 44, fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => _artworkPlaceholder(t))
                                      : _artworkPlaceholder(t),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, style: TextStyle(color: t.textPrimary,
                                        fontSize: 13, fontWeight: FontWeight.w600),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(r.artist, style: TextStyle(color: t.accent,
                                        fontSize: 11), maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                )),
                                Icon(Icons.add_rounded, color: t.accent, size: 18),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],



            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAttachBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final GradientTheme t;
  final VoidCallback onTap;
  const _InlineAttachBtn({required this.icon, required this.active,
      required this.color, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? color.withAlpha(35) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon,
          color: active ? color : t.textSecondary.withAlpha(160), size: 20),
    ),
  );
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final GradientTheme t;
  final bool active;
  final VoidCallback onTap;
  const _AttachOption({required this.icon, required this.label, required this.color,
      required this.t, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: active ? color.withAlpha(60) : color.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: active ? color : color.withAlpha(60), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(color: t.textSecondary, fontSize: 12,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ChatAttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final GradientTheme t;
  final VoidCallback onTap;
  const _ChatAttachBtn({required this.icon, required this.label,
      required this.active, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? t.accent.withAlpha(50) : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? t.accent.withAlpha(180) : Colors.white.withAlpha(20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? t.accent : t.textSecondary, size: 14),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(
            color: active ? t.accent : t.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final GradientTheme t;
  final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label, required this.active,
      required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? t.accent.withAlpha(40) : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? t.accent : Colors.white.withAlpha(25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: active ? t.accent : t.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
            color: active ? t.accent : t.textSecondary,
            fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

Widget _artworkPlaceholder(GradientTheme t) => Container(
  width: 50, height: 50,
  color: t.accent.withAlpha(30),
  child: Icon(Icons.music_note_rounded, color: t.accent, size: 22),
);

class _SelectedMusicCard extends StatelessWidget {
  final MusicResult music;
  final GradientTheme t;
  final VoidCallback onClear;
  const _SelectedMusicCard({required this.music, required this.t, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          if (music.artworkUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: music.artworkUrl!,
                width: 48, height: 48, fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(music.title,
                    style: TextStyle(color: t.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(music.artist,
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (music.album != null)
                  Text(music.album!,
                      style: TextStyle(color: t.textSecondary.withAlpha(150),
                          fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: t.textSecondary, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

// ─── Lista de pensamientos ────────────────────────────────────────────────────

class _ThoughtList extends ConsumerWidget {
  final bool isReceived;
  final GradientTheme t;
  const _ThoughtList({required this.isReceived, required this.t});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = isReceived ? ref.watch(_receivedProvider) : ref.watch(_sentProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (thoughts) => thoughts.isEmpty
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border_rounded,
                  color: t.textSecondary.withAlpha(80), size: 56),
              const SizedBox(height: 14),
              Text(isReceived ? 'Aún no hay pensamientos recibidos'
                             : 'Aún no has enviado pensamientos',
                  style: TextStyle(color: t.textSecondary, fontSize: 15,
                      fontFamily: 'PlayfairDisplay')),
            ])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
              itemCount: thoughts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ThoughtCard(thought: thoughts[i], t: t),
            ),
    );
  }
}

// ─── Tarjeta de pensamiento ───────────────────────────────────────────────────

class _ThoughtCard extends StatelessWidget {
  final Map<String, dynamic> thought;
  final GradientTheme t;
  const _ThoughtCard({required this.thought, required this.t});

  static const _toneColors = {
    'ROMANTIC': Color(0xFFE879A0), 'FUNNY': Color(0xFFFFB347),
    'NOSTALGIC': Color(0xFF87CEEB), 'TENDER': Color(0xFFB39DDB),
  };
  static const _toneEmojis = {
    'ROMANTIC': '🌹', 'FUNNY': '😂', 'NOSTALGIC': '🌅', 'TENDER': '🥰',
  };

  @override
  Widget build(BuildContext context) {
    final tone  = thought['tone'] as String? ?? 'ROMANTIC';
    final type  = thought['type'] as String? ?? 'TEXT';
    final ts    = thought['createdAt'] as Timestamp?;
    final date  = ts?.toDate();
    final color = _toneColors[tone] ?? t.accent;
    final cardBg = t.isLight ? Colors.white.withAlpha(200) : Colors.white.withAlpha(12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  Text(_toneEmojis[tone] ?? '💬',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(date != null
                      ? DateFormat('d MMM, HH:mm', 'es').format(date) : '',
                      style: TextStyle(color: t.textSecondary, fontSize: 12)),
                  const Spacer(),
                  if (thought['isRead'] == false)
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: color,
                            shape: BoxShape.circle)),
                ]),
              ),
              // Texto
              if ((thought['content'] as String? ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(thought['content'],
                      style: TextStyle(color: t.textPrimary, fontSize: 14,
                          height: 1.6, fontStyle: FontStyle.italic)),
                ),
              // Imagen
              if (type == 'IMAGE' && thought['imageUrl'] != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18)),
                  child: CachedNetworkImage(
                    imageUrl: thought['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        height: 200,
                        color: Colors.white.withAlpha(15),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                ),
              ],
              // Música
              if (type == 'MUSIC' && thought['music'] != null) ...[
                const SizedBox(height: 10),
                _MusicAttachment(music: thought['music'] as Map, t: t, color: color),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicAttachment extends StatelessWidget {
  final Map music;
  final GradientTheme t;
  final Color color;
  const _MusicAttachment({required this.music, required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    final title   = music['title']  as String? ?? '';
    final artist  = music['artist'] as String? ?? '';
    final lyrics  = music['lyrics'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if ((music['artworkUrl'] as String? ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: music['artworkUrl'] as String,
                  width: 44, height: 44, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                      width: 44, height: 44,
                      color: color.withAlpha(40),
                      child: Icon(Icons.music_note_rounded, color: color, size: 20)),
                ),
              )
            else
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(40), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.music_note_rounded, color: color, size: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(title, style: TextStyle(color: t.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (artist.isNotEmpty)
                    Text(artist, style: TextStyle(color: t.textSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ]),
          if (lyrics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"$lyrics"',
                style: TextStyle(color: t.textSecondary, fontSize: 13,
                    fontStyle: FontStyle.italic, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
