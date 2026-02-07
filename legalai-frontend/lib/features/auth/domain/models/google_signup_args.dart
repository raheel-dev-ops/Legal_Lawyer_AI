class GoogleSignupArgs {
  final String googleToken;
  final String? name;
  final String? email;

  const GoogleSignupArgs({
    required this.googleToken,
    this.name,
    this.email,
  });
}
