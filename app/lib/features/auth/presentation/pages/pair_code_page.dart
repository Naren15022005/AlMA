import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class PairCodePage extends ConsumerStatefulWidget {
  const PairCodePage({super.key});

  @override
  ConsumerState<PairCodePage> createState() => _PairCodePageState();
}

class _PairCodePageState extends ConsumerState<PairCodePage>
    with SingleTickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _heartAnim = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) return;

    setState(() => _loading = true);
    try {
      final db = ref.read(firestoreServiceProvider);
      await db.linkCouple(code);
      setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myCode = authState.pairCode ?? '------';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _heartAnim,
                child: Icon(
                  Icons.favorite,
                  size: 64,
                  color: _success ? AppColors.primary : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _success ? '¡Conectados!' : 'Conecta con tu pareja',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Comparte tu código o ingresa el de tu pareja',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _CodeCard(
                code: myCode,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: myCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: const InputDecoration(hintText: 'CÓDIGO', counterText: ''),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _link,
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Conectar'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  const _CodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Text('Tu código', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10, color: AppColors.primary)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: onCopy, icon: const Icon(Icons.copy, size: 16), label: const Text('Copiar')),
        ],
      ),
    );
  }
}
