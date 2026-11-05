import '../../domain/entities/app_user.dart';
import '../../domain/entities/code_request.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthRemoteDataSource remote, required AuthLocalDataSource local})
    : _remote = remote, // ignore: prefer_initializing_formals
      _local = local; // ignore: prefer_initializing_formals

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<CodeRequest> requestCode(String email) => _remote.requestCode(_normalise(email));

  @override
  Future<AppUser> verifyCode({required String email, required String code}) async {
    final normalisedEmail = _normalise(email);
    final session = await _remote.verifyCode(email: normalisedEmail, code: code.trim());
    await _local.tokenStorage.saveToken(session.token, expiresAt: session.expiresAt);
    await _local.tokenStorage.saveLastEmail(normalisedEmail);
    return session.user;
  }

  @override
  Future<AppUser> fetchCurrentUser() => _remote.fetchCurrentUser();

  @override
  Future<bool> fetchIsWorkspaceReady() => _remote.fetchIsWorkspaceReady();

  @override
  Future<Organization> fetchOrganization() => _remote.fetchOrganization();

  @override
  Future<bool> hasValidStoredToken() async {
    final storage = _local.tokenStorage;
    if (await storage.readToken() == null) return false;
    if (await storage.isTokenExpired()) {
      await clearSession();
      return false;
    }
    return true;
  }

  @override
  Future<void> useDeveloperToken(String token) async {
    if (await _local.tokenStorage.readToken() == null) await _local.tokenStorage.saveToken(token);
  }

  @override
  Future<void> clearSession() async {
    await _local.tokenStorage.clearToken();
    await _local.clearAccount();
  }

  @override
  Future<String?> lastSignedInEmail() => _local.tokenStorage.readLastEmail();

  @override
  Future<SavedAccount?> readSavedAccount() => _local.readAccount();

  @override
  Future<void> saveAccount(SavedAccount account) => _local.saveAccount(account);

  @override
  Future<bool> readIsDemo() => _local.readIsDemo();

  @override
  Future<void> saveIsDemo(bool isDemo) => _local.saveIsDemo(isDemo);

  static String _normalise(String email) => email.trim().toLowerCase();
}
