/// Build-time settings. Override with `--dart-define=API_BASE=https://…` (e.g. a local backend while developing).
abstract final class Env {
  /// The Business Genie server. The API lives under `/api/genie`; the web app is served from the same host.
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'https://business-genie.gophygital.work');

  static String get apiRoot => '$apiBase/api/genie';

  /// Where someone without an account creates their workspace.
  static String get signUpUrl => '$apiBase/signup';

  static String get webUrl => apiBase;

  /// Debug builds only: a sign-in token to start with, so a developer can
  /// skip the email code. Pass it at run time, never in code:
  /// `flutter run --dart-define=DEV_TOKEN=$(cat path/to/token)`.
  /// Release builds ignore it.
  static const devToken = String.fromEnvironment('DEV_TOKEN');
}
