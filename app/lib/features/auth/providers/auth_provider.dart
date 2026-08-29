import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

// ─── Estado de auth ──────────────────────────────────────────────────────────

class AuthState {
  final User? firebaseUser;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.firebaseUser,
    this.userData,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => firebaseUser != null;
  bool get isPaired => (userData?['coupleId'] as String?)?.isNotEmpty ?? false;
  String? get coupleId => userData?['coupleId'] as String?;
  String? get uid => firebaseUser?.uid;
  String get name => userData?['name'] as String? ?? '';
  String? get pairCode => userData?['pairCode'] as String?;
  String? get avatarUrl => userData?['avatarUrl'] as String?;

  AuthState copyWith({
    User? firebaseUser,
    Map<String, dynamic>? userData,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        firebaseUser: firebaseUser ?? this.firebaseUser,
        userData: userData ?? this.userData,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Escucha cambios en Firebase Auth
    ref.listen(firebaseUserProvider, (_, next) {
      next.whenData((user) => _onUserChanged(user));
    });
    return const AuthState(isLoading: true);
  }

  AuthService get _authService => ref.read(authServiceProvider);
  FirestoreService get _db => ref.read(firestoreServiceProvider);

  Future<void> _onUserChanged(User? user) async {
    if (user == null) {
      state = const AuthState();
      return;
    }
    state = state.copyWith(firebaseUser: user, isLoading: true);
    try {
      final userData = await _db.getUser(user.uid);
      state = state.copyWith(userData: userData, isLoading: false);
      // Escucha cambios en el documento del usuario (ej: coupleId se actualiza)
      ref.listen(
        StreamProvider((ref) => _db.userStream(user.uid)),
        (_, next) => next.whenData((data) {
          if (data != null) state = state.copyWith(userData: data);
        }),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> register(String email, String name, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(email: email, name: name, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.code == 'email-already-in-use'
            ? 'Este correo ya está registrado'
            : 'Error al crear la cuenta',
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.code == 'invalid-credential'
            ? 'Correo o contraseña incorrectos'
            : 'Error al iniciar sesión',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  void refreshUserData(Map<String, dynamic> data) {
    state = state.copyWith(userData: data);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
