import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/auth_user.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient);
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}


class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final ApiClient _apiClient;
  late final StreamSubscription<void> _authFailureSubscription;

  AuthNotifier(this._repository, this._apiClient) : super(const AuthState()) {
    _tryAutoLogin();
    _authFailureSubscription = _apiClient.authFailureStream.listen((_) {
      logout();
    });
  }

  @override
  void dispose() {
    _authFailureSubscription.cancel();
    super.dispose();
  }

  Future<void> _tryAutoLogin() async {
    state = state.copyWith(status: AuthStatus.loading);
    final loggedIn = await _repository.tryAutoLogin();
    if (loggedIn) {
      var user = await _repository.getProfile();
      final localName = await _repository.getLocalName(user.id);
      if (localName != null && localName.isNotEmpty) {
        user = user.copyWith(fullName: localName);
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      var user = await _repository.login(email, password);
      final localName = await _repository.getLocalName(user.id);
      if (localName != null && localName.isNotEmpty) {
        user = user.copyWith(fullName: localName);
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.register(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(AuthUser user) {
    if (user.fullName != null && user.fullName!.isNotEmpty) {
      _repository.saveLocalName(user.id, user.fullName!);
    }
    state = state.copyWith(user: user);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  final apiClient = ref.read(apiClientProvider);
  return AuthNotifier(repository, apiClient);
});
