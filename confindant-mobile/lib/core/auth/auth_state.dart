enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  final AuthStatus status;
  final Map<String, dynamic>? user;
  final String? token;
  final String? errorMessage;

  AuthSessionState copyWith({
    AuthStatus? status,
    Map<String, dynamic>? user,
    String? token,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory AuthSessionState.initial() =>
      const AuthSessionState(status: AuthStatus.unknown);
}
