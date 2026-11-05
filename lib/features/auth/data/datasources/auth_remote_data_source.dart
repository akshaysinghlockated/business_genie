import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json_reader.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/code_request.dart';
import '../../domain/entities/organization.dart';
import '../models/app_user_model.dart';
import '../models/organization_model.dart';

/// The sign-in endpoints of the Business Genie API.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// POST /auth/login → `{ ok, to, note }`. 404 with `no_account` for an unknown email.
  Future<CodeRequest> requestCode(String email) async {
    final response = await _apiClient.post('/auth/login', {'email': email});
    _printDeveloperCode(email, response);
    return CodeRequest(sentTo: response.readString('to', email), note: response.readString('note'));
  }

  /// POST /auth/login/verify → `{ ok, token, token_type, expires_at, user }`. 422 for a wrong code.
  Future<({String token, DateTime? expiresAt, AppUser user})> verifyCode({required String email, required String code}) async {
    final response = await _apiClient.post('/auth/login/verify', {'email': email, 'code': code});
    return (
      token: response.readString('token'),
      expiresAt: response.readDate('expires_at'),
      user: AppUserModel.fromJson(response.readMap('user')),
    );
  }

  /// GET /auth/me → `{ ok, user }`.
  Future<AppUser> fetchCurrentUser() async => AppUserModel.fromJson((await _apiClient.get('/auth/me')).readMap('user'));

  /// GET /onboarding → `{ workspace, step }`. Ready when `workspace && step == "done"`.
  Future<bool> fetchIsWorkspaceReady() async {
    final response = await _apiClient.get('/onboarding');
    final hasWorkspace = response['workspace'] is Map || response.readBool('workspace');
    return hasWorkspace && response.readString('step') == 'done';
  }

  /// GET /dashboard → `organization`.
  Future<Organization> fetchOrganization() async =>
      OrganizationModel.fromJson((await _apiClient.get('/dashboard')).readMap('organization'));

  /// Debug builds only: the test server returns the code as `dev_code`.
  /// Printing it to the run console means sign-in needs no inbox. Never in
  /// release builds.
  void _printDeveloperCode(String email, JsonMap response) {
    final developerCode = response.readStringOrNull('dev_code');
    if (kDebugMode && developerCode != null) debugPrint('[genie] sign-in code for $email: $developerCode');
  }
}
