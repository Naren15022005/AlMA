import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Modelos ──────────────────────────────────────────────────────────────────

class TVResult {
  final int    id;
  final String title;
  final String? posterUrl;
  final String? summary;
  final double? rating;
  final String? premiered;
  final String? status;

  const TVResult({
    required this.id,
    required this.title,
    this.posterUrl,
    this.summary,
    this.rating,
    this.premiered,
    this.status,
  });

  factory TVResult.fromJson(Map<String, dynamic> show) => TVResult(
    id:        show['id'] as int,
    title:     show['name'] as String,
    posterUrl: (show['image'] as Map<String, dynamic>?)?['medium'] as String?,
    summary:   _stripHtml(show['summary'] as String? ?? ''),
    rating:    (show['rating'] as Map<String, dynamic>?)?['average'] as double?,
    premiered: show['premiered'] as String?,
    status:    show['status'] as String?,
  );
}

class TVDetails {
  final int    id;
  final String title;
  final int    totalSeasons;
  final int    totalEpisodes;
  final String? posterUrl;
  final String? summary;
  final double? rating;

  const TVDetails({
    required this.id,
    required this.title,
    required this.totalSeasons,
    required this.totalEpisodes,
    this.posterUrl,
    this.summary,
    this.rating,
  });
}

String _stripHtml(String html) =>
    html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

// ─── Servicio ─────────────────────────────────────────────────────────────────

class TVMazeService {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.tvmaze.com',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  final _cache = <String, dynamic>{};

  Future<List<TVResult>> search(String query) async {
    if (query.trim().length < 2) return [];
    final key = 'search:$query';
    if (_cache.containsKey(key)) return _cache[key] as List<TVResult>;

    try {
      final res = await _dio.get('/search/shows',
          queryParameters: {'q': query.trim()});
      final results = (res.data as List<dynamic>)
          .take(8)
          .map((r) => TVResult.fromJson(r['show'] as Map<String, dynamic>))
          .toList();
      _cache[key] = results;
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<TVDetails?> getDetails(int id) async {
    final key = 'details:$id';
    if (_cache.containsKey(key)) return _cache[key] as TVDetails;

    try {
      final results = await Future.wait([
        _dio.get('/shows/$id'),
        _dio.get('/shows/$id/seasons'),
      ]);

      final show    = results[0].data as Map<String, dynamic>;
      final seasons = (results[1].data as List<dynamic>)
          .where((s) => (s['number'] as int?) != null)
          .toList();

      final totalEpisodes = seasons.fold<int>(
          0, (sum, s) => sum + ((s['episodeOrder'] as int?) ?? 0));

      final d = TVDetails(
        id:            show['id'] as int,
        title:         show['name'] as String,
        totalSeasons:  seasons.length,
        totalEpisodes: totalEpisodes,
        posterUrl:     (show['image'] as Map<String, dynamic>?)?['medium'] as String?,
        summary:       _stripHtml(show['summary'] as String? ?? ''),
        rating:        (show['rating'] as Map<String, dynamic>?)?['average'] as double?,
      );
      _cache[key] = d;
      return d;
    } catch (_) {
      return null;
    }
  }
}

final tvMazeServiceProvider = Provider<TVMazeService>((ref) => TVMazeService());
