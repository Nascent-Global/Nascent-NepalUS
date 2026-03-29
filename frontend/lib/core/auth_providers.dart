import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'auth_session_storage.dart';
import '../data/remote/auth_api_client.dart';
import '../data/remote/auth_models.dart';

class AuthState {
  const AuthState({
    required this.session,
    required this.isLoading,
    required this.errorMessage,
  });

  const AuthState.initial()
    : session = null,
      isLoading = false,
      errorMessage = null;

  final AuthSession? session;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => session != null;

  AuthState copyWith({
    AuthSession? session,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final authBaseUrlProvider = Provider<String>((ref) {
  return AppConfig.apiBaseUrl;
});

final authApiClientProvider = Provider<AuthApiClient>((ref) {
  final baseUrl = ref.watch(authBaseUrlProvider);
  return AuthApiClient(baseUrl: baseUrl);
});

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return AuthSessionStorage();
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthApiClient get _authApi => ref.read(authApiClientProvider);
  AuthSessionStorage get _storage => ref.read(authSessionStorageProvider);

  @override
  AuthState build() {
    Future<void>.microtask(_restoreSession);
    return const AuthState.initial();
  }

  Future<void> _restoreSession() async {
    final cached = await _storage.readSession();
    if (cached == null) return;

    state = state.copyWith(session: cached, clearError: true);

    try {
      final refreshed = await _authApi.refresh(
        refreshToken: cached.refreshToken,
      );
      state = state.copyWith(session: refreshed, clearError: true);
      await _storage.save(refreshed);
    } on AuthError catch (error) {
      if (error.statusCode == 401) {
        await _storage.clear();
        state = state.copyWith(clearSession: true, clearError: true);
      }
    } catch (_) {
      // Keep cached session for offline-first UX if backend is unreachable.
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _authApi.login(email: email, password: password);
      state = state.copyWith(
        session: session,
        isLoading: false,
        clearError: true,
      );
      await _storage.save(session);
    } on AuthError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _unexpectedAuthMessage(error),
      );
    }
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String timezone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _authApi.register(
        username: username,
        email: email,
        password: password,
        timezone: timezone,
      );
      state = state.copyWith(
        session: session,
        isLoading: false,
        clearError: true,
      );
      await _storage.save(session);
    } on AuthError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _unexpectedAuthMessage(error),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    final token = state.session?.token;
    if (token != null) {
      try {
        await _authApi.logout(token: token);
      } catch (_) {
        // Always clear local session even if server logout fails.
      }
    }
    await _storage.clear();
    state = state.copyWith(
      clearSession: true,
      clearError: true,
      isLoading: false,
    );
  }

  String _unexpectedAuthMessage(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('connection refused') ||
        text.contains('failed host lookup')) {
      return 'Cannot reach backend. If using a physical device, run: adb reverse tcp:3000 tcp:3000';
    }
    return 'Unable to authenticate. Please try again.';
  }
}
