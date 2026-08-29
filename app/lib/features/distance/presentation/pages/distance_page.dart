import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

class DistancePage extends ConsumerStatefulWidget {
  const DistancePage({super.key});

  @override
  ConsumerState<DistancePage> createState() => _DistancePageState();
}

class _DistancePageState extends ConsumerState<DistancePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _shareLocation();
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  Future<void> _shareLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final auth = ref.read(authProvider);
      await ref.read(firestoreServiceProvider).updateLocation(auth.uid!, auth.coupleId!, pos.latitude, pos.longitude);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final coupleId = auth.coupleId;
    final uid = auth.uid;

    if (coupleId == null || uid == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Identificar el partner
    final myLocationStream = ref.watch(StreamProvider.autoDispose((ref) =>
        ref.read(firestoreServiceProvider).locationStream(uid)));
    final coupleStream = ref.watch(StreamProvider.autoDispose((ref) =>
        ref.read(firestoreServiceProvider).coupleStream(coupleId)));

    final coupleData = coupleStream.value;
    String? partnerId;
    if (coupleData != null) {
      partnerId = (coupleData['user1Id'] as String?) == uid
          ? coupleData['user2Id'] as String?
          : coupleData['user1Id'] as String?;
    }

    final partnerLocationAsync = partnerId != null
        ? ref.watch(StreamProvider.autoDispose((ref) =>
            ref.read(firestoreServiceProvider).locationStream(partnerId!)))
        : null;

    int? distKm;
    if (myLocationStream.value != null && partnerLocationAsync?.value != null) {
      final me = myLocationStream.value!;
      final partner = partnerLocationAsync!.value!;
      distKm = _haversineKm(
        (me['lat'] as num).toDouble(), (me['lng'] as num).toDouble(),
        (partner['lat'] as num).toDouble(), (partner['lng'] as num).toDouble(),
      ).round();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distancia'),
        actions: [IconButton(icon: const Icon(Icons.my_location), onPressed: _shareLocation)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _pulseAnim,
            child: Icon(Icons.favorite, size: 80,
              color: distKm == null || distKm > 100 ? AppColors.primaryLight : AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            distKm != null ? '$distKm km' : 'Ubicación no disponible',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: 'PlayfairDisplay', color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            distKm == null ? 'Activa la ubicación para calcular' : distKm == 0 ? '¡Están juntos!' : 'Entre ustedes dos',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 40),
          _InfoCard(icon: Icons.access_time_outlined, label: 'Tu hora', value: TimeOfDay.now().format(context)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _shareLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar ubicación'),
          ),
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
      );
}
