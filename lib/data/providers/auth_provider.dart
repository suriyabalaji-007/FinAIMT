import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    // Start initial session restoration
    _init();
    return AuthState(isLoading: true);
  }

  Future<void> _init() async {
    final token = await _authService.getToken();
    if (token != null) {
      try {
        final profile = await _authService.getProfile();
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: profile,
        );
      } catch (e) {
        // Token might be expired or invalid
        await _authService.logout();
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> register(
    String name,
    String email,
    String phone,
    String password,
    String transactionPin,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userResponse = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        transactionPin: transactionPin,
      );
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: userResponse,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userResponse = await _authService.login(email: email, password: password);
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: userResponse,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}
