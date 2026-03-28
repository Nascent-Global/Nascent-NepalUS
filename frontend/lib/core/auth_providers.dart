import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
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

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthApiClient get _authApi => ref.read(authApiClientProvider);

  @override
  AuthState build() => const AuthState.initial();

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _authApi.login(email: email, password: password);
      final meUser = await _authApi.fetchMe(token: session.token);
      state = state.copyWith(
        session: AuthSession(token: session.token, user: meUser),
        isLoading: false,
        clearError: true,
      );
    } on AuthError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign in. Please try again.',
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
      final meUser = await _authApi.fetchMe(token: session.token);
      state = state.copyWith(
        session: AuthSession(token: session.token, user: meUser),
        isLoading: false,
        clearError: true,
      );
    } on AuthError catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to create account. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void logout() {
    state = state.copyWith(
      clearSession: true,
      clearError: true,
      isLoading: false,
    );
  }
}
