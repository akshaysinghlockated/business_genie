import '../entities/app_user.dart';
import '../entities/code_request.dart';
import '../entities/organization.dart';

/// Everything about signing in, whatever the source. Calls that reach the
/// server throw ApiException with a sentence to show.
abstract interface class AuthRepository {
  /// Emails a six-digit code. An unknown email throws with `isNoAccount`.
  Future<CodeRequest> requestCode(String email);

  /// Checks the code, then keeps the token and remembers the email.
  Future<AppUser> verifyCode({required String email, required String code});

  /// The signed-in person, from the server.
  Future<AppUser> fetchCurrentUser();

  /// True once the company finished its set-up on the web.
  Future<bool> fetchIsWorkspaceReady();

  /// The company. Its first read of the day can start the weekly AI brief,
  /// so call it once per sign-in and keep the answer.
  Future<Organization> fetchOrganization();

  /// True when a token is stored and has not run out. An expired token is
  /// dropped.
  Future<bool> hasValidStoredToken();

  /// Debug builds: starts with a given token so developers can skip the code.
  Future<void> useDeveloperToken(String token);

  /// Forgets the token and the saved account on this phone.
  Future<void> clearSession();

  Future<String?> lastSignedInEmail();

  /// The account as last seen, so the app opens straight away and offline.
  Future<SavedAccount?> readSavedAccount();
  Future<void> saveAccount(SavedAccount account);

  Future<bool> readIsDemo();
  Future<void> saveIsDemo(bool isDemo);
}

/// The account as kept on the phone between launches.
class SavedAccount {
  const SavedAccount({required this.user, this.organization, this.isWorkspaceSetupPending = false});

  final AppUser user;
  final Organization? organization;
  final bool isWorkspaceSetupPending;
}
