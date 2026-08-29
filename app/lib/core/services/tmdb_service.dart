import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modelos ──────────────────────────────────────────────────────────────────

class TMDBResult {
  final int id;
  final String title;
  final String mediaType;
  final String? posterPath;
  final String? overview;
  final String? releaseDate;
  final double? rating;

  const TMDBResult({
    required this.id, required this.title, required this.mediaType,
    this.posterPath, this.overview, this.releaseDate, this.rating,
  });

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w342$posterPath'
      : null;

  factory TMDBResult.fromJson(Map<String, dynamic> j) => TMDBResult(
    id: j['id'] as int,
    title: (j['name'] ?? j['title'] ?? '') as String,
    mediaType: j['media_type'] as String? ?? 'tv',
    posterPath: j['poster_path'] as String?,
    overview: j['overview'] as String?,
    releaseDate: (j['first_air_date'] ?? j['release_date']) as String?,
    rating: (j['vote_average'] as num?)?.toDouble(),
  );
}

class TMDBDetails {
  final int id;
  final String title;
  final String mediaType;
  final int? totalSeasons;
  final int? totalEpisodes;
  final String? posterPath;
  final String? overview;

  const TMDBDetails({
    required this.id, required this.title, required this.mediaType,
    this.totalSeasons, this.totalEpisodes, this.posterPath, this.overview,
  });

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w342$posterPath'
      : null;

  factory TMDBDetails.fromJson(Map<String, dynamic> j, String mediaType) =>
      TMDBDetails(
        id: j['id'] as int,
        title: (j['name'] ?? j['title'] ?? '') as String,
        mediaType: mediaType,
        totalSeasons: j['number_of_seasons'] as int?,
        totalEpisodes: j['number_of_episodes'] as int?,
        posterPath: j['poster_path'] as String?,
        overview: j['overview'] as String?,
      );
}

// ─── Servicio ─────────────────────────────────────────────────────────────────

const _kTmdbKey = 'tmdb_api_key';
const _base      = 'https://api.themoviedb.org/3';

class TMDBService {
  String? _apiKey;
  Dio? _dio;
  final _cache = <String, dynamic>{};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_kTmdbKey);
    _buildDio();
  }

  void _buildDio() {
    if (_apiKey == null || _apiKey!.isEmpty) { _dio = null; return; }
    _dio = Dio(BaseOptions(
      baseUrl: _base,
      queryParameters: {'api_key': _apiKey, 'language': 'es-ES'},
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));
  }

  bool get hasKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<void> saveKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTmdbKey, _apiKey!);
    _buildDio();
    _cache.clear();
  }

  /// Returns null on network error, empty list on no results.
  /// Throws [TMDBException] if the key is invalid (401/403).
  Future<List<TMDBResult>> search(String query) async {
    if (!hasKey) throw const TMDBException('no_key');
    final key = 'search:$query';
    if (_cache.containsKey(key)) return _cache[key] as List<TMDBResult>;

    try {
      final res = await _dio!.get('/search/multi',
          queryParameters: {'query': query.trim(), 'include_adult': 'false'});
      final results = (res.data['results'] as List<dynamic>)
          .where((r) => r['media_type'] == 'tv' || r['media_type'] == 'movie')
          .map((r) => TMDBResult.fromJson(r as Map<String, dynamic>))
          .take(8)
          .toList();
      _cache[key] = results;
      return results;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const TMDBException('invalid_key');
      }
      throw const TMDBException('network_error');
    }
  }

  Future<TMDBDetails?> getDetails(int id, String mediaType) async {
    if (!hasKey) return null;
    final key = 'details:$mediaType:$id';
    if (_cache.containsKey(key)) return _cache[key] as TMDBDetails;
    try {
      final endpoint = mediaType == 'tv' ? 'tv' : 'movie';
      final res = await _dio!.get('/$endpoint/$id');
      final d = TMDBDetails.fromJson(res.data as Map<String, dynamic>, mediaType);
      _cache[key] = d;
      return d;
    } catch (_) { return null; }
  }
}

class TMDBException implements Exception {
  final String code; // 'no_key' | 'invalid_key' | 'network_error'
  const TMDBException(this.code);
}

final tmdbServiceProvider = Provider<TMDBService>((ref) => TMDBService());
