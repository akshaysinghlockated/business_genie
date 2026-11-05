import 'package:flutter/foundation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/code_request.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/auth_repository.dart';

/// Where the person is in signing in.
enum SessionStatus {
  /// Not read from the phone yet.
  unknown,
  signedOut,

  /// Exploring the sample company, with no network at all.
  demo,

  /// Signed in, but the company isn't set up on the web yet.
  workspaceSetupPending,
  signedIn,
}

/// Sign-in state for the whole app: who is signed in, to which company, and
/// the actions that change it. Screens listen to it through AppState.
class SessionController extends ChangeNotifier {
  SessionController({required AuthRepository repository}) : _repository = repository; // ignore: prefer_initializing_formals

  final AuthRepository _repository;

  SessionStatus status = SessionStatus.unknown;
  AppUser? user;
  Organization? organization;

  /// Shown once on the sign-in screen, after a sign-in ran out.
  String? _signInNotice;

  /// The sign-out started by a 401, so callers can wait for it.
  Future<void>? _pendingSignOut;

  bool get isSignedIn => status == SessionStatus.signedIn || status == SessionStatus.demo || isWorkspaceSetupPending;
  bool get isDemo => status == SessionStatus.demo;
  bool get isWorkspaceSetupPending => status == SessionStatus.workspaceSetupPending;

  /// Signed in with a real account, not the demo.
  bool get isRealAccount => isSignedIn && !isDemo;

  /// Reads the session kept on the phone. With a stored token the app opens
  /// straight away with the last known account; call [refresh] afterwards
  /// to check it with the server.
  Future<void> restore() async {
    if (await _repository.readIsDemo()) {
      _setStatus(SessionStatus.demo);
      return;
    }
    if (kDebugMode && Env.devToken.isNotEmpty) await _repository.useDeveloperToken(Env.devToken);
    if (!await _repository.hasValidStoredToken()) {
      _setStatus(SessionStatus.signedOut);
      return;
    }
    final saved = await _repository.readSavedAccount();
    user = saved?.user;
    organization = saved?.organization;
    _setStatus(saved?.isWorkspaceSetupPending == true ? SessionStatus.workspaceSetupPending : SessionStatus.signedIn);
  }

  /// Step 1 of sign-in: emails a six-digit code.
  Future<CodeRequest> requestCode(String email) => _repository.requestCode(email);

  /// Step 2: checks the code, then learns who this is and whether the
  /// company is set up. On any failure nothing is kept.
  Future<void> verifyCode({required String email, required String code}) async {
    final signedInUser = await _repository.verifyCode(email: email, code: code);
    try {
      final isWorkspaceReady = await _repository.fetchIsWorkspaceReady();
      user = signedInUser;
      organization = isWorkspaceReady ? await _fetchOrganizationOrNull() : null;
      _signInNotice = null;
      await _saveAccount(isWorkspaceSetupPending: !isWorkspaceReady);
      _setStatus(isWorkspaceReady ? SessionStatus.signedIn : SessionStatus.workspaceSetupPending);
    } on ApiException {
      await _repository.clearSession();
      user = null;
      rethrow;
    }
  }

  /// Checks the stored sign-in with the server. A 401 signs out through
  /// [handleUnauthorized]; offline, the last known account stays.
  Future<void> refresh() async {
    if (!isRealAccount) return;
    try {
      final currentUser = await _repository.fetchCurrentUser();
      final isWorkspaceReady = await _repository.fetchIsWorkspaceReady();
      if (!isRealAccount) return;
      user = currentUser;
      if (isWorkspaceReady && organization == null) organization = await _fetchOrganizationOrNull();
      await _saveAccount(isWorkspaceSetupPending: !isWorkspaceReady);
      _setStatus(isWorkspaceReady ? SessionStatus.signedIn : SessionStatus.workspaceSetupPending);
    } on ApiException catch (error) {
      // A 401 is signing out through [handleUnauthorized]; offline keeps
      // the account as it was.
      if (error.isUnauthorized) await _pendingSignOut;
    }
  }

  /// Opens the sample company, with no network.
  Future<void> startDemo() async {
    await _repository.saveIsDemo(true);
    _setStatus(SessionStatus.demo);
  }

  /// Signs out on this phone. There is no logout call yet (backend task
  /// B4), so the token is simply forgotten.
  Future<void> signOut() async {
    user = null;
    organization = null;
    _setStatus(SessionStatus.signedOut);
    await _repository.clearSession();
    await _repository.saveIsDemo(false);
  }

  /// The API answered 401 to a signed-in call: the token ran out or was revoked.
  void handleUnauthorized() {
    if (!isRealAccount) return;
    _signInNotice = 'Your sign-in has ended. Sign in again.';
    _pendingSignOut = signOut();
  }

  /// The notice for the sign-in screen, handed out once.
  String? takeSignInNotice() {
    final notice = _signInNotice;
    _signInNotice = null;
    return notice;
  }

  Future<String?> lastSignedInEmail() => _repository.lastSignedInEmail();

  /// The company name can wait; everything else works without it.
  Future<Organization?> _fetchOrganizationOrNull() async {
    try {
      return await _repository.fetchOrganization();
    } on ApiException catch (error) {
      if (error.isUnauthorized) rethrow;
      return null;
    }
  }

  Future<void> _saveAccount({required bool isWorkspaceSetupPending}) async {
    final currentUser = user;
    if (currentUser == null) return;
    await _repository.saveAccount(
      SavedAccount(user: currentUser, organization: organization, isWorkspaceSetupPending: isWorkspaceSetupPending),
    );
  }

  void _setStatus(SessionStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }
}
