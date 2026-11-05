/// Every failed API call, in one shape. [message] is the backend's own
/// sentence ("That code is wrong or has expired…"), safe to show as is; the
/// getters let screens react to the few answers that change the flow.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.body = const {}});

  final String message;

  /// Null when the request never got an answer (offline, timeout).
  final int? statusCode;
  final Map<String, dynamic> body;

  bool get isUnauthorized => statusCode == 401;
  bool get isOffline => statusCode == null;
  bool get isInvalidInput => statusCode == 422;

  /// Too many tries or codes in a short time (429).
  bool get isRateLimited => statusCode == 429;

  /// HRMS is switched off for this company (423).
  bool get isModuleOff => statusCode == 423;

  /// Sign-in for an email that has no account (404 with `no_account`).
  bool get isNoAccount => body['no_account'] == true;

  static const offlineMessage = "You're offline. Check your connection and try again.";
  static const unknownMessage = 'Something went wrong on our side. Try again in a minute.';

  @override
  String toString() => 'ApiException($statusCode): $message';
}
